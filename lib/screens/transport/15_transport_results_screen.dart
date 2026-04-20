import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../providers/optimization_provider.dart';
import '../../providers/transport_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart' as custom;

class TransportResultsScreen extends StatefulWidget {
  const TransportResultsScreen({super.key});

  @override
  State<TransportResultsScreen> createState() => _TransportResultsScreenState();
}

class _TransportResultsScreenState extends State<TransportResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _solve());
  }

  Future<void> _solve() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final transportProv = Provider.of<TransportProvider>(context, listen: false);
    final optiProv = Provider.of<OptimizationProvider>(context, listen: false);

    await optiProv.solveTransport(
      businessId: auth.currentUser?.businessId ?? 'default',
      supplyPoints: transportProv.supplyPoints,
      demandPoints: transportProv.demandPoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final optiProv = Provider.of<OptimizationProvider>(context);
    final resultData = optiProv.lastResult?.resultData;

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
          ? LoadingIndicator(message: 'Analyzing West African Trade Corridors...')
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
                          // Header Section
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                (resultData['status'] ?? 'Success').toUpperCase(), 
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Optimal Transport\nPlan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          Text(
                            resultData['message'] ?? 'Optimization completed successfully.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildSmallActionBtn(Icons.save_outlined, 'Save Result'),
                              const SizedBox(width: 8),
                              _buildSmallActionBtn(Icons.picture_as_pdf_outlined, 'Export PDF'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Primary Metrics
                          _buildMetricCard(
                            'TOTAL TRANSPORT COST',
                            'CFA ${(resultData['total_cost'] ?? 1200000).toStringAsFixed(0)}',
                            '${(resultData['cost_reduction'] ?? 12).toStringAsFixed(0)}% lower than last period',
                            AppColors.successGreen,
                            isLarge: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'TOTAL DISTANCE',
                                  '${(resultData['total_distance'] ?? 1200).toStringAsFixed(0)} km',
                                  'OPTIMIZED',
                                  AppColors.primaryOrange,
                                  showProgress: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMetricCard(
                                  'FUEL REQUIRED',
                                  '${(resultData['fuel_required'] ?? 200).toStringAsFixed(0)}L',
                                  'Estimated consumption:\n${(resultData['fuel_efficiency'] ?? 16.6).toStringAsFixed(1)}L/100km',
                                  AppColors.primaryGreen,
                                  icon: Icons.local_gas_station,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Route Allocation Table
                          const Text('Route\nAllocation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('ORIGIN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight))),
                                    Expanded(flex: 2, child: Text('DESTINATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight))),
                                    Expanded(flex: 2, child: Text('VEHICLE\nTYPE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight))),
                                  ],
                                ),
                                const Divider(),
                                _buildRouteRow('🇳🇪 Niamey', '🇳🇬 Kano', 'Heavy Duty\nTrailer'),
                                _buildRouteRow('🇳🇪 Maradi', '🇳🇬 Katsina', 'Medium\nRigid Truck'),
                                _buildRouteRow('🇳🇪 Zinder', '🇳🇬 Maiduguri', 'Heavy Duty\nTrailer'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Visualization Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.primaryGreen.withOpacity(0.1),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 30),
                                Text('Route Network\nVisualization', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Visualizing optimized corridors across West Africa', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Final Action
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Plan Routes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textDark),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subLabel, Color color, {bool isLarge = false, bool showProgress = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isLarge ? Colors.white : (icon != null ? AppColors.primaryGreen : Colors.white), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: Colors.white, size: 24),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: icon != null ? Colors.white70 : AppColors.textLight)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: isLarge ? 28 : 20, fontWeight: FontWeight.bold, color: icon != null ? Colors.white : color)),
          const SizedBox(height: 4),
          if (showProgress) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.7, backgroundColor: AppColors.backgroundGray, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4, borderRadius: BorderRadius.circular(2)),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: Text(subLabel, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight))),
          ] else
            Text(subLabel, style: TextStyle(fontSize: 10, color: icon != null ? Colors.white.withOpacity(0.8) : color, fontWeight: isLarge ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildRouteRow(String origin, String destination, String vehicle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(origin, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(destination, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(vehicle, style: const TextStyle(fontSize: 10, color: AppColors.textLight))),
        ],
      ),
    );
  }
}
