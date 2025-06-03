import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../config/jwt.config.dart';
import '../constant/config.message.dart';
import '../exception/config.exception.dart';
import '../exception/exception.dart';
import '../model/users.dart';

String generateResetPassTokenJwt(User user) {
  final resetPassJwt = JWT(
    {
      'id': user.id,
      'email': user.email,
      'roleId': user.roleId,
      'roleName': user.role?.name,
      'checkOtp': 'true',
      'exp': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/
          1000,
    },
  );
  return resetPassJwt.sign(SecretKey(JwtConfig.secretKey));
}

Map<String, dynamic>? decodeResetToken(String token) {
  try {
    final resetPassJwt = JWT.verify(token, SecretKey(JwtConfig.secretKey));
    return {
      'id': resetPassJwt.payload['id'],
      'email': resetPassJwt.payload['email'],
      'roleId': resetPassJwt.payload['roleId'],
      'roleName': resetPassJwt.payload['roleName'],
      'checkOtp': resetPassJwt.payload['checkOtp'],
      'exp': resetPassJwt.payload['exp'],
    };
  } catch (e) {
    throw const CustomHttpException(
        ErrorMessage.TOKEN_INVALID, HttpStatus.internalServerError,);
  }
}

AppException? verifyResetToken(String token) {
  try {
    JWT.verify(token, SecretKey(JwtConfig.secretKey));
    return null;
  } catch (e) {
    throw const CustomHttpException(
        ErrorMessage.TOKEN_INVALID, HttpStatus.internalServerError,);
  }
}
