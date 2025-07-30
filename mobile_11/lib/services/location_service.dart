import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import '../models/offline_location.dart';
import 'api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final DatabaseService _dbService = DatabaseService();

  // Check location permission
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }
    return true;
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Start location tracking with offline support
  void startTracking(Function(Position) onLocationChanged) {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    ).listen((Position position) async {
      onLocationChanged(position);

      // Save to local database
      await _saveLocationOffline(position);

      // Try to sync if online
      if (ConnectivityService().hasConnection) {
        await _syncOfflineLocations();
      }
    });
  }

  // Save location to offline database
  Future<void> _saveLocationOffline(Position position) async {
    try {
      final offlineLocation = OfflineLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      await _dbService.insertLocation(offlineLocation);
    } catch (e) {
      print('Error saving offline location: $e');
    }
  }

  // Sync offline locations to server
  Future<void> _syncOfflineLocations() async {
    try {
      final unsyncedLocations = await _dbService.getUnsyncedLocations();

      for (var location in unsyncedLocations) {
        try {
          // Send to server
          await ApiService.saveLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            placeName: location.placeName,
            address: location.address,
            accuracy: location.accuracy,
          );

          // Mark as synced
          await _dbService.markLocationAsSynced(location.id!);
        } catch (e) {
          print('Error syncing location ${location.id}: $e');
          // Continue with next location
        }
      }
    } catch (e) {
      print('Error syncing offline locations: $e');
    }
  }

  // Manual sync trigger
  Future<void> syncOfflineLocations() async {
    if (ConnectivityService().hasConnection) {
      await _syncOfflineLocations();
    }
  }

  // Get locations for a specific date (offline + online)
  Future<List<dynamic>> getLocationsForDate(DateTime date) async {
    // Get offline locations
    final offlineLocations = await _dbService.getLocationsByDate(date);

    // If online, also get from server
    if (ConnectivityService().hasConnection) {
      try {
        final onlineLocations = await ApiService.getDailyLocations(date);
        // Combine and deduplicate if needed
        return onlineLocations;
      } catch (e) {
        print('Error fetching online locations: $e');
      }
    }

    // Return offline locations if offline or server error
    return offlineLocations
        .map(
          (loc) => {
            '_id': loc.id.toString(),
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'timestamp': loc.timestamp.toIso8601String(),
            'placeName': loc.placeName,
            'address': loc.address,
            'accuracy': loc.accuracy,
          },
        )
        .toList();
  }

  void stopTracking() {
    _positionStream?.cancel();
  }
}
