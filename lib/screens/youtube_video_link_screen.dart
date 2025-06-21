import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_button.dart';

class YouTubeVideoLinkScreen extends StatefulWidget {
  const YouTubeVideoLinkScreen({Key? key}) : super(key: key);

  @override
  _YouTubeVideoLinkScreenState createState() => _YouTubeVideoLinkScreenState();
}

class _YouTubeVideoLinkScreenState extends State<YouTubeVideoLinkScreen> {
  final TextEditingController _linkController = TextEditingController();
  String _selectedLanguage = 'Auto';
  bool _isProcessing = false;

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

  // Base URL for your API - update this to match your backend
  static const String baseUrl = 'http://localhost:5000'; // Change this to your actual backend URL

  Future<void> _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        setState(() {
          _linkController.text = data.text!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link pasted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No link found in clipboard'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pasting link: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processYouTubeVideo() async {
    if (_linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a YouTube URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get userId and currentFolderId from SharedPreferences (similar to localStorage in web)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String? currentFolderId = prefs.getString('currentFolderId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'url': _linkController.text.trim(),
        'dialect': _selectedLanguage,
        'userId': userId,
      };

      if (currentFolderId != null) {
        requestBody['folderId'] = currentFolderId;
      }

      // Make API call to process YouTube video
      final response = await http.post(
        Uri.parse('$baseUrl/api/youtube/process-video'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('YouTube video processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to notes screen or show notes
        if (data['noteId'] != null) {
          // Navigate to the specific note view
          // You'll need to implement this navigation based on your app's routing
          Navigator.pushNamed(
            context, 
            '/notes/${data['noteId']}',
            arguments: {
              'notes': data['notes'],
              'noteId': data['noteId'],
            },
          );
        } else {
          // Show notes in a dialog or navigate to notes list
          _showNotesDialog(data['notes'] ?? 'No notes generated.');
        }

      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to process YouTube URL');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process YouTube video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showNotesDialog(String notes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generated Notes'),
          content: SingleChildScrollView(
            child: Text(notes),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Copy notes to clipboard
                Clipboard.setData(ClipboardData(text: notes));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notes copied to clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

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
                maxLines: 2,
                minLines: 1,
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
                          text: 'Paste Link',
                          onPressed: _pasteFromClipboard,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: _isProcessing ? 'Processing...' : 'Generate Notes',
                          onPressed: _isProcessing ? null : _processYouTubeVideo,
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
                            text: 'Paste Link',
                            onPressed: _pasteFromClipboard,
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: _isProcessing ? 'Processing...' : 'Generate Notes',
                            onPressed: _isProcessing ? null : _processYouTubeVideo,
                            backgroundColor: Theme.of(context).primaryColor,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Processing YouTube video...\nThis may take a few moments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
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