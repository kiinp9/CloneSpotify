import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/playlist_controller.dart';
import '../../../../controllers/user_controller.dart';
import '../../../../exception/config.exception.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'PATCH') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final jwtUser = context.read<User?>();
  final playlistController = context.read<PlaylistController>();
  final userController = context.read<UserController>();
  if (jwtUser == null) {
    return AppResponse()
        .error(HttpStatus.unauthorized, ErrorMessage.UNAUTHORIZED);
  }
  final playlistId = int.tryParse(context.request.uri.pathSegments.last);
  if (playlistId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.MUSIC_NOT_FOUND);
  }
  try {
    final user = await userController.findUserById(jwtUser.id!);
    if (user == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.USER_NOT_FOUND);
    }
    final body = await context.request.json() as Map<String, dynamic>;
    final updateFields = <String, dynamic>{};

    if (body.containsKey('name')) {
      updateFields['name'] = body['name'].toString();
    }
    if (body.containsKey('description')) {
      updateFields['description'] = body['description'].toString();
    }
    if (updateFields.isEmpty) {
      return AppResponse()
          .error(HttpStatus.badRequest, ErrorMessage.EMPTY_FIELD);
    }
    final result = await playlistController.updatePlaylist(
        jwtUser.id!, playlistId, updateFields,);
    return AppResponse().ok(HttpStatus.ok, result.toJson());
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
