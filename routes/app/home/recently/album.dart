import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/history_controller.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse().error(
      HttpStatus.methodNotAllowed,
      ErrorMessage.MSG_METHOD_NOT_ALLOW,
    );
  }

  final user = context.read<User?>();
  final historyController = context.read<HistoryController>();

  final offset =
      int.tryParse(context.request.uri.queryParameters['offset'] ?? '0') ?? 0;
  final limit =
      int.tryParse(context.request.uri.queryParameters['limit'] ?? '8') ?? 8;

  if (user == null) {
    return AppResponse()
        .error(HttpStatus.unauthorized, ErrorMessage.UNAUTHORIZED);
  }
  try {
    final albums = await historyController.getAlbumByHistoryAlbum(
      user.id!,
      offset: offset,
      limit: limit,
    );
    return AppResponse().ok(HttpStatus.ok, {'albums': albums});
  } catch (e) {
    return AppResponse().error(
      HttpStatus.internalServerError,
      e.toString(),
    );
  }
}
