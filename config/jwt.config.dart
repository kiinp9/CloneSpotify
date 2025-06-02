import 'package:dotenv/dotenv.dart';

class JwtConfig {
  static late String secretKey;
  static late int accessTokenExpiry;
  static late int refreshTokenExpiry;

  static void init(DotEnv env) {
    secretKey = env['JWT_SECRET'] ?? '';
    accessTokenExpiry = int.tryParse(env['ACCESS_TOKEN_EXPIRY'] ?? '') ?? 7200;
    refreshTokenExpiry =
        int.tryParse(env['REFRESH_TOKEN_EXPIRY'] ?? '') ?? 86400;
  }
}
