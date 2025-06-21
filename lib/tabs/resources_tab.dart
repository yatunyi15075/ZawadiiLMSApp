import 'package:flutter/material.dart';

class ResourcesTab extends StatelessWidget {
  // Professional color scheme
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color resourcesColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF059669);
  static const Color purpleColor = Color(0xFF7C3AED);

  const ResourcesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
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
                    Icons.library_books_rounded,
                    color: resourcesColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Learning Resources',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final resources = [
                  {
                    'title': 'Introduction to Data Structures',
                    'type': 'Video Tutorial',
                    'duration': '12:45',
                    'icon': Icons.play_circle_outline,
                    'color': resourcesColor,
                  },
                  {
                    'title': 'Arrays and Linked Lists Guide',
                    'type': 'Article',
                    'duration': '8 min read',
                    'icon': Icons.article_outlined,
                    'color': primaryColor,
                  },
                  {
                    'title': 'Stack and Queue Implementation',
                    'type': 'Code Examples',
                    'duration': '15 examples',
                    'icon': Icons.code_rounded,
                    'color': successColor,
                  },
                  {
                    'title': 'Tree Data Structures Deep Dive',
                    'type': 'Interactive Tutorial',
                    'duration': '25 min',
                    'icon': Icons.psychology_rounded,
                    'color': purpleColor,
                  },
                ];
                
                final resource = resources[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (resource['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        resource['icon'] as IconData,
                        color: resource['color'] as Color,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      resource['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${resource['type']} • ${resource['duration']}',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: textSecondary,
                      size: 16,
                    ),
                    onTap: () {
                      // TODO: Open resource
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}