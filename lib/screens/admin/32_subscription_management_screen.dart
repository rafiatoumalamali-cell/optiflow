import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../providers/admin_provider.dart';
import '../../models/plan_model.dart';
import '../../models/subscription_model.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();
      adminProvider.fetchPlans();
      adminProvider.fetchSubscriptions();
      adminProvider.initializeDefaultPlans(); // Initialize default plans if needed
    });
  }

  @override
  Widget build(BuildContext context) {
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
              'Subscriptions',
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
      drawer: const AdminSidebar(selectedRoute: '/admin/subscriptions'),
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     AppBar().preferredSize.height - 
                     MediaQuery.of(context).padding.top,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         AppBar().preferredSize.height - 
                         MediaQuery.of(context).padding.top - 
                         32, // Account for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subscription Plans', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Manage multi-region pricing tiers and global service accessibility.', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Add Plan'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Consumer<AdminProvider>(
                    builder: (context, adminProvider, child) {
                      if (adminProvider.isPlansLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Column(
                        children: adminProvider.plans.map((plan) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildPlanCard(
                              plan.name,
                              '${plan.currency} ${plan.price.toInt()}',
                              plan.features,
                              isFree: plan.price == 0,
                              isPopular: plan.isPopular,
                              isEnterprise: plan.name == 'ENTERPRISE',
                              plan: plan,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSubscriptionAnalytics(context.read<AdminProvider>()),
                  const SizedBox(height: 24),
                  _buildPaymentMethods(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          const Text('Plan Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Text('CURRENCY: ', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                Text('XOF (CFA)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Icon(Icons.keyboard_arrow_down, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/user_avatar.png')),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, List<String> features, {bool isFree = false, bool isPopular = false, bool isEnterprise = false, PlanModel? plan}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isPopular ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(20)),
              child: const Text('MOST POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: isPopular ? Colors.white : AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold)),
              if (plan != null && !isFree)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showEditPlanDialog(plan),
                      icon: Icon(Icons.edit, color: isPopular ? Colors.white : AppColors.textLight, size: 18),
                    ),
                    IconButton(
                      onPressed: () => _showDeletePlanDialog(plan),
                      icon: Icon(Icons.delete, color: isPopular ? Colors.white : AppColors.errorRed, size: 18),
                    ),
                  ],
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(color: isPopular ? Colors.white : AppColors.textDark, fontSize: 32, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                child: Text('/mo', style: TextStyle(color: isPopular ? Colors.white70 : AppColors.textLight, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(Icons.check_circle, color: isPopular ? Colors.white : AppColors.primaryGreen, size: 18),
              const SizedBox(width: 12),
              Text(f, style: TextStyle(color: isPopular ? Colors.white : AppColors.textDark, fontSize: 13)),
            ]),
          )).toList(),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(onPressed: () {}, child: Text('Edit', style: TextStyle(color: isPopular ? Colors.white : AppColors.textLight, fontWeight: FontWeight.bold))),
              const Spacer(),
              _buildSmallButton(isPopular ? 'Deactivate' : 'Deactivate', isPopular),
              const SizedBox(width: 12),
              _buildSmallButton('Active', isPopular, isOutline: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String label, bool isPopular, {bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : (isPopular ? Colors.white.withOpacity(0.2) : AppColors.backgroundGray),
        borderRadius: BorderRadius.circular(8),
        border: isOutline ? Border.all(color: isPopular ? Colors.white : Colors.grey.shade300) : null,
      ),
      child: Text(label, style: TextStyle(color: isPopular ? Colors.white : AppColors.textDark, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSubscriptionAnalytics(AdminProvider adminProvider) {
    final totalSubs = adminProvider.subscriptions.length;
    final activeSubs = adminProvider.activeSubscriptions;
    final revenue = adminProvider.totalRevenue;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subscription\nAnalytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MONTHLY RECURRING REVENUE', style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                  Text('CFA ${revenue.toInt().toString()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Donut Chart with real data
          Container(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                 SizedBox(
                   width: 120, 
                   height: 120, 
                   child: CircularProgressIndicator(
                     value: totalSubs > 0 ? activeSubs / totalSubs : 0, 
                     strokeWidth: 15, 
                     color: AppColors.primaryGreen, 
                     backgroundColor: Colors.orange.shade200
                   )
                 ),
                 Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$activeSubs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('ACTIVE SUBS', style: const TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                 ]),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildLegendRow('Active', '$activeSubs (${((activeSubs/totalSubs)*100).toInt()}%)', AppColors.primaryGreen),
          _buildLegendRow('Expired', '${adminProvider.expiredSubscriptions} (${((adminProvider.expiredSubscriptions/totalSubs)*100).toInt()}%)', AppColors.primaryOrange),
          _buildLegendRow('Free Tier', '13% (162)', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPaymentToggle('Orange Money', 'Regional Gateway', true),
          _buildPaymentToggle('Moov Money', 'Cross-border Sync', true),
          _buildPaymentToggle('Airtel Money', 'Direct Deposit', false),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textDark, minimumSize: const Size(double.infinity, 50)),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentToggle(String name, String subtitle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 40, height: 24, decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
          ),
          Switch(value: isActive, onChanged: (v) {}, activeColor: AppColors.primaryGreen),
        ],
      ),
    );
  }

  void _showEditPlanDialog(PlanModel plan) {
    final nameController = TextEditingController(text: plan.name);
    final priceController = TextEditingController(text: plan.price.toString());
    final featuresController = TextEditingController(text: plan.features.join(', '));
    final descriptionController = TextEditingController(text: plan.description);
    final maxUsersController = TextEditingController(text: plan.maxUsers.toString());
    final maxDeliveriesController = TextEditingController(text: plan.maxDeliveries.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Plan: ${plan.name}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Plan Name')),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                  TextField(controller: featuresController, decoration: const InputDecoration(labelText: 'Features (comma-separated)'), maxLines: 3),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  TextField(controller: maxUsersController, decoration: const InputDecoration(labelText: 'Max Users'), keyboardType: TextInputType.number),
                  TextField(controller: maxDeliveriesController, decoration: const InputDecoration(labelText: 'Max Deliveries'), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updatedPlan = PlanModel(
                  planId: plan.planId,
                  name: nameController.text,
                  price: double.tryParse(priceController.text) ?? plan.price,
                  features: featuresController.text.split(',').map((f) => f.trim()).toList(),
                  description: descriptionController.text,
                  maxUsers: int.tryParse(maxUsersController.text) ?? plan.maxUsers,
                  maxDeliveries: int.tryParse(maxDeliveriesController.text) ?? plan.maxDeliveries,
                  isPopular: plan.isPopular,
                  currency: plan.currency,
                  hasAdvancedFeatures: plan.hasAdvancedFeatures,
                  hasPrioritySupport: plan.hasPrioritySupport,
                );

                final success = await context.read<AdminProvider>().updatePlan(updatedPlan);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan updated successfully')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlanDialog(PlanModel plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Plan: ${plan.name}'),
          content: Text('Are you sure you want to delete the ${plan.name} plan? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<AdminProvider>().deletePlan(plan.planId);
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan deleted successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
