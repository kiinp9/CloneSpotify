import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/album_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  try {
    final albumController = context.read<AlbumController>();

    final body = await context.request.json();
    final result = await albumController.findAlbumByAlbumTitle(
      body['albumTitle']?.toString() ?? '',
    );

    return AppResponse().ok(HttpStatus.ok, {
      'album': {
        'id': result?.id,
        'albumTitle': result?.albumTitle,
        'description': result?.description,
        'linkUrlImageAlbum': result?.linkUrlImageAlbum,
      },
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
        };
      }).toList(),
      'authors': result?.authors.map((author) {
        return {
          'id': author.id,
          'name': author.name,
          'description': author.description,
          'avatarUrl': author.avatarUrl,
          'followingCount': author.followingCount,
          'createdAt': author.createdAt?.toIso8601String(),
          'updatedAt': author.updatedAt?.toIso8601String(),
        };
      }).toList(),
      'categories': result?.categories.map((category) {
        return {
          'id': category.id,
          'name': category.name,
          'description': category.description,
          'createdAt': category.createdAt?.toIso8601String(),
          'updatedAt': category.updatedAt?.toIso8601String(),
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
