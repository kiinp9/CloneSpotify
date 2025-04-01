import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../constant/config.message.dart';
import '../../exception/config.exception.dart';

class CloudinaryService {
  final String cloudName = "di6hah0gf";
  final String apiKey = "374432928571719";

  String _getFolderByFileType(String filePath) {
    final String extension = filePath.split('.').last.toLowerCase();

    if (["mp3", "wav", "aac", "flac"].contains(extension)) {
      return "music";
    }
    if (["jpg", "jpeg", "png", "gif", "bmp"].contains(extension)) {
      return filePath.contains("avatar") || filePath.contains("profile")
          ? "avatarImages"
          : "images";
    }
    return "default";
  }

  Future<String?> uploadFile(String filePath) async {
    File file = File(filePath);
    if (!file.existsSync()) {
      throw const CustomHttpException(
          ErrorMessage.FILE_NOT_EXIST, HttpStatus.badRequest);
    }

    final String folder = _getFolderByFileType(filePath);
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = "spotifyclone"
      ..fields["folder"] = folder
      ..fields["api_key"] = apiKey
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return data["secure_url"] as String?;
    } else {
      throw const CustomHttpException(
          ErrorMessage.UPLOAD_FAIL, HttpStatus.badRequest);
    }
  }

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
