import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/auth/hash_service.dart';
import 'dart:math';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  bool _isLoading = true;
  List<UserModel> _drivers = [];
  
  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bizId = authProvider.currentUser?.businessId;
    
    if (bizId != null) {
      final doc = await FirebaseFirestore.instance.collection('businesses').doc(bizId).get();
      if (doc.exists && doc.data()!['drivers'] != null) {
        List<String> driverIds = List<String>.from(doc.data()!['drivers']);
        if (driverIds.isNotEmpty) {
          final usersQuery = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: driverIds).get();
          _drivers = usersQuery.docs.map((d) => UserModel.fromMap(d.data())).toList();
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddDriverModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddDriverModal(),
    ).then((_) => _fetchDrivers());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.currentUser?.role == 'Driver') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Drivers are not permitted to manage fleet data.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Fleet Drivers', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _drivers.isEmpty
              ? _buildEmptyState()
              : _buildDriversList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDriverModal,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Driver', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: AppColors.textLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No drivers added yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Create accounts for your drivers\nto assign optimizing routes.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildDriversList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primaryOrange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(driver.phone, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: driver.isActive ? AppColors.successGreen.withOpacity(0.1) : AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  driver.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: driver.isActive ? AppColors.successGreen : AppColors.errorRed),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _AddDriverModal extends StatefulWidget {
  const _AddDriverModal();

  @override
  State<_AddDriverModal> createState() => _AddDriverModalState();
}

class _AddDriverModalState extends State<_AddDriverModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useCustomPassword = false;
  
  bool _isSaving = false;

  String _generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _createDriverAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentBizId = authProvider.currentUser?.businessId;
      final currentUserId = authProvider.currentUser?.userId;

      if (currentBizId == null) throw Exception("No business linked to the current user.");

      final email = _emailController.text.trim().isEmpty 
          ? '${_phoneController.text.trim()}@optiflow.driver' 
          : _emailController.text.trim();
      
      final plainPassword = _useCustomPassword && _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : _generateTempPassword();
      
      final password = HashService.hashPassword(plainPassword);

      // IMPORTANT: Use a secondary Firebase app to avoid logging out the current admin
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryDriverCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: plainPassword, // Use plain password for Firebase Auth
      );

      final driverUid = userCredential.user!.uid;

      // Create Driver User Document
      final newDriver = UserModel(
        userId: driverUid,
        phone: _phoneController.text.trim(),
        email: email,
        fullName: _nameController.text.trim(),
        role: 'Driver',
        businessId: currentBizId,
        createdAt: DateTime.now(),
        isActive: true,
        mustChangePassword: true,
        createdBy: currentUserId,
        password: password, // Save password to Firestore
      );

      await FirebaseFirestore.instance.collection('users').doc(driverUid).set(newDriver.toMap());

      // Link to business
      await FirebaseFirestore.instance.collection('businesses').doc(currentBizId).update({
        'drivers': FieldValue.arrayUnion([driverUid])
      });

      // Cleanup
      await tempApp.delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver Created! Password: $plainPassword\n(An SMS would be sent in production)'),
            duration: const Duration(seconds: 10),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Creates a secure account for a driver. They will be forced to set a permanent password on first login.', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(height: 24),
            
            CustomTextField(
              label: 'Full Name',
              hintText: 'e.g., John Doe',
              controller: _nameController,
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone Number',
              hintText: '+227...',
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              validator: (v) => v!.isEmpty ? 'Phone is required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email (Optional)',
              hintText: 'For password recovery',
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            const SizedBox(height: 16),
            
            // Password Option Toggle
            Row(
              children: [
                Checkbox(
                  value: _useCustomPassword,
                  onChanged: (value) {
                    setState(() {
                      _useCustomPassword = value ?? false;
                      if (!_useCustomPassword) {
                        _passwordController.clear();
                      }
                    });
                  },
                  activeColor: AppColors.primaryGreen,
                ),
                const Expanded(
                  child: Text(
                    'Set custom password (optional)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Custom Password Field
            if (_useCustomPassword) ...[
              CustomTextField(
                label: 'Driver Password',
                hintText: 'Enter password for driver',
                controller: _passwordController,
                obscureText: true,
                validator: _useCustomPassword ? (v) {
                  if (v!.isEmpty) return 'Password is required when custom password is enabled';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                } : null,
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 32),
            CustomButton(
              text: 'CREATE DRIVER',
              isLoading: _isSaving,
              onPressed: _createDriverAccount,
            ),
          ],
        ),
      ),
    );
  }
}
