import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/logger.dart';
import '../models/delivery_point.dart';

class MarkerClusterService {
  static const int _defaultClusterSize = 4;
  static const double _defaultZoomThreshold = 12.0;
  
  final int clusterSize;
  final double zoomThreshold;
  double currentZoom = 10.0;
  
  MarkerClusterService({
    this.clusterSize = _defaultClusterSize,
    this.zoomThreshold = _defaultZoomThreshold,
  });

  /// Cluster markers based on their proximity
  List<Marker> clusterMarkers(List<DeliveryPoint> deliveryPoints, double currentZoom) {
    if (deliveryPoints.isEmpty) return [];
    
    // If zoom is high enough or too few points, return individual markers
    if (currentZoom >= zoomThreshold || deliveryPoints.length <= clusterSize) {
      return _createIndividualMarkers(deliveryPoints);
    }
    
    // Perform clustering
    final clusters = _performClustering(deliveryPoints);
    return _createClusterMarkers(clusters);
  }

  /// Perform the actual clustering algorithm
  List<MarkerCluster> _performClustering(List<DeliveryPoint> deliveryPoints) {
    final clusters = <MarkerCluster>[];
    final unprocessedPoints = List<DeliveryPoint>.from(deliveryPoints);
    
    while (unprocessedPoints.isNotEmpty) {
      // Take the first point as cluster center
      final centerPoint = unprocessedPoints.removeAt(0);
      final cluster = MarkerCluster(
        center: centerPoint.location,
        points: [centerPoint],
      );
      
      // Find nearby points within cluster radius
      final nearbyPoints = <DeliveryPoint>[];
      final remainingPoints = <DeliveryPoint>[];
      
      for (final point in unprocessedPoints) {
        final distance = _calculateDistance(centerPoint.location, point.location);
        if (distance <= _getClusterRadius(currentZoom)) {
          nearbyPoints.add(point);
        } else {
          remainingPoints.add(point);
        }
      }
      
      // Add nearby points to cluster
      cluster.points.addAll(nearbyPoints);
      unprocessedPoints.clear();
      unprocessedPoints.addAll(remainingPoints);
      
      clusters.add(cluster);
    }
    
    return clusters;
  }

  /// Calculate cluster radius based on zoom level
  double _getClusterRadius(double zoom) {
    // Smaller radius at higher zoom levels
    return math.max(50.0, 500.0 / math.pow(2, zoom - 10));
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Create individual markers for high zoom levels
  List<Marker> _createIndividualMarkers(List<DeliveryPoint> deliveryPoints) {
    return deliveryPoints.map((point) {
      return Marker(
        markerId: MarkerId(point.id),
        position: point.location,
        infoWindow: InfoWindow(
          title: point.name,
          snippet: '${point.address} • ${point.status}',
        ),
        icon: _getMarkerIcon(point.type, point.status),
        onTap: () {
          Logger.info('Tapped marker: ${point.name}', name: 'MarkerCluster');
        },
      );
    }).toList();
  }

  /// Create cluster markers
  List<Marker> _createClusterMarkers(List<MarkerCluster> clusters) {
    return clusters.map((cluster) {
      return Marker(
        markerId: MarkerId('cluster_${cluster.center.latitude}_${cluster.center.longitude}'),
        position: cluster.center,
        infoWindow: InfoWindow(
          title: '${cluster.points.length} Delivery Points',
          snippet: 'Tap to zoom in and see individual points',
        ),
        icon: _getClusterIcon(cluster.points.length),
        onTap: () {
          Logger.info('Tapped cluster with ${cluster.points.length} points', name: 'MarkerCluster');
        },
      );
    }).toList();
  }

  /// Get appropriate marker icon based on type and status
  BitmapDescriptor _getMarkerIcon(DeliveryPointType type, DeliveryStatus status) {
    switch (type) {
      case DeliveryPointType.pickup:
        return BitmapDescriptor.defaultMarkerWithHue(_getStatusColor(status));
      case DeliveryPointType.delivery:
        return BitmapDescriptor.defaultMarkerWithHue(_getStatusColor(status));
      case DeliveryPointType.warehouse:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case DeliveryPointType.distribution:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }
  }

  /// Get color based on delivery status
  double _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return BitmapDescriptor.hueYellow;
      case DeliveryStatus.inProgress:
        return BitmapDescriptor.hueBlue;
      case DeliveryStatus.completed:
        return BitmapDescriptor.hueGreen;
      case DeliveryStatus.failed:
        return BitmapDescriptor.hueRed;
      case DeliveryStatus.cancelled:
        return BitmapDescriptor.hueAzure;
    }
  }

  /// Get cluster icon based on number of points
  BitmapDescriptor _getClusterIcon(int pointCount) {
    // Different colors/sizes based on cluster size
    if (pointCount <= 5) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else if (pointCount <= 10) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  /// Get cluster bounds for zooming
  LatLngBounds getClusterBounds(List<DeliveryPoint> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    
    double minLat = points.first.location.latitude;
    double maxLat = points.first.location.latitude;
    double minLng = points.first.location.longitude;
    double maxLng = points.first.location.longitude;
    
    for (final point in points) {
      minLat = math.min(minLat, point.location.latitude);
      maxLat = math.max(maxLat, point.location.latitude);
      minLng = math.min(minLng, point.location.longitude);
      maxLng = math.max(maxLng, point.location.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

/// Marker cluster data model
class MarkerCluster {
  final LatLng center;
  final List<DeliveryPoint> points;
  
  MarkerCluster({
    required this.center,
    required this.points,
  });
  
  int get pointCount => points.length;
  
  /// Get the average position of all points in the cluster
  LatLng get averagePosition {
    if (points.isEmpty) return center;
    
    double totalLat = 0;
    double totalLng = 0;
    
    for (final point in points) {
      totalLat += point.location.latitude;
      totalLng += point.location.longitude;
    }
    
    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }
}

/// Custom cluster marker widget for more advanced clustering
class ClusterMarkerWidget extends StatelessWidget {
  final int pointCount;
  final VoidCallback? onTap;
  
  const ClusterMarkerWidget({
    super.key,
    required this.pointCount,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _getClusterSize(),
        height: _getClusterSize(),
        decoration: BoxDecoration(
          color: _getClusterColor(),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            pointCount.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: _getFontSize(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  double _getClusterSize() {
    if (pointCount <= 5) return 40.0;
    if (pointCount <= 10) return 50.0;
    if (pointCount <= 20) return 60.0;
    return 70.0;
  }
  
  Color _getClusterColor() {
    if (pointCount <= 5) return Colors.orange;
    if (pointCount <= 10) return Colors.red;
    if (pointCount <= 20) return Colors.purple;
    return Colors.deepPurple;
  }
  
  double _getFontSize() {
    if (pointCount <= 5) return 14.0;
    if (pointCount <= 10) return 16.0;
    if (pointCount <= 20) return 18.0;
    return 20.0;
  }
}
