import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message = 'Loading...',
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: color != null 
                ? AlwaysStoppedAnimation<Color>(color!)
                : AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            strokeWidth: 3.0,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
