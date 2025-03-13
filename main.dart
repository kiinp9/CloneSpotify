import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'database/postgres.dart';

final database = Database(); // ✅ Gọi constructor, _connect() sẽ chạy tự động

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
