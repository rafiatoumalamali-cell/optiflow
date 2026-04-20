import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database/database_service.dart';
import '../../utils/logger.dart';

class SyncQueueService {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds an operation to the local sync queue.
  Future<void> addToQueue({
    required String operationType,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Use a custom encoder to handle Timestamp objects
      final String jsonData = jsonEncode(data, toEncodable: (item) {
        if (item is Timestamp) {
          return item.toDate().toIso8601String();
        }
        return item;
      });

      await _dbService.insert('sync_queue', {
        'operation_type': operationType,
        'collection': collection,
        'data': jsonData,
        'timestamp': DateTime.now().toIso8601String(),
      });
      Logger.info('Sync: Added $operationType to queue for $collection', name: 'SyncQueueService');
    } on Exception catch (e, stack) {
      Logger.error('Sync: Failed to add to queue', name: 'SyncQueueService', error: e, stackTrace: stack);
    }
  }

  /// Processes all pending items in the sync queue.
  Future<void> processQueue() async {
    try {
      final List<Map<String, dynamic>> queueItems = await _dbService.queryAll('sync_queue');
      
      if (queueItems.isEmpty) {
        Logger.info('Sync: Queue is empty', name: 'SyncQueueService');
        return;
      }

      Logger.info('Sync: Processing ${queueItems.length} items...', name: 'SyncQueueService');

      for (var item in queueItems) {
        final int id = item['id'];
        final String operationType = item['operation_type'];
        final String collection = item['collection'];
        final Map<String, dynamic> data = jsonDecode(item['data']);

        try {
          final String docIdField = _getDocIdField(collection);
          final String docId = data[docIdField];

          if (operationType == 'INSERT' || operationType == 'UPDATE') {
            await _firestore.collection(collection).doc(docId).set(data, SetOptions(merge: true));
          } else if (operationType == 'DELETE') {
            await _firestore.collection(collection).doc(docId).delete();
          }

          // On success, remove from local queue
          await _dbService.delete('sync_queue', 'id', id.toString());
          Logger.info('Sync: Completed $operationType for $collection ($id)', name: 'SyncQueueService');
        } on FirebaseException catch (e, stack) {
          Logger.error('Sync: Firestore error processing item $id', name: 'SyncQueueService', error: e, stackTrace: stack);
        } on Exception catch (e, stack) {
          Logger.error('Sync: Failed to process item $id', name: 'SyncQueueService', error: e, stackTrace: stack);
        }
      }
    } on FirebaseException catch (e, stack) {
      Logger.error('Sync: Firestore error during processQueue', name: 'SyncQueueService', error: e, stackTrace: stack);
    } on Exception catch (e, stack) {
      Logger.error('Sync: Error during processQueue', name: 'SyncQueueService', error: e, stackTrace: stack);
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
