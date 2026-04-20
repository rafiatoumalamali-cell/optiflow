import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/resource_model.dart';
import '../models/product_resource_model.dart';
import '../services/database/database_service.dart';
import '../services/sync/sync_queue_service.dart';
import '../utils/logger.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  List<ProductModel> _products = [];
  List<ResourceModel> _resources = [];
  Map<String, List<ProductResourceRequirement>> _productRequirements = {}; // productId -> requirements
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  List<ResourceModel> get resources => _resources;
  Map<String, List<ProductResourceRequirement>> get productRequirements => _productRequirements;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Initial Load from Local DB
      final localData = await _dbService.queryAll('products');
      _products = localData.map((m) => ProductModel.fromMap(m)).toList();
      notifyListeners();

      // 2. Fetch Cloud Data
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('business_id', isEqualTo: businessId)
          .get();

      // 3. Update Local DB with Cloud Data (Merging, not clearing)
      final pendingDeletes = await _dbService.queryAll('sync_queue');
      final deletedIds = pendingDeletes.where((q) => q['operation_type'] == 'DELETE').map((q) {
         try {
           final dataMap = q['data'] is String ? (jsonDecode(q['data']) ?? {}) : q['data'];
           return dataMap['product_id']?.toString() ?? '';
         } catch(_) { return ''; }
      }).toList();

      for (var doc in snapshot.docs) {
        final cloudProd = ProductModel.fromMap(doc.data() as Map<String, dynamic>);
        if (!deletedIds.contains(cloudProd.productId)) {
           await _dbService.insert('products', cloudProd.toSqliteMap());
        }
      }

      // 4. Final Refresh from Local DB
      final refreshedData = await _dbService.queryAll('products');
      _products = refreshedData.map((m) => ProductModel.fromMap(m)).toList();
    } catch (e, stack) {
      Logger.error('Error fetching products', name: 'ProductProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(ProductModel product) async {
    final syncService = SyncQueueService();
    try {
      // 1. Save locally first (Source of Truth for the UI)
      await _dbService.insert('products', product.toSqliteMap());
      
      // 2. Add to sync queue for cloud persistence
      await syncService.addToQueue(
        operationType: 'INSERT',
        collection: 'products',
        data: product.toMap(),
      );

      // 3. Update local state
      _products.add(product);
      notifyListeners();

      // 4. Attempt immediate sync (non-blocking)
      syncService.processQueue().catchError((e, stack) => Logger.warning('Sync: Immediate sync failed', name: 'ProductProvider', error: e, stackTrace: stack));
    } catch (e, stack) {
      Logger.error('Error adding product', name: 'ProductProvider', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> fetchResources(String businessId) async {
    try {
      // 1. Initial Load
      final localRes = await _dbService.queryAll('resources');
      _resources = localRes.map((m) => ResourceModel.fromMap(m)).toList();
      notifyListeners();

      // 2. Sync Cloud
      QuerySnapshot snapshot = await _firestore
          .collection('resources')
          .where('business_id', isEqualTo: businessId)
          .get();

      // 3. Update Local
      final pendingDeletes = await _dbService.queryAll('sync_queue');
      final deletedIds = pendingDeletes.where((q) => q['operation_type'] == 'DELETE').map((q) {
         try {
           final dataMap = q['data'] is String ? (jsonDecode(q['data']) ?? {}) : q['data'];
           return dataMap['resource_id']?.toString() ?? '';
         } catch(_) { return ''; }
      }).toList();

      for (var doc in snapshot.docs) {
        final cloudRes = ResourceModel.fromMap(doc.data() as Map<String, dynamic>);
        if (!deletedIds.contains(cloudRes.resourceId)) {
          await _dbService.insert('resources', cloudRes.toSqliteMap());
        }
      }

      // 4. Final Load
      final refreshedRes = await _dbService.queryAll('resources');
      _resources = refreshedRes.map((m) => ResourceModel.fromMap(m)).toList();
    } catch (e, stack) {
      Logger.error('Error fetching resources', name: 'ProductProvider', error: e, stackTrace: stack);
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchProductRequirements(String productId) async {
    try {
      // 1. Initial Load from Local DB
      final db = await _dbService.database;
      final localReqs = await db.query(
        'product_resources',
        where: 'product_id = ?',
        whereArgs: [productId]
      );
      
      _productRequirements[productId] = localReqs.map((m) => ProductResourceRequirement.fromMap(m)).toList();
      notifyListeners();

      // 2. Fetch Cloud Data 
      QuerySnapshot snapshot = await _firestore
          .collection('product_resources')
          .where('product_id', isEqualTo: productId)
          .get();

      // 3. Update Local DB if cloud has data
      for (var doc in snapshot.docs) {
        final cloudReq = ProductResourceRequirement.fromMap(doc.data() as Map<String, dynamic>);
        await _dbService.insert('product_resources', cloudReq.toMap());
      }
      
      // 4. Final Refresh from Local DB
      final refreshedReqs = await db.query(
        'product_resources',
        where: 'product_id = ?',
        whereArgs: [productId]
      );
      
      _productRequirements[productId] = refreshedReqs.map((m) => ProductResourceRequirement.fromMap(m)).toList();
      notifyListeners();
    } catch (e, stack) {
      Logger.error('Error fetching requirements', name: 'ProductProvider', error: e, stackTrace: stack);
    }
  }

  Future<void> addResource(ResourceModel resource) async {
    final syncService = SyncQueueService();
    try {
      // 1. Save locally
      await _dbService.insert('resources', resource.toSqliteMap());
      
      // 2. Queue for sync
      await syncService.addToQueue(
        operationType: 'INSERT',
        collection: 'resources',
        data: resource.toMap(),
      );

      // 3. Update state
      _resources.add(resource);
      notifyListeners();
      
      // 4. Non-blocking sync
      syncService.processQueue().catchError((e) => Logger.warning('Sync: Resource sync failed'));
    } catch (e, stack) {
      Logger.error('Error adding resource', name: 'ProductProvider', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    final syncService = SyncQueueService();
    try {
      await _dbService.insert('products', product.toSqliteMap());
      await syncService.addToQueue(operationType: 'UPDATE', collection: 'products', data: product.toMap());
      final index = _products.indexWhere((p) => p.productId == product.productId);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      syncService.processQueue().catchError((e) => Logger.warning('Update Product Sync Failed'));
    } catch (e) {
      Logger.error('Error updating product', error: e);
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final syncService = SyncQueueService();
    try {
      await _dbService.delete('products', 'product_id', productId);
      await _dbService.delete('product_resources', 'product_id', productId);
      await syncService.addToQueue(operationType: 'DELETE', collection: 'products', data: {'product_id': productId});
      _products.removeWhere((p) => p.productId == productId);
      _productRequirements.remove(productId);
      notifyListeners();
      syncService.processQueue().catchError((e) => Logger.warning('Delete Product Sync Failed'));
    } catch (e) {
      Logger.error('Error deleting product', error: e);
      rethrow;
    }
  }

  Future<void> deleteProductRequirements(String productId) async {
    try {
      await _dbService.delete('product_resources', 'product_id', productId);
      // Local clean for the current memory
      _productRequirements[productId] = [];
      notifyListeners();
    } catch (e) {
      Logger.error('Error deleting requirements', error: e);
    }
  }

  Future<void> updateResource(ResourceModel resource) async {
    final syncService = SyncQueueService();
    try {
      await _dbService.insert('resources', resource.toSqliteMap());
      await syncService.addToQueue(operationType: 'UPDATE', collection: 'resources', data: resource.toMap());
      final index = _resources.indexWhere((r) => r.resourceId == resource.resourceId);
      if (index != -1) {
        _resources[index] = resource;
        notifyListeners();
      }
      syncService.processQueue().catchError((e) => Logger.warning('Update Resource Sync Failed'));
    } catch (e) {
      Logger.error('Error updating resource', error: e);
      rethrow;
    }
  }

  Future<void> deleteResource(String resourceId) async {
    final syncService = SyncQueueService();
    try {
      await _dbService.delete('resources', 'resource_id', resourceId);
      await syncService.addToQueue(operationType: 'DELETE', collection: 'resources', data: {'resource_id': resourceId});
      _resources.removeWhere((r) => r.resourceId == resourceId);
      notifyListeners();
      syncService.processQueue().catchError((e) => Logger.warning('Delete Resource Sync Failed'));
    } catch (e) {
      Logger.error('Error deleting resource', error: e);
      rethrow;
    }
  }

  Future<void> saveProductRequirement(ProductResourceRequirement requirement) async {
    final syncService = SyncQueueService();
    try {
      // 1. Save locally
      await _dbService.insert('product_resources', requirement.toMap());
      
      // 2. Queue for sync
      await syncService.addToQueue(
        operationType: 'INSERT',
        collection: 'product_resources',
        data: requirement.toMap(),
      );

      // 3. Update state
      if (_productRequirements.containsKey(requirement.productId)) {
        _productRequirements[requirement.productId]!.add(requirement);
      } else {
        _productRequirements[requirement.productId] = [requirement];
      }
      notifyListeners();
      
      // 4. Non-blocking sync
      syncService.processQueue().catchError((e) => Logger.warning('Sync: Req sync failed'));
    } catch (e, stack) {
      Logger.error('Error saving requirement', name: 'ProductProvider', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> clearAllBusinessData(String businessId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Clear local memory states instantly
      _products.clear();
      _resources.clear();
      _productRequirements.clear();
      
      // 2. Unconditionally wipe local SQLite cache so UI reflects a clean slate immediately
      await _dbService.clearTable('products');
      await _dbService.clearTable('resources');
      await _dbService.clearTable('product_resources');
      await _dbService.clearTable('sync_queue');
      
      notifyListeners();

      // 3. Gracefully attempt to wipe Cloud states (Will fail gracefully if offline)
      try {
        final productSnaps = await _firestore.collection('products').where('business_id', isEqualTo: businessId).get();
        for (var doc in productSnaps.docs) await doc.reference.delete();
        
        final resourceSnaps = await _firestore.collection('resources').where('business_id', isEqualTo: businessId).get();
        for (var doc in resourceSnaps.docs) await doc.reference.delete();
      } catch (cloudError) {
        Logger.warning('Cloud clear failed (Offline?), but local wiped.');
      }

    } catch (e, stack) {
      Logger.error('Error clearing local data', name: 'ProductProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
