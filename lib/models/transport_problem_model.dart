import 'package:cloud_firestore/cloud_firestore.dart';

class TransportProblem {
  final String? id;
  final String name;
  final String description;
  final String businessId;
  final List<SupplyPointData> supplyPoints;
  final List<DemandPointData> demandPoints;
  final List<List<double>> costMatrix;
  final TransportOptimizationResult? lastResult;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  TransportProblem({
    this.id,
    required this.name,
    required this.description,
    required this.businessId,
    required this.supplyPoints,
    required this.demandPoints,
    required this.costMatrix,
    this.lastResult,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  TransportProblem copyWith({
    String? id,
    String? name,
    String? description,
    String? businessId,
    List<SupplyPointData>? supplyPoints,
    List<DemandPointData>? demandPoints,
    List<List<double>>? costMatrix,
    TransportOptimizationResult? lastResult,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return TransportProblem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessId: businessId ?? this.businessId,
      supplyPoints: supplyPoints ?? this.supplyPoints,
      demandPoints: demandPoints ?? this.demandPoints,
      costMatrix: costMatrix ?? this.costMatrix,
      lastResult: lastResult ?? this.lastResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'businessId': businessId,
      'supplyPoints': supplyPoints.map((sp) => sp.toMap()).toList(),
      'demandPoints': demandPoints.map((dp) => dp.toMap()).toList(),
      'costMatrix': costMatrix,
      'lastResult': lastResult?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  factory TransportProblem.fromMap(Map<String, dynamic> map, String? id) {
    return TransportProblem(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      businessId: map['businessId'] as String,
      supplyPoints: (map['supplyPoints'] as List)
          .map((sp) => SupplyPointData.fromMap(sp as Map<String, dynamic>))
          .toList(),
      demandPoints: (map['demandPoints'] as List)
          .map((dp) => DemandPointData.fromMap(dp as Map<String, dynamic>))
          .toList(),
      costMatrix: (map['costMatrix'] as List)
          .map((row) => (row as List).map((cell) => (cell as num).toDouble()).toList())
          .toList(),
      lastResult: map['lastResult'] != null
          ? TransportOptimizationResult.fromMap(map['lastResult'] as Map<String, dynamic>)
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }
}

class SupplyPointData {
  final String id;
  final String name;
  final String location;
  final int availableQuantity;

  SupplyPointData({
    this.id = '',
    required this.name,
    required this.location,
    required this.availableQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'availableQuantity': availableQuantity,
    };
  }

  factory SupplyPointData.fromMap(Map<String, dynamic> map) {
    return SupplyPointData(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      availableQuantity: map['availableQuantity'] as int,
    );
  }
}

class DemandPointData {
  final String id;
  final String name;
  final String location;
  final int requiredQuantity;

  DemandPointData({
    this.id = '',
    required this.name,
    required this.location,
    required this.requiredQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'requiredQuantity': requiredQuantity,
    };
  }

  factory DemandPointData.fromMap(Map<String, dynamic> map) {
    return DemandPointData(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      requiredQuantity: map['requiredQuantity'] as int,
    );
  }
}

class TransportOptimizationResult {
  final double totalCost;
  final List<ShipmentData> shipments;
  final double savings;
  final double savingsPercentage;
  final DateTime timestamp;
  final bool wasBalanced;
  final int? excessSupply;
  final int? excessDemand;

  TransportOptimizationResult({
    required this.totalCost,
    required this.shipments,
    required this.savings,
    required this.savingsPercentage,
    required this.timestamp,
    this.wasBalanced = false,
    this.excessSupply,
    this.excessDemand,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalCost': totalCost,
      'shipments': shipments.map((s) => s.toMap()).toList(),
      'savings': savings,
      'savingsPercentage': savingsPercentage,
      'timestamp': Timestamp.fromDate(timestamp),
      'wasBalanced': wasBalanced,
      'excessSupply': excessSupply,
      'excessDemand': excessDemand,
    };
  }

  factory TransportOptimizationResult.fromMap(Map<String, dynamic> map) {
    return TransportOptimizationResult(
      totalCost: (map['totalCost'] as num).toDouble(),
      shipments: (map['shipments'] as List)
          .map((s) => ShipmentData.fromMap(s as Map<String, dynamic>))
          .toList(),
      savings: (map['savings'] as num?)?.toDouble() ?? 0.0,
      savingsPercentage: (map['savingsPercentage'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      wasBalanced: (map['wasBalanced'] as bool?) ?? false,
      excessSupply: map['excessSupply'] as int?,
      excessDemand: map['excessDemand'] as int?,
    );
  }
}

class ShipmentData {
  final String fromPoint;
  final String toPoint;
  final int quantity;
  final double costPerUnit;
  final double totalCost;

  ShipmentData({
    required this.fromPoint,
    required this.toPoint,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromPoint': fromPoint,
      'toPoint': toPoint,
      'quantity': quantity,
      'costPerUnit': costPerUnit,
      'totalCost': totalCost,
    };
  }

  factory ShipmentData.fromMap(Map<String, dynamic> map) {
    return ShipmentData(
      fromPoint: map['fromPoint'] as String,
      toPoint: map['toPoint'] as String,
      quantity: map['quantity'] as int,
      costPerUnit: (map['costPerUnit'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
    );
  }
}
