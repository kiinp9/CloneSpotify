import '../model/like_music.dart';
import '../repository/like_music_repository.dart';

class LikeMusicController {
  LikeMusicController(this._likeMusicRepository);
  final LikeMusicRepository _likeMusicRepository;

  Future<LikeMusic?> addMusicToLikeMusic(int userId, int musicId) async {
    final result =
        await _likeMusicRepository.addMusicToLikeMusic(userId, musicId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMusicFromLikeMusic(int userId) async {
    final result = await _likeMusicRepository.getMusicFromLikeMusic(userId);
    return result;
  }

  Future<LikeMusic> deleteMusicFromLikeMusic(int userId, int musicId) async {
    final result =
        await _likeMusicRepository.deleteMusicFromLikeMusic(userId, musicId);
    return result;
  }
}
