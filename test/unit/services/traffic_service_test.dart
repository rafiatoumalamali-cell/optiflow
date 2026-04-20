import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../lib/services/traffic_service.dart';

void main() {
  group('TrafficService Tests', () {
    late TrafficService trafficService;

    setUp(() {
      trafficService = TrafficService(apiKey: 'test-api-key');
    });

    tearDown(() {
      trafficService.dispose();
    });

    test('should create traffic service with API key', () {
      expect(trafficService.apiKey, equals('test-api-key'));
      expect(trafficService._isTrafficEnabled, isFalse);
    });

    test('should start and stop traffic monitoring', () async {
      final testRoute = [
        const LatLng(13.5127, 2.1128),
        const LatLng(13.5234, 2.1245),
        const LatLng(13.5456, 2.1367),
      ];

      trafficService.startTrafficMonitoring(
        routePoints: testRoute,
        updateInterval: const Duration(milliseconds: 100), // Short for testing
      );

      expect(trafficService._isTrafficEnabled, isTrue);
      expect(trafficService._trafficUpdateTimer, isNotNull);

      // Wait a bit to ensure timer is active
      await Future.delayed(const Duration(milliseconds: 150));

      trafficService.stopTrafficMonitoring();

      expect(trafficService._isTrafficEnabled, isFalse);
      expect(trafficService._trafficUpdateTimer, isNull);
    });

    test('should get traffic data for route points', () async {
      final testRoute = [
        const LatLng(13.5127, 2.1128),
        const LatLng(13.5234, 2.1245),
        const LatLng(13.5456, 2.1367),
        const LatLng(13.5678, 2.1489),
      ];

      final trafficResponse = await trafficService.getTrafficData(
        routePoints: testRoute,
        detailLevel: TrafficDetailLevel.medium,
      );

      expect(trafficResponse.segments.length, equals(testRoute.length - 1));
      expect(trafficResponse.overallLevel, isA<TrafficLevel>());
      expect(trafficResponse.lastUpdated, isA<DateTime>());
    });

    test('should get traffic incidents for bounds', () async {
      final bounds = LatLngBounds(
        southwest: const LatLng(13.5000, 2.1000),
        northeast: const LatLng(13.6000, 2.2000),
      );

      final incidents = await trafficService.getTrafficIncidents(bounds: bounds);

      expect(incidents, isA<List<TrafficIncident>>());
      // May be empty or have incidents depending on random generation
    });

    test('should get travel time with traffic', () async {
      final origin = const LatLng(13.5127, 2.1128);
      final destination = const LatLng(13.5678, 2.1489);

      final travelTime = await trafficService.getTravelTimeWithTraffic(
        origin: origin,
        destination: destination,
      );

      expect(travelTime.distance, isNotNull);
      expect(travelTime.durationWithoutTraffic, isNotNull);
      expect(travelTime.durationWithTraffic, isNotNull);
      expect(travelTime.trafficDelay, isNotNull);
      expect(travelTime.trafficLevel, isA<TrafficLevel>());
    });

    test('should cache and retrieve traffic data', () async {
      final testRoute = [
        const LatLng(13.5127, 2.1128),
        const LatLng(13.5234, 2.1245),
      ];

      // Get traffic data (this will cache it)
      await trafficService.getTrafficData(routePoints: testRoute);

      // Retrieve cached data
      final cachedData = trafficService.getCachedTraffic(
        testRoute.first,
        testRoute.last,
      );

      expect(cachedData, isNotNull);
      expect(cachedData!.level, isA<TrafficLevel>());
      expect(cachedData.speed, greaterThan(0));
      expect(cachedData.density, greaterThanOrEqualTo(0));
      expect(cachedData.density, lessThanOrEqualTo(1));
    });

    test('should clear traffic cache', () {
      trafficService.clearTrafficCache();
      expect(trafficService._trafficCache, isEmpty);
    });

    test('should calculate distance between points correctly', () {
      final point1 = const LatLng(13.5127, 2.1128);
      final point2 = const LatLng(13.5234, 2.1245);

      final distance = trafficService._calculateDistance(point1, point2);

      expect(distance, greaterThan(0));
      expect(distance, lessThan(20000)); // Should be less than 20km
    });

    test('should get correct speed for traffic level', () {
      expect(trafficService._getSpeedForTrafficLevel(TrafficLevel.freeFlow), equals(50.0));
      expect(trafficService._getSpeedForTrafficLevel(TrafficLevel.light), equals(40.0));
      expect(trafficService._getSpeedForTrafficLevel(TrafficLevel.moderate), equals(30.0));
      expect(trafficService._getSpeedForTrafficLevel(TrafficLevel.heavy), equals(20.0));
      expect(trafficService._getSpeedForTrafficLevel(TrafficLevel.severe), equals(10.0));
    });

    test('should get correct density for traffic level', () {
      expect(trafficService._getDensityForTrafficLevel(TrafficLevel.freeFlow), equals(0.2));
      expect(trafficService._getDensityForTrafficLevel(TrafficLevel.light), equals(0.4));
      expect(trafficService._getDensityForTrafficLevel(TrafficLevel.moderate), equals(0.6));
      expect(trafficService._getDensityForTrafficLevel(TrafficLevel.heavy), equals(0.8));
      expect(trafficService._getDensityForTrafficLevel(TrafficLevel.severe), equals(1.0));
    });

    test('should calculate overall traffic level correctly', () {
      final segments = [
        TrafficSegment(
          start: const LatLng(13.5127, 2.1128),
          end: const LatLng(13.5234, 2.1245),
          trafficData: TrafficData(
            level: TrafficLevel.light,
            speed: 40.0,
            density: 0.4,
            travelTime: const Duration(minutes: 5),
            delay: const Duration(minutes: 1),
            lastUpdated: DateTime.now(),
          ),
        ),
        TrafficSegment(
          start: const LatLng(13.5234, 2.1245),
          end: const LatLng(13.5456, 2.1367),
          trafficData: TrafficData(
            level: TrafficLevel.moderate,
            speed: 30.0,
            density: 0.6,
            travelTime: const Duration(minutes: 8),
            delay: const Duration(minutes: 3),
            lastUpdated: DateTime.now(),
          ),
        ),
      ];

      final overallLevel = trafficService._calculateOverallTrafficLevel(segments);
      expect(overallLevel, isA<TrafficLevel>());
    });

    test('should calculate traffic level based on duration ratio', () {
      final withoutTraffic = const Duration(minutes: 10);
      final withTraffic = const Duration(minutes: 15);

      final trafficLevel = trafficService._calculateTrafficLevel(withoutTraffic, withTraffic);
      expect(trafficLevel, equals(TrafficLevel.light));
    });

    test('should generate segment key correctly', () {
      final start = const LatLng(13.5127, 2.1128);
      final end = const LatLng(13.5234, 2.1245);

      final key = trafficService._generateSegmentKey(start, end);
      expect(key, contains('13.5127'));
      expect(key, contains('2.1128'));
      expect(key, contains('13.5234'));
      expect(key, contains('2.1245'));
    });
  });

  group('TrafficData Tests', () {
    test('should create traffic data with required fields', () {
      final trafficData = TrafficData(
        level: TrafficLevel.moderate,
        speed: 30.0,
        density: 0.6,
        travelTime: const Duration(minutes: 10),
        delay: const Duration(minutes: 3),
        lastUpdated: DateTime.now(),
      );

      expect(trafficData.level, equals(TrafficLevel.moderate));
      expect(trafficData.speed, equals(30.0));
      expect(trafficData.density, equals(0.6));
      expect(trafficData.travelTime, equals(const Duration(minutes: 10)));
      expect(trafficData.delay, equals(const Duration(minutes: 3)));
    });

    test('should return correct color for traffic level', () {
      expect(TrafficData(level: TrafficLevel.freeFlow, speed: 50, density: 0.2, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).color, equals(const Color(0xFF4CAF50)));
      expect(TrafficData(level: TrafficLevel.light, speed: 40, density: 0.4, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).color, equals(const Color(0xFFFFEB3B)));
      expect(TrafficData(level: TrafficLevel.moderate, speed: 30, density: 0.6, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).color, equals(const Color(0xFFFF9800)));
      expect(TrafficData(level: TrafficLevel.heavy, speed: 20, density: 0.8, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).color, equals(const Color(0xFFFF5722)));
      expect(TrafficData(level: TrafficLevel.severe, speed: 10, density: 1.0, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).color, equals(const Color(0xFFF44336)));
    });

    test('should return correct description for traffic level', () {
      expect(TrafficData(level: TrafficLevel.freeFlow, speed: 50, density: 0.2, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).description, equals('Free Flow'));
      expect(TrafficData(level: TrafficLevel.light, speed: 40, density: 0.4, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).description, equals('Light Traffic'));
      expect(TrafficData(level: TrafficLevel.moderate, speed: 30, density: 0.6, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).description, equals('Moderate Traffic'));
      expect(TrafficData(level: TrafficLevel.heavy, speed: 20, density: 0.8, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).description, equals('Heavy Traffic'));
      expect(TrafficData(level: TrafficLevel.severe, speed: 10, density: 1.0, travelTime: Duration.zero, delay: Duration.zero, lastUpdated: DateTime.now()).description, equals('Severe Congestion'));
    });
  });

  group('TrafficIncident Tests', () {
    test('should create traffic incident with required fields', () {
      final incident = TrafficIncident(
        id: 'incident-1',
        location: const LatLng(13.5127, 2.1128),
        type: TrafficIncidentType.accident,
        severity: TrafficSeverity.high,
        description: 'Test accident',
        startTime: DateTime.now(),
        estimatedDuration: const Duration(minutes: 30),
        affectedRoutes: ['Route 1', 'Route 2'],
      );

      expect(incident.id, equals('incident-1'));
      expect(incident.type, equals(TrafficIncidentType.accident));
      expect(incident.severity, equals(TrafficSeverity.high));
      expect(incident.description, equals('Test accident'));
      expect(incident.affectedRoutes, equals(['Route 1', 'Route 2']));
    });

    test('should calculate estimated end time', () {
      final startTime = DateTime.now();
      final duration = const Duration(minutes: 30);
      
      final incident = TrafficIncident(
        id: 'incident-2',
        location: const LatLng(13.5234, 2.1245),
        type: TrafficIncidentType.construction,
        severity: TrafficSeverity.medium,
        description: 'Road construction',
        startTime: startTime,
        estimatedDuration: duration,
        affectedRoutes: ['Route 3'],
      );

      final expectedEndTime = startTime.add(duration);
      expect(incident.estimatedEndTime, equals(expectedEndTime));
    });

    test('should determine if incident is active', () {
      final activeIncident = TrafficIncident(
        id: 'incident-3',
        location: const LatLng(13.5456, 2.1367),
        type: TrafficIncidentType.weather,
        severity: TrafficSeverity.low,
        description: 'Weather delay',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        estimatedDuration: const Duration(minutes: 30),
        affectedRoutes: ['Route 4'],
      );

      final inactiveIncident = TrafficIncident(
        id: 'incident-4',
        location: const LatLng(13.5678, 2.1489),
        type: TrafficIncidentType.closure,
        severity: TrafficSeverity.critical,
        description: 'Road closure',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        estimatedDuration: const Duration(minutes: 30),
        affectedRoutes: ['Route 5'],
      );

      expect(activeIncident.isActive, isTrue);
      expect(inactiveIncident.isActive, isFalse);
    });

    test('should return correct color for severity level', () {
      expect(TrafficIncident(id: '1', location: LatLng(0, 0), type: TrafficIncidentType.accident, severity: TrafficSeverity.low, description: '', startTime: DateTime.now(), estimatedDuration: Duration.zero, affectedRoutes: []).color, equals(Colors.yellow));
      expect(TrafficIncident(id: '2', location: LatLng(0, 0), type: TrafficIncidentType.accident, severity: TrafficSeverity.medium, description: '', startTime: DateTime.now(), estimatedDuration: Duration.zero, affectedRoutes: []).color, equals(Colors.orange));
      expect(TrafficIncident(id: '3', location: LatLng(0, 0), type: TrafficIncidentType.accident, severity: TrafficSeverity.high, description: '', startTime: DateTime.now(), estimatedDuration: Duration.zero, affectedRoutes: []).color, equals(Colors.red));
      expect(TrafficIncident(id: '4', location: LatLng(0, 0), type: TrafficIncidentType.accident, severity: TrafficSeverity.critical, description: '', startTime: DateTime.now(), estimatedDuration: Duration.zero, affectedRoutes: []).color, equals(const Color(0xFF8B0000)));
    });
  });

  group('TravelTimeWithTraffic Tests', () {
    test('should calculate delay percentage correctly', () {
      final travelTime = TravelTimeWithTraffic(
        distance: Distance.fromMeters(10000),
        durationWithoutTraffic: const Duration(minutes: 10),
        durationWithTraffic: const Duration(minutes: 15),
        trafficDelay: const Duration(minutes: 5),
        trafficLevel: TrafficLevel.light,
      );

      expect(travelTime.delayPercentage, equals(50.0)); // 5 minutes is 50% of 10 minutes
    });

    test('should handle zero duration without traffic', () {
      final travelTime = TravelTimeWithTraffic(
        distance: Distance.fromMeters(5000),
        durationWithoutTraffic: Duration.zero,
        durationWithTraffic: const Duration(minutes: 5),
        trafficDelay: const Duration(minutes: 5),
        trafficLevel: TrafficLevel.heavy,
      );

      expect(travelTime.delayPercentage, equals(0.0));
    });
  });

  group('Distance Tests', () {
    test('should create distance from meters', () {
      final distance = Distance.fromMeters(1000);
      expect(distance.meters, equals(1000.0));
      expect(distance.kilometers, equals(1.0));
      expect(distance.miles, closeTo(0.621, 0.001));
    });

    test('should format kilometers correctly', () {
      final distance = Distance.fromMeters(1500);
      expect(distance.formattedKilometers, equals('1.5 km'));
    });

    test('should format miles correctly', () {
      final distance = Distance.fromMeters(1609);
      expect(distance.formattedMiles, equals('1.0 mi'));
    });

    test('should format meters for short distances', () {
      final distance = Distance.fromMeters(500);
      expect(distance.formattedMeters, equals('500 m'));
    });

    test('should format kilometers for long distances', () {
      final distance = Distance.fromMeters(2000);
      expect(distance.formattedMeters, equals('2.0 km'));
    });
  });

  group('TrafficException Tests', () {
    test('should create traffic exception with message', () {
      const exception = TrafficException('Test error message');
      expect(exception.message, equals('Test error message'));
      expect(exception.toString(), equals('TrafficException: Test error message'));
    });
  });
}
