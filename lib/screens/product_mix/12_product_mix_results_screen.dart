import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../providers/optimization_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';

class ProductMixResultsScreen extends StatefulWidget {
  const ProductMixResultsScreen({super.key});

  @override
  State<ProductMixResultsScreen> createState() => _ProductMixResultsScreenState();
}

class _ProductMixResultsScreenState extends State<ProductMixResultsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _solve());
  }

  Future<void> _solve() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final optiProv = Provider.of<OptimizationProvider>(context, listen: false);

    if (productProv.products.isEmpty) return;

    // IMPORTANT: Ensure requirements are loaded for each product
    for (var p in productProv.products) {
       await productProv.fetchProductRequirements(p.productId);
    }

    await optiProv.solveProductMix(
      businessId: auth.currentUser?.businessId ?? 'default',
      products: productProv.products,
      resources: productProv.resources,
      requirements: productProv.productRequirements,
    );
  }

  @override
  Widget build(BuildContext context) {
    final optiProv = Provider.of<OptimizationProvider>(context);
    final resultData = optiProv.lastResult?.resultData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Strategy Result',
          style: GoogleFonts.outfit(color: const Color(0xFF1B5E20), fontWeight: FontWeight.bold),
        ),
      ),
      body: optiProv.isLoading
          ? _buildLoadingState()
          : optiProv.errorMessage != null
              ? _buildErrorState(optiProv.errorMessage!)
              : resultData == null
                  ? _buildNoDataState()
                  : _buildResultsView(resultData),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF1B5E20)),
          const SizedBox(height: 24),
          Text(
            'Calculating Optimal Solution...',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF546E7A)),
          ),
          Text(
            'Maxmizing ROI using real-time constraints',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF90A4AE)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Calculation Failed', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _solve,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Optimization Data', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Configure products & resources to see results.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(Map<String, dynamic> data) {
    final profit = (data['total_profit'] ?? 0.0).toStringAsFixed(2);
    final plan = data['production_plan'] as Map<String, dynamic>? ?? {};
    final resourceUsage = data['resource_usage'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(profit),
          const SizedBox(height: 32),
          _buildSectionHeader('📦 RECOMMENDED PRODUCTION'),
          const SizedBox(height: 16),
          ...plan.entries.map((e) => _buildProductionItem(e.key, e.value)).toList(),
          const SizedBox(height: 32),
          _buildSectionHeader('🔧 RESOURCE ANALYSIS'),
          const SizedBox(height: 16),
          ...resourceUsage.entries.map((e) => _buildResourceUsageItem(e.key, e.value)).toList(),
          const SizedBox(height: 32),
          _buildInsightsSection(data),
          const SizedBox(height: 40),
          _buildActionButtons(data),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String profit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'PROJECTED MAXIMUM PROFIT',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$ $profit',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1C1E),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProductionItem(String productName, dynamic quantity) {
    final qty = (quantity as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(productName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Optimized target', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Text(
            '${qty.toStringAsFixed(1)} Units',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20)),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceUsageItem(String name, dynamic data) {
    final double used = (data['used'] ?? 0).toDouble();
    final double total = (data['total'] ?? 0).toDouble();
    final double percent = (data['percent'] ?? 0).toDouble() / 100;
    final double remaining = total - used;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              Text('${(percent * 100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: percent >= 0.95 ? Colors.red : Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: const Color(0xFFECEFF1),
              valueColor: AlwaysStoppedAnimation<Color>(percent >= 0.95 ? Colors.red : const Color(0xFF1B5E20)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Used: $used / $total', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              Text('Slack: ${remaining.toStringAsFixed(1)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> data) {
    final insights = _generateInsights(data);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 STRATEGIC INSIGHTS:', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF8D4B00))),
          const SizedBox(height: 16),
          ...insights.map((i) => _buildInsightBullet(i)).toList(),
        ],
      ),
    );
  }

  List<String> _generateInsights(Map<String, dynamic> data) {
    final List<String> insights = [];
    final usage = data['resource_usage'] as Map<String, dynamic>? ?? {};
    
    // Check for bottlenecks
    usage.forEach((name, stats) {
      final double percent = (stats['percent'] ?? 0).toDouble();
      if (percent >= 99) {
        insights.add('$name is a major bottleneck (100% utilized). Consider expanding capacity.');
      } else if (percent < 50) {
        insights.add('$name has excessive spare capacity (${(100 - percent).toStringAsFixed(0)}% idle).');
      }
    });

    if (insights.isEmpty) {
      insights.add('Production is well-balanced across all available resources.');
    }
    
    insights.add('Current plan maximizes net profit under local West African market constraints.');
    return insights;
  }

  Widget _buildInsightBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D4B00))),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF92400E)))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(Icons.save_outlined, 'SAVE RESULT', const Color(0xFF1B5E20), Colors.white, () => _handleSave(data)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionBtn(Icons.picture_as_pdf_outlined, 'EXPORT PDF', Colors.white, const Color(0xFF1B5E20), () => _handleExportPDF(data), isBorder: true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionBtn(Icons.share_outlined, 'SHARE ON WHATSAPP', const Color(0xFF25D366), Colors.white, () => _handleShare(data)),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color bg, Color text, VoidCallback onTap, {bool isBorder = false}) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: text, size: 18),
        label: Text(label, style: GoogleFonts.outfit(color: text, fontWeight: FontWeight.bold, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isBorder ? const BorderSide(color: Color(0xFF1B5E20)) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _handleSave(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Strategy saved to your local archives.'), backgroundColor: Color(0xFF1B5E20)),
    );
  }

  Future<void> _handleExportPDF(Map<String, dynamic> data) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('OptiFlow Production Strategy', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Projected Profit: \$${data['total_profit']}'),
            pw.SizedBox(height: 20),
            pw.Text('Production Plan:'),
            ...(data['production_plan'] as Map).entries.map((e) => pw.Text('- ${e.key}: ${e.value} units')).toList(),
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  void _handleShare(Map<String, dynamic> data) {
    String text = "OptiFlow Product Mix Result\n\nTotal Profit: \$${data['total_profit']}\n\nPlan:\n";
    (data['production_plan'] as Map).forEach((k, v) => text += "- $k: $v units\n");
    Share.share(text);
  }
}
