import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import '../utils/logger.dart';
import '../utils/environment.dart';
import '../services/error_handling_service.dart';
import 'mock_route_service.dart';

class RouteService {
  static String get _baseUrl => Environment.apiBaseUrl;

  // Optimize route using backend API
  static Future<RouteModel?> optimizeRoute({
    required List<String> destinations,
    required String origin,
    Map<String, dynamic>? preferences,
    BuildContext? context,
  }) async {
    // Mock routing removed per strict "no mock data" requirement

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/optimize'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'origin': origin,
          'destinations': destinations,
          'preferences': preferences ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOptimizedRoute(data);
      } else if (response.statusCode == 404) {
        Logger.error('API endpoint not found (404)', name: 'RouteService');
        return null;
      } else {
        Logger.error('Route optimization failed: ${response.statusCode} - ${response.body}', name: 'RouteService');
        return null;
      }
    } catch (e, stack) {
      Logger.error('Error optimizing route', name: 'RouteService', error: e, stackTrace: stack);
      
      // Show user-friendly error if context is provided
      if (context != null) {
        await ErrorHandlingService.handleApiError(
          context!,
          e,
          stack,
          endpoint: 'optimize',
          action: 'optimize route',
        );
      }
      
      return null;
    }
  }

  // Get saved routes from backend
  static Future<List<RouteModel>> getSavedRoutes(String businessId, {BuildContext? context}) async {
    // Removed MockRouteService

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/routes/business/$businessId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((route) => RouteModel.fromMap(route)).toList();
      } else {
        Logger.error('Failed to get saved routes: ${response.statusCode}', name: 'RouteService');
        
        // Show user-friendly error if context is provided
        if (context != null) {
          await ErrorHandlingService.handleApiError(
            context!,
            'HTTP ${response.statusCode}',
            null,
            endpoint: 'get routes',
            action: 'load saved routes',
          );
        }
        
        return [];
      }
    } catch (e, stack) {
      Logger.error('Error getting saved routes', name: 'RouteService', error: e, stackTrace: stack);
      
      // Show user-friendly error if context is provided
      if (context != null) {
        await ErrorHandlingService.handleApiError(
          context!,
          e,
          stack,
          endpoint: 'get routes',
          action: 'load saved routes',
        );
      }
      
      return [];
    }
  }

  // Save route to backend
  static Future<bool> saveRoute(RouteModel route, {BuildContext? context}) async {
    // Removed mock routing

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/routes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(route.toMap()),
      );

      if (response.statusCode == 201) {
        Logger.info('Route saved successfully: ${route.routeId}', name: 'RouteService');
        
        // Show success message if context is provided
        if (context != null) {
          ErrorHandlingService.showSuccessMessage(context!, 'Route saved successfully!');
        }
        
        return true;
      } else {
        Logger.error('Failed to save route: ${response.statusCode}', name: 'RouteService');
        
        // Show user-friendly error if context is provided
        if (context != null) {
          await ErrorHandlingService.handleApiError(
            context!,
            'HTTP ${response.statusCode}',
            null,
            endpoint: 'save route',
            action: 'save route',
          );
        }
        
        return false;
      }
    } catch (e, stack) {
      Logger.error('Error saving route', name: 'RouteService', error: e, stackTrace: stack);
      
      // Show user-friendly error if context is provided
      if (context != null) {
        await ErrorHandlingService.handleApiError(
          context!,
          e,
          stack,
          endpoint: 'save route',
          action: 'save route',
        );
      }
      
      return false;
    }
  }

  // Update route status
  static Future<bool> updateRouteStatus(String routeId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/routes/$routeId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        Logger.info('Route status updated: $routeId -> $status', name: 'RouteService');
        return true;
      } else {
        Logger.error('Failed to update route status: ${response.statusCode}', name: 'RouteService');
        return false;
      }
    } catch (e, stack) {
      Logger.error('Error updating route status', name: 'RouteService', error: e, stackTrace: stack);
      return false;
    }
  }

  // Get route statistics
  static Future<Map<String, dynamic>> getRouteStats(String businessId) async {
    // Mock feature removed.

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/routes/stats/$businessId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        Logger.error('Failed to get route stats: ${response.statusCode}', name: 'RouteService');
        return {};
      }
    } catch (e, stack) {
      Logger.error('Error getting route stats', name: 'RouteService', error: e, stackTrace: stack);
      return {};
    }
  }

  // Parse optimized route from backend response
  static RouteModel _parseOptimizedRoute(Map<String, dynamic> data) {
    return RouteModel(
      routeId: data['route_id'] ?? '',
      businessId: data['business_id'] ?? '',
      originId: data['origin_id'] ?? '',
      destinationId: data['destination_id'] ?? '',
      distanceKm: (data['distance_km'] ?? 0.0).toDouble(),
      estimatedTime: data['estimated_time'] ?? '',
      cost: (data['cost'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      // Parse waypoints if available
      startLocation: data['start_location'] != null
          ? LatLng(data['start_location']['lat'], data['start_location']['lng'])
          : null,
      endLocation: data['end_location'] != null
          ? LatLng(data['end_location']['lat'], data['end_location']['lng'])
          : null,
      waypoints: (data['waypoints'] as List<dynamic>?)
          ?.map((w) => LatLng(w['lat'], w['lng']))
          .cast<LatLng>()
          .toList() ?? [],
    );
  }

  // Get route by ID
  static Future<RouteModel?> getRouteById(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/routes/$routeId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RouteModel.fromMap(data);
      } else {
        Logger.error('Failed to get route: ${response.statusCode}', name: 'RouteService');
        return null;
      }
    } catch (e, stack) {
      Logger.error('Error getting route by ID', name: 'RouteService', error: e, stackTrace: stack);
      return null;
    }
  }

  // Delete route
  static Future<bool> deleteRoute(String routeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/routes/$routeId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Logger.info('Route deleted successfully: $routeId', name: 'RouteService');
        return true;
      } else {
        Logger.error('Failed to delete route: ${response.statusCode}', name: 'RouteService');
        return false;
      }
    } catch (e, stack) {
      Logger.error('Error deleting route', name: 'RouteService', error: e, stackTrace: stack);
      return false;
    }
  }
}
