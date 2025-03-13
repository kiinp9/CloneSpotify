import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../config/app.config.dart';

Handler middleware(Handler handler) {
  return handler.use(
    provider<AppConfig>(
      (_) => AppConfig(),
    ),
  );
}
