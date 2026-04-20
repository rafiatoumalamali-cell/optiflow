import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database/database_service.dart';
import '../../services/sync/sync_queue_service.dart';
import '../../services/sync/conflict_resolver.dart';
import '../../utils/logger.dart';

class SyncManager {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncQueueService _syncQueue = SyncQueueService();

  /// Performs a full bi-directional sync for all core collections.
  Future<void> performFullSync(String businessId) async {
    Logger.info('SyncManager: Starting full sync for business: $businessId', name: 'SyncManager');
    
    // 1. Push local changes to remote
    await _syncQueue.processQueue();

    // 2. Pull remote changes to local for each collection
    final collections = ['products', 'locations', 'resources', 'budgets', 'optimization_results'];
    
    for (var collection in collections) {
      await _syncCollection(collection, businessId);
    }

    Logger.info('SyncManager: Full sync completed.', name: 'SyncManager');
  }

  /// Syncs a specific collection from remote to local.
  Future<void> _syncCollection(String collection, String businessId) async {
    try {
      // Find the latest updated_at in local DB as a baseline
      final localItems = await _dbService.queryAll(collection);
      DateTime lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      
      for (var item in localItems) {
        if (item['updated_at'] != null) {
          final dt = DateTime.parse(item['updated_at']);
          if (dt.isAfter(lastUpdate)) lastUpdate = dt;
        }
      }

      // Fetch from Firestore anything newer than lastUpdate
      final snapshot = await _firestore
          .collection(collection)
          .where('business_id', isEqualTo: businessId)
          .where('updated_at', isGreaterThan: Timestamp.fromDate(lastUpdate))
          .get();

      for (var doc in snapshot.docs) {
        final remoteData = doc.data();
        final String docIdField = _getDocIdField(collection);
        final String docId = remoteData[docIdField];

        // Check for local conflicts
        final existingLocal = localItems.where((l) => l[docIdField] == docId).toList();
        
        if (existingLocal.isNotEmpty) {
          final resolvedData = ConflictResolver.resolve(existingLocal.first, remoteData);
          await _dbService.insert(collection, resolvedData);
          
          // If local was newer, we should push it back to remote in next cycle
          if (resolvedData == existingLocal.first) {
             await _syncQueue.addToQueue(operationType: 'UPDATE', collection: collection, data: resolvedData);
          }
        } else {
          // New record from remote
          await _dbService.insert(collection, remoteData);
        }
      }
      Logger.info('SyncManager: Synced $collection collection (${snapshot.docs.length} updates)', name: 'SyncManager');
    } catch (e, stack) {
       Logger.error('SyncManager: Error syncing $collection', name: 'SyncManager', error: e, stackTrace: stack);
    }
  }

  String _getDocIdField(String collection) {
    switch (collection) {
      case 'products': return 'product_id';
      case 'locations': return 'location_id';
      case 'resources': return 'resource_id';
      case 'budgets': return 'budget_id';
      case 'optimization_results': return 'result_id';
      default: return 'id';
    }
  }
}
