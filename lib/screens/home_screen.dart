import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/note_screen.dart';
import '../screens/youtube_video_link_screen.dart';
import '../screens/upload_audio_screen.dart';
import '../screens/topic_exploration_screen.dart';
import '../screens/recording_screen.dart';
import '../screens/upgrade_screen.dart';
import '../screens/settings_screen.dart';

// Note model to match your backend structure
class Note {
  final String id;
  final String topic;
  final String content;
  final String createdAt;
  final String? folderId;

  Note({
    required this.id,
    required this.topic,
    required this.content,
    required this.createdAt,
    this.folderId,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id']?.toString() ?? '',
      topic: json['topic'] ?? 'Untitled Note',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      folderId: json['folderId']?.toString(),
    );
  }
}

// Folder model to match your backend structure
class Folder {
  final String id;
  final String name;

  Folder({
    required this.id,
    required this.name,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Untitled Folder',
    );
  }
}

// Subscription status model
class SubscriptionStatus {
  final bool hasActiveSubscription;
  final String? planName;
  final String? nextPaymentDate;
  final String? reason;

  SubscriptionStatus({
    required this.hasActiveSubscription,
    this.planName,
    this.nextPaymentDate,
    this.reason,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final subscriptionDetails = data['subscriptionDetails'];
    
    return SubscriptionStatus(
      hasActiveSubscription: data['hasActiveSubscription'] ?? false,
      planName: subscriptionDetails?['plan'],
      nextPaymentDate: subscriptionDetails?['nextPaymentDate'],
      reason: data['reason'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _showWelcomeBanner = false;
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isCheckingSubscription = true;
  bool _showFolders = false;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _folderNameController = TextEditingController();
  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  List<Folder> _folders = [];
  String? _selectedFolderId;
  String _errorMessage = '';
  SubscriptionStatus? _subscriptionStatus;
  
  // Initialize as nullable and provide safe access
  AnimationController? _folderAnimationController;
  Animation<double>? _folderAnimation;
  
// Cache management variables
DateTime? _lastNotesRefresh;
DateTime? _lastFoldersRefresh;
static const Duration _cacheTimeout = Duration(minutes: 5); // 5 minutes cache
bool _useCache = true;


  // Replace with your backend URL
  static const String _baseUrl = 'https://zawadi-lms.onrender.com';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller and animation
    _folderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _folderAnimation = CurvedAnimation(
      parent: _folderAnimationController!,
      curve: Curves.easeInOut,
    );
    
    _checkWelcomeBannerVisibility();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _folderNameController.dispose();
    _folderAnimationController?.dispose();
    super.dispose();
  }

  // Check if welcome banner should be shown (only for first-time users)
  Future<void> _checkWelcomeBannerVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTimeUser = prefs.getBool('is_first_time_user') ?? true;
      
      print('Checking welcome banner visibility - is_first_time_user: $isFirstTimeUser');
      
      setState(() {
        _showWelcomeBanner = isFirstTimeUser;
      });
      
      // If this is a first-time user and banner is shown, mark them as returning user
      // so the banner won't show again on next app launch
      if (isFirstTimeUser) {
        await prefs.setBool('is_first_time_user', false);
        print('Marked user as returning user for future sessions');
      }
    } catch (e) {
      print('Error checking welcome banner visibility: $e');
      // Default to not showing banner if there's an error
      setState(() {
        _showWelcomeBanner = false;
      });
    }
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

  // Get stored user email
  Future<String?> _getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('email') ?? prefs.getString('userEmail');
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  // Check authentication before making API calls
  Future<bool> _checkAuthentication() async {
    final token = await _getAuthToken();
    final userId = await _getUserId();
    
    if (token == null || userId == null) {
      setState(() {
        _errorMessage = 'Please sign in to view your notes';
        _isLoading = false;
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

  // Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isCheckingSubscription = true;
    });

    try {
      final email = await _getUserEmail();
      if (email == null) {
        print('No email found for subscription check');
        setState(() {
          _subscriptionStatus = SubscriptionStatus(
            hasActiveSubscription: false,
            reason: 'No email found',
          );
          _isCheckingSubscription = false;
        });
        return;
      }

      print('Checking subscription for email: $email');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/subscription/check-status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      print('Subscription check response status: ${response.statusCode}');
      print('Subscription check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _subscriptionStatus = SubscriptionStatus.fromJson(data);
          });
        } else {
          setState(() {
            _subscriptionStatus = SubscriptionStatus(
              hasActiveSubscription: false,
              reason: data['message'] ?? 'Failed to check subscription',
            );
          });
        }
      } else {
        setState(() {
          _subscriptionStatus = SubscriptionStatus(
            hasActiveSubscription: false,
            reason: 'Failed to connect to server',
          );
        });
      }
    } catch (e) {
      print('Error checking subscription status: $e');
      setState(() {
        _subscriptionStatus = SubscriptionStatus(
          hasActiveSubscription: false,
          reason: 'Network error: ${e.toString()}',
        );
      });
    } finally {
      setState(() {
        _isCheckingSubscription = false;
      });
    }
  }

