import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../model/history.dart';
import '../model/history_album.dart';
import '../model/history_author.dart';

abstract class IHistoryRepo {
  Future<History> addMusicToHistory(int userId, int musicId);
  Future<List<Map<String, dynamic>>> getMusicByHistory(
    int userId, {
    int offset = 0,
    int limit = 8,
  });
  Future<HistoryAuthor> addAuthorToHistoryAuthor(int userId, int authorId);
  Future<List<Map<String, dynamic>>> getAuthorByHistoryAuthor(int userId,
      {int offset = 0, int limit = 8,});
  Future<HistoryAlbum?> createHistoryAlbum(
    int userId,
    int? albumId,
    int musicId,
  );

  Future<List<Map<String, dynamic>>> getAlbumByHistoryAlbum(
    int userId, {
    int offset = 0,
    int limit = 8,
  });
}

class HistoryRepository implements IHistoryRepo {
  HistoryRepository(this._db);
  final Database _db;
  @override
  Future<History> addMusicToHistory(int userId, int musicId) async {
    try {
      final now = DateTime.now();

      final result = await _db.executor.execute(
        Sql.named('''
        INSERT INTO history (userId, musicId, createdAt)
        VALUES (@userId, @musicId, @createdAt)
        ON CONFLICT (userId, musicId) DO NOTHING
        RETURNING id, userId, musicId, createdAt
      '''),
        parameters: {
          'userId': userId,
          'musicId': musicId,
          'createdAt': now,
        },
      );

      if (result.isEmpty || result.first.isEmpty) {
        final existing = await _db.executor.execute(
          Sql.named('''
          SELECT id, userId, musicId, createdAt
          FROM history
          WHERE userId = @userId AND musicId = @musicId
        '''),
          parameters: {
            'userId': userId,
            'musicId': musicId,
          },
        );

        if (existing.isEmpty || existing.first.isEmpty) {
          throw const CustomHttpException(
            ErrorMessageSQL.SQL_QUERY_ERROR,
            HttpStatus.internalServerError,
          );
        }

        final row = existing.first;
        final history = History(
          id: row[0]! as int,
          userId: row[1]! as int,
          musicId: row[2]! as int,
          createdAt: row[3] as DateTime?,
        );

        return history;
      }

      final row = result.first;
      final history = History(
        id: row[0]! as int,
        userId: row[1]! as int,
        musicId: row[2]! as int,
        createdAt: row[3] as DateTime?,
      );

      return history;
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
  Future<List<Map<String, dynamic>>> getMusicByHistory(
    int userId, {
    int offset = 0,
    int limit = 8,
  }) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''

  SELECT
          m.id AS musicId,
          m.title AS musicTitle,
          m.imageUrl AS musicImageUrl,
          a.name AS authorName
        FROM history h
          JOIN music m ON h.musicId = m.id
          JOIN music_author ma ON m.id = ma.musicId
          JOIN author a ON ma.authorId = a.id
        WHERE h.userId = @userId
        ORDER BY h.createdAt DESC
               LIMIT @limit OFFSET @offset

'''),
        parameters: {
          'userId': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      final grouped = <int, Map<String, dynamic>>{};
      for (final row in result) {
        final musicId = row[0]! as int;
        final title = row[1]! as String;
        final imageUrl = row[2]! as String;
        final authorName = row[3]! as String;

        grouped.putIfAbsent(
          musicId,
          () => {
            'musicId': musicId,
            'title': title,
            'imageUrl': imageUrl,
            'authors': <String>[],
          },
        );
        (grouped[musicId]!['authors'] as List<String>).add(authorName);
      }

      return grouped.values
          .map((entry) => {
                'id': entry['musicId'],
                'title': entry['title'],
                'imageUrl': entry['imageUrl'],
                'authors': (entry['authors'] as List<String>).join(', '),
              },)
          .toList();
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
  Future<HistoryAuthor> addAuthorToHistoryAuthor(
      int userId, int authorId,) async {
    try {
      final now = DateTime.now();

      final result = await _db.executor.execute(
        Sql.named('''
        INSERT INTO history_author (userId, authorId, createdAt)
        VALUES (@userId, @authorId, @createdAt)
        ON CONFLICT (userId, authorId) DO NOTHING
        RETURNING id, userId, authorId, createdAt
      '''),
        parameters: {
          'userId': userId,
          'authorId': authorId,
          'createdAt': now,
        },
      );

      if (result.isEmpty || result.first.isEmpty) {
        final existing = await _db.executor.execute(
          Sql.named('''
          SELECT id, userId, authorId, createdAt
          FROM history_author
          WHERE userId = @userId AND authorId = @authorId
        '''),
          parameters: {
            'userId': userId,
            'authorId': authorId,
          },
        );

        if (existing.isEmpty || existing.first.isEmpty) {
          throw const CustomHttpException(
            ErrorMessageSQL.SQL_QUERY_ERROR,
            HttpStatus.internalServerError,
          );
        }

        final row = existing.first;
        final historyAuthor = HistoryAuthor(
          id: row[0]! as int,
          userId: row[1]! as int,
          authorId: row[2]! as int,
          createdAt: row[3] as DateTime?,
        );

        return historyAuthor;
      }

      final row = result.first;
      final historyAuthor = HistoryAuthor(
        id: row[0]! as int,
        userId: row[1]! as int,
        authorId: row[2]! as int,
        createdAt: row[3] as DateTime?,
      );

      return historyAuthor;
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
  Future<List<Map<String, dynamic>>> getAuthorByHistoryAuthor(
    int userId, {
    int offset = 0,
    int limit = 8,
  }) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''
        SELECT
          a.id AS authorId,
          a.name AS authorName,
          a.avatarUrl AS authorAvatarUrl
        FROM history_author ha
        JOIN author a ON ha.authorId = a.id
        WHERE ha.userId = @userId
        ORDER BY ha.createdAt DESC
        LIMIT @limit OFFSET @offset
      '''),
        parameters: {
          'userId': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (result.isEmpty) return [];

      return result.map((row) {
        return {
          'authorId': row[0]! as int,
          'authorName': row[1]! as String,
          'avatarUrl': row[2]! as String,
        };
      }).toList();
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<HistoryAlbum?> createHistoryAlbum(
    int userId,
    int? albumId,
    int musicId,
  ) async {
    try {
      if (albumId == null) {
        return null;
      }

      final result = await _db.executor.execute(
        Sql.named('''
      INSERT INTO history_album (userId, albumId, musicId)
      VALUES (@userId, @albumId, @musicId)
      ON CONFLICT (userId, albumId, musicId) DO NOTHING
      RETURNING id, userId, albumId, musicId, createdAt
    '''),
        parameters: {
          'userId': userId,
          'albumId': albumId,
          'musicId': musicId,
        },
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;

      final historyAlbum = HistoryAlbum(
        id: row[0]! as int,
        userId: row[1]! as int,
        albumId: row[2]! as int,
        musicId: row[3]! as int,
        createdAt: row[4]! as DateTime,
      );

      return historyAlbum;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAlbumByHistoryAlbum(
    int userId, {
    int offset = 0,
    int limit = 8,
  }) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''
        SELECT
          a.id AS albumId, 
          a.albumTitle AS authorAlbumTitle,
          a.linkUrlImageAlbum AS albumLinkUrlImageAlbum
        FROM history_album hal
        JOIN album a ON hal.albumId = a.id 
        WHERE hal.userId = @userId
        ORDER BY hal.createdAt DESC
        LIMIT @limit OFFSET @offset
      '''),
        parameters: {
          'userId': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (result.isEmpty) {
        return [];
      }

      final albums = result.map((row) {
        return {
          'albumId': row[0]! as int,
          'albumTitle': row[1]! as String,
          'linkUrlImageAlbum': row[2]! as String,
        };
      }).toList();

      return albums;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }
}
