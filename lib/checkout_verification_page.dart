import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'payment_success_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/checkout_session.dart';

class CheckoutVerificationPage extends StatefulWidget {
  const CheckoutVerificationPage({super.key, required this.result});

  final PaymentResult result;

  @override
  State<CheckoutVerificationPage> createState() =>
      _CheckoutVerificationPageState();
}

class _CheckoutVerificationPageState extends State<CheckoutVerificationPage> {
  bool _sending = false;
  bool _checking = false;

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _sending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      if (!mounted) return;
      _showMessage('Verification email sent');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to send verification email');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _continueAfterVerification() async {
    setState(() {
      _checking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(result: widget.result),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.backgroundDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.accent,
                    size: 54,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verify Payment Email',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We will use email verification as the mock confirmation step for this payment.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.backgroundDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton(
                    onPressed: _sending ? null : _sendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.backgroundDark,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_sending ? 'Sending...' : 'Send Email'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _checking ? null : _continueAfterVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_checking ? 'Checking...' : 'I Have Verified'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
