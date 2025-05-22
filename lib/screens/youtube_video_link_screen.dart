import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class YouTubeVideoLinkScreen extends StatefulWidget {
  const YouTubeVideoLinkScreen({Key? key}) : super(key: key);

  @override
  _YouTubeVideoLinkScreenState createState() => _YouTubeVideoLinkScreenState();
}

class _YouTubeVideoLinkScreenState extends State<YouTubeVideoLinkScreen> {
  final TextEditingController _linkController = TextEditingController();
  String _selectedLanguage = 'Auto';

  final List<String> _languages = [
    'Auto',
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Korean'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Video Link'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  hintText: 'Paste YouTube video link',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _linkController.clear(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Note language',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _languages.map((language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Fixed responsive layout for buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  // If screen is too narrow, stack buttons vertically
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomButton(
                          text: 'Open YouTube App',
                          onPressed: () {
                            // TODO: Implement open YouTube app functionality
                          },
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Paste Link',
                          onPressed: () {
                            // TODO: Implement paste link functionality
                          },
                          backgroundColor: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                        ),
                      ],
                    );
                  } else {
                    // For wider screens, keep them side by side
                    return Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Open YouTube App',
                            onPressed: () {
                              // TODO: Implement open YouTube app functionality
                            },
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Paste Link',
                            onPressed: () {
                              // TODO: Implement paste link functionality
                            },
                            backgroundColor: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}