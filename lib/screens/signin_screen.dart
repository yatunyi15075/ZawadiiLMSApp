// signin_screen.dart - Updated to properly handle first-time user flag
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/clerk_service.dart';
import '../screens/home_screen.dart';
import '../screens/signup_screen.dart';
import '../widgets/custom_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  // Demo credentials
  static const String DEMO_EMAIL = 'demo@example.com';
  static const String DEMO_PASSWORD = 'demo123';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isDemoCredentials() {
    return _emailController.text.trim().toLowerCase() == DEMO_EMAIL.toLowerCase() &&
           _passwordController.text == DEMO_PASSWORD;
  }

  Future<void> _handleDemoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store demo credentials
      await prefs.setString('token', 'demo_token_12345');
      await prefs.setString('userId', 'demo_user_123');
      await prefs.setString('role', 'user');
      await prefs.setString('name', 'Demo User');
      await prefs.setString('email', DEMO_EMAIL);

      // Mark as not first-time user (they've completed onboarding/sign-in flow)
      await prefs.setBool('is_first_time_user', false);
      print('Demo login - Marked as first-time user: false');

      // Verify the data was stored
      final storedToken = prefs.getString('token');
      final storedUserId = prefs.getString('userId');
      
      print('Demo login - Token stored: $storedToken');
      print('Demo login - UserId stored: $storedUserId');

      if (storedToken != null && storedUserId != null) {
        _showSuccessSnackBar('Demo login successful!');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        throw Exception('Failed to store demo credentials');
      }
    } catch (error) {
      print('Demo login error: $error');
      _showError('Demo login failed. Please try again.');
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Check if demo credentials are being used
        if (_isDemoCredentials()) {
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            await _handleDemoLogin();
          }
          return;
        }

        // Clear any existing data before new login
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Use ClerkService for actual login
        final loginResult = await ClerkService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });

          if (loginResult != null) {
            // Mark as not first-time user (they've completed the auth flow)
            await prefs.setBool('is_first_time_user', false);
            print('Sign in - Marked as first-time user: false');
            
            // Verify that data was stored correctly
            final storedToken = prefs.getString('token');
            final storedUserId = prefs.getString('userId');
            
            print('Real login - Token stored: $storedToken');
            print('Real login - UserId stored: $storedUserId');
            
            if (storedToken != null && storedUserId != null) {
              _showSuccessSnackBar('Logged in successfully!');

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else {
              throw Exception('Authentication data not stored properly');
            }
          } else {
            _showError('Login failed. Please check your credentials.');
          }
        }
      } catch (error) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          
          String errorMessage = 'Network error. Please check your connection and try again.';
          
          if (error.toString().contains('SocketException')) {
            errorMessage = 'No internet connection. Please check your network.';
          } else if (error.toString().contains('TimeoutException')) {
            errorMessage = 'Connection timeout. Please try again.';
          } else if (error.toString().contains('Authentication data not stored')) {
            errorMessage = 'Login failed. Please try again.';
          }
          
          print('Login error: $error');
          _showError(errorMessage);
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        const Text(
                          'Zawadii AI', 
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.blue
                          )
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sign in to your account', 
                          style: TextStyle(fontSize: 18, color: Colors.grey)
                        ),
                        const SizedBox(height: 20),
                        
                        // Demo info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Demo: Use $DEMO_EMAIL / $DEMO_PASSWORD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Email', 
                            border: OutlineInputBorder()
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        CustomButton(text: "Sign In", onPressed: _signIn),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ", 
                              style: TextStyle(color: Colors.grey)
                            ),
                            TextButton(
                              onPressed: _navigateToSignUp, 
                              child: const Text(
                                "Sign Up", 
                                style: TextStyle(
                                  color: Colors.blue, 
                                  fontWeight: FontWeight.bold
                                )
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
