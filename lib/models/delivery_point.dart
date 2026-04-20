import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Delivery point model for logistics operations
class DeliveryPoint {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final DeliveryPointType type;
  final DeliveryStatus status;
  final DateTime? scheduledTime;
  final DateTime? completedTime;
  final String? notes;
  final String? contactPhone;
  final String? contactName;
  final Map<String, dynamic>? metadata;
  
  DeliveryPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.type,
    required this.status,
    this.scheduledTime,
    this.completedTime,
    this.notes,
    this.contactPhone,
    this.contactName,
    this.metadata,
  });
  
  factory DeliveryPoint.fromJson(Map<String, dynamic> json) {
    return DeliveryPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      location: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      type: DeliveryPointType.values.firstWhere(
        (type) => type.toString() == 'DeliveryPointType.${json['type']}',
        orElse: () => DeliveryPointType.delivery,
      ),
      status: DeliveryStatus.values.firstWhere(
        (status) => status.toString() == 'DeliveryStatus.${json['status']}',
        orElse: () => DeliveryStatus.pending,
      ),
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['scheduledTime'] as int)
          : null,
      completedTime: json['completedTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedTime'] as int)
          : null,
      notes: json['notes'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactName: json['contactName'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduledTime': scheduledTime?.millisecondsSinceEpoch,
      'completedTime': completedTime?.millisecondsSinceEpoch,
      'notes': notes,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'metadata': metadata,
    };
  }
  
  DeliveryPoint copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? location,
    DeliveryPointType? type,
    DeliveryStatus? status,
    DateTime? scheduledTime,
    DateTime? completedTime,
    String? notes,
    String? contactPhone,
    String? contactName,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      notes: notes ?? this.notes,
      contactPhone: contactPhone ?? this.contactPhone,
      contactName: contactName ?? this.contactName,
      metadata: metadata ?? this.metadata,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryPoint && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'DeliveryPoint(id: $id, name: $name, type: $type, status: $status)';
  }
}

/// Delivery point types
enum DeliveryPointType {
  pickup,
  delivery,
  warehouse,
  distribution,
}

/// Delivery status
enum DeliveryStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Delivery priority levels
enum DeliveryPriority {
  low,
  normal,
  high,
  urgent,
}
