import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../exception/config.exception.dart';

import '../libs/cloudinary/service/upload-album.service.dart';
import '../model/album.dart';
import '../model/author.dart';
import '../model/category.dart';
import '../model/music.dart';
import '../database/postgres.dart';
import '../ultis/ffmpeg_helper.dart';

abstract class IAlbumRepo {
  Future<int?> uploadAlbum(
      Album album,
      String albumFolderPath,
      String avatarPath,
      List<Music> music,
      Author author,
      List<Category> categories);
  Future<Album?> findAlbumById(int id);
  Future<Album?> findAlbumByAlbumTitle(String albumTitle);
}

class AlbumRepository implements IAlbumRepo {
  AlbumRepository(this._db) : _uploadAlbumService = UploadAlbumService();
  final Database _db;
  final UploadAlbumService _uploadAlbumService;

  @override
  Future<int?> uploadAlbum(
      Album album,
      String albumFolderPath,
      String avatarPath,
      List<Music> music,
      Author author,
      List<Category> categories) async {
    try {
      final uploadedAlbumData = await _uploadAlbumService.uploadAlbumFromFolder(
          albumFolderPath, avatarPath);

      if (uploadedAlbumData.isEmpty) {
        throw const CustomHttpException(
            ErrorMessage.UPLOAD_FAIL, HttpStatus.badRequest);
      }

      final now = DateTime.now().toIso8601String();

      final albumResult = await _db.executor.execute(
        Sql.named('''
  INSERT INTO album (albumTitle, description, linkUrlImageAlbum, createdAt, updatedAt,nation,listenCountAlbum)
  VALUES (@albumTitle, @description, @linkUrlImageAlbum, @createdAt, @updatedAt,@nation,listenCountAlbum)
  RETURNING id
  '''),
        parameters: {
          'albumTitle': album.albumTitle,
          'description': album.description ?? '',
          'linkUrlImageAlbum': uploadedAlbumData['albumImage'],
          'createdAt': now,
          'updatedAt': now,
          'nation': album.nation,
          'listenCountAlbum': album.listenCountAlbum
        },
      );
      if (albumResult.isEmpty || albumResult.first.isEmpty) {
        throw const CustomHttpException(
            ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
      }

      final albumId = albumResult.first[0] as int;

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
            'avatarUrl': uploadedAlbumData['avatarImage'],
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
            'avatarUrl': uploadedAlbumData['avatarImage'],
            'createdAt': now,
            'updatedAt': now,
          },
        );
        authorId = authorResult.first[0] as int;
      }

      final existingAlbumAuthorResult = await _db.executor.execute(
        Sql.named(
            'SELECT 1 FROM album_author WHERE albumId = @albumId AND authorId = @authorId'),
        parameters: {
          'albumId': albumId,
          'authorId': authorId,
        },
      );

