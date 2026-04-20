import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/logger.dart';
import '../utils/environment.dart';

class TrafficService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  static const Duration _timeout = Duration(seconds: 30);
  
  // Traffic layer states
  bool _isTrafficEnabled = false;
  Timer? _trafficUpdateTimer;
  Map<String, TrafficData> _trafficCache = {};
  
  TrafficService();
  
  /// Get real-time traffic data for a route
  Future<TrafficResponse> getTrafficData({
    required List<LatLng> routePoints,
    TrafficDetailLevel detailLevel = TrafficDetailLevel.medium,
  }) async {
    try {
      Logger.info('Requesting traffic data for ${routePoints.length} points', name: 'TrafficService');
      
      // For now, we'll simulate traffic data since Google Maps Traffic API requires special setup
      // In production, this would use the actual Google Maps Traffic API
      final trafficResponse = await _simulateTrafficData(routePoints, detailLevel);
      
      // Cache the traffic data
      for (final segment in trafficResponse.segments) {
        final key = _generateSegmentKey(segment.start, segment.end);
        _trafficCache[key] = segment.trafficData;
      }
      
      return trafficResponse;
      
    } catch (e, stack) {
      Logger.error('Error getting traffic data', name: 'TrafficService', error: e, stackTrace: stack);
      throw TrafficException('Failed to get traffic data: $e');
    }
  }
  
  /// Get traffic incidents for a region
  Future<List<TrafficIncident>> getTrafficIncidents({
    required LatLngBounds bounds,
    TrafficIncidentType? incidentType,
  }) async {
    try {
      // Simulate traffic incidents
      final incidents = <TrafficIncident>[];
      final random = math.Random();
      
      // Generate random incidents in the bounds
      final incidentCount = random.nextInt(5);
      
      for (int i = 0; i < incidentCount; i++) {
        final lat = bounds.southwest.latitude + 
            random.nextDouble() * (bounds.northeast.latitude - bounds.southwest.latitude);
        final lng = bounds.southwest.longitude + 
            random.nextDouble() * (bounds.northeast.longitude - bounds.southwest.longitude);
        
        final incident = TrafficIncident(
          id: 'incident_${DateTime.now().millisecondsSinceEpoch}_$i',
          location: LatLng(lat, lng),
          type: TrafficIncidentType.values[random.nextInt(TrafficIncidentType.values.length)],
          severity: TrafficSeverity.values[random.nextInt(TrafficSeverity.values.length)],
          description: _generateIncidentDescription(),
          startTime: DateTime.now().subtract(Duration(minutes: random.nextInt(120))),
          estimatedDuration: Duration(minutes: random.nextInt(60) + 15),
          affectedRoutes: ['Route ${i + 1}', 'Route ${i + 2}'],
        );
        
        incidents.add(incident);
      }
      
      return incidents;
      
    } catch (e, start) {
      Logger.error('Error getting traffic incidents', name: 'TrafficService', error: e, stackTrace: start);
      throw TrafficException('Failed to get traffic incidents: $e');
    }
  }
  
  /// Get travel time with traffic consideration
  Future<TravelTimeWithTraffic> getTravelTimeWithTraffic({
    required LatLng origin,
    required LatLng destination,
    TravelMode mode = TravelMode.driving,
  }) async {
    try {
      // Use Distance Matrix API with traffic consideration
      final url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=${origin.latitude},${origin.longitude}'
          '&destinations=${destination.latitude},${destination.longitude}'
          '&mode=${mode.name}'
          '&departure_time=now' // This enables traffic consideration
          '&traffic_model=best_guess'
          '&key=${Environment.googleMapsApiKey}';
      
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final element = data['rows'][0]['elements'][0];
        
        if (element['status'] == 'OK') {
          final duration = Duration(seconds: element['duration']['value'] as int);
          final durationInTraffic = Duration(seconds: element['duration_in_traffic']['value'] as int);
          final distance = element['distance']['value'] as int;
          
          return TravelTimeWithTraffic(
            distance: Distance.fromMeters(distance),
            durationWithoutTraffic: duration,
            durationWithTraffic: durationInTraffic,
            trafficDelay: durationInTraffic - duration,
            trafficLevel: _calculateTrafficLevel(duration, durationInTraffic),
          );
        }
      }
      
      throw TrafficException('Failed to get travel time with traffic');
      
    } catch (e, stack) {
      Logger.error('Error getting travel time with traffic', name: 'TrafficService', error: e, stackTrace: stack);
      throw TrafficException('Failed to get travel time with traffic: $e');
    }
  }
  
  /// Start real-time traffic monitoring
  void startTrafficMonitoring({
    required List<LatLng> routePoints,
    Duration updateInterval = const Duration(minutes: 5),
  }) {
    _isTrafficEnabled = true;
    
    _trafficUpdateTimer = Timer.periodic(updateInterval, (timer) async {
      try {
        final trafficData = await getTrafficData(routePoints: routePoints);
        Logger.info('Traffic data updated: ${trafficData.segments.length} segments', name: 'TrafficService');
      } catch (e) {
        Logger.error('Error updating traffic data', name: 'TrafficService', error: e);
      }
    });
    
    Logger.info('Started traffic monitoring with ${updateInterval.inMinutes} minute intervals', name: 'TrafficService');
  }
  
  /// Stop traffic monitoring
  void stopTrafficMonitoring() {
    _trafficUpdateTimer?.cancel();
    _trafficUpdateTimer = null;
    _isTrafficEnabled = false;
    
    Logger.info('Stopped traffic monitoring', name: 'TrafficService');
  }
  
  /// Get cached traffic data for a segment
  TrafficData? getCachedTraffic(LatLng start, LatLng end) {
    final key = _generateSegmentKey(start, end);
    return _trafficCache[key];
  }
  
  /// Clear traffic cache
  void clearTrafficCache() {
    _trafficCache.clear();
    Logger.info('Traffic cache cleared', name: 'TrafficService');
  }
  
  /// Generate segment key for caching
  String _generateSegmentKey(LatLng start, LatLng end) {
    return '${start.latitude}_${start.longitude}_${end.latitude}_${end.longitude}';
  }
  
  /// Simulate traffic data (replace with real API in production)
  Future<TrafficResponse> _simulateTrafficData(
    List<LatLng> routePoints, 
    TrafficDetailLevel detailLevel
  ) async {
    final segments = <TrafficSegment>[];
    final random = math.Random();
    
    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];
      
      // Generate realistic traffic data
      final trafficLevel = TrafficLevel.values[random.nextInt(TrafficLevel.values.length)];
      final speed = _getSpeedForTrafficLevel(trafficLevel);
      final density = _getDensityForTrafficLevel(trafficLevel);
      
      final segment = TrafficSegment(
        start: start,
        end: end,
        trafficData: TrafficData(
          level: trafficLevel,
          speed: speed,
          density: density,
          travelTime: Duration(
            seconds: (_calculateDistance(start, end) / speed * 3.6).round(),
          ),
          delay: Duration(
            seconds: random.nextInt(300), // 0-5 minutes delay
          ),
          lastUpdated: DateTime.now(),
        ),
      );
      
      segments.add(segment);
    }
    
    return TrafficResponse(
      segments: segments,
      overallLevel: _calculateOverallTrafficLevel(segments),
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Calculate distance between two points
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
  
  /// Get speed for traffic level
  double _getSpeedForTrafficLevel(TrafficLevel level) {
    switch (level) {
      case TrafficLevel.freeFlow:
        return 50.0; // 50 km/h
      case TrafficLevel.light:
        return 40.0; // 40 km/h
      case TrafficLevel.moderate:
        return 30.0; // 30 km/h
      case TrafficLevel.heavy:
        return 20.0; // 20 km/h
      case TrafficLevel.severe:
        return 10.0; // 10 km/h
    }
  }
  
  /// Get density for traffic level
  double _getDensityForTrafficLevel(TrafficLevel level) {
    switch (level) {
      case TrafficLevel.freeFlow:
        return 0.2; // 20% density
      case TrafficLevel.light:
        return 0.4; // 40% density
      case TrafficLevel.moderate:
        return 0.6; // 60% density
      case TrafficLevel.heavy:
        return 0.8; // 80% density
      case TrafficLevel.severe:
        return 1.0; // 100% density
    }
  }
  
  /// Calculate overall traffic level
  TrafficLevel _calculateOverallTrafficLevel(List<TrafficSegment> segments) {
    if (segments.isEmpty) return TrafficLevel.freeFlow;
    
    double totalWeight = 0;
    double weightedSum = 0;
    
    for (final segment in segments) {
      final weight = _calculateDistance(segment.start, segment.end);
      totalWeight += weight;
      weightedSum += weight * segment.trafficData.level.index;
    }
    
    final averageIndex = weightedSum / totalWeight;
    return TrafficLevel.values[averageIndex.round().clamp(0, TrafficLevel.values.length - 1)];
  }
  
  /// Calculate traffic level based on duration difference
  TrafficLevel _calculateTrafficLevel(Duration withoutTraffic, Duration withTraffic) {
    final ratio = withTraffic.inSeconds / withoutTraffic.inSeconds;
    
    if (ratio <= 1.2) return TrafficLevel.freeFlow;
    if (ratio <= 1.5) return TrafficLevel.light;
    if (ratio <= 2.0) return TrafficLevel.moderate;
    if (ratio <= 3.0) return TrafficLevel.heavy;
    return TrafficLevel.severe;
  }
  
  /// Generate incident description
  String _generateIncidentDescription() {
    final descriptions = [
      'Accident on highway',
      'Road construction ahead',
      'Heavy traffic due to event',
      'Vehicle breakdown',
      'Weather-related delays',
      'Road closure',
      'Signal malfunction',
    ];
    
    return descriptions[math.Random().nextInt(descriptions.length)];
  }
  
  /// Dispose resources
  void dispose() {
    stopTrafficMonitoring();
    clearTrafficCache();
  }
}

