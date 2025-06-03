import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../libs/cloudinary/service/upload-avatarAuthor.dart';
import '../model/album.dart';
import '../model/author.dart';
import '../model/music.dart';

abstract class IAuthorRepo {
  Future<Author?> findAuthorById(int id);
  Future<Author?> findAuthorByName(String name);
  Future<List<Author>> showAuthorPaging({int offset = 0, int limit = 8});
  Future<int?> createAuthor(Author author, String avatarPath);
}

class AuthorRepository implements IAuthorRepo {
  AuthorRepository(this._db)
      : _uploadAvatarAuthorService = UploadAvatarAuthorService();
  final Database _db;
  final UploadAvatarAuthorService _uploadAvatarAuthorService;
  final now = DateTime.now().toIso8601String();
  @override
  Future<Author?> findAuthorById(int id) async {
    try {
      final authorResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, name, description, avatarUrl,followingCount, createdAt, updatedAt 
        FROM author 
        WHERE id = @id
        '''),
        parameters: {'id': id},
      );

      if (authorResult.isEmpty || authorResult.first.isEmpty) {
        throw const CustomHttpException(
            ErrorMessage.AUTHOR_NOT_FOUND, HttpStatus.notFound,);
      }

      final authorRow = authorResult.first;
      final author = Author(
        id: authorRow[0]! as int,
        name: authorRow[1]! as String,
        description: authorRow[2]! as String,
        avatarUrl: authorRow[3] as String?,
        followingCount: authorRow[4]! as int,
        createdAt: _parseDate(authorRow[5]),
        updatedAt: _parseDate(authorRow[6]),
      );
      final albumResult = await _db.executor.execute(
        Sql.named('''
SELECT al.id,
  al.albumTitle,
  al.description,
  al.linkUrlImageAlbum,

  al.createdAt,
  al.updatedAt,
    al.nation,
  al.listenCountAlbum
  FROM album al
  JOIN album_author ala ON al.id = ala.albumId
  WHERE ala.authorId = @id
'''),
        parameters: {'id': id},
      );
      author.albums = albumResult.map((albumRow) {
        return Album(
          id: albumRow[0]! as int,
          albumTitle: albumRow[1]! as String,
          description: albumRow[2]! as String,
          linkUrlImageAlbum: albumRow[3]! as String,
          createdAt: _parseDate(albumRow[4]),
          updatedAt: _parseDate(albumRow[5]),
          nation: albumRow[6] as String? ?? '',
          listenCountAlbum: albumRow[7]! as int,
        );
      }).toList();
      final musicResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, 
               m.createdAt, m.updatedAt, m.imageUrl,m.nation, m.listenCount
        FROM music m
        JOIN music_author ma ON m.id = ma.musicId
        WHERE ma.authorId = @id
        '''),
        parameters: {'id': id},
      );

      author.musics = musicResult.map((musicRow) {
        return Music(
          id: musicRow[0]! as int,
          title: musicRow[1]! as String,
          description: musicRow[2]! as String,
          broadcastTime: musicRow[3]! as int,
          linkUrlMusic: musicRow[4]! as String,
          createdAt: _parseDate(musicRow[5]),
          updatedAt: _parseDate(musicRow[6]),
          imageUrl: musicRow[7]! as String,
          nation: musicRow[8] as String? ?? '',
          listenCount: musicRow[9]! as int,
        );
      }).toList();

      return author;
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
  Future<Author?> findAuthorByName(String name) async {
    try {
      final authorResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, name, description, avatarUrl, followingCount, createdAt, updatedAt 
        FROM author 
        WHERE LOWER(name) = LOWER(@name)
      '''),
        parameters: {'name': name},
      );

      if (authorResult.isEmpty || authorResult.first.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.AUTHOR_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final row = authorResult.first;
      final author = Author(
        id: row[0]! as int,
        name: row[1]! as String,
        description: row[2]! as String,
        avatarUrl: row[3] as String?,
        followingCount: row[4]! as int,
        createdAt: _parseDate(row[5]),
        updatedAt: _parseDate(row[6]),
      );

      final albumResult = await _db.executor.execute(
        Sql.named('''
        SELECT al.id, al.albumTitle, al.description, al.linkUrlImageAlbum,
               al.createdAt, al.updatedAt, al.nation, al.listenCountAlbum
        FROM album al
        JOIN album_author ala ON al.id = ala.albumId
        WHERE ala.authorId = @id
      '''),
        parameters: {'id': author.id},
      );

      author.albums = albumResult.map((albumRow) {
        return Album(
          id: albumRow[0]! as int,
          albumTitle: albumRow[1]! as String,
          description: albumRow[2]! as String,
          linkUrlImageAlbum: albumRow[3]! as String,
          createdAt: _parseDate(albumRow[4]),
          updatedAt: _parseDate(albumRow[5]),
          nation: albumRow[6] as String? ?? '',
          listenCountAlbum: albumRow[7]! as int,
        );
      }).toList();

      final musicResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic, 
               m.createdAt, m.updatedAt, m.imageUrl, m.nation, m.listenCount
        FROM music m
        JOIN music_author ma ON m.id = ma.musicId
        WHERE ma.authorId = @id
      '''),
        parameters: {'id': author.id},
      );

      author.musics = musicResult.map((musicRow) {
        return Music(
          id: musicRow[0]! as int,
          title: musicRow[1]! as String,
          description: musicRow[2]! as String,
          broadcastTime: musicRow[3]! as int,
          linkUrlMusic: musicRow[4]! as String,
          createdAt: _parseDate(musicRow[5]),
          updatedAt: _parseDate(musicRow[6]),
          imageUrl: musicRow[7]! as String,
          nation: musicRow[8] as String? ?? '',
          listenCount: musicRow[9]! as int,
        );
      }).toList();

      return author;
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
  Future<List<Author>> showAuthorPaging({int offset = 0, int limit = 8}) async {
    try {
      final authorResult = await _db.executor.execute(Sql.named('''
SELECT id, name,avatarUrl
FROM author
ORDER BY RANDOM()
LIMIT @limit
OFFSET @offset
'''), parameters: {
        'limit': limit,
        'offset': offset,
      },);

      if (authorResult.isEmpty) {
        return [];
      }
      final authors = <Author>[];

      for (final row in authorResult) {
        final author = Author(
          id: row[0]! as int,
          name: row[1]! as String,
          avatarUrl: row[2]! as String,
        );

        authors.add(author);
      }
      return authors;
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
  Future<int?> createAuthor(Author author, String avatarPath) async {
    try {
      final avatarUrl =
          await _uploadAvatarAuthorService.uploadAvatarAuthor(avatarPath);
      final result = await _db.executor.execute(
        Sql.named('''
        INSERT INTO author (name, description, avatarUrl, followingCount, createdAt, updatedAt)
        VALUES (@name, @description, @avatarUrl, @followingCount, @createdAt, @updatedAt)
        RETURNING id
      '''),
        parameters: {
          'name': author.name,
          'description': author.description,
          'avatarUrl': avatarUrl,
          'followingCount': author.followingCount,
          'createdAt': now,
          'updatedAt': now,
        },
      );
      if (result.isEmpty || result.first.isEmpty) {
        throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR,
          HttpStatus.internalServerError,
        );
      }
      final authorId = result.first[0]! as int;
      return authorId;
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
