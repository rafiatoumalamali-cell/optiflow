import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';

class ExportModal extends StatelessWidget {
  const ExportModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Export Optimization Result',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textLight),
              ),
            ],
          ),
          const Text(
            'Select your preferred delivery method',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          
          // WhatsApp Option (Recommended)
          _buildExportOption(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'WhatsApp',
            subtitle: 'Instant share to fleet manager',
            isRecommended: true,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          
          // Email Option
          _buildExportOption(
            context,
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'Full breakdown CSV',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          
          // Download PDF Option
          _buildExportOption(
            context,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Download PDF',
            subtitle: 'Official report',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          
          // SMS Option
          _buildExportOption(
            context,
            icon: Icons.sms_outlined,
            title: 'SMS',
            subtitle: 'Send as short link to driver',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          
          CustomButton(
            text: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRecommended ? AppColors.successGreen.withOpacity(0.05) : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(16),
          border: isRecommended ? Border.all(color: AppColors.successGreen.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRecommended ? AppColors.successGreen : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isRecommended ? Colors.white : AppColors.textLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
