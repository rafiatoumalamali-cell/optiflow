import 'package:flutter/material.dart';
import '../../utils/environment.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../widgets/common/loading_widget.dart';

class EnvironmentVerificationScreen extends StatefulWidget {
  const EnvironmentVerificationScreen({super.key});

  @override
  State<EnvironmentVerificationScreen> createState() => _EnvironmentVerificationScreenState();
}

class _EnvironmentVerificationScreenState extends State<EnvironmentVerificationScreen> {
  Map<String, dynamic>? _verificationResults;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runEnvironmentVerification();
  }

  Future<void> _runEnvironmentVerification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Environment.verifyEnvironmentConfiguration();
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
          'Environment Verification',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: _runEnvironmentVerification,
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
            Text('Verifying environment configuration...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorRed),
            const SizedBox(height: 16),
            Text(
              'Environment Verification Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.errorRed),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _runEnvironmentVerification,
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
          _buildEnvironmentInfo(),
          const SizedBox(height: 16),
          _buildApiUrlStatus(),
          const SizedBox(height: 16),
          _buildGoogleMapsStatus(),
          const SizedBox(height: 16),
          _buildEnvironmentSwitching(),
          const SizedBox(height: 16),
          _buildOverallStatus(),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildEnvironmentInfo() {
    final envInfo = Environment.getEnvironmentInfo();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Environment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Environment', envInfo['current_environment']),
            _buildInfoRow('Development Mode', envInfo['is_development'].toString()),
            _buildInfoRow('Staging Mode', envInfo['is_staging'].toString()),
            _buildInfoRow('Production Mode', envInfo['is_production'].toString()),
            _buildInfoRow('Debug Logs', envInfo['debug_logs_enabled'].toString()),
            _buildInfoRow('Mock Data', envInfo['mock_data_enabled'].toString()),
            _buildInfoRow('App Name', Environment.appName),
            _buildInfoRow('App Version', Environment.appVersion),
          ],
        ),
      ),
    );
  }

  Widget _buildApiUrlStatus() {
    final apiUrl = _verificationResults!['api_url'];
    final isSecure = apiUrl['is_secure'];
    final isLocalhost = apiUrl['is_localhost'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSecure ? Icons.lock : Icons.lock_open,
                  color: isSecure ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'API Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('URL', apiUrl['url']),
            _buildInfoRow('Secure', isSecure ? 'Yes' : 'No'),
            _buildInfoRow('Localhost', isLocalhost ? 'Yes' : 'No'),
            _buildInfoRow('Status', apiUrl['status']),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMapsStatus() {
    final maps = _verificationResults!['google_maps'];
    final keyValid = maps['key_valid'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  keyValid ? Icons.check_circle : Icons.error,
                  color: keyValid ? AppColors.successGreen : AppColors.errorRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Google Maps Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Key Provided', maps['key_provided'] ? 'Yes' : 'No'),
            _buildInfoRow('Key Valid', keyValid ? 'Yes' : 'No'),
            _buildInfoRow('Key Format', maps['key_format']),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSwitching() {
    final switching = _verificationResults!['environment_switching'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment Switching',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Current', switching['current']),
            _buildInfoRow('Can Switch to Production', switching['can_switch_to_production'].toString()),
            _buildInfoRow('Can Switch to Staging', switching['can_switch_to_staging'].toString()),
            _buildInfoRow('Can Switch to Development', switching['can_switch_to_development'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatus() {
    final status = _verificationResults!['overall_status'];
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
                  const Text(
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

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Environment.switchEnvironment(EnvironmentType.development);
              _runEnvironmentVerification();
            },
            icon: const Icon(Icons.developer_mode),
            label: const Text('Switch to Development'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Environment.switchEnvironment(EnvironmentType.staging);
              _runEnvironmentVerification();
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Switch to Staging'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Environment.switchEnvironment(EnvironmentType.production);
              _runEnvironmentVerification();
            },
            icon: const Icon(Icons.production_quantity_limits),
            label: const Text('Switch to Production'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
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
}
