import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/firebase_verification_service.dart';
import '../../widgets/common/loading_widget.dart';

class FirebaseVerificationScreen extends StatefulWidget {
  const FirebaseVerificationScreen({super.key});

  @override
  State<FirebaseVerificationScreen> createState() => _FirebaseVerificationScreenState();
}

class _FirebaseVerificationScreenState extends State<FirebaseVerificationScreen> {
  Map<String, dynamic>? _verificationResults;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runVerification();
  }

  Future<void> _runVerification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await FirebaseVerificationService.verifyFirebaseSetup();
      setState(() {
        _verificationResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Firebase Verification',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: _runVerification,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verifying Firebase setup...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Verification Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _runVerification,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_verificationResults == null) {
      return const Center(
        child: Text('No verification results available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildPlatformInfo(),
          const SizedBox(height: 16),
          _buildServiceCards(),
          const SizedBox(height: 16),
          _buildReportButton(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _verificationResults!['overall_status'] ?? 'unknown';
    final isSuccess = status == 'success';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? AppColors.successGreen : AppColors.errorRed,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? AppColors.successGreen : AppColors.errorRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    final platformInfo = _verificationResults!['platform_info'];
    if (platformInfo == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Platform', platformInfo['platform']?.toString() ?? 'Unknown'),
            _buildInfoRow('Debug Mode', platformInfo['is_debug_mode']?.toString() ?? 'Unknown'),
            _buildInfoRow('Release Mode', platformInfo['is_release_mode']?.toString() ?? 'Unknown'),
            _buildInfoRow('Firebase Core Version', platformInfo['firebase_core_version']?.toString() ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildServiceCard('Firebase Core', _verificationResults!['firebase_core']),
        _buildServiceCard('Firebase Auth', _verificationResults!['firebase_auth']),
        _buildServiceCard('Firestore', _verificationResults!['firestore']),
        _buildServiceCard('Messaging', _verificationResults!['messaging']),
        _buildServiceCard('Storage', _verificationResults!['storage']),
      ],
    );
  }

  Widget _buildServiceCard(String title, Map<String, dynamic>? service) {
    if (service == null) return const SizedBox.shrink();
    
    final status = service['status'] ?? 'unknown';
    final isSuccess = status == 'success';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? AppColors.successGreen : AppColors.errorRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppColors.successGreen : AppColors.errorRed,
                  ),
                ),
              ],
            ),
            if (service['error'] != null) ...[
              const SizedBox(height: 4),
              Text(
                service['error'],
                style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textLight),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final report = FirebaseVerificationService.generateReport(_verificationResults!);
          _showReportDialog(report);
        },
        icon: const Icon(Icons.description),
        label: const Text('View Full Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showReportDialog(String report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Report'),
        content: SingleChildScrollView(
          child: Text(
            report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
