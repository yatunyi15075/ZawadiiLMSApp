import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../screens/parent_contact_details_screen.dart';
import '../screens/home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  final List<Map<String, dynamic>> roles = [
    {'name': 'Student', 'icon': Icons.school},
    {'name': 'High School', 'icon': Icons.school_outlined},
    {'name': 'Primary School', 'icon': Icons.child_care},
    {'name': 'Teacher', 'icon': Icons.person_4},
    {'name': 'Exploring', 'icon': Icons.explore},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRole = role['name'];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedRole == role['name']
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          border: selectedRole == role['name']
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              role['icon'],
                              size: 50,
                              color: selectedRole == role['name']
                                  ? Colors.blue
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              role['name']!,
                              style: TextStyle(
                                color: selectedRole == role['name']
                                    ? Colors.blue
                                    : Colors.black,
                                fontWeight: selectedRole == role['name']
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Continue',
                onPressed: selectedRole != null
                    ? () {
                        if (selectedRole == 'Primary School') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ParentContactDetailsScreen(),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
