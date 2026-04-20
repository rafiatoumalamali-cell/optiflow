import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_client.dart';
import 'endpoints.dart';
import 'api_config.dart';

class MapsApi {
  /// Fetches a route between an origin and destination with optional waypoints.
  /// Returns a Map containing the decoded points and other route metadata.
  Future<Map<String, dynamic>> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    final String originStr = '${origin.latitude},${origin.longitude}';
    final String destStr = '${destination.latitude},${destination.longitude}';
    
    String url = '${Endpoints.directionsUrl}?origin=$originStr&destination=$destStr&key=${Endpoints.mapsApiKey}';
    
    if (waypoints != null && waypoints.isNotEmpty) {
      final String waypointsStr = waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
      url += '&waypoints=optimize:true|$waypointsStr';
    }

    try {
      final response = await ApiClient.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];
          final points = _decodePolyline(polyline);
          
          return {
            'points': points,
            'distance': route['legs'][0]['distance']['text'],
            'duration': route['legs'][0]['duration']['text'],
            'bounds': route['bounds'],
          };
        } else {
          throw Exception('Maps API Error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch directions: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Estimates travel distances and times for a set of origins and destinations.
  Future<Map<String, dynamic>> getDistanceMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
  }) async {
    final String originsStr = origins.map((o) => '${o.latitude},${o.longitude}').join('|');
    final String destinationsStr = destinations.map((d) => '${d.latitude},${d.longitude}').join('|');
    
    final String url = '${Endpoints.distanceMatrixUrl}?origins=$originsStr&destinations=$destinationsStr&mode=driving&key=${Endpoints.mapsApiKey}';

    try {
      final response = await ApiClient.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch distance matrix: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Searches for places matching a query.
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    
    // 1. Try Google Maps API first
    final String baseUrl = Endpoints.directionsUrl.replaceAll('directions/json', 'place/autocomplete/json');
    final String googleUrl = '$baseUrl?input=$encodedQuery&key=${Endpoints.mapsApiKey}&components=country:ne|country:ng|country:gh|country:sn|country:ci&language=en';
    
    try {
      final response = await ApiClient.get(Uri.parse(googleUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions'] ?? []);
        } else {
          print('DEBUG: Maps API search error status: ${data['status']}. Trying OSM fallback...');
        }
      }
    } catch (e) {
      print('DEBUG: Google Maps Search error: $e');
    }

    // 2. Genuine OpenStreetMap (Nominatim) Fallback - 100% real, no API key required!
    try {
      final String osmUrl = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=5&countrycodes=ne,ng,gh,sn,ci';
      final osmResponse = await ApiClient.get(
        Uri.parse(osmUrl),
        headers: {'User-Agent': 'OptiFlow App/1.0 (Geocoding Fallback)'}
      );
      
      if (osmResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(osmResponse.body);
        return data.map((item) {
          final displayName = item['display_name'] as String;
          final parts = displayName.split(', ');
          final mainText = parts.first;
          final secondaryText = parts.length > 1 ? parts.skip(1).join(', ') : '';
          
          return {
            'place_id': 'osm_${item['place_id']}', 
            'description': displayName,
            'structured_formatting': {
              'main_text': mainText,
              'secondary_text': secondaryText,
            },
            'lat': double.tryParse(item['lat'].toString()),
            'lng': double.tryParse(item['lon'].toString()),
          };
        }).toList();
      }
    } catch (e) {
      print('DEBUG: OpenStreetMap error: $e');
    }
    
    return [];
  }

  /// Fetches details (coordinates) for a specific place ID.
  Future<LatLng?> getPlaceDetails(String placeId) async {
    // If it's an OSM ID, it should have been caught by the UI fallback, but just in case
    if (placeId.startsWith('osm_')) return null;

    final String baseUrl = Endpoints.directionsUrl.replaceAll('directions/json', 'place/details/json');
    final String url = '$baseUrl?place_id=$placeId&key=${Endpoints.mapsApiKey}';
    
    try {
      final response = await ApiClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Safely check if result is present
        if (data['status'] == 'OK' && data['result'] != null) {
           final loc = data['result']['geometry']['location'];
           return LatLng(loc['lat'], loc['lng']);
        }
      }
      return null;
    } catch (e) {
      print('DEBUG: Google place details error: $e');
      return null;
    }
  }

  /// Decodes Googl's encoded polyline string into a list of LatLng points.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

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
