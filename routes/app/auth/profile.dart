import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/user_controller.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final userController = context.read<UserController>();
  final user = context.read<User?>();

  try {
    final userDb = await userController.findUserById(user?.id ?? 0);

    return AppResponse().ok(HttpStatus.ok, userDb?.toJson() ?? {});
  } catch (e) {
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
