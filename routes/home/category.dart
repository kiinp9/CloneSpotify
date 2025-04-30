import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../constant/config.message.dart';
import '../../controllers/music_controller.dart';
import '../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse().error(
      HttpStatus.methodNotAllowed,
      ErrorMessage.MSG_METHOD_NOT_ALLOW,
    );
  }
  final musicController = context.read<MusicController>();
  final categoryId =
      int.tryParse(context.request.uri.queryParameters['categoryId'] ?? '');
  if (categoryId == null) {
    return AppResponse().error(HttpStatus.internalServerError,
        ErrorMessageRoute.PARAMETER_QUERY_ROUTER_NOT_NULL);
  }
  try {
    final musics = await musicController.showMusicByCategory(categoryId);
    final musicJson = musics.map((music) {
      return {
        'id': music.id,
        'title': music.title,
        'imageUrl': music.imageUrl,
        'authors': music.authors
            .map((a) => {
                  'id': a.id,
                  'name': a.name,
                })
            .toList(),
      };
    }).toList();
    return AppResponse().ok(HttpStatus.ok, {'musics': musicJson});
  } catch (e) {
    return AppResponse().error(
      HttpStatus.internalServerError,
      e.toString(),
    );
  }
}
