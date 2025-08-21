import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';


class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save login status
  Future<void> setLoggedIn(bool loggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', loggedIn);
  }

  // Save auth token
  Future<void> saveAuthToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Save current job ID
  Future<void> saveCurrentJobId(String jobId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_job_id', jobId);
  }

  // Get current job ID
  Future<String?> getCurrentJobId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_job_id');
  }

  // Clear auth data
  Future<void> clearAuthData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('auth_token');
    await prefs.remove('current_job_id');
  }

  // Register user
  Future<Map<String, dynamic>> register(String email) async {
    return await ApiService.register(email);
  }

  // Login user and start job
  Future<Map<String, dynamic>> login(
    String email,
    String deviceId,
    String loginPhoto,
  ) async {
    final response = await ApiService.login(email, deviceId, loginPhoto);

    if (response.containsKey('token')) {
      await saveAuthToken(response['token'] as String);
      await setLoggedIn(true);

      if (response.containsKey('job') && response['job'].containsKey('id')) {
        await saveCurrentJobId(response['job']['id'] as String);
      }
    }

    return response;
  }

  // Logout user and end job
  Future<Map<String, dynamic>> logout(String logoutPhoto) async {
    try {
      final response = await ApiService.logout(logoutPhoto);
      await clearAuthData();
      return response;
    } catch (e) {
      print('AuthService logout error: $e');
      // Still clear local data even if server call fails
      await clearAuthData();
      rethrow;
    }
  }

  // Verify email
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    return await ApiService.verifyEmail(token);
  }
}
