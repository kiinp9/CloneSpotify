import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../controllers/user_controller.dart';
import '../database/postgres.dart';
import '../log/log.dart';
import '../model/response.dart';
import '../model/roles.dart';
import '../model/users.dart';
import '../repository/user_repository.dart';
import '../security/jwt.security.dart';

Handler middleware(Handler handler) {
  final database = Database();
  final userRepository = UserRepository(database);
  final userController = UserController(userRepository);

  return handler
      .use(provider<Database>((context) => database))
      .use(provider<UserRepository>((context) => userRepository))
      .use(provider<UserController>((context) => userController))
      .use(loggingMiddleware());
}

Middleware injectionController() {
  return (handler) {
    return handler
        .use(provider<Database>((context) => Database()))
        .use(provider<UserRepository>(
      (context) {
        final db = context.read<Database>();
        return UserRepository(db);
      },
    )).use(provider<UserController>(
      (context) {
        final userRepository = context.read<UserRepository>();
        return UserController(userRepository);
      },
    )).use(loggingMiddleware());
  };
}

// Middleware kiểm tra JWT
Middleware verifyJwt() {
  return (handler) {
    return (context) async {
      try {
        final url = context.request.url.toString();
        if (url.startsWith('user/register') || url.startsWith('user/login')) {
          return await handler(context);
        }

        final headers = context.request.headers;
        final authInfo = headers['Authorization'];

        if (authInfo == null || !authInfo.startsWith('Bearer ')) {
          return Response(
              statusCode: HttpStatus.badRequest,
              body: 'Missing or invalid Authorization header');
        }

        final token = authInfo.split(' ')[1];

        verifyToken(token);

        final userData = decodeToken(token);
        if (userData == null) {
          return Response(
              statusCode: HttpStatus.unauthorized, body: 'Invalid token');
        }

        final user = User(
          id: userData['id'] as int?,
          email: userData['email']?.toString() ?? '',
          roleId: userData['roleId'] as int?,
          role: userData['roleName'] is String
              ? Role(name: userData['roleName'] as String)
              : null,
        );

        return await handler(context.provide<User>(() => user));
      } catch (e) {
        return AppResponse().error(HttpStatus.unauthorized,
            'Token verification failed: ${e.toString()}');
      }
    };
  };
}

Middleware loggingMiddleware() {
  return (handler) {
    return (context) async {
      final request = context.request;
      final method = request.method.name;
      final path = request.uri.toString();
      final headers = request.headers;

      String requestBody = await request.body();
      if (requestBody.isEmpty) requestBody = '{}';

      AppLogger.logRequest(method, path, headers, requestBody);

      final response = await handler(context);

      final responseBody = await response.body();
      final newResponse = response.copyWith(body: responseBody);

      AppLogger.logResponse(
          method,
          path,
          response.statusCode,
          jsonDecode(responseBody.isNotEmpty ? responseBody : '""'),
          response.headers);

      return newResponse;
    };
  };
}
