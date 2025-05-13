import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/follow_author_controller.dart';
import '../../../../controllers/user_controller.dart';
import '../../../../exception/config.exception.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'DELETE') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final jwtUser = context.read<User?>();
  final _followAuthorController = context.read<FollowAuthorController>();
  final userController = context.read<UserController>();
  if (jwtUser == null) {
    return AppResponse()
        .error(HttpStatus.unauthorized, ErrorMessage.UNAUTHORIZED);
  }
  final authorId = int.tryParse(context.request.uri.pathSegments.last);
  if (authorId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.AUTHOR_NOT_FOUND);
  }
  try {
    final user = await userController.findUserById(jwtUser.id!);
    if (user == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.USER_NOT_FOUND);
    }
    await _followAuthorController.unFollowAuthor(jwtUser.id!, authorId);
    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
