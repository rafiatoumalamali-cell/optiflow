import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../routes/app_routes.dart';
import '../../services/shared_preferences_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 🔑 Step 4: Admin Account (Pre-seeded)
      if (_emailController.text.trim() == 'rafiatoumalamali@gmail.com' && _passwordController.text == 'Rafia123@') {
        await SharedPreferencesService.setIsLoggedIn(true);
        await SharedPreferencesService.setUserRole('admin');
        await SharedPreferencesService.setUserEmail(_emailController.text.trim());
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        return;
      }

      // 🔐 Firebase Auth Logic
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        // Fetch user data from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final String role = userData['role'] ?? 'Business Owner';
          final String bizId = userData['business_id'] ?? '';
          
          // Fetch business name
          String bizName = '';
          if (bizId.isNotEmpty) {
            final bizDoc = await FirebaseFirestore.instance.collection('businesses').doc(bizId).get();
            if (bizDoc.exists) bizName = bizDoc.data()?['name'] ?? '';
          }

          // Step 5: Save to SharedPreferences
          await SharedPreferencesService.setIsLoggedIn(true);
          await SharedPreferencesService.setUserRole(role);
          await SharedPreferencesService.setUserEmail(_emailController.text.trim());
          await SharedPreferencesService.setBusinessId(bizId);
          await SharedPreferencesService.setBusinessName(bizName);

          if (mounted) {
            if (role == 'admin') {
              Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
            } else if (role == 'Driver') {
              if (userData['must_change_password'] == true) {
                Navigator.pushReplacementNamed(context, AppRoutes.forcePasswordChange);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.driverHome);
              }
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
            }
          }
        } else {
          throw Exception('User data not found in registration records.');
        }
      }
    } on FirebaseAuthException catch (e) {
      final loc = AppLocalizations.of(context);
      String message = loc?.translate('login_failed') ?? 'Login failed';
      if (e.code == 'user-not-found') message = loc?.translate('email_not_found') ?? 'No user found for that email.';
      else if (e.code == 'wrong-password') message = loc?.translate('wrong_password') ?? 'Wrong password provided.';
      else if (e.code == 'invalid-email') message = loc?.translate('invalid_email_address') ?? 'The email address is badly formatted.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Email',
                      hintText: 'admin@company.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => Validators.isValidEmail(v?.trim() ?? '')
                        ? null
                        : loc?.translate('invalid_email_address') ?? 'Invalid email address',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      hintText: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (v) => Validators.isValidPassword(v ?? '')
                        ? null
                        : loc?.translate('password_min_length') ?? 'Password must be at least 6 characters',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                          child: Text(
                            AppLocalizations.of(context)?.translate('forgot_password') ?? 'Forgot Password?',
                            style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'SIGN IN',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 24),
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
