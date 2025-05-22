import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class TopicExplorationScreen extends StatefulWidget {
  const TopicExplorationScreen({Key? key}) : super(key: key);

  @override
  _TopicExplorationScreenState createState() => _TopicExplorationScreenState();
}

class _TopicExplorationScreenState extends State<TopicExplorationScreen> {
  final List<String> _topicCategories = [
    'Computer Science',
    'Nursing',
    'Business'
  ];

  String? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feynman AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/feynman_bot.png', // You'll need to add this asset
              width: 100,
              height: 100,
            ),
            SizedBox(height: 16),
            Text(
              'What topic do you want to explore today?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topicCategories.map((topic) {
                return ChoiceChip(
                  label: Text(topic),
                  selected: _selectedTopic == topic,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedTopic = selected ? topic : null;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter a topic you want to explore',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // TODO: Handle custom topic input
              },
            ),
            Spacer(),
            CustomButton(
              text: 'Start Exploring',
              onPressed: _selectedTopic != null
                  ? () {
                      // TODO: Implement navigation to topic exploration
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}