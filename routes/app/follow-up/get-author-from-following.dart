import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/follow_author_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
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

  final offset =
      int.tryParse(context.request.uri.queryParameters['offset'] ?? '0') ?? 0;
  final limit =
      int.tryParse(context.request.uri.queryParameters['limit'] ?? '5') ?? 8;

  try {
    final user = await userController.findUserById(jwtUser.id!);
    if (user == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.USER_NOT_FOUND);
    }
    final result = await _followAuthorController
        .getAuthorFromFollowAuthor(jwtUser.id!, offset: offset, limit: limit);
    return AppResponse().ok(HttpStatus.ok, {'author': result});
  } catch (e) {
    return AppResponse().error(
      HttpStatus.internalServerError,
      e.toString(),
    );
  }
}
