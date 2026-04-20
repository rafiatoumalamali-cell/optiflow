import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/app_localizations.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Navigate to security question-based password reset
    Navigator.pushNamed(context, AppRoutes.securityPasswordReset);
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                loc?.translate('forgot_password_title') ?? 'Reset Password',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your email address and we\'ll ask you security questions to verify your identity before resetting your password.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              if (!_isEmailSent) ...[
                Form(
                  key: _formKey,
                  child: CustomTextField(
                    label: loc?.translate('email_address') ?? 'Email Address',
                    hintText: 'example@hub.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => Validators.isValidEmail(v?.trim() ?? '')
                        ? null
                        : loc?.translate('invalid_email_address') ?? 'Invalid email address',
                  ),
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: loc?.translate('send_reset_link') ?? 'Send Reset Link',
                      isLoading: auth.isLoading,
                      onPressed: _handleResetPassword,
                    );
                  },
                ),
              ] else ...[
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.successGreen),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          loc?.translate('back_to_login') ?? 'Back to Login',
                          style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              const Center(
                child: Text(
                  'OPTIFLOW • SECURE AUTH SYSTEM',
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
