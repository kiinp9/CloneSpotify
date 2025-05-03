import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../constant/config.message.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';
import '../../../controllers/music_controller.dart';

import '../../../model/music.dart';
import '../../../model/author.dart';
import '../../../model/category.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final musicController = context.read<MusicController>();
  final user = context.read<User?>();
  if (user == null || user.role?.name != 'admin') {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }
  final body = await context.request.json();

  final musicFilePath = body['musicFilePath']?.toString();
  final imageFilePath = body['imageFilePath']?.toString();

  if (musicFilePath == null || imageFilePath == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_MUSIC_OR_IMAGE_FILE);
  }

  try {
    final music = Music(
      title: body['title'].toString(),
      description: body['description'].toString(),
      nation: body['nation'].toString(),
    );

    final author = Author(
      name: body['author']['name'].toString(),
      description: body['author']['description'].toString(),
      avatarUrl: body['author']['avatarUrl']?.toString(),
    );

    final categories = (body['categories'] as List)
        .map((categoryData) => Category(
              name: categoryData['name'].toString(),
              description: categoryData['description'].toString(),
            ))
        .toList();

    await musicController.uploadMusic(
      music,
      musicFilePath,
      imageFilePath,
      author,
      categories,
    );

    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
