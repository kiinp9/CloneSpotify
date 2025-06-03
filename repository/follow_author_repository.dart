import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../model/follow_author.dart';

abstract class IFollowAuthorRepo {
  Future<FollowAuthor?> followAuthor(int userId, int authorId);
  Future<FollowAuthor> unFollowAuthor(int userId, int authorId);
  Future<List<Map<String, dynamic>>> getAuthorFromFollowAuthor(
    int userId, {
    int offset = 0,
    int limit = 5,
  });
}

class FollowAuthorRepository implements IFollowAuthorRepo {
  FollowAuthorRepository(this._db);
  final Database _db;

  @override
  Future<FollowAuthor?> followAuthor(int userId, int authorId) async {
    try {
      final now = DateTime.now();

      final result = await _db.executor.execute(Sql.named('''
      INSERT INTO followAuthor (userId, authorId, createdAt, updatedAt)
      VALUES (@userId, @authorId, @createdAt, @updatedAt)
      ON CONFLICT (userId, authorId) DO NOTHING
      RETURNING id, userId, authorId, createdAt, updatedAt
    '''), parameters: {
        'userId': userId,
        'authorId': authorId,
        'createdAt': now,
        'updatedAt': now,
      },);

      if (result.isEmpty) {
        return null;
      }

      await _db.executor.execute(Sql.named('''
      UPDATE author
      SET followingCount = COALESCE(followingCount, 0) + 1
      WHERE id = @authorId
    '''), parameters: {
        'authorId': authorId,
      },);

      final row = result.first;
      return FollowAuthor(
        id: row[0]! as int,
        userId: row[1]! as int,
        authorId: row[2]! as int,
        createdAt: row[3]! as DateTime,
        updatedAt: row[4]! as DateTime,
      );
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<FollowAuthor> unFollowAuthor(int userId, int authorId) async {
    try {
      final author = await _db.executor.execute(
        Sql.named('''
        SELECT * FROM followAuthor
        WHERE userId = @userId AND authorId = @authorId
      '''),
        parameters: {'userId': userId, 'authorId': authorId},
      );

      if (author.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.NOT_FOLLOWING,
          HttpStatus.badRequest,
        );
      }

      final row = author.first;
      final followAuthor = FollowAuthor(
        id: row[0]! as int,
        userId: row[1]! as int,
        authorId: row[2]! as int,
        createdAt: row[3]! as DateTime,
        updatedAt: row[4]! as DateTime,
      );

      await _db.executor.execute(
        Sql.named('''
        DELETE FROM followAuthor
        WHERE userId = @userId AND authorId = @authorId
      '''),
        parameters: {
          'userId': userId,
          'authorId': authorId,
        },
      );

      await _db.executor.execute(
        Sql.named('''
        UPDATE author
        SET followingCount = GREATEST(COALESCE(followingCount, 0) - 1, 0)
        WHERE id = @authorId
      '''),
        parameters: {
          'authorId': authorId,
        },
      );

      return followAuthor;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw const CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAuthorFromFollowAuthor(
    int userId, {
    int offset = 0,
    int limit = 5,
  }) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''
SELECT 
  a.id AS authorId,
  a.name AS authorName,
  a.avatarUrl AS authorAvatarUrl
FROM followAuthor fa
JOIN author a ON fa.authorId = a.id
WHERE fa.userId = @userId
ORDER BY a.followingCount DESC
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
}
