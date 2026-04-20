import 'dart:convert';
import 'database_service.dart';
import '../../models/optimization_result_model.dart';

class ResultDao {
  final _dbService = DatabaseService();
  final String _tableName = 'optimization_results';

  Future<void> insertResult(OptimizationResultModel result) async {
    final data = result.toMap();
    data['result_data'] = jsonEncode(result.resultData);
    await _dbService.insert(_tableName, data);
  }

  Future<List<OptimizationResultModel>> getAllResults() async {
    final List<Map<String, dynamic>> maps = await _dbService.queryAll(_tableName);
    return maps.map((m) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(m);
      data['result_data'] = jsonDecode(m['result_data']);
      return OptimizationResultModel.fromMap(data);
    }).toList();
  }

  Future<void> deleteResult(String resultId) async {
    await _dbService.delete(_tableName, 'result_id', resultId);
  }

  Future<void> clearAll() async {
    await _dbService.clearTable(_tableName);
  }
}
