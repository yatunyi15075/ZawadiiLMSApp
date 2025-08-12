import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class SummaryTab extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  final String noteContent;

  const SummaryTab({
    Key? key,
    required this.noteId,
    required this.noteTitle,
    this.noteContent = '',
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
  static const Color downloadColor = Color(0xFF059669);

  String? summary;
  bool isLoading = false;
  bool isGenerating = false;
  bool isDownloading = false;
  String? error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

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
        'content': widget.noteContent,
      };

      print('Sending request to: https://zawadi-lms.onrender.com/api/summary');
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['summary'] != null) {
          setState(() {
            summary = data['summary'];
            isGenerating = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Summary generated successfully!'),
                  ],
                ),
                backgroundColor: summaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          throw Exception('Invalid response format: ${data.toString()}');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthTokens();
        setState(() {
          error = 'Session expired. Please sign in again.';
          isGenerating = false;
        });
        return;
      } else {
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to generate summary: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _stripMarkdown(String markdown) {
    // Convert markdown to plain text for PDF
    return markdown
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Remove headers
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Remove bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Remove italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Remove inline code
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Remove code blocks
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Remove links
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up extra newlines
        .trim();
  }

  Future<void> _downloadSummaryAsPDF() async {
    if (summary == null) return;
    
    setState(() {
      isDownloading = true;
    });

    try {
      final pdf = pw.Document();
      final plainTextSummary = _stripMarkdown(summary!);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Title
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      widget.noteTitle,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.normal,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Divider(color: PdfColors.grey400, thickness: 1),
                  ],
                ),
              ),
              
              // Summary Content
              pw.Container(
                child: pw.Text(
                  plainTextSummary,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.5,
                    color: PdfColors.black,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
              
              // Footer
              pw.SizedBox(height: 40),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Generated by Zawadi LMS',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save and share the PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.noteTitle}_Summary.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.download_done, color: Colors.white),
                SizedBox(width: 8),
                Text('Summary downloaded successfully!'),
              ],
            ),
            backgroundColor: downloadColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to download PDF: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (summary != null) {
      final plainText = _stripMarkdown(summary!);
      Clipboard.setData(ClipboardData(text: plainText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.copy, color: Colors.white),
              SizedBox(width: 8),
              Text('Summary copied to clipboard!'),
            ],
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Enhanced Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, summaryColor.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [summaryColor, summaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: summaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.summarize_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.noteTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (summary != null) ...[
                  // Copy Button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Copy to Clipboard',
                    ),
                  ),
                  // Download Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [downloadColor, downloadColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: downloadColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: isDownloading ? null : _downloadSummaryAsPDF,
                      icon: isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Download as PDF',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Enhanced Error Display
          if (error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100], // Fixed: Changed shade25 to shade100
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        error = null;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red.shade600, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),

          // Enhanced Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: summaryColor),
                      )
                    : summary == null
                        ? _buildEmptyState()
                        : _buildEnhancedSummaryView(),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [summaryColor.withOpacity(0.1), summaryColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: summaryColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: summaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Summary Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Generate an AI-powered summary to extract key insights and main concepts from your note content.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [summaryColor, summaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: summaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isGenerating ? null : generateSummary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isGenerating
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 12),
                          Text('Generate Summary', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSummaryView() {
    return Column(
      children: [
        // Action Buttons Row
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [summaryColor, summaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: summaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isGenerating ? null : generateSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isGenerating
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Regenerating...', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Generate New Summary', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ),

        // Enhanced Summary Content with Markdown
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [summaryColor.withOpacity(0.03), summaryColor.withOpacity(0.01)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: summaryColor.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: summaryColor.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: summaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: summaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: summaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Generated Summary',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: summaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Markdown rendered content
                  MarkdownBody(
                    data: summary!,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.4,
                      ),
                      h2: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.4,
                      ),
                      h3: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.4,
                      ),
                      h4: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.4,
                      ),
                      p: const TextStyle(
                        fontSize: 15,
                        color: textPrimary,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: textSecondary,
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.grey.shade100,
                        color: summaryColor,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      listBullet: const TextStyle(
                        color: summaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: summaryColor.withOpacity(0.05),
                        border: Border( // Fixed: Use Border with BorderSide for left border
                          left: BorderSide(
                            color: summaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.all(16),
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