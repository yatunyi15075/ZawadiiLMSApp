import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../screens/upload_audio_screen.dart';

class AskFeynmanScreen extends StatefulWidget {
  const AskFeynmanScreen({Key? key}) : super(key: key);

  @override
  _AskFeynmanScreenState createState() => _AskFeynmanScreenState();
}

class _AskFeynmanScreenState extends State<AskFeynmanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask FeynmanAI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Hello! I\'m Feynman AI, your friendly learning companion. I\'m here to help you understand better today. What would you like to understand better now?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            CustomButton(
              text: 'Upload Audio',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadAudioScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}