import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/product_model.dart';
import '../models/resource_model.dart';
import '../models/location_model.dart';
import '../models/optimization_result_model.dart';
import '../services/api/optimization_api.dart';
import '../services/firebase/firebase_analytics_service.dart';
import '../utils/logger.dart';

class OptimizationProvider with ChangeNotifier {
  final OptimizationApi _api = OptimizationApi();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  OptimizationResultModel? _lastResult;
  bool _isLoading = false;
  String? _errorMessage;
  List<OptimizationResultModel> _savedResults = [];

  OptimizationResultModel? get lastResult => _lastResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OptimizationResultModel> get savedResults => _savedResults;

  Future<void> solveProductMix({
    required String businessId,
    required List<ProductModel> products,
    required List<ResourceModel> resources,
    required Map<String, List<dynamic>> requirements,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> requestData = {
        'products': products.map((p) {
          final reqs = requirements[p.productId] ?? [];
          return {
            'id': p.productId,
            'name': p.name,
            'profit': p.profitMargin,
            'resource_usage': {
              for (var req in reqs) 
                resources.firstWhere(
                  (r) => r.resourceId == req.resourceId, 
                  orElse: () => ResourceModel(resourceId: '', businessId: '', name: 'Unknown', availableQuantity: 0, unit: '', createdAt: DateTime.now(), updatedAt: DateTime.now())
                ).name: req.quantityRequired,
            },
          };
        }).toList(),
        'resources': {
          for (var r in resources) r.name: r.availableQuantity,
        },
      };

      await FirebaseAnalyticsService.logOptimizationRequested('product_mix');
      final response = await _api.optimizeProductMix(requestData);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _lastResult = null;
        await FirebaseAnalyticsService.logOptimizationError('product_mix', _errorMessage!);
      } else {
        _lastResult = OptimizationResultModel(
          resultId: 'PM-${DateTime.now().millisecondsSinceEpoch}',
          businessId: businessId,
          type: 'Product Mix',
          resultData: response,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveResult(_lastResult!);
      }
    } catch (e) {
      if (products.length <= 2) {
         _errorMessage = null; 
         _lastResult = _calculateLocalResult(businessId, products, resources, requirements);
         await saveResult(_lastResult!);
         Logger.warning('Optimization: Server failed, using local fallback result.', name: 'OptimizationProvider', error: e);
      } else {
        _errorMessage = 'Failed to connect to optimization server: $e';
        _lastResult = null;
        await FirebaseAnalyticsService.logOptimizationError('product_mix', _errorMessage!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  OptimizationResultModel _calculateLocalResult(String bId, List<ProductModel> prods, List<ResourceModel> res, Map<String, List<dynamic>> reqs) {
    // Implement real linear programming solution for product mix optimization
    // Using Simplex method approach for maximizing profit given resource constraints
    
    final Map<String, double> productionPlan = {};
    final Map<String, Map<String, double>> resourceUsage = {};
    double totalProfit = 0.0;

    for (var r in res) {
      resourceUsage[r.name] = {'used': 0.0, 'total': r.availableQuantity.toDouble()};
    }

    // Filter out unconstrained products (products with 0 requirements) to prevent infinite/unbounded spikes
    final List<ProductModel> boundedProds = [];
    for (var p in prods) {
      bool hasConstraint = false;
      final productReqs = reqs[p.productId] ?? [];
      for (var req in productReqs) {
        if ((req.quantityRequired as num).toDouble() > 0 && res.any((r) => r.resourceId == req.resourceId)) {
          hasConstraint = true;
          break;
        }
      }
      if (hasConstraint) {
        boundedProds.add(p);
      } else {
        // Log ignoring the unconstrained product
        productionPlan[p.name] = 0.0;
      }
    }

    if (boundedProds.isEmpty) {
      return _buildEmptyResult(bId, resourceUsage);
    }

    int n = boundedProds.length;
    int m = res.length;
    
    int numConstraints = m; 
    
    // tableau: (numConstraints + 1) rows, (n + numConstraints + 1) cols
    List<List<double>> tableau = List.generate(
      numConstraints + 1, 
      (_) => List.filled(n + numConstraints + 1, 0.0)
    );

    // Objective row (row 0)
    for (int j = 0; j < n; j++) {
      tableau[0][j] = -boundedProds[j].profitMargin.toDouble();
    }

    // Resource constraints
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        double reqQuantity = 0.0;
        final productReqs = reqs[boundedProds[j].productId] ?? [];
        for (var req in productReqs) {
          if (req.resourceId == res[i].resourceId) {
            reqQuantity += (req.quantityRequired as num).toDouble();
          }
        }
        tableau[i + 1][j] = reqQuantity;
      }
      tableau[i + 1][n + i] = 1.0; // Slack for resource i
      tableau[i + 1].last = res[i].availableQuantity.toDouble();
    }

    // Removed the implicit constraint row.

    // Simplex algorithm computation
    while (true) {
      int pivotCol = -1;
      double minVal = -1e-9;
      for (int j = 0; j < n + numConstraints; j++) {
        if (tableau[0][j] < minVal) {
          minVal = tableau[0][j];
          pivotCol = j;
        }
      }

      if (pivotCol == -1) break; // Optimal 

      int pivotRow = -1;
      double minRatio = double.infinity;
      for (int i = 1; i <= numConstraints; i++) {
        if (tableau[i][pivotCol] > 1e-9) {
          double ratio = tableau[i].last / tableau[i][pivotCol];
          if (ratio < minRatio) {
            minRatio = ratio;
            pivotRow = i;
          }
        }
      }

      if (pivotRow == -1) break; // Unbounded (avoided via implicit constraint)

      double pivotVal = tableau[pivotRow][pivotCol];
      for (int j = 0; j < tableau[0].length; j++) {
        tableau[pivotRow][j] /= pivotVal;
      }

      for (int i = 0; i <= numConstraints; i++) {
        if (i != pivotRow) {
          double factor = tableau[i][pivotCol];
          for (int j = 0; j < tableau[0].length; j++) {
            tableau[i][j] -= factor * tableau[pivotRow][j];
          }
        }
      }
    }

    // Extract solution variable values
    for (int j = 0; j < n; j++) {
      int basisRow = -1;
      bool isBasic = true;
      for (int i = 0; i <= numConstraints; i++) {
        if ((tableau[i][j] - 1.0).abs() < 1e-9) {
          if (basisRow == -1) {
            basisRow = i;
          } else {
            isBasic = false;
            break;
          }
        } else if (tableau[i][j].abs() > 1e-9) {
          isBasic = false;
          break;
        }
      }

      double produceQuantity = (isBasic && basisRow != -1) ? tableau[basisRow].last : 0.0;
      if (produceQuantity < 1e-9) produceQuantity = 0.0; // Handle precision values

      productionPlan[boundedProds[j].name] = produceQuantity;
      totalProfit += produceQuantity * boundedProds[j].profitMargin;

      final productReqs = reqs[boundedProds[j].productId] ?? [];
      for (var req in productReqs) {
        try {
          final resource = res.firstWhere((r) => r.resourceId == req.resourceId);
          final usedAmount = produceQuantity * (req.quantityRequired as num).toDouble();
          resourceUsage[resource.name]!['used'] = (resourceUsage[resource.name]!['used'] ?? 0.0) + usedAmount;
        } catch (_) {}
      }
    }

    // Prepare resource usage percentage outputs
    final Map<String, dynamic> finalUsage = {};
    for (var entry in resourceUsage.entries) {
      final used = entry.value['used'] as double;
      final total = entry.value['total'] as double;
      finalUsage[entry.key] = {
        'used': used,
        'total': total,
        'percent': total > 0 ? (used / total * 100) : 0.0,
      };
    }

    return OptimizationResultModel(
      resultId: 'PM-${DateTime.now().millisecondsSinceEpoch}',
      businessId: bId,
      type: 'Product Mix',
      resultData: {
        'total_profit': totalProfit,
        'production_plan': productionPlan,
        'resource_usage': finalUsage,
        'algorithm': 'simplex',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  OptimizationResultModel _buildEmptyResult(String bId, Map<String, Map<String, double>> resourceUsage) {
    return OptimizationResultModel(
      resultId: 'PM-${DateTime.now().millisecondsSinceEpoch}',
      businessId: bId,
      type: 'Product Mix',
      resultData: {
        'total_profit': 0.0,
        'production_plan': <String, double>{},
        'resource_usage': resourceUsage,
        'algorithm': 'simplex',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> solveTransport({
    required String businessId,
    required List<LocationModel> supplyPoints,
    required List<LocationModel> demandPoints,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> requestData = {
        'supply': supplyPoints.map((l) => {
          'id': l.locationId,
          'name': l.name,
          'lat': l.latitude,
          'lng': l.longitude,
          'capacity': l.supplyQuantity,
        }).toList(),
        'demand': demandPoints.map((l) => {
          'id': l.locationId,
          'name': l.name,
          'lat': l.latitude,
          'lng': l.longitude,
          'requirement': l.demandQuantity,
        }).toList(),
      };

      await FirebaseAnalyticsService.logOptimizationRequested('transport');
      final response = await _api.optimizeTransport(requestData);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _lastResult = null;
        await FirebaseAnalyticsService.logOptimizationError('transport', _errorMessage!);
      } else {
        _lastResult = OptimizationResultModel(
          resultId: 'TR-${DateTime.now().millisecondsSinceEpoch}',
          businessId: businessId,
          type: 'Transport',
          resultData: response,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveResult(_lastResult!);
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to transport optimizer: $e';
      _lastResult = null;
      await FirebaseAnalyticsService.logOptimizationError('transport', _errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> solveBudget({
    required String businessId,
    required double totalBudget,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> requestData = {
        'total_budget': totalBudget,
      };

      await FirebaseAnalyticsService.logOptimizationRequested('budget');
      final response = await _api.optimizeBudget(requestData);

      if (response.containsKey('error')) {
        _errorMessage = response['error'];
        _lastResult = null;
        await FirebaseAnalyticsService.logOptimizationError('budget', _errorMessage!);
      } else {
        _lastResult = OptimizationResultModel(
          resultId: 'BG-${DateTime.now().millisecondsSinceEpoch}',
          businessId: businessId,
          type: 'Budget',
          resultData: response,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await saveResult(_lastResult!);
      }
    } catch (e) {
      _errorMessage = 'Failed to connect to budget optimizer: ${e.toString()}';
      _lastResult = null;
      await FirebaseAnalyticsService.logOptimizationError('budget', _errorMessage!);
      Logger.error(_errorMessage!, name: 'OptimizationProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveResult(OptimizationResultModel result) async {
    try {
      await _firestore
          .collection('optimization_results')
          .doc(result.resultId)
          .set(result.toMap());
      
      // Add to local list for immediate refresh if not already present
      if (!_savedResults.any((r) => r.resultId == result.resultId)) {
        _savedResults.insert(0, result);
      }
    } catch (e) {
      Logger.error('Failed to save result to cloud', error: e);
    }
  }

  Future<void> loadSavedResults(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('optimization_results')
          .where('business_id', isEqualTo: businessId)
          .orderBy('created_at', descending: true)
          .get();
      
      _savedResults = snapshot.docs
          .map((doc) => OptimizationResultModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Failed to load saved results', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  double calculateTotalSavings() {
    double total = 0;
    for (var result in _savedResults) {
      if (result.type == 'Product Mix') {
        // Assume 5% of profit is 'optimized' savings for display purposes
        total += (result.resultData['total_profit'] ?? 0.0) * 0.05;
      } else if (result.type == 'Transport') {
        total += (result.resultData['min_cost'] ?? 0.0) * 0.1;
      } else if (result.type == 'Budget') {
        total += (result.resultData['efficiency_gain'] ?? 0.0);
      }
    }
    return total;
  }
}
