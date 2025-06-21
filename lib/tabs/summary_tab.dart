import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SummaryTab extends StatefulWidget {
  final String? noteContent;
  final String? topic;
  final String? noteId;

  const SummaryTab({
    Key? key,
    this.noteContent,
    this.topic,
    this.noteId,
  }) : super(key: key);

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  // Professional color scheme
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color summaryColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF059669);

  String? generatedSummary;
  bool isLoading = false;
  String? error;
  List<String> keyPoints = [];

  @override
  void initState() {
    super.initState();
    // Generate summary automatically if content is available
    if (widget.noteContent != null && widget.noteContent!.isNotEmpty) {
      generateSummary();
    }
  }

  Future<void> generateSummary() async {
    if (widget.noteContent == null || widget.noteContent!.isEmpty) {
      setState(() {
        error = 'No content available to summarize';
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Simulate API call to generate summary (similar to TranscriptView)
      await Future.delayed(const Duration(seconds: 2));

      // Create summary based on content (similar to React TranscriptView logic)
      List<String> paragraphs = widget.noteContent!
          .split('\n\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();

      String summary = '';
      List<String> points = [];

      if (paragraphs.isNotEmpty) {
        // Extract key points from content
        for (String paragraph in paragraphs) {
          if (paragraph.trim().isNotEmpty) {
            // Simple extraction logic - take first sentence or important phrases
            List<String> sentences = paragraph.split('.');
            if (sentences.isNotEmpty && sentences[0].length > 20) {
              String point = sentences[0].trim();
              if (point.length > 200) {
                point = '${point.substring(0, 200)}...';
              }
              points.add(point);
            }
          }
        }

        // If no meaningful points extracted, create generic ones
        if (points.isEmpty) {
          points = [
            'Key concepts and definitions are covered in this topic',
            'Important principles and methodologies are explained',
            'Practical applications and examples are provided',
            'Fundamental understanding is established',
          ];
        }

        summary = 'This note covers key aspects of ${widget.topic ?? "the topic"}. '
            'The content provides comprehensive information that helps build '
            'understanding of the subject matter and its applications.';
      }

      setState(() {
        generatedSummary = summary;
        keyPoints = points.take(5).toList(); // Limit to 5 key points
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to generate summary: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Loading state
              if (isLoading)
                Container(
                  padding: const EdgeInsets.all(40),
                  child: const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Generating summary...',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              
              // Error state
              else if (error != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: generateSummary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: summaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              
              // No content state
              else if (widget.noteContent == null || widget.noteContent!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No content available to summarize',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              
              // Summary content
              else ...[
                // Key Points Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Points:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (keyPoints.isNotEmpty)
                        ...keyPoints.map((point) => _buildSummaryPoint(point))
                      else
                        const Text(
                          'No key points extracted',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Quick Review Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: successColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Review:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        generatedSummary ?? 'No summary available',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action button to regenerate
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: generateSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate Summary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 16),
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}