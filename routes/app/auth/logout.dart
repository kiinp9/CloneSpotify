import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../database/iredis.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

//POST
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  try {
    final user = context.read<User?>();

    if (user == null) {
      return AppResponse()
          .error(HttpStatus.unauthorized, ErrorMessage.USER_NOT_FOUND);
    }

    final redisService = context.read<IRedisService>();

    await redisService.invalidateToken(user.id ?? 0);

    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
