import 'haversine_formula.dart';

class DistanceUtils {
  /// The average speed in km/h for West African transport corridors (e.g., Niamey-Zinder).
  /// This takes into account road conditions and checkpoint delays.
  static const double averageSpeedKmH = 65.0;

  /// The factor to multiply straight-line distance to estimate actual road distance.
  /// Standard practice for regional logistics estimation is 1.4x.
  static const double corridorFactor = 1.4;

  /// Estimates the road distance between two coordinates in kilometers.
  static double estimateRoadDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    final straightLine = HaversineFormula.calculateDistance(lat1, lon1, lat2, lon2);
    return straightLine * corridorFactor;
  }

  /// Estimates travel time in hours based on distance.
  static double estimateTravelTimeHours(double distanceKm) {
    if (distanceKm <= 0) return 0;
    return distanceKm / averageSpeedKmH;
  }

  /// Formats the travel time into a readable string (e.g., "5h 30m").
  static String formatTravelTime(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Formats distance into a readable string (e.g., "1,200 km").
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)} km';
  }
}
