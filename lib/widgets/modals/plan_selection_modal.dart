import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_localizations.dart';
import '../../utils/error_utils.dart';
import '../../services/payment/payment_service.dart';
import '../../models/subscription_model.dart';
import '../../models/transaction_model.dart';

class PlanSelectionModal extends StatefulWidget {
  final String businessId;
  final String email;
  final String currency;
  final Function(SubscriptionModel, TransactionModel) onPaymentSuccess;

  const PlanSelectionModal({
    super.key,
    required this.businessId,
    required this.email,
    this.currency = 'XOF',
    required this.onPaymentSuccess,
  });

  @override
  State<PlanSelectionModal> createState() => _PlanSelectionModalState();
}

class _PlanSelectionModalState extends State<PlanSelectionModal> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  String _selectedPlan = 'Professional';

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'Free',
      'name': 'Free Plan',
      'price': 0.0,
      'features': ['10 Optimizations/mo', 'Single User', 'Standard Support'],
      'color': Colors.grey,
    },
    {
      'id': 'Pro Plan',
      'name': 'Pro Plan',
      'price': 5000.0,
      'features': ['Unlimited Optimizations', 'Cloud Sync', '+ 1,000 CFA/mo per Extra Driver'],
      'color': AppColors.primaryGreen,
    },
    {
      'id': 'Annual Pro',
      'name': 'Annual Pro',
      'price': 50000.0,
      'features': ['Save 10,000 CFA', 'Unlimited Optimizations', '+ 1,000 CFA/mo per Extra Driver'],
      'color': AppColors.primaryOrange,
    },
  ];

  Future<void> _handlePayment(Map<String, dynamic> plan) async {
    if (plan['price'] == 0.0) {
      // Handle Free Plan immediately
      _completeSubscription(plan, null);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await _paymentService.processPayment(
        email: widget.email,
        amount: plan['price'],
        currency: widget.currency,
      );

      if (result != null && result['status'] == 'success') {
        _completeSubscription(plan, result);
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      final paymentFailedLabel = loc?.translate('payment_failed') ?? 'Payment Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$paymentFailedLabel: ${ErrorUtils.localizeError(e, context, includePrefix: false)}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _completeSubscription(Map<String, dynamic> plan, Map<String, dynamic>? paymentResult) {
    final subId = const Uuid().v4();
    final txnId = const Uuid().v4();

    final subscription = SubscriptionModel(
      subscriptionId: subId,
      businessId: widget.businessId,
      plan: plan['id'],
      price: plan['price'],
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      status: 'Active',
    );

    final transaction = TransactionModel(
      transactionId: txnId,
      businessId: widget.businessId,
      amount: plan['price'],
      currency: widget.currency,
      status: 'success',
      type: 'subscription',
      paymentMethod: paymentResult?['provider'] ?? 'System',
      createdAt: DateTime.now(),
      reference: paymentResult?['reference'],
    );

    widget.onPaymentSuccess(subscription, transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Business Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Text('Accelerate your logistics optimization.', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          const SizedBox(height: 24),
          ..._plans.map((plan) => _buildPlanCard(plan)).toList(),
          const SizedBox(height: 24),
          const Text(
            'Payments are processed securely via encrypted gateways.',
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    bool isSelected = _selectedPlan == plan['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? plan['color'] : Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? plan['color'].withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${widget.currency} ${plan['price']}/mo', style: TextStyle(fontWeight: FontWeight.bold, color: plan['color'])),
                  const SizedBox(height: 8),
                  ... (plan['features'] as List).map((f) => Row(children: [
                    Icon(Icons.check, size: 12, color: plan['color']),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ])),
                ],
              ),
            ),
            if (isSelected)
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _handlePayment(plan),
                style: ElevatedButton.styleFrom(backgroundColor: plan['color'], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Activate'),
              ),
          ],
        ),
      ),
    );
  }
}
