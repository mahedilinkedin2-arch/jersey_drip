import 'package:flutter/material.dart';

import 'bkash_payment_page.dart';
import 'checkout_verification_page.dart';
import 'core/theme/app_spacing.dart';
import 'models/checkout_session.dart';

class CardPaymentPage extends StatefulWidget {
  const CardPaymentPage({super.key, required this.session});

  final CheckoutSession session;

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _cvvController.dispose();
    _expiryController.dispose();
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
            paymentMethod: 'card',
            transactionId: _fakeTransactionId('CD'),
          ),
        ),
      ),
    );
  }

  String? _validateCardNumber(String? value) {
    final cardNumber = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{16}$').hasMatch(cardNumber)) {
      return 'Enter a 16-digit card number';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    final cvv = value?.trim() ?? '';
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      return 'Enter a valid CVV';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    final expiry = value?.trim() ?? '';
    final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(expiry);
    if (match == null) {
      return 'Use MM/YY format';
    }

    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final expiryDate = DateTime(year, month + 1, 0, 23, 59, 59);

    if (!expiryDate.isAfter(DateTime.now())) {
      return 'Expiry must be a future date';
    }

    return null;
  }

  String _fakeTransactionId(String prefix) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return PaymentInputShell(
      title: 'Card Payment',
      subtitle: 'Mock card payment only. No real card will be charged.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '16 digits',
              ),
              validator: _validateCardNumber,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                    ),
                    validator: _validateExpiry,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    obscureText: true,
                    validator: _validateCvv,
                  ),
                ),
              ],
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
