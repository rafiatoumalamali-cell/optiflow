import 'dart:math';

/// A utility class for calculating distances on a sphere using the Haversine formula.
/// This is essential for offline logistics distance estimation in OptiFlow.
class HaversineFormula {
  /// The radius of the Earth in kilometers.
  static const double earthRadiusKm = 6371.0;

  /// Calculates the "as-the-crow-flies" distance between two GPS coordinates.
  /// Returns the distance in kilometers.
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
