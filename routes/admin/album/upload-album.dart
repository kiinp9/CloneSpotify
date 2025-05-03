import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/album_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/album.dart';
import '../../../model/author.dart';
import '../../../model/category.dart';
import '../../../model/music.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final albumController = context.read<AlbumController>();
  final user = context.read<User?>();
  if (user == null || user.role?.name != 'admin') {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }
  final body = await context.request.json();
  final albumFolderPath = body['albumFolderPath']?.toString();
  final avatarPath = body['author']['avatarUrl']?.toString();

  if (avatarPath == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_AUTHOR_IMAGE_FOLDER);
  }
  if (albumFolderPath == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_ALBUM_FOLDER);
  }
  try {
    final album = Album(
      albumTitle: body['albumTitle'].toString(),
      description: body['description'].toString(),
      nation: body['nation'].toString(),
    );
    final music = (body['music'] as List)
        .map((m) => Music(
              title: m['title'].toString(),
              description: m['description'].toString(),
              nation: album.nation,
            ))
        .toList();

    final author = Author(
      name: body['author']['name'].toString(),
      description: body['author']['description'].toString(),
      avatarUrl: avatarPath,
    );

    final categories = (body['categories'] as List)
        .map((categoryData) => Category(
              name: categoryData['name'].toString(),
              description: categoryData['description'].toString(),
            ))
        .toList();

    await albumController.uploadAlbum(
        album, albumFolderPath, avatarPath, music, author, categories);

    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
