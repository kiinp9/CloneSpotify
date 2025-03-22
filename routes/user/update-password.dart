import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

import '../../constant/config.message.dart';
import '../../controllers/user_controller.dart';
import '../../exception/config.exception.dart';
import '../../model/response.dart';
import '../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'PUT') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final user = context.read<User?>();

  if (user == null || user.id == null) {
    return AppResponse()
        .error(HttpStatus.unauthorized, ErrorMessage.USER_NOT_FOUND);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final currentPassword = body['currentPassword']?.toString();
  final newPassword = body['newPassword']?.toString();
  final confirmPassword = body['confirmPassword']?.toString();

  if (currentPassword == null ||
      newPassword == null ||
      confirmPassword == null) {
    return AppResponse().error(HttpStatus.badRequest, ErrorMessage.REQUIRED);
  }

  try {
    final userController = context.read<UserController>();

    await userController.resetPassword(
      user.id!,
      currentPassword,
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
