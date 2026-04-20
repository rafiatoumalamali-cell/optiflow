import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../../providers/optimization_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../models/optimization_result_model.dart';

class SavedResultsScreen extends StatefulWidget {
  const SavedResultsScreen({super.key});

  @override
  State<SavedResultsScreen> createState() => _SavedResultsScreenState();
}

class _SavedResultsScreenState extends State<SavedResultsScreen> {
  int _currentIndex = 1;
  String _selectedCategory = 'All';

  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessId = authProvider.currentUser?.businessId;
      if (businessId != null) {
        Provider.of<OptimizationProvider>(context, listen: false).loadSavedResults(businessId);
        Provider.of<RouteProvider>(context, listen: false).fetchRoutes(businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Saved Results', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search saved scenarios...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.textLight),
                ),
              ),
            ),
          ),
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Product Mix'),
                _buildCategoryChip('Routes'),
                _buildCategoryChip('Transport'),
                _buildCategoryChip('Budget'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Results List
          Expanded(
            child: Consumer2<OptimizationProvider, RouteProvider>(
              builder: (context, optimizationProvider, routeProvider, child) {
                if (optimizationProvider.isLoading || routeProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                var results = optimizationProvider.savedResults;
                var routes = routeProvider.routes;
                
                // Combine and filter
                List<dynamic> combinedList = [];
                if (_selectedCategory == 'All' || _selectedCategory == 'Product Mix' || _selectedCategory == 'Transport' || _selectedCategory == 'Budget') {
                  combinedList.addAll(results.where((r) => _selectedCategory == 'All' || r.type == _selectedCategory));
                }
                if (_selectedCategory == 'All' || _selectedCategory == 'Routes') {
                  combinedList.addAll(routes);
                }

                if (combinedList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No results found for $_selectedCategory', style: const TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: combinedList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final item = combinedList[index];
                    if (item is OptimizationResultModel) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMappedResultCard(item),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRouteResultCard(item),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.homeDashboard);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildMappedResultCard(OptimizationResultModel model) {
    Color accentColor;
    Color bgColor;
    String metricLabel = 'Result';
    String metricValue = 'View Details';
    IconData icon = Icons.bar_chart;

    switch (model.type) {
      case 'Product Mix':
        accentColor = Colors.orange;
        bgColor = Colors.orange[50]!;
        metricLabel = 'Optimized Profit';
        metricValue = 'CFA ${model.resultData['total_profit'] ?? 0}';
        icon = Icons.inventory_2;
        break;
      case 'Transport':
        accentColor = Colors.green;
        bgColor = Colors.green[50]!;
        metricLabel = 'Minimum Cost';
        metricValue = 'CFA ${model.resultData['total_cost'] ?? 0}';
        icon = Icons.local_shipping;
        break;
      case 'Budget':
        accentColor = Colors.purple;
        bgColor = Colors.purple[50]!;
        metricLabel = 'Allocated Capital';
        metricValue = 'CFA ${model.resultData['allocated_budget'] ?? 0}';
        icon = Icons.account_balance_wallet;
        break;
      default:
        accentColor = Colors.blue;
        bgColor = Colors.blue[50]!;
    }

    final dateStr = '${model.createdAt.day} ${_getMonth(model.createdAt.month)} ${model.createdAt.year}';

    return _buildResultCard(
      model.type,
      'Scenario: ${model.resultId.split('-').last}',
      metricLabel,
      metricValue,
      dateStr,
      bgColor,
      accentColor,
      onTap: () {
         // Logic to navigate back to the specific result screen with this data
         // In a full implementation, we'd pass the model as an argument
      }
    );
  }

  Widget _buildRouteResultCard(dynamic route) {
    final date = route.createdAt;
    final dateStr = '${date.day} ${_getMonth(date.month)} ${date.year}';
    
    return _buildResultCard(
      'Logistics Route',
      'Route ID: ${route.routeId.split('-').last}',
      'Performance',
      route.status.toUpperCase(),
      dateStr,
      Colors.blue[50]!,
      Colors.blue,
      onTap: () => _showRoutePODDetails(route),
    );
  }

  void _showRoutePODDetails(dynamic route) {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    routeProvider.fetchStopsForRoute(route.routeId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Consumer<RouteProvider>(
          builder: (context, p, _) => Column(
            children: [
               _buildDragHandle(),
               ListTile(
                 title: Text('ROUTE RECAP: ${route.routeId.split('-').last}', style: const TextStyle(fontWeight: FontWeight.bold)),
                 subtitle: Text('${route.originId} → ${route.destinationId}'),
               ),
               const Divider(),
               Expanded(
                 child: p.isLoading 
                   ? const Center(child: CircularProgressIndicator())
                   : ListView.builder(
                       itemCount: p.currentRouteStops.length,
                       itemBuilder: (context, i) {
                         final s = p.currentRouteStops[i];
                         return ListTile(
                           leading: Icon(
                             s.status == 'Completed' ? Icons.check_circle : Icons.pending,
                             color: s.status == 'Completed' ? AppColors.successGreen : Colors.grey,
                           ),
                           title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                           subtitle: Text('Status: ${s.status}', style: const TextStyle(fontSize: 10)),
                           trailing: s.status == 'Completed' ? const Icon(Icons.arrow_forward_ios, size: 12) : null,
                           onTap: s.status == 'Completed' ? () => _showStopPOD(s) : null,
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

  void _showStopPOD(dynamic stop) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Proof of Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (stop.podUrl != null) ...[
                    const Text('DELIVERY PHOTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(stop.podUrl!, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 50)),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (stop.signatureUrl != null) ...[
                    const Text('DIGITAL SIGNATURE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Image.network(stop.signatureUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.draw, size: 50)),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
            const SizedBox(height: 8),
          ],
        ),
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

  String _getMonth(int m) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[m - 1];
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _updateCategory(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String subtitle, String metricLabel, String metricValue, String date, Color bgColor, Color accentColor, {required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                      title == 'Product Mix' ? Icons.inventory_2 : 
                      title == 'Transport' ? Icons.local_shipping : 
                      Icons.account_balance_wallet,
                      color: accentColor, 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    ],
                  ),
                ],
              ),
              Text(date, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(metricLabel, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                Text(metricValue, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Deep Dive ↗', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
