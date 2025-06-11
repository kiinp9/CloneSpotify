

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../../../constant/config.message.dart';
import '../../../exception/config.exception.dart';
import '../../../model/music.dart';
import '../../../ultis/file/interface/file.interface.dart';

import '../interface/generate_image_playlist_interface.dart';


class PlaylistImageGeneratorService implements IPlaylistImageGenerator { 

  PlaylistImageGeneratorService({
    required IFileService fileService,
  }) : _fileService = fileService;
  final IFileService _fileService;

  static const int _requiredImagesCount = 4;
  static const int _imageSize = 300;
  static const int _gridItemSize = 150;

  @override
  Future<String> generatePlaylistImage(List<Music> musicList) async {
    try {
      if (musicList.length < _requiredImagesCount) {
        return await _generateBlankImage();
      } else {
        return await _handleMultipleTracks(musicList);
      }
    } catch (e) {
      throw const CustomHttpException(
          ErrorMessage.GENERATE_IMAGE_PLAYLIST_FAILED,
          HttpStatus.internalServerError,);
    }
  }

  /// Xử lý trường hợp playlist có 4 bài hát trở lên
  Future<String> _handleMultipleTracks(List<Music> musicList) async {
    final imageUrls = _extractValidImageUrls(musicList);

    if (imageUrls.isEmpty) {
      return _generateBlankImage();
    } else if (imageUrls.length < _requiredImagesCount) {
      // Trả về đường dẫn tạm chứa ảnh đã tải về từ URL đầu tiên
      final tempDir = Directory.systemTemp;
      final imagePath = path.join(tempDir.path, 'single_track_image.jpg');
      await _downloadImage(imageUrls.first, imagePath);
      return imagePath;
    }

    return _combineImages(imageUrls.take(_requiredImagesCount).toList());
  }

  /// Trích xuất các URL ảnh hợp lệ từ danh sách bài hát
  List<String> _extractValidImageUrls(List<Music> musicList) {
    return musicList
        .take(_requiredImagesCount)
        .map((music) => music.imageUrl)
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Tạo ảnh trắng cho playlist rỗng và trả về đường dẫn file
  Future<String> _generateBlankImage() async {
    final tempDir = Directory.systemTemp;
    final blankImagePath = path.join(tempDir.path, 'blank_playlist_cover.png');

    await _fileService.createBlankImage(
        path: blankImagePath, width: _imageSize, height: _imageSize,);

    return blankImagePath;
  }

  /// Tải xuống, kết hợp các hình ảnh dưới dạng lưới 2x2 và trả về đường dẫn
  Future<String> _combineImages(List<String> imageUrls) async {
    try {
      final tempDir = Directory.systemTemp;
      final downloadedImagePaths = <String>[];

      // Tải từng ảnh về file tạm
      for (var i = 0; i < imageUrls.length; i++) {
        final imagePath = path.join(tempDir.path, 'track_image_$i.jpg');
        await _downloadImage(imageUrls[i], imagePath);
        downloadedImagePaths.add(imagePath);
      }

      // Tạo ảnh đã kết hợp
      final combinedImagePath =
          await _createCombinedImage(downloadedImagePaths);

      // Dọn dẹp các file tạm (giữ lại file ảnh kết hợp)
      await _cleanupTempFiles(downloadedImagePaths);

      return combinedImagePath;
    } catch (e) {
      throw const CustomHttpException(
          ErrorMessage.GENERATE_IMAGE_PLAYLIST_FAILED,
          HttpStatus.internalServerError,);
    }
  }

  /// Tải ảnh từ URL về file local
  Future<void> _downloadImage(String url, String targetPath) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw const CustomHttpException(
            ErrorMessage.DOWNLOAD_IMAGE_FAILED, HttpStatus.badRequest,);
      }

      final bytes = await _consolidateHttpClientResponseBytes(response);
      await _fileService.writeBytes(targetPath, bytes);
    } finally {
      client.close();
    }
  }

  /// Đọc toàn bộ dữ liệu từ HttpClientResponse
  Future<Uint8List> _consolidateHttpClientResponseBytes(
      HttpClientResponse response,) async {
    final chunks = <List<int>>[];
    var contentLength = 0;

    await for (final chunk in response) {
      chunks.add(chunk);
      contentLength += chunk.length;
    }

    if (chunks.isEmpty) {
      return Uint8List(0);
    }

    final bytes = Uint8List(contentLength);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    return bytes;
  }

  /// Tạo ảnh lưới 2x2 từ các đường dẫn ảnh đã cung cấp
  Future<String> _createCombinedImage(List<String> imagePaths) async {
    final tempDir = Directory.systemTemp;
    final outputPath = path.join(tempDir.path, 'combined_playlist_cover.png');

    // Tải tất cả ảnh
    final images = <img.Image>[];
    for (final path in imagePaths) {
      final imageBytes = await _fileService.readBytes(path);
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        // Thay đổi kích thước mỗi ảnh thành một nửa kích thước cuối cùng
        images.add(img.copyResize(decodedImage,
            width: _gridItemSize, height: _gridItemSize,),);
      }
    }

    // Tạo ảnh kết hợp
    final combinedImage = img.Image(width: _imageSize, height: _imageSize);

    // Đặt ảnh vào lưới 2x2
    final positions = [
      [0, 0],
      [_gridItemSize, 0],
      [0, _gridItemSize],
      [_gridItemSize, _gridItemSize],
    ];

    for (var i = 0; i < images.length && i < positions.length; i++) {
      img.compositeImage(combinedImage, images[i],
          dstX: positions[i][0], dstY: positions[i][1],);
    }

    // Lưu ảnh kết hợp
    await _fileService.writeBytes(outputPath, img.encodePng(combinedImage));

    return outputPath;
  }

  /// Xóa các file tạm
  Future<void> _cleanupTempFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      await _fileService.deleteFile(path);
    }
  }
}
