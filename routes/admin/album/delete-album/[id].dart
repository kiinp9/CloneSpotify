import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/album_controller.dart';
import '../../../../exception/config.exception.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'DELETE') {
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
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_CATEGORY_ID);
  }
  try {
    await albumController.deleteAlbumById(albumId);
    return AppResponse().success(HttpStatus.ok);
  } on CustomHttpException catch (e) {
    return AppResponse().error(e.statusCode, e.message);
  } catch (e) {
    return AppResponse().error(
      HttpStatus.internalServerError,
      e.toString(),
    );
  }
}
