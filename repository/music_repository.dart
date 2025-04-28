import 'dart:io';
import 'dart:async';

import 'package:postgres/postgres.dart';
import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../model/author.dart';
import '../model/category.dart';
import '../model/music.dart';
import '../libs/cloudinary/cloudinary.service.dart';
import '../ultis/ffmpeg_helper.dart';

abstract class IMusicRepo {
  Future<int?> uploadMusic(Music music, String musicFilePath,
      String imageFilePath, Author author, List<Category> categories);
  Future<Music?> findMusicById(int id);
  Future<Music?> findMusicByTitle(String title);
  Future<List<Music>> showMusicPaging({int offset = 0, int limit = 10});
  Future<List<Music>> showMusicByCategory(int categoryId);
  Future<List<Category>> showCategoryPaging({int offset = 0, int limit = 5});
  Future<Music?> nextMusic(int currentMusicId);
}

class MusicRepository implements IMusicRepo {
  MusicRepository(this._db) : _cloudinaryService = CloudinaryService();
  final Database _db;
  final CloudinaryService _cloudinaryService;

  @override
  Future<int?> uploadMusic(Music music, String musicFilePath,
      String imageFilePath, Author author, List<Category> categories) async {
    try {
      final int? durationInSeconds =
          await FFmpegHelper.getAudioDuration(musicFilePath);
      if (durationInSeconds == null) {
        throw const CustomHttpException(
            ErrorMessage.UNABLE_TO_GET_SONG_DURATION,
            HttpStatus.internalServerError);
      }

      String? musicUrl = await _cloudinaryService.uploadFile(musicFilePath);
      String? imageUrl = await _cloudinaryService.uploadFile(imageFilePath);
      String? avatarUrl = author.avatarUrl != null
          ? await _cloudinaryService.uploadFile(author.avatarUrl!)
          : null;

      final now = DateTime.now().toIso8601String();

      final musicResult = await _db.executor.execute(
        Sql.named('''
          INSERT INTO music (title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl)
          VALUES (@title, @description, @broadcastTime, @linkUrlMusic, @createdAt, @updatedAt, @imageUrl)
          RETURNING id
        '''),
        parameters: {
          'title': music.title,
          'description': music.description,
          'broadcastTime': durationInSeconds,
          'linkUrlMusic': musicUrl,
          'createdAt': now,
          'updatedAt': now,
          'imageUrl': imageUrl,
        },
      );

      if (musicResult.isEmpty || musicResult.first.isEmpty) {
        throw const CustomHttpException(
            ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
      }

      final musicId = musicResult.first[0] as int;

      final existingAuthorResult = await _db.executor.execute(
        Sql.named('SELECT id FROM author WHERE name = @name'),
        parameters: {'name': author.name},
      );

      int authorId;
      if (existingAuthorResult.isNotEmpty &&
          existingAuthorResult.first.isNotEmpty) {
        authorId = existingAuthorResult.first[0] as int;
        await _db.executor.execute(
          Sql.named('''
            UPDATE author 
            SET description = CASE WHEN @description = '' THEN description ELSE @description END,
                avatarUrl = COALESCE(@avatarUrl, avatarUrl),
                updatedAt = @updatedAt
            WHERE id = @id
          '''),
          parameters: {
            'id': authorId,
            'description': author.description ?? '',
            'avatarUrl': avatarUrl,
            'updatedAt': now,
          },
        );
      } else {
        final authorResult = await _db.executor.execute(
          Sql.named('''
            INSERT INTO author (name, description, avatarUrl, createdAt, updatedAt)
            VALUES (@name, @description, @avatarUrl, @createdAt, @updatedAt)
            RETURNING id
          '''),
          parameters: {
            'name': author.name,
            'description': author.description ?? '',
            'avatarUrl': avatarUrl,
            'createdAt': now,
            'updatedAt': now,
          },
        );
        authorId = authorResult.first[0] as int;
      }

      final existingMusicAuthorResult = await _db.executor.execute(
        Sql.named(
            'SELECT 1 FROM music_author WHERE musicId = @musicId AND authorId = @authorId'),
        parameters: {
          'musicId': musicId,
          'authorId': authorId,
        },
      );

      if (existingMusicAuthorResult.isEmpty) {
        await _db.executor.execute(
          Sql.named('''
            INSERT INTO music_author (musicId, authorId)
            VALUES (@musicId, @authorId)
          '''),
          parameters: {
            'musicId': musicId,
            'authorId': authorId,
          },
        );
      }

      if (categories.isNotEmpty) {
        for (var category in categories) {
          final existingCategoryResult = await _db.executor.execute(
            Sql.named('SELECT id FROM category WHERE name = @name'),
            parameters: {'name': category.name},
          );

          int categoryId;
          if (existingCategoryResult.isNotEmpty &&
              existingCategoryResult.first.isNotEmpty) {
            categoryId = existingCategoryResult.first[0] as int;
            await _db.executor.execute(
              Sql.named('''
                UPDATE category 
                SET description = CASE WHEN @description = '' THEN description ELSE @description END,
                    updatedAt = @updatedAt
                WHERE id = @id
              '''),
              parameters: {
                'id': categoryId,
                'description': category.description ?? '',
                'updatedAt': now,
              },
            );
          } else {
            final categoryResult = await _db.executor.execute(
              Sql.named('''
                INSERT INTO category (name, description, createdAt, updatedAt)
                VALUES (@name, @description, @createdAt, @updatedAt)
                RETURNING id
              '''),
              parameters: {
                'name': category.name,
                'description': category.description ?? '',
                'createdAt': now,
                'updatedAt': now,
              },
            );
            categoryId = categoryResult.first[0] as int;
          }

          final existingMusicCategoryResult = await _db.executor.execute(
            Sql.named(
                'SELECT 1 FROM music_category WHERE musicId = @musicId AND categoryId = @categoryId'),
            parameters: {
              'musicId': musicId,
              'categoryId': categoryId,
            },
          );

          if (existingMusicCategoryResult.isEmpty) {
            await _db.executor.execute(
              Sql.named('''
                INSERT INTO music_category (musicId, categoryId)
                VALUES (@musicId, @categoryId)
              '''),
              parameters: {
                'musicId': musicId,
                'categoryId': categoryId,
              },
            );
          }
        }
      }

      return musicId;
    } catch (e) {
      throw CustomHttpException(
          "Lỗi khi upload nhạc: $e", HttpStatus.internalServerError);
    }
  }

  @override
  Future<Music?> findMusicById(int id) async {
    try {
      final musicResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl,listenCount
        FROM music
        WHERE id = @id
      '''),
        parameters: {'id': id},
      );

      if (musicResult.isEmpty) {
        throw CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final musicRow = musicResult.first;
      final music = Music(
        id: musicRow[0] as int,
        title: musicRow[1] as String,
        description: musicRow[2] as String,
        broadcastTime: musicRow[3] as int,
        linkUrlMusic: musicRow[4] as String,
        createdAt: _parseDate(musicRow[5]),
        updatedAt: _parseDate(musicRow[6]),
        imageUrl: musicRow[7] as String,
        listenCount: musicRow[8] as int,
      );

      final authorResult = await _db.executor.execute(
        Sql.named('''
        SELECT a.id, a.name, a.description, a.avatarUrl, a.createdAt, a.updatedAt
        FROM author a
        JOIN music_author ma ON a.id = ma.authorId
        WHERE ma.musicId = @id
      '''),
        parameters: {'id': id},
      );

      music.authors = authorResult.map((row) {
        return Author(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          avatarUrl: row[3] as String?,
          createdAt: _parseDate(row[4]),
          updatedAt: _parseDate(row[5]),
        );
      }).toList();

      final categoryResult = await _db.executor.execute(
        Sql.named('''
        SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt
        FROM category c
        JOIN music_category mc ON c.id = mc.categoryId
        WHERE mc.musicId = @id
      '''),
        parameters: {'id': id},
      );

      music.categories = categoryResult.map((row) {
        return Category(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
        );
      }).toList();

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<Music?> findMusicByTitle(String title) async {
    try {
      final musicResult = await _db.executor.execute(
        Sql.named('''
      SELECT id, title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl,listenCount
      FROM music 
      WHERE LOWER(title) = LOWER(@title)
    '''),
        parameters: {'title': title},
      );

      if (musicResult.isEmpty) {
        throw CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }
      final musicRow = musicResult.first;
      final music = Music(
        id: musicRow[0] as int,
        title: musicRow[1] as String,
        description: musicRow[2] as String,
        broadcastTime: musicRow[3] as int,
        linkUrlMusic: musicRow[4] as String,
        createdAt: _parseDate(musicRow[5]),
        updatedAt: _parseDate(musicRow[6]),
        imageUrl: musicRow[7] as String,
        listenCount: musicRow[8] as int,
      );

      final authorResult = await _db.executor.execute(
        Sql.named('''
      SELECT a.id, a.name, a.description, a.avatarUrl, a.createdAt, a.updatedAt 
      FROM author a 
      JOIN music_author ma ON a.id = ma.authorId 
      WHERE ma.musicId = @musicId
    '''),
        parameters: {'musicId': music.id},
      );

      music.authors = authorResult.map((row) {
        return Author(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          avatarUrl: row[3] as String?,
          createdAt: _parseDate(row[4]),
          updatedAt: _parseDate(row[5]),
        );
      }).toList();

      final categoryResult = await _db.executor.execute(
        Sql.named('''
      SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt 
      FROM category c 
      JOIN music_category mc ON c.id = mc.categoryId 
      WHERE mc.musicId = @musicId
    '''),
        parameters: {'musicId': music.id},
      );

      music.categories = categoryResult.map((row) {
        return Category(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
        );
      }).toList();

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Music>> showMusicPaging({int offset = 0, int limit = 10}) async {
    try {
      final musicResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, title, imageUrl
        FROM music
  ORDER BY RANDOM()
        LIMIT @limit
        OFFSET @offset
      '''),
        parameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (musicResult.isEmpty) {
        return [];
      }

      final List<Music> musics = [];

      for (final row in musicResult) {
        final music = Music(
          id: row[0] as int,
          title: row[1] as String,
          imageUrl: row[2] as String,
        );

        final authorResult = await _db.executor.execute(
          Sql.named('''
          SELECT a.id, a.name
          FROM author a
          JOIN music_author ma ON a.id = ma.authorId
          WHERE ma.musicId = @musicId
        '''),
          parameters: {'musicId': music.id},
        );

        music.authors = authorResult.map((row) {
          return Author(
            id: row[0] as int,
            name: row[1] as String,
          );
        }).toList();

        musics.add(music);
      }

      return musics;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  Future<Music?> nextMusic(int currentMusicId) async {
    try {
      final authorResult = await _db.executor.execute(
        Sql.named('''
        SELECT authorId
        FROM music_author
        WHERE musicId = @musicId
        LIMIT 1
      '''),
        parameters: {'musicId': currentMusicId},
      );

      if (authorResult.isEmpty) {
        return null;
      }

      final authorId = authorResult.first[0] as int;

      final nextMusicResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, m.createdAt, m.updatedAt, m.imageUrl,m.listenCount
        FROM music m
        JOIN music_author ma ON m.id = ma.musicId
        WHERE ma.authorId = @authorId
          AND m.id != @currentMusicId
        ORDER BY RANDOM()
        LIMIT 1;
      '''),
        parameters: {
          'authorId': authorId,
          'currentMusicId': currentMusicId,
        },
      );

      if (nextMusicResult.isEmpty) {
        throw CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final musicRow = nextMusicResult.first;

      final music = Music(
        id: musicRow[0] as int,
        title: musicRow[1] as String,
        description: musicRow[2] as String,
        broadcastTime: musicRow[3] as int,
        linkUrlMusic: musicRow[4] as String,
        createdAt: _parseDate(musicRow[5]),
        updatedAt: _parseDate(musicRow[6]),
        imageUrl: musicRow[7] as String,
        listenCount: musicRow[8] as int,
      );
      if (music.id != null) {
        await incrementListenCount(music.id!);
      }

      final author = await _db.executor.execute(
        Sql.named('''
        SELECT a.id, a.name, a.description, a.avatarUrl, a.createdAt, a.updatedAt
        FROM author a
        JOIN music_author ma ON a.id = ma.authorId
        WHERE ma.musicId = @musicId
      '''),
        parameters: {'musicId': music.id},
      );

      music.authors = author.map((row) {
        return Author(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          avatarUrl: row[3] as String?,
          createdAt: _parseDate(row[4]),
          updatedAt: _parseDate(row[5]),
        );
      }).toList();

      final categoryResult = await _db.executor.execute(
        Sql.named('''
        SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt
        FROM category c
        JOIN music_category mc ON c.id = mc.categoryId
        WHERE mc.musicId = @musicId
      '''),
        parameters: {'musicId': music.id},
      );

      music.categories = categoryResult.map((row) {
        return Category(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
        );
      }).toList();

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Music>> showMusicByCategory(int categoryId) async {
    try {
      final musicResult = await _db.executor.execute(
        Sql.named('''
SELECT m.id,m.title,m.imageUrl
FROM music m 
JOIN music_category mc ON m.id = mc.musicId
WHERE mc.categoryId = @categoryId
'''),
        parameters: {'categoryId': categoryId},
      );
      if (musicResult.isEmpty) {
        return [];
      }

      final List<Music> musics = [];

      for (final row in musicResult) {
        final music = Music(
          id: row[0] as int,
          title: row[1] as String,
          imageUrl: row[2] as String,
        );

        final authorResult = await _db.executor.execute(
          Sql.named('''
          SELECT a.id, a.name
          FROM author a
          JOIN music_author ma ON a.id = ma.authorId
          WHERE ma.musicId = @musicId
        '''),
          parameters: {'musicId': music.id},
        );

        music.authors = authorResult.map((row) {
          return Author(
            id: row[0] as int,
            name: row[1] as String,
          );
        }).toList();

        musics.add(music);
      }

      return musics;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  Future<List<Category>> showCategoryPaging(
      {int offset = 0, int limit = 5}) async {
    try {
      final categoryResult = await _db.executor.execute(
        Sql.named('''
  SELECT id, name
  FROM category
    ORDER BY RANDOM()
          LIMIT @limit
          OFFSET @offset
  '''),
        parameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (categoryResult.isEmpty) {
        return [];
      }
      final categories = categoryResult.map((row) {
        return Category(
          id: row[0] as int,
          name: row[1] as String,
        );
      }).toList();

      return categories;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  Future<void> incrementListenCount(int musicId) async {
    try {
      await _db.executor.execute(
        Sql.named('''
        UPDATE music
        SET listenCount = listenCount + 1
        WHERE id = @id
      '''),
        parameters: {
          'id': musicId,
        },
      );
    } catch (e) {
      throw CustomHttpException(
        "Lỗi khi cập nhật số lần nghe: $e",
        HttpStatus.internalServerError,
      );
    }
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) {
      return null;
    } else if (date is DateTime) {
      return date;
    } else if (date is String) {
      return DateTime.tryParse(date);
    }
    return null;
  }
}
