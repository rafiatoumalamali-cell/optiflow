import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../services/database/database_service.dart';
import '../utils/logger.dart';

class TransportProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  List<LocationModel> _locations = [];
  bool _isLoading = false;

  List<LocationModel> get locations => _locations;
  List<LocationModel> get supplyPoints => _locations.where((l) => l.type == 'Factory' || l.type == 'Distribution Hub').toList();
  List<LocationModel> get demandPoints => _locations.where((l) => l.type == 'Retail').toList();
  bool get isLoading => _isLoading;

  Future<void> fetchLocations(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final localData = await _dbService.queryAll('locations');
      if (localData.isNotEmpty) {
        _locations = localData.map((m) => LocationModel.fromMap(m)).toList();
        notifyListeners();
      }

      QuerySnapshot snapshot = await _firestore
          .collection('locations')
          .where('business_id', isEqualTo: businessId)
          .get();

      _locations = snapshot.docs.map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

      await _dbService.clearTable('locations');
      for (var location in _locations) {
        await _dbService.insert('locations', location.toMap());
      }
    } catch (e, stack) {
      Logger.error('Error fetching locations', name: 'TransportProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLocation(LocationModel location) async {
    try {
      // Save to Firestore with proper Timestamp format
      final firestoreData = location.toMap();
      await _firestore.collection('locations').doc(location.locationId).set(firestoreData);
      
      // Save to local database with DateTime format (not Timestamp)
      final localData = Map<String, dynamic>.from(firestoreData);
      localData['created_at'] = location.createdAt.toIso8601String();
      localData['updated_at'] = location.updatedAt.toIso8601String();
      await _dbService.insert('locations', localData);
      
      _locations.add(location);
      notifyListeners();
    } catch (e) {
      Logger.error('Error adding location', name: 'TransportProvider', error: e);
      rethrow;
    }
  }
}
