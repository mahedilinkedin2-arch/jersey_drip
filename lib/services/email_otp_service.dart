// import 'package:emailjs/emailjs.dart' as emailjs;

// import '../config/emailjs_config.dart';

// class EmailOtpService {
//   Future<bool> sendOtp({required String toEmail, required String otp}) async {
//     final templateParams = <String, dynamic>{
//       'to_email': toEmail.trim(),
//       'otp': otp.trim(),
//     };
//     print('EMAIL SENDING START');
//     print(templateParams);

//     try {
//       await emailjs.send(
//         EmailJSConfig.serviceId,
//         EmailJSConfig.templateId,
//         templateParams,
//         const emailjs.Options(publicKey: EmailJSConfig.publicKey),
//       );
//       print('EMAILJS SUCCESS');
//       return true;
//     } catch (error) {
//       if (error is emailjs.EmailJSResponseStatus) {
//         print('EMAILJS FAILED + ERROR: ${error.status}: ${error.text}');
//       } else {
//         print('EMAILJS FAILED + ERROR: $error');
//       }
//       return false;
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/emailjs_config.dart';

class EmailOtpService {
  Future<bool> sendOtp({required String toEmail, required String otp}) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': EmailJSConfig.serviceId,
          'template_id': EmailJSConfig.templateId,
          'user_id': EmailJSConfig.publicKey,
          'template_params': {'to_email': toEmail.trim(), 'otp': otp.trim()},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
