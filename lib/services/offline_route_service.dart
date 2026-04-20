import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/route_model.dart';
import '../utils/logger.dart';

class OfflineRouteService {
  static Database? _database;
  static const String _tableName = 'offline_routes';
  
  // Initialize offline database
  static Future<void> init() async {
    if (_database != null) return;
    
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'optiflow_offline.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              route_id TEXT UNIQUE,
              name TEXT,
              start_lat REAL,
              start_lng REAL,
              end_lat REAL,
              end_lng REAL,
              waypoints TEXT,
              distance REAL,
              estimated_time INTEGER,
              created_at INTEGER,
              last_used INTEGER
            )
          ''');
        },
      );
      
      Logger.info('Offline route database initialized successfully', name: 'OfflineRouteService');
    } catch (e, stack) {
      Logger.error('Failed to initialize offline route database', name: 'OfflineRouteService', error: e, stackTrace: stack);
    }
  }

  // Check if device is online
  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      Logger.error('Failed to check connectivity', name: 'OfflineRouteService', error: e);
      return false; // Assume offline if check fails
    }
  }

  // Cache a route for offline use
  static Future<bool> cacheRoute(RouteModel route) async {
    try {
      await init();
      
      final routeData = {
        'route_id': route.routeId,
        'name': route.routeId,
        'start_lat': route.startLocation?.latitude ?? 0.0,
        'start_lng': route.startLocation?.longitude ?? 0.0,
        'end_lat': route.endLocation?.latitude ?? 0.0,
        'end_lng': route.endLocation?.longitude ?? 0.0,
        'waypoints': jsonEncode(route.waypoints.map((w) => {
          'lat': w.latitude,
          'lng': w.longitude,
        }).toList()),
        'distance': route.distanceKm,
        'estimated_time': int.parse(route.estimatedTime.split(' ')[0]),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'last_used': DateTime.now().millisecondsSinceEpoch,
      };

      await _database!.insert(
        _tableName,
        routeData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('Route cached successfully: ${route.routeId}', name: 'OfflineRouteService');
      return true;
    } catch (e, stack) {
      Logger.error('Failed to cache route', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return false;
    }
  }

  // Get cached route by ID
  static Future<RouteModel?> getCachedRoute(String routeId) async {
    try {
      await init();
      
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'route_id = ?',
        whereArgs: [routeId],
      );

      if (maps.isEmpty) return null;

      final routeData = maps.first;
      final waypointsList = jsonDecode(routeData['waypoints']) as List;
      
      return RouteModel(
        routeId: routeData['route_id'],
        businessId: 'default',
        originId: routeData['route_id'],
        destinationId: routeData['route_id'],
        distanceKm: routeData['distance'],
        estimatedTime: '${routeData['estimated_time']} min',
        cost: 0.0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(routeData['created_at']),
        startLocation: LatLng(routeData['start_lat'], routeData['start_lng']),
        endLocation: LatLng(routeData['end_lat'], routeData['end_lng']),
        waypoints: waypointsList.map((w) => LatLng(w['lat'], w['lng'])).cast<LatLng>().toList(),
      );
    } catch (e, stack) {
      Logger.error('Failed to get cached route', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return null;
    }
  }

  // Get all cached routes
  static Future<List<RouteModel>> getAllCachedRoutes() async {
    try {
      await init();
      
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        orderBy: 'last_used DESC',
      );

      return maps.map((routeData) {
        final waypointsList = jsonDecode(routeData['waypoints']) as List;
        
        return RouteModel(
          routeId: routeData['route_id'],
          businessId: 'default',
          originId: routeData['route_id'],
          destinationId: routeData['route_id'],
          distanceKm: routeData['distance'],
          estimatedTime: '${routeData['estimated_time']} minutes',
          cost: 0.0,
          createdAt: DateTime.fromMillisecondsSinceEpoch(routeData['created_at']),
          startLocation: LatLng(routeData['start_lat'], routeData['start_lng']),
          endLocation: LatLng(routeData['end_lat'], routeData['end_lng']),
          waypoints: waypointsList.map((w) => LatLng(w['lat'], w['lng'])).cast<LatLng>().toList(),
          isOffline: true,
          lastUsed: DateTime.fromMillisecondsSinceEpoch(routeData['last_used']),
        );
      }).toList();
    } catch (e, stack) {
      Logger.error('Failed to get all cached routes', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return [];
    }
  }

  // Update route last used timestamp
  static Future<bool> updateRouteLastUsed(String routeId) async {
    try {
      await init();
      
      await _database!.update(
        _tableName,
        {'last_used': DateTime.now().millisecondsSinceEpoch},
        where: 'route_id = ?',
        whereArgs: [routeId],
      );

      Logger.info('Route last used updated: $routeId', name: 'OfflineRouteService');
      return true;
    } catch (e, stack) {
      Logger.error('Failed to update route last used', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return false;
    }
  }

  // Delete cached route
  static Future<bool> deleteCachedRoute(String routeId) async {
    try {
      await init();
      
      await _database!.delete(
        _tableName,
        where: 'route_id = ?',
        whereArgs: [routeId],
      );

      Logger.info('Route deleted from cache: $routeId', name: 'OfflineRouteService');
      return true;
    } catch (e, stack) {
      Logger.error('Failed to delete cached route', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return false;
    }
  }

  // Clear all cached routes
  static Future<bool> clearAllCachedRoutes() async {
    try {
      await init();
      
      await _database!.delete(_tableName);

      Logger.info('All cached routes cleared', name: 'OfflineRouteService');
      return true;
    } catch (e, stack) {
      Logger.error('Failed to clear cached routes', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return false;
    }
  }

  // Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      await init();
      
      final List<Map<String, dynamic>> maps = await _database!.rawQuery('''
        SELECT COUNT(*) as count, 
               AVG(LENGTH(waypoints)) as avg_waypoints_size
        FROM $_tableName
      ''');

      if (maps.isEmpty) return 0;
      
      final count = maps.first['count'] as int;
      final avgSize = maps.first['avg_waypoints_size'] as double;
      
      // Rough estimate of cache size
      return (count * avgSize * 2).round(); // Multiply by 2 for overhead
    } catch (e, stack) {
      Logger.error('Failed to get cache size', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return 0;
    }
  }

  // Clean old routes (older than 30 days)
  static Future<int> cleanOldRoutes() async {
    try {
      await init();
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      final deletedCount = await _database!.delete(
        _tableName,
        where: 'created_at < ?',
        whereArgs: [thirtyDaysAgo],
      );

      Logger.info('Cleaned $deletedCount old routes from cache', name: 'OfflineRouteService');
      return deletedCount;
    } catch (e, stack) {
      Logger.error('Failed to clean old routes', name: 'OfflineRouteService', error: e, stackTrace: stack);
      return 0;
    }
  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
