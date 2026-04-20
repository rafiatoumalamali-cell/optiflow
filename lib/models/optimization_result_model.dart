import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class OptimizationResultModel {
  final String resultId;
  final String businessId;
  final String type; // Product Mix, Transport, Route, Budget
  final Map<String, dynamic> resultData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  OptimizationResultModel({
    required this.resultId,
    required this.businessId,
    required this.type,
    required this.resultData,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory OptimizationResultModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    dynamic parseData(dynamic data) {
      if (data is String) return jsonDecode(data);
      return data;
    }

    return OptimizationResultModel(
      resultId: map['result_id'] ?? '',
      businessId: map['business_id'] ?? '',
      type: map['type'] ?? '',
      resultData: Map<String, dynamic>.from(parseData(map['result_data']) ?? {}),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      synced: map['synced'] == 1 || map['synced'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'result_id': resultId,
      'business_id': businessId,
      'type': type,
      'result_data': resultData,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'synced': synced,
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'result_id': resultId,
      'business_id': businessId,
      'type': type,
      'result_data': jsonEncode(resultData),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }
}
