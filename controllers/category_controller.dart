import 'dart:io';

import '../constant/config.message.dart';
import '../exception/config.exception.dart';
import '../model/category.dart';
import '../repository/category_repository.dart';
import '../validate/strings.dart';

class CategoryController {
  CategoryController(this._categoryRepository);
  final CategoryRepository _categoryRepository;

  Future<int?> createCategory(Category category, String imagePath) async {
    try {
      if (isNullOrEmpty(category.name)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_CATEGORY_NAME, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(category.description)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_CATEGORY_DESCRIPTION, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(category.imageUrl)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_CATEGORY_IMAGE_PATH, HttpStatus.badRequest);
      }

      final int? categoryId =
          await _categoryRepository.createCategory(category, imagePath);
      if (categoryId == null) {
        throw const CustomHttpException(
            ErrorMessage.SAVED_DB_FAIL, HttpStatus.internalServerError);
      }
      return categoryId;
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }
      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }
  }

  Future<List<Category>> getAllCategory() async {
    final result = await _categoryRepository.getAllCategory();
    return result;
  }

  Future<Category> updateCategory(
      int categoryId, Map<String, dynamic> updateFields) async {
    final result =
        await _categoryRepository.updateCategory(categoryId, updateFields);
    return result;
  }

  Future<Category?> findCategoryById(int categoryId) async {
    final result = await _categoryRepository.findCategoryById(categoryId);
    return result;
  }

  Future<Category?> deleteCategoryById(int categoryId) async {
    final result = await _categoryRepository.deleteCategoryById(categoryId);
    return result;
  }
}
