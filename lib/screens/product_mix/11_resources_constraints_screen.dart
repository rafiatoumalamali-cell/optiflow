import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../routes/app_routes.dart';
import '../../utils/optimizations_guard.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/resource_model.dart';

class ResourceConstraintsScreen extends StatefulWidget {
  const ResourceConstraintsScreen({super.key});

  @override
  State<ResourceConstraintsScreen> createState() => _ResourceConstraintsScreenState();
}

class _ResourceConstraintsScreenState extends State<ResourceConstraintsScreen> {
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
        title: const Text('Resource Constraints', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProv, child) {
          final resources = productProv.resources;
          
          return Column(
            children: [
          // Info Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Resources are the raw materials, labor, and machine time available for production. Enter your maximum available quantities.',
                    style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Current Audit Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT AUDIT', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                    Text('${resources.length} resources\ndefined', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddResourceDialog(context, productProv),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Resource', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Resources List
          Expanded(
            child: resources.isEmpty 
              ? const Center(child: Text('No resources defined. Add constraints like Space or Weight.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final res = resources[index];
                    return _buildResourceCard(
                      'Defined Resource', 
                      res.name, 
                      res.availableQuantity.toString(), 
                      res.unit, 
                      0.0, // Allocation will be set by the result
                      () => productProv.deleteResource(res.resourceId)
                    );
                  },
              ),
          ),
          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Save Resources',
                    icon: Icons.save,
                    onPressed: () => OptimizationGuard.checkAndNavigate(context, AppRoutes.productMixResults),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.bolt, color: Colors.white),
                ),
              ],
            ),
          ),
          _buildModuleNav(),
        ],
      );
     }),
    );
  }

  Future<void> _showAddResourceDialog(BuildContext context, ProductProvider prov) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Resource Constraint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Resource Name (e.g., Space, Weight)')),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available Capacity (Max limit)')),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g., kg, cubic meters)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final String val = qtyCtrl.text.trim();
              if (nameCtrl.text.isNotEmpty && val.isNotEmpty) {
                prov.addResource(ResourceModel(
                  resourceId: const Uuid().v4(),
                  businessId: auth.currentUser?.businessId ?? 'default',
                  name: nameCtrl.text.trim(),
                  availableQuantity: double.tryParse(val) ?? 0.0,
                  unit: unitCtrl.text.trim(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  Widget _buildResourceCard(String category, String name, String value, String unit, double allocation, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                  ),
                ],
              ),
            ],
          ),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(unit, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Allocation', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  Text('${(allocation * 100).toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: allocation > 0.8 ? AppColors.errorRed : AppColors.successGreen)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: allocation,
            backgroundColor: AppColors.backgroundGray,
            valueColor: AlwaysStoppedAnimation<Color>(allocation > 0.8 ? AppColors.errorRed : AppColors.successGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.inventory_2_outlined, 'INVENTORY'),
          _buildNavIcon(Icons.bolt, 'OPTIMIZE', isActive: true),
          _buildNavIcon(Icons.source_outlined, 'RESOURCES'),
          _buildNavIcon(Icons.analytics_outlined, 'ANALYTICS'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: isActive ? AppColors.primaryGreen : AppColors.textLight),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isActive ? AppColors.primaryGreen : AppColors.textLight)),
      ],
    );
  }
}
