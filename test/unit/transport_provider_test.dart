import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:optiflow/providers/transport_provider.dart';
import 'package:optiflow/models/location_model.dart';

import '../mocks/mock_firestore_service.dart';

@GenerateMocks([MockFirestoreService])
void main() {
  group('TransportProvider Tests', () {
    late TransportProvider transportProvider;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      transportProvider = TransportProvider(firestoreService: mockFirestoreService);
    });

    test('should initialize with empty locations', () {
      expect(transportProvider.supplyPoints, isEmpty);
      expect(transportProvider.demandPoints, isEmpty);
      expect(transportProvider.isLoading, isFalse);
    });

    test('should add supply point correctly', () async {
      final location = LocationModel(
        locationId: 'test_supply_1',
        businessId: 'test_business',
        name: 'Test Supply Point',
        address: 'Test Address',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Factory',
        supplyQuantity: 100,
        demandQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock successful save
      when(mockFirestoreService.saveLocation(any))
          .thenAnswer((_) async => Future.value());

      await transportProvider.addLocation(location);

      verify(mockFirestoreService.saveLocation(location)).called(1);
      expect(transportProvider.supplyPoints, contains(location));
    });

    test('should add demand point correctly', () async {
      final location = LocationModel(
        locationId: 'test_demand_1',
        businessId: 'test_business',
        name: 'Test Demand Point',
        address: 'Test Address',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Retail',
        supplyQuantity: 0,
        demandQuantity: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock successful save
      when(mockFirestoreService.saveLocation(any))
          .thenAnswer((_) async => Future.value());

      await transportProvider.addLocation(location);

      verify(mockFirestoreService.saveLocation(location)).called(1);
      expect(transportProvider.demandPoints, contains(location));
    });

    test('should fetch locations correctly', () async {
      final businessId = 'test_business';
      final locations = [
        LocationModel(
          locationId: 'test_1',
          businessId: businessId,
          name: 'Test Location 1',
          address: 'Address 1',
          latitude: 6.5244,
          longitude: 3.3792,
          type: 'Factory',
          supplyQuantity: 100,
          demandQuantity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        LocationModel(
          locationId: 'test_2',
          businessId: businessId,
          name: 'Test Location 2',
          address: 'Address 2',
          latitude: 6.5244,
          longitude: 3.3792,
          type: 'Retail',
          supplyQuantity: 0,
          demandQuantity: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Mock successful fetch
      when(mockFirestoreService.fetchLocations(businessId))
          .thenAnswer((_) async => Future.value(locations));

      await transportProvider.fetchLocations(businessId);

      verify(mockFirestoreService.fetchLocations(businessId)).called(1);
      expect(transportProvider.supplyPoints, isNotEmpty);
      expect(transportProvider.demandPoints, isNotEmpty);
    });

    test('should handle loading states correctly', () {
      transportProvider.setLoading(true);
      expect(transportProvider.isLoading, isTrue);

      transportProvider.setLoading(false);
      expect(transportProvider.isLoading, isFalse);
    });

    test('should handle error states correctly', () {
      final error = 'Test error message';
      transportProvider.setError(error);
      
      expect(transportProvider.errorMessage, equals(error));
    });

    test('should filter locations by type correctly', () {
      final supplyLocation = LocationModel(
        locationId: 'supply_1',
        businessId: 'test_business',
        name: 'Supply Point',
        address: 'Address 1',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Factory',
        supplyQuantity: 100,
        demandQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final demandLocation = LocationModel(
        locationId: 'demand_1',
        businessId: 'test_business',
        name: 'Demand Point',
        address: 'Address 2',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Retail',
        supplyQuantity: 0,
        demandQuantity: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      transportProvider.supplyPoints.add(supplyLocation);
      transportProvider.demandPoints.add(demandLocation);

      expect(transportProvider.supplyPoints.length, equals(1));
      expect(transportProvider.demandPoints.length, equals(1));
      expect(transportProvider.supplyPoints.first.type, equals('Factory'));
      expect(transportProvider.demandPoints.first.type, equals('Retail'));
    });

    test('should clear locations correctly', () {
      final location = LocationModel(
        locationId: 'test_1',
        businessId: 'test_business',
        name: 'Test Location',
        address: 'Test Address',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Factory',
        supplyQuantity: 100,
        demandQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      transportProvider.supplyPoints.add(location);
      transportProvider.demandPoints.add(location);

      transportProvider.clearLocations();

      expect(transportProvider.supplyPoints, isEmpty);
      expect(transportProvider.demandPoints, isEmpty);
    });
  });
}
