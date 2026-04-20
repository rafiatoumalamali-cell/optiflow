class ProductResourceRequirement {
  final String productId;
  final String resourceId;
  final double quantityRequired;

  ProductResourceRequirement({
    required this.productId,
    required this.resourceId,
    required this.quantityRequired,
  });

  factory ProductResourceRequirement.fromMap(Map<String, dynamic> map) {
    return ProductResourceRequirement(
      productId: map['product_id'] ?? '',
      resourceId: map['resource_id'] ?? '',
      quantityRequired: (map['quantity_required'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'resource_id': resourceId,
      'quantity_required': quantityRequired,
    };
  }
}
