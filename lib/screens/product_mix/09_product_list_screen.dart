import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/optimization_provider.dart';
import '../../routes/app_routes.dart';
import '../../models/product_model.dart';
import '../../models/resource_model.dart';
import '../../models/product_resource_model.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../utils/logger.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final businessId = auth.currentUser?.businessId;
      
      if (businessId != null && businessId.isNotEmpty) {
        productProvider.fetchProducts(businessId);
        productProvider.fetchResources(businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
                    children: [
                      _buildStrategyDashboardCard(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Current Products', 'Manage your mix'),
                      const SizedBox(height: 16),
                      if (productProvider.isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                        ))
                      else if (productProvider.products.isEmpty)
                        _buildEmptyState('No products added yet', 'Tap + to add your first product')
                      else
                        ...productProvider.products.map((p) => _buildProductCard(p)).toList(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Available Resources', 'Weekly constraints'),
                      const SizedBox(height: 16),
                      if (productProvider.resources.isEmpty)
                        _buildEmptyState('No resources defined', 'Add machines or man-hours below')
                      else
                        ...productProvider.resources.map((r) => _buildResourceCard(r)).toList(),
                    ],
                  ),
                ),
              ],
            ),
            _buildBottomActionOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: _showAddProductDialog,
          backgroundColor: const Color(0xFF1B5E20),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRODUCT MIX', style: GoogleFonts.outfit(color: const Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Text('Optimization', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
            ],
          ),
          Consumer2<AuthProvider, BusinessProvider>(
            builder: (context, auth, biz, _) {
              final initials = auth.currentUser?.fullName.isNotEmpty == true 
                ? auth.currentUser!.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                : 'U';
              return CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(initials, style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyDashboardCard() {
    final optiProv = Provider.of<OptimizationProvider>(context);
    final bizProv = Provider.of<BusinessProvider>(context);
    final currencySymbol = bizProv.currentBusiness?.currency ?? 'CFA';
    final lastResult = optiProv.lastResult;
    final lastData = lastResult?.resultData;
    final String profit = (lastData?['total_profit'] ?? 0.0).toStringAsFixed(2);
    final String efficiency = lastResult != null ? '98.5%' : '---';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lastResult != null ? 'LAST OPTIMIZATION RESULT' : 'READY TO ANALYZE', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('Strategy Dashboard', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMetricItem('PROJECTED PROFIT', '$currencySymbol $profit'),
              const SizedBox(width: 12),
              _buildMetricItem('EFFICIENCY', efficiency),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78909C))),
          ],
        ),
        if (title == 'Available Resources')
           TextButton.icon(
            onPressed: _showAddResourceDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Resource'),
           ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECEFF1))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Profit: ${Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.currency ?? 'CFA'} ${product.profitMargin.toStringAsFixed(2)} / ${product.unit}', style: GoogleFonts.inter(color: const Color(0xFF78909C), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF546E7A), size: 20),
            onPressed: () => _showAddProductDialog(product: product),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _showDeleteConfirmation('product', product.name, product.productId),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    String symbol = resource.constraintType == 'LE' ? '≤' : (resource.constraintType == 'GE' ? '≥' : '=');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFECEFF1))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.settings_outlined, color: Color(0xFF546E7A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Capacity: $symbol ${resource.availableQuantity} ${resource.unit}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF78909C))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF546E7A), size: 18),
            onPressed: () => _showAddResourceDialog(resource: resource),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            onPressed: () => _showDeleteConfirmation('resource', resource.name, resource.resourceId),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String type, String name, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final productProv = Provider.of<ProductProvider>(context, listen: false);
              if (type == 'product') {
                await productProv.deleteProduct(id);
              } else {
                await productProv.deleteResource(id);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: const Color(0xFFECEFF1).withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFECEFF1))),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF546E7A))),
          Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF90A4AE))),
        ],
      ),
    );
  }

  Widget _buildBottomActionOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.96), border: const Border(top: BorderSide(color: Color(0xFFECEFF1))), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _showClearAllConfirmation,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFFECEFF1))),
                child: Text('Clear All', style: GoogleFonts.outfit(color: const Color(0xFF546E7A), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.productMixResults),
                icon: const Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                label: Text('Optimize Mix', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Delete all products and requirements permanently?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final productProv = Provider.of<ProductProvider>(context, listen: false);
              final optiProv = Provider.of<OptimizationProvider>(context, listen: false);
              await productProv.clearAllBusinessData(auth.currentUser?.businessId ?? '');
              optiProv.clearResult();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductSheet(onSaved: () => _loadData(), initialProduct: product),
    );
  }

  void _showAddResourceDialog({ResourceModel? resource}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddResourceSheet(onSaved: () => _loadData(), initialResource: resource),
    );
  }
}

class AddResourceSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final ResourceModel? initialResource;
  const AddResourceSheet({super.key, required this.onSaved, this.initialResource});

  @override
  State<AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends State<AddResourceSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  String _unit = 'hours';
  String _constraintType = 'LE';

  @override
  void initState() {
    super.initState();
    if (widget.initialResource != null) {
      _nameCtrl.text = widget.initialResource!.name;
      _qtyCtrl.text = widget.initialResource!.availableQuantity.toString();
      _unit = widget.initialResource!.unit;
      _constraintType = widget.initialResource!.constraintType;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(widget.initialResource != null ? 'EDIT RESOURCE' : 'ADD RESOURCE CONSTRAINT', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildFormRow('Resource Name:', _nameCtrl, 'e.g. Space'),
                   const SizedBox(height: 24),
                   _buildFormRow('Available Quantity:', _qtyCtrl, 'e.g. 400', isNumber: true),
                   const SizedBox(height: 24),
                   _buildDropdownRow('Unit of measurement:', _unit, ['hours', 'kg', 'liters', 'units', 'cubic meters'], (v) => setState(() => _unit = v!)),
                   const SizedBox(height: 32),
                   Text('CONSTRAINT TYPE:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF78909C), letterSpacing: 1)),
                   const SizedBox(height: 16),
                   _buildRadio('Less than or equal (≤)', 'LE'),
                   _buildRadio('Greater than or equal (≥)', 'GE'),
                   _buildRadio('Equal (=)', 'EQ'),
                   const SizedBox(height: 48),
                   Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)))),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(widget.initialResource != null ? 'UPDATE RESOURCE' : 'SAVE RESOURCE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Building Helper Methods
  Widget _buildFormRow(String label, TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF1F4F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(value: value, isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _buildRadio(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: GoogleFonts.inter(fontSize: 14)),
      value: value, groupValue: _constraintType,
      activeColor: const Color(0xFF1B5E20),
      onChanged: (v) => setState(() => _constraintType = v!),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _save() async {
    try {
      if (_nameCtrl.text.trim().isEmpty || _qtyCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and quantity')));
        return;
      }
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final businessId = auth.currentUser?.businessId;
      
      if (businessId == null || businessId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Business ID missing.')));
        return;
      }

      final resource = ResourceModel(
        resourceId: widget.initialResource?.resourceId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        businessId: businessId,
        name: _nameCtrl.text.trim(),
        availableQuantity: double.tryParse(_qtyCtrl.text) ?? 0.0,
        unit: _unit,
        constraintType: _constraintType,
        createdAt: widget.initialResource?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialResource != null) {
        await productProvider.updateResource(resource);
      } else {
        await productProvider.addResource(resource);
      }

      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class AddProductSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final ProductModel? initialProduct;
  const AddProductSheet({super.key, required this.onSaved, this.initialProduct});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _profitCtrl = TextEditingController();
  String _selectedUnit = 'unit';
  final List<Map<String, dynamic>> _activeReqs = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _nameCtrl.text = widget.initialProduct!.name;
      _profitCtrl.text = widget.initialProduct!.profitMargin.toString();
      _selectedUnit = widget.initialProduct!.unit;
      _loadRequirements();
    }
  }

  Future<void> _loadRequirements() async {
    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final resProv = Provider.of<ProductProvider>(context, listen: false);
    
    await prodProv.fetchProductRequirements(widget.initialProduct!.productId);
    final reqs = prodProv.productRequirements[widget.initialProduct!.productId] ?? [];
    
    if (mounted) {
      setState(() {
        for (var req in reqs) {
          final resource = resProv.resources.firstWhere((r) => r.resourceId == req.resourceId, orElse: () => ResourceModel(resourceId: '', businessId: '', name: 'Unknown', availableQuantity: 0, unit: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
          _activeReqs.add({
            'nameController': TextEditingController(text: resource.name),
            'qtyController': TextEditingController(text: req.quantityRequired.toString()),
            'unitController': TextEditingController(text: resource.unit),
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _profitCtrl.dispose();
    for (var r in _activeReqs) {
      r['nameController']?.dispose();
      r['qtyController']?.dispose();
      r['unitController']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.initialProduct != null ? 'EDIT PRODUCT' : 'ADD NEW PRODUCT', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInternalInput('Product Name:', _nameCtrl, 'e.g. Fragile Goods'),
                  const SizedBox(height: 24),
                  _buildInternalInput('Profit per unit (${Provider.of<BusinessProvider>(context, listen: false).currentBusiness?.currency ?? 'CFA'}):', _profitCtrl, 'e.g. 100', isNumber: true),
                  const SizedBox(height: 24),
                  _buildDropdownRow('Unit of measurement:', _selectedUnit, ['unit', 'tonne', 'kg', 'liter'], (v) => setState(() => _selectedUnit = v!)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RESOURCE REQUIREMENTS:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF78909C), letterSpacing: 1)),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                             _activeReqs.add({
                               'nameController': TextEditingController(),
                               'qtyController': TextEditingController(),
                               'unitController': TextEditingController(),
                             });
                          });
                        },
                        icon: const Icon(Icons.add, size: 18), label: const Text('Add Resource'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_activeReqs.isEmpty)
                    _buildPlaceholder()
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Column(children: List.generate(_activeReqs.length, (i) => _buildReqRow(i))),
                    ),
                  const SizedBox(height: 48),
                  
                  // THE SAVE BUTTON
                  GestureDetector(
                    onTap: _isSaving ? null : _handleSave,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isSaving ? Colors.grey : const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Center(
                        child: _isSaving 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(widget.initialProduct != null ? 'UPDATE PRODUCT' : 'SAVE PRODUCT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReqRow(int index) {
    final req = _activeReqs[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
               Text('Resource:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
               const SizedBox(width: 8),
               Expanded(
                 child: TextField(
                   controller: req['nameController'],
                   decoration: const InputDecoration(hintText: 'e.g. Space', isDense: true),
                   style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                 ),
               ),
               IconButton(onPressed: () => setState(() => _activeReqs.removeAt(index)), icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
               Text('Quantity:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
               const SizedBox(width: 8),
               Expanded(
                 child: TextField(
                   controller: req['qtyController'],
                   keyboardType: TextInputType.number,
                   decoration: const InputDecoration(hintText: '0.0', isDense: true),
                   style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                 ),
               ),
               const SizedBox(width: 12),
               Text('Unit:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
               const SizedBox(width: 8),
               Expanded(
                 child: TextField(
                   controller: req['unitController'],
                   decoration: const InputDecoration(hintText: 'e.g. kg', isDense: true),
                   style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                 ),
               ),
            ],
          ),
          if (index < _activeReqs.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(12)), child: Center(child: Text('Tap "Add Resource" to start', style: GoogleFonts.inter(color: Colors.grey))));
  }

  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(value: value, isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  Widget _buildInternalInput(String label, TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF1F4F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final String name = _nameCtrl.text.trim();
    final String profitStr = _profitCtrl.text.trim().replaceAll('\$', '').replaceAll(',', '');

    if (name.isEmpty || profitStr.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Data'),
          content: const Text('Please provide at least a product name and a profit value.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    bool hasValidRequirement = false;
    for (var req in _activeReqs) {
      final resName = req['nameController'].text.trim();
      final qtyStr = req['qtyController'].text.trim();
      if (resName.isNotEmpty && qtyStr.isNotEmpty) {
        hasValidRequirement = true;
        // Verify it matches an existing resource constraints exactly
        final existing = productProvider.resources.where((r) => r.name.toLowerCase() == resName.toLowerCase()).toList();
        if (existing.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unknown Resource'),
              content: Text('The resource constraint "$resName" does not exist in your database.\n\nPlease define it under "Available Resources" first, or check your spelling.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ),
          );
          return;
        }
      }
    }

    if (!hasValidRequirement) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Constraints'),
          content: const Text('You must add at least one valid Resource Requirement (e.g. Space, Time, Raw Materials) for the optimizer to bind limits correctly.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final businessId = auth.currentUser?.businessId;
      
      if (businessId == null || businessId.isEmpty) {
        throw Exception('Business ID is missing. Please ensure you are logged in and have set up a business.');
      }

      final productId = widget.initialProduct?.productId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final profitVal = double.tryParse(profitStr) ?? 0.0;

      final product = ProductModel(
        productId: productId,
        businessId: businessId,
        name: name,
        sellingPrice: profitVal,
        productionCost: 0,
        unit: _selectedUnit,
        profitMargin: profitVal,
        createdAt: widget.initialProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. SAVE PRODUCT
      if (widget.initialProduct != null) {
        await productProvider.updateProduct(product);
        // Clear old reqs for accurate update
        await productProvider.deleteProductRequirements(productId);
      } else {
        await productProvider.addProduct(product);
      }

      // 2. SAVE RESOURCE REQS
      for (var req in _activeReqs) {
        final resName = req['nameController'].text.trim();
        final qtyStr = req['qtyController'].text.trim();
        final unitStr = req['unitController'].text.trim();

        if (resName.isNotEmpty && qtyStr.isNotEmpty) {
          final qty = double.tryParse(qtyStr) ?? 0.0;
          
          String targetResId = '';
          final existing = productProvider.resources.where((r) => r.name.toLowerCase() == resName.toLowerCase()).toList();
          
          if (existing.isNotEmpty) {
            targetResId = existing.first.resourceId;
          } else {
             // This branch is now unreachable due to prior validation, but retained for safety.
            continue;
          }

          await productProvider.saveProductRequirement(ProductResourceRequirement(
            productId: productId,
            resourceId: targetResId,
            quantityRequired: qty,
          ));
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e, stack) {
      Logger.error('Critical Save Error', error: e, stackTrace: stack);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Failed'),
            content: Text('Reason: $e\n\nContact support if this persists.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
