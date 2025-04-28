abstract class IRedisService {
  Future<int?> getTokenVersion(int userId);
  Future<void> invalidateToken(int userId);

  Future<void> setPlayMusicHistory(int userId, String musicId);
  Future<List<String>> getPlayMusicHistory(int userId);

  Future<void> playNextMusic(int userId, String nextMusicId);
  Future<String?> rewindMusic(int userId, int currentMusicId);
  Future<void> deleteHistory(int userId);
}
