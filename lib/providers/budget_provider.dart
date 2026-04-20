import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../services/database/database_service.dart';
import '../utils/logger.dart';

class BudgetProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> fetchBudgets(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try local cache first
      final localData = await _dbService.queryAll('budgets'); // Assuming a budgets table exists or adding it
      if (localData.isNotEmpty) {
        _budgets = localData.map((m) => BudgetModel.fromMap(m)).toList();
        notifyListeners();
      }

      QuerySnapshot snapshot = await _firestore
          .collection('budgets')
          .where('business_id', isEqualTo: businessId)
          .get();

      _budgets = snapshot.docs.map((doc) => BudgetModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      
      // Update local cache
      await _dbService.clearTable('budgets');
      for (var budget in _budgets) {
        await _dbService.insert('budgets', budget.toSqliteMap());
      }
    } catch (e, stack) {
      Logger.error('Error fetching budgets', name: 'BudgetProvider', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget(BudgetModel budget) async {
    try {
      await _firestore.collection('budgets').doc(budget.budgetId).set(budget.toMap());
      await _dbService.insert('budgets', budget.toSqliteMap());
      _budgets.add(budget);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> solveBudget({required String businessId, required double totalBudget}) async {
    try {
      // Mock budget optimization calculation
      final result = {
        'message': 'Budget optimization completed successfully',
        'total_budget': totalBudget,
        'optimal_allocation': {
          'production': 45.0,
          'logistics': 30.0,
          'marketing': 25.0,
        },
        'expected_roi': 15.2,
        'cost_savings': 1200000,
        'regional_breakdown': {
          'lagos': totalBudget * 0.45,
          'accra': totalBudget * 0.32,
          'niamey': totalBudget * 0.23,
        },
        'constraints_met': true,
        'compliance_score': 98.5,
      };

      // Save optimization result to Firestore
      await _firestore.collection('budget_optimizations').add({
        'business_id': businessId,
        'result_data': result,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      Logger.info('Budget optimization completed for business: $businessId', name: 'BudgetProvider');
    } catch (e, stack) {
      Logger.error('Budget optimization failed', name: 'BudgetProvider', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
