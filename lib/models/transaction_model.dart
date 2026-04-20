import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String transactionId;
  final String businessId;
  final double amount;
  final String currency;
  final String status; // success, failed, pending
  final String type; // subscription, top-up
  final String paymentMethod; // Paystack, Flutterwave
  final DateTime createdAt;
  final String? reference;

  TransactionModel({
    required this.transactionId,
    required this.businessId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    required this.paymentMethod,
    required this.createdAt,
    this.reference,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transaction_id'] ?? '',
      businessId: map['business_id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'XOF',
      status: map['status'] ?? 'pending',
      type: map['type'] ?? 'subscription',
      paymentMethod: map['payment_method'] ?? 'Paystack',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      reference: map['reference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'business_id': businessId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'type': type,
      'payment_method': paymentMethod,
      'created_at': Timestamp.fromDate(createdAt),
      'reference': reference,
    };
  }
}
