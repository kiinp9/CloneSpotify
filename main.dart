import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'database/postgres.dart';
import 'package:dotenv/dotenv.dart';

final dotenv = DotEnv()..load();
final database = Database();

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  return serve(handler.use(setupHandler()), ip, port);
}

Middleware setupHandler() {
  return (handler) {
    return handler.use(
      provider<Database>(
        (context) => database,
      ),
    );
  };
}
