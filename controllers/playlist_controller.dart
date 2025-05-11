import '../model/playlist.dart';
import '../repository/playlist_repository.dart';

class PlaylistController {
  final PlaylistRepository _playlistRepository;

  PlaylistController(this._playlistRepository);

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
      int userId, int playlistId, int musicId) async {
    final result = await _playlistRepository.deleteMusicFromPlaylist(
        userId, playlistId, musicId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMusicByPlaylistId(
      int userId, int playlistId) async {
    final result =
        await _playlistRepository.getMusicByPlaylistId(userId, playlistId);
    return result;
  }

  Future<List<Playlist>> getPlaylistByUserId(int userId) async {
    final result = await _playlistRepository.getPlaylistByUserId(userId);
    return result;
  }

  Future<Playlist> updatePlaylist(
      int userId, int playlistId, Map<String, dynamic> updateFields) async {
    final result = await _playlistRepository.updatePlaylist(
        userId, playlistId, updateFields);
    return result;
  }

  Future<Playlist> deletePlaylist(int userId, int playlistId) async {
    final result = await _playlistRepository.deletePlaylist(userId, playlistId);
    return result;
  }
}
