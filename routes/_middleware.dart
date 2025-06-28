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
        provider<FollowAuthorController>((context) => followAuthorController),
      )
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
        .use(
      provider<UserRepository>((context) {
        final db = context.read<Database>();
        return UserRepository(db);
      }),
    ).use(
      provider<UserController>((context) {
        final userRepository = context.read<UserRepository>();
        return UserController(userRepository);
      }),
    ).use(
      provider<MusicRepository>((context) {
        final db = context.read<Database>();
        return MusicRepository(db);
      }),
    ).use(
      provider<MusicController>((context) {
        final musicRepository = context.read<MusicRepository>();
        return MusicController(musicRepository, redisService);
      }),
    ).use(
      provider<AuthorController>((context) {
        final authorRepository = context.read<AuthorRepository>();
        return AuthorController(authorRepository);
      }),
    ).use(
      provider<CategoryController>((context) {
        final categoryRepository = context.read<CategoryRepository>();
        return CategoryController(categoryRepository);
      }),
    ).use(
      provider<AlbumController>((context) {
        final albumRepository = context.read<AlbumRepository>();
        return AlbumController(albumRepository);
      }),
    ).use(
      provider<PlaylistController>((context) {
        final playlistRepository = context.read<PlaylistRepository>();
        return PlaylistController(playlistRepository, redisService);
      }),
    ).use(
      provider<HistoryController>((context) {
        final historyRepository = context.read<HistoryRepository>();
        return HistoryController(historyRepository);
      }),
    ).use(
      provider<LikeMusicController>((context) {
        final likeMusicRepository = context.read<LikeMusicRepository>();
        return LikeMusicController(likeMusicRepository);
      }),
    ).use(
      provider<FollowAuthorController>((context) {
        final followAuthorRepository = context.read<FollowAuthorRepository>();
        return FollowAuthorController(followAuthorRepository);
      }),
    ).use(
      provider<SearchController>((context) {
        final searchRepository = context.read<SearchRepository>();
        return SearchController(searchRepository);
      }),
    ).use(loggingMiddleware());
  };
}

Middleware createJwtMiddleware(
  JwtService jwtService,
  IRedisService redisService,
) {
  return (handler) {
    return (context) async {
      // Khai báo path ở đây để có thể sử dụng trong catch block
      final path = context.request.uri.path;
      final method = context.request.method;

      try {
        // Danh sách các path được bỏ qua xác thực JWT
        final publicPaths = [
          '/app/auth/register',
          '/app/auth/login',
          '/app/auth/forgot-password',
          '/app/auth/check-otp',
          '/app/auth/reset-password',
        ];

        // Bỏ qua xác thực cho các path công khai
        for (final publicPath in publicPaths) {
          if (path.startsWith(publicPath)) {
            return await handler(context);
          }
        }

        // Bỏ qua xác thực cho static files
        final staticExtensions = [
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
        ];
        if (staticExtensions.any((ext) => path.toLowerCase().contains(ext))) {
          return await handler(context);
        }

        // Bỏ qua cho OPTIONS request (CORS preflight)
        if (method == HttpMethod.options) {
          return await handler(context);
        }

        // Kiểm tra nếu request yêu cầu HTML content
        final acceptHeader = context.request.headers['accept']?.toLowerCase();
        if (acceptHeader != null && acceptHeader.contains('text/html')) {
          // Nếu là request HTML và không phải API endpoint thì bỏ qua JWT
          if (!path.startsWith('/app/')) {
            return await handler(context);
          }
        }

        // Từ đây trở đi mới kiểm tra JWT cho các API endpoints
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
          id: userData['id'] as int?,
          email: userData['email']?.toString() ?? '',
          roleId: userData['roleId'] as int?,
          role: userData['roleName'] is String
              ? Role(name: userData['roleName'] as String)
              : null,
        );

        return handler(context.provide(() => user));
      } catch (e) {
        print('JWT Middleware Error: $e');
        print('Path: $path');
        print('Method: ${method.name}');

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

      // Đọc body một cách an toàn
      String requestBody = '{}';
      try {
        final bodyContent = await request.body();
        requestBody = bodyContent.isEmpty ? '{}' : bodyContent;
      } catch (e) {
        requestBody = '{}';
      }

      // Log request
      AppLogger.logRequest(method, path, headers, requestBody);

      Response response;
      try {
        response = await handler(context);
      } catch (e, stackTrace) {
        AppLogger.logError('Handler error: $e', e, stackTrace);
        rethrow;
      }

      // Log response
      try {
        final responseBody = await response.body();
        final newResponse = response.copyWith(body: responseBody);

        // Parse response body safely
        dynamic parsedBody;
        if (responseBody.isNotEmpty) {
          try {
            parsedBody = jsonDecode(responseBody);
          } catch (e) {
            parsedBody = responseBody;
          }
        } else {
          parsedBody = "";
        }

        AppLogger.logResponse(
          method,
          path,
          response.statusCode,
          parsedBody,
          response.headers,
        );

        return newResponse;
      } catch (e) {
        AppLogger.logError('Response logging error: $e');
        return response;
      }
    };
  };
}
