// lib/interfaces/playlist/image_generator_interface.dart

import '../../../model/music.dart';

/// Interface cho service tạo ảnh playlist
abstract class IPlaylistImageGenerator {
  /// Tạo và tải lên ảnh bìa playlist dựa trên danh sách bài hát
  ///
  /// [musicList] Danh sách bài hát trong playlist
  /// Trả về URL của ảnh bìa playlist đã tải lên
  Future<String> generatePlaylistImage(List<Music> musicList);
}
