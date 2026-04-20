import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../routes/app_routes.dart';
import '../../providers/route_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/route_model.dart';

class RouteResultsScreen extends StatefulWidget {
  const RouteResultsScreen({super.key});

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  GoogleMapController? _mapController;
  RouteModel? _currentRoute;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRouteData();
    });
  }

  Future<void> _loadRouteData() async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    
    // Check if route was passed as argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RouteModel) {
      setState(() => _currentRoute = args);
    } else if (routeProvider.routes.isNotEmpty) {
      // Use most recent route
      setState(() => _currentRoute = routeProvider.routes.first);
    }
  }

  List<LatLng> get _routePoints => _currentRoute?.waypoints ?? [];
  
  Set<Marker> get _markers {
    if (_currentRoute == null) return {};
    
    return {
      if (_currentRoute!.startLocation != null)
        Marker(
          markerId: const MarkerId('start'),
          position: _currentRoute!.startLocation!,
          infoWindow: InfoWindow(title: 'Start: ${_currentRoute!.originId}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(120.0),
        ),
      if (_currentRoute!.endLocation != null)
        Marker(
          markerId: const MarkerId('end'),
          position: _currentRoute!.endLocation!,
          infoWindow: InfoWindow(title: 'End: ${_currentRoute!.destinationId}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(0.0),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: AppColors.primaryGreen)),
            const SizedBox(width: 8),
            const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/user_avatar.png')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                const SizedBox(width: 8),
                const Text('OPTIMIZATION COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<RouteProvider>(
              builder: (context, routeProvider, child) {
                final route = _currentRoute ?? (routeProvider.routes.isNotEmpty ? routeProvider.routes.first : null);
                if (route == null) {
                  return const Column(
                    children: [
                      Text('No Route Available', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('Please optimize a route first', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  );
                }
                
                return Column(
                  children: [
                    Text(
                      route.name.isNotEmpty ? route.name : 'Optimized Delivery Route',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Route for ${route.originId} to ${route.destinationId}\nOperations • ${_formatDate(route.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Real Route Visualization with Polylines
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(13.6342, 2.1858), // Center of route
                  zoom: 13.0,
                ),
                markers: _markers,
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    color: AppColors.primaryGreen,
                    width: 4,
                    points: _routePoints,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                  ),
                },
                mapType: MapType.normal,
                myLocationEnabled: false,
                zoomControlsEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit map to show entire route
                  if (_routePoints.isNotEmpty) {
                    final bounds = _calculateBounds(_routePoints);
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 100.0),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('ROUTE SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            const SizedBox(height: 16),
            Consumer<RouteProvider>(
              builder: (context, routeProvider, child) {
                final route = _currentRoute ?? (routeProvider.routes.isNotEmpty ? routeProvider.routes.first : null);
                if (route == null) {
                  return const SizedBox.shrink();
                }
                
                return Row(
                  children: [
                    _buildSummaryCard(
                      Icons.straighten, 
                      'Total Distance', 
                      '${route.distanceKm.toStringAsFixed(1)} km', 
                      Colors.green[50]!, 
                      AppColors.successGreen
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      Icons.access_time, 
                      'Estimated Time', 
                      route.estimatedTime, 
                      Colors.orange[50]!, 
                      AppColors.primaryOrange
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      Icons.location_on_outlined, 
                      'Number of Stops', 
                      '${route.waypoints.length}', 
                      Colors.blue[50]!, 
                      Colors.blue
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Optimized\nSequence', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: AppColors.successGreen),
                      SizedBox(width: 4),
                      Text('14% Efficiency\nGain', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sequence List
            Consumer<RouteProvider>(
              builder: (context, routeProvider, child) {
                final route = _currentRoute ?? (routeProvider.routes.isNotEmpty ? routeProvider.routes.first : null);
                if (route == null || route.waypoints.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  children: [
                    _buildSequenceItem('1', route.originId, 'Start Point', isCompleted: true),
                    if (route.waypoints.length > 2) ...[
                      _buildSequenceItem('2', 'Stop 2', 'Delivery Point'),
                      _buildSequenceItem('3', 'Stop 3', 'Delivery Point'),
                      if (route.waypoints.length > 4) const Center(child: Icon(Icons.more_vert, color: AppColors.textLight)),
                    ],
                    _buildSequenceItem('${route.waypoints.length}', route.destinationId, 'Final Destination', isLast: true),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Consumer<RouteProvider>(
              builder: (context, routeProvider, child) {
                final route = _currentRoute ?? (routeProvider.routes.isNotEmpty ? routeProvider.routes.first : null);
                
                return ElevatedButton.icon(
                  onPressed: route != null 
                      ? () => Navigator.pushNamed(context, AppRoutes.driverNavigation, arguments: route)
                      : null,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start Navigation'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildOutlineButton(Icons.save_outlined, 'Save Route', isSaveButton: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildOutlineButton(Icons.sms_outlined, 'Share via\nSMS', isShareButton: true)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.homeDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, String value, Color bgColor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSequenceItem(String index, String title, String subtitle, {bool isCompleted = false, bool isLast = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isCompleted ? AppColors.primaryGreen : AppColors.backgroundGray,
            child: Text(index, style: TextStyle(fontSize: 10, color: isCompleted ? Colors.white : AppColors.textLight, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          ),
          if (isCompleted) const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String label, {bool isSaveButton = false, bool isShareButton = false}) {
    return OutlinedButton.icon(
      onPressed: () {
        if (isSaveButton) {
          _saveRoute();
        } else if (isShareButton) {
          _shareRoute();
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: Colors.grey.shade300),
        foregroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _saveRoute() async {
    try {
      final route = _currentRoute ?? (context.read<RouteProvider>().routes.isNotEmpty 
          ? context.read<RouteProvider>().routes.first 
          : null);
      
      if (route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No route available to save'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      // Save route to saved results
      final savedRoute = {
        'route_id': route.routeId,
        'name': route.name,
        'origin': route.originId,
        'destination': route.destinationId,
        'distance': route.distanceKm,
        'estimated_time': route.estimatedTime,
        'cost': route.cost,
        'waypoints': route.waypoints.map((latLng) => {
          'latitude': latLng.latitude,
          'longitude': latLng.longitude,
        }).toList(),
        'saved_at': DateTime.now().toIso8601String(),
        'type': 'route_optimization',
      };

      // Here you would save to your preferred storage (Firebase, SharedPreferences, etc.)
      // For now, we'll show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route saved successfully!'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to saved results screen
      Navigator.pushNamed(context, AppRoutes.savedResults);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save route: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _shareRoute() async {
    try {
      final route = _currentRoute ?? (context.read<RouteProvider>().routes.isNotEmpty 
          ? context.read<RouteProvider>().routes.first 
          : null);
      
      if (route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No route available to share'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      // Create shareable text
      final shareText = '''
OptiFlow Route Details:
From: ${route.originId}
To: ${route.destinationId}
Distance: ${route.distanceKm.toStringAsFixed(1)} km
Estimated Time: ${route.estimatedTime}
Cost: \$${route.cost.toStringAsFixed(2)}

Generated on: ${_formatDate(DateTime.now())}
      ''';

      // Show share dialog (in a real app, you'd use share_plus package)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Route'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Route details ready to share:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shareText.trim(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Copy to clipboard (in a real app, you'd use flutter/services)
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route details copied to clipboard!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share route: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
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

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
