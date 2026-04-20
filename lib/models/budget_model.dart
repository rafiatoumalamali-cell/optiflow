import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String budgetId;
  final String businessId;
  final double totalAmount;
  final Map<String, double> departmentalAllocation; // { 'Production': 0.45, ... }
  final Map<String, double> regionalAllocation; // { 'Lagos': 4500000, ... }
  final double minProfitTarget;
  final double maxLaborCost;
  final DateTime createdAt;

  BudgetModel({
    required this.budgetId,
    required this.businessId,
    required this.totalAmount,
    required this.departmentalAllocation,
    required this.regionalAllocation,
    required this.minProfitTarget,
    required this.maxLaborCost,
    required this.createdAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    dynamic parseMap(dynamic data) {
      if (data is String) return jsonDecode(data);
      return data;
    }

    final deptMap = parseMap(map['departmental_allocation']);
    final regMap = parseMap(map['regional_allocation']);

    return BudgetModel(
      budgetId: map['budget_id'] ?? '',
      businessId: map['business_id'] ?? '',
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      departmentalAllocation: Map<String, double>.from(deptMap ?? {}),
      regionalAllocation: Map<String, double>.from(regMap ?? {}),
      minProfitTarget: (map['min_profit_target'] ?? 0.0).toDouble(),
      maxLaborCost: (map['max_labor_cost'] ?? 0.0).toDouble(),
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budget_id': budgetId,
      'business_id': businessId,
      'total_amount': totalAmount,
      'departmental_allocation': departmentalAllocation,
      'regional_allocation': regionalAllocation,
      'min_profit_target': minProfitTarget,
      'max_labor_cost': maxLaborCost,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'budget_id': budgetId,
      'business_id': businessId,
      'total_amount': totalAmount,
      'departmental_allocation': jsonEncode(departmentalAllocation),
      'regional_allocation': jsonEncode(regionalAllocation),
      'min_profit_target': minProfitTarget,
      'max_labor_cost': maxLaborCost,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
