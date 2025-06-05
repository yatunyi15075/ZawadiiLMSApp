import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';
import 'upgrade_screen.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Upgrade to Pro'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpgradeScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('brian.ondeiko'),
            subtitle: const Text('braysandy@gmail.com'),
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          const ListTile(
            title: Text('Free credits'),
            trailing: Text('Free'),
          ),
          const ListTile(
            title: Text('Version 1.1.3'),
          ),
          ListTile(
            title: const Text('Give Notewane 5 stars'),
            onTap: () {
              // TODO: Implement app store review logic
            },
          ),
          ListTile(
            title: const Text('Share Feynman AI'),
            onTap: () {
              // TODO: Implement share app functionality
            },
          ),
          ListTile(
            title: const Text('Get help'),
            onTap: () {
              // TODO: Implement help/support functionality
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Implement privacy policy navigation
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            onTap: () {
              // TODO: Implement terms of service navigation
            },
          ),
          ListTile(
            title: const Text('Logout'),
            textColor: Colors.red,
            onTap: () {
              // TODO: Implement logout functionality
            },
          ),
          ListTile(
            title: const Text('Delete account'),
            textColor: Colors.red,
            onTap: () {
              // TODO: Implement account deletion functionality
            },
          ),
        ],
      ),
    );
  }
}