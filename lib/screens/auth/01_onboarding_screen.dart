import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'OptiFlow',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Illustration/Image
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/onboarding_img.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                loc?.translate('live_logistics') ?? 'LIVE LOGISTICS',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                loc?.translate('niamey_hub_active') ?? 'Niamey Hub Active',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Title
              Column(
                children: [
                  Text(
                    loc?.translate('onboarding_title_part1') ?? 'Optimize Your',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    loc?.translate('onboarding_title_part2') ?? 'West African Business',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                loc?.translate('onboarding_subtitle') ?? 'Make smarter production, logistics, and budget decisions, even in challenging environments.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Next Button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.authChoice),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                ),
              ),
              const Spacer(),
              // Language Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _languageOption(context, 'ENGLISH', 'en'),
                  _languageDivider(),
                  _languageOption(context, 'FRANÇAIS', 'fr'),
                  _languageDivider(),
                  _languageOption(context, 'HAUSA', 'ha'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, String text, String code) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        bool isSelected = languageProvider.locale.languageCode == code;
        return GestureDetector(
          onTap: () => languageProvider.setLanguage(code),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primaryGreen : AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _languageDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
