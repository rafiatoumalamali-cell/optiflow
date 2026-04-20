import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../utils/validators.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/auth/hash_service.dart';
import '../../services/database/counter_service.dart';
import '../../models/user_model.dart';
import '../../utils/security_questions.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  // Security question fields
  final Map<String, TextEditingController> _answerControllers = {};
  final Map<String, String> _selectedQuestions = {};
  final Map<String, String> _selectedQuestionIds = {};
  
  String _selectedCountry = 'Niger';
  String _selectedCurrency = 'XOF';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSecurityQuestions();
  }

  void _initializeSecurityQuestions() {
    final availableQuestions = SecurityQuestions.getAvailableQuestions();
    final random = DateTime.now().millisecond;
    
    // Select 3 random questions
    for (int i = 0; i < 3; i++) {
      final questionIndex = (random + i) % availableQuestions.length;
      final question = availableQuestions[questionIndex];
      final key = 'question_${i + 1}';
      
      _selectedQuestions[key] = question['question']!;
      _selectedQuestionIds[key] = question['id']!;
      _answerControllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    
    // Dispose security question controllers
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    // Check if all security questions are answered
    bool allQuestionsAnswered = true;
    for (int i = 1; i <= 3; i++) {
      final key = 'question_$i';
      if (_answerControllers[key]?.text.trim().isEmpty ?? true) {
        allQuestionsAnswered = false;
        break;
      }
    }

    if (!allQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all security questions'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Complete registration with security questions
    final String bizId = _businessNameController.text.trim().toLowerCase().replaceAll(' ', '_');
    final String bizName = _businessNameController.text.trim();

    await _completeRegistrationWithSecurityQuestions(bizId, bizName);
  }

  Future<void> _completeRegistrationWithSecurityQuestions(String bizId, String bizName) async {
    setState(() => _isLoading = true);

    try {
      final String seqId = await CounterService.getNextUserSequentialId();
      final String hashedPassword = HashService.hashPassword(_passwordController.text.trim());

      // 1. Create Auth User
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = credential.user!.uid;

      // 2. Prepare Batch Writes for Atomic Persistence
      final batch = FirebaseFirestore.instance.batch();

      // Create Business
      final bizRef = FirebaseFirestore.instance.collection('businesses').doc(bizId);
      batch.set(bizRef, {
        'business_id': bizId,
        'name': bizName,
        'country': _selectedCountry,
        'currency': _selectedCurrency,
        'city': _cityController.text.trim(),
        'owner_id': uid,
        'subscription_plan': 'Free Trial',
        'remaining_free_optimizations': 30,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Create User with security questions
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final newUser = UserModel(
        userId: uid,
        phone: '', // Will be updated later
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: 'Business Owner',
        businessId: bizId,
        createdAt: DateTime.now(),
        password: hashedPassword,
        securityQuestion: _selectedQuestions['question_1']!,
        securityAnswer: _answerControllers['question_1']!.text.trim().toLowerCase(),
      );

      batch.set(userRef, newUser.toMap());

      // 3. Commit Batch
      await batch.commit();

      // 4. Save to SharedPreferences
      await SharedPreferencesService.setIsLoggedIn(true);
      await SharedPreferencesService.setUserRole('Business Owner');
      await SharedPreferencesService.setUserEmail(_emailController.text.trim());
      await SharedPreferencesService.setBusinessId(bizId);
      await SharedPreferencesService.setBusinessName(bizName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      // Navigate to home dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);

    } catch (e, stack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create account: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
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
        title: const Text('Setup Business Account', style: TextStyle(color: AppColors.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Business Name',
                hintText: 'e.g. Sahel Logistics',
                controller: _businessNameController,
                validator: (v) => v!.isEmpty ? 'Enter business name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Full Name',
                hintText: 'e.g. Rafiatou Malam Ali',
                controller: _fullNameController,
                validator: (v) => v!.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Login Email',
                hintText: 'admin@company.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.isValidEmail(v?.trim() ?? '')
                    ? null
                    : loc?.translate('invalid_email_address') ?? 'Invalid email',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Create Password',
                hintText: 'Min 6 characters',
                controller: _passwordController,
                obscureText: true,
                validator: (v) => Validators.isValidPassword(v ?? '') ? null : 'Min 6 characters',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Confirm Password',
                hintText: 'Re-enter password',
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (v) => v == _passwordController.text ? null : 'Passwords do not match',
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _buildDropdown('Country', _selectedCountry, ['Niger', 'Nigeria', 'Ghana'])),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('Currency', _selectedCurrency, ['XOF', 'NGN', 'GHS'])),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Primary City',
                hintText: 'e.g. Niamey',
                controller: _cityController,
                validator: (v) => v!.isEmpty ? 'Enter city' : null,
              ),
              const SizedBox(height: 32),
              
              // Security Questions Section
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
                      'Security Questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These questions will help you reset your password if you forget it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Security Question Fields
                    for (int i = 1; i <= 3; i++) ...[
                      _buildSecurityQuestionField(
                        questionNumber: i,
                        question: _selectedQuestions['question_$i']!,
                        controller: _answerControllers['question_$i']!,
                      ),
                      if (i < 3) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'CREATE ACCOUNT & DASHBOARD',
                isLoading: _isLoading,
                onPressed: _handleSetup,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSecurityQuestionField({
    required int questionNumber,
    required String question,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Your Answer',
            hintText: 'Enter your answer',
            controller: controller,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide an answer';
              }
              if (value.trim().length < 2) {
                return 'Answer must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value, isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() {
                if (label == 'Country') _selectedCountry = v!;
                else _selectedCurrency = v!;
              }),
            ),
          ),
        ),
      ],
    );
  }
}