  // Load both folders and notes
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Check authentication first
    if (!await _checkAuthentication()) {
      return;
    }

    try {
      await Future.wait([
        _loadFolders(),
        _loadNotes(),
        _checkSubscriptionStatus(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch folders from API
  
// CODE CHANGE 3: Update the _loadFolders method (around line 300)
// Replace the existing _loadFolders method with this optimized version:

Future<void> _loadFolders({bool forceRefresh = false}) async {
  // Check if we can use cached data
  if (!forceRefresh && _useCache && _lastFoldersRefresh != null) {
    final timeSinceLastRefresh = DateTime.now().difference(_lastFoldersRefresh!);
    if (timeSinceLastRefresh < _cacheTimeout && _folders.isNotEmpty) {
      print('Using cached folders data');
      return;
    }
  }

  try {
    final token = await _getAuthToken();
    final userId = await _getUserId();

    if (token == null || userId == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/folders?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> foldersJson = data['data'] ?? [];
        setState(() {
          _folders = foldersJson.map((json) => Folder.fromJson(json)).toList();
          _lastFoldersRefresh = DateTime.now(); // Update cache timestamp
          
          // Ensure "General" folder exists
          final hasGeneralFolder = _folders.any((folder) => folder.name == 'General');
          if (!hasGeneralFolder) {
            _createGeneralFolder();
          }
        });
        print('Folders loaded from API and cached');
      } else {
        throw Exception(data['message'] ?? 'Failed to load folders');
      }
    } else if (response.statusCode == 401) {
      await _clearAuthTokens();
      setState(() {
        _errorMessage = 'Session expired. Please sign in again.';
      });
      return;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error loading folders: $e');
    if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }
}


  // Create General folder if it doesn't exist
  Future<void> _createGeneralFolder() async {
    try {
      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        return;
      }

      final response = await http.post(
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newFolder = Folder.fromJson(data['data']);
          setState(() {
            _folders.insert(0, newFolder);
          });
        }
      }
    } catch (e) {
      print('Error creating General folder: $e');
    }
  }

  // Create a new folder
  Future<void> _createFolder(String folderName) async {
    try {
      final token = await _getAuthToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        _showSnackBar('Authentication required', isError: true);
        return;
      }

      // Check if folder already exists
      if (_folders.any((folder) => folder.name.toLowerCase() == folderName.toLowerCase())) {
        _showSnackBar('Folder already exists!', isError: true);
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/folders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': folderName,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newFolder = Folder.fromJson(data['data']);
          setState(() {
            _folders.add(newFolder);
          });
          _showSnackBar('Folder created successfully!');
        } else {
          _showSnackBar('Failed to create folder: ${data['message']}', isError: true);
        }
      } else {
        _showSnackBar('Failed to create folder', isError: true);
      }
    } catch (e) {
      print('Error creating folder: $e');
      _showSnackBar('Error creating folder: ${e.toString()}', isError: true);
    }
  }

