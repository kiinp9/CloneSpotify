import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../constant/config.message.dart';
import '../../../controllers/user_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';
import '../../../security/google.security.dart';
import '../../../security/jwt.security.dart';

//POST
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final userController = context.read<UserController>();
  final jwtService = context.read<JwtService>();
  final body = await context.request.json();

  if (body['idToken'] == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.MISSING_ID_TOKEN);
  }

  try {
    final googleUser = await GoogleSecurity.verifyGoogleToken(
      body['idToken'].toString(),
    );

    if (googleUser == null) {
      return AppResponse()
          .error(HttpStatus.unauthorized, ErrorMessage.ID_TOKEN_INVALID);
    }

    final email = googleUser['email']!;

    final existingUser = await userController.findUserByEmail(email);
    if (existingUser == null) {
      return AppResponse()
          .error(HttpStatus.notFound, ErrorMessage.ID_TOKEN_INVALID);
    }

    final token = await jwtService.generateTokenJwt(existingUser);

    return AppResponse().ok(HttpStatus.ok, {
      'user': existingUser.toJson(),
      'token': token,
    });
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
