import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/quiz_hint_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Question number and progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question 1/10',
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded space for question
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Explain the photosynthesis like I\'m five years old?',
                    textAlign: TextAlign.center,
                    style: AppTheme.headlineTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom control row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic button
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: Icon(Icons.mic, color: Colors.white),
                      onPressed: () {
                        // Implement recording functionality
                      },
                    ),
                  ),

                  // Hint button
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: Icon(Icons.lightbulb_outline, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizHintScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}