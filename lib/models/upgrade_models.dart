class SubscriptionPlan {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String period;
  final String displayPrice;
  final String subtitle;
  final String? paystackPlanCode; // For Kenya credit card payments
  final String? gatewayPlanId; // For international payments
  final String? savings;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.period,
    required this.displayPrice,
    required this.subtitle,
    this.paystackPlanCode,
    this.gatewayPlanId,
    this.savings,
    this.isPopular = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      title: json['title'],
      price: json['price'].toDouble(),
      currency: json['currency'],
      period: json['period'],
      displayPrice: json['displayPrice'],
      subtitle: json['subtitle'],
      paystackPlanCode: json['paystackPlanCode'],
      gatewayPlanId: json['gatewayPlanId'],
      savings: json['savings'],
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'currency': currency,
      'period': period,
      'displayPrice': displayPrice,
      'subtitle': subtitle,
      'paystackPlanCode': paystackPlanCode,
      'gatewayPlanId': gatewayPlanId,
      'savings': savings,
      'isPopular': isPopular,
    };
  }
}

class PaymentRequest {
  final double amount;
  final String phoneNumber;
  final String email;
  final String planId;
  final String currency;
  final String region;

  PaymentRequest({
    required this.amount,
    required this.phoneNumber,
    required this.email,
    required this.planId,
    required this.currency,
    required this.region,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'phoneNumber': phoneNumber,
      'email': email,
      'planId': planId,
      'currency': currency,
      'region': region,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String status;
  final String message;
  final String? paymentUrl;
  final String? transactionId;
  final Map<String, dynamic>? additionalData;

  PaymentResponse({
    required this.success,
    required this.status,
    required this.message,
    this.paymentUrl,
    this.transactionId,
    this.additionalData,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? (json['status'] == 'success'),
      status: json['status'] ?? 'unknown',
      message: json['message'] ?? 'No message provided',
      paymentUrl: json['payment_url'] ?? json['paymentUrl'],
      transactionId: json['transaction_id'] ?? json['transactionId'],
      additionalData: json['data'],
    );
  }
}

class SubscriptionStatus {
  final bool isActive;
  final String? planId;
  final DateTime? expiresAt;
  final String? status;
  final bool autoRenew;

  SubscriptionStatus({
    required this.isActive,
    this.planId,
    this.expiresAt,
    this.status,
    this.autoRenew = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['isActive'] ?? false,
      planId: json['planId'],
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      status: json['status'],
      autoRenew: json['autoRenew'] ?? false,
    );
  }
}

// Static plan data matching your webapp
class PlanData {
  // Kenya plans with proper backend URLs
  static final List<SubscriptionPlan> kenyaPlans = [
    SubscriptionPlan(
      id: 'kes-daily',
      title: 'Daily Access',
      price: 20,
      currency: 'KES',
      period: 'day',
      displayPrice: 'KSh 20',
      subtitle: 'Perfect for trying out',
      paystackPlanCode: 'https://paystack.shop/pay/-294l14o5j',
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'kes-weekly',
      title: 'Weekly Access',
      price: 100,
      currency: 'KES',
      period: 'week',
      displayPrice: 'KSh 100',
      subtitle: 'Great for short projects',
      paystackPlanCode: 'https://paystack.shop/pay/-294l14o5j',
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'kes-monthly',
      title: 'Monthly Access',
      price: 350,
      currency: 'KES',
      period: 'month',
      displayPrice: 'KSh 350',
      subtitle: 'Most flexible option',
      paystackPlanCode: 'https://paystack.shop/pay/-294l14o5j',
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'kes-yearly',
      title: 'Yearly Access',
      price: 3500,
      currency: 'KES',
      period: 'year',
      displayPrice: 'KSh 3,500',
      subtitle: 'Best value - Save 58%',
      paystackPlanCode: 'https://paystack.shop/pay/-294l14o5j',
      savings: 'Save KSh 4,700',
      isPopular: true,
    ),
  ];

  // International plans with proper backend URLs
  static final List<SubscriptionPlan> internationalPlans = [
    SubscriptionPlan(
      id: 'usd-weekly',
      title: 'Weekly Plan',
      price: 4,
      currency: 'USD',
      period: 'week',
      displayPrice: '\$4',
      subtitle: 'Auto-renews weekly',
      gatewayPlanId: 'https://paystack.shop/pay/jet-nqebel',
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'usd-monthly',
      title: 'Monthly Plan',
      price: 15,
      currency: 'USD',
      period: 'month',
      displayPrice: '\$15',
      subtitle: 'Auto-renews monthly',
      gatewayPlanId: 'https://paystack.shop/pay/jet-nqebel',
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'usd-yearly',
      title: 'Yearly Plan',
      price: 150,
      currency: 'USD',
      period: 'year',
      displayPrice: '\$150',
      subtitle: 'Auto-renews yearly - Best value',
      gatewayPlanId: 'https://paystack.shop/pay/jet-nqebel',
      savings: 'Save \$30',
      isPopular: false,
    ),
  ];

  static List<SubscriptionPlan> getPlansForRegion(String region) {
    return region == 'kenya' ? kenyaPlans : internationalPlans;
  }
}