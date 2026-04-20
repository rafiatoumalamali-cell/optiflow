import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String businessId;
  final String name;
  final String type; // Manufacturing, Distribution, etc.
  final String country;
  final String city;
  final String currency;
  final bool isVerified;
  final String subscriptionPlan;
  final DateTime createdAt;
  final List<String>? drivers;
  final int remainingFreeOptimizations;

  // Add getters for backward compatibility
  String get id => businessId;
  List<String> get businesses => [businessId];

  BusinessModel({
    required this.businessId,
    required this.name,
    required this.type,
    required this.country,
    required this.city,
    required this.currency,
    this.isVerified = false,
    required this.subscriptionPlan,
    required this.createdAt,
    this.drivers,
    this.remainingFreeOptimizations = 30,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      businessId: map['business_id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      currency: map['currency'] ?? '',
      isVerified: map['is_verified'] ?? false,
      subscriptionPlan: map['subscription_plan'] ?? 'Free',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      drivers: map['drivers'] != null ? List<String>.from(map['drivers']) : null,
      remainingFreeOptimizations: map['remaining_free_optimizations'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_id': businessId,
      'name': name,
      'type': type,
      'country': country,
      'city': city,
      'currency': currency,
      'is_verified': isVerified,
      'subscription_plan': subscriptionPlan,
      'created_at': Timestamp.fromDate(createdAt),
      'drivers': drivers,
      'remaining_free_optimizations': remainingFreeOptimizations,
    };
  }
}
