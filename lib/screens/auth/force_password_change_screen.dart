import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../routes/app_routes.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  State<ForcePasswordChangeScreen> createState() => _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No authenticated user found.");

      // 1. Update Password in Firebase Auth
      await user.updatePassword(_newPasswordController.text.trim());

      // 2. Update Firestore `must_change_password` flag
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'must_change_password': false,
      });

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc?.translate('password_updated_successfully') ?? 'Password updated successfully! Welcome to OptiFlow.'), backgroundColor: AppColors.successGreen),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.driverHome);
      }
    } on FirebaseAuthException catch (e) {
      final loc = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? loc?.translate('failed_to_update_password') ?? 'Failed to update password. Try logging in again.'), backgroundColor: AppColors.errorRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorUtils.localizeError(e, context)), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('OptiFlow Security', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_reset, size: 64, color: AppColors.primaryOrange),
                    const SizedBox(height: 24),
                    const Text(
                      'Secure Your Account',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You are currently using a temporary password assigned by your manager. Please set a new secure password to continue accessing your routes.',
                      style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    CustomTextField(
                      label: loc?.translate('new_password') ?? 'New Password',
                      hintText: loc?.translate('password_min_length') ?? 'Minimum 6 characters',
                      obscureText: true,
                      controller: _newPasswordController,
                      validator: (v) {
                        if (v == null || v.length < 6) return loc?.translate('password_min_length') ?? 'Password must be at least 6 characters.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: loc?.translate('confirm_new_password') ?? 'Confirm New Password',
                      hintText: loc?.translate('retype_password') ?? 'Retype password',
                      obscureText: true,
                      controller: _confirmPasswordController,
                      validator: (v) {
                        if (v != _newPasswordController.text) return loc?.translate('passwords_do_not_match') ?? 'Passwords do not match.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    CustomButton(
                      text: 'UPDATE & CONTINUE',
                      isLoading: _isLoading,
                      onPressed: _updatePassword,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: const Text('Cancel & Sign Out', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
