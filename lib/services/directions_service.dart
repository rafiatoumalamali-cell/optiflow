import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/logger.dart';
import '../utils/environment.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const Duration _timeout = Duration(seconds: 30);
  
  // Directions API request parameters
  final String apiKey;
  final TravelMode travelMode;
  final RoutingProfile routingProfile;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  
  DirectionsService({
    required this.apiKey,
    this.travelMode = TravelMode.driving,
    this.routingProfile = RoutingProfile.best,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidFerries = false,
  });

  /// Get directions between two points
  Future<DirectionsResponse> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String? language,
    String? region,
  }) async {
    try {
      final url = _buildDirectionsUrl(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        language: language,
        region: region,
      );
      
      Logger.info('Requesting directions from Google Maps API', name: 'DirectionsService');
      
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DirectionsResponse.fromJson(data);
      } else {
        throw DirectionsException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          DirectionsError.httpError,
        );
      }
    } catch (e, stack) {
      Logger.error('Error getting directions', name: 'DirectionsService', error: e, stackTrace: stack);
      
      if (e is DirectionsException) {
        rethrow;
      } else {
        throw DirectionsException(
          'Failed to get directions: $e',
          DirectionsError.networkError,
        );
      }
    }
  }

  /// Build the directions API URL
  String _buildDirectionsUrl({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    String? language,
    String? region,
  }) {
    final params = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': travelMode.name,
      'key': apiKey,
    };
    
    // Add optional parameters
    if (routingProfile != RoutingProfile.best) {
      params['profile'] = routingProfile.name;
    }
    
    if (avoidTolls) params['avoid'] = 'tolls';
    if (avoidHighways) params['avoid'] = 'highways';
    if (avoidFerries) params['avoid'] = 'ferries';
    
    if (language != null) params['language'] = language;
    if (region != null) params['region'] = region;
    
    // Add waypoints if provided
    if (waypoints != null && waypoints.isNotEmpty) {
      final waypointString = waypoints
          .map((wp) => '${wp.latitude},${wp.longitude}')
          .join('|');
      params['waypoints'] = waypointString;
    }
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$_baseUrl?$queryString';
  }

  /// Get alternative routes for the same origin/destination
  Future<List<DirectionsResponse>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    int maxRoutes = 3,
  }) async {
    final routes = <DirectionsResponse>[];
    
    try {
      // Request multiple alternatives
      final url = _buildDirectionsUrl(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      ) + '&alternatives=true';
      
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routesData = data['routes'] as List;
        
        for (int i = 0; i < math.min(maxRoutes, routesData.length); i++) {
          final routeData = {
            ...data,
            'routes': [routesData[i]],
          };
          routes.add(DirectionsResponse.fromJson(Map<String, dynamic>.from(routeData)));
        }
      }
    } catch (e, stack) {
      Logger.error('Error getting alternative routes', name: 'DirectionsService', error: e, stackTrace: stack);
      throw DirectionsException(
        'Failed to get alternative routes: $e',
        DirectionsError.networkError,
      );
    }
    
    return routes;
  }

  /// Get turn-by-turn navigation instructions
  Future<TurnByTurnNavigation> getTurnByTurnNavigation({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    final directionsResponse = await getDirections(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
    
    return TurnByTurnNavigation.fromDirectionsResponse(directionsResponse);
  }

  /// Calculate estimated travel time and distance
  Future<TravelEstimate> calculateTravelEstimate({
    required LatLng origin,
    required LatLng destination,
    TravelMode mode = TravelMode.driving,
  }) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=${origin.latitude},${origin.longitude}'
          '&destinations=${destination.latitude},${destination.longitude}'
          '&mode=${mode.name}'
          '&key=$apiKey';
      
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final element = data['rows'][0]['elements'][0];
        
        if (element['status'] == 'OK') {
          return TravelEstimate(
            distance: Distance.fromMeters(element['distance']['value'] as int),
            duration: Duration(seconds: element['duration']['value'] as int),
            status: TravelStatus.available,
          );
        } else {
          return TravelEstimate(
            status: TravelStatus.unavailable,
            error: element['status'] as String,
          );
        }
      }
    } catch (e, stack) {
      Logger.error('Error calculating travel estimate', name: 'DirectionsService', error: e, stackTrace: stack);
    }
    
    return TravelEstimate(
      status: TravelStatus.error,
      error: 'Failed to calculate estimate',
    );
  }
}

