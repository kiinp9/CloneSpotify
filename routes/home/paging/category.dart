import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/music_controller.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse().error(
      HttpStatus.methodNotAllowed,
      ErrorMessage.MSG_METHOD_NOT_ALLOW,
    );
  }

  final musicController = context.read<MusicController>();

  final offset =
      int.tryParse(context.request.uri.queryParameters['offset'] ?? '0') ?? 0;
  final limit =
      int.tryParse(context.request.uri.queryParameters['limit'] ?? '5') ?? 5;

  try {
    final categories =
        await musicController.showCategoryPaging(offset: offset, limit: limit);

    final categoriesJson = categories?.map((category) {
      return {
        'id': category.id,
        'name': category.name,
      };
    }).toList();
    return AppResponse().ok(HttpStatus.ok, {'categories': categoriesJson});
  } catch (e) {
    return AppResponse().error(
      HttpStatus.internalServerError,
      e.toString(),
    );
  }
}
