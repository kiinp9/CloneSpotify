import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/album_controller.dart';
import '../../../../exception/config.exception.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final albumController = context.read<AlbumController>();
  final user = context.read<User?>();
  if (user == null || user.role?.name != 'admin') {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }

  final albumId = int.tryParse(context.request.uri.pathSegments.last);
  if (albumId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.ALBUM_NOT_FOUND);
  }
  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final Map<String, dynamic> updateFields = {};

    if (body.containsKey('albumTitle')) {
      updateFields['albumTitle'] = body['albumTitle'].toString();
    }
    if (body.containsKey('description')) {
      updateFields['description'] = body['description'].toString();
    }
    if (body.containsKey('nation')) {
      updateFields['nation'] = body['nation'].toString();
    }

    if (updateFields.isEmpty) {
      return AppResponse()
          .error(HttpStatus.badRequest, ErrorMessage.EMPTY_FIELD);
    }

    final result = await albumController.updateAlbum(albumId, updateFields);

    return AppResponse().ok(HttpStatus.ok, result.toJson());
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
