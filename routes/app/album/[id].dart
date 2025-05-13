import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/album_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final albumController = context.read<AlbumController>();

  final albumId = int.tryParse(context.request.uri.pathSegments.last);
  if (albumId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.ALBUM_NOT_FOUND);
  }
  try {
    final result = await albumController.showMusicByAlbumId(albumId);

    return AppResponse().ok(HttpStatus.ok, result);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(
      HttpStatus.internalServerError,
      ErrorMessageSQL.SQL_QUERY_ERROR,
    );
  }
}
