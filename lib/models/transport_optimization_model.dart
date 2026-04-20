class TransportOptimizationResult {
  final double totalCost;
  final List<Shipment> shipments;
  final double savings;
  final double savingsPercentage;
  final DateTime timestamp;

  TransportOptimizationResult({
    required this.totalCost,
    required this.shipments,
    required this.savings,
    required this.savingsPercentage,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'total_cost': totalCost,
      'shipments': shipments.map((s) => s.toMap()).toList(),
      'savings': savings,
      'savings_percentage': savingsPercentage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransportOptimizationResult.fromMap(Map<String, dynamic> map) {
    return TransportOptimizationResult(
      totalCost: (map['total_cost'] as num).toDouble(),
      shipments: (map['shipments'] as List)
          .map((s) => Shipment.fromMap(s as Map<String, dynamic>))
          .toList(),
      savings: (map['savings'] as num?)?.toDouble() ?? 0.0,
      savingsPercentage: (map['savings_percentage'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class Shipment {
  final String fromPoint;
  final String toPoint;
  final int quantity;
  final double costPerUnit;
  final double totalCost;

  Shipment({
    required this.fromPoint,
    required this.toPoint,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'from_point': fromPoint,
      'to_point': toPoint,
      'quantity': quantity,
      'cost_per_unit': costPerUnit,
      'total_cost': totalCost,
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map) {
    return Shipment(
      fromPoint: map['from_point'] as String,
      toPoint: map['to_point'] as String,
      quantity: map['quantity'] as int,
      costPerUnit: (map['cost_per_unit'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
    );
  }
}

class SupplyPoint {
  final String id;
  final String name;
  final String location;
  final int availableQuantity;

  SupplyPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.availableQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'available_quantity': availableQuantity,
    };
  }

  factory SupplyPoint.fromMap(Map<String, dynamic> map) {
    return SupplyPoint(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      availableQuantity: map['available_quantity'] as int,
    );
  }
}

class DemandPoint {
  final String id;
  final String name;
  final String location;
  final int requiredQuantity;

  DemandPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.requiredQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'required_quantity': requiredQuantity,
    };
  }

  factory DemandPoint.fromMap(Map<String, dynamic> map) {
    return DemandPoint(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      requiredQuantity: map['required_quantity'] as int,
    );
  }
}
