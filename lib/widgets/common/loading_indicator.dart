import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  
  const LoadingIndicator({
    super.key,
    this.message = 'Processing...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your connection active',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
