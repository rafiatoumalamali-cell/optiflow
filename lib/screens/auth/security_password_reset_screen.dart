import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class SecurityPasswordResetScreen extends StatefulWidget {
  const SecurityPasswordResetScreen({super.key});

  @override
  State<SecurityPasswordResetScreen> createState() => _SecurityPasswordResetScreenState();
}

class _SecurityPasswordResetScreenState extends State<SecurityPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _userFound = false;
  bool _questionVerified = false;
  String? _securityQuestion;
  String? _userId;

  @override
  void dispose() {
    _emailController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _findUser() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No account found with this email address'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      final userDoc = usersQuery.docs.first;
      final userData = userDoc.data();
      
      if (userData['security_question'] == null || userData['security_answer'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This account does not have security questions set up. Please contact support.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      setState(() {
        _userFound = true;
        _securityQuestion = userData['security_question'];
        _userId = userDoc.id;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding user: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifySecurityAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer the security question'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final storedAnswer = userData['security_answer'] as String;
      final providedAnswer = _answerController.text.trim().toLowerCase();

      if (providedAnswer != storedAnswer.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect answer. Please try again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      setState(() {
        _questionVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security answer verified! You can now set a new password.'),
          backgroundColor: AppColors.successGreen,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying answer: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update user with new password
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
        'password_reset_token': _newPasswordController.text.trim(),
        'password_reset_time': FieldValue.serverTimestamp(),
        'must_change_password': true,
        'password_reset_method': 'security_questions',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! You can now login with your new password.'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login screen
      Navigator.pushReplacementNamed(context, '/login');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting password: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              'OptiFlow',
              style: TextStyle(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  _questionVerified ? 'Set New Password' : 'Reset Password',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _questionVerified 
                      ? 'Enter your new password below.'
                      : _userFound 
                          ? 'Answer your security question to reset your password.'
                          : 'Enter your email address to find your account.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Step 1: Email Input
                        if (!_userFound) ...[
                          CustomTextField(
                            label: 'Email Address',
                            hintText: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'FIND ACCOUNT',
                            isLoading: _isLoading,
                            onPressed: _findUser,
                          ),
                        ],

                        // Step 2: Security Question
                        if (_userFound && !_questionVerified) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGray.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Security Question:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _securityQuestion ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomTextField(
                            label: 'Your Answer',
                            hintText: 'Enter your answer',
                            controller: _answerController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Answer is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'VERIFY ANSWER',
                            isLoading: _isLoading,
                            onPressed: _verifySecurityAnswer,
                          ),
                        ],

                        // Step 3: New Password
                        if (_questionVerified) ...[
                          CustomTextField(
                            label: 'New Password',
                            hintText: 'Enter new password (min 6 characters)',
                            controller: _newPasswordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Password is required';
                              }
                              if (value.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Confirm Password',
                            hintText: 'Confirm new password',
                            controller: _confirmPasswordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'RESET PASSWORD',
                            isLoading: _isLoading,
                            onPressed: _resetPassword,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
