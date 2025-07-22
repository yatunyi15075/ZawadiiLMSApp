import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FlashcardsTab extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  
  const FlashcardsTab({
    Key? key, 
    required this.noteId,
    required this.noteTitle,
  }) : super(key: key);

  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  // Professional color scheme
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color flashcardColor = Color(0xFF7C3AED);

  List<Map<String, dynamic>> flashcards = [];
  bool isLoading = false;
  bool isGenerating = false;
  String? error;
  int currentCardIndex = 0;
  bool isFlipped = false;

  @override
  void initState() {
    super.initState();
    fetchFlashcards();
  }

  Future<void> fetchFlashcards() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://zawadi-lms.onrender.com/api/flashcards/${widget.noteId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          flashcards = data.map((flashcard) => {
            'id': flashcard['id'],
            'front': flashcard['front'],
            'back': flashcard['back'],
          }).toList();
          currentCardIndex = 0;
          isFlipped = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          flashcards = [];
        });
      } else {
        throw Exception('Failed to fetch flashcards');
      }
    } catch (e) {
      setState(() {
        error = 'Error loading flashcards: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> generateFlashcards() async {
    setState(() {
      isGenerating = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/flashcards/${widget.noteId}/generate'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchFlashcards();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcards generated successfully!'),
            backgroundColor: flashcardColor,
          ),
        );
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to generate flashcards');
      }
    } catch (e) {
      setState(() {
        error = 'Error generating flashcards: $e';
      });
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  void nextCard() {
    if (flashcards.isNotEmpty) {
      setState(() {
        currentCardIndex = (currentCardIndex + 1) % flashcards.length;
        isFlipped = false;
      });
    }
  }

  void previousCard() {
    if (flashcards.isNotEmpty) {
      setState(() {
        currentCardIndex = (currentCardIndex - 1 + flashcards.length) % flashcards.length;
        isFlipped = false;
      });
    }
  }

  void flipCard() {
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: flashcardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: flashcardColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flashcards',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        widget.noteTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${flashcards.length} cards',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Error Display
          if (error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: flashcardColor),
                  )
                : flashcards.isEmpty
                    ? _buildEmptyState()
                    : _buildFlashcardView(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: flashcardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.style_outlined,
              size: 48,
              color: flashcardColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Flashcards Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate flashcards based on your note content\nto help you memorize key concepts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isGenerating ? null : generateFlashcards,
            style: ElevatedButton.styleFrom(
              backgroundColor: flashcardColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isGenerating
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Generating...'),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text('Generate Flashcards'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardView() {
    final currentCard = flashcards[currentCardIndex];
    
    return Column(
      children: [
        // Generate New Flashcards Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton(
            onPressed: isGenerating ? null : generateFlashcards,
            style: ElevatedButton.styleFrom(
              backgroundColor: flashcardColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isGenerating
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Generating New Flashcards...'),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('Generate New Flashcards'),
                    ],
                  ),
          ),
        ),

        // Flashcard
        Expanded(
          child: GestureDetector(
            onTap: flipCard,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isFlipped ? flashcardColor.withOpacity(0.1) : cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFlipped ? Icons.lightbulb : Icons.help_outline,
                      color: flashcardColor,
                      size: 32,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isFlipped ? currentCard['back'] : currentCard['front'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isFlipped ? 'Tap to see question' : 'Tap to see answer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Navigation Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: flashcards.length > 1 ? previousCard : null,
              icon: const Icon(Icons.chevron_left),
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: flashcardColor.withOpacity(0.1),
                foregroundColor: flashcardColor,
                padding: const EdgeInsets.all(12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: flashcardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentCardIndex + 1} / ${flashcards.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: flashcardColor,
                ),
              ),
            ),
            IconButton(
              onPressed: flashcards.length > 1 ? nextCard : null,
              icon: const Icon(Icons.chevron_right),
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: flashcardColor.withOpacity(0.1),
                foregroundColor: flashcardColor,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}