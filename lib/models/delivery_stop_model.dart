import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryStopModel {
  final String stopId;
  final String routeId;
  final String locationId; // Keeps ID for reference
  final String name;      // Added for display
  final double lat;       // Added for map
  final double lng;       // Added for map
  final int sequenceOrder;
  final String status; // Pending, Arrived, Completed
  final DateTime? arrivalTime;
  final DateTime? completionTime;
  final String? proofOfDeliveryUrl;
  final String? signatureUrl;

  DeliveryStopModel({
    required this.stopId,
    required this.routeId,
    required this.locationId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.sequenceOrder,
    this.status = 'Pending',
    this.arrivalTime,
    this.completionTime,
    this.proofOfDeliveryUrl,
    this.signatureUrl,
  });

  factory DeliveryStopModel.fromMap(Map<String, dynamic> map) {
    return DeliveryStopModel(
      stopId: map['stop_id'] ?? '',
      routeId: map['route_id'] ?? '',
      locationId: map['location_id'] ?? map['name'] ?? '',
      name: map['name'] ?? 'Unnamed Stop',
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      sequenceOrder: map['sequence_order'] ?? 0,
      status: map['status'] ?? 'Pending',
      arrivalTime: map['arrival_time'] != null ? (map['arrival_time'] as Timestamp).toDate() : null,
      completionTime: map['completion_time'] != null ? (map['completion_time'] as Timestamp).toDate() : null,
      proofOfDeliveryUrl: map['proof_of_delivery_url'],
      signatureUrl: map['signature_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stop_id': stopId,
      'route_id': routeId,
      'location_id': locationId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'sequence_order': sequenceOrder,
      'status': status,
      'arrival_time': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'completion_time': completionTime != null ? Timestamp.fromDate(completionTime!) : null,
      'proof_of_delivery_url': proofOfDeliveryUrl,
      'signature_url': signatureUrl,
    };
  }
}