  // Fetch notes from API
  
Future<void> _loadNotes({bool forceRefresh = false}) async {
  // Check if we can use cached data
  if (!forceRefresh && _useCache && _lastNotesRefresh != null) {
    final timeSinceLastRefresh = DateTime.now().difference(_lastNotesRefresh!);
    if (timeSinceLastRefresh < _cacheTimeout && _allNotes.isNotEmpty) {
      print('Using cached notes data');
      setState(() {
        _filteredNotes = _allNotes;
        _isLoading = false;
      });
      return;
    }
  }

  try {
    final token = await _getAuthToken();
    final userId = await _getUserId();

    if (token == null || userId == null) {
      throw Exception('Authentication required');
    }

    String url = '$_baseUrl/api/notes?userId=$userId';
    if (_selectedFolderId != null) {
      url += '&folderId=$_selectedFolderId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        setState(() {
          _allNotes = data.map((json) => Note.fromJson(json)).toList();
          _filteredNotes = _allNotes;
          _lastNotesRefresh = DateTime.now(); // Update cache timestamp
        });
        print('Notes loaded from API and cached');
      } else {
        throw Exception('Invalid response format');
      }
    } else if (response.statusCode == 401) {
      await _clearAuthTokens();
      setState(() {
        _errorMessage = 'Session expired. Please sign in again.';
      });
      throw Exception('Session expired');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error loading notes: $e');
    if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
    throw e;
  }
}

  

  // Refresh data
  Future<void> _refreshData() async {
  setState(() {
    _useCache = false; // Disable cache for manual refresh
  });
  
  await _loadData();
  
  setState(() {
    _useCache = true; // Re-enable cache after refresh
  });
}

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _allNotes;
      } else {
        _filteredNotes = _allNotes
            .where((note) =>
                note.topic.toLowerCase().contains(query.toLowerCase()) ||
                note.content.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredNotes = _allNotes;
      }
    });
  }

  void _toggleFolders() {
    setState(() {
      _showFolders = !_showFolders;
    });
    if (_showFolders) {
      _folderAnimationController?.forward();
    } else {
      _folderAnimationController?.reverse();
    }
  }

  // Filter notes by folder
  void _filterByFolder(String? folderId) {
    setState(() {
      _selectedFolderId = folderId;
      _showFolders = false;
    });
    _folderAnimationController?.reverse();
    _loadNotes(); // Reload notes for selected folder
  }

  // Get folder name by ID
  String _getFolderName(String? folderId) {
    if (folderId == null) return 'General';
    final folder = _folders.firstWhere(
      (f) => f.id == folderId,
      orElse: () => Folder(id: '', name: 'General'),
    );
    return folder.name;
  }

  // Get current folder name for display
  String _getCurrentFolderName() {
    if (_selectedFolderId == null) return 'All Notes';
    return _getFolderName(_selectedFolderId);
  }

  // Extract preview text from content (remove markdown)
  String _getPreviewText(String content) {
    if (content.isEmpty) return 'No content';
    
    // Remove markdown syntax for preview
    String text = content
        .replaceAll(RegExp(r'#{1,6}\s'), '') // Remove headings
        .replaceAll(RegExp(r'\*\*'), '') // Remove bold
        .replaceAll(RegExp(r'\*'), '') // Remove italic
        .replaceAll(RegExp(r'^\s*[\*\-]\s', multiLine: true), '') // Remove list markers
        .replaceAll(RegExp(r'```[\s\S]*?```'), 'Code snippet') // Remove code blocks
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1'); // Remove inline code

    // Truncate to reasonable length
    if (text.length > 100) {
      text = text.substring(0, 100).trim() + '...';
    }
    
    return text;
  }

  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Show SnackBar for messages
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  
// CODE CHANGE 5: Add subscription check method for create note options
// Add this new method after the _showSnackBar method (around line 680):

