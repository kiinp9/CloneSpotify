// lib/services/playlist/playlist_image_generator_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../../../constant/config.message.dart';
import '../../../exception/config.exception.dart';
import '../../../model/music.dart';
import '../../file/interface/file.interface.dart';

import '../interface/generate_image_playlist_interface.dart';

/// Service chịu trách nhiệm tạo ảnh đại diện cho playlist
class PlaylistImageGeneratorService implements IPlaylistImageGenerator {
  final IImageUploader _imageUploader;
  final IFileService _fileService;

  static const int _requiredImagesCount = 4;
  static const int _imageSize = 300;
  static const int _gridItemSize = 150; // Một nửa kích thước ảnh cuối cùng

  PlaylistImageGeneratorService({
    required IImageUploader imageUploader,
    required IFileService fileService,
  })  : _imageUploader = imageUploader,
        _fileService = fileService;

  @override
  Future<String> generateAndUploadPlaylistImage(List<Music> musicList) async {
    try {
      if (musicList.isEmpty) {
        return await _handleEmptyPlaylist();
      } else if (musicList.length < _requiredImagesCount) {
        return await _handleFewTracks(musicList);
      } else {
        return await _handleMultipleTracks(musicList);
      }
    } catch (e) {
      throw const CustomHttpException(
          ErrorMessage.GENERATE_IMAGE_PLAYLIST_FAILED,
          HttpStatus.internalServerError);
    }
  }

  /// Xử lý trường hợp playlist rỗng
  Future<String> _handleEmptyPlaylist() async {
    return await _generateAndUploadBlankImage();
  }

  /// Xử lý trường hợp playlist có ít hơn 4 bài hát
  Future<String> _handleFewTracks(List<Music> musicList) async {
    final firstTrackImageUrl = musicList.first.imageUrl;

    if (firstTrackImageUrl == null || firstTrackImageUrl.isEmpty) {
      return await _generateAndUploadBlankImage();
    }

    return firstTrackImageUrl;
  }

  /// Xử lý trường hợp playlist có 4 bài hát trở lên
  Future<String> _handleMultipleTracks(List<Music> musicList) async {
    final imageUrls = _extractValidImageUrls(musicList);

    if (imageUrls.isEmpty) {
      return await _generateAndUploadBlankImage();
    } else if (imageUrls.length < _requiredImagesCount) {
      return imageUrls.first;
    }

    return await _combineAndUploadImages(
        imageUrls.take(_requiredImagesCount).toList());
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

  /// Tạo ảnh trắng cho playlist rỗng
  Future<String> _generateAndUploadBlankImage() async {
    final tempDir = Directory.systemTemp;
    final blankImagePath = path.join(tempDir.path, 'blank_playlist_cover.png');

    await _fileService.createBlankImage(
        path: blankImagePath, width: _imageSize, height: _imageSize);

    final imageUrl = await _imageUploader.uploadPlaylistImage(blankImagePath);

    await _fileService.deleteFile(blankImagePath);

    return imageUrl;
  }

  /// Tải xuống, kết hợp và tải lên các hình ảnh dưới dạng lưới 2x2
  Future<String> _combineAndUploadImages(List<String> imageUrls) async {
    try {
      final tempDir = Directory.systemTemp;
      final List<String> downloadedImagePaths = [];

      // Tải từng ảnh về file tạm
      for (int i = 0; i < imageUrls.length; i++) {
        final imagePath = path.join(tempDir.path, 'track_image_$i.jpg');
        await _downloadImage(imageUrls[i], imagePath);
        downloadedImagePaths.add(imagePath);
      }

      // Tạo và tải lên ảnh đã kết hợp
      final combinedImagePath =
          await _createCombinedImage(downloadedImagePaths);
      final uploadedImageUrl =
          await _imageUploader.uploadPlaylistImage(combinedImagePath);

      // Dọn dẹp các file tạm
      await _cleanupTempFiles([...downloadedImagePaths, combinedImagePath]);

      return uploadedImageUrl;
    } catch (e) {
      throw const CustomHttpException(
          ErrorMessage.GENERATE_IMAGE_PLAYLIST_FAILED,
          HttpStatus.internalServerError);
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
            ErrorMessage.DOWNLOAD_IMAGE_FAILED, HttpStatus.badRequest);
      }

      final bytes = await _consolidateHttpClientResponseBytes(response);
      await _fileService.writeBytes(targetPath, bytes);
    } finally {
      client.close();
    }
  }

  /// Đọc toàn bộ dữ liệu từ HttpClientResponse
  Future<Uint8List> _consolidateHttpClientResponseBytes(
      HttpClientResponse response) async {
    final List<List<int>> chunks = [];
    int contentLength = 0;

    await for (final chunk in response) {
      chunks.add(chunk);
      contentLength += chunk.length;
    }

    if (chunks.isEmpty) {
      return Uint8List(0);
    }

    final Uint8List bytes = Uint8List(contentLength);
    int offset = 0;
    for (final List<int> chunk in chunks) {
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
    final List<img.Image> images = [];
    for (final path in imagePaths) {
      final imageBytes = await _fileService.readBytes(path);
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        // Thay đổi kích thước mỗi ảnh thành một nửa kích thước cuối cùng
        images.add(img.copyResize(decodedImage,
            width: _gridItemSize, height: _gridItemSize));
      }
    }

    // Tạo ảnh kết hợp
    final combinedImage = img.Image(width: _imageSize, height: _imageSize);

    // Đặt ảnh vào lưới 2x2
    final positions = [
      [0, 0],
      [_gridItemSize, 0],
      [0, _gridItemSize],
      [_gridItemSize, _gridItemSize]
    ];

    for (int i = 0; i < images.length && i < positions.length; i++) {
      img.compositeImage(combinedImage, images[i],
          dstX: positions[i][0], dstY: positions[i][1]);
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
