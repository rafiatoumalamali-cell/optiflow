import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RoleChangeScreen extends StatefulWidget {
  const RoleChangeScreen({super.key});

  @override
  State<RoleChangeScreen> createState() => _RoleChangeScreenState();
}

class _RoleChangeScreenState extends State<RoleChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _userFound = false;
  String? _currentRole;
  String? _userId;
  String _selectedRole = 'Admin';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _findUser() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email address'),
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
            content: Text('No user found with this email address'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      final userDoc = usersQuery.docs.first;
      final userData = userDoc.data();

      setState(() {
        _userFound = true;
        _currentRole = userData['role'] ?? 'Unknown';
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

  Future<void> _changeRole() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please find a user first'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .update({
        'role': _selectedRole,
        'role_updated_at': FieldValue.serverTimestamp(),
        'role_updated_by': 'admin_panel',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role updated successfully to $_selectedRole!'),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset form
      setState(() {
        _userFound = false;
        _currentRole = null;
        _userId = null;
        _emailController.clear();
        _passwordController.clear();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Change User Role',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find a user and change their role. This action requires admin privileges.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                if (!_userFound) ...[
                  CustomTextField(
                    label: 'User Email',
                    hintText: 'Enter user email address',
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
                    text: 'FIND USER',
                    isLoading: _isLoading,
                    onPressed: _findUser,
                  ),
                ],

                if (_userFound) ...[
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
                          'User Found:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${_emailController.text.trim()}',
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Role: $_currentRole',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Select New Role:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _buildRoleOption('Admin', Icons.admin_panel_settings),
                        _buildRoleOption('Business Owner', Icons.business),
                        _buildRoleOption('Manager', Icons.supervisor_account),
                        _buildRoleOption('Driver', Icons.drive_eta),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'CHANGE ROLE TO $_selectedRole',
                    isLoading: _isLoading,
                    onPressed: _changeRole,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String role, IconData icon) {
    return RadioListTile<String>(
      value: role,
      groupValue: _selectedRole,
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
        });
      },
      title: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Text(
            role,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      activeColor: AppColors.primaryGreen,
    );
  }
}
