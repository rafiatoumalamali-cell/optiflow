import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/security_questions.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../services/auth/hash_service.dart';
import '../../services/database/counter_service.dart';
import '../../models/user_model.dart';
import '../../services/shared_preferences_service.dart';
import '../../routes/app_routes.dart';

class SecurityQuestionsSetupScreen extends StatefulWidget {
  const SecurityQuestionsSetupScreen({super.key});

  @override
  State<SecurityQuestionsSetupScreen> createState() => _SecurityQuestionsSetupScreenState();
}

class _SecurityQuestionsSetupScreenState extends State<SecurityQuestionsSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _answerControllers = {};
  final Map<String, String> _selectedQuestions = {};
  final Map<String, String> _selectedQuestionIds = {};
  bool _isLoading = false;
  
  // Registration data passed from business setup
  Map<String, dynamic>? _registrationData;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _getRegistrationData();
  }

  void _getRegistrationData() {
    _registrationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  void _initializeQuestions() {
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
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSecurityQuestions() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if all answers are provided
    bool allAnswersFilled = true;
    for (int i = 1; i <= 3; i++) {
      final key = 'question_$i';
      if (_answerControllers[key]?.text.trim().isEmpty ?? true) {
        allAnswersFilled = false;
        break;
      }
    }

    if (!allAnswersFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all security questions'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_registrationData != null) {
        // Complete registration process
        await _completeRegistration();
      } else {
        // Update existing user with security questions
        final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          throw Exception('No user logged in');
        }

        await authProvider.updateUserSecurityQuestions(
          userId: currentUser.userId,
          securityQuestion: _selectedQuestions['question_1']!,
          securityAnswer: _answerControllers['question_1']!.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security questions saved successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save security questions: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (_registrationData == null) return;

    final String bizId = _registrationData!['businessId'];
    final String bizName = _registrationData!['businessName'];
    final String fullName = _registrationData!['fullName'];
    final String email = _registrationData!['email'];
    final String password = _registrationData!['password'];
    final String city = _registrationData!['city'];
    final String country = _registrationData!['country'];
    final String currency = _registrationData!['currency'];

    final String seqId = await CounterService.getNextUserSequentialId();
    final String hashedPassword = HashService.hashPassword(password);

    // 1. Create Auth User
    firebase_auth.UserCredential credential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String uid = credential.user!.uid;

    // 2. Prepare Batch Writes for Atomic Persistence
    final batch = FirebaseFirestore.instance.batch();

    // Create Business
    final bizRef = FirebaseFirestore.instance.collection('businesses').doc(bizId);
    batch.set(bizRef, {
      'business_id': bizId,
      'name': bizName,
      'country': country,
      'currency': currency,
      'city': city,
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
      email: email,
      fullName: fullName,
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
    await SharedPreferencesService.setUserEmail(email);
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
                const Text(
                  'Set Up Security Questions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'These questions will help you reset your password if you forget it. Please provide answers that you\'ll remember.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: ListView(
                    children: [
                      for (int i = 1; i <= 3; i++) ...[
                        _buildQuestionCard(
                          questionNumber: i,
                          question: _selectedQuestions['question_$i']!,
                          controller: _answerControllers['question_$i']!,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),

                CustomButton(
                  text: 'SAVE SECURITY QUESTIONS',
                  isLoading: _isLoading,
                  onPressed: _saveSecurityQuestions,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int questionNumber,
    required String question,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
}
