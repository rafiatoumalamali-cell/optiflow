import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AdminPasswordResetScreen extends StatefulWidget {
  const AdminPasswordResetScreen({super.key});

  @override
  State<AdminPasswordResetScreen> createState() => _AdminPasswordResetScreenState();
}

class _AdminPasswordResetScreenState extends State<AdminPasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      setState(() {
        _isSending = false;
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent! Check your email inbox.'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() => _isSending = false);
      
      String message = 'Failed to send reset email';
      if (e.toString().contains('user-not-found')) {
        message = 'No account found with this email address';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email address format';
      } else if (e.toString().contains('too-many-requests')) {
        message = 'Too many requests. Try again in a few minutes';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'OptiFlow Admin',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Admin Password Reset',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _emailSent 
                  ? 'Reset link sent! Check your email inbox and spam folder.'
                  : 'Enter your admin email to receive a password reset link.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            if (!_emailSent) ...[
              CustomTextField(
                label: 'Admin Email Address',
                hintText: 'rafiatoumalamali@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'SEND RESET LINK',
                isLoading: _isSending,
                onPressed: _sendPasswordReset,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check Your Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We\'ve sent a password reset link to your email address.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            const Center(
              child: Text(
                'OPTIFLOW ADMIN PANEL',
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
    );
  }
}