/// Traffic response model
class TrafficResponse {
  final List<TrafficSegment> segments;
  final TrafficLevel overallLevel;
  final DateTime lastUpdated;
  
  TrafficResponse({
    required this.segments,
    required this.overallLevel,
    required this.lastUpdated,
  });
}

/// Traffic segment model
class TrafficSegment {
  final LatLng start;
  final LatLng end;
  final TrafficData trafficData;
  
  TrafficSegment({
    required this.start,
    required this.end,
    required this.trafficData,
  });
}

/// Traffic data model
class TrafficData {
  final TrafficLevel level;
  final double speed; // km/h
  final double density; // 0.0 to 1.0
  final Duration travelTime;
  final Duration delay;
  final DateTime lastUpdated;
  
  TrafficData({
    required this.level,
    required this.speed,
    required this.density,
    required this.travelTime,
    required this.delay,
    required this.lastUpdated,
  });
  
  Color get color {
    switch (level) {
      case TrafficLevel.freeFlow:
        return const Color(0xFF4CAF50); // Green
      case TrafficLevel.light:
        return const Color(0xFFFFEB3B); // Yellow
      case TrafficLevel.moderate:
        return const Color(0xFFFF9800); // Orange
      case TrafficLevel.heavy:
        return const Color(0xFFFF5722); // Red-Orange
      case TrafficLevel.severe:
        return const Color(0xFFF44336); // Red
    }
  }
  
