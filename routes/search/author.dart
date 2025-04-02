import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../constant/config.message.dart';
import '../../controllers/author_controller.dart';

import '../../model/response.dart';

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
        'createdAt': result?.createdAt?.toIso8601String(),
        'updatedAt': result?.updatedAt?.toIso8601String(),
      },
      'music': result?.music?.map((music) {
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
    });
  } catch (e) {
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
