import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../utils/optimizations_guard.dart';

class BudgetInputScreen extends StatefulWidget {
  const BudgetInputScreen({super.key});

  @override
  State<BudgetInputScreen> createState() => _BudgetInputScreenState();
}

class _BudgetInputScreenState extends State<BudgetInputScreen> {
  double _totalBudget = 1000000; 
  double _productionValue = 40;
  double _logisticsValue = 40;
  double _marketingValue = 20;
  bool _strictCompliance = true;
  int _selectedTab = 0; // 0: Regional, 1: Vendor, 2: Seasonal
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessId;
      if (businessId != null) {
        Provider.of<BudgetProvider>(context, listen: false).fetchBudgets(businessId);
      }
    });
  }

  Future<void> _runBudgetOptimization() async {
    if (_productionValue + _logisticsValue + _marketingValue != 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Departmental allocation must total 100%'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final businessId = authProvider.currentUser?.businessId ?? 'default_biz';

      // Create budget optimization request
      final budgetData = {
        'total_budget': _totalBudget,
        'production_allocation': _productionValue,
        'logistics_allocation': _logisticsValue,
        'marketing_allocation': _marketingValue,
        'strict_compliance': _strictCompliance,
        'regional_allocation': _selectedTab == 0,
        'vendor_split': _selectedTab == 1,
        'seasonal_adjustment': _selectedTab == 2,
      };

      await budgetProvider.solveBudget(businessId: businessId, totalBudget: _totalBudget);

      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.budgetResults);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget optimization failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
            Text(loc?.translate('budget_constraints_title') ?? 'Set Your\nBudget\nConstraints', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(loc?.translate('budget_constraints_desc') ?? 'Optimize resource allocation across West African hubs to maximize throughput while minimizing operational overhead.', 
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 24),

            // Total Budget Amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc?.translate('total_budget_amount') ?? 'TOTAL BUDGET AMOUNT', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Text('${Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.currency ?? 'CFA'} ${(_totalBudget / 1000000).toStringAsFixed(1)}M', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(loc?.translate('budget_rec_desc') ?? 'Recommended based on Q3 Niamey Hub throughput.', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Departmental Allocation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc?.translate('dept_allocation') ?? 'Departmental\nAllocation', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('TOTAL: 100%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAllocationSlider('Production', _productionValue, (v) => setState(() => _productionValue = v), Icons.factory_outlined),
                  _buildAllocationSlider('Logistics', _logisticsValue, (v) => setState(() => _logisticsValue = v), Icons.local_shipping_outlined),
                  _buildAllocationSlider('Marketing', _marketingValue, (v) => setState(() => _marketingValue = v), Icons.campaign_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabs for Allocation Breakdown
            Row(
              children: [
                _buildTab(loc?.translate('regional_allocation') ?? 'Regional\nAllocation', 0),
                _buildTab(loc?.translate('vendor_split') ?? 'Vendor\nSplit', 1),
                _buildTab(loc?.translate('seasonal_adjust') ?? 'Seasonal\nAdjust', 2),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<BusinessProvider>(
              builder: (context, biz, _) {
                final currency = biz.currentBusiness?.currency ?? 'CFA';
                final country = biz.currentBusiness?.country ?? 'Niger';
                final city = biz.currentBusiness?.city ?? 'Niamey';
                return Column(
                  children: [
                    _buildRegionalCard('$city HUB', '$currency ${(_totalBudget * 0.6 / 1000000).toStringAsFixed(1)}M', 'Primary Operations', Icons.location_on, AppColors.successGreen),
                    _buildRegionalCard('$country REGION', '$currency ${(_totalBudget * 0.4 / 1000000).toStringAsFixed(1)}M', 'Regional Distribution', Icons.location_on, AppColors.primaryOrange),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            // Constraints Section
            Text(loc?.translate('constraints') ?? 'Constraints', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildConstraintField(loc?.translate('min_profit_target') ?? 'Min Profit Target', '${Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.currency ?? 'CFA'} 5,000,000', 'Target set for locally optimized hubs.', Icons.trending_up),
            _buildConstraintField(loc?.translate('max_labor_cost') ?? 'Max Labor Cost', '${Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.currency ?? 'CFA'} 2,500,000', 'Includes temporary shift workers for peak periods.', Icons.people_outline),
            
            const SizedBox(height: 24),
            // Strict Compliance Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc?.translate('strict_compliance') ?? 'STRICT COMPLIANCE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                        Text(loc?.translate('compliance_desc') ?? 'Ensure all allocations strictly adhere to regional tax regulations and labor laws.', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _strictCompliance,
                    onChanged: (v) => setState(() => _strictCompliance = v),
                    activeColor: AppColors.primaryOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Run Button
            ElevatedButton(
              onPressed: _runBudgetOptimization,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(loc?.translate('run_budget_opt') ?? 'Run Budget Optimization', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${loc?.translate('est_compute_time') ?? 'Estimated compute time:'} 1.2 seconds', style: const TextStyle(fontSize: 8, color: Colors.white70)),
                    ],
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text('${loc?.translate('syncing_offline') ?? 'OFFLINE SYNC'}: 2M AGO | NIAMEY HUB DATA LOCAL', style: const TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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

  Widget _buildAllocationSlider(String label, double value, ValueChanged<double> onChanged, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${value.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
          ],
        ),
        Slider(
          value: value,
          max: 100,
          onChanged: onChanged,
          activeColor: AppColors.primaryGreen,
          inactiveColor: AppColors.backgroundGray,
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryGreen : Colors.transparent, width: 2)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primaryGreen : AppColors.textLight)),
        ),
      ),
    );
  }

  Widget _buildRegionalCard(String hub, String amount, String status, IconData icon, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.backgroundGray, shape: BoxShape.circle), child: Icon(icon, size: 16, color: AppColors.textLight)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hub, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstraintField(String label, String value, String hint, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textLight),
                const SizedBox(width: 12),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
