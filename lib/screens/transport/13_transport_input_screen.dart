import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../providers/transport_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/optimizations_guard.dart';

class TransportInputScreen extends StatefulWidget {
  const TransportInputScreen({super.key});

  @override
  State<TransportInputScreen> createState() => _TransportInputScreenState();
}

class _TransportInputScreenState extends State<TransportInputScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessId;
      if (businessId != null) {
        Provider.of<TransportProvider>(context, listen: false).fetchLocations(businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final transportProvider = Provider.of<TransportProvider>(context);

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
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(loc?.translate('home_title') ?? 'OptiFlow', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final initials = auth.currentUser?.fullName.isNotEmpty == true 
                ? auth.currentUser!.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                : 'U';
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: Text(initials, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc?.translate('transport_cost_input') ?? 'Transport Cost\nInput', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(loc?.translate('logistics_params_desc') ?? 'Define regional logistics parameters for West African hubs.', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(Icons.history, loc?.translate('history') ?? 'History'),
                const SizedBox(width: 12),
                _buildActionButton(Icons.compare_arrows, loc?.translate('border_crossing') ?? 'BORDER CROSSING', isOrange: true),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(loc?.translate('supply_points') ?? 'Supply Points', loc?.translate('factories') ?? 'FACTORIES'),
            
            if (transportProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ...transportProvider.supplyPoints.map((l) => LocationCard(
                name: l.name,
                subtitle: l.address,
                label1: loc?.translate('available_supply') ?? 'AVAILABLE SUPPLY',
                value1: '${l.supplyQuantity} Units',
                label2: loc?.translate('storage_cost') ?? 'STORAGE COST',
                value2: '51.20/unit',
                icon: Icons.factory_outlined,
              )),
            ],
            
            _buildAddButton(loc?.translate('add_supply_point') ?? 'Add Supply Point', 'Supply'),
            const SizedBox(height: 24),
            _buildSectionHeader(loc?.translate('demand_points') ?? 'Demand Points', loc?.translate('retailers') ?? 'RETAILERS'),
            
            if (!transportProvider.isLoading) ...[
              ...transportProvider.demandPoints.map((l) => LocationCard(
                name: l.name,
                subtitle: l.address,
                label1: loc?.translate('target_demand') ?? 'TARGET DEMAND',
                value1: '${l.demandQuantity} Units',
                label2: loc?.translate('lead_time_max') ?? 'LEAD TIME MAX',
                value2: '48 Hours',
                icon: Icons.storefront,
              )),
            ],
            
            _buildAddButton(loc?.translate('add_demand_point') ?? 'Add Demand Point', 'Demand'),
            const SizedBox(height: 24),
            // Transport Route Map
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(13.5127, 2.1128), // Center of West Africa
                      zoom: 5.0,
                    ),
                    markers: _createTransportMarkers(),
                    polylines: _createTransportPolylines(),
                    mapType: MapType.normal,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.public, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Text(loc?.translate('cross_border_active') ?? 'CROSS-BORDER CORRIDOR ACTIVE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(loc?.translate('route_mode') ?? 'Route Mode', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(loc?.translate('opt_algo_desc') ?? 'Optimization algorithm prioritizes paved roads and arterial expressways through Zinder and Katsina.', 
              style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            const SizedBox(height: 16),
            Text(loc?.translate('vehicle_profile') ?? 'Vehicle Profile', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text('Heavy Duty (30T)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => OptimizationGuard.checkAndNavigate(context, AppRoutes.transportResults),
              icon: const Icon(Icons.bolt),
              label: Text(loc?.translate('run_transport_opt') ?? 'Run Transport Optimization'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {bool isOrange = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isOrange ? AppColors.primaryOrange : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isOrange ? Colors.white : AppColors.textDark),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOrange ? Colors.white : AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, String type) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addLocation, arguments: type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textLight),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget LocationCard({
    required String name,
    required String subtitle,
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label1, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Text(value1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label2, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    const SizedBox(height: 4),
                    Text(value2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Set<Marker> _createTransportMarkers() {
    final transportProvider = Provider.of<TransportProvider>(context);
    final Set<Marker> markers = {};
    
    // Add supply point markers
    for (final location in transportProvider.supplyPoints) {
      markers.add(Marker(
        markerId: MarkerId('supply_${location.locationId}'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: 'Supply: ${location.supplyQuantity} units',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    
    // Add demand point markers
    for (final location in transportProvider.demandPoints) {
      markers.add(Marker(
        markerId: MarkerId('demand_${location.locationId}'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: 'Demand: ${location.demandQuantity} units',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    
    return markers;
  }

  Set<Polyline> _createTransportPolylines() {
    final transportProvider = Provider.of<TransportProvider>(context);
    final Set<Polyline> polylines = {};
    
    // Create sample routes between supply and demand points
    if (transportProvider.supplyPoints.isNotEmpty && transportProvider.demandPoints.isNotEmpty) {
      final supplyPoint = transportProvider.supplyPoints.first;
      final demandPoint = transportProvider.demandPoints.first;
      
      polylines.add(Polyline(
        polylineId: const PolylineId('sample_route'),
        color: AppColors.primaryGreen,
        width: 3,
        points: [
          LatLng(supplyPoint.latitude, supplyPoint.longitude),
          LatLng(demandPoint.latitude, demandPoint.longitude),
        ],
      ));
    }
    
    return polylines;
  }
}
