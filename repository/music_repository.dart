import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
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
        SELECT id, title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl,albumId
        FROM music
        WHERE id = @id
      '''),
        parameters: {'id': id},
      );

      if (musicResult.isEmpty || musicResult.first.isEmpty) {
        return null;
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
        albumId: musicRow[8] as int,
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
      throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
    }
  }

  @override
  Future<Music?> findMusicByTitle(String title) async {
    try {
      final musicResult = await _db.executor.execute(
        Sql.named('''
      SELECT id, title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl 
      FROM music 
            WHERE LOWER(title) = LOWER(@title)
      WHERE title = @title 
    '''),
        parameters: {'title': title},
      );

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
      throw CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
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
