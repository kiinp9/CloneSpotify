import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../libs/cloudinary/service/upload-music.service.dart';
import '../model/author.dart';
import '../model/category.dart';
import '../model/music.dart';
import '../ultis/ffmpeg_helper.dart';

abstract class IMusicRepo {
  Future<int?> uploadMusic(
    Music music,
    String musicFilePath,
    String imageFilePath,
    Author author,
    List<Category> categories,
  );
  Future<Music?> findMusicById(int id);
  Future<Music?> findMusicByTitle(String title);
  Future<List<Music>> showMusicPaging({int offset = 0, int limit = 10});
  Future<List<Music>> showMusicByCategory(int categoryId);

  Future<Music?> nextMusic(int currentMusicId);
  Future<Music> updateMusic(int musicId, Map<String, dynamic> updateField);
  Future<Music> deleteMusic(int musicId);
}

class MusicRepository implements IMusicRepo {
  MusicRepository(this._db) : _uploadMusicService = UploadMusicService();
  final Database _db;
  final UploadMusicService _uploadMusicService;

  @override
  Future<int?> uploadMusic(
    Music music,
    String musicFilePath,
    String imageFilePath,
    Author author,
    List<Category> categories,
  ) async {
    try {
      final durationInSeconds =
          await FFmpegHelper.getAudioDuration(musicFilePath);
      if (durationInSeconds == null) {
        throw const CustomHttpException(
          ErrorMessage.UNABLE_TO_GET_SONG_DURATION,
          HttpStatus.internalServerError,
        );
      }

      final musicUrl = await _uploadMusicService.uploadFile(musicFilePath);
      final imageUrl = await _uploadMusicService.uploadFile(imageFilePath);
      final avatarUrl = author.avatarUrl != null
          ? await _uploadMusicService.uploadFile(author.avatarUrl!)
          : null;

      final now = DateTime.now().toIso8601String();

      final musicResult = await _db.executor.execute(
        Sql.named('''
          INSERT INTO music (title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl,listenCount,nation)
          VALUES (@title, @description, @broadcastTime, @linkUrlMusic, @createdAt, @updatedAt, @imageUrl,@listenCount,@nation)
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
          'listenCount': music.listenCount,
          'nation': music.nation,
        },
      );

      if (musicResult.isEmpty || musicResult.first.isEmpty) {
        throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR,
          HttpStatus.internalServerError,
        );
      }

      final musicId = musicResult.first[0]! as int;

      final existingAuthorResult = await _db.executor.execute(
        Sql.named('SELECT id FROM author WHERE name = @name'),
        parameters: {'name': author.name},
      );

      int authorId;
      if (existingAuthorResult.isNotEmpty &&
          existingAuthorResult.first.isNotEmpty) {
        authorId = existingAuthorResult.first[0]! as int;
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
        authorId = authorResult.first[0]! as int;
      }

      final existingMusicAuthorResult = await _db.executor.execute(
        Sql.named(
          'SELECT 1 FROM music_author WHERE musicId = @musicId AND authorId = @authorId',
        ),
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
        for (final category in categories) {
          final existingCategoryResult = await _db.executor.execute(
            Sql.named('SELECT id FROM category WHERE name = @name'),
            parameters: {'name': category.name},
          );

          int categoryId;
          if (existingCategoryResult.isNotEmpty &&
              existingCategoryResult.first.isNotEmpty) {
            categoryId = existingCategoryResult.first[0]! as int;
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
            categoryId = categoryResult.first[0]! as int;
          }

          final existingMusicCategoryResult = await _db.executor.execute(
            Sql.named(
              'SELECT 1 FROM music_category WHERE musicId = @musicId AND categoryId = @categoryId',
            ),
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
        'Lỗi khi upload nhạc: $e',
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<Music?> findMusicById(int id) async {
    try {
      final musicResult = await _db.executor.execute(
        Sql.named('''
      SELECT id, title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl,albumId, listenCount, nation
      FROM music
      WHERE id = @id
    '''),
        parameters: {'id': id},
      );

      if (musicResult.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final musicRow = musicResult.first;
      final music = Music(
        id: musicRow[0]! as int,
        title: musicRow[1]! as String,
        description: musicRow[2]! as String,
        broadcastTime: musicRow[3]! as int,
        linkUrlMusic: musicRow[4]! as String,
        createdAt: _parseDate(musicRow[5]),
        updatedAt: _parseDate(musicRow[6]),
        imageUrl: musicRow[7]! as String,
        albumId: musicRow[8] as int?,
        listenCount: musicRow[9]! as int,
        nation: musicRow[10] as String? ?? '',
      );

      final authorResult = await _db.executor.execute(
        Sql.named('''
      SELECT a.id, a.name, a.description, a.avatarUrl,a.followingCount, a.createdAt, a.updatedAt
      FROM author a
      JOIN music_author ma ON a.id = ma.authorId
      WHERE ma.musicId = @id
    '''),
        parameters: {'id': id},
      );

      music.authors = authorResult.map((row) {
        return Author(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2]! as String,
          avatarUrl: row[3] as String?,
          followingCount: row[4]! as int,
          createdAt: _parseDate(row[5]),
          updatedAt: _parseDate(row[6]),
        );
      }).toList();

      final categoryResult = await _db.executor.execute(
        Sql.named('''
      SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt, imageUrl
      FROM category c
      JOIN music_category mc ON c.id = mc.categoryId
      WHERE mc.musicId = @id
    '''),
        parameters: {'id': id},
      );

      music.categories = categoryResult.map((row) {
        return Category(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2]! as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
          imageUrl: row[5] as String? ?? '',
        );
      }).toList();

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }

      throw const CustomHttpException(
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
      SELECT id, title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl,listenCount,nation
      FROM music 
      WHERE LOWER(title) = LOWER(@title)
    '''),
        parameters: {'title': title},
      );

      if (musicResult.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }
      final musicRow = musicResult.first;
      final music = Music(
        id: musicRow[0]! as int,
        title: musicRow[1]! as String,
        description: musicRow[2]! as String,
        broadcastTime: musicRow[3]! as int,
        linkUrlMusic: musicRow[4]! as String,
        createdAt: _parseDate(musicRow[5]),
        updatedAt: _parseDate(musicRow[6]),
        imageUrl: musicRow[7]! as String,
        listenCount: musicRow[8]! as int,
        nation: musicRow[9]! as String,
      );

      final authorResult = await _db.executor.execute(
        Sql.named('''
      SELECT a.id, a.name, a.description, a.avatarUrl,a.followingCount, a.createdAt, a.updatedAt 
      FROM author a 
      JOIN music_author ma ON a.id = ma.authorId 
      WHERE ma.musicId = @musicId
    '''),
        parameters: {'musicId': music.id},
      );

      music.authors = authorResult.map((row) {
        return Author(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2]! as String,
          avatarUrl: row[3] as String?,
          followingCount: row[4]! as int,
          createdAt: _parseDate(row[5]),
          updatedAt: _parseDate(row[6]),
        );
      }).toList();

      final categoryResult = await _db.executor.execute(
        Sql.named('''
      SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt ,imageUrl
      FROM category c 
      JOIN music_category mc ON c.id = mc.categoryId 
      WHERE mc.musicId = @musicId
    '''),
        parameters: {'musicId': music.id},
      );

      music.categories = categoryResult.map((row) {
        return Category(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2]! as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
          imageUrl: row[5]! as String,
        );
      }).toList();

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
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

