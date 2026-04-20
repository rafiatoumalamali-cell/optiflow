import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/images/user_avatar.png'),
          ),
        ),
        title: const Text(
          'OptiFlow',
          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Center',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 8),
            const Text(
              'How can we help you streamline your\nroute today?',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),

            // Top Cards
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.bug_report,
                    'Report Issue',
                    AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    Icons.star,
                    'Rate App',
                    AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              'Direct Contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            _buildContactTile(
              Icons.chat_bubble_outline,
              'WhatsApp Support',
              'Chat on WhatsApp',
              Colors.green[50]!,
              Colors.green,
            ),
            _buildContactTile(
              Icons.email_outlined,
              'Email Address',
              'support@optiflow.com',
              Colors.blue[50]!,
              Colors.blue,
            ),
            _buildContactTile(
              Icons.phone_outlined,
              'Phone Support',
              '+227 90 12 34 56',
              Colors.grey[100]!,
              AppColors.textDark,
            ),
            const SizedBox(height: 32),

            // Service Hours
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Hours',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our team is available across West Africa standard times.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  _buildServiceTimeRow('MON — FRI', '08:00 - 20:00'),
                  const SizedBox(height: 12),
                  _buildServiceTimeRow('SAT — SUN', '10:00 - 16:00'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Quick FAQ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            _buildFaqItem('How do I track my delivery?'),
            _buildFaqItem('Changing delivery routes mid-trip'),
            _buildFaqItem('Updating fuel consumption data'),
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

  Widget _buildActionCard(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.successGreen, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }

  Widget _buildServiceTimeRow(String day, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          time,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
          const Icon(Icons.add, color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }
}
