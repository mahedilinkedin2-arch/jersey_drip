import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'email_otp_service.dart';

enum OtpPurpose {
  signup('signup'),
  payment('payment');

  const OtpPurpose(this.value);

  final String value;
}

class OtpVerificationResult {
  const OtpVerificationResult({
    required this.success,
    required this.invalidated,
    this.message,
  });

  final bool success;
  final bool invalidated;
  final String? message;
}

class OtpService {
  OtpService({FirebaseFirestore? firestore, EmailOtpService? emailOtpService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _emailOtpService = emailOtpService ?? EmailOtpService();

  static const int maxAttempts = 5;
  static const Duration expiryDuration = Duration(minutes: 5);
  static const Duration resendCooldown = Duration(seconds: 60);

  final FirebaseFirestore _firestore;
  final EmailOtpService _emailOtpService;
  final Random _random = Random.secure();

  String generateOtp() {
    return List.generate(6, (_) => _random.nextInt(10)).join();
  }

  Future<String> createOtpRecord({
    required String email,
    required OtpPurpose purpose,
    String? verificationId,
  }) async {
    final docRef = verificationId == null
        ? _collection.doc()
        : _collection.doc(verificationId);
    final id = docRef.id;
    final otp = generateOtp();
    final now = Timestamp.now();
    final expiresAt = Timestamp.fromDate(now.toDate().add(expiryDuration));

    await docRef.set({
      'email': email.trim().toLowerCase(),
      'otp': otp,
      'purpose': purpose.value,
      'createdAt': now,
      'expiresAt': expiresAt,
      'attempts': 0,
      'verified': false,
    });

    try {
      final sent = await _emailOtpService.sendOtp(toEmail: email, otp: otp);
      if (!sent) {
        throw StateError('Unable to send OTP. Please try again.');
      }
      return id;
    } catch (_) {
      try {
        await docRef.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<OtpVerificationResult> verifyOtp({
    required String verificationId,
    required String email,
    required OtpPurpose purpose,
    required String otp,
  }) async {
    final docRef = _collection.doc(verificationId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return const OtpVerificationResult(
          success: false,
          invalidated: true,
          message: 'OTP expired or invalid. Please request a new OTP.',
        );
      }

      final storedEmail = _readString(data['email']).toLowerCase();
      final storedPurpose = _readString(data['purpose']);
      final attempts = _readInt(data['attempts']);
      final expiresAt = _readTimestamp(data['expiresAt']);
      final verified = data['verified'] == true;
      final now = Timestamp.now();

      if (verified ||
          storedEmail != email.trim().toLowerCase() ||
          storedPurpose != purpose.value ||
          expiresAt == null ||
          !expiresAt.toDate().isAfter(now.toDate()) ||
          attempts >= maxAttempts) {
        transaction.update(docRef, {'verified': false});
        return const OtpVerificationResult(
          success: false,
          invalidated: true,
          message: 'OTP expired or invalid. Please request a new OTP.',
        );
      }

      if (_readString(data['otp']) == otp.trim()) {
        transaction.update(docRef, {'verified': true});
        return const OtpVerificationResult(success: true, invalidated: false);
      }

      final nextAttempts = attempts + 1;
      transaction.update(docRef, {
        'attempts': nextAttempts,
        if (nextAttempts >= maxAttempts) 'verified': false,
      });

      if (nextAttempts >= maxAttempts) {
        return const OtpVerificationResult(
          success: false,
          invalidated: true,
          message: 'OTP expired or invalid. Please request a new OTP.',
        );
      }

      return OtpVerificationResult(
        success: false,
        invalidated: false,
        message: 'Incorrect OTP. ${maxAttempts - nextAttempts} attempts left.',
      );
    });
  }

  Future<void> resendOtp({
    required String verificationId,
    required String email,
    required OtpPurpose purpose,
  }) async {
    await createOtpRecord(
      email: email,
      purpose: purpose,
      verificationId: verificationId,
    );
  }

  Future<void> deleteOtpRecord(String verificationId) async {
    await _collection.doc(verificationId).delete();
  }

  String documentIdFor({required String email, required OtpPurpose purpose}) {
    final normalizedEmail = email.trim().toLowerCase();
    final safeEmail = normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${purpose.value}_$safeEmail';
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('otp_verifications');
  }

  String _readString(Object? value) => value is String ? value.trim() : '';

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) {
      final stringValue = value.toString();
      return int.tryParse(stringValue) ?? value.toInt();
    }
    final stringValue = value?.toString();
    if (stringValue != null) return int.tryParse(stringValue) ?? 0;
    return 0;
  }

  Timestamp? _readTimestamp(Object? value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    return null;
  }
}
