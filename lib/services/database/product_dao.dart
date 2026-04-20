import 'database_service.dart';
import '../../models/product_model.dart';

class ProductDao {
  final _dbService = DatabaseService();
  final String _tableName = 'products';

  Future<void> insertProduct(ProductModel product) async {
    await _dbService.insert(_tableName, product.toMap());
  }

  Future<List<ProductModel>> getAllProducts() async {
    final List<Map<String, dynamic>> maps = await _dbService.queryAll(_tableName);
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<void> deleteProduct(String productId) async {
    await _dbService.delete(_tableName, 'product_id', productId);
  }

  Future<void> clearAll() async {
    await _dbService.clearTable(_tableName);
  }
}
