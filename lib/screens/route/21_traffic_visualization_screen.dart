import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../services/traffic_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/environment.dart';

class TrafficVisualizationScreen extends StatefulWidget {
  const TrafficVisualizationScreen({super.key});

  @override
  State<TrafficVisualizationScreen> createState() => _TrafficVisualizationScreenState();
}

class _TrafficVisualizationScreenState extends State<TrafficVisualizationScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  MapType _mapType = MapType.normal;
  bool _showTrafficLayer = true;
  bool _showIncidents = true;
  bool _isLoading = true;
  bool _isMonitoring = false;
  List<LatLng> _sampleRoute = [];
  
  @override
  void initState() {
    super.initState();
    _initializeSampleRoute();
  }

  void _initializeSampleRoute() {
    _sampleRoute = [
      const LatLng(13.5127, 2.1128), // Niamey
      const LatLng(13.5234, 2.1245),
      const LatLng(13.5456, 2.1367),
      const LatLng(13.5678, 2.1489),
      const LatLng(13.5890, 2.1610),
      const LatLng(13.6012, 2.1732),
    ];
    setState(() {
      _isLoading = false;
    });
  }

  LatLngBounds _calculateRouteBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    const double padding = 0.05;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Visualization'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showIncidents ? Icons.warning : Icons.warning_amber),
            onPressed: () {
              setState(() {
                _showIncidents = !_showIncidents;
              });
            },
            tooltip: _showIncidents ? 'Hide Incidents' : 'Show Incidents',
          ),
          IconButton(
            icon: Icon(_showTrafficLayer ? Icons.layers : Icons.layers_clear),
            onPressed: () {
              setState(() {
                _showTrafficLayer = !_showTrafficLayer;
              });
            },
            tooltip: _showTrafficLayer ? 'Hide Traffic Layer' : 'Show Traffic Layer',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.5127, 2.1128),
              zoom: 12.0,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: _mapType,
            trafficEnabled: _showTrafficLayer,
            buildingsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_sampleRoute.isNotEmpty) {
                final bounds = _calculateRouteBounds(_sampleRoute);
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 100.0),
                );
              }
            },
          ),
          if (_isLoading)
            const LoadingWidget(message: 'Loading traffic data...'),
        ],
      ),
    );
  }
}