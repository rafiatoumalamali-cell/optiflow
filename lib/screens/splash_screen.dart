import 'package:flutter/material.dart';
import '../services/shared_preferences_service.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // Artificial delay for splash feel
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. Check Onboarding
    if (!SharedPreferencesService.onboardingSeen) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    // 2. Check Auth Status (SharedPreferences)
    if (!SharedPreferencesService.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.authChoice);
      return;
    }

    // 3. User is logged in, check role
    String? role = SharedPreferencesService.userRole;
    if (role == null || role.isEmpty) {
      // Should not happen if they completed setup, but if they didn't, go back to Login/Setup
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // 4. Redirect based on role
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (role == 'Driver') {
      Navigator.pushReplacementNamed(context, AppRoutes.driverHome);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 80, color: AppColors.primaryGreen),
            SizedBox(height: 24),
            Text(
              'OptiFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}
