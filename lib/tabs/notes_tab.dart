import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotesTab extends StatefulWidget {
  final String? noteId;
  final String? initialContent;
  final String? initialTopic;

  const NotesTab({
    Key? key,
    this.noteId,
    this.initialContent,
    this.initialTopic,
  }) : super(key: key);

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  // Color scheme matching the webapp
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color codeBackground = Color(0xFFF3F4F6);
  static const Color linkColor = Color(0xFF2563EB);
  static const Color borderColor = Color(0xFFD1D5DB);

  // Backend URL - same as home screen
  static const String _baseUrl = 'https://zawadi-lms.onrender.com';

  Map<String, dynamic>? noteData;
  bool isLoading = true;
  String? error;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      fetchNoteData();
    } else if (widget.initialContent != null) {
      noteData = {
        'content': widget.initialContent,
        'topic': widget.initialTopic ?? 'Untitled Note',
        'createdAt': DateTime.now().toIso8601String(),
        'folderId': 'general',
      };
      isLoading = false;
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // Get stored authentication token
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Get stored user ID
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Check authentication before making API calls
  Future<bool> _checkAuthentication() async {
    final token = await _getAuthToken();
    final userId = await _getUserId();
    
    if (token == null || userId == null) {
      setState(() {
        error = 'Please sign in to view your notes';
        isLoading = false;
      });
      return false;
    }
    return true;
  }

  // Clear authentication tokens
  Future<void> _clearAuthTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
    } catch (e) {
      print('Error clearing auth tokens: $e');
    }
  }

  Future<void> fetchNoteData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Check authentication first - this was missing!
      if (!await _checkAuthentication()) {
        return;
      }

      // Get authentication credentials
      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        setState(() {
          error = 'Authentication required. Please sign in.';
          isLoading = false;
        });
        return;
      }

      // Make API request with proper authentication headers
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notes/${widget.noteId}?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // This was missing!
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          noteData = data;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        await _clearAuthTokens();
        setState(() {
          error = 'Session expired. Please sign in again.';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load note: HTTP ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching note: $e');
      setState(() {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('TimeoutException')) {
          error = 'Network error. Please check your connection.';
        } else {
          error = 'Failed to load note: $e';
        }
        isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (noteData != null && noteData!['content'] != null) {
      Clipboard.setData(ClipboardData(text: noteData!['content']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note content copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header section matching webapp
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (noteData != null) ...[
                  // Title and folder info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              noteData!['topic'] ?? 'Untitled Note',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Folder: General',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Copy button
                      IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: backgroundColor,
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: 'Copy text',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date
                  if (noteData!['createdAt'] != null)
                    Text(
                      _formatDate(noteData!['createdAt']),
                      style: const TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                // Action buttons matching webapp
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Mind map functionality
                        },
                        icon: const Icon(Icons.account_tree, size: 18),
                        label: const Text('Mind map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Translate functionality
                        },
                        icon: const Icon(Icons.translate, size: 18),
                        label: const Text('Translate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, color: borderColor),
          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.noteId != null) {
                  fetchNoteData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (noteData == null) {
      return const Center(
        child: Text(
          'No note data available',
          style: TextStyle(
            color: textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: _buildMarkdownContent(noteData!['content'] ?? ''),
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    List<Widget> widgets = [];
    List<String> lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 16));
        continue;
      }
      
      // Headers (matching webapp styles)
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(4),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.4,
            ),
          ),
        ));
      } else if (line.startsWith('#### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line.substring(5),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.4,
            ),
          ),
        ));
      }
      // Code blocks
      else if (line.startsWith('```')) {
        List<String> codeLines = [];
        i++; // Skip opening ```
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildCodeBlock(codeLines.join('\n')));
      }
      // Blockquotes
      else if (line.startsWith('> ')) {
        widgets.add(_buildBlockquote(line.substring(2)));
      }
      // Horizontal rule
      else if (line.trim() == '---' || line.trim() == '***') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            height: 1,
            color: borderColor,
          ),
        ));
      }
      // Bullet points (unordered lists)
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        String bulletText = line.substring(line.indexOf(RegExp(r'[-*] ')) + 2);
        widgets.add(_buildBulletPoint(bulletText));
      }
      // Numbered lists
      else if (RegExp(r'^\d+\. ').hasMatch(line.trim())) {
        Match? match = RegExp(r'^(\d+)\. (.*)').firstMatch(line.trim());
        if (match != null) {
          String number = match.group(1)!;
          String text = match.group(2)!;
          widgets.add(_buildNumberedPoint(number, text));
        }
      }
      // Regular paragraphs
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRichText(line),
        ));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String text) {
    // Handle bold, italic, and inline code
    List<TextSpan> spans = [];
    String remaining = text;
    
    while (remaining.isNotEmpty) {
      // Check for inline code first (highest priority)
      RegExp codeRegex = RegExp(r'`([^`]+)`');
      Match? codeMatch = codeRegex.firstMatch(remaining);
      
      // Check for bold
      RegExp boldRegex = RegExp(r'\*\*([^*]+)\*\*');
      Match? boldMatch = boldRegex.firstMatch(remaining);
      
      // Check for italic
      RegExp italicRegex = RegExp(r'\*([^*]+)\*');
      Match? italicMatch = italicRegex.firstMatch(remaining);
      
      // Find the earliest match
      Match? earliestMatch;
      String type = '';
      
      List<MapEntry<Match?, String>> matches = [
        MapEntry(codeMatch, 'code'),
        MapEntry(boldMatch, 'bold'),
        MapEntry(italicMatch, 'italic'),
      ];
      
      for (var entry in matches) {
        if (entry.key != null && 
            (earliestMatch == null || entry.key!.start < earliestMatch.start)) {
          earliestMatch = entry.key;
          type = entry.value;
        }
      }
      
      if (earliestMatch != null) {
        // Add text before the match
        if (earliestMatch.start > 0) {
          spans.add(TextSpan(
            text: remaining.substring(0, earliestMatch.start),
          ));
        }
        
        // Add the styled text
        String matchedText = earliestMatch.group(1)!;
        TextSpan styledSpan;
        
        switch (type) {
          case 'code':
            styledSpan = TextSpan(
              text: matchedText,
              style: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: codeBackground,
                fontSize: 14,
              ),
            );
            break;
          case 'bold':
            styledSpan = TextSpan(
              text: matchedText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
            break;
          case 'italic':
            styledSpan = TextSpan(
              text: matchedText,
              style: const TextStyle(fontStyle: FontStyle.italic),
            );
            break;
          default:
            styledSpan = TextSpan(text: matchedText);
        }
        
        spans.add(styledSpan);
        remaining = remaining.substring(earliestMatch.end);
      } else {
        // No more matches, add remaining text
        spans.add(TextSpan(text: remaining));
        break;
      }
    }
    
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: textSecondary,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBlockquote(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 10, right: 16),
            decoration: const BoxDecoration(
              color: textPrimary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: _buildRichText(text),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: const TextStyle(
                fontSize: 16,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _buildRichText(text),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}