      final musics = <Music>[];

      for (final row in musicResult) {
        final music = Music(
          id: row[0]! as int,
          title: row[1]! as String,
          imageUrl: row[2]! as String,
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
            id: row[0]! as int,
            name: row[1]! as String,
          );
        }).toList();

        musics.add(music);
      }

      return musics;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
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

      final authorId = authorResult.first[0]! as int;

      final nextMusicResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, m.createdAt, m.updatedAt, m.imageUrl,m.albumId,m.listenCount,m.nation
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
        throw const CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final musicRow = nextMusicResult.first;

      final music = Music(
        id: musicRow[0]! as int,
        title: musicRow[1]! as String,
        description: musicRow[2]! as String,
        broadcastTime: musicRow[3]! as int,
        linkUrlMusic: musicRow[4]! as String,
        createdAt: _parseDate(musicRow[5]),
        updatedAt: _parseDate(musicRow[6]),
        imageUrl: musicRow[7]! as String,
        albumId: musicRow[8] as int?,
        listenCount: musicRow[9]! as int,
        nation: musicRow[10]! as String,
      );
      if (music.id != null) {
        await incrementListenCount(music.id!);
      }

      final author = await _db.executor.execute(
        Sql.named('''
        SELECT a.id, a.name, a.description, a.avatarUrl,a.followingCount, a.createdAt, a.updatedAt
        FROM author a
        JOIN music_author ma ON a.id = ma.authorId
        WHERE ma.musicId = @musicId
      '''),
        parameters: {'musicId': music.id},
      );

      music.authors = author.map((row) {
        return Author(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2]! as String,
          avatarUrl: row[3] as String?,
          followingCount: row[4]! as int,
          createdAt: _parseDate(row[5]),
          updatedAt: _parseDate(row[6]),
        );
      }).toList();

      final categoryResult = await _db.executor.execute(
        Sql.named('''
        SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt,c.imageUrl
        FROM category c
        JOIN music_category mc ON c.id = mc.categoryId
        WHERE mc.musicId = @musicId
      '''),
        parameters: {'musicId': music.id},
      );

      music.categories = categoryResult.map((row) {
        return Category(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2]! as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
          imageUrl: row[5]! as String,
        );
      }).toList();

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
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

      final musics = <Music>[];

      for (final row in musicResult) {
        final music = Music(
          id: row[0]! as int,
          title: row[1]! as String,
          imageUrl: row[2]! as String,
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
            id: row[0]! as int,
            name: row[1]! as String,
          );
        }).toList();

        musics.add(music);
      }

      return musics;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
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
        parameters: {'id': musicId},
      );

      final result = await _db.executor.execute(
        Sql.named('SELECT albumId FROM music WHERE id = @musicId'),
        parameters: {'musicId': musicId},
      );

      if (result.isEmpty || result.first.isEmpty) {
        return;
      }

      final albumId = result.first[0] as int?;

      if (albumId != null) {
        await _db.executor.execute(
          Sql.named('''
          UPDATE album
          SET listenCountAlbum = listenCountAlbum + 1
          WHERE id = @albumId
        '''),
          parameters: {'albumId': albumId},
        );
      }
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<Music> updateMusic(
    int musicId,
    Map<String, dynamic> updateFields,
  ) async {
    try {
      final setClauseParts = <String>[];
      final parameters = <String, dynamic>{
        'id': musicId,
        'updatedAt': DateTime.now(),
      };

      if (updateFields.containsKey('title')) {
        setClauseParts.add('title = @title');
        parameters['title'] = updateFields['title'];
      }
      if (updateFields.containsKey('description')) {
        setClauseParts.add('description = @description');
        parameters['description'] = updateFields['description'];
      }
      if (updateFields.containsKey('nation')) {
        setClauseParts.add('nation = @nation');
        parameters['nation'] = updateFields['nation'];
      }
      setClauseParts.add('updatedAt = @updatedAt');
      final setClause = setClauseParts.join(', ');
      final query = '''
UPDATE music
SET $setClause
WHERE id = @id
RETURNING id,title,description,broadcastTime,linkUrlMusic,createdAt,updatedAt,imageUrl,albumId,listenCount,nation
''';
      final result = await _db.executor.execute(
        Sql.named(query),
        parameters: parameters,
      );

      if (result.isEmpty || result.first.isEmpty) {
        throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR,
          HttpStatus.internalServerError,
        );
      }

      final row = result.first;
      return Music(
        id: row[0]! as int,
        title: row[1]! as String,
        description: row[2]! as String,
        broadcastTime: row[3]! as int,
        linkUrlMusic: row[4]! as String,
        createdAt: row[5] as DateTime?,
        updatedAt: row[6] as DateTime?,
        imageUrl: row[7] as String?,
        albumId: row[8]! as int,
        listenCount: row[9]! as int,
        nation: row[10]! as String,
      );
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<Music> deleteMusic(int musicId) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('SELECT * FROM music WHERE id = @id'),
        parameters: {'id': musicId},
      );

      if (result.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final row = result.first;

      final music = Music(
        id: row[0]! as int,
        title: row[1]! as String,
        description: row[2]! as String,
        broadcastTime: row[3]! as int,
        linkUrlMusic: row[4]! as String,
        createdAt: row[5] as DateTime?,
        updatedAt: row[6] as DateTime?,
        imageUrl: row[7] as String?,
        albumId: row[8]! as int,
        listenCount: row[9]! as int,
        nation: row[10] as String? ?? '',
      );

      await _db.executor.execute(
        Sql.named('DELETE FROM music_author WHERE musicId = @id'),
        parameters: {'id': musicId},
      );

      await _db.executor.execute(
        Sql.named('DELETE FROM music_category WHERE musicId = @id'),
        parameters: {'id': musicId},
      );

      await _db.executor.execute(
        Sql.named('DELETE FROM music WHERE id = @id'),
        parameters: {'id': musicId},
      );

      return music;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }
      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
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
