import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/author_controller.dart';

import '../../../exception/config.exception.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  try {
    final authorController = context.read<AuthorController>();

    final body = await context.request.json();

    final result = await authorController.findAuthorByName(
      body['name']?.toString() ?? '',
    );
    return AppResponse().ok(HttpStatus.ok, {
      'author': {
        'id': result?.id,
        'name': result?.name,
        'description': result?.description,
        'avatarUrl': result?.avatarUrl,
        'followingCount': result?.followingCount,
        'createdAt': result?.createdAt?.toIso8601String(),
        'updatedAt': result?.updatedAt?.toIso8601String(),
      },
      'albums': result?.albums.map((album) {
        return {
          'id': album.id,
          'albumTitle': album.albumTitle,
          'description': album.description,
          'linkUrlImageAlbum': album.linkUrlImageAlbum,
          'createdAt': album.createdAt?.toIso8601String(),
          'updatedAt': album.updatedAt?.toIso8601String(),
          'nation': album.nation,
          'listenCountAlbum': album.listenCountAlbum,
        };
      }).toList(),
      'musics': result?.musics.map((music) {
        return {
          'id': music.id,
          'title': music.title,
          'description': music.description,
          'broadcastTime': music.broadcastTime,
          'linkUrlMusic': music.linkUrlMusic,
          'createdAt': music.createdAt?.toIso8601String(),
          'updatedAt': music.updatedAt?.toIso8601String(),
          'imageUrl': music.imageUrl,
          'nation': music.nation,
          'listenCount': music.listenCount,
        };
      }).toList(),
    });
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
