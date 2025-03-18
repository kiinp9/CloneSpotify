import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';

import 'database/postgres.dart';
import 'database/redis.dart';
import 'libs/sendmail/service/sendmail.dart';
import 'security/otp.security.dart';

final dotenv = DotEnv()..load();
final database = Database();
final redisService = RedisService();
final otpService = OtpService(redisService);
final emailService = EmailService();

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
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
