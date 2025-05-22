import 'package:flutter/material.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  Duration _recordingDuration = const Duration(seconds: 0);
  bool _isRecording = false;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      // Add actual recording logic here
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      // Add actual stop recording logic here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Audio waveform representation (simplified)
            Container(
              width: 300,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Feynman AI',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '00:00:${_recordingDuration.inSeconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 40),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 50),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic,
                    color: _isRecording ? Colors.red : Colors.blue,
                    size: 60,
                  ),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                const SizedBox(width: 50),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green, size: 40),
                  onPressed: () {
                    // Add logic to save/confirm recording
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}