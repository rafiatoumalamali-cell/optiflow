import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transport_optimization_model.dart';
import '../models/transport_problem_model.dart' as prob;
import '../utils/logger.dart';

class TransportCostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;
  List<prob.TransportProblem> _transportProblems = [];
  prob.TransportProblem? _currentProblem;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<prob.TransportProblem> get transportProblems => _transportProblems;
  prob.TransportProblem? get currentProblem => _currentProblem;

  Future<prob.TransportOptimizationResult> optimizeTransportCost({
    required List<SupplyPoint> supplyPoints,
    required List<DemandPoint> demandPoints,
    required List<List<double>> costMatrix,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      if (supplyPoints.isEmpty || demandPoints.isEmpty) {
        throw Exception('Supply and demand points cannot be empty');
      }

      if (costMatrix.length != supplyPoints.length) {
        throw Exception('Cost matrix rows must match supply points count');
      }

      for (int i = 0; i < costMatrix.length; i++) {
        if (costMatrix[i].length != demandPoints.length) {
          throw Exception('Cost matrix columns must match demand points count');
        }
      }

      // Calculate total supply and demand
      final totalSupply = supplyPoints.fold<int>(0, (sum, point) => sum + point.availableQuantity);
      final totalDemand = demandPoints.fold<int>(0, (sum, point) => sum + point.requiredQuantity);

      // Balance the model by adding dummy source/destination if needed
      final balancedData = _balanceTransportationModel(supplyPoints, demandPoints, costMatrix, totalSupply, totalDemand);

      // Implement the transportation algorithm (using North-West Corner method)
      final result = _solveTransportationProblem(
        balancedData['supplyPoints'] as List<SupplyPoint>,
        balancedData['demandPoints'] as List<DemandPoint>,
        balancedData['costMatrix'] as List<List<double>>,
        totalSupply != totalDemand, // isBalanced flag
      );

      // Save result to Firestore
      await _saveOptimizationResult(result);

      return result;
    } catch (e) {
      _error = e.toString();
      Logger.error('Transport cost optimization failed', name: 'TransportCostProvider', error: e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _balanceTransportationModel(
    List<SupplyPoint> supplyPoints,
    List<DemandPoint> demandPoints,
    List<List<double>> costMatrix,
    int totalSupply,
    int totalDemand,
  ) {
    final balancedSupplyPoints = List<SupplyPoint>.from(supplyPoints);
    final balancedDemandPoints = List<DemandPoint>.from(demandPoints);
    final balancedCostMatrix = List<List<double>>.from(costMatrix);

    if (totalSupply > totalDemand) {
      // Add dummy destination to absorb excess supply
      final excessSupply = totalSupply - totalDemand;
      balancedDemandPoints.add(DemandPoint(
        id: 'dummy_demand',
        name: 'Excess',
        location: 'Storage',
        requiredQuantity: excessSupply,
      ));

      // Add zero costs to dummy destination
      for (int i = 0; i < balancedCostMatrix.length; i++) {
        balancedCostMatrix[i].add(0.0);
      }
    } else {
      // Add dummy supply point to meet excess demand
      final excessDemand = totalDemand - totalSupply;
      balancedSupplyPoints.add(SupplyPoint(
        id: 'dummy_supply',
        name: 'Dummy Source',
        location: 'Shortage',
        availableQuantity: excessDemand,
      ));

      // Add zero costs from dummy source
      final dummyRow = List<double>.filled(balancedCostMatrix[0].length, 0.0);
      balancedCostMatrix.add(dummyRow);
    }

    return {
      'supplyPoints': balancedSupplyPoints,
      'demandPoints': balancedDemandPoints,
      'costMatrix': balancedCostMatrix,
    };
  }

  prob.TransportOptimizationResult _solveTransportationProblem(
    List<SupplyPoint> supplyPoints,
    List<DemandPoint> demandPoints,
    List<List<double>> costMatrix,
    bool wasBalanced,
  ) {
    // Create mutable copies
    final supply = supplyPoints.map((sp) => sp.availableQuantity).toList();
    final demand = demandPoints.map((dp) => dp.requiredQuantity).toList();
    final shipments = <prob.ShipmentData>[];
    double totalCost = 0.0;

    // Calculate totals for return statement
    final totalSupply = supply.fold<int>(0, (sum, val) => sum + val);
    final totalDemand = demand.fold<int>(0, (sum, val) => sum + val);

    // Use North-West Corner method for all problems (no hardcoded examples)
    int i = 0; // supply index
    int j = 0; // demand index

    while (i < supply.length && j < demand.length) {
      final availableSupply = supply[i];
      final requiredDemand = demand[j];
      final cost = costMatrix[i][j];

      final shipmentQuantity = availableSupply < requiredDemand ? availableSupply : requiredDemand;
      
      // Create shipment record
      shipments.add(prob.ShipmentData(
        fromPoint: supplyPoints[i].name,
        toPoint: demandPoints[j].name,
        quantity: shipmentQuantity,
        costPerUnit: cost,
        totalCost: shipmentQuantity * cost,
      ));

      totalCost += shipmentQuantity * cost;

      // Update remaining supply and demand
      supply[i] -= shipmentQuantity;
      demand[j] -= shipmentQuantity;

      // Move to next row or column
      if (supply[i] == 0) i++;
      if (demand[j] == 0) j++;
    }

    // Filter out dummy shipments from results
    final filteredShipments = shipments.where((shipment) => 
      !shipment.fromPoint.contains('Dummy') && 
      !shipment.toPoint.contains('Dummy')
    ).toList();

    // Calculate potential manual cost (worst case scenario) - only for real points
    double manualCost = 0;
    final realSupplyCount = wasBalanced ? supplyPoints.length - 1 : supplyPoints.length;
    final realDemandCount = wasBalanced ? demandPoints.length - 1 : demandPoints.length;
    
    for (int i = 0; i < realSupplyCount; i++) {
      for (int j = 0; j < realDemandCount; j++) {
        // Find maximum cost for each route (inefficient manual planning)
        final maxCost = costMatrix[i][j];
        manualCost += supplyPoints[i].availableQuantity * maxCost;
      }
    }

    // Calculate savings
    final savings = manualCost - totalCost;
    final savingsPercentage = manualCost > 0 ? savings / manualCost : 0.0;

    return prob.TransportOptimizationResult(
      totalCost: totalCost,
      shipments: filteredShipments,
      savings: savings,
      savingsPercentage: savingsPercentage,
      timestamp: DateTime.now(),
      wasBalanced: wasBalanced,
      excessSupply: totalSupply > totalDemand ? totalSupply - totalDemand : null,
      excessDemand: totalDemand > totalSupply ? totalDemand - totalSupply : null,
    );
  }

  Future<void> _saveOptimizationResult(prob.TransportOptimizationResult result) async {
    try {
      await _firestore.collection('transport_optimizations').add({
        'total_cost': result.totalCost,
        'savings': result.savings,
        'savings_percentage': result.savingsPercentage,
        'shipments': result.shipments.map((s) => s.toMap()).toList(),
        'timestamp': Timestamp.fromDate(result.timestamp),
        'created_at': Timestamp.now(),
      });
    } catch (e) {
      Logger.error('Failed to save optimization result', name: 'TransportCostProvider', error: e);
      // Don't rethrow - saving failure shouldn't break optimization
    }
  }

  // CRUD Operations for Transport Problems

  Future<void> fetchTransportProblems(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('transport_problems')
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();

      _transportProblems = snapshot.docs.map((doc) {
        return prob.TransportProblem.fromMap(doc.data(), doc.id);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Failed to fetch transport problems', name: 'TransportCostProvider', error: e);
    }
  }

  Future<String> createTransportProblem({
    required String businessId,
    required String name,
    required String description,
    required List<prob.SupplyPointData> supplyPoints,
    required List<prob.DemandPointData> demandPoints,
    required List<List<double>> costMatrix,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final transportProblem = prob.TransportProblem(
        name: name,
        description: description,
        businessId: businessId,
        supplyPoints: supplyPoints,
        demandPoints: demandPoints,
        costMatrix: costMatrix,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('transport_problems')
          .add(transportProblem.toMap());

      _currentProblem = transportProblem.copyWith(id: docRef.id);
      _transportProblems.insert(0, _currentProblem!);
      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Failed to create transport problem', name: 'TransportCostProvider', error: e);
      rethrow;
    }
  }

  Future<void> updateTransportProblem({
    required String problemId,
    required String name,
    required String description,
    required List<prob.SupplyPointData> supplyPoints,
    required List<prob.DemandPointData> demandPoints,
    required List<List<double>> costMatrix,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existingProblem = _transportProblems.firstWhere((p) => p.id == problemId);

      await _firestore
          .collection('transport_problems')
          .doc(problemId)
          .update({
            'name': name,
            'description': description,
            'supply_points': supplyPoints.map((sp) => sp.toMap()).toList(),
            'demand_points': demandPoints.map((dp) => dp.toMap()).toList(),
            'cost_matrix': costMatrix,
            'updated_at': Timestamp.now(),
          });

      final updatedProblem = existingProblem.copyWith(
        name: name,
        description: description,
        supplyPoints: supplyPoints,
        demandPoints: demandPoints,
        costMatrix: costMatrix,
        updatedAt: DateTime.now(),
      );

      final index = _transportProblems.indexWhere((p) => p.id == problemId);
      _transportProblems[index] = updatedProblem;

      if (_currentProblem?.id == problemId) {
        _currentProblem = updatedProblem;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Failed to update transport problem', name: 'TransportCostProvider', error: e);
      rethrow;
    }
  }

  Future<void> deleteTransportProblem(String problemId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('transport_problems')
          .doc(problemId)
          .update({'isActive': false, 'updated_at': Timestamp.now()});

      _transportProblems.removeWhere((p) => p.id == problemId);

      if (_currentProblem?.id == problemId) {
        _currentProblem = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      Logger.error('Failed to delete transport problem', name: 'TransportCostProvider', error: e);
      rethrow;
    }
  }

  void setCurrentProblem(prob.TransportProblem? problem) {
    _currentProblem = problem;
    notifyListeners();
  }

  prob.TransportProblem? getProblemById(String problemId) {
    try {
      return _transportProblems.firstWhere((p) => p.id == problemId);
    } catch (e) {
      return null;
    }
  }

  Future<void> optimizeCurrentProblem() async {
    if (_currentProblem == null) {
      _error = 'No transport problem selected';
      notifyListeners();
      return;
    }

    try {
      final supplyPoints = _currentProblem!.supplyPoints.map((sp) => SupplyPoint(
        id: sp.id,
        name: sp.name,
        location: sp.location,
        availableQuantity: sp.availableQuantity,
      )).toList();

      final demandPoints = _currentProblem!.demandPoints.map((dp) => DemandPoint(
        id: dp.id,
        name: dp.name,
        location: dp.location,
        requiredQuantity: dp.requiredQuantity,
      )).toList();

      final result = await optimizeTransportCost(
        supplyPoints: supplyPoints,
        demandPoints: demandPoints,
        costMatrix: _currentProblem!.costMatrix,
      );

      final updatedProblem = _currentProblem!.copyWith(
        lastResult: result,
        updatedAt: DateTime.now(),
      );

      final index = _transportProblems.indexWhere((p) => p.id == _currentProblem!.id);
      _transportProblems[index] = updatedProblem;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      Logger.error('Failed to optimize current problem', name: 'TransportCostProvider', error: e);
    }
  }

  Future<List<Map<String, dynamic>>> getOptimizationHistory(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('transport_optimizations')
          .where('business_id', isEqualTo: businessId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      Logger.error('Failed to fetch optimization history', name: 'TransportCostProvider', error: e);
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
