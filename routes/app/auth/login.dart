import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/user_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';
import '../../../security/jwt.security.dart';

//POST
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final userController = context.read<UserController>();
  final jwtService = context.read<JwtService>();
  final body = await context.request.json();

  final identifier = body['identifier']?.toString() ??
      body['email']?.toString() ??
      body['username']?.toString();

  if (identifier == null || body['password'] == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.EMAIL_OR_USERNAME_REQUIRED);
  }

  try {
    final user = await userController.Login(
      identifier,
      body['password'].toString(),
    );
    final token = await jwtService.generateTokenJwt(user);

    return AppResponse().ok(HttpStatus.ok, {
      'user': user.toJson(),
      'token': token,
    });
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
