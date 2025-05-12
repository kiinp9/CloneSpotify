import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../model/history.dart';

abstract class IHistoryRepo {
  Future<History> addMusicToHistory(int userId, int musicId);
  Future<List<Map<String, dynamic>>> getMusicByHistory(int userId);
}

class HistoryRepository implements IHistoryRepo {
  final Database _db;
  HistoryRepository(this._db);
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
          id: row[0] as int,
          userId: row[1] as int,
          musicId: row[2] as int,
          createdAt: row[3] as DateTime?,
        );

        return history;
      }

      final row = result.first;
      final history = History(
        id: row[0] as int,
        userId: row[1] as int,
        musicId: row[2] as int,
        createdAt: row[3] as DateTime?,
      );

      return history;
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
  Future<List<Map<String, dynamic>>> getMusicByHistory(int userId) async {
    try {
      final history = await _db.executor.execute(
        Sql.named('''SELECT * FROM history WHERE userId = @userId'''),
        parameters: {'userId': userId},
      );
      if (history.isEmpty) {
        return [];
      }

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

'''),
        parameters: {'userId': userId},
      );

      final Map<int, Map<String, dynamic>> grouped = {};
      for (var row in result) {
        final musicId = row[0] as int;
        final title = row[1] as String;
        final imageUrl = row[2] as String;
        final authorName = row[3] as String;

        grouped.putIfAbsent(
          musicId,
          () => {
            'title': title,
            'imageUrl': imageUrl,
            'authors': <String>[],
          },
        );
        (grouped[musicId]!['authors'] as List<String>).add(authorName);
      }

      return grouped.values
          .map((entry) => {
                'title': entry['title'],
                'imageUrl': entry['imageUrl'],
                'authors': (entry['authors'] as List<String>).join(', ')
              })
          .toList();
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
}
