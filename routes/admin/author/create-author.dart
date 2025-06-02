import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/author_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/author.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final authorController = context.read<AuthorController>();
  final user = context.read<User?>();
  if (user == null || user.role?.name != 'admin') {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }
  final body = await context.request.json();
  final avatarPath = body['avatarPath']?.toString();
  if (avatarPath == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_AVATAR_AUTHOR);
  }
  try {
    final author = Author(
      name: body['name'].toString(),
      description: body['description'].toString(),
      avatarUrl: avatarPath,
    );
    await authorController.createAuthor(author, avatarPath);

    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
