import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('privacy_policy') ?? 'Privacy Policy', style: const TextStyle(color: AppColors.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last Updated: March 2024', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
            const SizedBox(height: 24),
            _buildSection('1. Data Collection', 'We collect phone numbers for authentication and GPS data to provide regional route optimizations in Niger, Nigeria, and Ghana...'),
            _buildSection('2. How We Use Data', 'Your logistics data is used to run the OR-Tools optimization engine and is cached locally for offline hub access...'),
            _buildSection('3. Regional Compliance', 'Our data processing follows the relevant data protection acts within ECOWAS member states...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.5)),
        ],
      ),
    );
  }
}
