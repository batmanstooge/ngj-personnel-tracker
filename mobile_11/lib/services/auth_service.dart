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

  // Clear auth data
  Future<void> clearAuthData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('auth_token');
  }

  // Perform login
  Future<bool> login(String phoneNumber, String otp) async {
    try {
      final response = await ApiService.verifyOtp(phoneNumber, otp);
      
      if (response.containsKey('token')) {
        await saveAuthToken(response['token'] as String);
        await setLoggedIn(true);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Perform logout
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      print('API logout error: $e');
    } finally {
      await clearAuthData();
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    return await ApiService.sendOtp(phoneNumber);
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return await ApiService.verifyOtp(phoneNumber, otp);
  }
}