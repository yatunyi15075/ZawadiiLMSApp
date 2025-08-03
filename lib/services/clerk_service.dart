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
        Uri.parse('$API_BASE_URL/api/auth/login'),
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
          // Store authentication data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          
          // Store token
          await prefs.setString('token', responseData['token']);
          print('Token stored: ${responseData['token']}');
          
          // Extract and store user data
          if (responseData['user'] != null) {
            final user = responseData['user'];
            
            // Store userId - ensure it's converted to string
            if (user['id'] != null) {
              final userId = user['id'].toString();
              await prefs.setString('userId', userId);
              print('UserId stored: $userId');
            }
            
            // Store other user data
            if (user['name'] != null) {
              await prefs.setString('name', user['name'].toString());
            }
            
            if (user['email'] != null) {
              await prefs.setString('email', user['email'].toString());
            }
            
            if (user['role'] != null) {
              await prefs.setString('role', user['role'].toString());
            }
          }
          
          // Verify data was stored correctly
          final storedToken = prefs.getString('token');
          final storedUserId = prefs.getString('userId');
          print('Verification - Token: $storedToken, UserId: $storedUserId');
          
          if (storedToken != null && storedUserId != null) {
            return responseData['token'];
          } else {
            print('Failed to store authentication data');
            return null;
          }
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
        Uri.parse('$API_BASE_URL/api/auth/register'),
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
          // Store authentication data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          
          // Store token
          await prefs.setString('token', responseData['token']);
          print('Registration - Token stored: ${responseData['token']}');
          
          // Extract and store user data
          if (responseData['user'] != null) {
            final user = responseData['user'];
            
            // Store userId - ensure it's converted to string
            if (user['id'] != null) {
              final userId = user['id'].toString();
              await prefs.setString('userId', userId);
              print('Registration - UserId stored: $userId');
            }
            
            // Store other user data
            if (user['name'] != null) {
              await prefs.setString('name', user['name'].toString());
            }
            
            if (user['email'] != null) {
              await prefs.setString('email', user['email'].toString());
            }
            
            if (user['role'] != null) {
              await prefs.setString('role', user['role'].toString());
            }
          }
          
          // Verify data was stored correctly
          final storedToken = prefs.getString('token');
          final storedUserId = prefs.getString('userId');
          print('Registration verification - Token: $storedToken, UserId: $storedUserId');
          
          if (storedToken != null && storedUserId != null) {
            return responseData['token'];
          } else {
            print('Failed to store registration data');
            return null;
          }
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
      await prefs.clear(); // Clear all stored data
      print('Logout completed - all data cleared');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');
      
      final isValid = token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
      print('Login status check - Token: ${token != null}, UserId: ${userId != null}, Valid: $isValid');
      
      return isValid;
    } catch (e) {
      print('Check login status error: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('Retrieved token: $token');
      return token;
    } catch (e) {
      print('Get token error: $e');
      return null;
    }
  }

  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      print('Retrieved userId: $userId');
      return userId;
    } catch (e) {
      print('Get userId error: $e');
      return null;
    }
  }

  static Future<String?> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      print('Retrieved role: $role');
      return role;
    } catch (e) {
      print('Get role error: $e');
      return null;
    }
  }

  static Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name');
      print('Retrieved name: $name');
      return name;
    } catch (e) {
      print('Get name error: $e');
      return null;
    }
  }

  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');
      print('Retrieved email: $email');
      return email;
    } catch (e) {
      print('Get email error: $e');
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
      
      final isConnected = response.statusCode == 200;
      print('API connection check: $isConnected');
      return isConnected;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  // Debug method to print all stored data
  static Future<void> debugPrintStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('=== DEBUG: Stored Authentication Data ===');
      print('Token: ${prefs.getString('token')}');
      print('UserId: ${prefs.getString('userId')}');
      print('Name: ${prefs.getString('name')}');
      print('Email: ${prefs.getString('email')}');
      print('Role: ${prefs.getString('role')}');
      print('=========================================');
    } catch (e) {
      print('Debug print error: $e');
    }
  }
}