Future<bool> _checkPremiumAccessForCreation(BuildContext context) async {
  if (_subscriptionStatus?.hasActiveSubscription == true) {
    return true;
  }

  // Show premium upgrade dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlock unlimited note creation and advanced features with Premium.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Maybe Later',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UpgradeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Upgrade Now',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  
  return false;
}


  // Show create folder dialog
  void _showCreateFolderDialog() {
    _folderNameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Create New Folder',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a name for your new folder:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _folderNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Folder name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final folderName = _folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _createFolder(folderName);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Build premium section or upgrade button
  Widget _buildPremiumSection(double padding, bool isTablet) {
    if (_isCheckingSubscription) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Checking subscription status...',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_subscriptionStatus?.hasActiveSubscription == true) {
      // Show premium status
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subscriptionStatus?.planName != null
                          ? 'Plan: ${_subscriptionStatus!.planName}'
                          : 'You have unlimited access to all features',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: isTablet ? 20 : 18,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show upgrade button
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UpgradeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size(double.infinity, isTablet ? 64 : 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: isTablet ? 20 : 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Build folder section with null safety
  Widget _buildFoldersSection(double padding, bool isTablet) {
    // Return empty container if animation is not initialized
    if (_folderAnimation == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _folderAnimation!,
      builder: (context, child) {
        return Container(
          height: _folderAnimation!.value * 200 + (_showFolders ? 60 : 0),
          child: Column(
            children: [
              // Folder header
              Container(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getCurrentFolderName(),
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCreateFolderDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('New Folder'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
              // Folders list
              if (_showFolders)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: padding

),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // All Notes option
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedFolderId == null 
                                ? const Color(0xFF3B82F6).withOpacity(0.1)
                                : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.all_inbox_rounded,
                              color: _selectedFolderId == null 
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF475569),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'All Notes',
                            style: TextStyle(
                              fontWeight: _selectedFolderId == null 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                              color: _selectedFolderId == null 
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF1E293B),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_allNotes.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          onTap: () => _filterByFolder(null),
                        ),
                        const Divider(height: 1),
                        // Individual folders
                        Expanded(
                          child: ListView.builder(
                            itemCount: _folders.length,
                            itemBuilder: (context, index) {
                              final folder = _folders[index];
                              final isSelected = _selectedFolderId == folder.id;
                              final notesCount = _allNotes.where((note) => note.folderId == folder.id).length;
                              
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                                      : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.folder_rounded,
                                    color: isSelected 
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF475569),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  folder.name,
                                  style: TextStyle(
                                    fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.w500,
                                    color: isSelected 
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFF1E293B),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$notesCount',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                onTap: () => _filterByFolder(folder.id),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = screenWidth > 400 ? 20.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  color: const Color(0xFF1E293B),
                ),
                onChanged: _filterNotes,
              )
            : Text(
                _getCurrentFolderName(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 22 : 20,
                  color: const Color(0xFF1E293B),
                ),
              ),
        actions: [
          // Folder toggle button
          if (!_isSearching)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _showFolders 
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _showFolders ? Icons.folder_open_rounded : Icons.folder_rounded,
                  color: _showFolders 
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF475569),
                ),
                onPressed: _toggleFolders,
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFF475569),
              ),
              onPressed: _toggleSearch,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_rounded,
                color: Color(0xFF475569),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // Professional Welcome banner - only shown for first-time users
              if (_showWelcomeBanner && !_isSearching)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome to Zawadii AI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 24 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your intelligent study and work companion',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showWelcomeBanner = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Premium section - either status or upgrade button
              if (!_isSearching)
                _buildPremiumSection(padding, isTablet),

              // Folders section
              if (!_isSearching)
                _buildFoldersSection(padding, isTablet),

              // Notes section header
              if (!_isSearching && !_showFolders)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Row(
                    children: [
                      Text(
                        'Your Notes',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedFolderId != null)
                        TextButton.icon(
                          onPressed: () => _filterByFolder(null),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Clear Filter',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Search results header
              if (_isSearching)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Search Results (${_filteredNotes.length})',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),

              // Notes list
              if (!_showFolders)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading notes...'),
                              ],
                            ),
                          )
                        : _errorMessage.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Error loading notes',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _refreshData,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredNotes.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(20),
                                         ),
                                         child: Icon(
                                           _isSearching ? Icons.search_off_rounded : Icons.note_add_rounded,
                                           size: 48,
                                           color: Colors.grey[400],
                                         ),
                                       ),
                                       const SizedBox(height: 24),
                                       Text(
                                         _isSearching ? 'No notes found' : 'No notes yet',
                                         style: const TextStyle(
                                           fontSize: 20,
                                           fontWeight: FontWeight.w600,
                                           color: Color(0xFF475569),
                                         ),
                                       ),
                                       const SizedBox(height: 8),
                                       Text(
                                         _isSearching
                                             ? 'Try searching with different keywords'
                                             : 'Create your first note to get started',
                                         style: TextStyle(
                                           fontSize: 14,
                                           color: Colors.grey[500],
                                         ),
                                       ),
                                     ],
                                   ),
                                 )
                               : ListView.builder(
                                   itemCount: _filteredNotes.length,
                                   itemBuilder: (context, index) {
                                     final note = _filteredNotes[index];
                                     return Container(
                                       margin: const EdgeInsets.only(bottom: 16),
                                       decoration: BoxDecoration(
                                         color: Colors.white,
                                         borderRadius: BorderRadius.circular(16),
                                         border: Border.all(
                                           color: const Color(0xFFE2E8F0),
                                           width: 1,
                                         ),
                                         boxShadow: [
                                           BoxShadow(
                                             color: Colors.black.withOpacity(0.04),
                                             blurRadius: 8,
                                             offset: const Offset(0, 2),
                                           ),
                                         ],
                                       ),
                                       child: ListTile(
                                         contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
                                         leading: Container(
                                           width: isTablet ? 56 : 48,
                                           height: isTablet ? 56 : 48,
                                           decoration: BoxDecoration(
                                             gradient: const LinearGradient(
                                               colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                               begin: Alignment.topLeft,
                                               end: Alignment.bottomRight,
                                             ),
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: Icon(
                                             Icons.description_rounded,
                                             color: Colors.white,
                                             size: isTablet ? 28 : 24,
                                           ),
                                         ),
                                         title: Text(
                                           note.topic,
                                           style: TextStyle(
                                             fontWeight: FontWeight.w600,
                                             fontSize: isTablet ? 18 : 16,
                                             color: const Color(0xFF1E293B),
                                           ),
                                         ),
                                         subtitle: Padding(
                                           padding: const EdgeInsets.only(top: 8),
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Text(
                                                 _getPreviewText(note.content),
                                                 style: TextStyle(
                                                   color: const Color(0xFF64748B),
                                                   fontSize: isTablet ? 15 : 14,
                                                   height: 1.4,
                                                 ),
                                                 maxLines: 2,
                                                 overflow: TextOverflow.ellipsis,
                                               ),
                                               const SizedBox(height: 8),
                                               Row(
                                                 children: [
                                                   Text(
                                                     _formatDate(note.createdAt),
                                                     style: const TextStyle(
                                                       color: Color(0xFF94A3B8),
                                                       fontSize: 12,
                                                     ),
                                                   ),
                                                   if (note.folderId != null) ...[
                                                     const SizedBox(width: 8),
                                                     Container(
                                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                       decoration: BoxDecoration(
                                                         color: const Color(0xFFF1F5F9),
                                                         borderRadius: BorderRadius.circular(12),
                                                       ),
                                                       child: Text(
                                                         _getFolderName(note.folderId),
                                                         style: const TextStyle(
                                                           color: Color(0xFF64748B),
                                                           fontSize: 10,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ],
                                               ),
                                             ],
                                           ),
                                         ),
                                         trailing: Container(
                                           padding: const EdgeInsets.all(8),
                                           decoration: BoxDecoration(
                                             color: const Color(0xFFF1F5F9),
                                             borderRadius: BorderRadius.circular(8),
                                           ),
                                           child: const Icon(
                                             Icons.arrow_forward_rounded,
                                             size: 16,
                                             color: Color(0xFF475569),
                                           ),
                                         ),
                                         onTap: () {
                                           Navigator.of(context).push(
                                             MaterialPageRoute(
                                               builder: (context) => NoteScreen(
                                                 noteTitle: note.topic,
                                                 noteId: note.id,
                                               ),
                                             ),
                                           );
                                         },
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
      // Enhanced bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFF3B82F6),
            unselectedItemColor: const Color(0xFF64748B),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 24,
                  ),
                ),
                label: 'Feynman AI',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 24,
                  ),
                ),
                label: 'New Note',
              ),
            ],
            onTap: (index) async {
  if (index == 1) {
    if (await _checkPremiumAccessForCreation(context)) {
      _showCreateNoteOptions(context);
    }
  }
},
          ),
        ),
      ),
      // Modern Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
  onPressed: () async {
    if (await _checkPremiumAccessForCreation(context)) {
      _showCreateNoteOptions(context);
    }
  },
  backgroundColor: Colors.transparent,
  foregroundColor: Colors.white,
  elevation: 0,
  child: const Icon(Icons.add_rounded, size: 28),
),
      ),
    );
  }


