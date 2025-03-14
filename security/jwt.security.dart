import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../config/jwt.config.dart';

import '../constant/config.message.dart';
import '../model/users.dart';
import '../model/roles.dart';
import '../exception/config.exception.dart';
import '../exception/exception.dart';

String generateTokenJwt(User user) {
  final jwt = JWT(
    {
      'id': user.id,
      'email': user.email,
      'roleId': user.roleId,
      'roleName': user.role?.name,
      'exp': DateTime.now()
              .add(Duration(
                  seconds:
                      JwtConfig.accessTokenExpiry)) // ✅ CHUYỂN INT -> DURATION
              .millisecondsSinceEpoch ~/
          1000,
    },
  );
  return jwt.sign(SecretKey(JwtConfig.secretKey));
}

Map<String, dynamic>? decodeToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(JwtConfig.secretKey));
    return {
      'id': jwt.payload['id'],
      'email': jwt.payload['email'],
      'roleId': jwt.payload['roleId'],
      'roleName': jwt.payload['roleName'],
      'exp': jwt.payload['exp'],
    };
  } catch (e) {
    throw const CustomHttpException(
        ErrorMessage.TOKEN_INVALID, HttpStatus.internalServerError);
  }
}

AppException? verifyToken(String token) {
  try {
    JWT.verify(token, SecretKey(JwtConfig.secretKey));
    return null;
  } catch (e) {
    throw const CustomHttpException(
        ErrorMessage.TOKEN_INVALID, HttpStatus.internalServerError);
  }
}
