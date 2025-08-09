import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuizzesTab extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  final String? userId; // Add userId parameter to match web app functionality
  
  const QuizzesTab({
    Key? key, 
    required this.noteId,
    required this.noteTitle,
    this.userId, // Make it optional for now
  }) : super(key: key);

  @override
  State<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<QuizzesTab> {
  // Professional color scheme
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color quizColor = Color(0xFF059669);
  static const Color correctColor = Color(0xFF059669);
  static const Color incorrectColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFF59E0B);

  List<Map<String, dynamic>> quizzes = [];
  bool isLoading = false;
  bool isGenerating = false;
  bool isSavingResult = false; // Add saving state
  String? error;
  String? actualUserId; // Store the actual user ID
  
  // Quiz interaction state
  Map<int, String?> userAnswers = {};
  bool showResults = false;
  Map<String, dynamic>? score;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    fetchQuizzes();
  }

  // Get the actual user ID from SharedPreferences
  Future<void> _initializeUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedUserId = prefs.getString('userId');
      
      setState(() {
        // Use the passed userId first, then stored userId, then fallback
        actualUserId = widget.userId ?? storedUserId ?? 'flutter_user';
      });
      
      print('Initialized user ID: $actualUserId'); // Debug log
    } catch (e) {
      print('Error getting user ID: $e');
      setState(() {
        actualUserId = widget.userId ?? 'flutter_user';
      });
    }
  }

  Future<void> fetchQuizzes() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://zawadi-lms.onrender.com/api/quizzes/${widget.noteId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          quizzes = data.map((quiz) => {
            'id': quiz['id'],
            'question': quiz['question'],
            'options': quiz['options'] is String 
                ? json.decode(quiz['options']) 
                : quiz['options'],
            'correctAnswer': quiz['correctAnswer'],
          }).toList();
          
          // Initialize user answers with null values
          userAnswers = {};
          for (int i = 0; i < quizzes.length; i++) {
            userAnswers[i] = null;
          }
          showResults = false;
          score = null;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          quizzes = [];
        });
      } else {
        throw Exception('Failed to fetch quizzes');
      }
    } catch (e) {
      setState(() {
        error = 'Error loading quizzes: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> generateQuizzes() async {
    setState(() {
      isGenerating = true;
      error = null;
      showResults = false;
    });

    try {
      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/quizzes/${widget.noteId}/generate'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchQuizzes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quizzes generated successfully!'),
              backgroundColor: quizColor,
            ),
          );
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to generate quizzes');
      }
    } catch (e) {
      setState(() {
        error = 'Error generating quizzes: $e';
      });
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  void handleAnswerSelect(int questionIndex, String optionKey) {
    if (!showResults) {
      setState(() {
        userAnswers[questionIndex] = optionKey;
      });
    }
  }

  // Fixed saveQuizResult function - now uses the proper user ID
  Future<void> saveQuizResult(Map<String, dynamic> scoreData) async {
    setState(() {
      isSavingResult = true;
    });

    try {
      // Ensure we have a user ID before saving
      if (actualUserId == null) {
        await _initializeUserId();
      }

      // Use the first quiz's ID as representative of the quiz session
      // or use noteId if your backend expects it that way
      final quizId = quizzes.isNotEmpty ? quizzes[0]['id'] : null;
      
      if (quizId == null) {
        throw Exception('No quiz ID available');
      }

      final requestBody = {
        'userId': actualUserId ?? 'flutter_user', // Use the actual user ID
        'quizId': quizId,
        'score': scoreData['percentage'].toDouble(),
        'totalQuestions': scoreData['total'],
        'correctAnswers': scoreData['correct'],
      };
      
      print('Saving quiz result with userId: ${actualUserId}'); // Debug log
      print('Saving quiz result: $requestBody'); // Debug log

      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/quizzes/${widget.noteId}/results'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Save response status: ${response.statusCode}'); // Debug log
      print('Save response body: ${response.body}'); // Debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Quiz Score Saved 🎉'),
                ],
              ),
              backgroundColor: quizColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to save quiz score');
      }
    } catch (e) {
      print('Error saving quiz result: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Failed to save quiz score: ${e.toString()}'),
              ],
            ),
            backgroundColor: incorrectColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        isSavingResult = false;
      });
    }
  }

  void checkAnswers() async {
    int correctCount = 0;
    
    for (int i = 0; i < quizzes.length; i++) {
      if (userAnswers[i] == quizzes[i]['correctAnswer']) {
        correctCount++;
      }
    }
    
    final scoreData = {
      'correct': correctCount,
      'total': quizzes.length,
      'percentage': ((correctCount / quizzes.length) * 100).round(),
    };
    
    setState(() {
      score = scoreData;
      showResults = true;
    });

    // Save quiz result to backend
    if (quizzes.isNotEmpty) {
      await saveQuizResult(scoreData);
    }
  }

  void resetQuiz() {
    setState(() {
      // Initialize with null values
      userAnswers = {};
      for (int i = 0; i < quizzes.length; i++) {
        userAnswers[i] = null;
      }
      showResults = false;
      score = null;
    });
  }

  Color getQuestionCardColor(int index) {
    if (!showResults) return cardColor;
    
    final correctAnswer = quizzes[index]['correctAnswer'];
    final userAnswer = userAnswers[index];
    
    if (userAnswer == correctAnswer) {
      return Colors.green.shade50;
    } else if (userAnswer != null && userAnswer != correctAnswer) {
      return Colors.red.shade50;
    }
    return cardColor;
  }

  Border getQuestionCardBorder(int index) {
    if (!showResults) return Border.all(color: Colors.grey.shade200);
    
    final correctAnswer = quizzes[index]['correctAnswer'];
    final userAnswer = userAnswers[index];
    
    if (userAnswer == correctAnswer) {
      return Border.all(color: Colors.green.shade300, width: 2);
    } else if (userAnswer != null && userAnswer != correctAnswer) {
      return Border.all(color: Colors.red.shade300, width: 2);
    }
    return Border.all(color: Colors.grey.shade200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
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
                      color: quizColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: quizColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Practice Quizzes',
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
                  // Add saving indicator
                  if (isSavingResult)
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(quizColor),
                        ),
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
                      child: CircularProgressIndicator(color: quizColor),
                    )
                  : quizzes.isEmpty
                      ? _buildEmptyState()
                      : _buildQuizzesView(),
            ),
          ],
        ),
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
              color: quizColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 48,
              color: quizColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Quizzes Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate quizzes based on your note content\nto test your knowledge.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isGenerating ? null : generateQuizzes,
            style: ElevatedButton.styleFrom(
              backgroundColor: quizColor,
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
                      Text('Generate Quizzes'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesView() {
    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          child: Column(
            children: [
              // Results Section (shown at top when available)
              if (showResults && score != null) _buildResultsSection(),
              
              // Quiz Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test your knowledge with these questions. Select the best answer for each question.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quizzes.length} ${quizzes.length == 1 ? 'question' : 'questions'} | ${showResults ? 'Results shown' : 'Results hidden'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Questions List
              ...quizzes.asMap().entries.map((entry) {
                return _buildQuestionCard(entry.key);
              }).toList(),

              // Add bottom padding to prevent content from being hidden behind bottom action bar
              if (!showResults) const SizedBox(height: 100),
            ],
          ),
        ),

        // Bottom Action Bar (only shown when not showing results)
        if (!showResults && quizzes.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final percentage = score!['percentage'];
    Color bgColor, borderColor, iconColor;
    IconData icon;
    String message;

    if (percentage >= 80) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      iconColor = Colors.green.shade600;
      icon = Icons.check_circle;
      message = 'Great job!';
    } else if (percentage >= 60) {
      bgColor = Colors.yellow.shade50;
      borderColor = Colors.yellow.shade200;
      iconColor = Colors.yellow.shade600;
      icon = Icons.warning;
      message = 'Good effort, keep studying!';
    } else {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      iconColor = Colors.red.shade600;
      icon = Icons.cancel;
      message = 'Keep practicing to improve your score!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Quiz Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Show saving indicator if still saving
              if (isSavingResult)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(quizColor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You scored ${score!['correct']}/${score!['total']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: percentage >= 80 ? correctColor : 
                         percentage >= 60 ? warningColor : incorrectColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: resetQuiz,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isGenerating ? null : generateQuizzes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isGenerating ? 'Generating...' : 'New Quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final quiz = quizzes[index];
    final options = quiz['options'] as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: getQuestionCardColor(index),
        borderRadius: BorderRadius.circular(12),
        border: getQuestionCardBorder(index),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Question ${index + 1} of ${quizzes.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Question text
            Text(
              quiz['question'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Options
            ...options.entries.map((entry) {
              return _buildOptionTile(index, entry.key, entry.value.toString());
            }).toList(),
            
            // Result feedback (shown after checking answers)
            if (showResults) _buildQuestionResult(index),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(int questionIndex, String optionKey, String optionValue) {
    final isSelected = userAnswers[questionIndex] == optionKey;
    final correctAnswer = quizzes[questionIndex]['correctAnswer'];
    
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    
    if (showResults) {
      if (optionKey == correctAnswer) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
      } else if (isSelected && optionKey != correctAnswer) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
      }
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade300;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => handleAnswerSelect(questionIndex, optionKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: optionKey,
                groupValue: userAnswers[questionIndex],
                onChanged: showResults ? null : (value) {
                  if (value != null) {
                    handleAnswerSelect(questionIndex, value);
                  }
                },
                activeColor: primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '$optionKey: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: optionValue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionResult(int index) {
    final userAnswer = userAnswers[index];
    final correctAnswer = quizzes[index]['correctAnswer'];
    final isCorrect = userAnswer == correctAnswer;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green.shade600 : Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCorrect 
                  ? 'Correct!' 
                  : 'Incorrect. The correct answer is $correctAnswer.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final answeredCount = userAnswers.values.where((answer) => answer != null && answer!.isNotEmpty).length;
    final allAnswered = answeredCount == quizzes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$answeredCount of ${quizzes.length} questions answered',
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: (allAnswered && !isSavingResult) ? checkAnswers : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSavingResult 
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
                      Text('Saving...'),
                    ],
                  )
                : const Text(
                    'Check Answers',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}