import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/optimization_provider.dart';
import '../../models/optimization_result_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transport_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/modals/plan_selection_modal.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load real data as soon as dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessId = authProvider.currentUser?.businessId;
      if (businessId != null) {
        Provider.of<ProductProvider>(context, listen: false).fetchProducts(businessId);
        Provider.of<TransportProvider>(context, listen: false).fetchLocations(businessId);
        Provider.of<BusinessProvider>(context, listen: false).fetchBusinessDetails(businessId);
        Provider.of<OptimizationProvider>(context, listen: false).loadSavedResults(businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final transportProvider = Provider.of<TransportProvider>(context);
    final businessProv = Provider.of<BusinessProvider>(context);

    // REAL NAME LOGIC: Use real name from profile, fallback to "User"
    final String fullName = authProvider.currentUser?.fullName ?? 'User';
    final String firstName = fullName.split(' ')[0];
    final String greetingPrefix = loc?.translate('welcome_user_prefix') ?? 'Sannu';
    final currencySymbol = authProvider.currentUser?.businessId != null 
        ? businessProv.currentBusiness?.currency ?? 'CFA'
        : 'CFA';

    final totalOptimizedSavings = Provider.of<OptimizationProvider>(context).calculateTotalSavings();

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
            Text(loc?.translate('home_title') ?? 'OptiFlow',
              style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(loc?.translate('active_status').toUpperCase() ?? 'OFFLINE MODE',
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              child: Text(firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'U',
                style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greetingPrefix, $firstName!',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc?.translate('dashboard_subtitle') ?? 'Ready to optimize your Niamey hub operations?',
                    style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                  ),
                  if (businessProv.currentBusiness != null && !businessProv.isPremium) ...[
                    const SizedBox(height: 16),
                    _buildTrialBanner(businessProv.currentBusiness!.remainingFreeOptimizations, businessProv.currentBusiness!.businessId),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildQuickStat(Icons.inventory_2_outlined, loc?.translate('total_products') ?? 'TOTAL PRODUCTS',
                        productProvider.products.length.toString()),
                      const SizedBox(width: 12),
                      _buildQuickStat(Icons.location_on_outlined, loc?.translate('active_locations') ?? 'ACTIVE LOCATIONS',
                        transportProvider.locations.length.toString()),
                      const SizedBox(width: 12),
                      _buildQuickStat(Icons.trending_up, loc?.translate('savings_mtd') ?? 'SAVINGS (MTD)', '${businessProv.currentBusiness?.currency ?? 'CFA'} ${totalOptimizedSavings.toStringAsFixed(0)}', isGreen: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Modules Grid
            Text(loc?.translate('ops_optimization') ?? 'Operations Optimization',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildModuleCard(context, loc?.translate('product_mix') ?? 'Product Mix', 'Optimize SKU ratios', Icons.inventory, Colors.orange[50]!, AppRoutes.productList),
                _buildModuleCard(context, loc?.translate('transport') ?? 'Transport Cost', 'Fuel & logistics', Icons.local_shipping, Colors.green[50]!, AppRoutes.transportCostOptimization),
                _buildModuleCard(context, loc?.translate('routes') ?? 'Route Planner', 'Optimal delivery paths', Icons.map, Colors.blue[50]!, AppRoutes.routePlanner),
                _buildModuleCard(context, loc?.translate('budget') ?? 'Budget Optimizer', 'Capital allocation', Icons.account_balance_wallet, Colors.purple[50]!, AppRoutes.budgetInput),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Results
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc?.translate('recent_results') ?? 'Recent Results', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.savedResults),
                  child: Text(loc?.translate('view_all') ?? 'View All', style: const TextStyle(color: AppColors.primaryGreen))),
              ],
            ),
            Consumer<OptimizationProvider>(
              builder: (context, optProv, child) {
                if (optProv.isLoading) return const Center(child: LinearProgressIndicator(color: AppColors.primaryGreen));
                
                final latest = optProv.savedResults.isNotEmpty ? optProv.savedResults.first : null;
                
                if (latest == null) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('No optimization results yet', style: TextStyle(color: AppColors.textLight))),
                  );
                }

                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.savedResults),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: latest.type == 'Product Mix' ? Colors.orange[50] : 
                                   latest.type == 'Transport' ? Colors.green[50] : Colors.blue[50], 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Icon(
                            latest.type == 'Product Mix' ? Icons.inventory_2 : 
                            latest.type == 'Transport' ? Icons.local_shipping : Icons.analytics, 
                            color: latest.type == 'Product Mix' ? Colors.orange : 
                                   latest.type == 'Transport' ? Colors.green : Colors.blue
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc?.translate('last_optimization') ?? 'LAST OPTIMIZATION',
                                style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                              Text(latest.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('ID: ${latest.resultId.split('-').last}',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value, {bool isGreen = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isGreen ? AppColors.successGreen : AppColors.textLight),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: AppColors.textLight)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isGreen ? AppColors.successGreen : AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.black87),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialBanner(int remaining, String bizId) {
    final isCritical = remaining <= 5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCritical ? Colors.yellow.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCritical ? Colors.yellow.shade700 : Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.stars, color: isCritical ? Colors.orange.shade800 : Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCritical
                  ? 'Only $remaining free optimizations left. Upgrade for unlimited.'
                  : '$remaining free optimizations remaining.',
              style: TextStyle(
                color: isCritical ? Colors.orange.shade900 : Colors.blue.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (isCritical)
            TextButton(
              onPressed: () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, controller) => SingleChildScrollView(
                      controller: controller,
                      child: PlanSelectionModal(
                        businessId: bizId,
                        email: auth.currentUser?.email ?? '',
                        onPaymentSuccess: (sub, txn) async {
                          final bizProv = Provider.of<BusinessProvider>(context, listen: false);
                          await bizProv.updateSubscription(sub, txn);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                );
              },
              child: Text('UPGRADE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
            )
        ],
      ),
    );
  }
}
