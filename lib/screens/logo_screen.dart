// logo_screen.dart - Updated to only show for first-time users
import 'package:flutter/material.dart';
import '../screens/onboarding_screen.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({Key? key}) : super(key: key);

  @override
  _LogoScreenState createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to onboarding screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed logo display with multiple path attempts
            Image.asset(
              'assets/images/logo.png', // Try this path first
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Try alternative path
                return Image.asset(
                  'assets/logo.png',
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error2, stackTrace2) {
                    // Final fallback - show icon instead
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
          ],
        ),
      ),
    );
  }
}
