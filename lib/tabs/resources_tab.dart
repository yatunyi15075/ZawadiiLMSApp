import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ResourcesTab extends StatefulWidget {
  final String noteId;
  final String noteTitle;

  const ResourcesTab({
    Key? key,
    required this.noteId,
    required this.noteTitle,
  }) : super(key: key);

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color resourcesColor = Color(0xFF059669);

  List<YouTubeVideo> videos = [];
  bool isLoading = false;
  bool isGenerating = false;
  bool isLoadingMore = false;
  String? error;
  String? nextPageToken;

  @override
  void initState() {
    super.initState();
    // No need to fetch resources on init since they need to be generated first
  }

  @override
  void dispose() {
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
        error = 'Please sign in to generate resources';
        isGenerating = false;
        isLoading = false;
        isLoadingMore = false;
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

  Future<void> fetchResources() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Check authentication first
      if (!await _checkAuthentication()) {
        return;
      }

      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Sending request to: https://zawadi-lms.onrender.com/api/resources');
      print('Request body: ${json.encode({
        'topic': widget.noteTitle,
        'maxResults': 10,
      })}');

      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/resources'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'topic': widget.noteTitle,
          'maxResults': 10,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            videos = (data['data']['videos'] as List? ?? [])
                .map((video) => YouTubeVideo.fromJson(video))
                .toList();
            nextPageToken = data['data']['nextPageToken'];
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch resources');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthTokens();
        setState(() {
          error = 'Authentication expired. Please sign in again.';
        });
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to fetch resources');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error loading resources: $e';
      });
      print('Error in fetchResources: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> generateResources() async {
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

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Sending request to: https://zawadi-lms.onrender.com/api/resources');
      print('Request body: ${json.encode({
        'topic': widget.noteTitle,
        'maxResults': 10,
      })}');

      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/resources'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'topic': widget.noteTitle,
          'maxResults': 10,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            videos = (data['data']['videos'] as List? ?? [])
                .map((video) => YouTubeVideo.fromJson(video))
                .toList();
            nextPageToken = data['data']['nextPageToken'];
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Resources generated successfully!'),
                backgroundColor: resourcesColor,
              ),
            );
          }
        } else {
          throw Exception(data['error'] ?? 'Failed to generate resources');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthTokens();
        setState(() {
          error = 'Authentication expired. Please sign in again.';
        });
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to generate resources');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error generating resources: $e';
      });
      print('Error in generateResources: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isGenerating = false;
      });
    }
  }

  Future<void> loadMoreResources() async {
    if (nextPageToken == null || !mounted) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      // Check authentication first
      if (!await _checkAuthentication()) {
        return;
      }

      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Sending request to: https://zawadi-lms.onrender.com/api/resources/more');
      print('Request body: ${json.encode({
        'topic': widget.noteTitle,
        'pageToken': nextPageToken,
        'maxResults': 10,
      })}');

      final response = await http.post(
        Uri.parse('https://zawadi-lms.onrender.com/api/resources/more'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'topic': widget.noteTitle,
          'pageToken': nextPageToken,
          'maxResults': 10,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            videos.addAll(
              (data['data']['videos'] as List? ?? [])
                  .map((video) => YouTubeVideo.fromJson(video))
                  .toList(),
            );
            nextPageToken = data['data']['nextPageToken'];
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load more resources');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthTokens();
        setState(() {
          error = 'Authentication expired. Please sign in again.';
        });
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to load more resources');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error loading more resources: $e';
      });
      print('Error in loadMoreResources: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  // Extract YouTube video ID from URL
  String? _extractVideoId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  // Open video player in a modal
  void _playVideo(YouTubeVideo video) {
    final videoId = _extractVideoId(video.url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid video URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoPlayerModal(
        video: video,
        videoId: videoId,
      ),
    );
  }

  String _formatDuration(String publishedAt) {
    try {
      final publishDate = DateTime.parse(publishedAt);
      final now = DateTime.now();
      final difference = now.difference(publishDate);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildVideoCard(YouTubeVideo video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _playVideo(video),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 120,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      if (video.thumbnail.medium != null)
                        Image.network(
                          video.thumbnail.medium!,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.video_library,
                                color: Colors.grey,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Video Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(video.publishedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      video.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    color: resourcesColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: resourcesColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Learning Resources',
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
                  '${videos.length} videos',
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
                        child: CircularProgressIndicator(color: resourcesColor),
                      )
                    : videos.isEmpty
                        ? _buildEmptyState()
                        : _buildResourcesView(),
              ),
            ),
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
              color: resourcesColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              size: 48,
              color: resourcesColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Learning Resources Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate curated YouTube videos and learning materials\nbased on your note content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isGenerating ? null : generateResources,
            style: ElevatedButton.styleFrom(
              backgroundColor: resourcesColor,
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
                      Text('Finding Resources...'),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text('Generate Resources'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesView() {
    return Column(
      children: [
        // Generate New Resources Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton(
            onPressed: isGenerating ? null : generateResources,
            style: ElevatedButton.styleFrom(
              backgroundColor: resourcesColor,
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
                      Text('Finding New Resources...'),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('Generate New Resources'),
                    ],
                  ),
          ),
        ),

        // Resources List
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    return _buildVideoCard(videos[index]);
                  },
                ),
              ),
              
              // Load More Button
              if (nextPageToken != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: isLoadingMore ? null : loadMoreResources,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resourcesColor.withOpacity(0.1),
                      foregroundColor: resourcesColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoadingMore
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: resourcesColor,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Loading More...'),
                            ],
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Load More Videos'),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Video Player Modal Widget
class VideoPlayerModal extends StatefulWidget {
  final YouTubeVideo video;
  final String videoId;

  const VideoPlayerModal({
    Key? key,
    required this.video,
    required this.videoId,
  }) : super(key: key);

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.video.channelTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          
          // Video Player
          YoutubePlayerBuilder(
            onExitFullScreen: () {
              // Handle exit full screen
            },
            player: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF059669),
              onReady: () {
                setState(() {
                  _isPlayerReady = true;
                });
              },
              onEnded: (data) {
                // Handle video end
              },
            ),
            builder: (context, player) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: player,
                ),
              );
            },
          ),
          
          // Video Description
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Video Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.video.channelTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height:4),
                       Row(
                         children: [
                           const Icon(
                             Icons.calendar_today,
                             size: 16,
                             color: Color(0xFF6B7280),
                           ),
                           const SizedBox(width: 8),
                           Text(
                             _formatDuration(widget.video.publishedAt),
                             style: const TextStyle(
                               fontSize: 13,
                               color: Color(0xFF6B7280),
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 20),
               ],
             ),
           ),
         ),
       ],
     ),
   );
 }

 String _formatDuration(String publishedAt) {
   try {
     final publishDate = DateTime.parse(publishedAt);
     final now = DateTime.now();
     final difference = now.difference(publishDate);

     if (difference.inDays > 365) {
       return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
     } else if (difference.inDays > 30) {
       return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
     } else if (difference.inDays > 0) {
       return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
     } else if (difference.inHours > 0) {
       return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
     } else {
       return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
     }
   } catch (e) {
     return 'Unknown';
   }
 }
}

// YouTube Video Model
class YouTubeVideo {
 final String id;
 final String title;
 final String description;
 final VideoThumbnail thumbnail;
 final String channelTitle;
 final String publishedAt;
 final String url;

 YouTubeVideo({
   required this.id,
   required this.title,
   required this.description,
   required this.thumbnail,
   required this.channelTitle,
   required this.publishedAt,
   required this.url,
 });

 factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
   return YouTubeVideo(
     id: json['id'] ?? '',
     title: json['title'] ?? '',
     description: json['description'] ?? '',
     thumbnail: VideoThumbnail.fromJson(json['thumbnail'] ?? {}),
     channelTitle: json['channelTitle'] ?? '',
     publishedAt: json['publishedAt'] ?? '',
     url: json['url'] ?? '',
   );
 }
}

class VideoThumbnail {
 final String? defaultUrl;
 final String? medium;
 final String? high;

 VideoThumbnail({
   this.defaultUrl,
   this.medium,
   this.high,
 });

 factory VideoThumbnail.fromJson(Map<String, dynamic> json) {
   return VideoThumbnail(
     defaultUrl: json['default'],
     medium: json['medium'],
     high: json['high'],
   );
 }
}