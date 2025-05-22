import 'package:flutter/material.dart';
import 'dart:async';

class RecordConversationScreen extends StatefulWidget {
  const RecordConversationScreen({Key? key}) : super(key: key);

  @override
  _RecordConversationScreenState createState() =>
      _RecordConversationScreenState();
}

class _RecordConversationScreenState extends State<RecordConversationScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  String? _selectedLanguage;
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Arabic',
    'Japanese',
    'Korean',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

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
        title: Text(
          'Record Conversation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Record Audio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Record a conversation, lecture, or audio to generate notes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Language selection
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, color: Colors.grey[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      hint: Text(
                        'Select recording language',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      isExpanded: true,
                      underline: SizedBox(),
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
            SizedBox(height: 50),

            // Recording visualization and timer
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red[50] : Colors.grey[100],
                border: Border.all(
                  color: _isRecording ? Colors.red[300]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _animation.value : 1.0,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : Colors.grey[400],
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            // Recording duration
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _isRecording ? Colors.red : Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _isRecording
                  ? (_isPaused ? 'Recording Paused' : 'Recording...')
                  : 'Tap to start recording',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 50),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Stop button
                if (_isRecording || _recordingDuration > Duration.zero)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: IconButton(
                      onPressed: _stopRecording,
                      icon: Icon(
                        Icons.stop,
                        color: Colors.grey[700],
                        size: 30,
                      ),
                    ),
                  ),

                // Record/Pause button
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.orange[500],
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Colors.orange)
                            .withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleRecording,
                    icon: Icon(
                      _isRecording
                          ? (_isPaused ? Icons.play_arrow : Icons.pause)
                          : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                // Delete button (only show if there's a recording)
                if (_recordingDuration > Duration.zero)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: IconButton(
                      onPressed: _deleteRecording,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.grey[700],
                        size: 30,
                      ),
                    ),
                  ),
              ],
            ),
            
            Spacer(),

            // Generate notes button
            if (_recordingDuration > Duration.zero && !_isRecording)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _generateNotesFromRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[500],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_add, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Generate Notes from Recording',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() {
    if (!_isRecording) {
      // Start recording
      _startRecording();
    } else {
      // Pause/Resume recording
      _pauseResumeRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordingDuration = Duration.zero;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _recordingDuration = _recordingDuration + Duration(seconds: 1);
        });
      }
    });

    // TODO: Implement actual recording start logic
    print('Recording started');
  }

  void _pauseResumeRecording() {
    setState(() {
      _isPaused = !_isPaused;
    });

    // TODO: Implement actual pause/resume logic
    print(_isPaused ? 'Recording paused' : 'Recording resumed');
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    _timer?.cancel();

    // TODO: Implement actual recording stop logic
    print('Recording stopped');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recording stopped successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteRecording() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Recording'),
          content: Text('Are you sure you want to delete this recording?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _recordingDuration = Duration.zero;
                  _isRecording = false;
                  _isPaused = false;
                });
                _timer?.cancel();
                Navigator.of(context).pop();
                
                // TODO: Implement actual recording deletion logic
                print('Recording deleted');
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _generateNotesFromRecording() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a language first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange[500]),
              SizedBox(height: 16),
              Text('Generating notes from recording...'),
            ],
          ),
        );
      },
    );

    try {
      // TODO: Implement actual note generation from recording
      await Future.delayed(Duration(seconds: 3)); // Simulate processing

      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pop(); // Go back to home

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notes generated successfully from recording!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate notes. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}