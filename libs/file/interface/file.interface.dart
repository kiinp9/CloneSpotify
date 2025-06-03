// lib/interfaces/common/file_service_interface.dart

import 'dart:typed_data';

/// Interface cho các thao tác với file
abstract class IFileService {
  /// Đọc bytes từ file
  ///
  /// [path] Đường dẫn tới file
  /// Trả về nội dung file dưới dạng bytes
  Future<Uint8List> readBytes(String path);

  /// Ghi bytes vào file
  ///
  /// [path] Đường dẫn nơi file sẽ được tạo
  /// [bytes] Bytes cần ghi
  Future<void> writeBytes(String path, Uint8List bytes);

  /// Xóa file
  ///
  /// [path] Đường dẫn tới file cần xóa
  Future<void> deleteFile(String path);

  /// Tạo ảnh trắng với kích thước chỉ định
  ///
  /// [path] Đường dẫn nơi ảnh sẽ được tạo
  /// [width] Chiều rộng của ảnh
  /// [height] Chiều cao của ảnh
  /// [color] Màu sắc (mặc định là trắng)
  Future<void> createBlankImage(
      {required String path,
      required int width,
      required int height,
      int color = 0xFFFFFFFF,});
}
