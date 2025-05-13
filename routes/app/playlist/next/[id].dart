import 'dart:io';
import 'dart:math';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/history_controller.dart';
import '../../../../controllers/playlist_controller.dart';
import '../../../../exception/config.exception.dart';
import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final _playlistController = context.read<PlaylistController>();
  final historyController = context.read<HistoryController>();
  final user = context.read<User?>();
  if (user == null || user.id == null) {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }
  final currentMusicId = int.tryParse(context.request.uri.pathSegments.last);
  if (currentMusicId == null) {
    return AppResponse()
        .error(HttpStatus.internalServerError, ErrorMessageRoute.ROUTER_ERROR);
  }
  final playlistIdStr = context.request.uri.queryParameters['playlistId'];
  final playlistId = int.tryParse(playlistIdStr ?? '');
  if (playlistId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.PLAYLIST_NOT_FOUND);
  }
  try {
    final result = await _playlistController.nextMusic(
        currentMusicId, user.id!, playlistId);
    if (result == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.MUSIC_NOT_FOUND);
    }
    await _playlistController.playNextMusic(user.id!, result.id!.toString());
    await _playlistController.incrementListenCount(result.id!);
    await historyController.addMusicToHistory(user.id!, result.id!);
    final authors = (result?.authors ?? []);
    for (final author in authors) {
      await historyController.addAuthorToHistoryAuthor(user.id!, author.id!);
    }
    await historyController.createHistoryAlbum(
        user.id!, result?.albumId, result.id!);

    return AppResponse().ok(HttpStatus.ok, {
      'music': {
        'id': result.id,
        'title': result.title,
        'description': result.description,
        'broadcastTime': result.broadcastTime,
        'linkUrlMusic': result.linkUrlMusic,
        'createdAt': result.createdAt?.toIso8601String(),
        'updatedAt': result.updatedAt?.toIso8601String(),
        'imageUrl': result.imageUrl,
        'albumId': result.albumId,
        'listenCount': result.listenCount,
        'nation': result.nation
      },
      'authors': result.authors.map((author) {
        return {
          'id': author.id,
          'name': author.name,
          'description': author.description,
          'avatarUrl': author.avatarUrl,
          'createdAt': author.createdAt?.toIso8601String(),
          'updatedAt': author.updatedAt?.toIso8601String(),
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
