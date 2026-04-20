import 'package:geolocator/geolocator.dart';
import '../../utils/logger.dart';

class GeolocationService {
  /// Checks permissions and returns the current position.
  /// If permissions are denied, it will throw an exception.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e, stack) {
      Logger.error('GeolocationService: Error getting location', name: 'GeolocationService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Returns a stream of position updates.
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update location every 10 meters
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculates the distance between two points in meters using Geolocator's utility.
  double calculateDistance(double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }
}
