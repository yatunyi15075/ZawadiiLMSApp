import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuizHintScreen extends StatelessWidget {
  const QuizHintScreen({Key? key}) : super(key: key);

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

            // Hint bot icon and title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Image.asset(
                    'assets/hint_bot_icon.png', // You'll need to add this asset
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Suggestion',
                    style: AppTheme.headlineTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Hint content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    'Photosynthesis is a magical trick that plants do! They take sunlight, air, and water to make their own food. The leaves are like little factories. Inside these factories, plants use sunlight to transform water and air into a sweet, energy-rich food called glucose. When the sun shines on the leaves, the green color helps capture the sunlight. This is how plants grow and make their food. So, plants are basically making their own super-important food!',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}