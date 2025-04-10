import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

import '../../constant/config.message.dart';
import '../../controllers/user_controller.dart';
import '../../exception/config.exception.dart';
import '../../model/response.dart';
import '../../model/roles.dart';
import '../../model/users.dart';
import '../../security/reset-password-token.security.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'PUT') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final headers = context.request.headers;
  final authInfo = headers['Authorization'];

  if (authInfo == null || !authInfo.startsWith('Bearer ')) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'message': 'Thiếu hoặc sai định dạng Authorization header'},
    );
  }

  final token = authInfo.split(' ')[1];
  Map<String, dynamic>? userData;

  try {
    userData = decodeResetToken(token);
    final checkOtp = userData?['checkOtp'];

    if (userData == null || !(checkOtp == true || checkOtp == 'true')) {
      throw CustomHttpException(
        ErrorMessage.TOKEN_INVALID,
        HttpStatus.unauthorized,
      );
    }
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'message': 'Token không hợp lệ hoặc đã hết hạn'},
    );
  }

  final user = User(
    id: userData['id'] as int?,
    email: userData['email']?.toString() ?? '',
    roleId: userData['roleId'] as int?,
    role: userData['roleName'] is String
        ? Role(name: userData['roleName'] as String)
        : null,
  );

  if (user.id == null) {
    return AppResponse()
        .error(HttpStatus.unauthorized, ErrorMessage.USER_NOT_FOUND);
  }

  final body = await context.request.json() as Map<String, dynamic>;

  final newPassword = body['newPassword']?.toString();
  final confirmPassword = body['confirmPassword']?.toString();

  if (newPassword == null || confirmPassword == null) {
    return AppResponse().error(HttpStatus.badRequest, ErrorMessage.REQUIRED);
  }

  try {
    final userController = context.read<UserController>();

    await userController.resetPassword(
      user.id!,
      newPassword,
      confirmPassword,
    );

    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse()
        .error(HttpStatus.internalServerError, 'Lỗi máy chủ: ${e.toString()}');
  }
}
