import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../config/jwt.config.dart';
import '../constant/config.message.dart';
import '../database/iredis.dart';
import '../exception/config.exception.dart';
import '../exception/exception.dart';
import '../model/users.dart';

class JwtService {
  final IRedisService redisService;

  JwtService(this.redisService);

  Future<String> generateTokenJwt(User user) async {
    final int tokenVersion =
        (await redisService.getTokenVersion(user.id ?? 0)) ?? 0;

    final jwt = JWT(
      {
        'id': user.id ?? 0,
        'email': user.email,
        'roleId': user.roleId,
        'roleName': user.role?.name,
        'tokenVersion': tokenVersion,
      },
    );

    return jwt.sign(
      SecretKey(JwtConfig.secretKey),
      expiresIn: Duration(seconds: JwtConfig.accessTokenExpiry),
    );
  }

  Map<String, dynamic>? decodeToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(JwtConfig.secretKey));
      return {
        'id': jwt.payload['id'],
        'email': jwt.payload['email'],
        'roleId': jwt.payload['roleId'],
        'roleName': jwt.payload['roleName'],
        'tokenVersion': jwt.payload['tokenVersion'],
        'exp': jwt.payload['exp'],
      };
    } catch (e) {
      throw const CustomHttpException(
          ErrorMessage.TOKEN_INVALID, HttpStatus.internalServerError);
    }
  }

  void verifyToken(String token) {
    try {
      JWT.verify(token, SecretKey(JwtConfig.secretKey));
    } catch (e) {
      throw const CustomHttpException(
          ErrorMessage.TOKEN_INVALID, HttpStatus.internalServerError);
    }
  }
}
