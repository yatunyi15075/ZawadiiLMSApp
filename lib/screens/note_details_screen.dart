import 'package:flutter/material.dart';

class NoteDetailsScreen extends StatefulWidget {
  const NoteDetailsScreen({Key? key}) : super(key: key);

  @override
  _NoteDetailsScreenState createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  final TextEditingController _topicController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A note Pressed'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Save note logic
            },
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Topic Title Input
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Topic Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Note Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptionChip('Add to folder', Icons.folder_open),
                _buildOptionChip('Mind Map', Icons.web),
                _buildOptionChip('Text History', Icons.history),
                _buildOptionChip('Translate', Icons.translate),
                _buildOptionChip('Edit Note', Icons.edit),
              ],
            ),
            
            const Spacer(),
            
            // Feynman Test Button
            ElevatedButton(
              onPressed: () {
                // Start Feynman Test logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Start Feynman Test',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, IconData icon) {
    return InkWell(
      onTap: () {
        // Handle chip tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}