import 'dart:convert';
import 'package:logging/logging.dart';

class AppLogger {
  static final Logger _logger = Logger('App');
  static bool _isInitialized = false;

  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String red = '\x1B[31m';
  static const String reset = '\x1B[0m';

  // Danh sách paths cần bỏ qua (hot reload, static files, etc.)
  static final Set<String> _ignoredPaths = {
    '/.well-known/appspecific/com.chrome.devtools.json',
    '/favicon.ico',
    '/robots.txt',
  };

  static final Set<String> _ignoredExtensions = {
    '.css',
    '.js',
    '.png',
    '.jpg',
    '.jpeg',
    '.ico',
    '.yaml',
    '.html',
    '.svg',
    '.woff',
    '.woff2',
    '.ttf'
  };

  static void init() {
    if (_isInitialized) return; // Chỉ khởi tạo 1 lần

    _isInitialized = true;
    Logger.root.level = Level.ALL;

    // Clear existing listeners để tránh duplicate
    Logger.root.clearListeners();

    Logger.root.onRecord.listen((record) {
      final timestamp = _getCurrentTimestamp();
      final logMessage =
          '$green[Dart] - $timestamp     LOG ${record.message}$reset';
      print(logMessage);
    });
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  static bool _shouldIgnoreRequest(String path, String method) {
    // Bỏ qua hot reload requests
    if (_ignoredPaths.contains(path)) return true;

    // Bỏ qua static files
    if (_ignoredExtensions.any((ext) => path.toLowerCase().contains(ext))) {
      return true;
    }

    // Bỏ qua Chrome DevTools requests
    if (path.contains('.well-known') || path.contains('devtools')) {
      return true;
    }

    // Bỏ qua Swagger routes
    if (path.contains('/swagger')) {
      return true;
    }

    return false;
  }

  static void logSeparator() {
    _logger.info(
        '*******************************************************************');
  }

  static void logInfo(String message) {
    _logger.info('$green[INFO] $message$reset');
  }

  static void logRequest(
    String method,
    String path,
    Map<String, dynamic> headers,
    String body,
  ) {
    // Bỏ qua requests không cần thiết
    if (_shouldIgnoreRequest(path, method)) return;

    logSeparator();
    _logger.info('$green[INFO] [Request $method $path]$reset');

    // Chỉ log headers quan trọng
    final importantHeaders = <String, dynamic>{};
    final headersToLog = ['authorization', 'content-type', 'user-agent'];

    for (final key in headersToLog) {
      if (headers.containsKey(key)) {
        importantHeaders[key] = headers[key];
      }
    }

    if (importantHeaders.isNotEmpty) {
      _logger
          .info('$green[INFO] Headers: ${jsonEncode(importantHeaders)}$reset');
    }

    // Chỉ log body nếu không rỗng và không phải GET request
    if (body.isNotEmpty && body != '{}' && method.toUpperCase() != 'GET') {
      try {
        final parsedBody = jsonDecode(body);
        _logger.info('$green[INFO] Body: ${jsonEncode(parsedBody)}$reset');
      } catch (e) {
        _logger.info('$green[INFO] Body: $body$reset');
      }
    }
  }

  static void logResponse(
    String method,
    String path,
    int statusCode,
    dynamic response,
    Map<String, dynamic> headers,
  ) {
    // Bỏ qua responses không cần thiết
    if (_shouldIgnoreRequest(path, method)) return;

    final statusColor = statusCode >= 400
        ? red
        : statusCode >= 300
            ? yellow
            : green;

    final logLevel = statusCode >= 400
        ? '[ERROR]'
        : statusCode >= 300
            ? '[WARNING]'
            : '[INFO]';

    _logger.info(
        '$statusColor$logLevel [Response $method $path - $statusCode]$reset');

    // Log response body nếu có
    if (response != null) {
      try {
        if (response is String && response.isNotEmpty) {
          // Cố gắng parse JSON
          try {
            final parsedResponse = jsonDecode(response);
            _logger.info(
                '$statusColor$logLevel Body: ${jsonEncode(parsedResponse)}$reset');
          } catch (e) {
            _logger.info('$statusColor$logLevel Body: "$response"$reset');
          }
        } else {
          _logger.info(
              '$statusColor$logLevel Body: ${jsonEncode(response)}$reset');
        }
      } catch (e) {
        _logger.info('$statusColor$logLevel Body: $response$reset');
      }
    }

    logSeparator();
  }

  static void logError(String message,
      [Object? error, StackTrace? stackTrace]) {
    _logger.severe('$red[ERROR] $message$reset');
    if (error != null) {
      _logger.severe('$red[ERROR] $error$reset');
    }
    if (stackTrace != null) {
      _logger.severe('$red[STACK] $stackTrace$reset');
    }
  }

  static String _getCurrentTimestamp() {
    final now = DateTime.now();
    return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)} ${_pad(now.day)}/${_pad(now.month)}/${now.year}';
  }
}
