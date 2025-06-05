import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  _UpgradeScreenState createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  int _selectedPlanIndex = 1; // Default to monthly plan

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Weekly',
      'price': '฿50.00/week',
      'savings': null,
    },
    {
      'title': 'Monthly',
      'price': '฿300.00/month',
      'savings': 'Most Popular',
    },
    {
      'title': 'Yearly',
      'price': '฿1,440.00/year',
      'savings': 'Save 20%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Unlimited'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Unlimited Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeaturesList(),
            const SizedBox(height: 16),
            _buildPlanSelection(),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Get Unlimited Now',
              onPressed: () {
                // TODO: Implement purchase logic
                _handlePurchase();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Unlimited Audio Notes',
      'Feynman AI Notes & Tests',
      'Unlimited PDF Notes',
      'Unlimited Mindmap Generation',
      'Unlimited AI Features',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(feature),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      children: List.generate(_plans.length, (index) {
        final plan = _plans[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPlanIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedPlanIndex == index 
                  ? AppTheme.primaryColor 
                  : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Radio<int>(
                value: index,
                groupValue: _selectedPlanIndex,
                onChanged: (value) {
                  setState(() {
                    _selectedPlanIndex = value!;
                  });
                },
              ),
              title: Text(plan['title']),
              subtitle: Text(plan['price']),
              trailing: plan['savings'] != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      plan['savings'],
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
            ),
          ),
        );
      }),
    );
  }

  void _handlePurchase() {
    final selectedPlan = _plans[_selectedPlanIndex];
    print('Selected plan: ${selectedPlan['title']} - ${selectedPlan['price']}');
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Text('You have selected the ${selectedPlan['title']} plan for ${selectedPlan['price']}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement actual purchase logic here
                // This is where you would integrate with your payment system
                _showPurchaseSuccess();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchase successful! Welcome to unlimited features!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}