import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../model/like_music.dart';

abstract class ILikeMusicRepo {
  Future<LikeMusic?> addMusicToLikeMusic(int userId, int musicId);
  Future<List<Map<String, dynamic>>> getMusicFromLikeMusic(int userId);
  Future<LikeMusic> deleteMusicFromLikeMusic(int userId, int musicId);
}

class LikeMusicRepository implements ILikeMusicRepo {
  LikeMusicRepository(this._db);
  final Database _db;

  @override
  Future<LikeMusic?> addMusicToLikeMusic(int userId, int musicId) async {
    try {
      final now = DateTime.now();

      final result = await _db.executor.execute(
        Sql.named('''
INSERT INTO likeMusic(userId, musicId, createdAt, updatedAt)
VALUES (@userId, @musicId, @createdAt, @updatedAt)
ON CONFLICT (userId, musicId) DO NOTHING
RETURNING id, userId, musicId, createdAt, updatedAt
'''),
        parameters: {
          'userId': userId,
          'musicId': musicId,
          'createdAt': now,
          'updatedAt': now,
        },
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;

      final likeMusic = LikeMusic(
        id: row[0]! as int,
        userId: row[1]! as int,
        musicId: row[2]! as int,
        createdAt: row[3]! as DateTime,
        updatedAt: row[4]! as DateTime,
      );

      return likeMusic;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMusicFromLikeMusic(int userId) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''
  SELECT
          m.id AS musicId,
          m.title AS musicTitle,
          m.imageUrl AS musicImageUrl,
          a.name AS authorName
        FROM likeMusic lm
          JOIN music m ON lm.musicId = m.id
          JOIN music_author ma ON m.id = ma.musicId
          JOIN author a ON ma.authorId = a.id
        WHERE lm.userId = @userId
  
'''),
        parameters: {
          'userId': userId,
        },
      );
      if (result.isEmpty) return [];
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
  Future<LikeMusic> deleteMusicFromLikeMusic(int userId, int musicId) async {
    try {
      final music = await _db.executor.execute(
        Sql.named('''
        SELECT * FROM likeMusic
        WHERE userId = @userId AND musicId = @musicId
      '''),
        parameters: {'userId': userId, 'musicId': musicId},
      );

      if (music.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final row = music.first;
      final likeMusic = LikeMusic(
        id: row[0]! as int,
        userId: row[1]! as int,
        musicId: row[2]! as int,
        createdAt: row[3]! as DateTime,
        updatedAt: row[4]! as DateTime,
      );

      await _db.executor.execute(
        Sql.named('''
        DELETE FROM likeMusic WHERE userId = @userId AND musicId = @musicId
      '''),
        parameters: {
          'userId': userId,
          'musicId': musicId,
        },
      );

      return likeMusic;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }
}
