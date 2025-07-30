import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();

  Stream<bool> get connectionChange => _connectionChangeController.stream;

  bool _hasConnection = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> initialize() async {
    _hasConnection = await _checkConnection();
    _connectionChangeController.add(_hasConnection);
    
    // Listen to connectivity changes - note the List<ConnectivityResult>
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      // Check if any of the results indicate connectivity
      bool isConnected = result.any((r) => r != ConnectivityResult.none);
      _hasConnection = isConnected;
      _connectionChangeController.add(_hasConnection);
    });
  }

  Future<bool> _checkConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    // Check if any of the results indicate connectivity
    return connectivityResult.any((r) => r != ConnectivityResult.none);
  }

  bool get hasConnection => _hasConnection;

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionChangeController.close();
  }
}