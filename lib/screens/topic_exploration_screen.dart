import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_button.dart';

class TopicExplorationScreen extends StatefulWidget {
  const TopicExplorationScreen({Key? key}) : super(key: key);

  @override
  _TopicExplorationScreenState createState() => _TopicExplorationScreenState();
}

class _TopicExplorationScreenState extends State<TopicExplorationScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _topicCategories = [
    {'name': 'Computer Science', 'icon': Icons.computer, 'color': const Color(0xFF6C63FF)},
    {'name': 'Nursing', 'icon': Icons.local_hospital, 'color': const Color(0xFF4ECDC4)},
    {'name': 'Business', 'icon': Icons.business_center, 'color': const Color(0xFF45B7D1)},
    {'name': 'Mathematics', 'icon': Icons.calculate, 'color': const Color(0xFFFF6B6B)},
    {'name': 'Biology', 'icon': Icons.biotech, 'color': const Color(0xFF4ECDC4)},
    {'name': 'Physics', 'icon': Icons.science, 'color': const Color(0xFF96CEB4)},
  ];

  final TextEditingController _topicController = TextEditingController();
  String? _selectedTopic;
  bool _isLoading = false;
  String _selectedDialect = 'en-US';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  Future<void> _handleGenerateNotes() async {
    if (_selectedTopic == null && _topicController.text.isEmpty) {
      _showSnackBar('Please select or enter a topic', isError: true);
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
        throw Exception('User ID is required but missing!');
      }

      final topic = _selectedTopic ?? _topicController.text;

      final response = await http.post(
        Uri.parse('$baseUrl/api/notes/generate-notes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic.isEmpty ? 'Generate study notes' : topic,
          'dialect': _selectedDialect,
          'folderId': currentFolderId,
          'userId': userId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to generate notes: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final notes = data['notes'] ?? 'No notes generated.';

      if (data['noteId'] != null) {
        Navigator.pushNamed(
          context,
          '/notes/${data['noteId']}',
          arguments: {
            'notes': notes,
            'noteId': data['noteId'],
            'folderId': data['folderId'],
          },
        );
      } else {
        _showNotesDialog(notes);
      }
    } catch (error) {
      print('Error generating notes: $error');
      _showSnackBar('Failed to generate notes: $error', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNotesDialog(String notes) {
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
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 16)),
                    ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Feynman AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3436),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'What topic do you want\nto explore today?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Language Selection
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: Color(0xFF6C63FF)),
                        const SizedBox(width: 12),
                        const Text(
                          'Language:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedDialect,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                              DropdownMenuItem(value: 'en-GB', child: Text('English (UK)')),
                              DropdownMenuItem(value: 'es-ES', child: Text('Spanish')),
                              DropdownMenuItem(value: 'fr-FR', child: Text('French')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDialect = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Topic Categories
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Popular Topics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _topicCategories.length,
                    itemBuilder: (context, index) {
                      final topic = _topicCategories[index];
                      final isSelected = _selectedTopic == topic['name'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTopic = isSelected ? null : topic['name'];
                            if (!isSelected) {
                              _topicController.clear();
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? topic['color'] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? topic['color'] : Colors.grey.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                  ? topic['color'].withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                                blurRadius: isSelected ? 12 : 6,
                                offset: Offset(0, isSelected ? 6 : 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                topic['icon'],
                                size: 32,
                                color: isSelected ? Colors.white : topic['color'],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                topic['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF2D3436),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Custom Topic Input
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Or enter a custom topic',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        hintText: 'Enter a topic you want to explore...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _selectedTopic = null;
                          });
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_selectedTopic != null || _topicController.text.isNotEmpty) && !_isLoading
                          ? _handleGenerateNotes
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: const Color(0xFF6C63FF).withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Start Exploring',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}