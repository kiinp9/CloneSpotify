import 'dart:convert';
import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('Dart');

  static const String green = '\x1B[32m'; // Màu xanh lá cây
  static const String yellow = '\x1B[33m'; // Màu vàng
  static const String reset = '\x1B[0m';   // Reset màu

  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final timestamp = _getCurrentTimestamp();
      final logMessage =
          '$green[Dart] - $timestamp     LOG ${record.message}$reset';
      print(logMessage);
    });
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  static void logSeparator() {
    print(
        "$green[Dart] - ${_getCurrentTimestamp()}     LOG *******************************************************************$reset");
  }

  static void logInfo(String message) {
    _logger.info("$green$message$reset");
  }

  static void logRequest(
      String method, String path, Map<String, dynamic> headers, String body) {
    logSeparator();
    _logger.info("$yellow[Request $method $path]$reset");
    logInfo("Headers: ${jsonEncode(headers)}");
    logInfo("Body: ${jsonEncode(jsonDecode(body))}");
  }

  static void logResponse(String method, String path, int statusCode,
      dynamic response, Map<String, String> headers) {
    _logger.info("$yellow[Response $method $path]${jsonEncode({
          'statusCode': statusCode,
          'body': response,
          'headers': headers
        })}$reset");
    logSeparator();
  }

  static String _getCurrentTimestamp() {
    final now = DateTime.now();
    return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)} ${_pad(now.day)}/${_pad(now.month)}/${now.year}';
  }
}
