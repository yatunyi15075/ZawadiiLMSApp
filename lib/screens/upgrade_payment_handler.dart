import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/upgrade_models.dart';
import '../services/upgrade_service.dart';
import '../theme/app_theme.dart';

class UpgradePaymentHandler extends StatefulWidget {
  final SubscriptionPlan selectedPlan;
  final String selectedRegion;
  final VoidCallback onPaymentInitiated;
  final Function(bool success, String message) onPaymentCompleted;
  final bool isLoading;

  const UpgradePaymentHandler({
    Key? key,
    required this.selectedPlan,
    required this.selectedRegion,
    required this.onPaymentInitiated,
    required this.onPaymentCompleted,
    required this.isLoading,
  }) : super(key: key);

  @override
  _UpgradePaymentHandlerState createState() => _UpgradePaymentHandlerState();
}

class _UpgradePaymentHandlerState extends State<UpgradePaymentHandler> {
  final UpgradeService _upgradeService = UpgradeService();
  String _phoneNumber = '';
  bool _showMpesaDialog = false;
  String _localError = '';
  String _localSuccess = '';
  String _userEmail = ''; // You might want to get this from user preferences/state

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentHeader(),
          const SizedBox(height: 16),
          _buildPlanSummary(),
          const SizedBox(height: 20),
          _buildPaymentButtons(),
          if (_showMpesaDialog) _buildMpesaDialog(),
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.payment,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Complete Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Plan:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                widget.selectedPlan.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${widget.selectedPlan.displayPrice}/${widget.selectedPlan.period}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (widget.selectedPlan.savings != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'You Save:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  widget.selectedPlan.savings!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentButtons() {
    final isKenyan = widget.selectedRegion == 'kenya';
    
    if (isKenyan) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPaymentButton(
                  label: 'Credit Card',
                  icon: Icons.credit_card,
                  color: const Color(0xFF1E293B),
                  onPressed: _handleCreditCardPayment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentButton(
                  label: 'M-Pesa',
                  icon: Icons.phone_android,
                  color: const Color(0xFF10B981),
                  onPressed: () => setState(() => _showMpesaDialog = true),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: _buildPaymentButton(
          label: 'Subscribe Now',
          icon: Icons.credit_card,
          color: AppTheme.primaryColor,
          onPressed: _handleInternationalPayment,
        ),
      );
    }
  }

