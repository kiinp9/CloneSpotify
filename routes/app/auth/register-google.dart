import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../../constant/config.constant.dart';
import '../../../constant/config.message.dart';
import '../../../controllers/user_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';
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
      body['idToken']?.toString() ?? '',
    );

    if (googleUser == null) {
      return AppResponse()
          .error(HttpStatus.unauthorized, ErrorMessage.ID_TOKEN_INVALID);
    }

    final existingUser =
        await userController.findUserByEmail(googleUser['email']!);
    if (existingUser != null) {
      final token = await jwtService.generateTokenJwt(existingUser);
      return AppResponse().ok(HttpStatus.ok, {
        'user': existingUser.toJson(),
        'token': token,
      });
    }

    if (body['userName'] == null ||
        body['gender'] == null ||
        body['birthday'] == null) {
      return AppResponse().error(HttpStatus.badRequest, ErrorMessage.REQUIRED);
    }

    final newUser = User(
      email: googleUser['email']!,
      fullName: googleUser['name'],
      userName: body['userName'].toString(),
      birthday: body['birthday'] != null
          ? DateTime.tryParse(body['birthday'].toString())
          : null,
      gender: GenderE.values.firstWhere(
        (e) => e.toString().split('.').last == body['gender'].toString(),
        orElse: () => GenderE.preferNotToSay,
      ),
      GoogleStatus: 2,
      roleId: 2,
    );

    final savedUser = await userController.registerGoogleUser(newUser);
    final token = await jwtService.generateTokenJwt(savedUser);

    return AppResponse().ok(HttpStatus.ok, {
      'user': savedUser.toJson(),
      'token': token,
    });
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
