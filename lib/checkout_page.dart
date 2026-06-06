import 'package:flutter/material.dart';

import 'bkash_payment_page.dart';
import 'card_payment_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/cart_item.dart';
import 'models/checkout_session.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, required this.items});

  final List<CartItem> items;

  int get _totalPrice {
    return items.fold<int>(0, (total, item) => total + item.totalPrice);
  }

  String _formatPrice(int amount) {
    return '৳$amount';
  }

  void _openBkashPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BkashPaymentPage(
          session: CheckoutSession(items: items, totalPrice: _totalPrice),
        ),
      ),
    );
  }

  void _openCardPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardPaymentPage(
          session: CheckoutSession(items: items, totalPrice: _totalPrice),
        ),
      ),
    );
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
          'Checkout',
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
              'Selected Items',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...items.map(
              (item) => _CheckoutItemRow(
                item: item,
                totalText: _formatPrice(item.totalPrice),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CheckoutTotal(totalText: _formatPrice(_totalPrice)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Payment Method',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PaymentMethodButton(
              icon: Icons.phone_android,
              title: 'bKash Mock Payment',
              subtitle: 'Validate a Bangladesh phone number',
              onTap: () => _openBkashPayment(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _PaymentMethodButton(
              icon: Icons.credit_card,
              title: 'Card Payment',
              subtitle: 'Validate card number, CVV, and expiry',
              onTap: () => _openCardPayment(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({required this.item, required this.totalText});

  final CartItem item;
  final String totalText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
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

class _CheckoutTotal extends StatelessWidget {
  const _CheckoutTotal({required this.totalText});

  final String totalText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total',
              style: AppTextStyles.label.copyWith(color: Colors.white70),
            ),
          ),
          Text(
            totalText,
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  const _PaymentMethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
