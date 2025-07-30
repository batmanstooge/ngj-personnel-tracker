import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
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
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isOnline = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationService().stopTracking();
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
    LocationService().startTracking((Position position) {
      setState(() {
        _currentPosition = position;
      });
      
      _addMarker(position.latitude, position.longitude, 'Tracked Location');
      _saveLocation(position);
    });
  }

  _saveLocation(Position position) async {
    try {
      // LocationService handles offline/online automatically
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  _addMarker(double latitude, double longitude, String title) {
    final markerId = MarkerId('${latitude}_${longitude}_${DateTime.now().millisecondsSinceEpoch}');
    
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistoryScreen()),
            ),
          ),
          
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _syncOfflineData,
          ),
          
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
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
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          // Map
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _currentPosition != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 15,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapType: Theme.of(context).brightness == Brightness.dark
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

  _logout() async {
    try {
      await ApiService.logout();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Logout failed: $e');
    }
  }
}