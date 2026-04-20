import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../models/route_model.dart';
import '../utils/environment.dart';

class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  Database? _database;
  bool _isInitialized = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  
  // Offline map tiles cache
  final Map<String, Uint8List> _tileCache = {};
  final int _maxCacheSize = 1000; // Maximum number of tiles to cache
  
  // Offline route data
  final List<OfflineRouteData> _offlineRoutes = [];
  
  // Connectivity monitoring
  Stream<bool> get connectivityStream => _connectivityController.stream;
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  List<OfflineRouteData> get offlineRoutes => List.unmodifiable(_offlineRoutes);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _initializeDatabase();
      await _startConnectivityMonitoring();
      await _loadCachedData();
      
      _isInitialized = true;
      Logger.info('OfflineMapService initialized successfully', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Failed to initialize OfflineMapService', name: 'OfflineMapService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/offline_maps.db';
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Offline routes table
    await db.execute('''
      CREATE TABLE offline_routes (
        id TEXT PRIMARY KEY,
        name TEXT,
        route_data TEXT,
        cached_at INTEGER,
        is_active INTEGER DEFAULT 1
      )
    ''');
    
    // Map tiles cache table
    await db.execute('''
      CREATE TABLE map_tiles (
        tile_key TEXT PRIMARY KEY,
        tile_data BLOB,
        cached_at INTEGER
      )
    ''');
    
    // Location points table for offline navigation
    await db.execute('''
      CREATE TABLE location_points (
        id TEXT PRIMARY KEY,
        route_id TEXT,
        latitude REAL,
        longitude REAL,
        sequence_index INTEGER,
        stop_name TEXT,
        stop_type TEXT,
        FOREIGN KEY (route_id) REFERENCES offline_routes (id)
      )
    ''');
  }

  Future<void> _startConnectivityMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        Logger.info('Connectivity changed: ${_isOnline ? "Online" : "Offline"}', name: 'OfflineMapService');
        
        if (_isOnline) {
          _syncOfflineData();
        }
      }
    });
    
    // Check initial connectivity
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  Future<void> _loadCachedData() async {
    if (_database == null) return;
    
    try {
      // Load cached routes
      final routes = await _database!.query('offline_routes', where: 'is_active = 1');
      _offlineRoutes.clear();
      
      for (final route in routes) {
        final routeData = OfflineRouteData.fromJson(jsonDecode(route['route_data'] as String));
        _offlineRoutes.add(routeData);
      }
      
      Logger.info('Loaded ${_offlineRoutes.length} cached routes', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Error loading cached data', name: 'OfflineMapService', error: e, stackTrace: stack);
    }
  }

  // Cache a route for offline use
  Future<void> cacheRouteForOffline(RouteModel route) async {
    if (!_isInitialized) await initialize();
    
    try {
      final offlineRoute = OfflineRouteData.fromRouteModel(route);
      
      // Save to database
      if (_database != null) {
        await _database!.insert(
          'offline_routes',
          {
            'id': offlineRoute.id,
            'name': offlineRoute.name,
            'route_data': jsonEncode(offlineRoute.toJson()),
            'cached_at': DateTime.now().millisecondsSinceEpoch,
            'is_active': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        // Save location points
        for (int i = 0; i < offlineRoute.waypoints.length; i++) {
          final waypoint = offlineRoute.waypoints[i];
          await _database!.insert(
            'location_points',
            {
              'id': '${offlineRoute.id}_point_$i',
              'route_id': offlineRoute.id,
              'latitude': waypoint.latitude,
              'longitude': waypoint.longitude,
              'sequence_index': i,
              'stop_name': waypoint.name ?? 'Stop $i',
              'stop_type': waypoint.type ?? 'waypoint',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      
      // Add to memory cache
      _offlineRoutes.add(offlineRoute);
      
      // Pre-cache map tiles for the route area
      await _preCacheRouteTiles(offlineRoute);
      
      Logger.info('Route cached for offline use: ${route.routeId}', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Error caching route for offline', name: 'OfflineMapService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // Pre-cache map tiles for a route area
  Future<void> _preCacheRouteTiles(OfflineRouteData route) async {
    if (!_isOnline) return;
    
    try {
      final bounds = _calculateRouteBounds(route);
      final zoomLevels = [10, 12, 14, 16]; // Different zoom levels for caching
      
      for (final zoom in zoomLevels) {
        await _cacheTilesForBounds(bounds, zoom);
      }
      
      Logger.info('Pre-cached map tiles for route: ${route.id}', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Error pre-caching route tiles', name: 'OfflineMapService', error: e, stackTrace: stack);
    }
  }

  LatLngBounds _calculateRouteBounds(OfflineRouteData route) {
    if (route.waypoints.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    
    double minLat = route.waypoints.first.latitude;
    double maxLat = route.waypoints.first.latitude;
    double minLng = route.waypoints.first.longitude;
    double maxLng = route.waypoints.first.longitude;
    
    for (final waypoint in route.waypoints) {
      minLat = math.min(minLat, waypoint.latitude);
      maxLat = math.max(maxLat, waypoint.latitude);
      minLng = math.min(minLng, waypoint.longitude);
      maxLng = math.max(maxLng, waypoint.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _cacheTilesForBounds(LatLngBounds bounds, int zoom) async {
    // This is a simplified implementation
    // In a real app, you would use a tile service like Mapbox or Google Maps tiles API
    
    final minTile = _latLngToTile(bounds.southwest, zoom);
    final maxTile = _latLngToTile(bounds.northeast, zoom);
    
    for (int x = minTile.x; x <= maxTile.x; x++) {
      for (int y = minTile.y; y <= maxTile.y; y++) {
        final tileKey = '$zoom/$x/$y';
        
        if (!_tileCache.containsKey(tileKey)) {
          try {
            // In a real implementation, you would fetch tiles from a tile service
            // For now, we'll simulate tile caching
            final tileData = await _fetchTileData(x, y, zoom);
            
            if (tileData != null) {
              _tileCache[tileKey] = tileData;
              
              // Save to database
              if (_database != null) {
                await _database!.insert(
                  'map_tiles',
                  {
                    'tile_key': tileKey,
                    'tile_data': tileData,
                    'cached_at': DateTime.now().millisecondsSinceEpoch,
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          } catch (e) {
            Logger.warning('Failed to cache tile $tileKey', name: 'OfflineMapService');
          }
        }
      }
    }
  }

  math.Point<int> _latLngToTile(LatLng latLng, int zoom) {
    final x = ((latLng.longitude + 180) / 360 * (1 << zoom)).floor();
    final y = ((1 - math.log(math.tan(latLng.latitude * math.pi / 180) + 
              1 / math.cos(latLng.latitude * math.pi / 180)) / math.pi / 2) * (1 << zoom)).floor();
    return math.Point(x, y);
  }

  Future<Uint8List?> _fetchTileData(int x, int y, int zoom) async {
    // Simulated tile data - in a real app, fetch from tile service
    // This would use services like Mapbox, Google Maps Tiles API, or OpenStreetMap
    return Uint8List.fromList([0, 0, 0]); // Placeholder
  }

  // Get offline route data
  OfflineRouteData? getOfflineRoute(String routeId) {
    try {
      return _offlineRoutes.firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }

  // Get all offline routes
  List<OfflineRouteData> getAllOfflineRoutes() {
    return List.unmodifiable(_offlineRoutes);
  }

  // Remove route from offline cache
  Future<void> removeOfflineRoute(String routeId) async {
    try {
      // Remove from database
      if (_database != null) {
        await _database!.delete('offline_routes', where: 'id = ?', whereArgs: [routeId]);
        await _database!.delete('location_points', where: 'route_id = ?', whereArgs: [routeId]);
      }
      
      // Remove from memory cache
      _offlineRoutes.removeWhere((route) => route.id == routeId);
      
      Logger.info('Removed offline route: $routeId', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Error removing offline route', name: 'OfflineMapService', error: e, stackTrace: stack);
    }
  }

  // Sync offline data when coming back online
  Future<void> _syncOfflineData() async {
    try {
      // Sync any pending operations
      // This would include uploading offline proof of delivery, route updates, etc.
      
      Logger.info('Syncing offline data', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Error syncing offline data', name: 'OfflineMapService', error: e, stackTrace: stack);
    }
  }

  // Get offline map tiles
  Uint8List? getOfflineTile(String tileKey) {
    return _tileCache[tileKey];
  }

  // Calculate route progress offline
  double calculateRouteProgress(String routeId, LatLng currentLocation) {
    final offlineRoute = getOfflineRoute(routeId);
    if (offlineRoute == null || offlineRoute.waypoints.isEmpty) {
      return 0.0;
    }
    
    double totalDistance = 0.0;
    double coveredDistance = 0.0;
    
    // Calculate total route distance
    for (int i = 0; i < offlineRoute.waypoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        LatLng(offlineRoute.waypoints[i].latitude, offlineRoute.waypoints[i].longitude),
        LatLng(offlineRoute.waypoints[i + 1].latitude, offlineRoute.waypoints[i + 1].longitude),
      );
    }
    
    // Find current position in route and calculate covered distance
    for (int i = 0; i < offlineRoute.waypoints.length - 1; i++) {
      coveredDistance += _calculateDistance(
        LatLng(offlineRoute.waypoints[i].latitude, offlineRoute.waypoints[i].longitude),
        LatLng(offlineRoute.waypoints[i + 1].latitude, offlineRoute.waypoints[i + 1].longitude),
      );
      
      // Check if we've passed this segment
      final distanceToNext = _calculateDistance(
        currentLocation,
        LatLng(offlineRoute.waypoints[i + 1].latitude, offlineRoute.waypoints[i + 1].longitude),
      );
      
      if (distanceToNext < 100) { // Within 100m of next waypoint
        break;
      }
    }
    
    return totalDistance > 0 ? (coveredDistance / totalDistance).clamp(0.0, 1.0) : 0.0;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Haversine formula for calculating distance between two points
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

  // Get next waypoint for offline navigation
  OfflineWaypoint? getNextWaypoint(String routeId, LatLng currentLocation) {
    final offlineRoute = getOfflineRoute(routeId);
    if (offlineRoute == null || offlineRoute.waypoints.isEmpty) {
      return null;
    }
    
    OfflineWaypoint? nextWaypoint;
    double minDistance = double.infinity;
    
    for (final waypoint in offlineRoute.waypoints) {
      final distance = _calculateDistance(currentLocation, waypoint.latLng);
      if (distance < minDistance && distance > 50) { // Not too close, not too far
        minDistance = distance;
        nextWaypoint = waypoint;
      }
    }
    
    return nextWaypoint;
  }

  // Cleanup old cached data
  Future<void> cleanupOldCache() async {
    if (_database == null) return;
    
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      // Remove old routes
      await _database!.delete(
        'offline_routes',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );
      
      // Remove old tiles
      await _database!.delete(
        'map_tiles',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );
      
      Logger.info('Cleaned up old cache data', name: 'OfflineMapService');
    } catch (e, stack) {
      Logger.error('Error cleaning up cache', name: 'OfflineMapService', error: e, stackTrace: stack);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _database?.close();
  }
}

class OfflineRouteData {
  final String id;
  final String name;
  final List<OfflineWaypoint> waypoints;
  final DateTime cachedAt;
  final Map<String, dynamic> metadata;

  OfflineRouteData({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.cachedAt,
    this.metadata = const {},
  });

  factory OfflineRouteData.fromRouteModel(RouteModel route) {
    return OfflineRouteData(
      id: route.routeId,
      name: route.routeId, // Use routeId as name since routeName doesn't exist
      waypoints: route.waypoints.map((point) => OfflineWaypoint(
        latitude: point.latitude,
        longitude: point.longitude,
        name: 'Waypoint', // Provide default name
        type: 'stop', // Provide default type
      )).toList(),
      cachedAt: DateTime.now(),
      metadata: {
        'businessId': route.businessId,
        'createdAt': route.createdAt.millisecondsSinceEpoch,
        'status': 'active', // Provide default status
      },
    );
  }

  factory OfflineRouteData.fromJson(Map<String, dynamic> json) {
    return OfflineRouteData(
      id: json['id'] as String,
      name: json['name'] as String,
      waypoints: (json['waypoints'] as List)
          .map((w) => OfflineWaypoint.fromJson(w as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}

class OfflineWaypoint {
  final double latitude;
  final double longitude;
  final String? name;
  final String? type;
  final Map<String, dynamic>? metadata;

  OfflineWaypoint({
    required this.latitude,
    required this.longitude,
    this.name,
    this.type,
    this.metadata,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory OfflineWaypoint.fromJson(Map<String, dynamic> json) {
    return OfflineWaypoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      name: json['name'] as String?,
      type: json['type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'type': type,
      'metadata': metadata,
    };
  }
}

