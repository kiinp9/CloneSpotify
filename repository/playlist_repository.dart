import 'dart:io';
import 'dart:async';
import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../exception/config.exception.dart';
import '../libs/cloudinary/service/upload-imagePlaylist.service.dart';
import '../libs/file/service/file.service.dart';
import '../libs/generate_image/interface/generate_image_playlist_interface.dart';
import '../libs/generate_image/service/generate_image_playlist.dart';
import '../model/music.dart';
import '../model/playlist.dart';
import '../database/postgres.dart';

abstract class IPlaylistRepo {
  Future<int?> createPlaylist(Playlist playlist);
  Future<Playlist> addMusicToPlaylist(int playlistId, int musicId);
  Future<Playlist> deleteMusicFromPlaylist(
      int userId, int playlistId, int musicId);
  Future<List<Map<String, dynamic>>> getMusicByPlaylistId(
      int userId, int playlistId);
  Future<List<Playlist>> getPlaylistByUserId(int userId);
  Future<Playlist> updatePlaylist(
      int userId, int playlistId, Map<String, dynamic> updateFields);
  Future<Playlist> deletePlaylist(int userId, int playlistId);
}

class PlaylistRepository implements IPlaylistRepo {
  final Database _db;
  final IPlaylistImageGenerator _playlistImageGenerator;
  final IUploadImagePlaylistService _imagePlaylistUploader;

  PlaylistRepository(this._db)
      : _playlistImageGenerator = PlaylistImageGeneratorService(
          fileService: FileService(),
        ),
        _imagePlaylistUploader = UploadImagePlaylistService();

  @override
  Future<int?> createPlaylist(Playlist playlist) async {
    try {
      final now = DateTime.now();

      final imagePath = await _playlistImageGenerator.generatePlaylistImage([]);

      final imageUrl =
          await _imagePlaylistUploader.uploadImagePlaylist(imagePath);

      if (imageUrl == null) {
        throw const CustomHttpException(
          ErrorMessage.UPLOAD_FAIL,
          HttpStatus.internalServerError,
        );
      }

      final playlistResult = await _db.executor.execute(
        Sql.named('''
          INSERT INTO playlist (userId, name, description, isPublic, imageUrl, createdAt, updatedAt)
          VALUES (@userId, @name, @description, @isPublic, @imageUrl, @createdAt, @updatedAt)
          RETURNING id
        '''),
        parameters: {
          'userId': playlist.userId,
          'name': playlist.name,
          'description': playlist.description ?? '',
          'isPublic': playlist.isPublic ?? false,
          'imageUrl': imageUrl,
          'createdAt': now,
          'updatedAt': now,
        },
      );

      if (playlistResult.isEmpty || playlistResult.first.isEmpty) {
        throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR,
          HttpStatus.internalServerError,
        );
      }

      final playlistId = playlistResult.first[0] as int;
      return playlistId;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<Playlist> addMusicToPlaylist(int playlistId, int musicId) async {
    try {
      final now = DateTime.now();
      final checkExist = await _db.executor.execute(
        Sql.named('''
    SELECT 1 FROM playlistItem 
    WHERE playlistId = @playlistId AND musicId = @musicId
    LIMIT 1
  '''),
        parameters: {
          'playlistId': playlistId,
          'musicId': musicId,
        },
      );

      if (checkExist.isNotEmpty) {
        throw const CustomHttpException(
          ErrorMessage.MUSIC_ALREADY_EXIST_IN_PLAYLIST,
          HttpStatus.conflict,
        );
      }

      final insertResult = await _db.executor.execute(
        Sql.named('''
        INSERT INTO playlistItem (playlistId, musicId, createdAt)
        VALUES (@playlistId, @musicId, @createdAt)
        RETURNING id
      '''),
        parameters: {
          'playlistId': playlistId,
          'musicId': musicId,
          'createdAt': now,
        },
      );

      if (insertResult.isEmpty) {
        throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR,
          HttpStatus.internalServerError,
        );
      }

      final musicListResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic,
               m.createdAt, m.updatedAt, m.imageUrl, m.listenCount, m.nation
        FROM playlistItem pi
        JOIN music m ON m.id = pi.musicId
        WHERE pi.playlistId = @playlistId
        ORDER BY pi.createdAt DESC
        LIMIT 4
      '''),
        parameters: {'playlistId': playlistId},
      );

      final musicList = musicListResult.map((row) {
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
          nation: row[9] as String? ?? '',
        );
      }).toList();

      if (musicList.length >= 4) {
        final imagePath =
            await _playlistImageGenerator.generatePlaylistImage(musicList);
        final imageUrl =
            await _imagePlaylistUploader.uploadImagePlaylist(imagePath);

        if (imageUrl == null) {
          throw const CustomHttpException(
            ErrorMessage.UPLOAD_FAIL,
            HttpStatus.internalServerError,
          );
        }

        await _db.executor.execute(
          Sql.named('''
          UPDATE playlist
          SET imageUrl = @imageUrl, updatedAt = @updatedAt
          WHERE id = @playlistId
        '''),
          parameters: {
            'imageUrl': imageUrl,
            'updatedAt': now,
            'playlistId': playlistId,
          },
        );
      }

      final playlistResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
        WHERE id = @playlistId
      '''),
        parameters: {'playlistId': playlistId},
      );

