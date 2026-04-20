import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/route_provider.dart';
import '../providers/auth_provider.dart';
import '../services/route_service.dart';
import '../services/offline_route_service.dart';
import '../utils/logger.dart';
import '../utils/app_config.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  // Initialize sync service
  Future<void> initialize() async {
    await _checkConnectivity();
    _setupConnectivityListener();
    _setupPeriodicSync();
    
    Logger.info('Sync service initialized', name: 'SyncService');
  }

  // Setup connectivity monitoring
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Just came back online - trigger immediate sync
        _performFullSync();
      }
      
      Logger.info('Connectivity changed: $_isOnline', name: 'SyncService');
    });
  }

  // Setup periodic sync
  void _setupPeriodicSync() {
    _syncTimer = Timer.periodic(AppConfig.offlineSyncInterval, (timer) {
      if (_isOnline && !_isSyncing) {
        _performIncrementalSync();
      }
    });
  }

  // Check current connectivity
  Future<void> _checkConnectivity() async {
    _isOnline = await OfflineRouteService.isOnline();
  }

  // Perform full sync when coming online
  Future<void> _performFullSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    Logger.info('Starting full sync', name: 'SyncService');
    
    try {
      // Sync routes
      await _syncRoutes();
      
      // Sync user data
      await _syncUserData();
      
      Logger.info('Full sync completed', name: 'SyncService');
    } catch (e, stack) {
      Logger.error('Full sync failed', name: 'SyncService', error: e, stackTrace: stack);
    } finally {
      _isSyncing = false;
    }
  }

  // Perform incremental sync periodically
  Future<void> _performIncrementalSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    Logger.info('Starting incremental sync', name: 'SyncService');
    
    try {
      // Only sync changed data
      await _syncChangedRoutes();
      
      Logger.info('Incremental sync completed', name: 'SyncService');
    } catch (e, stack) {
      Logger.error('Incremental sync failed', name: 'SyncService', error: e, stackTrace: stack);
    } finally {
      _isSyncing = false;
    }
  }

  // Sync routes with backend
  Future<void> _syncRoutes() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Get local cached routes
      final cachedRoutes = await OfflineRouteService.getAllCachedRoutes();
      
      // Get backend routes
      final backendRoutes = await RouteService.getSavedRoutes(currentUser.uid);
      
      // Sync logic
      for (final cachedRoute in cachedRoutes) {
        final backendMatch = backendRoutes.firstWhere(
          (r) => r.routeId == cachedRoute.routeId,
          orElse: () => cachedRoute, // Use cached if not found
        );
        
        // Update if different
        if (backendMatch.createdAt.isAfter(cachedRoute.createdAt)) {
          await OfflineRouteService.cacheRoute(backendMatch);
        }
      }
      
      // Add new routes from backend
      for (final backendRoute in backendRoutes) {
        final exists = cachedRoutes.any((r) => r.routeId == backendRoute.routeId);
        if (!exists) {
          await OfflineRouteService.cacheRoute(backendRoute);
        }
      }
      
    } catch (e, stack) {
      Logger.error('Route sync failed', name: 'SyncService', error: e, stackTrace: stack);
    }
  }

  // Sync changed routes only
  Future<void> _syncChangedRoutes() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Get recent routes from backend (last 24 hours)
      final since = DateTime.now().subtract(const Duration(hours: 24));
      // This would need backend API support for "since" parameter
      
      // For now, just do a light sync
      await _syncRoutes();
      
    } catch (e, stack) {
      Logger.error('Changed routes sync failed', name: 'SyncService', error: e, stackTrace: stack);
    }
  }

  // Sync user data
  Future<void> _syncUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Update user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'last_sync': DateTime.now().toIso8601String(),
            'sync_status': 'completed',
          });
      
    } catch (e, stack) {
      Logger.error('User data sync failed', name: 'SyncService', error: e, stackTrace: stack);
    }
  }

  // Force manual sync
  Future<void> forceSync() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }
    
    await _performFullSync();
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
      'last_sync': DateTime.now().toIso8601String(),
      'sync_interval': AppConfig.offlineSyncInterval.inSeconds,
    };
  }

  // Cleanup resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    Logger.info('Sync service disposed', name: 'SyncService');
  }
}
