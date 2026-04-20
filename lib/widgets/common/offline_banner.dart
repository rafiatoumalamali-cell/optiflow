import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_localizations.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: connectivity.isOnline ? 0 : 40,
          width: double.infinity,
          color: AppColors.errorRed,
          child: connectivity.isOnline 
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc?.translate('offline_mode_active') ?? 'OFFLINE MODE ACTIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
