import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../../constant/config.constant.dart';
import '../../constant/config.message.dart';
import '../../controllers/user_controller.dart';
import '../../exception/config.exception.dart';
import '../../model/response.dart';
import '../../model/users.dart';
import '../../security/jwt.security.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final userController = context.read<UserController>();
  final jwtService = context.read<JwtService>();
  final body = await context.request.json();
  final userReq = User(
    email: body['email'].toString(),
    password: body['password'].toString(),
    birthday: body['birthday'] != null
        ? DateTime.tryParse(body['birthday'].toString())
        : null,
    gender: GenderE.values.firstWhere(
      (e) => e.toString().split('.').last == body['gender'].toString(),
      orElse: () => GenderE.preferNotToSay,
    ),
    fullName: body['fullName'].toString(),
    userName: body['userName'].toString(),
    roleId: 2,
    GoogleStatus: 1,
  );

  try {
    final user = await userController.Register(userReq);
    final token = await jwtService.generateTokenJwt(user);

    return AppResponse().ok(HttpStatus.ok, {
      'user': user.toJson(),
      'token': token,
    });
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }

    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
