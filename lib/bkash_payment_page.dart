import 'package:flutter/material.dart';

import 'checkout_verification_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/checkout_session.dart';

class BkashPaymentPage extends StatefulWidget {
  const BkashPaymentPage({super.key, required this.session});

  final CheckoutSession session;

  @override
  State<BkashPaymentPage> createState() => _BkashPaymentPageState();
}

class _BkashPaymentPageState extends State<BkashPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutVerificationPage(
          result: PaymentResult(
            session: widget.session,
            paymentMethod: 'bkash',
            transactionId: _fakeTransactionId('BK'),
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^01\d{9}$').hasMatch(phone)) {
      return 'Enter a valid Bangladesh phone number';
    }
    return null;
  }

  String _fakeTransactionId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return PaymentInputShell(
      title: 'bKash Payment',
      subtitle: 'Mock payment only. No real charge will be made.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'bKash Phone Number',
                hintText: '01XXXXXXXXX',
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _continue,
              style: primaryPaymentButtonStyle(),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentInputShell extends StatelessWidget {
  const PaymentInputShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle primaryPaymentButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
