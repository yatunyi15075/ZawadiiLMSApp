import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  Duration _recordingDuration = const Duration(seconds: 0);
  bool _isRecording = false;
  bool _isLoading = false;
  bool _hasRecording = false;
  String _selectedDialect = 'Auto detect';
  
  FlutterSoundRecorder? _audioRecorder;
  String? _audioPath;
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  static const String baseUrl = 'https://zawadi-lms.onrender.com';
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 120);

  final List<Map<String, String>> _languages = [
    {'code': 'Auto detect', 'name': 'Auto detect', 'flag': '🌐'},
    {'code': 'English', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'French', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'Spanish', 'name': 'Spanish', 'flag': '🇪🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    try {
      await _audioRecorder!.openRecorder();
      print('Recorder initialized successfully');
    } catch (e) {
      print('Error initializing recorder: $e');
      _showSnackBar('Failed to initialize recorder. Please check permissions.', isError: true);
    }
  }

  @override
  void dispose() {
    _audioRecorder?.closeRecorder();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> _checkPermissions() async {
    // Request multiple permissions that might be needed
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
    
    // Check if microphone permission is granted (most important)
    bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    
    if (!micGranted) {
      // Try to get permanent denial status and guide user
      if (statuses[Permission.microphone]?.isPermanentlyDenied ?? false) {
        _showSnackBar('Microphone permission permanently denied. Please enable it in settings.', isError: true);
        await openAppSettings();
      } else {
        _showSnackBar('Microphone permission is required to record audio.', isError: true);
      }
      return false;
    }
    
    return true;
  }

  Future<void> _startRecording() async {
    try {
      if (!await _checkPermissions()) {
        return;
      }

      // Get a proper directory for recording
      Directory? directory;
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        // Fallback to temporary directory if documents directory fails
        directory = await getTemporaryDirectory();
      }
      
      final String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      final String filePath = '${directory.path}/$fileName';
      
      print('Starting recording to: $filePath');
      
      // Start recording with proper codec and settings
      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV, // Use WAV format
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1, // Mono recording for smaller file size
      );
      
      setState(() {
        _isRecording = true;
        _audioPath = filePath;
        _recordingDuration = const Duration(seconds: 0);
        _hasRecording = false;
      });

      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      _startTimer();
      
      print('Recording started successfully');
    } catch (e) {
      print('Error starting recording: $e');
      _showSnackBar('Failed to start recording: ${e.toString()}', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder!.stopRecorder();
      _pulseController.stop();
      _waveController.stop();
      
      print('Recording stopped. Path: $path');
      
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('Audio file size: $fileSize bytes');
          
          // Check if file has meaningful content (more than just headers)
          if (fileSize > 1000) { // At least 1KB to ensure it's not just headers
            setState(() {
              _isRecording = false;
              _audioPath = path;
              _hasRecording = true;
            });
            _showSnackBar('Recording completed successfully!');
          } else {
            // File is too small, likely just headers
            _showSnackBar('Recording failed - audio file is too small. Please try recording for longer.', isError: true);
            await file.delete(); // Clean up the empty file
            _resetRecording();
          }
        } else {
          throw Exception('Audio file was not created');
        }
      } else {
        throw Exception('Failed to get recording path');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _showSnackBar('Failed to stop recording: ${e.toString()}', isError: true);
      setState(() {
        _isRecording = false;
        _hasRecording = false;
        _audioPath = null;
      });
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _handleRecordedAudioSubmit() async {
    if (_audioPath == null) {
      _showSnackBar('Please record audio first.', isError: true);
      return;
    }

    final audioFile = File(_audioPath!);
    if (!await audioFile.exists()) {
      _showSnackBar('Audio file not found. Please record again.', isError: true);
      return;
    }

    final fileSize = await audioFile.length();
    print('Submitting audio file: $_audioPath (${fileSize} bytes)');

    // Check file size before submitting
    if (fileSize < 1000) {
      _showSnackBar('Audio file is too small. Please record for a longer duration.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final currentFolderId = prefs.getString('currentFolderId');

      if (userId == null) {
        _showSnackBar('User not authenticated. Please log in again.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Preparing multipart request...');
      print('User ID: $userId');
      print('Folder ID: $currentFolderId');
      print('Dialect: $_selectedDialect');
      print('File path: $_audioPath');
      print('File size: $fileSize bytes');

      // Create multipart request
      final uri = Uri.parse('$baseUrl/api/audio/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add the audio file - CRITICAL: Use 'audio' as field name to match backend
      final multipartFile = await http.MultipartFile.fromPath(
        'audio', // This MUST match your backend expectation
        _audioPath!,
        filename: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      
      request.files.add(multipartFile);

      // Add form fields
      request.fields['dialect'] = _selectedDialect;
      request.fields['userId'] = userId;
      
      if (currentFolderId != null && currentFolderId.isNotEmpty) {
        request.fields['folderId'] = currentFolderId;
      }

      // Add headers if needed
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('Sending request...');
      print('URL: ${request.url}');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)')}');

      // Send request with timeout
      final streamedResponse = await request.send().timeout(requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Response received!');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      // Handle different response codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _handleSuccessfulProcessing(data);
      } else {
        String errorMessage = 'Request failed with status ${response.statusCode}';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          // Use default error message if JSON parsing fails
        }
        
        _showSnackBar(errorMessage, isError: true);
      }
      
    } catch (error) {
      print('Error processing recorded audio: $error');
      String userFriendlyMessage = 'Failed to process recorded audio.';
      
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('timeout')) {
        userFriendlyMessage = 'Request timed out. Please check your internet connection and try again.';
      } else if (errorString.contains('connection')) {
        userFriendlyMessage = 'Connection failed. Please check your internet connection and try again.';
      } else if (errorString.contains('socket')) {
        userFriendlyMessage = 'Network error occurred. Please try again.';
      }
      
      _showSnackBar(userFriendlyMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSuccessfulProcessing(Map<String, dynamic> data) {
    String notes = data['notes'] ?? data['transcript'] ?? 'No notes generated.';
    
    _showSnackBar('Audio processed successfully!');
    
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
      _showNotesResult(notes, null);
    }
  }

  void _showNotesResult(String notes, String? noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Generated Notes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      notes,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      if (noteId != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushNamed(
                                context,
                                '/notes/$noteId',
                                arguments: {
                                  'notes': notes,
                                  'noteId': noteId,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('View Note'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  void _resetRecording() {
    setState(() {
      _hasRecording = false;
      _audioPath = null;
      _recordingDuration = const Duration(seconds: 0);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildWaveformVisualizer() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Container(
          width: 300,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.1),
                const Color(0xFF764ba2).withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isRecording 
                ? const Color(0xFF667eea).withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isRecording)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(12, (index) {
                    final height = 20.0 + (40 * _waveAnimation.value * 
                      (0.5 + 0.5 * (index % 3 + 1) / 3));
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 4,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              
              if (!_isRecording)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasRecording ? Icons.check_circle : Icons.mic_none,
                      size: 48,
                      color: _hasRecording 
                        ? Colors.green 
                        : const Color(0xFF667eea).withOpacity(0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasRecording 
                        ? 'Recording Complete!'
                        : 'Feynman AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _hasRecording 
                          ? Colors.green 
                          : const Color(0xFF667eea).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Voice Recording',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3436),
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedDialect,
            onSelected: (value) {
              setState(() {
                _selectedDialect = value;
              });
            },
            itemBuilder: (context) => _languages.map((lang) {
              return PopupMenuItem(
                value: lang['code'],
                child: Row(
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(lang['name']!),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _languages.firstWhere((lang) => lang['code'] == _selectedDialect)['flag']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Spacer(),
              
              _buildWaveformVisualizer(),
              
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              if (_isLoading)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing your recording...\nThis may take a moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF636e72),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _hasRecording ? Icons.refresh : Icons.close,
                      color: Colors.red,
                      onPressed: () {
                        if (_hasRecording) {
                          _resetRecording();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      label: _hasRecording ? 'Reset' : 'Cancel',
                    ),
                    
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: _buildControlButton(
                            icon: _isRecording ? Icons.stop : Icons.mic,
                            color: _isRecording ? Colors.red : const Color(0xFF667eea),
                            onPressed: _isRecording ? _stopRecording : _startRecording,
                            label: _isRecording ? 'Stop' : 'Record',
                            isLarge: true,
                          ),
                        );
                      },
                    ),
                    
                    _buildControlButton(
                      icon: Icons.send,
                      color: Colors.green,
                      onPressed: _hasRecording ? _handleRecordedAudioSubmit : null,
                      label: 'Submit',
                    ),
                  ],
                ),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF667eea),
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRecording
                        ? 'Recording in progress. Speak clearly and tap stop when finished.'
                        : _hasRecording
                          ? 'Great! Your recording is ready. Tap submit to generate notes.'
                          : 'Tap the microphone to start recording your voice notes.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF636e72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String label,
    bool isLarge = false,
  }) {
    final size = isLarge ? 72.0 : 56.0;
    final iconSize = isLarge ? 32.0 : 24.0;
    
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onPressed != null ? color : Colors.grey,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: onPressed != null ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: onPressed,
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onPressed != null ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
}