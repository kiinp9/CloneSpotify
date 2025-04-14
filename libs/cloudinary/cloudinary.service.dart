import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../constant/config.message.dart';
import '../../exception/config.exception.dart';

class CloudinaryService {
  final String cloudName = "di6hah0gf";
  final String apiKey = "374432928571719";
  final String uploadPreset = "spotifyclone";

  /// Xác định folder con trên Cloudinary dựa theo loại file
  String _getFolderByFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    if (["mp3", "wav", "aac", "flac"].contains(extension)) return "music";

    if (["jpg", "jpeg", "png", "gif", "bmp"].contains(extension)) {
      return filePath.contains("avatar") || filePath.contains("profile")
          ? "avatarImages"
          : "images";
    }

    return "default";
  }

  /// Upload 1 file đơn lẻ vào thư mục mặc định theo loại file
  Future<String?> uploadFile(String filePath) async {
    final folder = _getFolderByFileType(filePath);
    return _uploadFileToSpecificFolder(filePath, folder);
  }

  /// Upload 1 file vào thư mục chỉ định (ví dụ: album1/song1/music)
  Future<String?> _uploadFileToSpecificFolder(
      String filePath, String cloudFolder) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const CustomHttpException(
          ErrorMessage.FILE_NOT_EXIST, HttpStatus.badRequest);
    }

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..fields["folder"] = cloudFolder // Đảm bảo thư mục upload chính xác
      ..fields["api_key"] = apiKey
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      // Trả về URL của ảnh trên Cloudinary
      final secureUrl = data["secure_url"] as String?;

      // Nếu URL trả về hợp lệ, trả về URL của Cloudinary (không bao gồm đường dẫn local)
      if (secureUrl != null) {
        return secureUrl; // Trả về URL chuẩn của Cloudinary
      }
    } else {
      throw const CustomHttpException(
          ErrorMessage.UPLOAD_FAIL, HttpStatus.badRequest);
    }

    return null;
  }

  /// Upload nhiều file từ danh sách đường dẫn và phân loại theo folder
  Future<Map<String, List<String?>>> uploadMultipleFiles(
      List<String> filePaths) async {
    Map<String, List<String?>> categorizedUploads = {
      "music": [],
      "images": [],
      "avatarImages": []
    };

    final results = await Future.wait(filePaths.map(uploadFile));

    for (int i = 0; i < filePaths.length; i++) {
      final folder = _getFolderByFileType(filePaths[i]);
      if (categorizedUploads.containsKey(folder)) {
        categorizedUploads[folder]!.add(results[i]);
      }
    }

    return categorizedUploads;
  }

  /// ✅ Upload toàn bộ folder album (chứa nhiều thư mục bài hát con)
  /// Upload thêm ảnh đại diện album và avatar tác giả
  Future<Map<String, dynamic>> uploadAlbumFromRootFolder(
      String albumFolderPath, String avatarPath) async {
    final albumDirectory = Directory(albumFolderPath);

    if (!albumDirectory.existsSync()) {
      throw const CustomHttpException(
          ErrorMessage.FILE_NOT_EXIST, HttpStatus.badRequest);
    }

    // Lấy tên album từ tên thư mục cha
    final albumName = albumDirectory.path.split(Platform.pathSeparator).last;

    Map<String, dynamic> albumUploads = {
      "albumImage": null, // Ảnh đại diện của album
      "avatarImage": null, // Ảnh đại diện của tác giả album
      "songs": <String, Map<String, List<String?>>>{}
    };

    final allItems = albumDirectory.listSync().toList();

    // Lọc ra file ảnh đại diện của album (ở thư mục gốc)
    final albumImageFile = allItems.whereType<File>().firstWhere(
      (file) {
        final ext = file.path.split('.').last.toLowerCase();
        return ["jpg", "jpeg", "png", "gif", "bmp"].contains(ext);
      },
      orElse: () => File(""),
    );

    // Nếu tìm thấy ảnh album, upload nó
    if (albumImageFile.existsSync()) {
      final imageUrl = await _uploadFileToSpecificFolder(
        albumImageFile.path,
        "$albumName/albumImages",
      );
      albumUploads["albumImage"] = imageUrl;
    }

    // Kiểm tra avatarPath trước khi upload
    if (avatarPath.isNotEmpty) {
      final avatarFile = File(avatarPath);
      if (avatarFile.existsSync()) {
        // Upload avatar vào thư mục authors/avatars
        final avatarUrl = await _uploadFileToSpecificFolder(
          avatarPath,
          "$albumName/avatarImages", // Thư mục riêng cho avatar tác giả
        );

        // In ra URL avatar sau khi upload
        print("Avatar URL: $avatarUrl");

        albumUploads["avatarImage"] =
            avatarUrl; // Lưu URL avatar vào albumUploads
      } else {
        print("⚠️ Avatar file does not exist at: $avatarPath");
      }
    }

    // Lọc ra các thư mục bài hát
    final songFolders = allItems.whereType<Directory>().toList();

    for (final songDir in songFolders) {
      final songName = songDir.path.split(Platform.pathSeparator).last;
      final files =
          songDir.listSync(recursive: false).whereType<File>().toList();
      albumUploads["songs"][songName] = {
        "music": <String?>[],
      };

      for (final file in files) {
        try {
          final filePath = file.path;
          final folderType = _getFolderByFileType(filePath);

          final cloudFolder = "$albumName/$songName/$folderType";

          // Upload file vào Cloudinary và lấy URL
          final uploadedUrl =
              await _uploadFileToSpecificFolder(filePath, cloudFolder);

          if (uploadedUrl != null) {
            albumUploads["songs"][songName]![folderType]?.add(uploadedUrl);
          }
        } catch (e) {
          print("❌ Upload failed for ${file.path}: $e");
        }
      }
    }

    return albumUploads;
  }
}