/// Travel modes for directions
enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

/// Routing profiles for different optimization goals
enum RoutingProfile {
  best,
  fastest,
  shortest,
}

/// Travel status for estimates
enum TravelStatus {
  available,
  unavailable,
  error,
}

/// Directions API response model
class DirectionsResponse {
  final List<Route> routes;
  final List<GeocodedWaypoint> geocodedWaypoints;
  final String status;
  final String? errorMessage;
  
  DirectionsResponse({
    required this.routes,
    required this.geocodedWaypoints,
    required this.status,
    this.errorMessage,
  });
  
  factory DirectionsResponse.fromJson(Map<String, dynamic> json) {
    return DirectionsResponse(
      routes: (json['routes'] as List?)
          ?.map((r) => Route.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      geocodedWaypoints: (json['geocoded_waypoints'] as List?)
          ?.map((gw) => GeocodedWaypoint.fromJson(gw as Map<String, dynamic>))
          .toList() ?? [],
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
    );
  }
  
  bool get isSuccessful => status == 'OK';
  Route? get bestRoute => routes.isNotEmpty ? routes.first : null;
}

/// Route information
class Route {
  final List<Leg> legs;
  final Polyline overviewPolyline;
  final Bounds bounds;
  final String summary;
  final List<String> warnings;
  final Fare? fare;
  
  Route({
    required this.legs,
    required this.overviewPolyline,
    required this.bounds,
    required this.summary,
    required this.warnings,
    this.fare,
  });
  
  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      legs: (json['legs'] as List?)
          ?.map((l) => Leg.fromJson(l as Map<String, dynamic>))
          .toList() ?? [],
      overviewPolyline: Polyline.fromJson(json['overview_polyline'] as Map<String, dynamic>),
      bounds: Bounds.fromJson(json['bounds'] as Map<String, dynamic>),
      summary: json['summary'] as String? ?? '',
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
      fare: json['fare'] != null ? Fare.fromJson(json['fare'] as Map<String, dynamic>) : null,
    );
  }
  
  Duration get totalDuration {
    return legs.fold(Duration.zero, (total, leg) => total + leg.duration);
  }
  
  Distance get totalDistance {
    return legs.fold(Distance.zero, (total, leg) => total + leg.distance);
  }
}

/// Leg of a route (between waypoints)
class Leg {
  final List<Step> steps;
  final Distance distance;
  final Duration duration;
  final Location startLocation;
  final Location endLocation;
  final String startAddress;
  final String endAddress;
  final List<String> warnings;
  
  Leg({
    required this.steps,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.startAddress,
    required this.endAddress,
    required this.warnings,
  });
  
