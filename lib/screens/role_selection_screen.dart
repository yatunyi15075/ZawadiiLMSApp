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

  final List<Map<String, String>> roles = [
    {'name': 'Student', 'icon': 'student_icon.png'},
    {'name': 'High School', 'icon': 'high_school_icon.png'},
    {'name': 'Primary School', 'icon': 'primary_school_icon.png'},
    {'name': 'Teacher', 'icon': 'teacher_icon.png'},
    {'name': 'Exploring', 'icon': 'exploring_icon.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/${role['icon']}',
                              width: 50,
                              height: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              role['name']!,
                              style: TextStyle(
                                color: selectedRole == role['name']
                                   ? Colors.blue
                                   : Colors.black,
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
                        // Navigate to parent contact details screen for Primary School
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ParentContactDetailsScreen(),
                          ),
                        );
                      } else {
                        // Navigate directly to home screen for all other roles
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