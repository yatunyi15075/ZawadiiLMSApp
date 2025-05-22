import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyTextScreen extends StatefulWidget {
  const CopyTextScreen({Key? key}) : super(key: key);

  @override
  _CopyTextScreenState createState() => _CopyTextScreenState();
}

class _CopyTextScreenState extends State<CopyTextScreen> {
  final TextEditingController _textController = TextEditingController();
  String _selectedLanguage = 'Auto detect';

  final List<String> _languages = [
    'Auto detect',
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];

  void _copyText() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your content'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _languages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Text Input Area
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Paste Text',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Copy Button
            ElevatedButton(
              onPressed: _copyText,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Copy Text',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}