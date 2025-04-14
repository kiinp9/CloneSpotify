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
      int.tryParse(context.request.uri.queryParameters['limit'] ?? '10') ?? 10;

  try {
    final musics =
        await musicController.showMusicPaging(offset: offset, limit: limit);
    final musicJson = musics.map((music) {
      return {
        'id': music.id,
        'title': music.title,
        'imageUrl': music.imageUrl,
        'authors': music.authors
            ?.map((a) => {
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
