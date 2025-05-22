import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class FeynmanTestLevelScreen extends StatefulWidget {
  final String topic;

  const FeynmanTestLevelScreen({Key? key, required this.topic}) : super(key: key);

  @override
  _FeynmanTestLevelScreenState createState() => _FeynmanTestLevelScreenState();
}

class _FeynmanTestLevelScreenState extends State<FeynmanTestLevelScreen> {
  final List<Map<String, dynamic>> _levels = [
    {
      'name': 'Easy',
      'description': '(Beginner)',
      'color': Colors.green,
    },
    {
      'name': 'Medium',
      'description': '(Intermediate)',
      'color': Colors.orange,
    },
    {
      'name': 'Hard',
      'description': '(Advanced)',
      'color': Colors.red,
    },
    {
      'name': 'Super Hard',
      'description': '(Expert)',
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topic} Feynman Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Level For Feynman Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: CustomButton(
                      text: '${level['name']} ${level['description']}',
                      onPressed: () {
                        // TODO: Implement level selection logic
                        // Navigate to the next screen or start the Feynman test
                      },
                      backgroundColor: level['color'],
                      textColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}