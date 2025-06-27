// File: routes/swagger/_middleware.dart
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler.use(swaggerMiddleware());
}

// Middleware đơn giản chỉ cho swagger - không cần JWT, không cần phức tạp
Middleware swaggerMiddleware() {
  return (handler) {
    return (context) async {
      final path = context.request.uri.path;
      final method = context.request.method.name;

      // Log đơn giản
      print('📋 Swagger UI: $method $path');

      // Thêm CORS headers cho swagger
      final response = await handler(context);

      return response.copyWith(
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Cache-Control': 'no-cache',
        },
      );
    };
  };
}
