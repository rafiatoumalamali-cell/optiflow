import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../providers/admin_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Optimization controllers
  final _routeTimeoutController = TextEditingController();
  final _maxFleetController = TextEditingController();

  // Exchange rate controllers
  final _ngnRateController = TextEditingController();
  final _ghsRateController = TextEditingController();

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPlatformSettings().then((_) {
        _populateControllers();
      });
    });
  }

  void _populateControllers() {
    final prov = context.read<AdminProvider>();
    final settings = prov.platformSettings;

    final optimization = (settings['optimization'] as Map?)?.cast<String, dynamic>() ?? {};
    final exchangeRates = (settings['exchange_rates'] as Map?)?.cast<String, dynamic>() ?? {};

    _routeTimeoutController.text = (optimization['route_timeout_s'] ?? 45).toString();
    _maxFleetController.text = (optimization['max_fleet_density'] ?? 150).toString();
    _ngnRateController.text = (exchangeRates['NGN'] ?? 1.24).toString();
    _ghsRateController.text = (exchangeRates['GHS'] ?? 0.021).toString();

    // Listen for changes
    for (final ctrl in [_routeTimeoutController, _maxFleetController, _ngnRateController, _ghsRateController]) {
      ctrl.addListener(() => setState(() => _hasChanges = true));
    }
  }

  @override
  void dispose() {
    _routeTimeoutController.dispose();
    _maxFleetController.dispose();
    _ngnRateController.dispose();
    _ghsRateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final prov = context.read<AdminProvider>();
    final payload = {
      'exchange_rates': {
        'NGN': double.tryParse(_ngnRateController.text) ?? 1.24,
        'GHS': double.tryParse(_ghsRateController.text) ?? 0.021,
      },
      'optimization': {
        'route_timeout_s': int.tryParse(_routeTimeoutController.text) ?? 45,
        'max_fleet_density': int.tryParse(_maxFleetController.text) ?? 150,
      },
    };

    final success = await prov.savePlatformSettings(payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Settings saved successfully' : 'Failed to save settings'),
          backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
        ),
      );
      if (success) setState(() => _hasChanges = false);
    }
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
              'Settings',
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
      drawer: const AdminSidebar(selectedRoute: '/admin/settings'),
      body: Consumer<AdminProvider>(
        builder: (context, adminProv, _) {
          if (adminProv.isSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final integrations = (adminProv.platformSettings['integrations'] as Map?)?.cast<String, dynamic>() ?? {};
          final emailLimit = integrations['email_daily_limit'] as int? ?? 50000;
          final emailUsed = integrations['email_daily_used'] as int? ?? 0;
          final smsProvider = integrations['sms_provider'] as String? ?? 'N/A';
          final smsStatus = integrations['sms_status'] as String? ?? 'Unknown';
          final emailProvider = integrations['email_provider'] as String? ?? 'N/A';

          final lastUpdated = adminProv.settingsLastUpdated;
          final lastUpdatedStr = lastUpdated != null
              ? DateFormat('HH:mm:ss z, dd MMM yyyy').format(lastUpdated.toLocal())
              : 'Never saved';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(
                  'Configure global parameters and platform defaults for OptiFlow\'s West African logistics network.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                _buildCurrencySettings(),
                const SizedBox(height: 24),
                _buildRegionalContent(),
                const SizedBox(height: 24),
                _buildOptimizationSettings(),
                const SizedBox(height: 24),
                _buildNotificationApiSettings(smsProvider, smsStatus, emailProvider, emailUsed, emailLimit),
                const SizedBox(height: 40),
                _buildFooterActions(adminProv, lastUpdatedStr),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencySettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.payments_outlined, 'Currency Settings', Colors.green),
          const SizedBox(height: 20),
          const Text('BASE CURRENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Text('🇳🇪', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('West African CFA franc (XOF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Spacer(),
                Text('Primary', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ACTIVE EXCHANGE RATES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 12),
          _buildEditableRateRow('🇳🇬  Nigerian Naira (NGN)', '1 XOF =', _ngnRateController, 'NGN'),
          const SizedBox(height: 12),
          _buildEditableRateRow('🇬🇭  Ghanaian Cedi (GHS)', '1 XOF =', _ghsRateController, 'GHS'),
        ],
      ),
    );
  }

  Widget _buildEditableRateRow(String label, String prefix, TextEditingController controller, String currency) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ),
        const SizedBox(width: 12),
        Text(prefix, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              suffix: Text(currency, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegionalContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.language, 'Regional Content', Colors.orange),
          const SizedBox(height: 20),
          const Text('SUPPORTED LANGUAGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 12),
          _buildLanguageOption('English (US)', true),
          _buildLanguageOption('Français (FR)', false),
          _buildLanguageOption('Hausa (NG/NE)', false),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? AppColors.primaryGreen : AppColors.textLight,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildOptimizationSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.bolt, 'Optimization', Colors.pink[100]!),
          const SizedBox(height: 20),
          _buildEditableSettingsInput('ROUTE TIMEOUT (seconds)', _routeTimeoutController, 'e.g. 45'),
          const SizedBox(height: 16),
          _buildEditableSettingsInput('MAX FLEET DENSITY', _maxFleetController, 'e.g. 150'),
          const Text('Maximum vehicles per operator in optimization setting.', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildEditableSettingsInput(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.backgroundGray,
            suffixIcon: const Icon(Icons.edit, size: 14, color: AppColors.textLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationApiSettings(
    String smsProvider, String smsStatus,
    String emailProvider, int emailUsed, int emailLimit,
  ) {
    final emailUsage = emailLimit > 0 ? '${_formatNumber(emailUsed)} / ${_formatNumber(emailLimit)}' : 'N/A';
    final smsIsConnected = smsStatus.toLowerCase() == 'connected';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(Icons.api, 'Notification & API', Colors.green[300]!),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.sms_outlined, size: 14), SizedBox(width: 8), Text('SMS Gateway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    Text('Provider: $smsProvider', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Row(children: [
                      const Text('Status: ', style: TextStyle(fontSize: 10)),
                      Text(
                        smsStatus,
                        style: TextStyle(
                          fontSize: 10,
                          color: smsIsConnected ? AppColors.successGreen : AppColors.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildSmallButton('Manage Templates'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.email_outlined, size: 14), SizedBox(width: 8), Text('Email Integration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    Text('Provider: $emailProvider', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Row(children: [
                      const Text('Daily Limit: ', style: TextStyle(fontSize: 10)),
                      Text(emailUsage, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    _buildSmallButton('API Logs'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildCardHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildSmallButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooterActions(AdminProvider adminProv, String lastUpdatedStr) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Last saved: $lastUpdatedStr',
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
        ),
        TextButton(
          onPressed: _hasChanges ? () {
            _populateControllers();
            setState(() => _hasChanges = false);
          } : null,
          child: Text(
            'Discard Changes',
            style: TextStyle(color: _hasChanges ? AppColors.textLight : Colors.grey.shade300, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 24),
        ElevatedButton.icon(
          onPressed: adminProv.isSavingSettings
              ? null
              : (_hasChanges ? _saveSettings : null),
          icon: adminProv.isSavingSettings
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 16),
          label: Text(adminProv.isSavingSettings ? 'Saving...' : 'Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasChanges ? AppColors.primaryGreen : Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}
