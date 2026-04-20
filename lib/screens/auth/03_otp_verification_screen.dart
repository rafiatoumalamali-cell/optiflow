import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_utils.dart';
import '../../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _timerSeconds = 45;
  Timer? _timer;
  bool _isComplete = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    for (var controller in _controllers) {
      controller.addListener(_checkCompletion);
    }
  }

  void _checkCompletion() {
    bool complete = _controllers.every((c) => c.text.isNotEmpty);
    if (complete != _isComplete) {
      setState(() => _isComplete = complete);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete || _isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String otp = _controllers.map((c) => c.text).join();
      
      await authProvider.verifyOtp(otp);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.localizeError(e, context)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
            const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              loc?.translate('verify_number') ?? 'Verify your number',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              '${loc?.translate('enter_otp_prefix') ?? 'Enter the 6-digit code sent to'} +227 XX XX XX XX${loc?.translate('enter_otp_suffix') ?? '. This helps us secure your logistics hub access.'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 40),
            // OTP Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  '${loc?.translate('resend_available') ?? 'Resend available in'} $_timerSeconds seconds',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
            if (_timerSeconds == 0)
              TextButton(
                onPressed: () {
                  setState(() => _timerSeconds = 45);
                  _startTimer();
                },
                child: Text(loc?.translate('resend_code') ?? 'RESEND CODE', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 40),
            // Secure Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.successGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SECURE VERIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                        Text(loc?.translate('active_status') ?? 'ACTIVE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            CustomButton(
              text: loc?.translate('verify_continue') ?? 'Verify and continue',
              icon: Icons.arrow_forward,
              isLoading: _isVerifying,
              color: _isComplete ? AppColors.primaryGreen : Colors.grey,
              onPressed: _isComplete ? _verifyOtp : () {},
            ),
            const SizedBox(height: 20),
            const Text(
              'OPTIFLOW ENTERPRISE - SECURE AUTH V2.4',
              style: TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: AppColors.backgroundGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
