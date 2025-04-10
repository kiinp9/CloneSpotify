import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../controllers/album_controller.dart';
import '../controllers/author_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/user_controller.dart';
import '../database/iredis.dart';
import '../database/postgres.dart';
import '../database/redis.dart';
import '../libs/cloudinary/cloudinary.service.dart';
import '../log/log.dart';

import '../model/roles.dart';
import '../model/users.dart';
import '../repository/album_repository.dart';
import '../repository/author_repository.dart';
import '../repository/music_repository.dart';
import '../repository/user_repository.dart';
import '../security/jwt.security.dart';

Handler middleware(Handler handler) {
  final database = Database();
  final userRepository = UserRepository(database);
  final musicRepository = MusicRepository(database);
  final authorRepository = AuthorRepository(database);
  final albumRepository = AlbumRepository(database);
  final redisService = RedisService();
  final jwtService = JwtService(redisService);
  final cloudinaryService = CloudinaryService();
  final userController = UserController(userRepository, jwtService);
  final musicController = MusicController(musicRepository);
  final authorController = AuthorController(authorRepository);
  final albumController = AlbumController(albumRepository);
  final jwtMiddleware = createJwtMiddleware(jwtService, redisService);

  return handler
      .use(provider<Database>((context) => database))
      .use(provider<IRedisService>((context) => redisService))
      .use(provider<JwtService>((context) => jwtService))
      .use(provider<UserRepository>((context) => userRepository))
      .use(provider<UserController>((context) => userController))
      .use(provider<MusicController>((context) => musicController))
      .use(provider<AuthorController>((context) => authorController))
      .use(provider<AlbumController>((context) => albumController))
      .use(provider<CloudinaryService>((context) => cloudinaryService))
      .use(loggingMiddleware())
      .use(jwtMiddleware);
}

Middleware injectionController(JwtService jwtService) {
  return (handler) {
    return handler
        .use(provider<Database>((context) => Database()))
        .use(provider<IRedisService>((context) => RedisService()))
        .use(provider<JwtService>((context) => jwtService))
        .use(provider<CloudinaryService>((context) => CloudinaryService()))
        .use(provider<UserRepository>((context) {
      final db = context.read<Database>();
      return UserRepository(db);
    })).use(provider<UserController>((context) {
      final userRepository = context.read<UserRepository>();
      return UserController(userRepository, jwtService);
    })).use(provider<MusicRepository>((context) {
      final db = context.read<Database>();
      return MusicRepository(db);
    })).use(provider<MusicController>((context) {
      final musicRepository = context.read<MusicRepository>();
      return MusicController(musicRepository);
    })).use(provider<AuthorController>((context) {
      final authorRepository = context.read<AuthorRepository>();
      return AuthorController(authorRepository);
    })).use(provider<AlbumController>((context) {
      final albumRepository = context.read<AlbumRepository>();
      return AlbumController(albumRepository);
    })).use(loggingMiddleware());
  };
}

Middleware createJwtMiddleware(
    JwtService jwtService, IRedisService redisService) {
  return (handler) {
    return (context) async {
      try {
        final url = context.request.url.toString();
        if (url.contains('auth/register') ||
            url.contains('auth/login') ||
            url.contains('auth/forgot-password') ||
            url.contains('auth/check-otp') ||
            url.contains('auth/reset-password')) {
          // Bỏ qua xác thực JWT cho các endpoint công khai
          return await handler(context);
        }

        final authInfo = context.request.headers['Authorization'];
        if (authInfo == null || !authInfo.startsWith('Bearer ')) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {
              'message':
                  'Thiếu hoặc token không hợp lệ trong header Authorization'
            },
          );
        }

        final token = authInfo.split(' ')[1];

        final userData = jwtService.decodeToken(token);
        if (userData == null) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'message': 'Token không hợp lệ'},
          );
        }

        final userId = userData['id'] as int?;
        final tokenVersion = userData['tokenVersion'] as int?;
        if (userId == null || tokenVersion == null) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'message': 'Dữ liệu trong token không hợp lệ'},
          );
        }

        final redisVersion = await redisService.getTokenVersion(userId);
        if (tokenVersion != (redisVersion ?? 0)) {
          return Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'message': 'Tài khoản đã đăng xuất! Token bị thu hồi'},
          );
        }

        final user = User(
          id: userId,
          email: userData['email']?.toString() ?? '',
          roleId: userData['roleId'] as int?,
          role: userData['roleName'] is String
              ? Role(name: userData['roleName'] as String)
              : null,
        );

        return handler(context.provide<User?>(() => user));
      } catch (e) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'message': 'Xác thực token thất bại: ${e.toString()}'},
        );
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
