import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../utils/app_colors.dart';
import '../../utils/environment.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../providers/admin_provider.dart';

class AnalyticsOverviewScreen extends StatefulWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  State<AnalyticsOverviewScreen> createState() => _AnalyticsOverviewScreenState();
}

class _AnalyticsOverviewScreenState extends State<AnalyticsOverviewScreen> {
  Map<String, int> _regionalBreakdown = {'Niger': 0, 'Nigeria': 0, 'Ghana': 0};
  
  // Map controller for operations density
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();
  GoogleMapController? _mapController;
  
  // Sample operations data for map visualization
  final List<OperationHub> _operationHubs = [
    OperationHub(
      id: 'hub_1',
      name: 'Lagos Hub',
      position: const LatLng(6.5244, 3.3792),
      load: 87,
      status: 'active',
      region: 'Nigeria',
    ),
    OperationHub(
      id: 'hub_2',
      name: 'Abuja Hub',
      position: const LatLng(7.4855, 3.5500),
      load: 65,
      status: 'active',
      region: 'Nigeria',
    ),
    OperationHub(
      id: 'hub_3',
      name: 'Kano Hub',
      position: const LatLng(11.9606, 8.5316),
      load: 45,
      status: 'moderate',
      region: 'Nigeria',
    ),
    OperationHub(
      id: 'hub_4',
      name: 'Accra Hub',
      position: const LatLng(5.6037, -0.1870),
      load: 72,
      status: 'active',
      region: 'Ghana',
    ),
    OperationHub(
      id: 'hub_5',
      name: 'Kumasi Hub',
      position: const LatLng(6.6885, -1.6244),
      load: 38,
      status: 'moderate',
      region: 'Ghana',
    ),
    OperationHub(
      id: 'hub_6',
      name: 'Niamey Hub',
      position: const LatLng(13.5127, 2.1128),
      load: 56,
      status: 'active',
      region: 'Niger',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProv = Provider.of<AdminProvider>(context, listen: false);
      adminProv.fetchGlobalStats();
      adminProv.fetchReports();
      adminProv.fetchOptimizationBreakdown();
      adminProv.fetchRevenueByQuarter();
      _loadRegionalData(adminProv);
    });
  }

  Future<void> _loadRegionalData(AdminProvider prov) async {
    final data = await prov.getRegionalBreakdown();
    if (mounted) {
      setState(() => _regionalBreakdown = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Analytics',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AdminSidebar(selectedRoute: '/admin/analytics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Real-time insights into system performance and user engagement across West Africa.', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
            const SizedBox(height: 24),

            const Text('Network Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (adminProv.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Total Optimizations', adminProv.totalOptimizations.toString(), 'Current', Icons.bolt, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Active Users', adminProv.totalUsers.toString(), 'Live', Icons.people_outline, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Registered Businesses', adminProv.totalBusinesses.toString(), 'Enterprise', Icons.business_outlined, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Open Reports', adminProv.pendingReports.toString(), 'Pending', Icons.report_problem, Colors.red)),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            _buildReportsSummary(adminProv),
            const SizedBox(height: 24),
            _buildGrowthByRegion(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFeatureAdoption(adminProv)),
                const SizedBox(width: 24),
                Expanded(child: _buildRevenueImpact(adminProv)),
              ],
            ),
            const SizedBox(height: 24),
            _buildAccessProfile(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
           const Icon(Icons.analytics_outlined, color: AppColors.primaryGreen),
           const SizedBox(width: 12),
           const Text('Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
           const Spacer(),
           _buildTimeFilter('Last 30 Days'),
           const SizedBox(width: 16),
           const Icon(Icons.download_outlined, color: AppColors.textLight),
           const SizedBox(width: 16),
           const CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/user_avatar.png')),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [const Icon(Icons.calendar_today, size: 14), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), const Icon(Icons.keyboard_arrow_down, size: 16)]),
    );
  }

  Widget _buildMetricCard(String label, String value, String trend, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(trend, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trend.contains('+') ? AppColors.successGreen : (trend.contains('-') ? AppColors.successGreen : AppColors.textLight))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthByRegion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Business Density by Country', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
           const SizedBox(height: 24),
           _buildRegionalBar('Niger 🇳🇪', _regionalBreakdown['Niger'] ?? 0),
           _buildRegionalBar('Nigeria 🇳🇬', _regionalBreakdown['Nigeria'] ?? 0),
           _buildRegionalBar('Ghana 🇬🇭', _regionalBreakdown['Ghana'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildRegionalBar(String country, int count) {
    // Basic scaling for visualization
    double percentage = (count / 100).clamp(0.05, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(country, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text('$count Entities', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.backgroundGray,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsDensity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Operations Density Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
           const SizedBox(height: 24),
           Container(
             height: 300,
             decoration: BoxDecoration(
               color: Colors.grey[100],
               borderRadius: BorderRadius.circular(12),
             ),
             child: GoogleMap(
               initialCameraPosition: const CameraPosition(
                 target: LatLng(13.5127, 2.1128), // Center of West Africa
                 zoom: 5.0,
               ),
               markers: _createOperationMarkers().toSet(),
               circles: _createOperationCircles().toSet(),
               polygons: _createOperationPolygons().toSet(),
               mapType: MapType.normal,
               myLocationEnabled: false,
               zoomControlsEnabled: true,
               onMapCreated: (GoogleMapController controller) {
                 _mapControllerCompleter.complete(controller);
                 _mapController = controller;
               },
             ),
           ),
           const SizedBox(height: 16),
           _buildOperationsLegend(),
        ],
      ),
    );
  }

  Widget _buildOperationsLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Legend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildLegendItem('Active Hub', Colors.green, Icons.circle),
          _buildLegendItem('Moderate Load', Colors.orange, Icons.circle),
          _buildLegendItem('High Load', Colors.red, Icons.circle),
          const SizedBox(height: 8),
          const Text(
            'Click on markers to view hub details',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  List<Marker> _createOperationMarkers() {
    return _operationHubs.map((hub) => Marker(
      markerId: MarkerId(hub.id),
      position: hub.position,
      infoWindow: InfoWindow(
        title: hub.name,
        snippet: 'Load: ${hub.load}%\nStatus: ${hub.status}\nRegion: ${hub.region}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(210.0),
    )).toList();
  }

  List<Circle> _createOperationCircles() {
    return _operationHubs.map((hub) => Circle(
      circleId: CircleId('${hub.id}_circle'),
      center: hub.position,
      radius: _getLoadRadius(hub.load),
      strokeWidth: 2,
      strokeColor: _getLoadColor(hub.load).withOpacity(0.8),
      fillColor: _getLoadColor(hub.load).withOpacity(0.3),
    )).toList();
  }

  List<Polygon> _createOperationPolygons() {
    return _operationHubs.map((hub) {
      final regionHubs = _operationHubs.where((h) => h.region == hub.region).toList();
      if (regionHubs.length > 1) {
        // Create convex hull for regional hubs
        final points = regionHubs.map((h) => h.position).toList();
        return Polygon(
          polygonId: PolygonId('${hub.region}_polygon'),
          points: points,
          strokeWidth: 2,
          strokeColor: Colors.blue.withOpacity(0.6),
          fillColor: Colors.blue.withOpacity(0.2),
        );
      }
      return null;
    }).where((polygon) => polygon != null).cast<Polygon>().toList();
  }

  Color _getLoadColor(double load) {
    if (load >= 80) {
      return Colors.red;
    } else if (load >= 60) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  double _getLoadRadius(double load) {
    return 50000 + (load * 1000); // Radius in meters
  }
}

class OperationHub {
  final String id;
  final String name;
  final LatLng position;
  final double load;
  final String status;
  final String region;

  OperationHub({
    required this.id,
    required this.name,
    required this.position,
    required this.load,
    required this.status,
    required this.region,
  });
}

  Widget _buildFeatureAdoption(AdminProvider adminProv) {
    final byType = adminProv.optimizationByType;
    final total = byType.values.fold(0, (a, b) => a + b);

    // Build bar data: label → count
    final entries = [
      {'label': 'Product Mix', 'count': byType['Product Mix'] ?? 0, 'color': AppColors.primaryGreen},
      {'label': 'Transport', 'count': byType['Transport'] ?? 0, 'color': AppColors.primaryOrange},
      {'label': 'Route', 'count': byType['Route'] ?? 0, 'color': Colors.blue},
      {'label': 'Budget', 'count': byType['Budget'] ?? 0, 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Feature Adoption by Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No optimization data yet.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((e) {
                  final count = e['count'] as int;
                  final pct = total > 0 ? (count / total * 100).round() : 0;
                  return _buildBarChartItem(e['label'] as String, pct.toDouble(), e['color'] as Color);
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          ...entries.map((e) => _buildLegendRow(e['label'] as String, e['color'] as Color)),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 10))]),
    );
  }

  Widget _buildRevenueImpact(AdminProvider adminProv) {
    final qData = adminProv.revenueByQuarter;
    final maxVal = qData.values.fold(0.0, (a, b) => a > b ? a : b);
    final total = adminProv.totalRevenue;
    final totalStr = total >= 1000000
        ? 'CFA ${(total / 1000000).toStringAsFixed(1)}M'
        : total >= 1000
            ? 'CFA ${(total / 1000).toStringAsFixed(0)}k'
            : 'CFA ${total.toInt()}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REVENUE IMPACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 24),
          if (maxVal == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No revenue data yet.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ['Q1', 'Q2', 'Q3', 'Q4'].map((q) {
                  return _buildRevenueBar(q, qData[q] ?? 0, AppColors.primaryGreen, maxVal);
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          Text(totalStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('TOTAL REVENUE (ALL SUBSCRIPTIONS)', style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccessProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACCESS PROFILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 24),
          _buildAccessRow('Mobile App', 0.64),
          _buildAccessRow('Dashboard (Web)', 0.36),
          const SizedBox(height: 24),
          const Text('AVG SESSION', style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
          const Text('N/A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text('Access ratios are estimated. Session tracking coming soon.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildReportsSummary(AdminProvider adminProv) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Report Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryChip('Pending', adminProv.pendingReports.toString(), AppColors.primaryOrange),
              const SizedBox(width: 12),
              _buildSummaryChip('In Review', adminProv.inReviewReports.toString(), Colors.blue),
              const SizedBox(width: 12),
              _buildSummaryChip('Resolved', adminProv.resolvedReports.toString(), AppColors.successGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccessRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12)), Text('${(val * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: val, backgroundColor: AppColors.backgroundGray, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen), minHeight: 4, borderRadius: BorderRadius.circular(2)),
        ],
      ),
    );
  }

  Widget _buildBarChartItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueBar(String label, double value, Color color, double maxVal) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: maxVal > 0 ? (value / maxVal) * 100 : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value >= 1000 ? 'CFA ${(value / 1000).toStringAsFixed(0)}k' : 'CFA ${value.toInt()}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

