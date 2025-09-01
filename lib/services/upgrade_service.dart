import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/upgrade_models.dart';

class UpgradeService {
  // Backend base URL - Update this to match your server
  static const String _baseUrl = 'https://zawadi-lms.onrender.com/api';
  
  // Alternative URLs for different environments
  static const String _prodUrl = 'https://zawadi-lms.onrender.com/api';
  static const String _stagingUrl = 'https://zawadi-lms.onrender.com/api';
  
  String get baseUrl => _baseUrl; // Switch to _prodUrl for production

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Create M-Pesa payment request
  Future<PaymentResponse> createMpesaPayment({
    required double amount,
    required String phoneNumber,
    required String email,
    required String planId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment'),
        headers: _headers,
        body: json.encode({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'email': email,
          'planId': planId,
          'paymentMethod': 'mpesa',
          'currency': 'KES',
          'region': 'kenya',
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Create international subscription
  Future<PaymentResponse> createInternationalSubscription({
    required double amount,
    required String email,
    required String planId,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-subscription'),
        headers: _headers,
        body: json.encode({
          'amount': amount,
          'email': email,
          'planId': planId,
          'currency': currency,
          'paymentMethod': 'card',
          'region': 'international',
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Verify payment status
  Future<PaymentResponse> verifyPayment(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-payment/$transactionId'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Verification failed: ${e.toString()}',
      );
    }
  }

  // Get user subscription status
  Future<SubscriptionStatus> getUserSubscription(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/status/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionStatus.fromJson(data);
      } else {
        return SubscriptionStatus(isActive: false);
      }
    } catch (e) {
      return SubscriptionStatus(isActive: false);
    }
  }

  // Cancel subscription
  Future<PaymentResponse> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/subscription/cancel/$subscriptionId'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Cancellation failed: ${e.toString()}',
      );
    }
  }

  // Update subscription plan
  Future<PaymentResponse> updateSubscription({
    required String subscriptionId,
    required String newPlanId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subscription/update/$subscriptionId'),
        headers: _headers,
        body: json.encode({
          'newPlanId': newPlanId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Update failed: ${e.toString()}',
      );
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/history/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['payments'] != null) {
          return List<Map<String, dynamic>>.from(data['payments']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Handle API response
  PaymentResponse _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return PaymentResponse.fromJson(data);
      } else {
        return PaymentResponse(
          success: false,
          status: 'error',
          message: data['message'] ?? 'Request failed',
          additionalData: data,
        );
      }
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Failed to parse response: ${e.toString()}',
      );
    }
  }

  // Validate phone number format
  bool validatePhoneNumber(String phoneNumber) {
    // Kenya phone number validation
    final kenyanRegex = RegExp(r'^(254|0)7[0-9]{8}$');
    return kenyanRegex.hasMatch(phoneNumber);
  }

  // Format phone number to international format
  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return '254${phoneNumber.substring(1)}';
    }
    return phoneNumber;
  }

  // Get available plans from backend (optional - can use static data)
  Future<List<SubscriptionPlan>> getAvailablePlans(String region) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plans/$region'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['plans'] != null) {
          return (data['plans'] as List)
              .map((plan) => SubscriptionPlan.fromJson(plan))
              .toList();
        }
      }
      
      // Fallback to static data
      return PlanData.getPlansForRegion(region);
    } catch (e) {
      // Return static data on error
      return PlanData.getPlansForRegion(region);
    }
  }

  // Send webhook notification (for backend to handle subscription updates)
  Future<PaymentResponse> sendWebhookNotification({
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/webhook/payment'),
        headers: _headers,
        body: json.encode({
          'event': event,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        status: 'error',
        message: 'Webhook failed: ${e.toString()}',
      );
    }
  }

  // Check server health
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Create payment with retry mechanism
  Future<PaymentResponse> createPaymentWithRetry({
    required PaymentRequest paymentRequest,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        
        final response = await http.post(
          Uri.parse('$baseUrl/create-payment'),
          headers: _headers,
          body: json.encode(paymentRequest.toJson()),
        ).timeout(const Duration(seconds: 30));

        final result = _handleResponse(response);
        
        if (result.success) {
          return result;
        }
        
        // If not the last attempt and it's a network error, retry
        if (attempts < maxRetries && _isRetryableError(result.message)) {
          await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
          continue;
        }
        
        return result;
      } catch (e) {
        if (attempts >= maxRetries) {
          return PaymentResponse(
            success: false,
            status: 'error',
            message: 'Payment failed after $maxRetries attempts: ${e.toString()}',
          );
        }
        
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    return PaymentResponse(
      success: false,
      status: 'error',
      message: 'Payment failed after maximum retries',
    );
  }

  // Check if error is retryable
  bool _isRetryableError(String message) {
    final retryableErrors = [
      'network error',
      'connection timeout',
      'server error',
      'temporarily unavailable',
    ];
    
    return retryableErrors.any((error) => 
        message.toLowerCase().contains(error.toLowerCase()));
  }

  // Log payment attempt for debugging
  void logPaymentAttempt({
    required String planId,
    required String method,
    required String status,
    String? error,
  }) {
    // In a real app, you'd send this to your logging service
    print('Payment Attempt Log:');
    print('Plan ID: $planId');
    print('Method: $method');
    print('Status: $status');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    if (error != null) {
      print('Error: $error');
    }
  }
}