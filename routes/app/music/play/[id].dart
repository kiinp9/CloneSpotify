import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/history_controller.dart';
import '../../../../controllers/music_controller.dart';
import '../../../../exception/config.exception.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final musicController = context.read<MusicController>();
  final historyController = context.read<HistoryController>();
  final user = context.read<User?>();
  if (user == null || user.id == null) {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }

  final id = int.tryParse(context.request.uri.pathSegments.last);
  final musicId = id;
  if (musicId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.MUSIC_NOT_FOUND);
  }
  try {
    await musicController.setPlayMusicHistory(user.id!, musicId.toString());
    await musicController.incrementListenCount(musicId);
    final result = await musicController.findMusicById(id ?? 0);
    await historyController.addMusicToHistory(user.id!, musicId);
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
        'listenCount': result?.listenCount,
        'nation': result?.nation,
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
          'imageUrl': category.imageUrl,
        };
      }).toList(),
    });
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
