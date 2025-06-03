import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';

abstract class ISearchRepo {
  Future<Map<String, dynamic>> search(String query);
}

class SearchRepository implements ISearchRepo {

  SearchRepository(this._db);
  final Database _db;
  @override
  Future<Map<String, dynamic>> search(String query) async {
    try {
      final sql = Sql.named('''
     SELECT 
  m.id, 
  m.title, 
  m.description, 
  m.broadcastTime, 
  m.linkUrlMusic,
  m.createdAt, 
  m.updatedAt, 
  m.imageUrl, 
  m.listenCount, 
  m.nation,
  a.id, 
  a.name, 
  a.description,
  a.avatarUrl,
  c.id, 
  c.name, 
  c.description,
  c.imageUrl,
  al.id, 
  al.albumTitle, 
  al.linkUrlImageAlbum
FROM music m
LEFT JOIN music_author ma ON m.id = ma.musicId
LEFT JOIN author a ON ma.authorId = a.id
LEFT JOIN music_category mc ON m.id = mc.musicId
LEFT JOIN category c ON mc.categoryId = c.id
LEFT JOIN album al ON m.albumId = al.id 
WHERE 
  m.title ILIKE @query OR
  a.name ILIKE @query OR
  c.name ILIKE @query OR
  al.albumTitle ILIKE @query
ORDER BY m.title
LIMIT 50
      ''');

      final result = await _db.executor.execute(
        sql,
        parameters: {
          'query': '%$query%',
        },
      );

      if (result.isEmpty) {
        throw const CustomHttpException(
          ErrorMessage.MUSIC_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final searchResults = <Map<String, dynamic>>[];
      for (var i = 0; i < result.length; i++) {
        final row = result[i];

        searchResults.add({
          'music': {
            'id': row[0]! as int,
            'title': row[1]! as String,
            'description': row[2]! as String,
            'broadcastTime': row[3]! as int,
            'linkUrlMusic': row[4]! as String,
            'createdAt': _parseDate(row[5])?.toIso8601String(),
            'updatedAt': _parseDate(row[6])?.toIso8601String(),
            'imageUrl': row[7]! as String,
            'listenCount': row[8]! as int,
            'nation': row[9] as String? ?? '',
          },
          'author': {
            'id': row[10]! as int,
            'name': row[11]! as String,
            'description': row[12]! as String,
            'avatarUrl': row[13] as String? ?? '',
          },
          'category': {
            'id': row[14]! as int,
            'name': row[15]! as String,
            'description': row[16]! as String,
            'imageUrl': row[17] as String? ?? '',
          },
          'album': {
            'id': row[18] as int? ?? 0,
            'albumTitle': row[19] as String? ?? '',
            'linkUrlImageAlbum': row[20] as String? ?? '',
          },
        });
      }

      return {'results': searchResults};
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
    if (date == null) return null;
    return DateTime.tryParse(date.toString());
  }
}
