import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../providers/theme_provider.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isOnline = true;
  bool _isTracking = false;
  File? _logoutPhoto;
  bool _photoTaken = false;
  double _lastTrackedDistance = 0;
  LatLng? _lastTrackedPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    LocationService().stopTracking();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed, restart tracking if needed
      if (_isTracking) {
        _startLocationTracking();
      }
    } else if (state == AppLifecycleState.paused) {
      // App paused, stop tracking to save battery
      LocationService().stopTracking();
    }
  }

  _initializeServices() async {
    setState(() => _isLoading = true);

    // Listen to connectivity changes
    ConnectivityService().connectionChange.listen((isConnected) {
      setState(() {
        _isOnline = isConnected;
      });

      if (isConnected) {
        // Sync offline data when back online
        _syncOfflineData();
      }
    });

    // Initialize location
    bool hasPermission = await LocationService().checkPermission();
    if (hasPermission) {
      _getCurrentLocation();
      _startLocationTracking();
      setState(() => _isTracking = true);
    } else {
      Fluttertoast.showToast(msg: 'Location permission denied');
    }

    setState(() => _isLoading = false);
  }

  _getCurrentLocation() async {
    try {
      Position position = await LocationService().getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });

      _addMarker(position.latitude, position.longitude, 'Current Location');

      // Save location (handles offline automatically)
      await _saveLocation(position);

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    }
  }

  _startLocationTracking() {
    LocationService().startTracking((Position position) async {
      setState(() {
        _currentPosition = position;
      });

      // Check if distance is >= 100m from last tracked position
      bool shouldTrack = true;
      if (_lastTrackedPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastTrackedPosition!.latitude,
          _lastTrackedPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < 100) {
          shouldTrack = false;
        }
      }

      if (shouldTrack) {
        _addMarker(position.latitude, position.longitude, 'Tracked Location');
        await _saveLocation(position);
        _lastTrackedPosition = LatLng(position.latitude, position.longitude);
      }
    });
  }

  _saveLocation(Position position) async {
    try {
      // Check if user is stationary (simplified logic)
      bool isStationary = false;
      int stationaryDuration = 0;

      // LocationService handles offline/online automatically
      await LocationService().saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isStationary: isStationary,
        stationaryDuration: stationaryDuration,
      );
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  _addMarker(double latitude, double longitude, String title) {
    final markerId = MarkerId(
      '${latitude}_${longitude}_${DateTime.now().millisecondsSinceEpoch}',
    );

    final marker = Marker(
      markerId: markerId,
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarker,
    );

    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _takeLogoutPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _logoutPhoto = File(pickedFile.path);
          _photoTaken = true;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error taking photo: ${e.toString()}');
      print('Photo capture error: $e');
    }
  }

  Future<String> _getImageBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print('Image encoding error: $e');
      rethrow; // Re-throw to handle in calling function
    }
  }

  Future<void> _logout() async {
    print('Starting logout process...');

    if (_logoutPhoto == null) {
      Fluttertoast.showToast(
        msg: 'Please take a logout photo for verification',
      );
      return;
    }

    setState(() => _isLoading = true);
    print('Loading state set to true');

    try {
      print('Converting image to base64...');
      String photoBase64 = '';
      try {
        photoBase64 = await _getImageBase64(_logoutPhoto!);
        print('Image converted successfully, length: ${photoBase64.length}');
      } catch (imageError) {
        print('Image conversion failed: $imageError');
        Fluttertoast.showToast(msg: 'Failed to process logout photo');
        setState(() => _isLoading = false);
        return;
      }

      print('Calling AuthService.logout...');
      final response = await AuthService().logout(photoBase64);
      print('AuthService.logout completed');

      if (response.containsKey('message')) {
        Fluttertoast.showToast(msg: response['message']);
      }

      print('Clearing local data...');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('auth_token');
      await prefs.remove('current_job_id');

      print('Navigating to login screen...');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Logout process failed with error: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        Fluttertoast.showToast(msg: 'Logout failed: ${e.toString()}');
      }
    } finally {
      print('Logout process completed');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Location Tracker'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          ),

          // Theme toggle
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.setThemeMode(
                themeProvider.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.history),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                ),
          ),

          IconButton(icon: Icon(Icons.sync), onPressed: _syncOfflineData),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          if (!_isOnline)
            Container(
              color: Colors.orange[100],
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[800]),
                  SizedBox(width: 8),
                  Text(
                    'Offline mode - Locations saved locally',
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                ],
              ),
            ),

          // Logout section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Job & Logout',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Take a photo to verify logout',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                if (_photoTaken && _logoutPhoto != null)
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(_logoutPhoto!, fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).disabledColor,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).disabledColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),

                SizedBox(width: 10),

                ElevatedButton.icon(
                  onPressed: _takeLogoutPhoto,
                  icon: Icon(Icons.camera_alt, size: 16),
                  label: Text('Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                SizedBox(width: 10),

                ElevatedButton(
                  onPressed: _isLoading ? null : (_photoTaken ? _logout : null),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Logging out...'),
                            ],
                          )
                          : Text('Logout'),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _currentPosition != null
                    ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 15,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      mapType:
                          Theme.of(context).brightness == Brightness.dark
                              ? MapType.hybrid
                              : MapType.normal,
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_searching,
                            size: 60,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Getting your location...',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 10),
                          CircularProgressIndicator(),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.my_location),
        tooltip: 'Center on current location',
      ),
    );
  }

  _syncOfflineData() async {
    if (_isOnline) {
      Fluttertoast.showToast(msg: 'Syncing offline data...');

      try {
        await LocationService().syncOfflineLocations();
        Fluttertoast.showToast(msg: 'Data synced successfully!');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Sync failed: $e');
      }
    } else {
      Fluttertoast.showToast(msg: 'You are currently offline');
    }
  }
}
