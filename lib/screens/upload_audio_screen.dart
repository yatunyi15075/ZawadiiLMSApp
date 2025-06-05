import 'package:flutter/material.dart';
import 'dart:io';
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
  final TextEditingController _filePathController = TextEditingController();
  
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Arabic',
  ];

  Future<void> _setAudioFile() async {
    try {
      setState(() {
        _isUploading = true;
      });

      String filePath = _filePathController.text.trim();
      
      if (filePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a file path'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if file exists
      File file = File(filePath);
      bool exists = await file.exists();
      
      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File does not exist at the specified path'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Extract filename from path
      String fileName = filePath.split('/').last;
      
      setState(() {
        _selectedFile = file;
        _fileName = fileName;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio file selected: $fileName'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Show error message
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

  void _generateNote() {
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

    // TODO: Implement generate note functionality with selected file and language
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating note for $_fileName in $_selectedLanguage...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _filePathController.dispose();
    super.dispose();
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight - 32,
            ),
            child: Column(
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
                          hint: const Text('Note language'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                          },
                          items: _languages
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // File Path Input
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
                      const Icon(Icons.folder, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _filePathController,
                          decoration: const InputDecoration(
                            hintText: 'Enter audio file path (e.g., /path/to/audio.mp3)',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _setAudioFile(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Set File Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isUploading 
                        ? 'Setting file...' 
                        : _selectedFile != null 
                            ? 'Change audio file' 
                            : 'Set audio file',
                    onPressed: _isUploading ? null : _setAudioFile,
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
                              _filePathController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Generate Note Button
                Center(
                  child: TextButton(
                    onPressed: _generateNote,
                    child: const Text(
                      'Generate note',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}