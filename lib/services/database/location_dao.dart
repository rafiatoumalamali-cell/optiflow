import 'database_service.dart';
import '../../models/location_model.dart';

class LocationDao {
  final _dbService = DatabaseService();
  final String _tableName = 'locations';

  Future<void> insertLocation(LocationModel location) async {
    await _dbService.insert(_tableName, location.toMap());
  }

  Future<List<LocationModel>> getAllLocations() async {
    final List<Map<String, dynamic>> maps = await _dbService.queryAll(_tableName);
    return maps.map((m) => LocationModel.fromMap(m)).toList();
  }

  Future<void> deleteLocation(String locationId) async {
    await _dbService.delete(_tableName, 'location_id', locationId);
  }

  Future<void> clearAll() async {
    await _dbService.clearTable(_tableName);
  }
}
