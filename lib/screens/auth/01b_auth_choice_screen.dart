import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../routes/app_routes.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: AppColors.primaryGreen, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'OptiFlow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Operational Optimization for West Africa',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  ),
                  const SizedBox(height: 60),

                  // LOGIN Button
                  CustomButton(
                    text: 'LOGIN',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                  const SizedBox(height: 16),

                  // REGISTER Button
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.phoneAuth),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: AppColors.primaryGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'REGISTER',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
