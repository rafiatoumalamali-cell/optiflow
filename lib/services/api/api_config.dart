import '../../utils/environment.dart';
import '../../utils/constants.dart';

abstract class ApiConfig {
  /// The base URL for the OptiFlow backend.
  ///
  /// Set via Dart defines in build/run commands:
  /// `--dart-define=API_BASE_URL=https://api.optiflow.com/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.optiflow.com/api',
  );

  /// HTTP timeouts for API requests.
  static const Duration timeout = apiTimeout;
  /// Google Maps API key from environment or build config.
  static String get mapsApiKey => Environment.googleMapsApiKey;

  /// Google Maps endpoints.
  static const String directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String distanceMatrixUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  static const String placesUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String placeDetailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
}
