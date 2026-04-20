import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';
import '../utils/logger.dart';

class BusinessProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BusinessModel? _currentBusiness;
  SubscriptionModel? _activeSubscription;
  bool _isLoading = false;

  BusinessModel? get currentBusiness => _currentBusiness;
  SubscriptionModel? get activeSubscription => _activeSubscription;
  bool get isLoading => _isLoading;
  List<BusinessModel> get businesses => _currentBusiness != null ? [_currentBusiness!] : [];
  String get userId => _currentBusiness?.businessId ?? '';

  /// Fetches the business and its active subscription from Firestore.
  Future<void> fetchBusinessDetails(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Business Profile
      final bizDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (bizDoc.exists) {
        _currentBusiness = BusinessModel.fromMap(bizDoc.data()!);
      }

      // 2. Fetch Active Subscription
      final subQuery = await _firestore
          .collection('subscriptions')
          .where('business_id', isEqualTo: businessId)
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get();

      if (subQuery.docs.isNotEmpty) {
        _activeSubscription = SubscriptionModel.fromMap(subQuery.docs.first.data());
      } else {
        _activeSubscription = null;
      }
    } catch (e, stack) {
      Logger.error('BusinessProvider: Failed to fetch details', name: 'BusinessProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if the business currently has an active premium plan.
  bool get isPremium {
    if (_activeSubscription == null) return false;
    return _activeSubscription!.endDate.isAfter(DateTime.now()) && 
           _activeSubscription!.plan != 'Free Trial' && 
           _activeSubscription!.plan != 'Free';
  }

  /// Guards optimization execution, decrements trial count if standard.
  Future<bool> consumeOptimization() async {
    // If unrestricted
    if (isPremium) return true;

    // Check balances
    if (_currentBusiness != null && _currentBusiness!.remainingFreeOptimizations > 0) {
      try {
        final newCount = _currentBusiness!.remainingFreeOptimizations - 1;
        
        // Push decrement to Firebase
        await _firestore.collection('businesses').doc(_currentBusiness!.businessId).update({
          'remaining_free_optimizations': FieldValue.increment(-1),
        });

        // Update local object immediately to prevent flicker
        _currentBusiness = BusinessModel(
          businessId: _currentBusiness!.businessId,
          name: _currentBusiness!.name,
          type: _currentBusiness!.type,
          country: _currentBusiness!.country,
          city: _currentBusiness!.city,
          currency: _currentBusiness!.currency,
          isVerified: _currentBusiness!.isVerified,
          subscriptionPlan: _currentBusiness!.subscriptionPlan,
          createdAt: _currentBusiness!.createdAt,
          drivers: _currentBusiness!.drivers,
          remainingFreeOptimizations: newCount,
        );
        notifyListeners();
        return true;
      } catch (e, stack) {
        Logger.error('BusinessProvider: Failed to decrement optimization count', name: 'BusinessProvider', error: e, stackTrace: stack);
        return false;
      }
    }
    return false; // Out of transactions
  }

  /// Processes a plan upgrade and updates Firestore records.
  Future<void> updateSubscription(SubscriptionModel newSub, TransactionModel transaction) async {
    try {
      final batch = _firestore.batch();
      
      // Update Subscription
      final subRef = _firestore.collection('subscriptions').doc(newSub.subscriptionId);
      batch.set(subRef, newSub.toMap());

      // Log Transaction
      final txnRef = _firestore.collection('transactions').doc(transaction.transactionId);
      batch.set(txnRef, transaction.toMap());

      // Update Business Plan Metadata
      final bizRef = _firestore.collection('businesses').doc(newSub.businessId);
      batch.update(bizRef, {'subscription_plan': newSub.plan});

      await batch.commit();
      _activeSubscription = newSub;
      notifyListeners();
    } catch (e, stack) {
      Logger.error('BusinessProvider: Subscription update failed', name: 'BusinessProvider', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
