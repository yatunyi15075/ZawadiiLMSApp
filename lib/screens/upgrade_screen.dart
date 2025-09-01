import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';
import 'upgrade_plan_selector.dart';
import 'upgrade_payment_handler.dart';
import '../models/upgrade_models.dart';
import '../services/upgrade_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  _UpgradeScreenState createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> with TickerProviderStateMixin {
  String _selectedRegion = 'kenya';
  SubscriptionPlan? _selectedPlan;
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final UpgradeService _upgradeService = UpgradeService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleRegionChanged(String region) {
    setState(() {
      _selectedRegion = region;
      _selectedPlan = null; // Reset plan when region changes
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _handlePlanSelected(SubscriptionPlan plan) {
    setState(() {
      _selectedPlan = plan;
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _handlePaymentInitiated() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _handlePaymentCompleted(bool success, String message) {
    setState(() {
      _isLoading = false;
      if (success) {
        _successMessage = message;
        _errorMessage = '';
      } else {
        _errorMessage = message;
        _successMessage = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Upgrade to Premium',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildRegionSelector(),
              UpgradePlanSelector(
                selectedRegion: _selectedRegion,
                selectedPlan: _selectedPlan,
                onPlanSelected: _handlePlanSelected,
                isLoading: _isLoading,
              ),
              if (_selectedPlan != null) ...[
                const SizedBox(height: 24),
                UpgradePaymentHandler(
                  selectedPlan: _selectedPlan!,
                  selectedRegion: _selectedRegion,
                  onPaymentInitiated: _handlePaymentInitiated,
                  onPaymentCompleted: _handlePaymentCompleted,
                  isLoading: _isLoading,
                ),
              ],
              if (_errorMessage.isNotEmpty) _buildErrorMessage(),
              if (_successMessage.isNotEmpty) _buildSuccessMessage(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Get unlimited access to all premium features',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.chat_bubble_outline, 'text': 'Unlimited AI conversations'},
      {'icon': Icons.flash_on_outlined, 'text': 'Advanced AI capabilities'},
      {'icon': Icons.support_agent_outlined, 'text': 'Priority support'},
      {'icon': Icons.download_outlined, 'text': 'Export conversations'},
      {'icon': Icons.block, 'text': 'Ad-free experience'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: const Color(0xFF10B981),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature['text'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRegionSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Region',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleRegionChanged('kenya'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRegion == 'kenya' 
                            ? Colors.white 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedRegion == 'kenya' 
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          const Text('🇰🇪', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            'Kenya',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedRegion == 'kenya' 
                                  ? FontWeight.w600 
                                  : FontWeight.w500,
                              color: _selectedRegion == 'kenya' 
                                  ? const Color(0xFF1E293B) 
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'One-time payment',
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedRegion == 'kenya' 
                                  ? const Color(0xFF64748B) 
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleRegionChanged('international'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRegion == 'international' 
                            ? Colors.white 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedRegion == 'international' 
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          const Text('🌍', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            'International',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedRegion == 'international' 
                                  ? FontWeight.w600 
                                  : FontWeight.w500,
                              color: _selectedRegion == 'international' 
                                  ? const Color(0xFF1E293B) 
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Subscription',
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedRegion == 'international' 
                                  ? const Color(0xFF64748B) 
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}