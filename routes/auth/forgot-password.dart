import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../constant/config.message.dart';
import '../../controllers/user_controller.dart';
import '../../database/redis.dart';
import '../../libs/sendmail/service/sendmail.dart';
import '../../model/response.dart';
import '../../exception/config.exception.dart';
import '../../security/otp.security.dart';

Future<Response> onRequest(RequestContext context) async {
  final redisService = RedisService();
  final otpService = OtpService(redisService);
  final userController = context.read<UserController>();
  final emailService = EmailService();

  if (context.request.method == HttpMethod.post) {
    return _sendOtp(context, otpService, userController, emailService);
  } else {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
}

Future<Response> _sendOtp(
  RequestContext context,
  OtpService otpService,
  UserController userController,
  EmailService emailService,
) async {
  try {
    final body = await context.request.json();
    final email = body['email']?.toString();

    if (email == null || email.isEmpty) {
      return AppResponse()
          .error(HttpStatus.badRequest, ErrorMessage.EMAIL_REQUIRED);
    }

    final user = await userController.findUserByEmail(email);
    if (user == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.EMAIL_NOT_FOUND);
    }

    await otpService.saveOtp(email);
    final otp = await otpService.getOtp(email);

    if (otp != null) {
      await emailService.sendOtpEmail(email, otp);
    }

    return AppResponse().ok(HttpStatus.ok, {
      'message': 'OTP đã được gửi đến email của bạn',
    });
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