      if (existingAlbumAuthorResult.isEmpty) {
        await _db.executor.execute(
          Sql.named('''
              INSERT INTO album_author (albumId, authorId)
              VALUES (@albumId, @authorId)
            '''),
          parameters: {
            'albumId': albumId,
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

          final existingAlbumCategoryResult = await _db.executor.execute(
            Sql.named(
                'SELECT 1 FROM album_category WHERE albumId = @albumId AND categoryId = @categoryId'),
            parameters: {
              'albumId': albumId,
              'categoryId': categoryId,
            },
          );

          if (existingAlbumCategoryResult.isEmpty) {
            await _db.executor.execute(
              Sql.named('''
                  INSERT INTO album_category (albumId, categoryId)
                  VALUES (@albumId, @categoryId)
                '''),
              parameters: {
                'albumId': albumId,
                'categoryId': categoryId,
              },
            );
          }
        }
      }

      if (music.isNotEmpty) {
        for (var music in music) {
          final songName = music.title?.split('.').first ?? 'unknown_song';
          final musicFilePath =
              '${albumFolderPath.replaceAll("\\", "/")}/$songName/$songName.mp3';

          final int? broadcastTime =
              await FFmpegHelper.getAudioDuration(musicFilePath);

          if (broadcastTime == null) {
            throw const CustomHttpException(
                ErrorMessage.UNABLE_TO_GET_SONG_DURATION,
                HttpStatus.internalServerError);
          }

          String? musicUrl;
          String? imageUrl;

          if (uploadedAlbumData['songs'] != null &&
              uploadedAlbumData['songs'][songName] != null) {
            final songData =
                uploadedAlbumData['songs'][songName] as Map<String, dynamic>;

            if (songData['music'] != null &&
                (songData['music'] as List).isNotEmpty) {
              musicUrl = (songData['music'] as List).first as String;
            }

            if (songData['image'] != null &&
                (songData['image'] as List).isNotEmpty) {
              imageUrl = (songData['image'] as List).first as String;
            }
          }

          imageUrl ??= uploadedAlbumData['albumImage'] as String;

          if (musicUrl == null) {
            throw const CustomHttpException(
                'Không thể lấy URL nhạc sau khi tải lên',
                HttpStatus.internalServerError);
          }

          final musicResult = await _db.executor.execute(
            Sql.named('''
              INSERT INTO music (title, description, broadcastTime, linkUrlMusic, createdAt, updatedAt, imageUrl, albumId,listenCount,nation)
              VALUES (@title, @description, @broadcastTime, @linkUrlMusic, @createdAt, @updatedAt, @imageUrl, @albumId,@listenCount,@nation)
              RETURNING id
            '''),
            parameters: {
              'title': music.title,
              'description': music.description ?? '',
              'broadcastTime': broadcastTime,
              'linkUrlMusic': musicUrl,
              'createdAt': now,
              'updatedAt': now,
              'imageUrl': imageUrl,
              'albumId': albumId,
              'nation': album.nation,
              'listenCount': music.listenCount,
            },
          );

          if (musicResult.isEmpty || musicResult.first.isEmpty) {
            throw const CustomHttpException(
                'Failed to insert music into database',
                HttpStatus.internalServerError);
          }

          final musicId = musicResult.first[0] as int;

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

          for (var category in categories) {
            final existingCategoryResult = await _db.executor.execute(
              Sql.named('SELECT id FROM category WHERE name = @name'),
              parameters: {'name': category.name},
            );

            if (existingCategoryResult.isNotEmpty &&
                existingCategoryResult.first.isNotEmpty) {
              final categoryId = existingCategoryResult.first[0] as int;

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
      }

      return albumId;
    } catch (e) {
      if (e is CustomHttpException) {
        rethrow;
      }

      throw CustomHttpException(e.toString(), HttpStatus.internalServerError);
    }
  }

  @override
  Future<Album?> findAlbumById(int id) async {
    try {
      final albumResult = await _db.executor.execute(
        Sql.named('''
SELECT id,albumTitle,description,linkUrlImageAlbum,createdAt,updatedAt,listenCountAlbum,nation
FROM album
WHERE id = @id
'''),
        parameters: {'id': id},
      );

      if (albumResult.isEmpty || albumResult.first.isEmpty) {
        throw const CustomHttpException(
            ErrorMessage.ALBUM_NOT_FOUND, HttpStatus.notFound);
      }

      final albumRow = albumResult.first;
      final album = Album(
        id: albumRow[0] as int,
        albumTitle: albumRow[1] as String,
        description: albumRow[2] as String,
        linkUrlImageAlbum: albumRow[3] as String,
        createdAt: _parseDate(albumRow[4]),
        updatedAt: _parseDate(albumRow[5]),
        listenCountAlbum: albumRow[6] as int,
        nation: albumRow[7] as String,
      );

      final authorResult = await _db.executor.execute(
        Sql.named('''
SELECT a.id, a.name, a.description, a.avatarUrl, a.createdAt, a.updatedAt
FROM author a
JOIN album_author ala ON a.id = ala.authorId
WHERE ala.albumId = @id
'''),
        parameters: {'id': id},
      );

      album.authors = authorResult.map((row) {
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
JOIN album_category alc ON c.id = alc.categoryId
WHERE alc.albumId = @id
'''),
        parameters: {'id': id},
      );

      album.categories = categoryResult.map((row) {
        return Category(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
        );
      }).toList();

      final musicResult = await _db.executor.execute(
        Sql.named('''
SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, m.createdAt, m.updatedAt, m.imageUrl, m.albumId,m.listenCount,m.nation
FROM music m
WHERE m.albumId = @id
'''),
        parameters: {'id': id},
      );

      album.musics = musicResult.map((row) {
        return Music(
          id: row[0] as int,
          title: row[1] as String,
          description: row[2] as String,
          broadcastTime: row[3] as int,
          linkUrlMusic: row[4] as String,
          createdAt: _parseDate(row[5]),
          updatedAt: _parseDate(row[6]),
          imageUrl: row[7] as String,
          listenCount: row[8] as int,
          nation: row[9] as String,
        );
      }).toList();

      return album;
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
  Future<Album?> findAlbumByAlbumTitle(String albumTitle) async {
    try {
      final albumResult = await _db.executor.execute(
        Sql.named('''
SELECT id,albumTitle,description,linkUrlImageAlbum,createdAt,updatedAt,listenCountAlbum,nation
FROM album
WHERE LOWER(albumTitle) = LOWER(@albumTitle)
'''),
        parameters: {'albumTitle': albumTitle},
      );
      if (albumResult.isEmpty || albumResult.first.isEmpty) {
        throw const CustomHttpException(
            ErrorMessage.ALBUM_NOT_FOUND, HttpStatus.notFound);
      }

      final albumRow = albumResult.first;
      final album = Album(
        id: albumRow[0] as int,
        albumTitle: albumRow[1] as String,
        description: albumRow[2] as String,
        linkUrlImageAlbum: albumRow[3] as String,
        createdAt: _parseDate(albumRow[4]),
        updatedAt: _parseDate(albumRow[5]),
        listenCountAlbum: albumRow[6] as int,
        nation: albumRow[7] as String,
      );
      final authorResult = await _db.executor.execute(
        Sql.named('''
SELECT a.id, a.name, a.description, a.avatarUrl, a.createdAt, a.updatedAt
FROM author a
JOIN album_author ala ON a.id = ala.authorId
WHERE ala.albumId = @id
'''),
        parameters: {'id': album.id},
      );

      album.authors = authorResult.map((row) {
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
JOIN album_category alc ON c.id = alc.categoryId
WHERE alc.albumId = @id
'''),
        parameters: {'id': album.id},
      );

      album.categories = categoryResult.map((row) {
        return Category(
          id: row[0] as int,
          name: row[1] as String,
          description: row[2] as String,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
        );
      }).toList();

      final musicResult = await _db.executor.execute(
        Sql.named('''
SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, m.createdAt, m.updatedAt, m.imageUrl, m.albumId,m.listenCount,m.nation
FROM music m
WHERE m.albumId = @id
'''),
        parameters: {'id': album.id},
      );

      album.musics = musicResult.map((row) {
        return Music(
          id: row[0] as int,
          title: row[1] as String,
          description: row[2] as String,
          broadcastTime: row[3] as int,
          linkUrlMusic: row[4] as String,
          createdAt: _parseDate(row[5]),
          updatedAt: _parseDate(row[6]),
          imageUrl: row[7] as String,
          listenCount: row[8] as int,
          nation: row[9] as String,
        );
      }).toList();

      return album;
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
