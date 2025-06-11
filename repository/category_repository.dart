import 'dart:io';

import 'package:postgres/postgres.dart';

import '../constant/config.message.dart';
import '../database/postgres.dart';
import '../exception/config.exception.dart';
import '../ultis/cloudinary/service/upload-imageCategory.service.dart';
import '../model/category.dart';

abstract class ICategoryRepo {
  Future<int?> createCategory(Category category, String imagePath);
  Future<List<Category>> getAllCategory();
  Future<Category?> findCategoryById(int categoryId);
  Future<Category> updateCategory(
      int categoryId, Map<String, dynamic> updateFields,);

  Future<Category> deleteCategoryById(int categoryId);
}

class CategoryRepository implements ICategoryRepo {
  CategoryRepository(this._db)
      : _uploadImageCategoryService = UploadImageCategoryService();
  final Database _db;
  final UploadImageCategoryService _uploadImageCategoryService;
  final now = DateTime.now().toIso8601String();
  @override
  Future<int?> createCategory(Category category, String imagePath) async {
    try {
      final imageUrl =
          await _uploadImageCategoryService.uploadImageCategory(imagePath);

      final categoryResult = await _db.executor.execute(
        Sql.named('''
   INSERT INTO category (name, description, createdAt, updatedAt,imageUrl)
                VALUES (@name, @description, @createdAt, @updatedAt,@imageUrl)
                RETURNING id
'''),
        parameters: {
          'name': category.name,
          'description': category.description ?? '',
          'createdAt': now,
          'updatedAt': now,
          'imageUrl': imageUrl,
        },
      );
      if (categoryResult.isEmpty || categoryResult.first.isEmpty) {
        throw const CustomHttpException(
            ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError,);
      }

      final categoryId = categoryResult.first[0]! as int;

      return categoryId;
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
  Future<List<Category>> getAllCategory() async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''
    SELECT id, name, description, createdAt, updatedAt, imageUrl
        FROM category
'''),
      );

      if (result.isEmpty) {
        return [];
      }

      final categories = result.map((row) {
        return Category(
          id: row[0]! as int,
          name: row[1]! as String,
          description: row[2] as String?,
          createdAt: _parseDate(row[3]),
          updatedAt: _parseDate(row[4]),
          imageUrl: row[5] as String?,
        );
      }).toList();

      return categories;
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
  Future<Category?> findCategoryById(int categoryId) async {
    try {
      final result = await _db.executor.execute(
        Sql.named('''
SELECT id, name, description, createdAt, updatedAt, imageUrl
FROM category
WHERE id = @id
LIMIT 1
'''),
        parameters: {'id': categoryId},
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;

      DateTime? createdAt;
      if (row[3] != null) {
        createdAt = row[3] is DateTime
            ? row[3]! as DateTime
            : DateTime.tryParse(row[3].toString());
      }

      DateTime? updatedAt;
      if (row[4] != null) {
        updatedAt = row[4] is DateTime
            ? row[4]! as DateTime
            : DateTime.tryParse(row[4].toString());
      }

      final imageUrl = row[5] as String?;

      return Category(
        id: row[0]! as int,
        name: row[1]! as String,
        description: row[2] as String?,
        createdAt: createdAt,
        updatedAt: updatedAt,
        imageUrl: imageUrl,
      );
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
  Future<Category> updateCategory(
      int categoryId, Map<String, dynamic> updateFields,) async {
    try {
      final setClauseParts = <String>[];
      final parameters = <String, dynamic>{
        'id': categoryId,
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
      UPDATE category
      SET $setClause
      WHERE id = @id
      RETURNING id, name, description, createdAt, updatedAt, imageUrl
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

      return Category(
        id: row[0]! as int,
        name: row[1]! as String,
        description: row[2] as String?,
        createdAt: row[3] as DateTime?,
        updatedAt: row[4] as DateTime?,
        imageUrl: row[5] as String?,
      );
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
  Future<Category> deleteCategoryById(int categoryId) async {
    try {
      final category = await findCategoryById(categoryId);
      if (category == null) {
        throw const CustomHttpException(
          ErrorMessage.CATEGORY_NOT_FOUND,
          HttpStatus.notFound,
        );
      }

      final musicCategoryCheck = await _db.executor.execute(
        Sql.named(
            'SELECT 1 FROM music_category WHERE categoryId = @id LIMIT 1',),
        parameters: {'id': categoryId},
      );
      if (musicCategoryCheck.isNotEmpty) {
        throw const CustomHttpException(
          ErrorMessage.CANNOT_DELETE_CATEGORY_CASE_1,
          HttpStatus.conflict,
        );
      }

      final albumCategoryCheck = await _db.executor.execute(
        Sql.named(
            'SELECT 1 FROM album_category WHERE categoryId = @id LIMIT 1',),
        parameters: {'id': categoryId},
      );
      if (albumCategoryCheck.isNotEmpty) {
        throw const CustomHttpException(
          ErrorMessage.CANNOT_DELETE_CATEGORY_CASE_2,
          HttpStatus.conflict,
        );
      }

      await _db.executor.execute(
        Sql.named('DELETE FROM category WHERE id = @id'),
        parameters: {'id': categoryId},
      );

      return category;
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
