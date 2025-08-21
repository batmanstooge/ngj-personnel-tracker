import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl =
      'http://10.0.2.2:3000'; 
  static String? _token;

  static Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: defaultHeaders);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: defaultHeaders,
          body: jsonEncode(body),
        );
        break;
      default:
        throw Exception('Unsupported HTTP method');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'API request failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<List<dynamic>> _makeListRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: defaultHeaders);
        break;
      case 'POST':
        response = await http.post(
          url,
          headers: defaultHeaders,
          body: jsonEncode(body),
        );
        break;
      default:
        throw Exception('Unsupported HTTP method');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      } else if (decoded is Map<String, dynamic> &&
          decoded.containsKey('data') &&
          decoded['data'] is List) {
        return decoded['data'] as List;
      } else {
        return [];
      }
    } else {
      throw Exception(
        'API request failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Register user
  static Future<Map<String, dynamic>> register(String email) async {
    final response = await _makeRequest(
      'POST',
      '/auth/register',
      body: {'email': email},
    );
    return response;
  }

  // Verify email
  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await _makeRequest(
      'GET',
      '/auth/verify-email?token=$token',
    );
    return response;
  }

  // Login user and start job
  static Future<Map<String, dynamic>> login(
    String email,
    String deviceId,
    String loginPhoto,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/auth/login',
      body: {'email': email, 'deviceId': deviceId, 'loginPhoto': loginPhoto},
    );

    // Save token if login successful
    if (response.containsKey('token')) {
      _token = response['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
    }

    return response;
  }

  // Logout user and end job
  static Future<Map<String, dynamic>> logout(String logoutPhoto) async {
  try {
    final response = await _makeRequest('POST', '/auth/logout', body: {
      'logoutPhoto': logoutPhoto,
    });
    
    _token = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_job_id');
    
    return response;
  } catch (e) {
    print('API Service logout error: $e');
    // Clear local tokens even if server call fails
    _token = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_job_id');
    
    // Return a default response
    return {'message': 'Logged out successfully'};
  }
}

  // Save location
  static Future<Map<String, dynamic>> saveLocation({
    required double latitude,
    required double longitude,
    String? placeName,
    String? address,
    double? accuracy,
    bool isStationary = false,
    int? stationaryDuration,
  }) async {
    final response = await _makeRequest(
      'POST',
      '/locations',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'placeName': placeName,
        'address': address,
        'accuracy': accuracy,
        'isStationary': isStationary,
        'stationaryDuration': stationaryDuration,
      },
    );
    return response;
  }

  // Get job locations
  static Future<List<dynamic>> getJobLocations() async {
    return await _makeListRequest('GET', '/locations/job');
  }

  // Get daily job summary
  static Future<Map<String, dynamic>> getDailyJobSummary(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _makeRequest(
      'GET',
      '/locations/daily-summary?date=$dateString',
    );
    return response;
  }

  // Get stationary locations
  static Future<List<dynamic>> getStationaryLocations() async {
    return await _makeListRequest('GET', '/locations/stationary');
  }
}
