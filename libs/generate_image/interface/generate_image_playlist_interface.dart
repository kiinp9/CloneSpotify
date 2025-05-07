// lib/interfaces/playlist/image_generator_interface.dart

import '../../../model/music.dart';

/// Interface cho service tạo ảnh playlist
abstract class IPlaylistImageGenerator {
  /// Tạo và tải lên ảnh bìa playlist dựa trên danh sách bài hát
  ///
  /// [musicList] Danh sách bài hát trong playlist
  /// Trả về URL của ảnh bìa playlist đã tải lên
  Future<String> generateAndUploadPlaylistImage(List<Music> musicList);
}

// lib/interfaces/playlist/image_uploader_interface.dart

/// Interface cho service tải lên ảnh playlist
abstract class IImageUploader {
  /// Tải lên ảnh playlist vào dịch vụ lưu trữ
  ///
  /// [imagePath] Đường dẫn local tới file ảnh
  /// Trả về URL của ảnh đã tải lên
  Future<String> uploadPlaylistImage(String imagePath);
}
