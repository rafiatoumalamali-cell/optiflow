import '../models/route_model.dart';
import '../utils/logger.dart';
import '../utils/environment.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class MockRouteService {
  // Mock optimized route data
  static Future<RouteModel?> optimizeRoute({
    required List<String> destinations,
    required String origin,
    Map<String, dynamic>? preferences,
  }) async {
    Logger.info('Using mock route optimization', name: 'MockRouteService');
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate mock waypoints
    final waypoints = _generateMockWaypoints(origin, destinations);
    
    return RouteModel(
      routeId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      businessId: 'mock_business',
      originId: origin,
      destinationId: destinations.last,
      distanceKm: _calculateMockDistance(waypoints),
      estimatedTime: _calculateMockTime(waypoints),
      cost: _calculateMockCost(waypoints),
      createdAt: DateTime.now(),
      startLocation: waypoints.first,
      endLocation: waypoints.last,
      waypoints: waypoints,
      isOffline: false,
    );
  }

  // Get mock saved routes
  static Future<List<RouteModel>> getSavedRoutes(String businessId) async {
    Logger.info('Using mock saved routes', name: 'MockRouteService');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate dynamic routes based on businessId hash for variety
    final routes = <RouteModel>[];
    final routeCount = (businessId.hashCode % 5) + 3; // 3-7 routes
    
    for (int i = 0; i < routeCount; i++) {
      final distance = 20.0 + (i * 15.5); // Dynamic distances
      final hours = 1 + (i * 0.5); // Dynamic times
      final minutes = ((hours * 60) % 60).toInt();
      final timeStr = '${hours.floor()}h ${minutes}m';
      
      routes.add(_createMockRoute(
        'route_${i + 1}',
        'Hub ${i + 1}',
        'Destination ${i + 1}',
        distance,
        timeStr,
      ));
    }
    
    return routes;
  }

  // Save mock route
  static Future<bool> saveRoute(RouteModel route) async {
    Logger.info('Mock saving route: ${route.routeId}', name: 'MockRouteService');
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // Get mock route by ID
  static Future<RouteModel?> getRouteById(String routeId) async {
    Logger.info('Mock getting route: $routeId', name: 'MockRouteService');
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _createMockRoute(routeId, 'Niamey Hub', 'Destination', 50.0, '2h 30m');
  }

  // Delete mock route
  static Future<bool> deleteRoute(String routeId) async {
    Logger.info('Mock deleting route: $routeId', name: 'MockRouteService');
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  // Get mock route statistics
  static Future<Map<String, dynamic>> getRouteStats(String businessId) async {
    Logger.info('Mock getting route stats', name: 'MockRouteService');
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'total_routes': 12,
      'total_distance': 543.2,
      'total_time_saved': '15h 30m',
      'total_cost_saved': 'CFA 45,000',
      'efficiency_gain': 18.5,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // Update mock route status
  static Future<bool> updateRouteStatus(String routeId, String status) async {
    Logger.info('Mock updating route status: $routeId -> $status', name: 'MockRouteService');
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  // Generate mock waypoints
  static List<LatLng> _generateMockWaypoints(String origin, List<String> destinations) {
    // Use dynamic base location based on origin hash for variety
    final baseLat = 13.0 + (origin.hashCode % 10) * 0.1;
    final baseLng = 2.0 + (origin.hashCode % 10) * 0.1;
    final baseLocation = LatLng(baseLat, baseLng);
    
    final waypoints = <LatLng>[baseLocation];
    
    // Generate dynamic waypoints based on destinations
    for (int i = 0; i < destinations.length; i++) {
      final lat = baseLat + (i + 1) * 0.05;
      final lng = baseLng + (i + 1) * 0.05;
      waypoints.add(LatLng(lat, lng));
    }
    
    return waypoints;
  }

  // Calculate mock distance
  static double _calculateMockDistance(List<LatLng> waypoints) {
    // Dynamic distance calculation based on actual coordinates
    double totalDistance = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final lat1 = waypoints[i].latitude;
      final lng1 = waypoints[i].longitude;
      final lat2 = waypoints[i + 1].latitude;
      final lng2 = waypoints[i + 1].longitude;
      
      // Simple Haversine distance calculation
      const double earthRadius = 6371; // in km
      final double dLat = (lat2 - lat1) * (math.pi / 180);
      final double dLng = (lng2 - lng1) * (math.pi / 180);
      
      final double a = math.pow(math.sin(dLat / 2), 2) +
          math.cos(lat1 * (math.pi / 180)) *
          math.pow(math.sin(dLng / 2), 2);
      final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      
      totalDistance += earthRadius * c;
    }
    
    return totalDistance;
  }

  // Calculate mock time
  static String _calculateMockTime(List<LatLng> waypoints) {
    final distance = _calculateMockDistance(waypoints);
    // Dynamic time calculation based on distance (average 40 km/h)
    final totalMinutes = (distance / 40 * 60).round();
    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${totalMinutes}m';
    }
  }

  // Calculate mock cost
  static double _calculateMockCost(List<LatLng> waypoints) {
    final distance = _calculateMockDistance(waypoints);
    // Dynamic cost calculation based on distance (CFA 50 per km + base fee)
    return distance * 50.0 + 200.0; // Base fee + per km cost
  }

  // Create mock route
  static RouteModel _createMockRoute(String id, String origin, String destination, double distance, String time) {
    final waypoints = _generateMockWaypoints(origin, [destination]);
    
    return RouteModel(
      routeId: id,
      businessId: 'mock_business',
      originId: origin,
      destinationId: destination,
      distanceKm: distance,
      estimatedTime: time,
      cost: _calculateMockCost(waypoints),
      createdAt: DateTime.now().subtract(Duration(hours: id.hashCode % 24)),
      startLocation: waypoints.first,
      endLocation: waypoints.last,
      waypoints: waypoints,
      isOffline: false,
    );
  }
}
