import '../constant/config.message.dart';
import '../database/iredis.dart';
import '../exception/config.exception.dart';
import '../model/author.dart';
import '../model/category.dart';
import '../model/music.dart';
import '../repository/music_repository.dart';
import 'dart:async';
import 'dart:io';

import '../validate/strings.dart';

class MusicController {
  MusicController(this._musicRepository, this._redisService);

  final MusicRepository _musicRepository;
  final IRedisService _redisService;

  Future<int> uploadMusic(
    Music music,
    String musicFilePath,
    String imageFilePath,
    Author author,
    List<Category> categories,
  ) async {
    try {
      if (isNullOrEmpty(music.title)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_TITLE, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(music.description)) {
        throw CustomHttpException(
            ErrorMessage.EMPTY_DESCRIPTION, HttpStatus.badRequest);
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
      if (isNullOrEmpty(musicFilePath)) {
        throw CustomHttpException(
            ErrorMessage.INVALID_MUSIC_PATH, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(imageFilePath)) {
        throw CustomHttpException(
            ErrorMessage.INVALID_IMAGE_PATH, HttpStatus.badRequest);
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

      // Thực hiện upload nhạc và hình ảnh
      final int? musicId = await _musicRepository.uploadMusic(
        music,
        musicFilePath,
        imageFilePath,
        author,
        categories,
      );

      if (musicId == null) {
        throw const CustomHttpException(
            ErrorMessage.SAVED_DB_FAIL, HttpStatus.internalServerError);
      }

      return musicId;
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }
      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }
  }

  Future<Music?> findMusicById(int id) async {
    final music = await _musicRepository.findMusicById(id);

    return music;
  }

  Future<Music?> findMusicByTitle(String title) async {
    final music = await _musicRepository.findMusicByTitle(title);
    return music;
  }

  Future<List<Music>> showMusicPaging({int offset = 0, int limit = 10}) async {
    return await _musicRepository.showMusicPaging(offset: offset, limit: limit);
  }

  Future<List<Music>> showMusicByCategory(int categoryId) async {
    return await _musicRepository.showMusicByCategory(categoryId);
  }

  Future<Music?> nextMusic(int currentMusicId) async {
    final music = await _musicRepository.nextMusic(currentMusicId);
    return music;
  }

  Future<void> incrementListenCount(int musicId) async {
    final music = await _musicRepository.incrementListenCount(musicId);
    return music;
  }

  Future<void> setPlayMusicHistory(int userId, String musicId) async {
    final music = await _redisService.setPlayMusicHistory(userId, musicId);
    return music;
  }

  Future<List<String>> getPlayMusicHistory(int userId) async {
    final music = await _redisService.getPlayMusicHistory(userId);
    return music;
  }

  Future<void> playNextMusic(int userId, String nextMusicId) async {
    final music = await _redisService.playNextMusic(userId, nextMusicId);
    return music;
  }

  Future<String?> rewindMusicFromHistory(int userId, int currentMusicId) async {
    final music = await _redisService.rewindMusic(userId, currentMusicId);

    return music;
  }

  Future<Music> updateMusic(
      int musicId, Map<String, dynamic> updateFields) async {
    final music = await _musicRepository.updateMusic(musicId, updateFields);
    return music;
  }

  Future<Music> deleteMusic(int musicId) async {
    final music = await _musicRepository.deleteMusic(musicId);
    return music;
  }
}
