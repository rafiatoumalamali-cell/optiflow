import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String locationId;
  final String businessId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // Factory, Retail, Hub
  final double supplyQuantity;
  final double demandQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationModel({
    required this.locationId,
    required this.businessId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.supplyQuantity = 0.0,
    this.demandQuantity = 0.0,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    return LocationModel(
      locationId: map['location_id'] ?? '',
      businessId: map['business_id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      type: map['type'] ?? '',
      supplyQuantity: (map['supply_quantity'] ?? 0.0).toDouble(),
      demandQuantity: (map['demand_quantity'] ?? 0.0).toDouble(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location_id': locationId,
      'business_id': businessId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'supply_quantity': supplyQuantity,
      'demand_quantity': demandQuantity,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
