import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/music_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  try {
    final musicController = context.read<MusicController>();

    final body = await context.request.json();

    final result = await musicController.findMusicByTitle(
      body['title']?.toString() ?? '',
    );

    return AppResponse().ok(HttpStatus.ok, {
      'music': {
        'id': result?.id,
        'title': result?.title,
        'description': result?.description,
        'broadcastTime': result?.broadcastTime,
        'linkUrlMusic': result?.linkUrlMusic,
        'createdAt': result?.createdAt?.toIso8601String(),
        'updatedAt': result?.updatedAt?.toIso8601String(),
        'imageUrl': result?.imageUrl,
      },
      'authors': result?.authors?.map((author) {
        return {
          'id': author.id,
          'name': author.name,
          'description': author.description,
          'avatarUrl': author.avatarUrl,
          'createdAt': author.createdAt?.toIso8601String(),
          'updatedAt': author.updatedAt?.toIso8601String(),
        };
      }).toList(),
      'categories': result?.categories?.map((category) {
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
