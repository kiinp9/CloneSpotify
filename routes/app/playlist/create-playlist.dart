import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/playlist_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/playlist.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final jwtUser = context.read<User?>();
  final playlistController = context.read<PlaylistController>();
  final userController = context.read<UserController>();

  if (jwtUser == null) {
    return AppResponse()
        .error(HttpStatus.unauthorized, ErrorMessage.UNAUTHORIZED);
  }

  try {
    final user = await userController.findUserById(jwtUser.id!);
    if (user == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.USER_NOT_FOUND);
    }
    final playlist = Playlist(
      userId: user.id!,
      name: 'playlist của ${user.userName}',
      description: 'playlist của ${user.userName}',
    );

    await playlistController.createPlaylist(playlist);

    return AppResponse().success(
      HttpStatus.ok,
    );
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