  factory Leg.fromJson(Map<String, dynamic> json) {
    return Leg(
      steps: (json['steps'] as List?)
          ?.map((s) => Step.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      distance: Distance.fromMeters(json['distance']['value'] as int),
      duration: Duration(seconds: json['duration']['value'] as int),
      startLocation: Location.fromJson(json['start_location'] as Map<String, dynamic>),
      endLocation: Location.fromJson(json['end_location'] as Map<String, dynamic>),
      startAddress: json['start_address'] as String,
      endAddress: json['end_address'] as String,
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Step in navigation instructions
class Step {
  final Distance distance;
  final Duration duration;
  final Location startLocation;
  final Location endLocation;
  final String htmlInstructions;
  final String maneuver;
  final Polyline polyline;
  final TravelMode travelMode;
  
  Step({
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.htmlInstructions,
    required this.maneuver,
    required this.polyline,
    required this.travelMode,
  });
  
  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      distance: Distance.fromMeters(json['distance']['value'] as int),
      duration: Duration(seconds: json['duration']['value'] as int),
      startLocation: Location.fromJson(json['start_location'] as Map<String, dynamic>),
      endLocation: Location.fromJson(json['end_location'] as Map<String, dynamic>),
      htmlInstructions: json['html_instructions'] as String,
      maneuver: json['maneuver'] as String? ?? '',
      polyline: Polyline.fromJson(json['polyline'] as Map<String, dynamic>),
      travelMode: TravelMode.values.firstWhere(
        (mode) => mode.name == json['travel_mode'],
        orElse: () => TravelMode.driving,
      ),
    );
  }
  
  String get plainInstructions {
    return htmlInstructions.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
  
  NavigationInstruction get navigationInstruction {
    return NavigationInstruction.fromManeuver(maneuver, plainInstructions);
  }
}

/// Navigation instruction model
class NavigationInstruction {
  final NavigationAction action;
  final String instruction;
  final String? roadName;
  final double? distance;
  final Duration? duration;
  
  NavigationInstruction({
    required this.action,
    required this.instruction,
    this.roadName,
    this.distance,
    this.duration,
  });
  
  factory NavigationInstruction.fromManeuver(String maneuver, String instruction) {
    final action = _parseManeuverAction(maneuver);
    final roadName = _extractRoadName(instruction);
    
    return NavigationInstruction(
      action: action,
      instruction: instruction,
      roadName: roadName,
    );
  }
  
  static NavigationAction _parseManeuverAction(String maneuver) {
    final lowerManeuver = maneuver.toLowerCase();
    
    if (lowerManeuver.contains('turn-left') || lowerManeuver.contains('left')) {
      return NavigationAction.turnLeft;
    } else if (lowerManeuver.contains('turn-right') || lowerManeuver.contains('right')) {
      return NavigationAction.turnRight;
    } else if (lowerManeuver.contains('straight') || lowerManeuver.contains('continue')) {
      return NavigationAction.straight;
    } else if (lowerManeuver.contains('merge')) {
      return NavigationAction.merge;
    } else if (lowerManeuver.contains('fork')) {
      return NavigationAction.fork;
    } else if (lowerManeuver.contains('roundabout')) {
      return NavigationAction.roundabout;
    } else if (lowerManeuver.contains('uturn') || lowerManeuver.contains('u-turn')) {
      return NavigationAction.uTurn;
    } else if (lowerManeuver.contains('exit')) {
      return NavigationAction.exit;
    } else {
      return NavigationAction.straight;
    }
  }
  
  static String? _extractRoadName(String instruction) {
    final regex = RegExp(r'onto\s+([^.!?]+)');
    final match = regex.firstMatch(instruction);
    return match?.group(1)?.trim();
  }
}

/// Navigation actions
enum NavigationAction {
  proceed,
  turnLeft,
  turnRight,
  straight,
  merge,
  fork,
  roundabout,
  uTurn,
  exit,
  arrive,
}

/// Turn-by-turn navigation model
class TurnByTurnNavigation {
  final List<NavigationStep> steps;
  final Duration totalDuration;
  final Distance totalDistance;
  final LatLng startLocation;
  final LatLng endLocation;
  
  TurnByTurnNavigation({
    required this.steps,
    required this.totalDuration,
    required this.totalDistance,
    required this.startLocation,
    required this.endLocation,
  });
  
  factory TurnByTurnNavigation.fromDirectionsResponse(DirectionsResponse response) {
    final route = response.bestRoute;
    if (route == null) {
      throw DirectionsException('No route available', DirectionsError.noRoute);
    }
    
    final navigationSteps = <NavigationStep>[];
    int stepIndex = 0;
    
    for (final leg in route.legs) {
      for (final step in leg.steps) {
        navigationSteps.add(NavigationStep(
          index: stepIndex++,
          instruction: step.navigationInstruction,
          distance: step.distance,
          duration: step.duration,
          startLocation: step.startLocation.latLng,
          endLocation: step.endLocation.latLng,
          polyline: step.polyline.decodedPoints,
        ));
      }
    }
    
    return TurnByTurnNavigation(
      steps: navigationSteps,
      totalDuration: route.totalDuration,
      totalDistance: route.totalDistance,
      startLocation: route.legs.first.startLocation.latLng,
      endLocation: route.legs.last.endLocation.latLng,
    );
  }
  
  NavigationStep? get currentStep {
    return steps.isNotEmpty ? steps.first : null;
  }
  
  NavigationStep? get nextStep {
    return steps.length > 1 ? steps[1] : null;
  }
}

/// Individual navigation step
class NavigationStep {
  final int index;
  final NavigationInstruction instruction;
  final Distance distance;
  final Duration duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> polyline;
  
  NavigationStep({
    required this.index,
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.polyline,
  });
  
  bool get isFinal => index == 0; // In reverse order (current step is index 0)
}

/// Distance model
class Distance {
  final double meters;
  final double kilometers;
  final double miles;
  
  Distance({
    required this.meters,
  }) : kilometers = meters / 1000,
       miles = meters / 1609.344;
  
  factory Distance.fromMeters(int meters) {
    return Distance(meters: meters.toDouble());
  }
  
  factory Distance.fromKilometers(double kilometers) {
    return Distance(meters: kilometers * 1000);
  }
  
  static Distance zero = Distance(meters: 0);
  
  Distance operator +(Distance other) {
    return Distance(meters: meters + other.meters);
  }
  
  String get formattedKilometers {
    return '${kilometers.toStringAsFixed(1)} km';
  }
  
  String get formattedMiles {
    return '${miles.toStringAsFixed(1)} mi';
  }
  
  String get formattedMeters {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return formattedKilometers;
    }
  }
}

/// Location model
class Location {
  final double latitude;
  final double longitude;
  
  Location({
    required this.latitude,
    required this.longitude,
  });
  
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['lat'] as double,
      longitude: json['lng'] as double,
    );
  }
  