  Widget _buildPaymentButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: widget.isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        widget.isLoading ? 'Processing...' : label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        disabledBackgroundColor: color.withOpacity(0.6),
      ),
    );
  }

  Widget _buildMpesaDialog() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'M-Pesa Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _showMpesaDialog = false;
                  _localError = '';
                  _localSuccess = '';
                }),
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Enter M-Pesa Phone Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          
          TextField(
            onChanged: (value) => _phoneNumber = value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '0712345678 or 254712345678',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(
                Icons.phone,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
            keyboardType: TextInputType.phone,
          ),

          if (_localError.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localError,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_localSuccess.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localSuccess,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            'You will receive an M-Pesa prompt on this number',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : _handleMpesaPayment,
              icon: const Icon(Icons.send, size: 18),
              label: Text(
                widget.isLoading ? 'Processing...' : 'Send M-Pesa Request',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreditCardPayment() async {
    widget.onPaymentInitiated();

    try {
      String? paymentUrl;
      
      if (widget.selectedRegion == 'kenya') {
        paymentUrl = widget.selectedPlan.paystackPlanCode;
      } else {
        paymentUrl = widget.selectedPlan.gatewayPlanId;
      }

      if (paymentUrl != null) {
        final Uri uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          widget.onPaymentCompleted(true, 'Redirected to payment page');
        } else {
          widget.onPaymentCompleted(false, 'Could not launch payment page');
        }
      } else {
        widget.onPaymentCompleted(false, 'Payment URL not available');
      }
    } catch (e) {
      widget.onPaymentCompleted(false, 'Error launching payment: $e');
    }
  }

  void _handleInternationalPayment() async {
    widget.onPaymentInitiated();

    try {
      // For international payments, we can either:
      // 1. Create a subscription via API and get payment URL
      // 2. Or directly use the gatewayPlanId URL (as in your static data)
      
      // Method 1: Create subscription via API
      if (_userEmail.isNotEmpty) {
        final response = await _upgradeService.createInternationalSubscription(
          amount: widget.selectedPlan.price,
          email: _userEmail,
          planId: widget.selectedPlan.id,
          currency: widget.selectedPlan.currency,
        );

        if (response.success && response.paymentUrl != null) {
          final Uri uri = Uri.parse(response.paymentUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            widget.onPaymentCompleted(true, 'Redirected to payment page');
          } else {
            widget.onPaymentCompleted(false, 'Could not launch payment page');
          }
        } else {
          widget.onPaymentCompleted(false, response.message);
        }
      } else {
        // Method 2: Use static gateway URL (fallback)
        if (widget.selectedPlan.gatewayPlanId != null) {
          final Uri uri = Uri.parse(widget.selectedPlan.gatewayPlanId!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            widget.onPaymentCompleted(true, 'Redirected to payment page');
          } else {
            widget.onPaymentCompleted(false, 'Could not launch payment page');
          }
        } else {
          widget.onPaymentCompleted(false, 'Payment URL not available');
        }
      }
    } catch (e) {
      widget.onPaymentCompleted(false, 'Error processing payment: $e');
    }
  }

  void _handleMpesaPayment() async {
    // Validate phone number
    if (_phoneNumber.isEmpty) {
      setState(() {
        _localError = 'Please enter your M-Pesa phone number';
        _localSuccess = '';
      });
      return;
    }

    if (!_upgradeService.validatePhoneNumber(_phoneNumber)) {
      setState(() {
        _localError = 'Please enter a valid Kenyan phone number';
        _localSuccess = '';
      });
      return;
    }

    widget.onPaymentInitiated();
    setState(() {
      _localError = '';
      _localSuccess = '';
    });

    try {
      // Format phone number
      final formattedPhone = _upgradeService.formatPhoneNumber(_phoneNumber);
      
      // Create M-Pesa payment request
      final response = await _upgradeService.createMpesaPayment(
        amount: widget.selectedPlan.price,
        phoneNumber: formattedPhone,
        email: _userEmail.isNotEmpty ? _userEmail : 'customer@example.com',
        planId: widget.selectedPlan.id,
      );

      if (response.success) {
        setState(() {
          _localSuccess = 'M-Pesa prompt sent to your phone. Please complete the payment.';
          _localError = '';
        });
        
        // Optionally start polling for payment status
        _pollPaymentStatus(response.transactionId);
        
        widget.onPaymentCompleted(true, response.message);
      } else {
        setState(() {
          _localError = response.message;
          _localSuccess = '';
        });
        widget.onPaymentCompleted(false, response.message);
      }
    } catch (e) {
      setState(() {
        _localError = 'Failed to process M-Pesa payment: $e';
        _localSuccess = '';
      });
      widget.onPaymentCompleted(false, 'M-Pesa payment failed: $e');
    }
  }

  void _pollPaymentStatus(String? transactionId) async {
    if (transactionId == null) return;

    // Poll for payment status every 5 seconds for up to 2 minutes
    int attempts = 0;
    const maxAttempts = 24; // 24 * 5 seconds = 2 minutes
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
      
      try {
        final response = await _upgradeService.verifyPayment(transactionId);
        
        if (response.success) {
          if (response.status == 'completed' || response.status == 'success') {
            setState(() {
              _localSuccess = 'Payment completed successfully!';
              _localError = '';
            });
            widget.onPaymentCompleted(true, 'Payment completed successfully');
            break;
          } else if (response.status == 'failed' || response.status == 'cancelled') {
            setState(() {
              _localError = 'Payment was cancelled or failed';
              _localSuccess = '';
            });
            widget.onPaymentCompleted(false, 'Payment failed');
            break;
          }
          // If status is 'pending', continue polling
        }
      } catch (e) {
        // Continue polling on error
        continue;
      }
    }
    
    if (attempts >= maxAttempts) {
      setState(() {
        _localError = 'Payment verification timeout. Please contact support if payment was deducted.';
        _localSuccess = '';
      });
    }
  }

  // Helper method to get user email - you might want to implement this based on your state management
  void _initializeUserEmail() {
    // Get email from user preferences, SharedPreferences, or state management
    // Example:
    // _userEmail = UserPreferences.getEmail() ?? '';
    _userEmail = 'user@example.com'; // Placeholder
  }

  @override
  void initState() {
    super.initState();
    _initializeUserEmail();
  }

  @override
  void dispose() {
    super.dispose();
  }
}