import '../database/iredis.dart';
import '../model/music.dart';
import '../model/playlist.dart';
import '../repository/playlist_repository.dart';

class PlaylistController {

  PlaylistController(this._playlistRepository, this._redisService);
  final PlaylistRepository _playlistRepository;
  final IRedisService _redisService;

  Future<int?> createPlaylist(Playlist playlist) async {
    final result = await _playlistRepository.createPlaylist(playlist);
    return result;
  }

  Future<Playlist> addMusicToPlaylist(int playlistId, int musicId) async {
    final result =
        await _playlistRepository.addMusicToPlaylist(playlistId, musicId);
    return result;
  }

  Future<Playlist> deleteMusicFromPlaylist(
      int userId, int playlistId, int musicId,) async {
    final result = await _playlistRepository.deleteMusicFromPlaylist(
        userId, playlistId, musicId,);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMusicByPlaylistId(
      int userId, int playlistId,) async {
    final result =
        await _playlistRepository.getMusicByPlaylistId(userId, playlistId);
    return result;
  }

  Future<List<Playlist>> getPlaylistByUserId(int userId) async {
    final result = await _playlistRepository.getPlaylistByUserId(userId);
    return result;
  }

  Future<Playlist> updatePlaylist(
      int userId, int playlistId, Map<String, dynamic> updateFields,) async {
    final result = await _playlistRepository.updatePlaylist(
        userId, playlistId, updateFields,);
    return result;
  }

  Future<Playlist> deletePlaylist(int userId, int playlistId) async {
    final result = await _playlistRepository.deletePlaylist(userId, playlistId);
    return result;
  }

  Future<Music> playMusicInPlayList(
      int userId, int playlistId, int musicId,) async {
    final result = await _playlistRepository.playMusicInPlayList(
        userId, playlistId, musicId,);
    return result;
  }

  Future<Music?> nextMusic(
      int currentMusicId, int userId, int playlistId,) async {
    final result =
        await _playlistRepository.nextMusic(currentMusicId, userId, playlistId);
    return result;
  }

  Future<void> incrementListenCount(int musicId) async {
    final result = await _playlistRepository.incrementListenCount(musicId);
    return result;
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
}
