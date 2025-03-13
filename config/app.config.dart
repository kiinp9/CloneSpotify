import 'package:dotenv/dotenv.dart';

class AppConfig {
  static final DotEnv _env = DotEnv()..load();

  // Môi trường và cổng
  static String get nodeEnv => _env['NODE_ENV'] ?? 'dev';
  static int get port => int.tryParse(_env['PORT'] ?? '8080') ?? 8080;

  // Cấu hình Database
  static String get dbHost => _env['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.tryParse(_env['DB_PORT'] ?? '5432') ?? 5432;
  static String get dbName => _env['DB_NAME'] ?? 'spotify';
  static String get dbUser => _env['DB_USERNAME'] ?? 'postgres';
  static String get dbPass => _env['DB_PASSWORD'] ?? '';

  // Cấu hình Authentication (JWT)
  static String get jwtSecret => _env['JWT_SECRET'] ?? '';
  static int get jwtExpired =>
      int.tryParse(_env['JWT_EXPIRED'] ?? '6000000') ?? 6000000;
  static int get refreshTokenExpired =>
      int.tryParse(_env['REFRESH_TOKEN_EXPIRED'] ?? '360000000') ?? 360000000;
  static int get refreshTokenKeepLoginExpired =>
      int.tryParse(_env['REFRESH_TOKEN_KEEP_LOGIN_EXPIRED'] ?? '360000000') ??
      360000000;

  // Load trước khi chạy ứng dụng
  static void init() {
    print(
        "🔹 AppConfig Loaded: NODE_ENV = $nodeEnv, DB = $dbHost:$dbPort/$dbName");
  }
}
