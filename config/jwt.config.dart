import 'package:dotenv/dotenv.dart';

class JwtConfig {
  static final DotEnv _env = DotEnv()..load();

  static final String secretKey = _env['JWT_SECRET'] ?? '';
  static const int accessTokenExpiry = 6000000;
  static const int refreshTokenExpiry = 360000000;
}
