import 'dart:convert';
import 'api_client.dart';
import 'api_config.dart';

class OptimizationApi {
  static const String baseUrl = '${ApiConfig.baseUrl}/optimize';

  Future<Map<String, dynamic>> optimizeProductMix(Map<String, dynamic> data) async {
    return await _post('/product-mix', data);
  }

  Future<Map<String, dynamic>> optimizeTransport(Map<String, dynamic> data) async {
    return await _post('/transport', data);
  }

  Future<Map<String, dynamic>> optimizeRoute(Map<String, dynamic> data) async {
    return await _post('/route', data);
  }

  Future<Map<String, dynamic>> optimizeBudget(Map<String, dynamic> data) async {
    return await _post('/budget', data);
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Optimization failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
