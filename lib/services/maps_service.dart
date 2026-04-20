import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/environment.dart';
import '../utils/logger.dart';

class MapsService {
  // Get Google Maps API key
  static String get apiKey => Environment.googleMapsApiKey;

  // Check if Google Maps is properly configured
  static bool get isConfigured {
    return apiKey.isNotEmpty && !apiKey.contains('YOUR_') && !apiKey.contains('DemoKey') && !apiKey.contains('KeyHere');
  }

  // Initialize Google Maps
  static Future<void> initialize() async {
    if (!isConfigured) {
      Logger.warning('Google Maps API key not configured', name: 'MapsService');
      if (Environment.isDevelopment) {
        Logger.info('Using development mode - maps will show with limited functionality', name: 'MapsService');
      }
      return;
    }

    try {
      // In a real app, you might initialize other map services here
      Logger.info('Google Maps initialized successfully', name: 'MapsService');
    } catch (e, stack) {
      Logger.error('Failed to initialize Google Maps', name: 'MapsService', error: e, stackTrace: stack);
    }
  }

  // Get initial camera position
  static CameraPosition getInitialCameraPosition({LatLng? center, double? zoom}) {
    return CameraPosition(
      target: center ?? const LatLng(13.5127, 2.1128), // Niamey default
      zoom: zoom ?? 13.0,
    );
  }

  // Get map style for different themes
  static MapType getMapType({bool isDarkMode = false}) {
    return isDarkMode ? MapType.normal : MapType.normal;
  }

  // Create marker with proper icon
  static Marker createMarker({
    required String id,
    required LatLng position,
    required String title,
    MarkerIcon? icon,
    bool isStart = false,
    bool isEnd = false,
    bool isCurrent = false,
  }) {
    // Determine marker color based on type
    BitmapDescriptor markerIcon;
    if (isStart) {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (isEnd) {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (isCurrent) {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else {
      markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }

    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: markerIcon,
    );
  }

  // Create polyline with proper styling
  static Polyline createPolyline({
    required String id,
    required List<LatLng> points,
    Color color = Colors.green,
    double width = 4.0,
    bool isDashed = false,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      color: color,
      width: width,
      points: points,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      patterns: isDashed ? [PatternItem.dash(10), PatternItem.gap(5)] : null,
    );
  }

  // Calculate bounds for fitting route in view
  static LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(13.5127, 2.1128),
        northeast: const LatLng(13.5127, 2.1128),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // Validate coordinates
  static bool isValidCoordinates(LatLng coordinates) {
    return coordinates.latitude >= -90 && 
           coordinates.latitude <= 90 && 
           coordinates.longitude >= -180 && 
           coordinates.longitude <= 180;
  }

  // Get distance between two points (rough calculation)
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = point1.latitude * (3.14159265359 / 180);
    final double lat2Rad = point2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final double a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    final double c = 2 * a.sqrt().asin((1 - a).sqrt());

    return earthRadius * c;
  }

  // Extension methods for double
}

extension DoubleExtension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin(double x) => math.asin(x);
  double sqrt() => math.sqrt(this);
}

// Import math for extensions
import 'dart:math' as math;
