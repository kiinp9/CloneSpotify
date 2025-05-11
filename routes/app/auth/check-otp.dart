import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../constant/config.message.dart';
import '../../../controllers/user_controller.dart';
import '../../../database/redis.dart';
import '../../../model/response.dart';
import '../../../exception/config.exception.dart';
import '../../../security/otp.security.dart';
import '../../../security/reset-password-token.security.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final redisService = RedisService();
  final otpService = OtpService(redisService);
  final userController = context.read<UserController>();
  final body = await context.request.json();

  final email = body['email']?.toString();
  final otp = body['otp']?.toString();

  if (email == null || otp == null || email.isEmpty || otp.isEmpty) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_OTP_REQUEST);
  }

  try {
    // Lấy OTP từ Redis
    final storedOtp = await otpService.getOtp(email);
    if (storedOtp == null || storedOtp != otp) {
      return AppResponse()
          .error(HttpStatus.badRequest, ErrorMessage.OTP_INVALID_OR_EXPIRED);
    }
    final user = await userController.findUserByEmail(email);
    if (user == null) {
      throw const CustomHttpException(
          ErrorMessage.USER_NOT_FOUND, HttpStatus.badRequest);
    }
    final token = generateResetPassTokenJwt(user);

    return AppResponse().ok(HttpStatus.ok, {'token': token});
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