  String get description {
    switch (level) {
      case TrafficLevel.freeFlow:
        return 'Free Flow';
      case TrafficLevel.light:
        return 'Light Traffic';
      case TrafficLevel.moderate:
        return 'Moderate Traffic';
      case TrafficLevel.heavy:
        return 'Heavy Traffic';
      case TrafficLevel.severe:
        return 'Severe Congestion';
    }
  }
}

/// Traffic incident model
class TrafficIncident {
  final String id;
  final LatLng location;
  final TrafficIncidentType type;
  final TrafficSeverity severity;
  final String description;
  final DateTime startTime;
  final Duration estimatedDuration;
  final List<String> affectedRoutes;
  
  TrafficIncident({
    required this.id,
    required this.location,
    required this.type,
    required this.severity,
    required this.description,
    required this.startTime,
    required this.estimatedDuration,
    required this.affectedRoutes,
  });
  
  DateTime? get estimatedEndTime => startTime.add(estimatedDuration);
  bool get isActive => DateTime.now().isBefore(estimatedEndTime ?? DateTime.now());
  
  Color get color {
    switch (severity) {
      case TrafficSeverity.low:
        return const Color(0xFFFFEB3B);
      case TrafficSeverity.medium:
        return const Color(0xFFFF9800);
      case TrafficSeverity.high:
        return const Color(0xFFF44336);
      case TrafficSeverity.critical:
        return const Color(0xFF8B0000); // Dark Red
    }
  }
}

/// Travel time with traffic model
class TravelTimeWithTraffic {
  final Distance distance;
  final Duration durationWithoutTraffic;
  final Duration durationWithTraffic;
  final Duration trafficDelay;
  final TrafficLevel trafficLevel;
  
  TravelTimeWithTraffic({
    required this.distance,
    required this.durationWithoutTraffic,
    required this.durationWithTraffic,
    required this.trafficDelay,
    required this.trafficLevel,
  });
  
  double get delayPercentage {
    if (durationWithoutTraffic.inSeconds == 0) return 0.0;
    return (trafficDelay.inSeconds / durationWithoutTraffic.inSeconds) * 100;
  }
}

/// Traffic levels
enum TrafficLevel {
  freeFlow,
  light,
  moderate,
  heavy,
  severe,
}

/// Traffic incident types
enum TrafficIncidentType {
  accident,
  construction,
  congestion,
  weather,
  closure,
  event,
  breakdown,
}

/// Traffic severity levels
enum TrafficSeverity {
  low,
  medium,
  high,
  critical,
}

/// Traffic detail levels
enum TrafficDetailLevel {
  low,
  medium,
  high,
}

/// Travel modes
enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

/// Distance model
class Distance {
  final double meters;
  final double kilometers;
  final double miles;
  
  Distance({
    required this.meters,
  }) : kilometers = meters / 1000,
       miles = meters / 1609.344;
  
  factory Distance.fromMeters(int meters) {
    return Distance(meters: meters.toDouble());
  }
  
  String get formattedKilometers {
    return '${kilometers.toStringAsFixed(1)} km';
  }
  
  String get formattedMiles {
    return '${miles.toStringAsFixed(1)} mi';
  }
}

/// Traffic exception
class TrafficException implements Exception {
  final String message;
  
  TrafficException(this.message);
  
  @override
  String toString() => 'TrafficException: $message';
}
