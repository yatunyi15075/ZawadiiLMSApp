import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyHistoryScreen extends StatefulWidget {
  final String userId; // Pass the user ID from your authentication system
  final String? noteTitle; // Optional parameter to match the usage in note_screen.dart
  
  const StudyHistoryScreen({
    Key? key, 
    required this.userId,
    this.noteTitle, // Add this optional parameter
  }) : super(key: key);

  @override
  State<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Study data
  List<Quiz> _quizzes = [];
  List<StudySession> _sessions = [];
  StudySummary _summary = StudySummary();
  String _errorMessage = '';

  // Base URL - same as home screen
  static const String _baseUrl = 'https://zawadi-lms.onrender.com';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start with Quizzes tab
    _fetchStudyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get stored authentication token - same as home screen
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Get stored user ID - same as home screen
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Check authentication before making API calls - same as home screen
  Future<bool> _checkAuthentication() async {
    final token = await _getAuthToken();
    final userId = await _getUserId();
    
    if (token == null || userId == null) {
      setState(() {
        _errorMessage = 'Please sign in to view your study history';
        _isLoading = false;
      });
      return false;
    }
    return true;
  }

  // Clear authentication tokens - same as home screen
  Future<void> _clearAuthTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
    } catch (e) {
      print('Error clearing auth tokens: $e');
    }
  }

  Future<void> _fetchStudyData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Check authentication first - same as home screen
      if (!await _checkAuthentication()) {
        return;
      }

      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }
      
      // Debug: Print the userId being sent
      print('Fetching quiz results for userId: $userId');
      
      // Fetch quiz results with authentication headers
      final response = await http.get(
        Uri.parse('$_baseUrl/api/quizzes/results?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add authentication header
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        // Handle empty response
        if (responseBody.isEmpty || responseBody == 'null') {
          print('Empty response received');
          setState(() {
            _quizzes = [];
            _summary = StudySummary();
          });
        } else {
          final dynamic jsonData = json.decode(responseBody);
          
          // Handle case where response might be null or not a list
          if (jsonData == null) {
            print('JSON data is null');
            setState(() {
              _quizzes = [];
              _summary = StudySummary();
            });
            return;
          }
          
          List<dynamic> quizResults;
          if (jsonData is List) {
            quizResults = jsonData;
          } else {
            print('Unexpected response format: ${jsonData.runtimeType}');
            quizResults = [];
          }
        
          // Process quiz results
          _quizzes = quizResults.map((result) {
            return Quiz(
              id: result['id']?.toString() ?? '',
              date: result['createdAt']?.toString() ?? '',
              topic: result['noteTitle']?.toString() ?? 'Unknown Topic',
              correctAnswers: _parseIntSafely(result['correctAnswers']),
              totalQuestions: _parseIntSafely(result['totalQuestions']),
              score: _parseDoubleSafely(result['score']),
              noteId: result['noteId']?.toString() ?? '',
            );
          }).toList();
        
          print('Processed ${_quizzes.length} quizzes');
        
          // Calculate summary
          _summary = _calculateSummary(_quizzes);
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized access - same as home screen
        await _clearAuthTokens();
        setState(() {
          _errorMessage = 'Session expired. Please sign in again.';
        });
        return;
      } else {
        print('Error: HTTP ${response.statusCode} - ${response.reasonPhrase}');
        print('Response body: ${response.body}');
        // Handle error response
        setState(() {
          _quizzes = [];
          _summary = StudySummary();
          _errorMessage = 'Failed to load study history: HTTP ${response.statusCode}';
        });
        
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load study history: HTTP ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      print('Error fetching quiz results: $error');
      setState(() {
        _quizzes = [];
        _summary = StudySummary();
      });
      
      // Handle different types of errors - same as home screen
      if (error.toString().contains('SocketException') || error.toString().contains('TimeoutException')) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load study history. Please try again.';
        });
      }
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to safely parse integers
  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method to safely parse doubles
  double _parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  StudySummary _calculateSummary(List<Quiz> quizzes) {
    if (quizzes.isEmpty) {
      return StudySummary();
    }

    final totalQuizzes = quizzes.length;
    final averageScore = quizzes.fold<double>(0, (sum, quiz) => sum + quiz.score) / totalQuizzes;
    final topicsCovered = quizzes.map((q) => q.topic).toSet().toList();
    final totalStudyTime = quizzes.fold<int>(0, (sum, quiz) => sum + (quiz.totalQuestions * 3));
    
    return StudySummary(
      totalStudyTime: totalStudyTime,
      totalQuizzesTaken: totalQuizzes,
      averageScore: averageScore,
      topicsCovered: topicsCovered,
      strengthAreas: _getStrengthAreas(quizzes),
      improvementAreas: _getImprovementAreas(quizzes),
    );
  }

  List<String> _getStrengthAreas(List<Quiz> quizzes) {
    if (quizzes.isEmpty) return ['N/A'];
    
    Map<String, List<double>> topicScores = {};
    for (var quiz in quizzes) {
      topicScores.putIfAbsent(quiz.topic, () => []).add(quiz.score);
    }
    
    var topicAverages = topicScores.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, average);
    }).toList();
    
    topicAverages.sort((a, b) => b.value.compareTo(a.value));
    return topicAverages.take(2).map((e) => e.key).toList();
  }

  List<String> _getImprovementAreas(List<Quiz> quizzes) {
    if (quizzes.isEmpty) return ['N/A'];
    
    Map<String, List<double>> topicScores = {};
    for (var quiz in quizzes) {
      topicScores.putIfAbsent(quiz.topic, () => []).add(quiz.score);
    }
    
    var topicAverages = topicScores.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, average);
    }).toList();
    
    topicAverages.sort((a, b) => a.value.compareTo(b.value));
    return topicAverages.take(2).map((e) => e.key).toList();
  }

  int _calculatePassingProbability() {
    final averageScore = _summary.averageScore;
    final quizzesTaken = _summary.totalQuizzesTaken;
    
    double baseProbability = averageScore / 100;
    double quizBoost = (quizzesTaken / 10).clamp(0.0, 0.1);
    double probability = (baseProbability + quizBoost).clamp(0.0, 0.99);
    
    return (probability * 100).round();
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE, MMM d, y').format(date);
    } catch (e) {
      print('Error parsing date: $dateString, error: $e');
      return 'Unknown date';
    }
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if authentication failed or other errors
    if (_errorMessage.isNotEmpty && !_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.noteTitle ?? 'Study History'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchStudyData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.noteTitle ?? 'Study History'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteTitle ?? 'Study History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _fetchStudyData();
                  break;
                case 'print':
                  // Implement print functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Print functionality would be implemented here')),
                  );
                  break;
                case 'download':
                  // Implement download functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download functionality would be implemented here')),
                  );
                  break;
                case 'share':
                  // Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share functionality would be implemented here')),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'refresh', child: Row(children: [Icon(Icons.refresh), SizedBox(width: 8), Text('Refresh')])),
              const PopupMenuItem(value: 'print', child: Row(children: [Icon(Icons.print), SizedBox(width: 8), Text('Print')])),
              const PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download), SizedBox(width: 8), Text('Download')])),
              const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Share')])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Section - FIXED FOR RESPONSIVE DESIGN
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Study Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // RESPONSIVE LAYOUT: Stack vertically on small screens, horizontally on larger ones
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Small screens - Stack vertically
                      return Column(
                        children: [
                          _buildSummaryCard('Study Time', _formatDuration(_summary.totalStudyTime), 'Estimated based on quiz length', Icons.schedule, Colors.blue),
                          const SizedBox(height: 8),
                          _buildSummaryCard('Quizzes', '${_summary.totalQuizzesTaken} completed', 'Avg. score: ${_summary.averageScore.toStringAsFixed(1)}%', Icons.check, Colors.green),
                          const SizedBox(height: 8),
                          _buildPerformanceCard(),
                        ],
                      );
                    } else {
                      // Larger screens - Keep horizontal layout
                      return Row(
                        children: [
                          Expanded(child: _buildSummaryCard('Study Time', _formatDuration(_summary.totalStudyTime), 'Estimated based on quiz length', Icons.schedule, Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('Quizzes', '${_summary.totalQuizzesTaken} completed', 'Avg. score: ${_summary.averageScore.toStringAsFixed(1)}%', Icons.check, Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPerformanceCard()),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: Colors.blue.shade500,
              tabs: const [
                Tab(icon: Icon(Icons.calendar_today), text: 'Sessions'),
                Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSessionsTab(),
                _buildQuizzesTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, MaterialColor color) {
    return Container(
      width: double.infinity, // Ensure full width usage
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color[700]),
              const SizedBox(width: 4),
              Flexible( // FIXED: Use Flexible to prevent text overflow
                child: Text(
                  title, 
                  style: TextStyle(color: color[700], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis, // FIXED: Prevent overflow
          ),
          Text(
            subtitle, 
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            overflow: TextOverflow.ellipsis, // FIXED: Prevent overflow
            maxLines: 2, // Allow up to 2 lines for subtitle
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      width: double.infinity, // Ensure full width usage
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 16, color: Colors.purple[700]),
              const SizedBox(width: 4),
              Flexible( // FIXED: Use Flexible to prevent overflow
                child: Text(
                  'Performance', 
                  style: TextStyle(color: Colors.purple[700], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // FIXED: Made RichText responsive with proper text wrapping
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 10),
              children: [
                TextSpan(
                  text: 'Strengths: ', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[600])
                ),
                TextSpan(
                  text: _summary.strengthAreas.join(', '), 
                  style: const TextStyle(color: Colors.black)
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 10),
              children: [
                TextSpan(
                  text: 'Improve: ', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[500])
                ),
                TextSpan(
                  text: _summary.improvementAreas.join(', '), 
                  style: const TextStyle(color: Colors.black)
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No study sessions yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Text('Your study sessions will appear here once you start tracking them.', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.shade50,
                        child: Column( // FIXED: Changed from Row to Column for better responsive layout
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatDate(session.date), 
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${session.startTime} - ${session.endTime}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(_formatDuration(session.duration), style: const TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.blue.shade100,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session.topic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(session.notes, style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildQuizzesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _quizzes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No quizzes taken yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Text('Your quiz results will appear here after you take quizzes.', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchStudyData,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: Column( // FIXED: Changed from Row to Column for better responsive layout
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      quiz.topic, 
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(quiz.date), 
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: quiz.score >= 80 ? Colors.green.shade100 : quiz.score >= 60 ? Colors.yellow.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Score: ${quiz.score.toStringAsFixed(0)}% (${quiz.correctAnswers}/${quiz.totalQuestions})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: quiz.score >= 80 ? Colors.green.shade800 : quiz.score >= 60 ? Colors.yellow.shade800 : Colors.red.shade800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Passing Probability Card
        Card(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.indigo.shade600],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Probability of Passing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Small screens - Stack vertically
                      return Column(
                        children: [
                          Text('${_calculatePassingProbability()}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                          const Text('Estimated chance of success', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info, color: Colors.indigo.shade500, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'This estimation is based on your quiz performance. It\'s only an approximation and should not be taken as a final prediction of your actual results.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Larger screens - Keep horizontal layout
                      return Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_calculatePassingProbability()}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                              const Text('Estimated chance of success', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info, color: Colors.indigo.shade500, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'This estimation is based on your quiz performance. It\'s only an approximation and should not be taken as a final prediction of your actual results.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Topic Performance Card
        SizedBox(
          height: 400, // Fixed height to prevent overflow
          child: Card(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.teal.shade600],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Topic Performance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _summary.topicsCovered.isEmpty
                        ? const Center(child: Text('No topic data available yet', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _summary.topicsCovered.length,
                            itemBuilder: (context, index) {
                              final topic = _summary.topicsCovered[index];
                              final topicQuizzes = _quizzes.where((q) => q.topic == topic).toList();
                              final topicAvgScore = topicQuizzes.fold<double>(0, (sum, q) => sum + q.score) / topicQuizzes.length;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            topic, 
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${topicAvgScore.round()}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: topicAvgScore >= 80 ? Colors.green.shade600 : topicAvgScore >= 60 ? Colors.yellow.shade600 : Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: topicAvgScore / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        topicAvgScore >= 80 ? Colors.green.shade600 : topicAvgScore >= 60 ? Colors.yellow.shade500 : Colors.red.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${topicQuizzes.length} ${topicQuizzes.length == 1 ? 'quiz' : 'quizzes'} taken',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}

// Data models
class Quiz {
  final String id;
  final String date;
  final String topic;
  final int correctAnswers;
  final int totalQuestions;
  final double score;
  final String noteId;

  Quiz({
    required this.id,
    required this.date,
    required this.topic,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.noteId,
  });
}

class StudySession {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final int duration;
  final String topic;
  final String notes;

  StudySession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.topic,
    required this.notes,
  });
}

class StudySummary {
  final int totalStudyTime;
  final int totalQuizzesTaken;
  final double averageScore;
  final List<String> topicsCovered;
  final List<String> strengthAreas;
  final List<String> improvementAreas;

  StudySummary({
    this.totalStudyTime = 0,
    this.totalQuizzesTaken = 0,
    this.averageScore = 0,
    this.topicsCovered = const [],
    this.strengthAreas = const ['N/A'],
    this.improvementAreas = const ['N/A'],
  });
}