// services/clerk_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ClerkService {
  // Replace with your actual API URL
  static const String API_BASE_URL = 'https://zawadi-lms.onrender.com';

  static Future<String?> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/api/users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Check if the response has the expected structure
        if (responseData['status'] == 'success' && responseData['token'] != null) {
          return responseData['token'];
        } else {
          print('Login failed: Invalid response structure');
          return null;
        }
      } else {
        // Try to decode error message
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          print('Login failed: ${errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          print('Login failed: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  static Future<String?> register(String name, String email, String password) async {
    try {
      print('Attempting registration with name: $name, email: $email');
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/api/users/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Check if the response has the expected structure
        if (responseData['status'] == 'success' && responseData['token'] != null) {
          return responseData['token'];
        } else {
          print('Registration failed: Invalid response structure');
          return null;
        }
      } else {
        // Try to decode error message
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          print('Registration failed: ${errorData['message'] ?? 'Unknown error'}');
          throw Exception(errorData['message'] ?? 'Registration failed');
        } catch (e) {
          print('Registration failed: ${response.statusCode} - ${response.body}');
          throw Exception('Registration failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Check login status error: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Get token error: $e');
      return null;
    }
  }

  static Future<String?> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      print('Get role error: $e');
      return null;
    }
  }

  // Helper method to validate API connection
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }
}