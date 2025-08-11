import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SummaryTab extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  final String noteContent; // Added to pass content to backend

  const SummaryTab({
    Key? key,
    required this.noteId,
    required this.noteTitle,
    this.noteContent = '', // Make it optional with default empty string
  }) : super(key: key);

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color summaryColor = Color(0xFFDC2626);

  String? summary;
  bool isLoading = false;
  bool isGenerating = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // Don't try to fetch summary on init since backend doesn't have GET endpoint
    // Just show the empty state initially
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Get stored authentication token - same as study_history.dart
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Get stored user ID - same as study_history.dart
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Check authentication before making API calls - same as study_history.dart
  Future<bool> _checkAuthentication() async {
    final token = await _getAuthToken();
    final userId = await _getUserId();
    
    if (token == null || userId == null) {
      setState(() {
        error = 'Please sign in to generate summary';
        isGenerating = false;
      });
      return false;
    }
    return true;
  }

  // Clear authentication tokens - same as study_history.dart
  Future<void> _clearAuthTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
    } catch (e) {
      print('Error clearing auth tokens: $e');
    }
  }

  Future<void> generateSummary() async {
    if (!mounted) return;
    
    setState(() {
      isGenerating = true;
      error = null;
    });

    try {
      // Check authentication first
      if (!await _checkAuthentication()) {
        return;
      }

      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      final requestBody = {
        'noteId': widget.noteId,
        'topic': widget.noteTitle,
        'content': widget.noteContent, // Include content if available
      };

      print('Sending request to: https://zawadi-lms.onrender.com/api/summary');
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add authentication header
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if the response has the expected structure
        if (data['status'] == 'success' && data['summary'] != null) {
          setState(() {
            summary = data['summary'];
            isGenerating = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Summary generated successfully!'),
                backgroundColor: summaryColor,
              ),
            );
          }
        } else {
          throw Exception('Invalid response format: ${data.toString()}');
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized access - same as study_history.dart
        await _clearAuthTokens();
        setState(() {
          error = 'Session expired. Please sign in again.';
          isGenerating = false;
        });
        return;
      } else {
        // Handle different error status codes
        String errorMessage = 'Failed to generate summary';
        
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Server returned status ${response.statusCode}';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error generating summary: $e');
      if (!mounted) return;
      
      setState(() {
        error = 'Error generating summary: ${e.toString()}';
        isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate summary: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    color: summaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.summarize_rounded,
                    color: summaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
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
                  IconButton(
                    onPressed: () {
                      setState(() {
                        error = null;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red.shade600, size: 16),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: Container(
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: summaryColor),
                      )
                    : summary == null
                        ? _buildEmptyState()
                        : _buildSummaryView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: summaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.summarize_outlined,
                size: 40,
                color: summaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Summary Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Generate a comprehensive summary of your note content to quickly grasp the main concepts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isGenerating ? null : generateSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: summaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        Icon(Icons.auto_awesome, size: 16),
                        SizedBox(width: 8),
                        Text('Generate Summary'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryView() {
    return Column(
      children: [
        // Generate New Summary Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton(
            onPressed: isGenerating ? null : generateSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: summaryColor,
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
                      Text('Generating New Summary...'),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('Generate New Summary'),
                    ],
                  ),
          ),
        ),

        // Summary Content
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: summaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: summaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: summaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Generated Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: summaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    summary!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}