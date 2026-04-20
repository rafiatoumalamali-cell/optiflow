import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/modals/plan_selection_modal.dart';

class OptimizationGuard {
  static Future<void> checkAndNavigate(BuildContext context, String routeName) async {
    final bizProv = Provider.of<BusinessProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    bool canOptimize = await bizProv.consumeOptimization();

    if (canOptimize && context.mounted) {
      Navigator.pushNamed(context, routeName);
    } else if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) => SingleChildScrollView(
            controller: controller,
            child: PlanSelectionModal(
              businessId: bizProv.currentBusiness?.businessId ?? '',
              email: authProv.currentUser?.email ?? '',
              onPaymentSuccess: (sub, txn) async {
                await bizProv.updateSubscription(sub, txn);
                if (context.mounted) {
                  Navigator.pop(context); // Close modal
                  Navigator.pushNamed(context, routeName); // Proceed after upgrading
                }
              },
            ),
          ),
        ),
      );
    }
  }
}
