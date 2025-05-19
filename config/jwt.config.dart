import 'dart:io';

class JwtConfig {
  static final String secretKey = Platform.environment['JWT_SECRET'] ?? '';
  static final int accessTokenExpiry =
      int.tryParse(Platform.environment['ACCESS_TOKEN_EXPIRY'] ?? '') ?? 0;
  static final int refreshTokenExpiry =
      int.tryParse(Platform.environment['REFRESH_TOKEN_EXPIRY'] ?? '') ?? 0;
}