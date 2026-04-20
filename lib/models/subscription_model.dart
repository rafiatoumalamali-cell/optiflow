import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String businessId;
  final String plan;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // Active, Expired, Cancelled

  SubscriptionModel({
    required this.subscriptionId,
    required this.businessId,
    required this.plan,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      subscriptionId: map['subscription_id'] ?? '',
      businessId: map['business_id'] ?? '',
      plan: map['plan'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      startDate: (map['start_date'] as Timestamp).toDate(),
      endDate: (map['end_date'] as Timestamp).toDate(),
      status: map['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscription_id': subscriptionId,
      'business_id': businessId,
      'plan': plan,
      'price': price,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'status': status,
    };
  }
}
