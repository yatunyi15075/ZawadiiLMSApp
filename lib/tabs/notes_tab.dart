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

  // Backend URL - same as your deployed backend
  static const String _baseUrl = 'https://zawadi-lms.onrender.com';

  Map<String, dynamic>? noteData;
  List<Map<String, dynamic>> folders = [];
  bool isLoading = true;
  bool isFoldersLoading = false;
  String? error;
  ScrollController scrollController = ScrollController();

  // Move note related variables
  bool showMoveNoteDialog = false;
  bool showConfirmationDialog = false;
  String? selectedDestinationFolderId;
  Map<String, dynamic>? selectedDestinationFolder;
  bool isMovingNote = false;

  @override
  void initState() {
    super.initState();
    _initializeNoteData();
    _fetchFolders();
  }

  void _initializeNoteData() {
    if (widget.noteId != null) {
      fetchNoteData();
    } else if (widget.initialContent != null) {
      noteData = {
        'content': widget.initialContent,
        'topic': widget.initialTopic ?? 'Untitled Note',
        'createdAt': DateTime.now().toIso8601String(),
        'folderId': 'general',
      };
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        error = 'No note data available';
        isLoading = false;
      });
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

  // Fetch folders from backend
  Future<void> _fetchFolders() async {
    try {
      setState(() {
        isFoldersLoading = true;
      });

      // Check authentication first
      if (!await _checkAuthentication()) {
        setState(() {
          folders = [{'id': 'general', 'name': 'General'}];
          isFoldersLoading = false;
        });
        return;
      }

      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        setState(() {
          folders = [{'id': 'general', 'name': 'General'}];
          isFoldersLoading = false;
        });
        return;
      }

      final url = '$_baseUrl/api/folders?userId=$userId';
      print('Fetching folders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('Folders API Response status: ${response.statusCode}');
      print('Folders API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map<String, dynamic> && data['success'] == true) {
          List<Map<String, dynamic>> fetchedFolders = List<Map<String, dynamic>>.from(data['data'] ?? []);
          
          // Ensure General folder is always present
          if (!fetchedFolders.any((folder) => folder['name'] == 'General')) {
            // Create General folder if it doesn't exist
            try {
              final createResponse = await http.post(
                Uri.parse('$_baseUrl/api/folders'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: json.encode({
                  'name': 'General',
                  'userId': userId,
                }),
              );
              
              if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
                final createData = json.decode(createResponse.body);
                if (createData['success'] == true) {
                  fetchedFolders.insert(0, createData['data']);
                }
              }
            } catch (createError) {
              print('Error creating General folder: $createError');
            }
          } else {
            // Move General to the front if it exists elsewhere in the array
            final generalIndex = fetchedFolders.indexWhere((folder) => folder['name'] == 'General');
            if (generalIndex > 0) {
              final generalFolder = fetchedFolders.removeAt(generalIndex);
              fetchedFolders.insert(0, generalFolder);
            }
          }
          
          setState(() {
            folders = fetchedFolders;
            isFoldersLoading = false;
          });
        } else {
          print('Error fetching folders: ${data['message']}');
          setState(() {
            folders = [{'id': 'general', 'name': 'General'}];
            isFoldersLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        await _clearAuthTokens();
        setState(() {
          folders = [{'id': 'general', 'name': 'General'}];
          isFoldersLoading = false;
        });
      } else {
        print('Failed to fetch folders: HTTP ${response.statusCode}');
        setState(() {
          folders = [{'id': 'general', 'name': 'General'}];
          isFoldersLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching folders: $e');
      setState(() {
        folders = [{'id': 'general', 'name': 'General'}];
        isFoldersLoading = false;
      });
    }
  }

  // Move note to folder functionality
  Future<void> _moveNoteToFolder() async {
    if (selectedDestinationFolderId == null || widget.noteId == null) {
      return;
    }

    setState(() {
      isMovingNote = true;
    });

    try {
      // Check authentication first
      if (!await _checkAuthentication()) {
        _showSnackBar('Please sign in to move notes between folders.', isError: true);
        setState(() {
          isMovingNote = false;
        });
        return;
      }

      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        _showSnackBar('Authentication required. Please sign in.', isError: true);
        setState(() {
          isMovingNote = false;
        });
        return;
      }

      // First, validate the move
      final validateUrl = '$_baseUrl/api/notes/${widget.noteId}/validate-move';
      print('Validating move to: $validateUrl');

      final validateResponse = await http.post(
        Uri.parse(validateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'folderId': selectedDestinationFolderId,
          'userId': userId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('Validate Response status: ${validateResponse.statusCode}');
      print('Validate Response body: ${validateResponse.body}');

      if (validateResponse.statusCode == 200) {
        final validateData = json.decode(validateResponse.body);
        if (validateData['success'] != true) {
          _showSnackBar(validateData['message'] ?? 'Validation failed', isError: true);
          setState(() {
            isMovingNote = false;
          });
          return;
        }
      } else {
        _showSnackBar('Failed to validate move operation', isError: true);
        setState(() {
          isMovingNote = false;
        });
        return;
      }

      // If validation passes, perform the move
      final moveUrl = '$_baseUrl/api/notes/${widget.noteId}/move';
      print('Moving note to: $moveUrl');

      final moveResponse = await http.patch(
        Uri.parse(moveUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'folderId': selectedDestinationFolderId,
          'userId': userId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('Move Response status: ${moveResponse.statusCode}');
      print('Move Response body: ${moveResponse.body}');

      if (moveResponse.statusCode == 200) {
        final moveData = json.decode(moveResponse.body);
        
        if (moveData['note'] != null) {
          // Update local note data with new folder information
          setState(() {
            noteData?['folderId'] = selectedDestinationFolderId;
            showMoveNoteDialog = false;
            showConfirmationDialog = false;
            selectedDestinationFolderId = null;
            selectedDestinationFolder = null;
            isMovingNote = false;
          });
          
          _showSnackBar('Note moved successfully!');
        } else {
          _showSnackBar('Failed to move note', isError: true);
          setState(() {
            isMovingNote = false;
          });
        }
      } else {
        _showSnackBar('Failed to move note. Please try again.', isError: true);
        setState(() {
          isMovingNote = false;
        });
      }
    } catch (e) {
      print('Error moving note: $e');
      setState(() {
        isMovingNote = false;
      });
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Request timeout')) {
        _showSnackBar('Network error. Please check your connection.', isError: true);
      } else {
        _showSnackBar('Failed to move note. Please try again.', isError: true);
      }
    }
  }

  Future<void> fetchNoteData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('Fetching note with ID: ${widget.noteId}');

      // Check authentication first
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

      final url = '$_baseUrl/api/notes/${widget.noteId}?userId=$userId';
      print('Making API request to: $url');

      // Make API request with proper authentication headers
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both direct note data and wrapped response
        Map<String, dynamic> processedData;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true && data.containsKey('data')) {
            // Wrapped response format
            processedData = data['data'];
          } else if (data.containsKey('content') || data.containsKey('topic')) {
            // Direct note format
            processedData = data;
          } else {
            print('Unexpected response format: $data');
            throw Exception('Invalid response format');
          }
        } else {
          print('Response is not a Map: $data');
          throw Exception('Invalid response format');
        }

        setState(() {
          noteData = processedData;
          isLoading = false;
        });
        
        print('Note data loaded successfully: ${noteData?['topic']}');
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        await _clearAuthTokens();
        setState(() {
          error = 'Session expired. Please sign in again.';
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          error = 'Note not found. It may have been deleted.';
          isLoading = false;
        });
      } else {
        final errorMsg = 'Failed to load note: HTTP ${response.statusCode}';
        print(errorMsg);
        print('Response body: ${response.body}');
        setState(() {
          error = errorMsg;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching note: $e');
      setState(() {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('TimeoutException') ||
            e.toString().contains('Request timeout')) {
          error = 'Network error. Please check your connection.';
        } else {
          error = 'Failed to load note: ${e.toString()}';
        }
        isLoading = false;
      });
    }
  }


  void _copyToClipboard() {
    if (noteData != null && noteData!['content'] != null) {
      Clipboard.setData(ClipboardData(text: noteData!['content']));
      _showSnackBar('Note content copied to clipboard!');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      ),
    );
  }

  void _showMoveNoteDialog() {
    setState(() {
      showMoveNoteDialog = true;
      selectedDestinationFolderId = null;
      selectedDestinationFolder = null;
    });
  }

  void _closeMoveNoteDialog() {
    setState(() {
      showMoveNoteDialog = false;
      selectedDestinationFolderId = null;
      selectedDestinationFolder = null;
    });
  }

  void _showConfirmationDialog() {
    setState(() {
      showConfirmationDialog = true;
    });
  }

  void _closeConfirmationDialog() {
    setState(() {
      showConfirmationDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Column(
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
                                    'Folder: ${_getFolderName(noteData!['folderId'])}',
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
                          // Action buttons
                          Row(
                            children: [
                              // Move to folder button
                              IconButton(
                                onPressed: _showMoveNoteDialog,
                                icon: const Icon(Icons.folder, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: backgroundColor,
                                  padding: const EdgeInsets.all(8),
                                ),
                                tooltip: 'Move to folder',
                              ),
                              const SizedBox(width: 8),
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
                    ] else if (isLoading) ...[
                      // Loading state header
                      Container(
                        height: 40,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
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
                              // Mind map functionality - to be implemented
                              _showSnackBar('Mind map feature coming soon!');
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
                              // Translate functionality - to be implemented
                              _showSnackBar('Translate feature coming soon!');
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
          
          // Move Note Dialog
          if (showMoveNoteDialog) _buildMoveNoteDialog(),
          
          // Confirmation Dialog
          if (showConfirmationDialog) _buildConfirmationDialog(),
        ],
      ),
    );
  }

  Widget _buildMoveNoteDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Move note to folder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _closeMoveNoteDialog,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(24, 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Current folder info
              if (noteData != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 20, color: textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Current Folder: ${_getFolderName(noteData!['folderId'])}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Folders list
              const Text(
                'Select destination folder:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              Flexible(
                child: isFoldersLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : folders.isEmpty
                        ? const Center(
                            child: Text(
                              'No folders available',
                              style: TextStyle(color: textSecondary),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: folders
                                  .where((folder) => folder['id'] != noteData?['folderId'])
                                  .map((folder) => _buildFolderItem(folder))
                                  .toList(),
                            ),
                          ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _closeMoveNoteDialog,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: selectedDestinationFolderId != null
                        ? _showConfirmationDialog
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text('Move Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// FIXED VERSION:
Widget _buildFolderItem(Map<String, dynamic> folder) {
  final isSelected = selectedDestinationFolderId?.toString() == folder['id'].toString();
  
  return GestureDetector(
    onTap: () {
      setState(() {
        // CRITICAL FIX: Store folder ID as string consistently
        selectedDestinationFolderId = folder['id'].toString();
        selectedDestinationFolder = folder;
      });
    },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder,
              size: 20,
              color: isSelected ? primaryColor : textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder['name'] ?? 'Unnamed Folder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryColor : textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Move',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Are you sure you want to move this note to '),
                    TextSpan(
                      text: selectedDestinationFolder?['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isMovingNote ? null : _closeConfirmationDialog,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isMovingNote ? null : () {
                      _closeConfirmationDialog();
                      _moveNoteToFolder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: isMovingNote
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                              ),
                         )
                       : const Text('Yes, Move'),
                 ),
               ],
             ),
           ],
         ),
       ),
     ),
   );
 }

// FIXED VERSION:
String _getFolderName(dynamic folderId) {
  if (folderId == null) {
    return 'General';
  }
  
  // If folderId is an object with name property
  if (folderId is Map<String, dynamic> && folderId.containsKey('name')) {
    return folderId['name'] ?? 'General';
  }
  
  // If folderId is a string, find the matching folder by ID
  if (folderId is String) {
    if (folderId.isEmpty || folderId == 'general') {
      return 'General';
    }
    
    // CRITICAL FIX: Find folder by ID and return its name
    final folder = folders.firstWhere(
      (f) => f['id'].toString() == folderId.toString(),
      orElse: () => {'name': 'General'},
    );
    return folder['name'] ?? 'General';
  }
  
  // If folderId is a number, find the matching folder by ID
  if (folderId is int) {
    final folder = folders.firstWhere(
      (f) => f['id'].toString() == folderId.toString(),
      orElse: () => {'name': 'Folder $folderId'},
    );
    return folder['name'] ?? 'Folder $folderId';
  }
  
  return 'General';
}

 Widget _buildContent() {
   if (isLoading) {
     return const Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           CircularProgressIndicator(
             color: primaryColor,
           ),
           SizedBox(height: 16),
           Text(
             'Loading note...',
             style: TextStyle(
               color: textSecondary,
               fontSize: 16,
             ),
           ),
         ],
       ),
     );
   }

   if (error != null) {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(24.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               error!.contains('Network') || error!.contains('connection') 
                 ? Icons.wifi_off 
                 : error!.contains('sign in') 
                   ? Icons.login 
                   : Icons.error_outline,
               size: 64,
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
             const SizedBox(height: 24),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
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
                 if (error!.contains('sign in')) ...[
                   const SizedBox(width: 12),
                   ElevatedButton(
                     onPressed: () {
                       Navigator.of(context).pushNamedAndRemoveUntil(
                         '/login', 
                         (route) => false,
                       );
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.green,
                       foregroundColor: Colors.white,
                     ),
                     child: const Text('Sign In'),
                   ),
                 ],
               ],
             ),
           ],
         ),
       ),
     );
   }

   if (noteData == null) {
     return const Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(
             Icons.description_outlined,
             size: 64,
             color: textSecondary,
           ),
           SizedBox(height: 16),
           Text(
             'No note data available',
             style: TextStyle(
               color: textSecondary,
               fontSize: 16,
             ),
           ),
         ],
       ),
     );
   }

   return SingleChildScrollView(
     controller: scrollController,
     padding: const EdgeInsets.all(16.0),
     child: Container(
       constraints: const BoxConstraints(maxWidth: 800),
       child: _buildMarkdownContent(noteData!['content'] ?? 'No content available.'),
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