      if (playlistResult.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.PLAYLIST_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final row = playlistResult.first;
      return Playlist(
        id: row[0] as int,
        userId: row[1] as int,
        name: row[2] as String,
        description: row[3] as String?,
        isPublic: row[4] as bool,
        imageUrl: row[5] as String?,
        createdAt: _parseDate(row[6]),
        updatedAt: _parseDate(row[7]),
      );
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<Playlist> deleteMusicFromPlaylist(
      int userId, int playlistId, int musicId) async {
    try {
      final now = DateTime.now();
      final playlistCheck = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
    WHERE userId = @userId
      '''),
        parameters: {
          'userId': userId,
        },
      );

      if (playlistCheck.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.NO_PLAYLIST_FOUND,
          HttpStatus.forbidden,
        );
      }
      final playlistExist = await _db.executor.execute(
        Sql.named('SELECT * FROM playlist WHERE id = @playlistId'),
        parameters: {'playlistId': playlistId},
      );

      if (playlistExist.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.PLAYLIST_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

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

      await _db.executor.execute(
        Sql.named('''
        DELETE FROM playlistItem 
        WHERE playlistId = @playlistId AND musicId = @musicId
      '''),
        parameters: {
          'playlistId': playlistId,
          'musicId': musicId,
        },
      );

      final musicListResult = await _db.executor.execute(
        Sql.named('''
        SELECT m.id, m.title, m.description, m.broadcastTime, m.linkUrlMusic,
               m.createdAt, m.updatedAt, m.imageUrl, m.listenCount, m.nation
        FROM playlistItem pi
        JOIN music m ON m.id = pi.musicId
        WHERE pi.playlistId = @playlistId
        ORDER BY pi.createdAt DESC
      '''),
        parameters: {'playlistId': playlistId},
      );

      final musicList = musicListResult.map((row) {
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
          nation: row[9] as String? ?? '',
        );
      }).toList();

      if (musicList.length < 4) {
        final imagePath =
            await _playlistImageGenerator.generatePlaylistImage([]);
        final imageUrl =
            await _imagePlaylistUploader.uploadImagePlaylist(imagePath);

        if (imageUrl == null) {
          throw const CustomHttpException(
            ErrorMessage.UPLOAD_FAIL,
            HttpStatus.internalServerError,
          );
        }

        await _db.executor.execute(
          Sql.named('''
          UPDATE playlist
          SET imageUrl = @imageUrl, updatedAt = @updatedAt
          WHERE id = @playlistId
        '''),
          parameters: {
            'imageUrl': imageUrl,
            'updatedAt': now,
            'playlistId': playlistId,
          },
        );
      }

      final playlistResult = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
        WHERE id = @playlistId
      '''),
        parameters: {'playlistId': playlistId},
      );

      if (playlistResult.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.PLAYLIST_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final row = playlistResult.first;
      return Playlist(
        id: row[0] as int,
        userId: row[1] as int,
        name: row[2] as String,
        description: row[3] as String?,
        isPublic: row[4] as bool,
        imageUrl: row[5] as String?,
        createdAt: _parseDate(row[6]),
        updatedAt: _parseDate(row[7]),
      );
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMusicByPlaylistId(
    int userId,
    int playlistId,
  ) async {
    try {
      final playlistCheck = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
    WHERE userId = @userId
      '''),
        parameters: {
          'userId': userId,
        },
      );

      if (playlistCheck.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.NO_PLAYLIST_FOUND,
          HttpStatus.forbidden,
        );
      }
      final playlistExist = await _db.executor.execute(
        Sql.named('SELECT * FROM playlist WHERE id = @playlistId'),
        parameters: {'playlistId': playlistId},
      );

      if (playlistExist.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.PLAYLIST_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final result = await _db.executor.execute(
        Sql.named('''
        SELECT 
          m.id AS musicId,
          m.title AS musicTitle,
          a.name AS authorName
        FROM playlistItem pi
        JOIN music m ON pi.musicId = m.id
        JOIN music_author ma ON m.id = ma.musicId
        JOIN author a ON ma.authorId = a.id
        WHERE pi.playlistId = @playlistId
      '''),
        parameters: {'playlistId': playlistId},
      );

      if (result.isEmpty) {
        throw CustomHttpException(
          ErrorMessage.PLAYLIST_IS_EMPTY,
          HttpStatus.ok,
        );
      }

      final Map<int, Map<String, dynamic>> grouped = {};
      for (var row in result) {
        final musicId = row[0] as int;
        final title = row[1] as String;
        final authorName = row[2] as String;

        grouped.putIfAbsent(
          musicId,
          () => {
            'title': title,
            'authors': <String>[],
          },
        );
        (grouped[musicId]!['authors'] as List<String>).add(authorName);
      }

      return grouped.values
          .map((entry) => {
                'title': entry['title'],
                'authors': (entry['authors'] as List<String>).join(', ')
              })
          .toList();
    } catch (e) {
      if (e is CustomHttpException) rethrow;
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  @override
  Future<List<Playlist>> getPlaylistByUserId(int userId) async {
    try {
      final user = await _db.executor.execute(
        Sql.named('''
        SELECT * FROM users
        WHERE id = @userId
      '''),
        parameters: {'userId': userId},
      );

      if (user.isEmpty) {
        throw CustomHttpException(
          ErrorMessage.USER_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final result = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
        WHERE userId = @userId
      '''),
        parameters: {'userId': userId},
      );

      if (result.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.NO_PLAYLIST_FOUND,
          HttpStatus.ok,
        );
      }

      final playlists = result.map((row) {
        return Playlist(
          id: row[0] as int,
          userId: row[1] as int,
          name: row[2] as String,
          description: row[3] as String?,
          isPublic: row[4] as bool,
          imageUrl: row[5] as String?,
          createdAt: row[6] as DateTime?,
          updatedAt: row[7] as DateTime?,
        );
      }).toList();

      return playlists;
    } catch (e) {
      if (e is CustomHttpException) rethrow;

      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  Future<Playlist> updatePlaylist(
      int userId, int playlistId, Map<String, dynamic> updateFields) async {
    try {
      final playlistCheck = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
    WHERE userId = @userId
      '''),
        parameters: {
          'userId': userId,
        },
      );

      if (playlistCheck.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.NO_PLAYLIST_FOUND,
          HttpStatus.forbidden,
        );
      }
      final playlistExist = await _db.executor.execute(
        Sql.named('SELECT * FROM playlist WHERE id = @playlistId'),
        parameters: {'playlistId': playlistId},
      );

      if (playlistExist.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.PLAYLIST_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final setClauseParts = <String>[];
      final parameters = <String, dynamic>{
        'playlistId': playlistId,
        'updatedAt': DateTime.now(),
      };

      if (updateFields.containsKey('name')) {
        setClauseParts.add('name = @name');
        parameters['name'] = updateFields['name'];
      }

      if (updateFields.containsKey('description')) {
        setClauseParts.add('description = @description');
        parameters['description'] = updateFields['description'];
      }

      setClauseParts.add('updatedAt = @updatedAt');
      final setClause = setClauseParts.join(', ');

      final query = '''
UPDATE playlist
SET $setClause
WHERE id = @playlistId
RETURNING id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
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

      return Playlist(
        id: row[0] as int,
        userId: row[1] as int,
        name: row[2] as String,
        description: row[3] as String?,
        isPublic: row[4] as bool,
        imageUrl: row[5] as String?,
        createdAt: row[6] as DateTime?,
        updatedAt: row[7] as DateTime?,
      );
    } catch (e) {
      if (e is CustomHttpException) rethrow;
      throw CustomHttpException(
        ErrorMessageSQL.SQL_QUERY_ERROR,
        HttpStatus.internalServerError,
      );
    }
  }

  Future<Playlist> deletePlaylist(int userId, int playlistId) async {
    try {
      final playlistCheck = await _db.executor.execute(
        Sql.named('''
        SELECT id, userId, name, description, isPublic, imageUrl, createdAt, updatedAt
        FROM playlist
    WHERE userId = @userId
      '''),
        parameters: {
          'userId': userId,
        },
      );

      if (playlistCheck.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.NO_PLAYLIST_FOUND,
          HttpStatus.forbidden,
        );
      }
      final playlistExist = await _db.executor.execute(
        Sql.named('SELECT * FROM playlist WHERE id = @playlistId'),
        parameters: {'playlistId': playlistId},
      );

      if (playlistExist.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.PLAYLIST_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final row = playlistCheck.first;
      final deletedPlaylist = Playlist(
        id: row[0] as int,
        userId: row[1] as int,
        name: row[2] as String,
        description: row[3] as String?,
        isPublic: row[4] as bool,
        imageUrl: row[5] as String?,
        createdAt: row[6] as DateTime?,
        updatedAt: row[7] as DateTime?,
      );

      await _db.executor.execute(
        Sql.named('DELETE FROM playlistItem WHERE playlistId = @playlistId'),
        parameters: {'playlistId': playlistId},
      );

      await _db.executor.execute(
        Sql.named('DELETE FROM playlist WHERE id = @playlistId'),
        parameters: {'playlistId': playlistId},
      );

      return deletedPlaylist;
    } catch (e) {
      if (e is CustomHttpException) rethrow;
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
