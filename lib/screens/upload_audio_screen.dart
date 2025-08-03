import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_button.dart';

class UploadAudioScreen extends StatefulWidget {
  const UploadAudioScreen({Key? key}) : super(key: key);

  @override
  _UploadAudioScreenState createState() => _UploadAudioScreenState();
}

class _UploadAudioScreenState extends State<UploadAudioScreen> {
  String? _selectedLanguage;
  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  bool _isProcessing = false;
  
  final List<String> _languages = [
    'Auto',
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Arabic',
  ];

  // Base URL for your API - updated to match notifications
  static const String baseUrl = 'https://zawadi-project.onrender.com';

  // Get stored authentication token (same as notifications)
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _pickAudioFile() async {
    try {
      setState(() {
        _isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        setState(() {
          _selectedFile = file;
          _fileName = fileName;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file selected: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _processAudioFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an audio file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get token using the same method as notifications
      final token = await _getAuthToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No authentication token found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Get userId and currentFolderId from SharedPreferences
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
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/audio/upload'),
      );

      // Add headers with token authentication (same as notifications)
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          _selectedFile!.path,
        ),
      );

      // Add other fields
      request.fields['dialect'] = _selectedLanguage!;
      request.fields['userId'] = userId;
      
      if (currentFolderId != null) {
        request.fields['folderId'] = currentFolderId;
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Handle response similar to your React code
        if (data['notes'] != null) {
          // If notes are directly available
          _handleSuccessfulProcessing(data);
        } else if (data['fileUri'] != null) {
          // If we need to transcribe
          await _transcribeAudio(data['fileUri'], userId, currentFolderId, token);
        } else {
          _showNotesDialog('No notes or transcript available.');
        }

      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to process uploaded audio: ${response.statusCode}');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _transcribeAudio(String fileUri, String userId, String? currentFolderId, String token) async {
    try {
      Map<String, dynamic> requestBody = {
        'fileUri': fileUri,
        'userId': userId,
        'dialect': _selectedLanguage!,
      };

      if (currentFolderId != null) {
        requestBody['folderId'] = currentFolderId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/audio/transcribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add token authentication
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _handleSuccessfulProcessing(data);
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to transcribe audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSuccessfulProcessing(Map<String, dynamic> data) {
    String notes = data['notes'] ?? data['transcript'] ?? 'No notes generated.';
    
    if (data['noteId'] != null) {
      // Navigate to the specific note view
      Navigator.pushNamed(
        context, 
        '/notes/${data['noteId']}',
        arguments: {
          'notes': notes,
          'noteId': data['noteId'],
        },
      );
    } else {
      // Show notes in a dialog
      _showNotesDialog(notes);
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
                // Clipboard.setData(ClipboardData(text: notes));
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Audio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              // Language Selection
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        hint: const Text(
                          'Note language',
                          style: TextStyle(color: Colors.black), // Fixed text color
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.black), // Fixed dropdown text color
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        },
                        items: _languages
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(color: Colors.black), // Fixed menu item text color
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // File Selection Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isUploading 
                      ? 'Selecting file...' 
                      : _selectedFile != null 
                          ? 'Change audio file' 
                          : 'Select audio file',
                  onPressed: _isUploading ? null : _pickAudioFile,
                ),
              ),
              
              // Selected File Display
              if (_selectedFile != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audiotrack, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected file:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _fileName ?? 'Unknown file',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _fileName = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Processing indicator
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Processing audio file...\nThis may take a few moments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
              
              // Add some spacing before the button
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
              ),
              
              // Generate Note Button
              Center(
                child: TextButton(
                  onPressed: _isProcessing ? null : _processAudioFile,
                  child: Text(
                    _isProcessing ? 'Processing...' : 'Generate note',
                    style: TextStyle(
                      color: _isProcessing ? Colors.grey : Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              
              // Add bottom padding to ensure the button is not too close to the bottom
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}