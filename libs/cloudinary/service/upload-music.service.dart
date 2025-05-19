import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../constant/config.message.dart';
import '../../../exception/config.exception.dart';

abstract class IUploadMusicService {
  Future<String?> uploadFile(String filePath);
}

class UploadMusicService implements IUploadMusicService {
  final env = DotEnv()..load();
  late final String cloudName = env['CLOUDINARY_CLOUD_NAME'] ?? '';
  late final String apiKey = env['CLOUDINARY_API_KEY'] ?? '';
  late final String uploadPreset = env['CLOUDINARY_UPLOAD_PRESET'] ?? '';


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
      ..fields["folder"] = cloudFolder
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
}
