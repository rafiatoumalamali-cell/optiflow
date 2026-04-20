import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/shared_preferences_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCountryCode = '+227';
  String _selectedFlag = '🇳🇪';
  int _requiredDigits = 8;
  bool _isButtonEnabled = false;

  final List<Map<String, dynamic>> _countries = [
    {'code': '+227', 'flag': '🇳🇪', 'name': 'Niger', 'digits': 8},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria', 'digits': 10},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana', 'digits': 9},
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      _isButtonEnabled = _phoneController.text.length == _requiredDigits;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';

    try {
      // 💾 Save phone number for business setup later
      await SharedPreferencesService.setUserPhone(fullPhoneNumber);

      await authProvider.signInWithPhone(
        fullPhoneNumber,
        (verificationId) {
          Navigator.pushNamed(context, AppRoutes.otpVerification);
        },
        (errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorRed),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _countries.map((country) {
              return ListTile(
                leading: Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(country['name']!),
                trailing: Text(country['code']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  setState(() {
                    _selectedCountryCode = country['code']!;
                    _selectedFlag = country['flag']!;
                    _requiredDigits = country['digits']!;
                    _phoneController.clear();
                    _isButtonEnabled = false;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
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
            Text(loc?.translate('home_title') ?? 'OptiFlow', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.phonelink_ring, size: 48, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 32),
              Text(
                loc?.translate('phone_auth_title') ?? 'Enter your phone\nnumber',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),
              Text(
                loc?.translate('phone_auth_subtitle') ?? "We'll send a verification code to\nsecure your logistics account.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedFlag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text(_selectedCountryCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_requiredDigits),
                      ],
                      decoration: InputDecoration(
                        hintText: '0' * _requiredDigits,
                        filled: true,
                        fillColor: AppColors.backgroundGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        counterText: "",
                      ),
                      validator: (value) {
                        final fullPhone = '$_selectedCountryCode${value ?? ''}';
                        if (value == null || value.isEmpty) {
                          return loc?.translate('phone_error');
                        }
                        if (!Validators.isValidPhone(fullPhone)) {
                          return loc?.translate('phone_error') ?? 'Invalid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: loc?.translate('send_code') ?? 'Send verification code',
                isLoading: authProvider.isLoading,
                color: _isButtonEnabled ? AppColors.primaryGreen : Colors.grey,
                onPressed: _isButtonEnabled ? _sendCode : () {},
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(Icons.sync, loc?.translate('secure_sync') ?? 'SECURE SYNC'),
                  const SizedBox(width: 20),
                  _buildBadge(Icons.sms, loc?.translate('instant_sms') ?? 'INSTANT SMS'),
                ],
              ),
              const SizedBox(height: 60),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  children: [
                    TextSpan(text: loc?.translate('terms_privacy_prefix') ?? 'By continuing, you agree to our '),
                    TextSpan(
                      text: loc?.translate('terms_of_service') ?? 'Terms of Service',
                      style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRoutes.termsOfService),
                    ),
                    TextSpan(text: loc?.translate('and') ?? ' and '),
                    TextSpan(
                      text: loc?.translate('privacy_policy') ?? 'Privacy Policy.',
                      style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.successGreen),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
      ],
    );
  }
}
