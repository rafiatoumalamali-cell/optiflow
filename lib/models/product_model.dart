import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String businessId;
  final String name;
  final double sellingPrice;
  final double productionCost;
  final String unit;
  final double profitMargin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl; 

  ProductModel({
    required this.productId,
    required this.businessId,
    required this.name,
    required this.sellingPrice,
    required this.productionCost,
    required this.unit,
    required this.profitMargin,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    return ProductModel(
      productId: map['product_id'] ?? '',
      businessId: map['business_id'] ?? '',
      name: map['name'] ?? '',
      sellingPrice: (map['selling_price'] ?? 0.0).toDouble(),
      productionCost: (map['production_cost'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      profitMargin: (map['profit_margin'] ?? 0.0).toDouble(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'business_id': businessId,
      'name': name,
      'selling_price': sellingPrice,
      'production_cost': productionCost,
      'unit': unit,
      'profit_margin': profitMargin,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'image_url': imageUrl,
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'product_id': productId,
      'business_id': businessId,
      'name': name,
      'selling_price': sellingPrice,
      'production_cost': productionCost,
      'unit': unit,
      'profit_margin': profitMargin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}
