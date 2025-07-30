import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl = 'http://10.0.2.2:3000';
  static String? _token;

  static Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>?> _makeRequest(
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
        return null;
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

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await _makeRequest(
      'POST',
      '/login/send-otp',
      body: {'phoneNumber': phoneNumber},
    );
    print('Response from sendOtp: $response');
    return response ?? {};
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/login/verify-otp',
      body: {'phoneNumber': phoneNumber, 'otp': otp},
    );

    // Save token if login successful
    if (response != null && response.containsKey('token')) {
      _token = response['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
    }
    print('Response from verifyOtp: $response');

    return response ?? {};
  }

  static Future<void> logout() async {
    try {
      await _makeRequest('POST', '/login/logout');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _token = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  static Future<Map<String, dynamic>> saveLocation({
    required double latitude,
    required double longitude,
    String? placeName,
    String? address,
    double? accuracy,
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
      },
    );
    return response ?? {};
  }

  static Future<List<dynamic>> getDailyLocations(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return await _makeListRequest('GET', '/locations/daily?date=$dateString');
  }

  static Future<List<dynamic>> getCalendarData() async {
    return await _makeListRequest('GET', '/locations/calendar');
  }

  static Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _makeRequest(
      'GET',
      '/locations/daily-summary?date=$dateString',
    );
    return response ?? {};
  }
}