void _showCreateNoteOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Note',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Choose how you want to create your note',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Column(
                children: [
                  _buildCreateOption(
                    context,
                    icon: Icons.explore_rounded,
                    title: 'Topic Exploration',
                    subtitle: 'Explore and learn about any topic',
                    onTap: () async {
                      Navigator.pop(context);
                      if (await _checkPremiumAccessForCreation(context)) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TopicExplorationScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCreateOption(
                    context,
                    icon: Icons.mic_rounded,
                    title: 'Voice Recording',
                    subtitle: 'Record your voice and convert to notes',
                    onTap: () async {
                      Navigator.pop(context);
                      if (await _checkPremiumAccessForCreation(context)) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RecordingScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCreateOption(
                    context,
                    icon: Icons.upload_file_rounded,
                    title: 'Upload Audio',
                    subtitle: 'Upload audio files for transcription',
                    onTap: () async {
                      Navigator.pop(context);
                      if (await _checkPremiumAccessForCreation(context)) {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UploadAudioScreen(),
                          ),
                        );
                        
                        if (result == true) {
                          _refreshData();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCreateOption(
                    context,
                    icon: Icons.play_circle_outline_rounded,
                    title: 'YouTube Video',
                    subtitle: 'Convert YouTube videos to notes',
                    onTap: () async {
                      Navigator.pop(context);
                      if (await _checkPremiumAccessForCreation(context)) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const YouTubeVideoLinkScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCreateOption(
                    context,
                    icon: Icons.edit_note_rounded,
                    title: 'Manual Note',
                    subtitle: 'Create a note from scratch',
                    onTap: () async {
                      Navigator.pop(context);
                      if (await _checkPremiumAccessForCreation(context)) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NoteScreen(
                              noteTitle: 'New Note',
                              noteId: '',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                 colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Icon(
               icon,
               color: Colors.white,
               size: 24,
             ),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: const TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                     color: Color(0xFF1E293B),
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   subtitle,
                   style: const TextStyle(
                     fontSize: 14,
                     color: Color(0xFF64748B),
                   ),
                 ),
               ],
             ),
           ),
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: const Color(0xFFF1F5F9),
               borderRadius: BorderRadius.circular(8),
             ),
             child: const Icon(
               Icons.arrow_forward_rounded,
               size: 16,
               color: Color(0xFF475569),
             ),
           ),
         ],
       ),
     ),
   );
 }
}