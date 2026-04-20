import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/transport_cost_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transport_optimization_model.dart' as opt;
import '../../models/transport_problem_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class TransportCostOptimizationScreen extends StatefulWidget {
  const TransportCostOptimizationScreen({super.key});

  @override
  State<TransportCostOptimizationScreen> createState() => _TransportCostOptimizationScreenState();
}

class _TransportCostOptimizationScreenState extends State<TransportCostOptimizationScreen> {
  final _scrollController = ScrollController();
  
  List<opt.SupplyPoint> _supplyPoints = [];
  List<opt.DemandPoint> _demandPoints = [];
  List<List<double>> _costMatrix = [];
  bool _isCalculating = false;
  TransportOptimizationResult? _result;

  @override
  void initState() {
    super.initState();
    _initializeDefaultData();
    _loadTransportProblems();
  }

  void _initializeDefaultData() {
    _supplyPoints = [];
    _demandPoints = [];
    _costMatrix = [];
  }

  Future<void> _loadTransportProblems() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessId = authProvider.currentUser?.businessId;
    if (businessId != null) {
      final provider = Provider.of<TransportCostProvider>(context, listen: false);
      await provider.fetchTransportProblems(businessId);
    }
  }

  int get _totalNetworkCapacity {
    return _supplyPoints.fold(0, (sum, sp) => sum + sp.availableQuantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _result == null ? _buildMainUI() : _buildResultsView(),
          if (_result == null) _buildBottomActions(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0, // Not on home, so keep index 0
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Transport Optimization',
        style: GoogleFonts.outfit(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              final initials = user?.fullName.isNotEmpty == true 
                ? user!.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                : 'U';
              return CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2E7D32),
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF546E7A)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMainUI() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(),
          const SizedBox(height: 20),
          _buildMetricsCard(),
          const SizedBox(height: 32),
          _buildSectionHeader('Supply Points', 'Production Factories & Hubs'),
          const SizedBox(height: 12),
          ..._supplyPoints.asMap().entries.map((e) => _buildSupplyCard(e.key, e.value)),
          const SizedBox(height: 32),
          _buildSectionHeader('Demand Points', 'Regional Distribution Centers'),
          const SizedBox(height: 12),
          ..._demandPoints.asMap().entries.map((e) => _buildDemandCard(e.key, e.value)),
          const SizedBox(height: 32),
          _buildCostMatrixSummary(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Configuration',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Define supply origins and demand destinations across the West African hub network to optimize transit costs and carbon footprint.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF546E7A),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hub_outlined, color: Color(0xFF2E7D32), size: 30),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHeroButton(
            label: 'Add Supply Point',
            icon: Icons.add_circle,
            color: const Color(0xFF1B5E20),
            onTap: _showAddSupplyDialog,
          ),
          const SizedBox(height: 12),
          _buildHeroButton(
            label: 'Add Demand Point',
            icon: Icons.add_location_alt,
            color: const Color(0xFF8D4B00),
            onTap: _showAddDemandDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'LIVE METRICS',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_totalNetworkCapacity',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Units',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Text(
            'Total Network Capacity',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF78909C),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyCard(int index, opt.SupplyPoint sp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.factory_outlined, color: Color(0xFF2E7D32)),
        ),
        title: Text(
          '${sp.name} - ${sp.location}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '${sp.availableQuantity} units capacity',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF78909C)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFFB0BEC5)),
          onPressed: () => _removeSupplyPoint(index),
        ),
        onTap: () => _editSupplyPoint(index, sp),
      ),
    );
  }

  Widget _buildDemandCard(int index, opt.DemandPoint dp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.warehouse_outlined, color: Color(0xFFF57C00)),
        ),
        title: Text(
          '${dp.name} - ${dp.location}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '${dp.requiredQuantity} units required',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF78909C)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFFB0BEC5)),
          onPressed: () => _removeDemandPoint(index),
        ),
        onTap: () => _editDemandPoint(index, dp),
      ),
    );
  }

  Widget _buildCostMatrixSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost Matrix Summary',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Unit shipping costs (\$/unit) between nodes',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78909C)),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showEditCostMatrixDialog,
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2E7D32)),
              label: Text(
                'Edit Cost Matrix',
                style: GoogleFonts.outfit(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                horizontalMargin: 8,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F9)),
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 120,
                      child: Text('Origin / Destination', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12))
                    )
                  ),
                  ..._demandPoints.map((dp) => DataColumn(
                    label: SizedBox(
                      width: 80,
                      child: Text('${dp.name.split(' ').last}\n(${dp.location})', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10))
                    )
                  )),
                ],
                rows: _supplyPoints.asMap().entries.map((s) {
                  return DataRow(cells: [
                    DataCell(SizedBox(
                      width: 120,
                      child: Text('${s.value.name.split(' ').last} (${s.value.location})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))
                    )),
                    ..._demandPoints.asMap().entries.map((d) {
                      final cost = _costMatrix[s.key][d.key];
                      return DataCell(SizedBox(
                        width: 80,
                        child: Text('\$${cost.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12))
                      ));
                    }),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _resetForm,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                minimumSize: const Size(120, 48),
              ),
              child: Text('Clear All', style: GoogleFonts.outfit(color: const Color(0xFF1C1B1F), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isCalculating ? null : _runOptimization,
              icon: _isCalculating 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.calculate_outlined, color: Colors.white),
              label: Text('Run Optimization', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                minimumSize: const Size(160, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showAddSupplyDialog() {
    _showSupplyDialog(null, null);
  }

  void _editSupplyPoint(int index, opt.SupplyPoint sp) {
    _showSupplyDialog(index, sp);
  }

  void _showSupplyDialog(int? index, opt.SupplyPoint? sp) {
    final nameCtrl = TextEditingController(text: sp?.name);
    final qtyCtrl = TextEditingController(text: sp?.availableQuantity.toString());
    final locCtrl = TextEditingController(text: sp?.location);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Add / Edit Supply Point', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Configure logistical nodes for the regional hub network.', style: GoogleFonts.inter(color: const Color(0xFF78909C))),
              const SizedBox(height: 24),
              _buildDialogField('SUPPLY POINT NAME', 'e.g. Ikeja Distribution Center', nameCtrl),
              const SizedBox(height: 16),
              _buildDialogField('AVAILABLE SUPPLY (UNITS)', '0.00 QTY', qtyCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildDialogField('LOCATION (OPTIONAL)', 'Enter GPS coordinates or City', locCtrl, icon: Icons.location_on),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF546E7A), fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      minimumSize: const Size(120, 48),
                    ),
                    child: Text('Save Supply', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        final newSp = opt.SupplyPoint(
                          id: sp?.id ?? DateTime.now().toString(),
                          name: nameCtrl.text,
                          location: locCtrl.text,
                          availableQuantity: int.tryParse(qtyCtrl.text) ?? 0,
                        );
                        if (index != null) {
                          _supplyPoints[index] = newSp;
                        } else {
                          _supplyPoints.add(newSp);
                          // Add new row for the new supply point
                          _costMatrix.add(List.generate(_demandPoints.length, (index) => 0.0, growable: true));
                          // Ensure all existing rows have the correct number of columns
                          for (var row in _costMatrix) {
                            while (row.length < _demandPoints.length) {
                              row.add(0.0);
                            }
                          }
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDemandDialog() {
    _showDemandDialog(null, null);
  }

  void _editDemandPoint(int index, opt.DemandPoint dp) {
    _showDemandDialog(index, dp);
  }

  void _showDemandDialog(int? index, opt.DemandPoint? dp) {
    final nameCtrl = TextEditingController(text: dp?.name);
    final qtyCtrl = TextEditingController(text: dp?.requiredQuantity.toString());
    final locCtrl = TextEditingController(text: dp?.location);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add / Edit Demand Point', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Configure logistics endpoint and required volume.', style: GoogleFonts.inter(color: const Color(0xFF78909C))),
              const SizedBox(height: 24),
              _buildDialogField('DEMAND POINT NAME', 'e.g. Kano Regional Distribution Center', nameCtrl),
              const SizedBox(height: 16),
              _buildDialogField('REQUIRED DEMAND (UNITS)', '0.00 QTY', qtyCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildDialogField('LOCATION (OPTIONAL)', 'GPS or City', locCtrl, icon: Icons.location_on),
              const SizedBox(height: 20),
              Container(
                height: 120,
                constraints: const BoxConstraints(maxWidth: 300),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32), size: 32),
                      const SizedBox(height: 8),
                      Text('Location Preview', style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Coordinates will be displayed here', style: GoogleFonts.inter(color: const Color(0xFF78909C), fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF546E7A), fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      minimumSize: const Size(120, 48),
                    ),
                    child: Text('Save Demand', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        final newDp = opt.DemandPoint(
                          id: dp?.id ?? DateTime.now().toString(),
                          name: nameCtrl.text,
                          location: locCtrl.text,
                          requiredQuantity: int.tryParse(qtyCtrl.text) ?? 0,
                        );
                        if (index != null) {
                          _demandPoints[index] = newDp;
                        } else {
                          _demandPoints.add(newDp);
                          // Add new column to all existing rows
                          for (int i = 0; i < _costMatrix.length; i++) {
                            _costMatrix[i].add(0.0);
                          }
                          // If there are no supply points yet, don't add rows
                          // The rows will be added when supply points are added
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, String hint, TextEditingController ctrl, {bool isNumber = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF546E7A), letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF546E7A), size: 18) : null,
            filled: true,
            fillColor: const Color(0xFFECEFF1).withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showEditCostMatrixDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Edit Cost Matrix', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                                Text('Optimize West African shipping corridors', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78909C))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.black, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter the cost to ship ONE unit from each supply to each demand. Use West African CFA (XOF) for consistency across regional hubs.',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 100),
                              ..._demandPoints.map((dp) => Flexible(
                                child: SizedBox(
                                  width: 80,
                                  child: Text(
                                    '${dp.name.split(' ').last}\n${dp.location.toUpperCase()}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF546E7A)),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._supplyPoints.asMap().entries.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.value.name.split(' ').last, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(s.value.location, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78909C))),
                                      ],
                                    ),
                                  ),
                                  ..._demandPoints.asMap().entries.map((d) {
                                    return Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: SizedBox(
                                          width: 80,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.all(8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                            ),
                                            controller: TextEditingController(text: _costMatrix[s.key][d.key].toStringAsFixed(0)),
                                            onChanged: (v) {
                                              _costMatrix[s.key][d.key] = double.tryParse(v) ?? 0;
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('CANCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        minimumSize: const Size(140, 48),
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.save_outlined, color: Colors.black, size: 20),
                          const SizedBox(width: 10),
                          Text('SAVE MATRIX', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Logic ---

  void _removeSupplyPoint(int i) => setState(() { 
    _supplyPoints.removeAt(i); 
    if (i < _costMatrix.length) {
      _costMatrix.removeAt(i);
    }
  });
  
  void _removeDemandPoint(int i) => setState(() { 
    _demandPoints.removeAt(i); 
    for (int row = 0; row < _costMatrix.length; row++) {
      if (i < _costMatrix[row].length) {
        _costMatrix[row].removeAt(i);
      }
    }
  });

  void _resetForm() => setState(() { _initializeDefaultData(); _result = null; });

  void _validateAndFixCostMatrix() {
    // Ensure cost matrix has the correct dimensions
    while (_costMatrix.length < _supplyPoints.length) {
      _costMatrix.add(List.generate(_demandPoints.length, (index) => 0.0, growable: true));
    }
    
    // Remove extra rows if there are too many
    while (_costMatrix.length > _supplyPoints.length) {
      _costMatrix.removeLast();
    }
    
    // Ensure each row has the correct number of columns
    for (int i = 0; i < _costMatrix.length; i++) {
      while (_costMatrix[i].length < _demandPoints.length) {
        _costMatrix[i].add(0.0);
      }
      // Remove extra columns if there are too many
      while (_costMatrix[i].length > _demandPoints.length) {
        _costMatrix[i].removeLast();
      }
    }
  }

  void _runOptimization() async {
    setState(() => _isCalculating = true);
    try {
      // Validate and fix cost matrix dimensions before optimization
      _validateAndFixCostMatrix();
      
      final provider = Provider.of<TransportCostProvider>(context, listen: false);
      _result = await provider.optimizeTransportCost(
        supplyPoints: _supplyPoints, 
        demandPoints: _demandPoints, 
        costMatrix: _costMatrix
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
          _buildResultHeader(),
          const SizedBox(height: 24),
          ..._groupShipmentsByFactory().map(_buildFactoryShipmentCard),
          const SizedBox(height: 24),
          _buildResultSection(title: 'DEMAND VERIFICATION', children: _buildDemandVerification()),
          _buildResultSection(title: 'SUPPLY VERIFICATION', children: _buildSupplyVerification()),
          const SizedBox(height: 24),
          CustomButton(text: 'NEW OPTIMIZATION', onPressed: () => setState(() => _result = null), color: const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 60),
          const SizedBox(height: 16),
          Text(
            'Optimal Cost Found',
            style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 4),
          Text(
            '${_result!.totalCost.toStringAsFixed(0)} CFA',
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection({required String title, required List<Widget> children}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          ...children,
        ]
      ),
    );
  }

  List<FactoryShipmentGroup> _groupShipmentsByFactory() {
    final Map<String, List<ShipmentData>> grouped = {};
    for (final s in _result!.shipments) {
      grouped.putIfAbsent(s.fromPoint, () => []).add(s);
    }
    return grouped.entries.map((e) => FactoryShipmentGroup(factoryName: e.key, shipments: e.value)).toList();
  }

  Widget _buildFactoryShipmentCard(FactoryShipmentGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                Text('FROM: ${group.factoryName}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 24),
            ...group.shipments.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, color: Color(0xFFF57C00)),
                  const SizedBox(width: 8),
                  Text('Send ${s.quantity} units to ', style: GoogleFonts.inter(fontSize: 13)),
                  Text(s.toPoint, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ]
        ),
      ),
    );
  }

  List<Widget> _buildDemandVerification() {
    final Map<String, int> received = {};
    for (final s in _result!.shipments) { 
      received[s.toPoint] = (received[s.toPoint] ?? 0) + s.quantity;
    }
    return _demandPoints.map((dp) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dp.name, style: GoogleFonts.inter(fontSize: 13)),
          Text('${received[dp.name] ?? 0} / ${dp.requiredQuantity}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    )).toList();
  }

  List<Widget> _buildSupplyVerification() {
    final Map<String, int> sent = {};
    for (final s in _result!.shipments) { 
      sent[s.fromPoint] = (sent[s.fromPoint] ?? 0) + s.quantity;
    }
    return _supplyPoints.map((sp) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(sp.name, style: GoogleFonts.inter(fontSize: 13)),
          Text('${sent[sp.name] ?? 0} / ${sp.availableQuantity}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    )).toList();
  }

  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class FactoryShipmentGroup {
  final String factoryName;
  final List<ShipmentData> shipments;
  FactoryShipmentGroup({required this.factoryName, required this.shipments});
}
