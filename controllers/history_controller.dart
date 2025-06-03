import '../model/history.dart';
import '../model/history_album.dart';
import '../model/history_author.dart';
import '../repository/history_repository.dart';

class HistoryController {
  HistoryController(this._historyRepository);
  final HistoryRepository _historyRepository;

  Future<History> addMusicToHistory(int userId, int musicId) async {
    final result = await _historyRepository.addMusicToHistory(userId, musicId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMusicByHistory(
    int userId, {
    int offset = 0,
    int limit = 8,
  }) async {
    final result = await _historyRepository.getMusicByHistory(
      userId,
      offset: offset,
      limit: limit,
    );
    return result;
  }

  Future<HistoryAuthor> addAuthorToHistoryAuthor(
      int userId, int authorId,) async {
    final result =
        await _historyRepository.addAuthorToHistoryAuthor(userId, authorId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAuthorByHistoryAuthor(
    int userId, {
    int offset = 0,
    int limit = 8,
  }) async {
    final result = await _historyRepository.getAuthorByHistoryAuthor(
      userId,
      offset: offset,
      limit: limit,
    );
    return result;
  }

  Future<HistoryAlbum?> createHistoryAlbum(
    int userId,
    int? albumId,
    int musicId,
  ) async {
    final result =
        _historyRepository.createHistoryAlbum(userId, albumId, musicId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAlbumByHistoryAlbum(
    int userId, {
    int offset = 0,
    int limit = 8,
  }) async {
    final result = await _historyRepository.getAlbumByHistoryAlbum(
      userId,
      offset: offset,
      limit: limit,
    );
    return result;
  }
}
