import 'package:flutter/material.dart';
import '../../services/auth_integration_test.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/loading_widget.dart';

class AuthIntegrationTestScreen extends StatefulWidget {
  const AuthIntegrationTestScreen({super.key});

  @override
  State<AuthIntegrationTestScreen> createState() => _AuthIntegrationTestScreenState();
}

class _AuthIntegrationTestScreenState extends State<AuthIntegrationTestScreen> {
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runIntegrationTest();
  }

  Future<void> _runIntegrationTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await AuthIntegrationTest.testAuthIntegration();
      setState(() {
        _testResults = results;
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
          'Auth Integration Test',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: _runIntegrationTest,
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
            Text('Testing authentication integration...'),
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
              'Integration Test Failed',
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
              onPressed: _runIntegrationTest,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_testResults == null) {
      return const Center(
        child: Text('No test results available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStatus(),
          const SizedBox(height: 16),
          _buildServiceStatusCards(),
          const SizedBox(height: 16),
          _buildDataFlowStatus(),
          const SizedBox(height: 16),
          _buildReportButton(),
        ],
      ),
    );
  }

  Widget _buildOverallStatus() {
    final status = _testResults!['overall_status'] ?? 'unknown';
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
                    'Integration Status',
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

  Widget _buildServiceStatusCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildServiceCard('Auth Provider', _testResults!['auth_provider']),
        _buildServiceCard('Business Provider', _testResults!['business_provider']),
        _buildServiceCard('Route Provider', _testResults!['route_provider']),
        _buildServiceCard('Subscription Provider', _testResults!['subscription_provider']),
      ],
    );
  }

  Widget _buildServiceCard(String title, Map<String, dynamic>? service) {
    if (service == null) return const SizedBox.shrink();
    
    final status = service!['status'] ?? 'unknown';
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
            _buildServiceDetails(service),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetails(Map<String, dynamic> service) {
    final details = <String, dynamic>{};
    
    service.forEach((key, value) {
      if (key != 'status' && key != 'error') {
        details[key] = value;
      }
    });
    
    if (details.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...details.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                entry.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildDataFlowStatus() {
    final dataFlow = _testResults!['data_flow'];
    if (dataFlow == null) return const SizedBox.shrink();
    
    final status = dataFlow['status'] ?? 'unknown';
    final isSuccess = status == 'success';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Flow Test',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? AppColors.successGreen : AppColors.errorRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cross-Service Integration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? AppColors.successGreen : AppColors.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'User → Business → Route Data Flow',
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            if (dataFlow['issues'] != null && dataFlow['issues'].isNotEmpty) ...[
              const Text(
                'Issues Found:',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...dataFlow['issues'].map<Widget>((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue,
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final report = AuthIntegrationTest.generateReport(_testResults!);
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
        title: const Text('Integration Test Report'),
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
