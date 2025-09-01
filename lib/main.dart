// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/logo_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FeynmanAIApp());
}

class FeynmanAIApp extends StatelessWidget {
  const FeynmanAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zawadii Learn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: Typography.material2021().englishLike,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
        ),
      ),
      home: const AuthChecker(), // Changed from LogoScreen to AuthChecker
      debugShowCheckedModeBanner: false,
    );
  }
}

// New widget to check authentication status
class AuthChecker extends StatefulWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user is already logged in
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');
      
      // Add a small delay to show the logo briefly
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        if (token != null && userId != null && token.isNotEmpty && userId.isNotEmpty) {
          // User is logged in, go directly to home screen
          print('User is already logged in, navigating to home');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // User is not logged in, check if they're a first-time user
          final isFirstTime = prefs.getBool('is_first_time_user') ?? true;
          
          if (isFirstTime) {
            // First time user - show onboarding
            print('First time user, showing onboarding');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          } else {
            // Returning user but not logged in - go directly to sign in
            print('Returning user not logged in, showing sign in');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            );
          }
        }
      }
    } catch (error) {
      print('Error checking auth status: $error');
      // On error, default to sign in screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed logo display with error handling
            Image.asset(
              'assets/images/logo.png', // Try this path first
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if the image doesn't load
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(75),
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.blue,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Zawadii AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}


