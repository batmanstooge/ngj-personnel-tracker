// lib/services/location_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:location_ui/backend_config/config.dart';
import 'package:location_ui/models/local_location.dart';
import 'dart:convert';
import 'dart:async';
import 'auth_service.dart'; // To get the JWT token
import 'local_db_service.dart'; // For local storage if needed
import 'connectivity_service.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static Timer? _periodicUploadTimer;
  static const Duration _uploadInterval = Duration(
    minutes: 3,
  ); 

  // Services for offline capabilities
  static final LocalDbService _localDbService = LocalDbService();
  static final ConnectivityService _connectivityService = ConnectivityService();
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription; // For syncing when online
  //  StreamController for live location updates
  static final StreamController<Position> _liveLocationStreamController =
      StreamController<
        Position
      >.broadcast(); // Use for multiple listeners

  // Public stream getter for live location
  static Stream<Position> get liveLocationStream =>
      _liveLocationStreamController.stream;

  // Request location permissions
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.deniedForever) {
        print("Background location permission (Always) not granted fully.");
      }
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Start continuous location tracking
  static Future<void> startLocationTracking() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      print("Location permissions not granted. Cannot start tracking.");
      return;
    }

    // Check if location services are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print(
        "Location services are disabled on the device. Please enable them.",
      );
      Geolocator.openLocationSettings();
      return;
    }

    // Initialize local database to ensure it's ready
    await _localDbService.database;

  
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
          final bool isOnline =
              results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.ethernet);
          print("LocationService: Connectivity changed. Is online: $isOnline");
          if (isOnline) {
            print("Device is online. Attempting to sync pending locations.");
            _syncPendingLocations(); // Trigger sync when online
          } else {
            print("Device is offline. Locations will be stored locally.");
          }
        });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters moved
      
    );
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print(
          'Live Location: ${position.latitude}, ${position.longitude}, Timestamp: ${position.timestamp}',
        );
        _liveLocationStreamController.add(position);
        _processAndUploadLocation(position);
      },
      onError: (error) {
        print('Error getting location stream: $error');
      },
      cancelOnError: false, 
    );

    
    _periodicUploadTimer?.cancel();
    _periodicUploadTimer = Timer.periodic(_uploadInterval, (timer) {
      _getCurrentLocationAndUpload();
    });
    // Attempt an initial sync in case there are pending locations from a previous offline session
    _syncPendingLocations();
  }

  // Stop location tracking
  static void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _periodicUploadTimer?.cancel();
    _periodicUploadTimer = null;
    _connectivitySubscription?.cancel(); 
    _connectivitySubscription = null;
    _liveLocationStreamController.close();
    print("Location tracking stopped.");
  }

  static Future<void> _getCurrentLocationAndUpload() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services disabled, skipping current location fetch.");
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _processAndUploadLocation(position);
    } catch (e) {
      print("Error getting current location for upload: $e");
    }
  }

  // Decides whether to upload to backend or save locally based on network status
  static Future<void> _processAndUploadLocation(Position position) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print("No JWT token found. Cannot process location.");
      
      await _localDbService.insertLocation(
        LocalLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
        ),
      );
      return;
    }

    // Check connectivity for decision
    final isOnline = await _connectivityService.isOnline();
    final LocalLocation localLocation = LocalLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );

    if (isOnline) {
      // Try to upload immediately if online
      final uploaded = await _uploadLocationToBackend(localLocation);
      if (!uploaded) {
        // If upload fails even when online, save locally for retry
        await _localDbService.insertLocation(localLocation);
        print(
          "Failed to upload location while online, saved locally for retry.",
        );
      }
    } else {
      // save locally if offline
      await _localDbService.insertLocation(localLocation);
    }
  }

  // Upload a single location to backend 
  static Future<bool> _uploadLocationToBackend(LocalLocation location) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print(
        "No JWT token found for _uploadLocationToBackend. This shouldn't happen if _processAndUploadLocation handled it.",
      );
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(trackUrl), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'timestamp':
              location.timestamp
                  .toIso8601String(), 
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Failed to upload location to backend: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Network error uploading location to backend: $e');
      return false; 
    }
  }

  // Syncs all pending locations from local DB to backend when online
  static Future<void> _syncPendingLocations() async {
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      print("Not online. Cannot sync pending locations.");
      return;
    }

    final pendingLocations = await _localDbService.getPendingLocations();
    if (pendingLocations.isEmpty) {
      print("No pending locations to sync.");
      return;
    }

    print("Attempting to sync ${pendingLocations.length} pending locations...");

    for (final loc in pendingLocations) {
      final uploaded = await _uploadLocationToBackend(loc);
      if (uploaded) {
        if (loc.id != null) {
          await _localDbService.deleteLocation(loc.id!);
        }
      } else {
        
        print("Failed to upload a pending location. Stopping sync for now.");
        break; 
      }
    }
    print("Pending locations sync attempt finished.");
  }

  // Get daily location summary (from backend only, as local is just for pending uploads)
  static Future<List<dynamic>?> getDailyLocationSummary(DateTime date) async {
    final token = await AuthService.getToken();
    if (token == null) {
      print("No JWT token found. Cannot get location summary.");
      return null;
    }
    final String summaryUrl = getDailyLocationSummaryURl(date);

    try {
      final response = await http.get(
        Uri.parse(summaryUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['locations']; 
      } else {
        print(
          'Failed to get daily summary: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Network error getting daily summary: $e');
      return null;
    }
  }
}
