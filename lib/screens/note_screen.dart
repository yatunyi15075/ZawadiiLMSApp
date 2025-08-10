import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/ai_chat_bot.dart'; // Import the AI chat from separate file
import '../screens/study_history.dart'; // Import the Study History screen
import '../tabs/notes_tab.dart';
import '../tabs/quizzes_tab.dart';
import '../tabs/flashcards_tab.dart';
import '../tabs/summary_tab.dart';
import '../tabs/resources_tab.dart';

class NoteScreen extends StatefulWidget {
  final String? noteTitle;
  final String noteId; // Add noteId parameter
  
  const NoteScreen({
    Key? key, 
    this.noteTitle,
    required this.noteId, // Make noteId required
  }) : super(key: key);

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String? userId; // Add userId state

  // Professional color scheme
  static const Color primaryColor = Color(0xFF2563EB); // Professional blue
  static const Color secondaryColor = Color(0xFF1E40AF); // Darker blue
  static const Color accentColor = Color(0xFF3B82F6); // Lighter blue
  static const Color surfaceColor = Color(0xFFF8FAFC); // Light gray-blue
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color historyColor = Color(0xFF7C3AED); // Purple for history

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadUserId(); // Load userId on init
  }

  // Load userId from SharedPreferences
  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      setState(() {
        userId = storedUserId;
      });
    } catch (e) {
      print('Error loading userId: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        title: Text(
          widget.noteTitle ?? 'Study Notes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 20 : 18,
            color: textPrimary,
          ),
        ),
        actions: [
          // Study History Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                if (userId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudyHistoryScreen(
                        userId: userId!, // Use the actual userId
                        noteTitle: widget.noteTitle ?? 'Study Notes',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to view study history'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: historyColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: historyColor,
                  size: 20,
                ),
              ),
              tooltip: 'Study History',
            ),
          ),
          // AI Chat Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AIChatScreen(),
                  ),
                );
              },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              tooltip: 'AI Assistant',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: textSecondary),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              labelColor: primaryColor,
              unselectedLabelColor: textSecondary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isTablet ? 16 : 14,
              ),
              tabs: const [
                Tab(text: 'Notes'),
                Tab(text: 'Quizzes'),
                Tab(text: 'Flashcards'),
                Tab(text: 'Summary'),
                Tab(text: 'Resources'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotesTab(noteId: widget.noteId), // Correctly passing noteId to NotesTab
          QuizzesTab(
            noteId: widget.noteId,
            noteTitle: widget.noteTitle ?? 'Study Notes',
          ),
          FlashcardsTab(
            noteId: widget.noteId,
            noteTitle: widget.noteTitle ?? 'Study Notes',
          ),
          const SummaryTab(),
          const ResourcesTab(),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Quick Access to Study History in More Options
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: historyColor),
              title: const Text('Study Analytics', style: TextStyle(color: textPrimary)),
              subtitle: const Text('View detailed study progress', style: TextStyle(color: textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                if (userId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudyHistoryScreen(
                        userId: userId!, // Use the actual userId
                        noteTitle: widget.noteTitle ?? 'Study Notes',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to view study history'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: primaryColor),
              title: const Text('Edit Note', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Color(0xFF059669)),
              title: const Text('Share', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626)),
              title: const Text('Delete', style: TextStyle(color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}