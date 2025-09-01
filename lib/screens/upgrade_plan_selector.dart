import 'package:flutter/material.dart';
import '../models/upgrade_models.dart';
import '../theme/app_theme.dart';

class UpgradePlanSelector extends StatelessWidget {
  final String selectedRegion;
  final SubscriptionPlan? selectedPlan;
  final Function(SubscriptionPlan) onPlanSelected;
  final bool isLoading;

  const UpgradePlanSelector({
    Key? key,
    required this.selectedRegion,
    required this.selectedPlan,
    required this.onPlanSelected,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plans = PlanData.getPlansForRegion(selectedRegion);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (selectedRegion == 'international')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Auto-renews',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...plans.map((plan) => _buildPlanCard(context, plan)).toList(),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan) {
    final isSelected = selectedPlan?.id == plan.id;
    final isPopular = plan.isPopular;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor
              : isPopular 
                  ? AppTheme.primaryColor.withOpacity(0.5) 
                  : const Color(0xFFE2E8F0),
          width: isSelected || isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => onPlanSelected(plan),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (isPopular)
                Positioned(
                  top: -1,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ Most Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  isPopular ? 28 : 20,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected 
                                      ? AppTheme.primaryColor 
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.subtitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.displayPrice,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? AppTheme.primaryColor 
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  '/${plan.period}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            if (plan.savings != null && plan.savings != 'Most Popular')
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  plan.savings!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Plan features
                    _buildPlanFeatures(plan),
                    
                    const SizedBox(height: 16),
                    
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withOpacity(0.1) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.3) 
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isSelected 
                              ? 'Selected - Tap to see payment options' 
                              : 'Tap to select this plan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : const Color(0xFF64748B),
                          ),
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
    );
  }

  Widget _buildPlanFeatures(SubscriptionPlan plan) {
    // Define features based on plan type
    List<String> features = [];
    
    switch (plan.period) {
      case 'day':
        features = [
          '24-hour premium access',
          'All AI features unlocked',
          'No usage limits',
        ];
        break;
      case 'week':
        features = [
          '7-day premium access',
          'All AI features unlocked',
          'Priority support',
          'Export conversations',
        ];
        break;
      case 'month':
        features = [
          '30-day premium access',
          'All AI features unlocked',
          'Priority support',
          'Export conversations',
          'Advanced prompts',
        ];
        break;
      case 'year':
        features = [
          '365-day premium access',
          'All AI features unlocked',
          'Priority support',
          'Export conversations',
          'Advanced prompts',
          'Early access to new features',
        ];
        break;
    }

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              feature,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}