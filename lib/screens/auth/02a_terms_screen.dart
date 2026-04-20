import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('terms_of_service') ?? 'Terms of Service', style: const TextStyle(color: AppColors.textDark)),
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
            _buildSection('1. Acceptance of Terms', 'By accessing OptiFlow, you agree to optimize your West African logistics operations according to regional regulations...'),
            _buildSection('2. Service Usage', 'Drivers and Managers must provide accurate GPS coordinates for route optimization accuracy...'),
            _buildSection('3. Data Privacy', 'We prioritize secure sync across Niger, Nigeria, and Ghana corridors...'),
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
