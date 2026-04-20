import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../providers/optimization_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart' as custom;

class BudgetResultsScreen extends StatefulWidget {
  const BudgetResultsScreen({super.key});

  @override
  State<BudgetResultsScreen> createState() => _BudgetResultsScreenState();
}

class _BudgetResultsScreenState extends State<BudgetResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _solve());
  }

  Future<void> _solve() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final optiProv = Provider.of<OptimizationProvider>(context, listen: false);

    // Default to 1M if none provided (for demo)
    await optiProv.solveBudget(
      businessId: auth.currentUser?.businessId ?? 'default',
      totalBudget: 1000000.0, 
    );
  }

  @override
  Widget build(BuildContext context) {
    final optiProv = Provider.of<OptimizationProvider>(context);
    final currencyProv = Provider.of<CurrencyProvider>(context);
    final resultData = optiProv.lastResult?.resultData;
    final symbol = currencyProv.currencySymbol;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: optiProv.isLoading
          ? LoadingIndicator(message: 'Optimizing Capital Allocation...')
          : optiProv.errorMessage != null
              ? Center(
                  child: custom.ErrorContainer(
                    message: optiProv.errorMessage!,
                    onRetry: _solve,
                  ),
                )
              : resultData == null
                  ? const Center(child: Text('No optimization data found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              const Text('Optimal Budget\nAllocation', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              const Icon(Icons.check_circle, color: AppColors.successGreen, size: 24),
                            ],
                          ),
                          const Text(
                            'Strategic distribution calculated based on Q3 logistics demand and current fuel volatility in West African corridors.',
                            style: TextStyle(fontSize: 12, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildSmallActionBtn(Icons.picture_as_pdf_outlined, 'Export PDF'),
                              const SizedBox(width: 8),
                              _buildSmallActionBtn(Icons.save_outlined, 'Save Budget'),
                              const SizedBox(width: 8),
                              _buildApplyButton(),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Primary Metrics
                          _buildMainMetricCard(
                            'TOTAL BUDGET', 
                            '$symbol ${(1000000.0).toStringAsFixed(0)}', 
                            '↘ 5% from last cycle', 
                            AppColors.successGreen
                          ),
                          const SizedBox(height: 16),
                          _buildMainMetricCard(
                            'EXPECTED ROI', 
                            resultData['expected_roi'] ?? '0%', 
                            'Q High efficiency rating', 
                            AppColors.primaryOrange, 
                            icon: Icons.trending_up
                          ),
                          const SizedBox(height: 16),
                          _buildMainMetricCard(
                            'REMAINING BUFFER', 
                            '$symbol 50,000', 
                            '5.0% Risk mitigation', 
                            AppColors.textDark, 
                            icon: Icons.shield_outlined
                          ),
                          
                          const SizedBox(height: 32),
                          // Allocation by Department
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Allocation by\nDepartment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Row(
                                children: [
                                  Icon(Icons.fiber_manual_record, color: AppColors.primaryGreen, size: 8),
                                  SizedBox(width: 4),
                                  Text('CURRENT\nRECOMMENDATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (resultData['allocation'] != null)
                            ... (resultData['allocation'] as Map<String, dynamic>).entries.map((e) {
                              // Calculate percentage relative to total if total is 1M (for simplicity in display)
                              double val = (e.value as num).toDouble() / 1000000.0;
                              return _buildDepartmentProgress(e.key, val);
                            }).toList(),

                          const SizedBox(height: 32),
                          // Regional Breakdown
                          const Text('Regional Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildRegionalRow('Niamey, Niger', 'Hub Operations', '$symbol 3,200,000'),
                          _buildRegionalRow('Accra, Ghana', 'Coastal Logistics', '$symbol 1,500,000'),

                          const SizedBox(height: 24),
                          // Optimization Insight
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline, color: AppColors.primaryOrange, size: 20),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Allocating more to the Niamey-Kano corridor could boost ROI by an additional 1.2% based on current custom clearance trends.',
                                    style: TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
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

  Widget _buildSmallActionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textDark),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(8)),
      child: const Row(
        children: [
          Icon(Icons.check, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('Apply\nBudget', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainMetricCard(String label, String value, String subLabel, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: color, width: 4))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subLabel, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (icon != null) Icon(icon, color: Colors.grey[300], size: 32),
        ],
      ),
    );
  }

  Widget _buildDepartmentProgress(String name, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.backgroundGray,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalRow(String city, String type, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(type, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
        ],
      ),
    );
  }
}
