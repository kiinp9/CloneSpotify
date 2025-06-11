import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../controllers/album_controller.dart';
import '../controllers/author_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/follow_author_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/like_music_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/user_controller.dart';
import '../database/iredis.dart';
import '../database/postgres.dart';
import '../database/redis.dart';

import '../ultis/cloudinary/service/upload-album.service.dart';
import '../ultis/cloudinary/service/upload-music.service.dart';
import '../log/log.dart';

import '../main.dart';
import '../model/roles.dart';
import '../model/users.dart';
import '../repository/album_repository.dart';
import '../repository/author_repository.dart';
import '../repository/category_repository.dart';
import '../repository/follow_author_repository.dart';
import '../repository/history_repository.dart';
import '../repository/like_music_repository.dart';
import '../repository/music_repository.dart';
import '../repository/playlist_repository.dart';
import '../repository/search_repository.dart';
import '../repository/user_repository.dart';
import '../security/jwt.security.dart';

Handler middleware(Handler handler) {
  final database = Database();
  final userRepository = UserRepository(database);
  final musicRepository = MusicRepository(database);
  final authorRepository = AuthorRepository(database);
  final categoryRepository = CategoryRepository(database);
  final albumRepository = AlbumRepository(database);
  final playlistRepository = PlaylistRepository(database);
  final historyRepository = HistoryRepository(database);
  final likeMusicRepository = LikeMusicRepository(database);
  final followAuthorRepository = FollowAuthorRepository(database);
  final searchRepository = SearchRepository(database);
  final redisService = RedisService();
  final jwtService = JwtService(redisService);
  final uploadMusicService = UploadMusicService();
  final uploadAlbumService = UploadAlbumService();
  final userController = UserController(userRepository);
  final musicController = MusicController(musicRepository, redisService);
  final authorController = AuthorController(authorRepository);
  final albumController = AlbumController(albumRepository);
  final categoryController = CategoryController(categoryRepository);
  final playlistController =
      PlaylistController(playlistRepository, redisService);
  final historyController = HistoryController(historyRepository);
  final likeMusicController = LikeMusicController(likeMusicRepository);
  final followAuthorController = FollowAuthorController(followAuthorRepository);
  final searchController = SearchController(searchRepository);
  final jwtMiddleware = createJwtMiddleware(jwtService, redisService);

  return handler
      .use(provider<Database>((context) => database))
      .use(provider<IRedisService>((context) => redisService))
      .use(provider<JwtService>((context) => jwtService))
      .use(provider<UserRepository>((context) => userRepository))
      .use(provider<UserController>((context) => userController))
      .use(provider<MusicController>((context) => musicController))
      .use(provider<AuthorController>((context) => authorController))
      .use(provider<CategoryController>((context) => categoryController))
      .use(provider<AlbumController>((context) => albumController))
      .use(provider<PlaylistController>((context) => playlistController))
      .use(provider<HistoryController>((context) => historyController))
      .use(provider<LikeMusicController>((context) => likeMusicController))
      .use(
          provider<FollowAuthorController>((context) => followAuthorController),)
      .use(provider<SearchController>((context) => searchController))
      .use(provider<UploadMusicService>((context) => uploadMusicService))
      .use(provider<UploadAlbumService>((context) => uploadAlbumService))
      .use(loggingMiddleware())
      .use(jwtMiddleware);
}

Middleware injectionController(JwtService jwtService) {
  return (handler) {
    return handler
        .use(provider<Database>((context) => Database()))
        .use(provider<IRedisService>((context) => RedisService()))
        .use(provider<JwtService>((context) => jwtService))
        .use(provider<UploadMusicService>((context) => UploadMusicService()))
        .use(provider<UploadAlbumService>((context) => UploadAlbumService()))
        .use(provider<UserRepository>((context) {
      final db = context.read<Database>();
      return UserRepository(db);
    }),).use(provider<UserController>((context) {
      final userRepository = context.read<UserRepository>();
      return UserController(userRepository);
    }),).use(provider<MusicRepository>((context) {
      final db = context.read<Database>();
      return MusicRepository(db);
    }),).use(provider<MusicController>((context) {
      final musicRepository = context.read<MusicRepository>();
      return MusicController(musicRepository, redisService);
    }),).use(provider<AuthorController>((context) {
      final authorRepository = context.read<AuthorRepository>();
      return AuthorController(authorRepository);
    }),).use(provider<CategoryController>((context) {
      final categoryRepository = context.read<CategoryRepository>();
      return CategoryController(categoryRepository);
    }),).use(provider<AlbumController>((context) {
      final albumRepository = context.read<AlbumRepository>();
      return AlbumController(albumRepository);
    }),).use(provider<PlaylistController>((context) {
      final playlistRepository = context.read<PlaylistRepository>();
      return PlaylistController(playlistRepository, redisService);
    }),).use(provider<HistoryController>((context) {
      final historyRepository = context.read<HistoryRepository>();
      return HistoryController(historyRepository);
    }),).use(provider<LikeMusicController>((context) {
      final likeMusicRepository = context.read<LikeMusicRepository>();
      return LikeMusicController(likeMusicRepository);
    }),).use(provider<FollowAuthorController>((context) {
      final followAuthorRepository = context.read<FollowAuthorRepository>();
      return FollowAuthorController(followAuthorRepository);
    }),).use(provider<SearchController>((context) {
      final searchRepository = context.read<SearchRepository>();
      return SearchController(searchRepository);
    }),).use(loggingMiddleware());
  };
}

Middleware createJwtMiddleware(
    JwtService jwtService, IRedisService redisService,) {
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
                  'Thiếu hoặc token không hợp lệ trong header Authorization',
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
          body: {'message': 'Xác thực token thất bại: $e'},
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

      var requestBody = await request.body();
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
          response.headers,);

      return newResponse;
    };
  };
}
