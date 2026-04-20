import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../routes/app_routes.dart';
import '../../providers/route_provider.dart';
import '../../models/delivery_stop_model.dart';
import '../../models/route_model.dart';

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({super.key});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ConnectivityResult>? _connectivityStream;
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.5127, 2.1128), // Niamey
    zoom: 16.0,
  );

  RouteModel? _currentRoute;
  
  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final route = ModalRoute.of(context)!.settings.arguments as RouteModel?;
       if (route != null) {
         setState(() => _currentRoute = route);
         Provider.of<RouteProvider>(context, listen: false).fetchStopsForRoute(route.routeId);
       }
    });
  }

  void _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position position) {
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
      }
    });
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Widget _buildStopPreview(String label, String name, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(status, style: TextStyle(fontSize: 10, color: status == 'Completed' ? AppColors.successGreen : AppColors.primaryOrange, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCircleIconButton(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: iconColor), onPressed: () {}),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _connectivityStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Update Arrived Logic
  Future<void> _handleStopAction(DeliveryStopModel stop, RouteProvider prov) async {
    if (stop.status == 'Pending') {
      await prov.updateStopStatus(stop.stopId, 'Arrived');
    } else if (stop.status == 'Arrived') {
       Navigator.pushNamed(context, AppRoutes.proofOfDelivery, arguments: stop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);
    final stops = routeProvider.currentRouteStops;
    final currentStopIndex = stops.indexWhere((s) => s.status != 'Completed');
    final currentStop = currentStopIndex != -1 ? stops[currentStopIndex] : null;

    // Real markers from stops
    final Set<Marker> routeMarkers = stops.map((s) => Marker(
      markerId: MarkerId(s.stopId),
      position: LatLng(s.lat, s.lng),
      icon: s.status == 'Completed' 
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
        : s.status == 'Arrived' 
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: s.name, snippet: s.status),
    )).toSet();

    // Real polyline
    final List<LatLng> polyPoints = stops.map((s) => LatLng(s.lat, s.lng)).toList();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: routeMarkers,
            polylines: {
              Polyline(
                polylineId: const PolylineId('main_route'),
                color: AppColors.primaryGreen,
                width: 5,
                points: polyPoints,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              if (polyPoints.isNotEmpty) {
                 final bounds = _calculateBounds(polyPoints);
                 controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currentStop != null ? 'NEXT STOP' : 'ROUTE COMPLETED', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Text(currentStop?.name ?? 'Well done!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (currentStop != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStopPreview('CURRENT', currentStop.name, currentStop.status),
                      if (currentStopIndex + 1 < stops.length)
                        _buildStopPreview('NEXT', stops[currentStopIndex+1].name, 'Upcoming'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildCircleIconButton(Icons.phone, Colors.grey[100]!, AppColors.textDark),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleStopAction(currentStop, routeProvider),
                          icon: Icon(currentStop.status == 'Pending' ? Icons.play_arrow : Icons.check_circle),
                          label: Text(currentStop.status == 'Pending' ? 'Start Journey' : 'Arrived / Complete', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStop.status == 'Pending' ? AppColors.primaryOrange : AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildCircleIconButton(Icons.more_horiz, Colors.grey[100]!, AppColors.textDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}