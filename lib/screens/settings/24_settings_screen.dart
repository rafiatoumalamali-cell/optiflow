import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'Nigerian Naira';
  bool _pushNotifications = true;
  bool _optimizationAlerts = true;
  bool _budgetWatch = false;
  bool _routeChanges = true;
  bool _smsFallback = true;
  bool _offlineMaps = true;

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
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: AppColors.primaryGreen)),
            const SizedBox(width: 8),
            const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/user_avatar.png')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('Tailor your operational environment for peak efficiency across West African corridors.', 
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 24),

            // Language Section
            _buildSectionHeader(Icons.language, 'Language'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildRadioOption('English', _selectedLanguage, (v) => setState(() => _selectedLanguage = v!)),
                  const Divider(),
                  _buildRadioOption('Français', _selectedLanguage, (v) => setState(() => _selectedLanguage = v!)),
                  const Divider(),
                  _buildRadioOption('Hausa', _selectedLanguage, (v) => setState(() => _selectedLanguage = v!)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Currency Section
            _buildSectionHeader(Icons.payments_outlined, 'Currency'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildCurrencyChip('XOF', 'West African CFA', _selectedCurrency == 'West African CFA'),
                  const SizedBox(height: 12),
                  _buildCurrencyChip('NGN', 'Nigerian Naira', _selectedCurrency == 'Nigerian Naira'),
                  const SizedBox(height: 12),
                  _buildCurrencyChip('GHS', 'Ghanaian Cedi', _selectedCurrency == 'Ghanaian Cedi'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionHeader(Icons.notifications_none, 'Notifications'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildSwitchOption('Push Notifications', 'Real-time alerts for all events', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                  _buildSwitchOption('Optimization Alerts', 'Route efficiency updates', _optimizationAlerts, (v) => setState(() => _optimizationAlerts = v)),
                  _buildSwitchOption('Budget Watch', 'Spending & fuel thresholds', _budgetWatch, (v) => setState(() => _budgetWatch = v)),
                  _buildSwitchOption('Route Changes', 'Traffic & blockages', _routeChanges, (v) => setState(() => _routeChanges = v)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.sms_outlined, size: 20, color: AppColors.successGreen),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SMS Fallback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Vital alerts when data connection is low', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _smsFallback,
                          onChanged: (v) => setState(() => _smsFallback = v),
                          activeColor: AppColors.successGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Map Settings
            _buildSectionHeader(Icons.map_outlined, 'Map Settings'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ensure navigation reliability in remote areas with high-fidelity offline mapping data.', 
                    style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Offline Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(value: _offlineMaps, onChanged: (v) => setState(() => _offlineMaps = v), activeColor: AppColors.primaryGreen),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download Lagos-Accra Corridor', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Map Illustration
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/africa_map_outline.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('CACHED AREA: 2.4 GB', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Storage Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage_outlined, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offline Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Storage Health: Optimal', style: TextStyle(fontSize: 10, color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cache Usage', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      const Text('420 MB / 1 GB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.42,
                    backgroundColor: AppColors.backgroundGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: const Text('CLEAR CACHE', style: TextStyle(color: AppColors.errorRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Changes Button
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.homeDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.savedResults);
        },
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: label,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primaryGreen,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildCurrencyChip(String code, String name, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = name),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange.withOpacity(0.05) : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryOrange : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: isSelected ? AppColors.primaryOrange : Colors.grey[400], borderRadius: BorderRadius.circular(4)),
              child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primaryOrange, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryGreen,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
