import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../providers/admin_provider.dart';
import '../../models/report_model.dart';

class ReportsIssuesScreen extends StatefulWidget {
  const ReportsIssuesScreen({super.key});

  @override
  State<ReportsIssuesScreen> createState() => _ReportsIssuesScreenState();
}

class _ReportsIssuesScreenState extends State<ReportsIssuesScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchReports();
    });
  }

  // ── Status colour helpers ──────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return AppColors.successGreen;
      case 'in review':
        return Colors.blue;
      default:
        return AppColors.primaryOrange;
    }
  }

  Color _statusBg(String status) => _statusColor(status).withOpacity(0.1);

  // ── Main build ─────────────────────────────────────────────────────────────
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
              'Reports & Issues',
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
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
      drawer: const AdminSidebar(selectedRoute: '/admin/reports'),
      body: Consumer<AdminProvider>(
        builder: (context, adminProv, _) {
          // Filter reports
          final allReports = adminProv.reports;
          final filtered = _statusFilter == 'All'
              ? allReports
              : allReports.where((r) => r.status.toLowerCase() == _statusFilter.toLowerCase()).toList();

          return Container(
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
                      // ── Page heading ─────────────────────────────────────────────
                      const Text('ADMIN MODULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      const Text('Reports & Issues', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      const Text(
                        'Monitor and resolve user-reported issues across all regions.',
                        style: TextStyle(fontSize: 13, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 20),

                      // ── Summary stat chips ────────────────────────────────────────
                      if (adminProv.isReportsLoading)
                        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
                      else ...[
                        Row(
                          children: [
                            Expanded(child: _statChip('TOTAL', adminProv.reportCount.toString(), AppColors.errorRed)),
                            const SizedBox(width: 10),
                            Expanded(child: _statChip('PENDING', adminProv.pendingReports.toString(), AppColors.primaryOrange)),
                            const SizedBox(width: 10),
                            Expanded(child: _statChip('IN REVIEW', adminProv.inReviewReports.toString(), Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _statChip('RESOLVED', adminProv.resolvedReports.toString(), AppColors.successGreen)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Status filter chips ───────────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('All', () => setState(() => _statusFilter = 'All')),
                              _filterChip('Pending', () => setState(() => _statusFilter = 'Pending')),
                              _filterChip('In Review', () => setState(() => _statusFilter = 'In Review')),
                              _filterChip('Resolved', () => setState(() => _statusFilter = 'Resolved')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Report list ───────────────────────────────────────────
                        if (filtered.isEmpty)
                          _emptyState()
                        else
                          ...filtered.map((r) => _reportCard(r, adminProv)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Filter chip widget ────────────────────────────────────────────────────
  Widget _filterChip(String label, VoidCallback onTap) {
    final isSelected = _statusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryGreen.withOpacity(0.1),
        checkmarkColor: AppColors.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _statusFilter == 'All' ? 'No reports submitted yet.' : 'No "$_statusFilter" reports.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(ReportModel report, AdminProvider adminProv) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt.toLocal());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(report.type), color: AppColors.primaryGreen, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.type.isNotEmpty ? report.type : 'General Issue',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg(report.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(report.status)),
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              report.description.isNotEmpty ? report.description : 'No description provided.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.4),
            ),
          ),

          // Reporter ID
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reporter: ${report.userId.isNotEmpty ? report.userId : "Unknown"}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (report.resolvedBy != null) ...[
                  const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text('Resolved by: ${report.resolvedBy}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ],
            ),
          ),

          // Action row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetailSheet(context, report, adminProv),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('View & Update', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (report.status.toLowerCase() != 'resolved') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _quickResolve(report, adminProv),
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return Icons.bug_report_outlined;
      case 'billing':
        return Icons.payment_outlined;
      case 'feature':
        return Icons.lightbulb_outline;
      default:
        return Icons.description_outlined;
    }
  }

  Future<void> _quickResolve(ReportModel report, AdminProvider adminProv) async {
    final ok = await adminProv.updateReportStatus(report.reportId, 'Resolved');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Report marked as resolved ✓' : 'Failed to update report'),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
      ));
    }
  }

  // ── Detail / Update bottom sheet ───────────────────────────────────────────
  void _openDetailSheet(BuildContext context, ReportModel report, AdminProvider adminProv) {
    String _selectedStatus = report.status;
    bool _saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt.toLocal());

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),

                  // Status badge + type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _statusBg(_selectedStatus), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          _selectedStatus.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(_selectedStatus)),
                        ),
                      ),
                      const Spacer(),
                      Text('ID: ${report.reportId.length > 12 ? report.reportId.substring(0, 12) : report.reportId}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.type.isNotEmpty ? '${report.type} Issue' : 'General Issue',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 24),

                  // Reporter info
                  _sheetInfoRow(Icons.person_outline, 'REPORTED BY', report.userId.isNotEmpty ? report.userId : 'Unknown'),
                  const SizedBox(height: 12),
                  if (report.resolvedBy != null)
                    _sheetInfoRow(Icons.admin_panel_settings_outlined, 'RESOLVED BY', report.resolvedBy!),
                  const SizedBox(height: 20),

                  // Description
                  const Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      report.description.isNotEmpty ? report.description : 'No description provided.',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status selector
                  const Text('UPDATE STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 12),
                  ...['Pending', 'In Review', 'Resolved'].map((s) {
                    final isSelected = _selectedStatus == s;
                    return InkWell(
                      onTap: () => setSheetState(() => _selectedStatus = s),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? _statusColor(s).withOpacity(0.08) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _statusColor(s).withOpacity(0.4) : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: isSelected ? _statusColor(s) : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 12),
                            Text(s, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const Spacer(),
                            if (isSelected)
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setSheetState(() => _saving = true);
                            final ok = await adminProv.updateReportStatus(
                              report.reportId,
                              _selectedStatus,
                              resolvedBy: _selectedStatus == 'Resolved' ? 'Admin' : null,
                            );
                            if (sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(ok ? 'Status updated to "$_selectedStatus" ✓' : 'Failed to update'),
                                backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
                              ));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Status Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.textLight),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}