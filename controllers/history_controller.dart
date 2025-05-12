import '../model/history.dart';
import '../repository/history_repository.dart';

class HistoryController {
  HistoryController(this._historyRepository);
  final HistoryRepository _historyRepository;

  Future<History> addMusicToHistory(int userId, int musicId) async {
    final result = await _historyRepository.addMusicToHistory(userId, musicId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMusicByHistory(int userId) async {
    final result = await _historyRepository.getMusicByHistory(userId);
    return result;
  }
}
