import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';
import '../models/delivery_stop_model.dart';
import '../services/database/database_service.dart';
import '../services/api/maps_api.dart';
import '../services/route_service.dart';
import '../services/offline_route_service.dart';
import '../services/error_handling_service.dart';
import '../utils/logger.dart';
import '../utils/app_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/location/haversine_formula.dart';

class RouteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();
  final MapsApi _mapsApi = MapsApi();

  List<RouteModel> _routes = [];
  List<DeliveryStopModel> _currentRouteStops = [];
  List<LatLng> _currentRoutePoints = [];
  bool _isLoading = false;
  bool _isOnline = true;
  String? _errorMessage;

  // Planner State
  List<Map<String, dynamic>> _plannedLocations = [];
  String _optimizationType = 'distance'; // distance, time, scenic
  Map<String, bool> _avoidances = {
    'tolls': false,
    'highways': false,
    'ferries': false,
  };
  Map<String, dynamic>? _lastOptimizationResult;

  List<RouteModel> get routes => _routes;
  List<DeliveryStopModel> get currentRouteStops => _currentRouteStops;
  List<LatLng> get currentRoutePoints => _currentRoutePoints;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get errorMessage => _errorMessage;
  
  List<Map<String, dynamic>> get plannedLocations => _plannedLocations;
  String get optimizationType => _optimizationType;
  Map<String, bool> get avoidances => _avoidances;
  Map<String, dynamic>? get lastOptimizationResult => _lastOptimizationResult;

  // --- Search & Directions ---

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];
    return await _mapsApi.searchPlaces(query);
  }

  Future<LatLng?> getPlaceLatLng(String placeId) async {
    return await _mapsApi.getPlaceDetails(placeId);
  }

  double _currentTotalDistance = 0;
  String _currentTotalDuration = '';

  double get currentTotalDistance => _currentTotalDistance;
  String get currentTotalDuration => _currentTotalDuration;

  Future<void> updateRoutePath() async {
    if (_plannedLocations.length < 2) {
      _currentRoutePoints = [];
      _currentTotalDistance = 0;
      _currentTotalDuration = '';
      notifyListeners();
      return;
    }

    try {
      final origin = LatLng(_plannedLocations.first['lat'], _plannedLocations.first['lng']);
      final destination = LatLng(_plannedLocations.last['lat'], _plannedLocations.last['lng']);
      final waypoints = _plannedLocations
          .skip(1)
          .take(_plannedLocations.length - 2)
          .map((l) => LatLng(l['lat'], l['lng']))
          .toList();

      final directions = await _mapsApi.getDirections(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );
      
      _currentRoutePoints = directions['points'] as List<LatLng>;
      _currentTotalDistance = double.tryParse((directions['distance'] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      _currentTotalDuration = directions['duration'] as String;
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to update route path', error: e);
    }
  }

  // --- Planner Methods ---

  void addLocation(Map<String, dynamic> location) {
    // Only set default role if not already specified
    if (location['role'] == null) {
      if (_plannedLocations.isEmpty) {
        location['role'] = 'Start Point';
      } else {
        location['role'] = 'Regular Stop';
      }
    }
    _plannedLocations.add(location);
    updateRoutePath();
    notifyListeners();
  }

  void updateLocation(int index, Map<String, dynamic> updatedData) {
    if (index >= 0 && index < _plannedLocations.length) {
      _plannedLocations[index] = {..._plannedLocations[index], ...updatedData};
      updateRoutePath();
      notifyListeners();
    }
  }

  void removeLocation(int index) {
    if (index >= 0 && index < _plannedLocations.length) {
      _plannedLocations.removeAt(index);
      updateRoutePath();
      notifyListeners();
    }
  }

  void reorderLocations(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _plannedLocations.removeAt(oldIndex);
    _plannedLocations.insert(newIndex, item);
    updateRoutePath();
    notifyListeners();
  }

  void setOptimizationType(String type) {
    _optimizationType = type;
    notifyListeners();
  }

  void setAvoidance(String key, bool value) {
    _avoidances[key] = value;
    notifyListeners();
  }

  void clearPlanner() {
    _plannedLocations = [];
    _currentRoutePoints = [];
    _lastOptimizationResult = null;
    notifyListeners();
  }

  // --- Optimization Logic ---

  Future<void> runOptimization() async {
    if (_plannedLocations.length < 2) {
      _errorMessage = 'At least 2 locations required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _checkConnectivity();
      
      if (_isOnline) {
        // Prepare call to API
        final origin = _plannedLocations.firstWhere((l) => l['role'] == 'Start Point', orElse: () => _plannedLocations.first);
        final destinations = _plannedLocations.where((l) => l != origin).map((l) => '${l['lat']},${l['lng']}').toList();
        
        final result = await RouteService.optimizeRoute(
          destinations: destinations,
          origin: '${origin['lat']},${origin['lng']}',
          preferences: {
            'type': _optimizationType,
            'avoid': _avoidances.entries.where((e) => e.value).map((e) => e.key).toList(),
          },
        );

        if (result != null) {
          double hours = _parseTimeToHours(result.estimatedTime, result.distanceKm);
          _lastOptimizationResult = {
            'total_distance': result.distanceKm,
            'total_time': hours,
            'stops': _plannedLocations.length,
          };
          _errorMessage = null;
          await updateRoutePath();
        } else {
          _errorMessage = 'Failed to optimize. Calculating real geographic distances...';
          await _calculateRealFallbackRoute();
        }
      } else {
        await _calculateRealFallbackRoute();
      }
    } catch (e) {
      _errorMessage = 'Optimization error. Calculating path manually.';
      await _calculateRealFallbackRoute();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _parseTimeToHours(String timeStr, double fallbackDistance) {
    if (timeStr.isEmpty) return fallbackDistance / 40.0;
    final cleanStr = timeStr.toLowerCase();
    final num = double.tryParse(timeStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? (fallbackDistance / 40.0);
    
    if (cleanStr.contains('min')) return num / 60.0;
    if (cleanStr.contains('day')) return num * 24.0;
    return num; 
  }

  Future<void> _calculateRealFallbackRoute() async {
    if (_plannedLocations.length < 2) return;

    try {
      final origins = _plannedLocations.map((l) => LatLng(l['lat'], l['lng'])).toList();
      double totalDistance = 0;
      double totalSeconds = 0;

      for (int i = 0; i < origins.length - 1; i++) {
        final matrix = await _mapsApi.getDistanceMatrix(
          origins: [origins[i]],
          destinations: [origins[i+1]],
        );

        if (matrix['status'] == 'OK' && matrix['rows'][0]['elements'][0]['status'] == 'OK') {
          final element = matrix['rows'][0]['elements'][0];
          totalDistance += (element['distance']['value'] / 1000.0);
          totalSeconds += element['duration']['value'];
        }
      }

      // Real fallback using genuine geographic GPS coordinates (Haversine Formula) when Google Distance Matrix is unavailable
      if (totalDistance == 0) {
        for (int i = 0; i < origins.length - 1; i++) {
          double geoDistance = HaversineFormula.calculateDistance(
            origins[i].latitude, origins[i].longitude, 
            origins[i+1].latitude, origins[i+1].longitude
          );
          // Add a 1.3 road winding factor multiplier to straight line distance
          totalDistance += (geoDistance * 1.3);
        }
        totalSeconds = (totalDistance / 40.0) * 3600; // Assume 40 km/h average
      }

      _lastOptimizationResult = {
        'total_distance': totalDistance,
        'total_time': totalSeconds / 3600.0,
        'stops': _plannedLocations.length,
      };
      
      await updateRoutePath();
    } catch (e) {
      Logger.error('Real fallback calculation failed', error: e);
    }
  }

  Future<void> fetchAssignedRoutes(String driverId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('driver_id', isEqualTo: driverId)
          .get();
      _routes = snapshot.docs.map((doc) => RouteModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to fetch assigned routes', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoutes(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _checkConnectivity();
      
      if (_isOnline) {
        // Try backend API first
        final backendRoutes = await RouteService.getSavedRoutes(businessId);
        if (backendRoutes.isNotEmpty) {
          _routes = backendRoutes;
          
          // Cache for offline use
          for (final route in _routes) {
            await OfflineRouteService.cacheRoute(route);
          }
          
          // Also save to Firestore for backup
          await _saveToFirestore(businessId);
        } else {
          // Fallback to Firestore
          await _fetchFromFirestore(businessId);
        }
      } else {
        // Offline mode - use cache
        _routes = await OfflineRouteService.getAllCachedRoutes();
      }
      
      notifyListeners();
    } catch (e, stack) {
      _errorMessage = 'Failed to load routes: ${e.toString()}';
      Logger.error('Error fetching routes', name: 'RouteProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkConnectivity() async {
    _isOnline = await OfflineRouteService.isOnline();
  }

  Future<void> _fetchFromFirestore(String businessId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('routes')
        .where('business_id', isEqualTo: businessId)
        .get();

    _routes = snapshot.docs.map((doc) => RouteModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

    // Update local cache
    await _dbService.clearTable('routes');
    for (var route in _routes) {
      await _dbService.insert('routes', route.toMap());
    }
  }

  Future<void> _saveToFirestore(String businessId) async {
    for (var route in _routes) {
      await _firestore.collection('routes').doc(route.routeId).set(route.toMap());
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchStopsForRoute(String routeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('delivery_stops')
          .where('route_id', isEqualTo: routeId)
          .orderBy('sequence_order')
          .get();

      _currentRouteStops = snapshot.docs.map((doc) => DeliveryStopModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      Logger.error('Error fetching stops', name: 'RouteProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoutePoints(LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    _isLoading = true;
    _currentRoutePoints = [];
    notifyListeners();

    try {
      final directions = await _mapsApi.getDirections(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );
      
      _currentRoutePoints = directions['points'] as List<LatLng>;
    } catch (e, stack) {
      Logger.error('Error fetching route points', name: 'RouteProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<UserModel> _availableDrivers = [];
  List<UserModel> get availableDrivers => _availableDrivers;

  Future<void> fetchDrivers(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('business_id', isEqualTo: businessId)
          .where('role', isEqualTo: 'Driver')
          .get();
      
      _availableDrivers = snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to fetch drivers', error: e);
    }
  }

  Future<bool> assignRouteToDriver({
    required String driverId,
    required String businessId,
    required List<Map<String, dynamic>> stops,
    required Map<String, dynamic> stats,
  }) async {
    try {
      final routeId = 'ROUTE-${DateTime.now().millisecondsSinceEpoch}';
      
      final routeData = {
        'route_id': routeId,
        'business_id': businessId,
        'driver_id': driverId,
        'assigned_at': FieldValue.serverTimestamp(),
        'status': 'assigned',
        'distance_km': stats['total_distance'],
        'estimated_time': '${(stats['total_time'] as double).toStringAsFixed(1)} hrs',
        'created_at': FieldValue.serverTimestamp(),
        'origin_id': stops.first['name'],
        'destination_id': stops.last['name'],
      };

      await _firestore.collection('routes').doc(routeId).set(routeData);

      // Create delivery stops
      for (int i = 0; i < stops.length; i++) {
        final s = stops[i];
        final stopId = 'STOP-${routeId}-$i';
        await _firestore.collection('delivery_stops').doc(stopId).set({
          'stop_id': stopId,
          'route_id': routeId,
          'business_id': businessId,
          'name': s['name'],
          'lat': s['lat'],
          'lng': s['lng'],
          'role': s['role'],
          'sequence_order': i,
          'status': 'Pending',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      Logger.error('Assignment failed', error: e);
      return false;
    }
  }

  Future<void> updateStopStatus(String stopId, String status, {String? podUrl, String? signatureUrl}) async {
    try {
      final updateData = {
        'status': status,
        if (status == 'Arrived') 'arrival_time': Timestamp.now(),
        if (status == 'Completed') 'completion_time': Timestamp.now(),
        if (podUrl != null) 'proof_of_delivery_url': podUrl,
        if (signatureUrl != null) 'signature_url': signatureUrl,
      };

      await _firestore.collection('delivery_stops').doc(stopId).update(updateData);

      // Update local state for immediate UI refresh
      final index = _currentRouteStops.indexWhere((s) => s.stopId == stopId);
      if (index != -1) {
        _currentRouteStops[index] = DeliveryStopModel.fromMap({
          ..._currentRouteStops[index].toMap(),
          ...updateData,
        });
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Failed to update stop status', error: e);
    }
  }
}
