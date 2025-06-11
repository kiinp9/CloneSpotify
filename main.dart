import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';

import 'config/jwt.config.dart';
import 'database/postgres.dart';
import 'database/redis.dart';
import 'libs/sendmail/service/sendmail.dart';
import 'log/log.dart';
import 'security/otp.security.dart';

final dotenv = DotEnv()..load();
final database = Database();
final redisService = RedisService();
final otpService = OtpService(redisService);
final emailService = EmailService();

void initConfigs() {
  JwtConfig.init(dotenv);
    AppLogger.init();
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  initConfigs();

  return serve(
    handler
        .use(setupMiddleware(database, redisService, otpService, emailService)),
    ip,
    port,
  );
}

Middleware setupMiddleware(
  Database database,
  RedisService redisService,
  OtpService otpService,
  EmailService emailService,
) {
  return (handler) {
    return handler
        .use(provider<Database>((context) => database)) 
        .use(provider<RedisService>((context) => redisService))
        .use(provider<OtpService>((context) => otpService))
        .use(provider<EmailService>((context) => emailService));
  };
}
