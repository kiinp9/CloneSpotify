import 'dart:io';
import 'package:postgres/postgres.dart';

import '../database/postgres.dart';
import '../model/author.dart';
import '../model/music.dart';
import '../exception/config.exception.dart';
import '../constant/config.message.dart';

abstract class IAuthorRepo {
  Future<Author?> findAuthorById(int id);
  Future<Author?> findAuthorByName(String name);
}

class AuthorRepository implements IAuthorRepo {
  AuthorRepository(this._db);
  final Database _db;

  @override
  Future<Author?> findAuthorById(int id) async {
    try {
      final authorResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, name, description, avatarUrl, createdAt, updatedAt 
        FROM author 
        WHERE id = @id
        '''),
        parameters: {'id': id},
      );

      if (authorResult.isEmpty || authorResult.first.isEmpty) {
        return null;
      }

      final authorRow = authorResult.first;
      final author = Author(
        id: authorRow[0] as int,
        name: authorRow[1] as String,
        description: authorRow[2] as String,
        avatarUrl: authorRow[3] as String?,
        createdAt: _parseDate(authorRow[4]),
        updatedAt: _parseDate(authorRow[5]),
      );

      final musicResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, 
               m.createdAt, m.updatedAt, m.imageUrl
        FROM music m
        JOIN music_author ma ON m.id = ma.musicId
        WHERE ma.authorId = @id
        '''),
        parameters: {'id': id},
      );

      author.musics = musicResult.map((musicRow) {
        return Music(
          id: musicRow[0] as int,
          title: musicRow[1] as String,
          description: musicRow[2] as String,
          broadcastTime: musicRow[3] as int,
          linkUrlMusic: musicRow[4] as String,
          createdAt: _parseDate(musicRow[5]),
          updatedAt: _parseDate(musicRow[6]),
          imageUrl: musicRow[7] as String,
        );
      }).toList();

      return author;
    } catch (e) {
      throw CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
    }
  }

  Future<Author?> findAuthorByName(String name) async {
    try {
      final authorResult = await _db.executor.execute(
        Sql.named('''
 SELECT id, name, description, avatarUrl, createdAt, updatedAt 
        FROM author 
WHERE LOWER(name) = LOWER(@name)
'''),
        parameters: {'name': name},
      );

      final row = authorResult.first;
      final author = Author(
        id: row[0] as int,
        name: row[1] as String,
        description: row[2] as String,
        avatarUrl: row[3] as String?,
        createdAt: _parseDate(row[4]),
        updatedAt: _parseDate(row[5]),
      );

      final musicResult = await _db.executor.execute(
        Sql.named('''
SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, 
               m.createdAt, m.updatedAt, m.imageUrl
               FROM music m 
               JOIN music_author ma ON m.id = ma.musicId
               WHERE ma.authorId = @authorId
'''),
        parameters: {'authorId': author.id},
      );

      author.musics = musicResult.map((musicRow) {
        return Music(
          id: musicRow[0] as int,
          title: musicRow[1] as String,
          description: musicRow[2] as String,
          broadcastTime: musicRow[3] as int,
          linkUrlMusic: musicRow[4] as String,
          createdAt: _parseDate(musicRow[5]),
          updatedAt: _parseDate(musicRow[6]),
          imageUrl: musicRow[7] as String,
        );
      }).toList();
      return author;
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
