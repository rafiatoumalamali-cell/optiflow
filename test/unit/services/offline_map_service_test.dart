import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../lib/services/offline_map_service.dart';
import '../../../lib/services/offline_route_service.dart';

void main() {
  group('OfflineMapService Tests', () {
    late OfflineMapService offlineMapService;

    setUp(() async {
      // Initialize services for testing
      await OfflineRouteService.init();
      offlineMapService = OfflineMapService();
    });

    tearDown(() {
      offlineMapService.dispose();
    });

    test('should initialize offline map service', () async {
      await offlineMapService.initialize();
      expect(offlineMapService.isInitialized, isTrue);
    });

    test('should cache route data', () async {
      final route = RouteModel(
        routeId: 'test-route-1',
        businessId: 'test-business',
        originId: 'origin-1',
        destinationId: 'destination-1',
        distanceKm: 10.5,
        estimatedTime: '25 min',
        cost: 150.0,
        createdAt: DateTime.now(),
        startLocation: const LatLng(13.5127, 2.1128),
        endLocation: const LatLng(13.5234, 2.1245),
        waypoints: [
          const LatLng(13.5127, 2.1128),
          const LatLng(13.5180, 2.1180),
          const LatLng(13.5234, 2.1245),
        ],
        isOffline: false,
      );

      await offlineMapService.cacheRoute(route);
      
      // Verify route was cached
      final cachedRoutes = await offlineMapService.getCachedRoutes();
      expect(cachedRoutes.any((r) => r.routeId == 'test-route-1'), isTrue);
    });

    test('should retrieve cached routes', () async {
      final route = RouteModel(
        routeId: 'test-route-2',
        businessId: 'test-business',
        originId: 'origin-2',
        destinationId: 'destination-2',
        distanceKm: 15.0,
        estimatedTime: '35 min',
        cost: 200.0,
        createdAt: DateTime.now(),
        startLocation: const LatLng(13.5456, 2.1367),
        endLocation: const LatLng(13.5678, 2.1489),
        waypoints: [
          const LatLng(13.5456, 2.1367),
          const LatLng(13.5567, 2.1428),
          const LatLng(13.5678, 2.1489),
        ],
        isOffline: false,
      );

      await offlineMapService.cacheRoute(route);
      
      final cachedRoutes = await offlineMapService.getCachedRoutes();
      expect(cachedRoutes.length, greaterThan(0));
      expect(cachedRoutes.any((r) => r.routeId == 'test-route-2'), isTrue);
    });

    test('should calculate route progress', () async {
      final routeId = 'test-route-progress';
      final currentLocation = const LatLng(13.5180, 2.1180);
      
      // Create and cache a test route
      final route = RouteModel(
        routeId: routeId,
        businessId: 'test-business',
        originId: 'origin-3',
        destinationId: 'destination-3',
        distanceKm: 20.0,
        estimatedTime: '45 min',
        cost: 250.0,
        createdAt: DateTime.now(),
        startLocation: const LatLng(13.5127, 2.1128),
        endLocation: const LatLng(13.5678, 2.1489),
        waypoints: [
          const LatLng(13.5127, 2.1128),
          const LatLng(13.5180, 2.1180), // Current location
          const LatLng(13.5345, 2.1312),
          const LatLng(13.5678, 2.1489),
        ],
        isOffline: false,
      );

      await offlineMapService.cacheRoute(route);
      
      final progress = offlineMapService.calculateRouteProgress(routeId, currentLocation);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });

    test('should get next waypoint', () async {
      final routeId = 'test-route-next-waypoint';
      final currentLocation = const LatLng(13.5180, 2.1180);
      
      final route = RouteModel(
        routeId: routeId,
        businessId: 'test-business',
        originId: 'origin-4',
        destinationId: 'destination-4',
        distanceKm: 25.0,
        estimatedTime: '55 min',
        cost: 300.0,
        createdAt: DateTime.now(),
        startLocation: const LatLng(13.5127, 2.1128),
        endLocation: const LatLng(13.5890, 2.1610),
        waypoints: [
          const LatLng(13.5127, 2.1128),
          const LatLng(13.5180, 2.1180), // Current location
          const LatLng(13.5345, 2.1312),
          const LatLng(13.5567, 2.1428),
          const LatLng(13.5890, 2.1610),
        ],
        isOffline: false,
      );

      await offlineMapService.cacheRoute(route);
      
      final nextWaypoint = offlineMapService.getNextWaypoint(routeId, currentLocation);
      expect(nextWaypoint, isNotNull);
      expect(nextWaypoint!.latLng, equals(const LatLng(13.5345, 2.1312)));
    });

    test('should cache map tiles', () async {
      final tileKey = 'tile_13_2_10';
      final tileData = [1, 2, 3, 4]; // Mock tile data
      
      await offlineMapService.cacheMapTile(tileKey, tileData);
      
      final cachedTile = await offlineMapService.getCachedMapTile(tileKey);
      expect(cachedTile, isNotNull);
      expect(cachedTile, equals(tileData));
    });

    test('should clear cache', () async {
      // Cache some data
      final route = RouteModel(
        routeId: 'test-route-clear',
        businessId: 'test-business',
        originId: 'origin-clear',
        destinationId: 'destination-clear',
        distanceKm: 5.0,
        estimatedTime: '15 min',
        cost: 100.0,
        createdAt: DateTime.now(),
        startLocation: const LatLng(13.5127, 2.1128),
        endLocation: const LatLng(13.5234, 2.1245),
        waypoints: [
          const LatLng(13.5127, 2.1128),
          const LatLng(13.5234, 2.1245),
        ],
        isOffline: false,
      );

      await offlineMapService.cacheRoute(route);
      await offlineMapService.cacheMapTile('tile_clear', [1, 2, 3]);
      
      // Verify data exists
      final routesBefore = await offlineMapService.getCachedRoutes();
      expect(routesBefore.length, greaterThan(0));
      
      // Clear cache
      await offlineMapService.clearCache();
      
      // Verify cache is empty
      final routesAfter = await offlineMapService.getCachedRoutes();
      expect(routesAfter, isEmpty);
    });

    test('should handle connectivity changes', () async {
      // Test connectivity monitoring
      expect(offlineMapService.isOnline, isA<bool>());
      
      // Simulate connectivity change
      offlineMapService.updateConnectivityStatus(false);
      expect(offlineMapService.isOnline, isFalse);
      
      offlineMapService.updateConnectivityStatus(true);
      expect(offlineMapService.isOnline, isTrue);
    });

    test('should create offline waypoints', () {
      final waypoints = [
        const LatLng(13.5127, 2.1128),
        const LatLng(13.5234, 2.1245),
        const LatLng(13.5456, 2.1367),
      ];

      final offlineWaypoints = offlineMapService.createOfflineWaypoints(waypoints);
      
      expect(offlineWaypoints.length, equals(waypoints.length));
      expect(offlineWaypoints.first.latLng, equals(waypoints.first));
      expect(offlineWaypoints.last.latLng, equals(waypoints.last));
    });

    test('should calculate distance between waypoints', () {
      final point1 = const LatLng(13.5127, 2.1128);
      final point2 = const LatLng(13.5234, 2.1245);
      
      final distance = offlineMapService.calculateDistance(point1, point2);
      
      expect(distance, greaterThan(0));
      expect(distance, lessThan(20000)); // Should be less than 20km
    });

    test('should sync offline data', () async {
      // Create test offline data
      final route = RouteModel(
        routeId: 'test-route-sync',
        businessId: 'test-business',
        originId: 'origin-sync',
        destinationId: 'destination-sync',
        distanceKm: 30.0,
        estimatedTime: '1h 15min',
        cost: 400.0,
        createdAt: DateTime.now(),
        startLocation: const LatLng(13.5127, 2.1128),
        endLocation: const LatLng(13.6234, 2.1856),
        waypoints: [
          const LatLng(13.5127, 2.1128),
          const LatLng(13.5678, 2.1489),
          const LatLng(13.6234, 2.1856),
        ],
        isOffline: true, // Mark as offline
      );

      await offlineMapService.cacheRoute(route);
      
      // Sync data
      await offlineMapService.syncOfflineData();
      
      // Verify sync completed (in real implementation, this would sync with backend)
      final cachedRoutes = await offlineMapService.getCachedRoutes();
      expect(cachedRoutes.any((r) => r.routeId == 'test-route-sync'), isTrue);
    });
  });

  group('OfflineWaypoint Tests', () {
    test('should create offline waypoint with required fields', () {
      final waypoint = OfflineWaypoint(
        id: 'waypoint-1',
        name: 'Test Waypoint',
        address: '123 Test Street',
        latLng: const LatLng(13.5127, 2.1128),
        estimatedArrival: DateTime.now().add(const Duration(minutes: 30)),
        estimatedDeparture: DateTime.now().add(const Duration(minutes: 35)),
        status: WaypointStatus.pending,
      );

      expect(waypoint.id, equals('waypoint-1'));
      expect(waypoint.name, equals('Test Waypoint'));
      expect(waypoint.address, equals('123 Test Street'));
      expect(waypoint.latLng, equals(const LatLng(13.5127, 2.1128)));
      expect(waypoint.status, equals(WaypointStatus.pending));
    });

    test('should create offline waypoint with optional fields', () {
      final now = DateTime.now();
      final waypoint = OfflineWaypoint(
        id: 'waypoint-2',
        name: 'Test Waypoint 2',
        address: '456 Test Avenue',
        latLng: const LatLng(13.5234, 2.1245),
        estimatedArrival: now.add(const Duration(minutes: 45)),
        estimatedDeparture: now.add(const Duration(minutes: 50)),
        status: WaypointStatus.completed,
        actualArrival: now.add(const Duration(minutes: 44)),
        actualDeparture: now.add(const Duration(minutes: 48)),
        notes: 'Delivery completed successfully',
        metadata: {'priority': 'high', 'weight': 15.5},
      );

      expect(waypoint.actualArrival, isNotNull);
      expect(waypoint.actualDeparture, isNotNull);
      expect(waypoint.notes, equals('Delivery completed successfully'));
      expect(waypoint.metadata, containsPair('priority', 'high'));
      expect(waypoint.metadata, containsPair('weight', 15.5));
    });

    test('should calculate delay correctly', () {
      final now = DateTime.now();
      final waypoint = OfflineWaypoint(
        id: 'waypoint-3',
        name: 'Test Waypoint 3',
        address: '789 Test Road',
        latLng: const LatLng(13.5456, 2.1367),
        estimatedArrival: now.add(const Duration(minutes: 30)),
        estimatedDeparture: now.add(const Duration(minutes: 35)),
        status: WaypointStatus.completed,
        actualArrival: now.add(const Duration(minutes: 32)), // 2 minutes late
        actualDeparture: now.add(const Duration(minutes: 37)),
      );

      expect(waypoint.arrivalDelay, equals(const Duration(minutes: 2)));
      expect(waypoint.departureDelay, equals(const Duration(minutes: 2)));
    });

    test('should handle null actual times', () {
      final waypoint = OfflineWaypoint(
        id: 'waypoint-4',
        name: 'Test Waypoint 4',
        address: '321 Test Lane',
        latLng: const LatLng(13.5678, 2.1489),
        estimatedArrival: DateTime.now().add(const Duration(minutes: 20)),
        estimatedDeparture: DateTime.now().add(const Duration(minutes: 25)),
        status: WaypointStatus.pending,
        actualArrival: null,
        actualDeparture: null,
      );

      expect(waypoint.arrivalDelay, isNull);
      expect(waypoint.departureDelay, isNull);
    });
  });

  group('WaypointStatus Tests', () {
    test('should have correct status values', () {
      expect(WaypointStatus.values, contains(WaypointStatus.pending));
      expect(WaypointStatus.values, contains(WaypointStatus.inProgress));
      expect(WaypointStatus.values, contains(WaypointStatus.completed));
      expect(WaypointStatus.values, contains(WaypointStatus.skipped));
      expect(WaypointStatus.values, contains(WaypointStatus.failed));
    });
  });
}
