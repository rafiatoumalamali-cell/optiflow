import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final String routeId;
  final String businessId;
  final String originId;
  final String destinationId;
  final double distanceKm;
  final String estimatedTime;
  final double cost;
  final DateTime createdAt;
  final String status; // 'pending', 'assigned', 'in_progress', 'completed'
  final String? driverId;
  
  // Offline support fields
  final LatLng? startLocation;
  final LatLng? endLocation;
  final List<LatLng> waypoints;
  final bool isOffline;
  final DateTime? lastUsed;

  // Add getters for backward compatibility
  String get name => routeId;
  double get distance => distanceKm;

  RouteModel({
    required this.routeId,
    required this.businessId,
    required this.originId,
    required this.destinationId,
    required this.distanceKm,
    required this.estimatedTime,
    required this.cost,
    required this.createdAt,
    this.status = 'pending', // Default status
    this.driverId,
    this.startLocation,
    this.endLocation,
    this.waypoints = const [],
    this.isOffline = false,
    this.lastUsed,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      routeId: map['route_id'] ?? '',
      businessId: map['business_id'] ?? '',
      originId: map['origin_id'] ?? '',
      destinationId: map['destination_id'] ?? '',
      distanceKm: (map['distance_km'] ?? 0.0).toDouble(),
      estimatedTime: map['estimated_time'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] is Timestamp 
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      status: map['status'] ?? 'pending', // Default to pending if not specified
      driverId: map['driver_id'],
      // Offline fields
      startLocation: map['start_lat'] != null && map['start_lng'] != null
          ? LatLng(map['start_lat'], map['start_lng'])
          : null,
      endLocation: map['end_lat'] != null && map['end_lng'] != null
          ? LatLng(map['end_lat'], map['end_lng'])
          : null,
      waypoints: (map['waypoints'] as List<dynamic>?)
          ?.map((w) => LatLng(w['lat'], w['lng']))
          .cast<LatLng>()
          .toList() ?? [],
      isOffline: map['is_offline'] ?? false,
      lastUsed: map['last_used'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'route_id': routeId,
      'business_id': businessId,
      'origin_id': originId,
      'destination_id': destinationId,
      'distance_km': distanceKm,
      'estimated_time': estimatedTime,
      'cost': cost,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
      'driver_id': driverId,
      // Offline fields
      'start_lat': startLocation?.latitude,
      'start_lng': startLocation?.longitude,
      'end_lat': endLocation?.latitude,
      'end_lng': endLocation?.longitude,
      'waypoints': waypoints.map((w) => {
        'lat': w.latitude,
        'lng': w.longitude,
      }).toList(),
      'is_offline': isOffline,
      'last_used': lastUsed?.millisecondsSinceEpoch,
    };
  }
}
