import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../lib/services/marker_clustering_service.dart';

void main() {
  group('MarkerClusteringService Tests', () {
    late MarkerClusterService clusteringService;
    late List<DeliveryPoint> testDeliveryPoints;

    setUp(() {
      clusteringService = MarkerClusterService(
        clusterSize: 4,
        zoomThreshold: 12.0,
      );

      // Create test delivery points
      testDeliveryPoints = [
        DeliveryPoint(
          id: '1',
          name: 'Test Point 1',
          address: 'Test Address 1',
          location: const LatLng(13.5127, 2.1128),
          type: DeliveryPointType.delivery,
          status: DeliveryStatus.pending,
        ),
        DeliveryPoint(
          id: '2',
          name: 'Test Point 2',
          address: 'Test Address 2',
          location: const LatLng(13.5130, 2.1130), // Very close to point 1
          type: DeliveryPointType.pickup,
          status: DeliveryStatus.completed,
        ),
        DeliveryPoint(
          id: '3',
          name: 'Test Point 3',
          address: 'Test Address 3',
          location: const LatLng(13.5200, 2.1200), // Further away
          type: DeliveryPointType.warehouse,
          status: DeliveryStatus.inProgress,
        ),
        DeliveryPoint(
          id: '4',
          name: 'Test Point 4',
          address: 'Test Address 4',
          location: const LatLng(13.5300, 2.1300), // Even further
          type: DeliveryPointType.distribution,
          status: DeliveryStatus.failed,
        ),
      ];
    });

    test('should create clustering service with default parameters', () {
      final service = MarkerClusterService();
      expect(service.clusterSize, equals(4));
      expect(service.zoomThreshold, equals(12.0));
    });

    test('should create clustering service with custom parameters', () {
      final service = MarkerClusterService(
        clusterSize: 6,
        zoomThreshold: 10.0,
      );
      expect(service.clusterSize, equals(6));
      expect(service.zoomThreshold, equals(10.0));
    });

    test('should return individual markers when zoom level is high', () {
      final markers = clusteringService.clusterMarkers(testDeliveryPoints, 15.0);
      expect(markers.length, equals(testDeliveryPoints.length));
    });

    test('should return individual markers when points are few', () {
      final fewPoints = testDeliveryPoints.take(2).toList();
      final markers = clusteringService.clusterMarkers(fewPoints, 10.0);
      expect(markers.length, equals(fewPoints.length));
    });

    test('should cluster markers when zoom level is low and points are many', () {
      final markers = clusteringService.clusterMarkers(testDeliveryPoints, 10.0);
      expect(markers.length, lessThan(testDeliveryPoints.length));
    });

    test('should return empty list for empty delivery points', () {
      final markers = clusteringService.clusterMarkers([], 12.0);
      expect(markers, isEmpty);
    });

    test('should calculate distance between two points correctly', () {
      final point1 = const LatLng(13.5127, 2.1128);
      final point2 = const LatLng(13.5130, 2.1130);
      
      // Distance should be small (within a few hundred meters)
      final distance = clusteringService._calculateDistance(point1, point2);
      expect(distance, lessThan(500)); // Less than 500 meters
    });

    test('should calculate cluster radius based on zoom level', () {
      final radiusAtZoom10 = clusteringService._getClusterRadius(10.0);
      final radiusAtZoom15 = clusteringService._getClusterRadius(15.0);
      
      expect(radiusAtZoom10, greaterThan(radiusAtZoom15));
    });

    test('should get correct marker icon for delivery point type', () {
      final deliveryIcon = clusteringService._getMarkerIcon(
        DeliveryPointType.delivery, 
        DeliveryStatus.pending
      );
      expect(deliveryIcon, isNotNull);
    });

    test('should get correct marker icon for pickup point type', () {
      final pickupIcon = clusteringService._getMarkerIcon(
        DeliveryPointType.pickup, 
        DeliveryStatus.completed
      );
      expect(pickupIcon, isNotNull);
    });

    test('should get correct marker icon for warehouse point type', () {
      final warehouseIcon = clusteringService._getMarkerIcon(
        DeliveryPointType.warehouse, 
        DeliveryStatus.inProgress
      );
      expect(warehouseIcon, isNotNull);
    });

    test('should get correct cluster icon based on point count', () {
      final smallClusterIcon = clusteringService._getClusterIcon(3);
      final mediumClusterIcon = clusteringService._getClusterIcon(8);
      final largeClusterIcon = clusteringService._getClusterIcon(15);
      
      expect(smallClusterIcon, isNotNull);
      expect(mediumClusterIcon, isNotNull);
      expect(largeClusterIcon, isNotNull);
    });

    test('should calculate cluster bounds correctly', () {
      final bounds = clusteringService.getClusterBounds(testDeliveryPoints);
      
      expect(bounds.southwest.latitude, lessThan(bounds.northeast.latitude));
      expect(bounds.southwest.longitude, lessThan(bounds.northeast.longitude));
    });

    test('should handle empty list for cluster bounds', () {
      final bounds = clusteringService.getClusterBounds([]);
      
      expect(bounds.southwest.latitude, equals(0.0));
      expect(bounds.southwest.longitude, equals(0.0));
      expect(bounds.northeast.latitude, equals(0.0));
      expect(bounds.northeast.longitude, equals(0.0));
    });
  });

  group('DeliveryPoint Tests', () {
    test('should create delivery point with required fields', () {
      final deliveryPoint = DeliveryPoint(
        id: 'test-1',
        name: 'Test Delivery',
        address: '123 Test Street',
        location: const LatLng(13.5127, 2.1128),
        type: DeliveryPointType.delivery,
        status: DeliveryStatus.pending,
      );

      expect(deliveryPoint.id, equals('test-1'));
      expect(deliveryPoint.name, equals('Test Delivery'));
      expect(deliveryPoint.address, equals('123 Test Street'));
      expect(deliveryPoint.type, equals(DeliveryPointType.delivery));
      expect(deliveryPoint.status, equals(DeliveryStatus.pending));
    });

    test('should create delivery point with optional fields', () {
      final scheduledTime = DateTime.now();
      final deliveryPoint = DeliveryPoint(
        id: 'test-2',
        name: 'Test Delivery 2',
        address: '456 Test Avenue',
        location: const LatLng(13.5130, 2.1130),
        type: DeliveryPointType.pickup,
        status: DeliveryStatus.completed,
        scheduledTime: scheduledTime,
        metadata: {'priority': 'high', 'weight': 10.5},
      );

      expect(deliveryPoint.scheduledTime, equals(scheduledTime));
      expect(deliveryPoint.metadata, containsPair('priority', 'high'));
      expect(deliveryPoint.metadata, containsPair('weight', 10.5));
    });

    test('should convert delivery point to JSON', () {
      final deliveryPoint = DeliveryPoint(
        id: 'test-3',
        name: 'Test Delivery 3',
        address: '789 Test Road',
        location: const LatLng(13.5140, 2.1140),
        type: DeliveryPointType.warehouse,
        status: DeliveryStatus.inProgress,
      );

      final json = deliveryPoint.toJson();
      
      expect(json['id'], equals('test-3'));
      expect(json['name'], equals('Test Delivery 3'));
      expect(json['latitude'], equals(13.5140));
      expect(json['longitude'], equals(2.1140));
      expect(json['type'], equals('warehouse'));
      expect(json['status'], equals('inProgress'));
    });

    test('should create delivery point from JSON', () {
      final json = {
        'id': 'test-4',
        'name': 'Test Delivery 4',
        'address': '321 Test Lane',
        'latitude': 13.5150,
        'longitude': 2.1150,
        'type': 'distribution',
        'status': 'failed',
        'scheduledTime': DateTime.now().millisecondsSinceEpoch,
        'metadata': {'priority': 'low'},
      };

      final deliveryPoint = DeliveryPoint.fromJson(json);
      
      expect(deliveryPoint.id, equals('test-4'));
      expect(deliveryPoint.name, equals('Test Delivery 4'));
      expect(deliveryPoint.location.latitude, equals(13.5150));
      expect(deliveryPoint.location.longitude, equals(2.1150));
      expect(deliveryPoint.type, equals(DeliveryPointType.distribution));
      expect(deliveryPoint.status, equals(DeliveryStatus.failed));
      expect(deliveryPoint.metadata, containsPair('priority', 'low'));
    });
  });

  group('MarkerCluster Tests', () {
    test('should create marker cluster with center and points', () {
      final center = const LatLng(13.5127, 2.1128);
      final points = [
        DeliveryPoint(
          id: '1',
          name: 'Point 1',
          address: 'Address 1',
          location: const LatLng(13.5127, 2.1128),
          type: DeliveryPointType.delivery,
          status: DeliveryStatus.pending,
        ),
        DeliveryPoint(
          id: '2',
          name: 'Point 2',
          address: 'Address 2',
          location: const LatLng(13.5130, 2.1130),
          type: DeliveryPointType.pickup,
          status: DeliveryStatus.completed,
        ),
      ];

      final cluster = MarkerCluster(
        center: center,
        points: points,
      );

      expect(cluster.center, equals(center));
      expect(cluster.points.length, equals(2));
      expect(cluster.pointCount, equals(2));
    });

    test('should calculate average position correctly', () {
      final points = [
        DeliveryPoint(
          id: '1',
          name: 'Point 1',
          address: 'Address 1',
          location: const LatLng(13.5120, 2.1120),
          type: DeliveryPointType.delivery,
          status: DeliveryStatus.pending,
        ),
        DeliveryPoint(
          id: '2',
          name: 'Point 2',
          address: 'Address 2',
          location: const LatLng(13.5140, 2.1140),
          type: DeliveryPointType.pickup,
          status: DeliveryStatus.completed,
        ),
      ];

      final cluster = MarkerCluster(
        center: const LatLng(13.5130, 2.1130),
        points: points,
      );

      final averagePosition = cluster.averagePosition;
      expect(averagePosition.latitude, equals(13.5130));
      expect(averagePosition.longitude, equals(2.1130));
    });

    test('should handle empty points list for average position', () {
      final cluster = MarkerCluster(
        center: const LatLng(13.5127, 2.1128),
        points: [],
      );

      final averagePosition = cluster.averagePosition;
      expect(averagePosition, equals(const LatLng(13.5127, 2.1128)));
    });
  });

  group('ClusterMarkerWidget Tests', () {
    testWidgets('should display correct point count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClusterMarkerWidget(
              pointCount: 5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should handle tap callback', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClusterMarkerWidget(
              pointCount: 3,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ClusterMarkerWidget));
      expect(wasTapped, isTrue);
    });

    testWidgets('should adjust size based on point count', (WidgetTester tester) async {
      // Test small cluster
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClusterMarkerWidget(
              pointCount: 3,
              onTap: () {},
            ),
          ),
        ),
      );

      final smallCluster = tester.widget<Container>(find.byType(Container).first);

      // Test large cluster
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClusterMarkerWidget(
              pointCount: 25,
              onTap: () {},
            ),
          ),
        ),
      );

      final largeCluster = tester.widget<Container>(find.byType(Container).first);
      
      // The large cluster should be bigger (this is a basic test)
      expect(largeCluster.constraints?.maxHeight, greaterThanOrEqualTo(smallCluster.constraints?.maxHeight ?? 0));
    });
  });
}
