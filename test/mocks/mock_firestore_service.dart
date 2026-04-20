import 'package:mockito/mockito.dart';
import 'package:optiflow/services/firebase/firestore_service.dart';
import 'package:optiflow/models/user_model.dart';
import 'package:optiflow/models/location_model.dart';
import 'package:optiflow/models/route_model.dart';
import 'package:optiflow/models/business_model.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    return Future.value(UserModel(
      userId: 'test_user_id',
      email: email,
      fullName: 'Test User',
      role: 'Business Owner',
      businessId: 'test_business_id',
      createdAt: DateTime.now(),
      isActive: true,
    ));
  }

  @override
  Future<void> signOut() async {
    // Mock implementation
  }

  @override
  Future<UserModel?> createUserWithEmailAndPassword(
    String email, String password, String fullName) async {
    return Future.value(UserModel(
      userId: 'new_user_id',
      email: email,
      fullName: fullName,
      role: 'Business Owner',
      businessId: 'test_business_id',
      createdAt: DateTime.now(),
      isActive: true,
    ));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Mock implementation
  }

  @override
  Future<List<LocationModel>> fetchLocations(String businessId) async {
    return Future.value([
      LocationModel(
        locationId: 'test_location_1',
        businessId: businessId,
        name: 'Test Supply Point',
        address: 'Test Address 1',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Factory',
        supplyQuantity: 100,
        demandQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LocationModel(
        locationId: 'test_location_2',
        businessId: businessId,
        name: 'Test Demand Point',
        address: 'Test Address 2',
        latitude: 6.5244,
        longitude: 3.3792,
        type: 'Retail',
        supplyQuantity: 0,
        demandQuantity: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    // Mock implementation
  }

  @override
  Future<List<RouteModel>> fetchRoutes(String businessId) async {
    return Future.value([
      RouteModel(
        routeId: 'test_route_1',
        businessId: businessId,
        originId: 'Lagos',
        destinationId: 'Abuja',
        distanceKm: 120.5,
        estimatedTime: '2h 30m',
        cost: 5000.0,
        createdAt: DateTime.now(),
        status: 'pending',
        waypoints: [],
      ),
      RouteModel(
        routeId: 'test_route_2',
        businessId: businessId,
        originId: 'Kano',
        destinationId: 'Katsina',
        distanceKm: 85.2,
        estimatedTime: '1h 45m',
        cost: 3500.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        waypoints: [],
      ),
    ]);
  }

  @override
  Future<BusinessModel?> fetchBusiness(String businessId) async {
    return Future.value(BusinessModel(
      businessId: businessId,
      name: 'Test Business',
      industry: 'Logistics',
      registrationNumber: 'TEST123',
      taxId: 'TEST-TAX-ID',
      contactEmail: 'test@business.com',
      contactPhone: '+2345678900',
      address: 'Test Business Address',
      city: 'Test City',
      country: 'Nigeria',
      isPremium: false,
      remainingFreeOptimizations: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updateBusiness(BusinessModel business) async {
    // Mock implementation
  }

  @override
  Future<List<UserModel>> fetchUsers(String businessId) async {
    return Future.value([]);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    // Mock implementation
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    // Mock implementation
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return Future.value(UserModel(
      userId: 'current_user_id',
      email: 'current@test.com',
      fullName: 'Current User',
      role: 'Business Owner',
      businessId: 'test_business_id',
      createdAt: DateTime.now(),
      isActive: true,
    ));
  }

  @override
  Future<void> updatePassword(String userId, String newPassword) async {
    // Mock implementation
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Mock implementation
  }

  @override
  Future<void> sendEmailVerification(String email) async {
    // Mock implementation
  }

  @override
  Future<bool> isEmailVerified(String userId) async {
    return Future.value(true);
  }

  @override
  Future<void> setEmailVerified(String userId) async {
    // Mock implementation
  }

  @override
  Future<void> logout() async {
    // Mock implementation
  }

  @override
  Stream<UserModel?> get userStream {
    return Stream.value(null);
  }

  @override
  Future<void> saveRoute(RouteModel route) async {
    // Mock implementation
  }

  @override
  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    // Mock implementation
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    // Mock implementation
  }

  @override
  Future<void> saveOptimizationResult(String businessId, Map<String, dynamic> result) async {
    // Mock implementation
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOptimizationResults(String businessId) async {
    return Future.value([]);
  }

  @override
  Future<void> createSubscription(String businessId, Map<String, dynamic> subscriptionData) async {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>?> getSubscription(String businessId) async {
    return Future.value(null);
  }

  @override
  Future<void> updateSubscription(String businessId, Map<String, dynamic> data) async {
    // Mock implementation
  }

  @override
  Future<void> cancelSubscription(String businessId) async {
    // Mock implementation
  }

  @override
  Future<void> sendNotification(String title, String body, List<String> userIds) async {
    // Mock implementation
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    return Future.value([]);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    // Mock implementation
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    // Mock implementation
  }

  @override
  Future<void> saveReport(String businessId, Map<String, dynamic> reportData) async {
    // Mock implementation
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReports(String businessId) async {
    return Future.value([]);
  }

  @override
  Future<void> updateReport(String reportId, Map<String, dynamic> data) async {
    // Mock implementation
  }

  @override
  Future<void> deleteReport(String reportId) async {
    // Mock implementation
  }

  @override
  Future<void> saveBudget(String businessId, Map<String, dynamic> budgetData) async {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>?> getBudget(String businessId) async {
    return Future.value(null);
  }

  @override
  Future<void> updateBudget(String businessId, Map<String, dynamic> data) async {
    // Mock implementation
  }

  @override
  Future<void> saveBudgetOptimization(String businessId, Map<String, dynamic> result) async {
    // Mock implementation
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBudgetOptimizations(String businessId) async {
    return Future.value([]);
  }
}
