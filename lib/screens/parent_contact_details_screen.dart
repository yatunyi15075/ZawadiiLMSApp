import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../screens/home_screen.dart';

class ParentContactDetailsScreen extends StatefulWidget {
  const ParentContactDetailsScreen({Key? key}) : super(key: key);

  @override
  _ParentContactDetailsScreenState createState() => _ParentContactDetailsScreenState();
}

class _ParentContactDetailsScreenState extends State<ParentContactDetailsScreen> {
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent\'s Contact Details',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              _buildTextField('Parent\'s Name', _parentNameController),
              const SizedBox(height: 10),
              _buildTextField('Parent\'s Email', _parentEmailController),
              const SizedBox(height: 10),
              _buildTextField('Parent\'s Phone Number', _parentPhoneController),
              const Spacer(),
              CustomButton(
                text: 'Continue',
                onPressed: () {
                  // TODO: Implement validation and navigation
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }
}