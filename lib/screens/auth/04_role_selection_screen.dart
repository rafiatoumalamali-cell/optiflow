import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../services/shared_preferences_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'Business Owner',
      'icon': Icons.business_center_rounded,
      'titleKey': 'business_owner',
      'descKey': 'role_owner_desc',
      'color': AppColors.primaryGreen,
    },
    {
      'id': 'Manager',
      'icon': Icons.settings_suggest_rounded,
      'titleKey': 'manager',
      'descKey': 'role_manager_desc',
      'color': Color(0xFF1565C0), // Deep Blue for Manager
    },
  ];

  Future<void> _handleRoleSelection(String roleId) async {
    setState(() => _selectedRole = roleId);
    
    // Slight delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    // Save role to SharedPreferences
    await SharedPreferencesService.setUserRole(roleId);

    if (mounted) {
      if (roleId == 'Driver') {
        Navigator.pushReplacementNamed(context, AppRoutes.driverHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.businessSetup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              loc?.translate('home_title') ?? 'OptiFlow',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                loc?.translate('select_role') ?? 'Select your role',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc?.translate('onboarding_subtitle') ?? 
                'Tailor your OptiFlow experience based on your daily operations.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['id'];
                    
                    return GestureDetector(
                      onTap: () => _handleRoleSelection(role['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (role['color'] as Color).withOpacity(0.05) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? (role['color'] as Color) 
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: (role['color'] as Color).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (role['color'] as Color).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                role['icon'] as IconData,
                                color: role['color'] as Color,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc?.translate(role['titleKey']) ?? role['id'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loc?.translate(role['descKey']) ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryGreen,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'OPTIFLOW • SECURE HUB ACCESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
