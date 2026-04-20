import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String resourceId;
  final String businessId;
  final String name;
  final double availableQuantity;
  final String unit;
  final String constraintType; // 'LE', 'GE', 'EQ'
  final DateTime createdAt;
  final DateTime updatedAt;

  ResourceModel({
    required this.resourceId,
    required this.businessId,
    required this.name,
    required this.availableQuantity,
    required this.unit,
    this.constraintType = 'LE',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    return ResourceModel(
      resourceId: map['resource_id'] ?? '',
      businessId: map['business_id'] ?? '',
      name: map['name'] ?? '',
      availableQuantity: (map['available_quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      constraintType: map['constraint_type'] ?? 'LE',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resource_id': resourceId,
      'business_id': businessId,
      'name': name,
      'available_quantity': availableQuantity,
      'unit': unit,
      'constraint_type': constraintType,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toSqliteMap() {
     return {
      'resource_id': resourceId,
      'business_id': businessId,
      'name': name,
      'available_quantity': availableQuantity,
      'unit': unit,
      'constraint_type': constraintType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
