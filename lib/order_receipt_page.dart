import 'package:flutter/material.dart';

import 'home.dart';
import 'models/order.dart';
import 'orders_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';

class OrderReceiptPage extends StatelessWidget {
  const OrderReceiptPage({super.key, required this.order});

  final AppOrder order;

  String _formatPrice(int amount) {
    return '৳$amount';
  }

  String _paymentMethodLabel(String method) {
    return method == 'bkash' ? 'bKash' : 'Card';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
        title: Text(
          'Receipt',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Order Processing',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Order ID: ${order.orderId}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ReceiptInfoRow(label: 'Status', value: 'Processing'),
            _ReceiptInfoRow(
              label: 'Payment',
              value: _paymentMethodLabel(order.paymentMethod),
            ),
            _ReceiptInfoRow(label: 'Transaction', value: order.transactionId),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Items',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...order.items.map(
              (item) => _ReceiptItemRow(
                item: item,
                totalText: _formatPrice(item.totalPrice),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReceiptInfoRow(
              label: 'Total',
              value: _formatPrice(order.totalPrice),
              prominent: true,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Continue Shopping'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.backgroundDark,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('View Orders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  const _ReceiptInfoRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: prominent ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style:
                  (prominent
                          ? AppTextStyles.headingMedium
                          : AppTextStyles.label)
                      .copyWith(
                        color: AppColors.backgroundDark,
                        fontWeight: FontWeight.w800,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({required this.item, required this.totalText});

  final OrderItem item;
  final String totalText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'x${item.quantity}',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            totalText,
            style: AppTextStyles.label.copyWith(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
