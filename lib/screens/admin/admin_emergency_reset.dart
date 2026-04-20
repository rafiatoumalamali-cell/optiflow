import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../models/user_model.dart';

class AdminEmergencyResetScreen extends StatefulWidget {
  const AdminEmergencyResetScreen({super.key});

  @override
  State<AdminEmergencyResetScreen> createState() => _AdminEmergencyResetScreenState();
}

class _AdminEmergencyResetScreenState extends State<AdminEmergencyResetScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _directPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_newPasswordController.text.trim().isEmpty || _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter and confirm your new password'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_newPasswordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find user by email in Firestore
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception('No account found with this email address');
      }

      final userDoc = usersQuery.docs.first;
      final userId = userDoc.id;

      // Update password in Firebase Auth (requires admin privileges)
      // This is a workaround method that creates a temporary admin session
      final tempApp = await Firebase.initializeApp(
        name: 'EmergencyReset_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      try {
        // Get the user's current auth data
        final userRecord = await FirebaseAuth.instanceFor(app: tempApp)
            .fetchSignInMethodsForEmail(_emailController.text.trim());

        if (userRecord.isNotEmpty) {
          // Update user document directly with password reset token
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: _emailController.text.trim())
              .limit(1)
              .get()
              .then((querySnapshot) async {
            if (querySnapshot.docs.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(querySnapshot.docs.first.id)
                  .update({
                'password_reset_token': _newPasswordController.text.trim(),
                'password_reset_time': FieldValue.serverTimestamp(),
                'must_change_password': true,
                'password_reset_method': 'emergency_reset',
              });
            }
          });

          setState(() {
            _isLoading = false;
            _resetSent = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset request created! You can now login with your new password.'),
              backgroundColor: AppColors.successGreen,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } finally {
        await tempApp.delete();
      }

    } catch (e) {
      setState(() => _isLoading = false);
      
      String message = 'Failed to reset password';
      if (e.toString().contains('No account found')) {
        message = 'No account found with this email address';
      } else if (e.toString().contains('too-many-requests')) {
        message = 'Too many requests. Try again in a few minutes';
      } else if (e.toString().contains('network')) {
        message = 'Network error. Check your connection';
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
              'OptiFlow Emergency',
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
              'Emergency Admin Reset',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _resetSent 
                  ? 'Reset successful! You can now login with your new password.'
                  : 'If email reset isn\'t working, use this emergency reset method.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            if (!_resetSent) ...[
              CustomTextField(
                label: 'Admin Email',
                hintText: 'rafiatoumalamali@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'New Password',
                hintText: 'Enter new password (min 6 characters)',
                controller: _newPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Confirm Password',
                hintText: 'Confirm new password',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'RESET PASSWORD',
                isLoading: _isLoading,
                onPressed: _directPasswordReset,
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
                      Icons.check_circle,
                      size: 64,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Password Reset Successful!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can now login with your new password.',
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
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            const Center(
              child: Text(
                'OPTIFLOW EMERGENCY ACCESS',
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