  LatLng get latLng => LatLng(latitude, longitude);
}

/// Polyline model
class Polyline {
  final String points;
  final List<LatLng> decodedPoints;
  
  Polyline({
    required this.points,
  }) : decodedPoints = _decodePolyline(points);
  
  factory Polyline.fromJson(Map<String, dynamic> json) {
    return Polyline(points: json['points'] as String);
  }
  
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;
    
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    
    return points;
  }
}

/// Bounds model
class Bounds {
  final LatLng northeast;
  final LatLng southwest;
  
  Bounds({
    required this.northeast,
    required this.southwest,
  });
  
  factory Bounds.fromJson(Map<String, dynamic> json) {
    return Bounds(
      northeast: LatLng(
        json['northeast']['lat'] as double,
        json['northeast']['lng'] as double,
      ),
      southwest: LatLng(
        json['southwest']['lat'] as double,
        json['southwest']['lng'] as double,
      ),
    );
  }
  
  LatLngBounds toGoogleMapsBounds() {
    return LatLngBounds(
      northeast: northeast,
      southwest: southwest,
    );
  }
}

/// Geocoded waypoint model
class GeocodedWaypoint {
  final String? placeId;
  final String? geocoderStatus;
  final List<Location> partialMatch;
  
  GeocodedWaypoint({
    this.placeId,
    this.geocoderStatus,
    required this.partialMatch,
  });
  
  factory GeocodedWaypoint.fromJson(Map<String, dynamic> json) {
    return GeocodedWaypoint(
      placeId: json['place_id'] as String?,
      geocoderStatus: json['geocoder_status'] as String?,
      partialMatch: (json['partial_match'] as List?)
          ?.map((pm) => Location.fromJson(pm as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

/// Fare model
class Fare {
  final String currency;
  final double value;
  final String text;
  
  Fare({
    required this.currency,
    required this.value,
    required this.text,
  });
  
  factory Fare.fromJson(Map<String, dynamic> json) {
    return Fare(
      currency: json['currency'] as String,
      value: (json['value'] as num).toDouble(),
      text: json['text'] as String,
    );
  }
}

/// Travel estimate model
class TravelEstimate {
  final Distance? distance;
  final Duration? duration;
  final TravelStatus status;
  final String? error;
  
  TravelEstimate({
    this.distance,
    this.duration,
    required this.status,
    this.error,
  });
}

/// Directions exception
class DirectionsException implements Exception {
  final String message;
  final DirectionsError error;
  
  DirectionsException(this.message, this.error);
  
  @override
  String toString() => 'DirectionsException: $message';
}

/// Directions error types
enum DirectionsError {
  networkError,
  httpError,
  noRoute,
  invalidRequest,
  overQueryLimit,
  requestDenied,
  unknownError,
}
