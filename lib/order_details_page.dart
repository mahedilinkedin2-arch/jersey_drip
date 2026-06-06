import 'package:flutter/material.dart';

import 'models/order.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order});

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
          'Order Details',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Order ${order.orderId}',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(label: 'Status', value: order.status),
            _DetailRow(
              label: 'Payment',
              value: _paymentMethodLabel(order.paymentMethod),
            ),
            _DetailRow(label: 'Payment Status', value: order.paymentStatus),
            _DetailRow(label: 'Transaction', value: order.transactionId),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Items',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...order.items.map(
              (item) => _OrderDetailItem(
                item: item,
                totalText: _formatPrice(item.totalPrice),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              label: 'Total',
              value: _formatPrice(order.totalPrice),
              prominent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

class _OrderDetailItem extends StatelessWidget {
  const _OrderDetailItem({required this.item, required this.totalText});

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
