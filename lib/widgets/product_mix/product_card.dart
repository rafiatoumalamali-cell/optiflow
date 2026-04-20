import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String unit;
  final String price;
  final String cost;
  final String profit;
  final String? imageUrl;

  const ProductCard({
    super.key,
    required this.name,
    required this.unit,
    required this.price,
    required this.cost,
    required this.profit,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.inventory_2, color: AppColors.textLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('PRICE', price),
                    _buildMetric('COST', cost),
                    _buildMetric('PROFIT', profit, isProfit: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {bool isProfit = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isProfit ? AppColors.successGreen : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
