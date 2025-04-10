import 'dart:io';

import '../constant/config.message.dart';
import '../exception/config.exception.dart';
import '../model/album.dart';
import '../model/author.dart';
import '../model/music.dart';
import '../repository/album_repository.dart';
import '../model/category.dart';
import '../validate/strings.dart';

class AlbumController {
  AlbumController(this._albumRepository);
  final AlbumRepository _albumRepository;

  Future<int> uploadAlbum(
      Album album,
      String albumFolderPath,
      String avatarPath,
      List<Music> music,
      Author author,
      List<Category> categories) async {
    try {
      if (isNullOrEmpty(album.albumTitle)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_ALBUM_TITLE, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(albumFolderPath)) {
        throw CustomHttpException(
            ErrorMessage.INVALID_ALBUM_FOLDER, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(author.name)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_AUTHOR_NAME, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(author.description)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_AUTHOR_DESC, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(author.avatarUrl)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_AUTHOR_AVATAR, HttpStatus.badRequest);
      }
      for (final category in categories) {
        if (isNullOrEmpty(category.name)) {
          throw CustomHttpException(
              ErrorMessage.EMPTY_CATEGORY_NAME, HttpStatus.badRequest);
        }
        if (isNullOrEmpty(category.description)) {
          throw CustomHttpException(
              ErrorMessage.EMPTY_CATEGORY_DESCRIPTION, HttpStatus.badRequest);
        }
      }

      final int? albumId = await _albumRepository.uploadAlbum(
          album, albumFolderPath, avatarPath, music, author, categories);

      if (albumId == null) {
        throw const CustomHttpException(
            ErrorMessage.SAVED_DB_FAIL, HttpStatus.internalServerError);
      }

      return albumId;
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }
      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }
  }

  Future<Album?> findAlbumById(int id) async {
    final album = await _albumRepository.findAlbumById(id);
    return album;
  }
}
