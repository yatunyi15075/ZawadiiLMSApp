import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';
import 'upgrade_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userRole = 'user';
  DateTime? createdAt;
  bool isLoading = true;
  bool hasToken = false;

  // Your backend base URL - adjust this to match your backend
  static const String BASE_URL = 'https://zawadi-lms.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<String?> _getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      print('Error getting role: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$BASE_URL/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // Check if user has token
      String? token = await _getToken();
      String? role = await _getRole();
      hasToken = token != null;

      if (!hasToken) {
        setState(() {
          userName = 'Guest User';
          userEmail = 'Not logged in';
          userRole = 'guest';
          isLoading = false;
        });
        return;
      }

      // Check if this is demo login
      if (token == 'demo_token_12345') {
        setState(() {
          userName = 'Demo User';
          userEmail = 'demo@example.com';
          userRole = role ?? 'parent';
          createdAt = DateTime.now().subtract(const Duration(days: 30)); // Demo account created 30 days ago
          isLoading = false;
        });
        return;
      }

      // Fetch user profile from backend for real users
      Map<String, dynamic>? userProfile = await _getUserProfile();
      
      if (userProfile != null) {
        setState(() {
          userName = userProfile['name'] ?? 'Unknown User';
          userEmail = userProfile['email'] ?? 'No email';
          userRole = userProfile['role'] ?? 'user';
          if (userProfile['createdAt'] != null) {
            createdAt = DateTime.parse(userProfile['createdAt']);
          }
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Error loading profile';
          userEmail = 'Please try again';
          userRole = role ?? 'user';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        userName = 'Error loading profile';
        userEmail = 'Please try again';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError('No authentication token found');
        return;
      }

      // Don't allow deletion of demo account
      if (token == 'demo_token_12345') {
        _showError('Cannot delete demo account');
        return;
      }

      final response = await http.delete(
        Uri.parse('$BASE_URL/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('role');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        _showError('Error deleting account. Please try again.');
      }
    } catch (e) {
      print('Error deleting account: $e');
      _showError('Error deleting account. Please try again.');
    }
  }

  Future<void> _showEditProfileDialog() async {
    TextEditingController nameController = TextEditingController(text: userName);
    TextEditingController emailController = TextEditingController(text: userEmail);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateProfile(nameController.text, emailController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(String name, String email) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError('No authentication token found');
        return;
      }

      // Don't allow editing demo account
      if (token == 'demo_token_12345') {
        _showError('Cannot edit demo account');
        return;
      }

      final response = await http.put(
        Uri.parse('$BASE_URL/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name.isEmpty ? null : name,
          'email': email.isEmpty ? null : email,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          userName = name.isEmpty ? userName : name;
          userEmail = email.isEmpty ? userEmail : email;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final data = json.decode(response.body);
        _showError(data['message'] ?? 'Error updating profile. Please try again.');
      }
    } catch (e) {
      print('Error updating profile: $e');
      _showError('Error updating profile. Please try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMemberSince() {
    if (createdAt == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: ListView(
                children: [
                  // Show upgrade section only for non-admin users and logged in users
                  if (hasToken && userRole != 'admin')
                    ListTile(
                      title: const Text('Upgrade to Pro'),
                      leading: const Icon(Icons.upgrade, color: Colors.amber),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                        );
                      },
                    ),
                  
                  // User profile section
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userEmail),
                                if (createdAt != null)
                                  Text(
                                    'Member since ${_formatMemberSince()}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            trailing: (hasToken && userRole != 'guest') ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _showEditProfileDialog,
                            ) : null,
                          ),
                          
                          // Role indicator
                          if (hasToken)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: userRole == 'admin' 
                                    ? Colors.purple.withOpacity(0.1)
                                    : userRole == 'parent'
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Account Type',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: userRole == 'admin' 
                                          ? Colors.purple
                                          : userRole == 'parent'
                                              ? Colors.blue
                                              : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      userRole.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Subscription status section
                  if (hasToken)
                    ListTile(
                      title: const Text('Subscription Status'),
                      leading: Icon(
                        userRole == 'admin' ? Icons.admin_panel_settings : Icons.account_balance_wallet,
                        color: userRole == 'admin' ? Colors.purple : Colors.orange,
                      ),
                      trailing: Text(
                        userRole == 'admin' ? 'Admin Access' : 'Free Plan',
                        style: TextStyle(
                          color: userRole == 'admin' ? Colors.purple : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  
                  const ListTile(
                    title: Text('App Version'),
                    leading: Icon(Icons.info_outline),
                    trailing: Text('1.1.3'),
                  ),
                  
                  const Divider(),
                  
                  // App actions
                  ListTile(
                    title: const Text('Give Notewane 5 stars'),
                    leading: const Icon(Icons.star_rate, color: Colors.amber),
                    onTap: () {
                      // TODO: Implement app store review logic
                    },
                  ),
                  
                  ListTile(
                    title: const Text('Share Feynman AI'),
                    leading: const Icon(Icons.share, color: Colors.blue),
                    onTap: () {
                      // TODO: Implement share app functionality
                    },
                  ),
                  
                  ListTile(
                    title: const Text('Get help'),
                    leading: const Icon(Icons.help_outline, color: Colors.green),
                    onTap: () {
                      // TODO: Implement help/support functionality
                    },
                  ),
                  
                  const Divider(),
                  
                  // Legal
                  ListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    onTap: () {
                      // TODO: Implement privacy policy navigation
                    },
                  ),
                  
                  ListTile(
                    title: const Text('Terms of Service'),
                    leading: const Icon(Icons.article_outlined),
                    onTap: () {
                      // TODO: Implement terms of service navigation
                    },
                  ),
                  
                  // Account actions - only show if user is logged in
                  if (hasToken) ...[
                    const Divider(),
                    
                    ListTile(
                      title: const Text('Logout'),
                      leading: const Icon(Icons.logout, color: Colors.red),
                      textColor: Colors.red,
                      onTap: _logout,
                    ),
                    
                    if (userRole != 'guest') // Don't show delete for demo/guest accounts
                      ListTile(
                        title: const Text('Delete account'),
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        textColor: Colors.red,
                        onTap: _showDeleteAccountDialog,
                      ),
                  ] else ...[
                    const Divider(),
                    
                    ListTile(
                      title: const Text('Login'),
                      leading: const Icon(Icons.login, color: Colors.green),
                      textColor: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}