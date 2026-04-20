import 'api_config.dart';

class Endpoints {
  // OPTIFLOW Backend Base URL
  static const String baseUrl = ApiConfig.baseUrl;

  // GOOGLE MAPS API STRINGS
  static String get mapsApiKey => ApiConfig.mapsApiKey;
  static String get directionsUrl => ApiConfig.directionsUrl;
  static String get distanceMatrixUrl => ApiConfig.distanceMatrixUrl;

  // LOGISTICS ENDPOINTS
  static const String productMix = '/optimize/product-mix';
  static const String transport = '/optimize/transport';
  static const String route = '/optimize/route';
  static const String budget = '/optimize/budget';
}
