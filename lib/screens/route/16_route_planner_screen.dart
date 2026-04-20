import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/route_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.5127, 2.1128), // Niamey
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15,
      ));
    } catch (e) {
      Logger.error('Error getting location', error: e);
    }
  }

  void _onMapTapped(LatLng pos) {
    _showAddLocationDialog(pos: pos);
  }

  @override
  Widget build(BuildContext context) {
    final routeProv = Provider.of<RouteProvider>(context);
    _updateMarkers(routeProv.plannedLocations);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. MAP VIEW (60%)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (c) => _mapController = c,
                  onTap: _onMapTapped,
                  markers: _markers,
                  polylines: {
                    if (routeProv.currentRoutePoints.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('route_path'),
                        points: routeProv.currentRoutePoints,
                        color: const Color(0xFF1B5E20),
                        width: 5,
                        jointType: JointType.round,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                      ),
                  },
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
              
              // 2. LOCATIONS LIST & OPTIONS
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: Column(
                      children: [
                         _buildDragHandle(),
                         Expanded(
                           child: ListView(
                             padding: const EdgeInsets.symmetric(horizontal: 20),
                             children: [
                               _buildSectionHeader('LOCATIONS LIST', 'Optimal order after optimization'),
                               const SizedBox(height: 8),
                               _buildHintText('⚠️ HINT: Tap map to add point. Drag handle [⋮⋮] to reorder.'),
                               const SizedBox(height: 12),
                               if (routeProv.plannedLocations.isEmpty)
                                 _buildEmptyState()
                               else
                                 _buildReorderableList(routeProv),
                               const SizedBox(height: 16),
                               _buildOptionsSection(routeProv),
                               const SizedBox(height: 24),
                               _buildRouteSummary(routeProv),
                               const SizedBox(height: 100),
                             ],
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          _buildTopSearchBar(),
          
          Positioned(
            right: 20,
            bottom: 120,
            child: FloatingActionButton(
              onPressed: () => _showSearchDialog(),
              backgroundColor: const Color(0xFF1B5E20),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),

          _buildBottomActionBar(routeProv),

          if (routeProv.lastOptimizationResult != null)
            _buildResultOverlay(routeProv),

          if (routeProv.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.homeDashboard);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHintText(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReorderableList(RouteProvider prov) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prov.plannedLocations.length,
      onReorder: prov.reorderLocations,
      itemBuilder: (context, index) {
        final loc = prov.plannedLocations[index];
        final isStart = loc['role'] == 'Start Point';
        final isEnd = loc['role'] == 'End Point';
        
        return Card(
          key: ValueKey('loc_$index'),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _showEditLocationDialog(index, loc),
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: isStart ? Colors.green : (isEnd ? Colors.blue : Colors.red),
              child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
            title: Text(loc['name'], style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(loc['role'], style: const TextStyle(fontSize: 10)),
            trailing: const Icon(Icons.drag_indicator),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No locations yet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(RouteProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('🔧 OPTIONS', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['distance', 'time', 'scenic'].map((type) => _buildChoiceChip(prov, type)).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: prov.avoidances.keys.map((key) => _buildAvoidanceCheck(prov, key)).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(RouteProvider prov, String value) {
    final isSelected = prov.optimizationType == value;
    return ChoiceChip(
      label: Text(value.toUpperCase(), style: const TextStyle(fontSize: 10)),
      selected: isSelected,
      onSelected: (s) => prov.setOptimizationType(value),
    );
  }

  Widget _buildAvoidanceCheck(RouteProvider prov, String key) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: prov.avoidances[key], onChanged: (v) => prov.setAvoidance(key, v!)),
        Text('Avoid $key', style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildRouteSummary(RouteProvider prov) {
    final res = prov.lastOptimizationResult;
    final displayDistance = res != null 
        ? '${res['total_distance']?.toStringAsFixed(1)}' 
        : '${prov.currentTotalDistance.toStringAsFixed(1)}';
    
    final displayTime = res != null 
        ? '${res['total_time']?.toStringAsFixed(1)} hrs' 
        : prov.currentTotalDuration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Distance', '$displayDistance km'),
          _buildSummaryItem('Estimated Time', displayTime.isEmpty ? '--' : displayTime),
          _buildSummaryItem('Stops', '${prov.plannedLocations.length}'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTopSearchBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 52,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: ListTile(
            leading: const Icon(Icons.search, color: Color(0xFF1B5E20)),
            title: const Text('Search address or pin location...', style: TextStyle(fontSize: 13, color: Colors.grey)),
            onTap: _showSearchDialog,
            trailing: IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF1B5E20)),
              onPressed: _getCurrentLocation,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(RouteProvider prov) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                prov.clearPlanner();
              },
              child: const Text('CLEAR ALL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: prov.runOptimization,
              icon: const Icon(Icons.rocket_launch, color: Colors.white, size: 18),
              label: const Text('OPTIMIZE ROUTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLocationDialog({LatLng? pos}) {
    String name = '';
    String role = 'Regular Stop';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ADD LOCATION', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(onChanged: (v) => name = v, decoration: const InputDecoration(labelText: 'Location Name', hintText: 'Shop C, Warehouse 1, etc.')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              items: ['Start Point', 'Regular Stop', 'End Point'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => role = v!,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                Provider.of<RouteProvider>(context, listen: false).addLocation({
                  'name': name,
                  'lat': pos?.latitude,
                  'lng': pos?.longitude,
                  'role': role,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchLocationSheet(),
    );
  }


  Future<void> _launchNavigation(List<Map<String, dynamic>> locations) async {
    if (locations.length < 2) return;
    
    final origin = locations.first;
    final destination = locations.last;
    final waypoints = locations.length > 2 
      ? locations.skip(1).take(locations.length - 2).map((l) => '${l['lat']},${l['lng']}').join('|')
      : '';

    final url = 'https://www.google.com/maps/dir/?api=1&origin=${origin['lat']},${origin['lng']}&destination=${destination['lat']},${destination['lng']}&waypoints=$waypoints&travelmode=driving';
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Google Maps...')));
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some Android versions
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.error('Failed to launch navigation', error: e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open map: $e'), backgroundColor: Colors.red));
    }
  }

  void _showEditLocationDialog(int index, Map<String, dynamic> loc) {
    String role = loc['role'] ?? 'Regular Stop';
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('EDIT ${loc['name'].toString().toUpperCase()}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Change the role of this location in your sequence.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: role,
            items: ['Start Point', 'Regular Stop', 'End Point'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => role = v!,
            decoration: const InputDecoration(labelText: 'Sequence Role'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () {
          Provider.of<RouteProvider>(context, listen: false).removeLocation(index);
          Navigator.pop(context);
        }, child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ElevatedButton(onPressed: () {
          Provider.of<RouteProvider>(context, listen: false).updateLocation(index, {'role': role});
          Navigator.pop(context);
        }, child: const Text('SAVE')),
      ],
    ));
  }


  Widget _buildResultOverlay(RouteProvider prov) {
    if (prov.lastOptimizationResult == null) return const SizedBox.shrink();
    
    final res = prov.lastOptimizationResult!;
    final currency = Provider.of<CurrencyProvider>(context);
    
    // Format time: if < 1 hour, show mins
    double hours = res['total_time'] ?? 0;
    String timeDisplay = hours < 1 
      ? '${(hours * 60).toInt()} mins' 
      : '${hours.toStringAsFixed(1)} hrs';

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 420,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            ListTile(
              title: Text('✅ OPTIMAL ROUTE FOUND', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: prov.clearPlanner),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Distance', '${res['total_distance']?.toStringAsFixed(1) ?? '0'} km'),
                        _buildSummaryItem('Time', timeDisplay),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchNavigation(prov.plannedLocations),
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.all(16)),
                      label: const Text('START NAVIGATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAssignDriverSheet(prov),
                      icon: const Icon(Icons.person_add, color: Color(0xFF1B5E20)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1B5E20)), padding: const EdgeInsets.all(16)),
                      label: const Text('ASSIGN TO DRIVER', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAssignDriverSheet(RouteProvider prov) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    prov.fetchDrivers(auth.currentUser?.businessId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<RouteProvider>(
        builder: (context, p, _) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              _buildDragHandle(),
              const ListTile(
                title: Text('SELECT DRIVER', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Choose which driver will follow this route.'),
              ),
              Expanded(
                child: p.availableDrivers.isEmpty 
                  ? const Center(child: Text('No drivers found for your business.'))
                  : ListView.builder(
                      itemCount: p.availableDrivers.length,
                      itemBuilder: (context, i) {
                        final d = p.availableDrivers[i];
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.person, color: Color(0xFF1B5E20))),
                          title: Text(d.fullName),
                          subtitle: Text(d.phone),
                          onTap: () async {
                            final success = await p.assignRouteToDriver(
                              driverId: d.userId,
                              businessId: d.businessId ?? '',
                              stops: p.plannedLocations,
                              stats: p.lastOptimizationResult!,
                            );
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Route successfully assigned to ${d.fullName}!')));
                              prov.clearPlanner();
                            }
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateMarkers(List<Map<String, dynamic>> locations) {
    _markers.clear();
    for (int i = 0; i < locations.length; i++) {
        final loc = locations[i];
        final isStart = loc['role'] == 'Start Point';
        final isEnd = loc['role'] == 'End Point';
        
        _markers.add(Marker(
          markerId: MarkerId('m_$i'),
          position: LatLng(loc['lat'], loc['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isStart ? BitmapDescriptor.hueGreen : (isEnd ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed),
          ),
          infoWindow: InfoWindow(title: loc['name'], snippet: 'Order: ${i + 1}'),
        ));
    }
  }
}

class SearchLocationSheet extends StatefulWidget {
  const SearchLocationSheet({super.key});

  @override
  State<SearchLocationSheet> createState() => _SearchLocationSheetState();
}

class _SearchLocationSheetState extends State<SearchLocationSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _searchError;
  Timer? _debounce;

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async { // Faster response like Bolt
      if (query.trim().length < 2) {
        setState(() {
          _results = [];
          _searchError = null;
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _searchError = null;
      });

      try {
        final results = await Provider.of<RouteProvider>(context, listen: false).searchLocations(query);
        setState(() {
          _results = results;
          _isLoading = false;
          if (_results.isEmpty && query.length > 2) {
            _searchError = 'No locations found. Try a different search term.';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _searchError = 'Search failed. Please check connection.';
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEARCH LOCATION', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearch,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Where to? Search for places...',
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.search, color: AppColors.primaryGreen, size: 20),
                    ),
                    suffixIcon: _isLoading 
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)))
                      : _controller.text.isNotEmpty 
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                              onPressed: () { _controller.clear(); _onSearch(''); },
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          
          if (_searchError != null && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_searchError!, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),

          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, index) {
                final item = _results[index];
                final mainText = item['structured_formatting']?['main_text'] ?? item['description'];
                final secondaryText = item['structured_formatting']?['secondary_text'] ?? '';
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        setState(() => _isLoading = true);
                        
                        try {
                          LatLng? latLng;
                          if (item['lat'] != null && item['lng'] != null) {
                            latLng = LatLng(item['lat'], item['lng']);
                          } else {
                            latLng = await Provider.of<RouteProvider>(context, listen: false).getPlaceLatLng(item['place_id']);
                          }
                          
                          if (latLng != null && mounted) {
                            Provider.of<RouteProvider>(context, listen: false).addLocation({
                              'name': mainText,
                              'lat': latLng.latitude,
                              'lng': latLng.longitude,
                            });
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _isLoading = false;
                              _searchError = 'Could not get location coordinates. Please try another place.';
                            });
                          }
                        } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location details: $e')));
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mainText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (secondaryText.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      secondaryText,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}
