import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
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
        title: const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How can we help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Search for guides or browse categories below.', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for route optimization...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.textLight),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Getting Started', isSelected: true),
                  _buildCategoryChip('Product Mix'),
                  _buildCategoryChip('Driver Guide'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Video Tutorials
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Video Tutorials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildVideoCard('Setting Up Your First Route', '4:20 • Logistics 101'),
                  _buildVideoCard('Managing Offline Deliveries', '3:12 • Driver Efficiency'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Start Guides
            const Text('Quick Start Guides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildGuideTile(Icons.local_shipping_outlined, 'Dispatching Orders', 'Step-by-step masterclass for admins', Colors.green[50]!, AppColors.successGreen),
            _buildGuideTile(Icons.payments_outlined, 'Payment Integration', 'Linking mobile money and cards', Colors.orange[50]!, AppColors.primaryOrange),
            _buildGuideTile(Icons.analytics_outlined, 'Performance Reports', 'Understanding your efficiency data', Colors.pink[50]!, Colors.pink),
            
            const SizedBox(height: 32),
            // FAQ
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFaqItem('How do I change my region settings?'),
            _buildFaqItem('What happens if I lose signal mid-route?'),
            _buildFaqItem('Can I export my driver logs?'),
            _buildFaqItem('Troubleshooting payment delays'),

            const SizedBox(height: 32),
            // Still need help
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('Still need help?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Our support team is available 24/7 to assist with your logistics needs.', 
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.support),
                    icon: const Icon(Icons.headset_mic, color: AppColors.primaryGreen),
                    label: const Text('Contact Support', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
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

  Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVideoCard(String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        // Show video tutorial dialog or navigate to video player
        _showVideoTutorial(title);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.8),
                      AppColors.primaryGreen,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Video thumbnail placeholder with icon
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          subtitle.split(' • ').first, // Extract duration like "4:20"
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.split(' • ').last, // Extract description like "Logistics 101"
                    style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoTutorial(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_fill,
                size: 64,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Video tutorials are coming soon!\n\nThis feature will include:\n• Step-by-step guides\n• Interactive demos\n• Downloadable resources',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuideTile(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(question, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen, size: 20),
        ],
      ),
    );
  }
}
