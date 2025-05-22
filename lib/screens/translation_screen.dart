import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({Key? key}) : super(key: key);

  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  String? _selectedSourceLanguage;
  String? _selectedTargetLanguage;

  final List<Map<String, String>> _languages = [
    {"code": "en", "name": "English"},
    {"code": "fr", "name": "French"},
    {"code": "de", "name": "German"},
    {"code": "es", "name": "Spanish"},
    {"code": "pt", "name": "Portuguese"},
    {"code": "ja", "name": "Japanese"},
    {"code": "ko", "name": "Korean"},
    {"code": "it", "name": "Italian"},
    {"code": "hi", "name": "Hindi"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Photosynthesis'),
        actions: [
          IconButton(
            icon: Icon(Icons.create_new_folder_outlined),
            onPressed: () {
              // TODO: Implement add to folder functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              // TODO: Implement 'Ask me' functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Languages support',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            // Source Language Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Source Language',
              ),
              value: _selectedSourceLanguage,
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSourceLanguage = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Target Language Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Target Language',
              ),
              value: _selectedTargetLanguage,
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTargetLanguage = value;
                });
              },
            ),
            Spacer(),
            CustomButton(
              text: 'Translate',
              onPressed: _selectedSourceLanguage != null && _selectedTargetLanguage != null
                  ? () {
                      // TODO: Implement translation logic
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}