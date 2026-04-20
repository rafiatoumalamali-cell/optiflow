class PlanModel {
  final String planId;
  final String name;
  final double price;
  final List<String> features;
  final bool isPopular;
  final String currency;
  final int maxUsers;
  final int maxDeliveries;
  final bool hasAdvancedFeatures;
  final bool hasPrioritySupport;
  final String description;

  PlanModel({
    required this.planId,
    required this.name,
    required this.price,
    required this.features,
    this.isPopular = false,
    this.currency = 'XOF',
    this.maxUsers = 5,
    this.maxDeliveries = 50,
    this.hasAdvancedFeatures = false,
    this.hasPrioritySupport = false,
    this.description = '',
  });

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      planId: map['plan_id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      features: List<String>.from(map['features'] ?? []),
      isPopular: map['is_popular'] ?? false,
      currency: map['currency'] ?? 'XOF',
      maxUsers: map['max_users'] ?? 5,
      maxDeliveries: map['max_deliveries'] ?? 50,
      hasAdvancedFeatures: map['has_advanced_features'] ?? false,
      hasPrioritySupport: map['has_priority_support'] ?? false,
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan_id': planId,
      'name': name,
      'price': price,
      'features': features,
      'is_popular': isPopular,
      'currency': currency,
      'max_users': maxUsers,
      'max_deliveries': maxDeliveries,
      'has_advanced_features': hasAdvancedFeatures,
      'has_priority_support': hasPrioritySupport,
      'description': description,
    };
  }
}
