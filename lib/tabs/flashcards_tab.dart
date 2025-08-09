import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

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

class _FlashcardsTabState extends State<FlashcardsTab> with TickerProviderStateMixin {
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
  
  // Animation controller for flip effect
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    fetchFlashcards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
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
          _flipController.reset();
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
        _flipController.reset();
      });
    }
  }

  void previousCard() {
    if (flashcards.isNotEmpty) {
      setState(() {
        currentCardIndex = (currentCardIndex - 1 + flashcards.length) % flashcards.length;
        isFlipped = false;
        _flipController.reset();
      });
    }
  }

  void flipCard() {
    setState(() {
      isFlipped = !isFlipped;
    });
    
    if (isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
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

        // Animated Flashcard with responsive content
        Expanded(
          child: GestureDetector(
            onTap: flipCard,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(
                minHeight: 200,
              ),
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final isShowingFront = _flipAnimation.value < 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAnimation.value * math.pi),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isShowingFront 
                            ? cardColor 
                            : flashcardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(isShowingFront ? 0 : math.pi),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final content = isShowingFront ? currentCard['front'] : currentCard['back'];
                              final isLongContent = content.toString().length > 200;
                              
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                child: isLongContent
                                    ? SingleChildScrollView(
                                        padding: const EdgeInsets.all(24),
                                        child: _buildCardContent(content, isShowingFront),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: _buildCardContent(content, isShowingFront),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

  Widget _buildCardContent(String content, bool isShowingFront) {
    // Calculate dynamic font size based on content length
    double getFontSize(String text) {
      if (text.length > 500) return 14;
      if (text.length > 300) return 15;
      if (text.length > 200) return 16;
      if (text.length > 100) return 17;
      return 18;
    }

    // Determine if content needs scrolling based on estimated height
    final fontSize = getFontSize(content);
    final estimatedLines = (content.length * 0.8) / 40; // Rough estimate
    final estimatedHeight = estimatedLines * fontSize * 1.4;
    final needsScrolling = estimatedHeight > 180; // Adjust threshold as needed

    if (needsScrolling) {
      // For very long content, use a scrollable layout
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Compact icon for scrollable content
                    Icon(
                      isShowingFront ? Icons.help_outline : Icons.lightbulb,
                      color: flashcardColor,
                      size: 24,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Main content with flexible layout
                    Flexible(
                      child: Text(
                        content,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                        softWrap: true,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Instruction text
                    Text(
                      isShowingFront ? 'Swipe to scroll • Tap to see answer' : 'Swipe to scroll • Tap to see question',
                      style: const TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      // For shorter content, use centered layout with flexible sizing
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flexible spacer
                const Flexible(flex: 1, child: SizedBox.shrink()),
                
                // Icon with subtle animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        isShowingFront ? Icons.help_outline : Icons.lightbulb,
                        color: flashcardColor,
                        size: 28,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Content text with flexible constraints
                Flexible(
                  flex: 3,
                  child: Center(
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instruction text
                Text(
                  isShowingFront ? 'Tap to see answer' : 'Tap to see question',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                // Flexible spacer
                const Flexible(flex: 1, child: SizedBox.shrink()),
              ],
            ),
          );
        },
      );
    }
  }
}