import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../constant/config.message.dart';
import '../../../exception/config.exception.dart';

abstract class IUploadImagePlaylistService {
  Future<String?> uploadImagePlaylist(String imagePath);

  Future<String?> uploadFile(String filePath, String folder);
}

class UploadImagePlaylistService implements IUploadImagePlaylistService {
  final env = DotEnv()..load();
  late final String cloudName = env['CLOUDINARY_CLOUD_NAME'] ?? '';
  late final String apiKey = env['CLOUDINARY_API_KEY'] ?? '';
  late final String uploadPreset = env['CLOUDINARY_UPLOAD_PRESET'] ?? '';


  @override
  Future<String?> uploadImagePlaylist(String imagePath) async {
    final url = await uploadFile(imagePath, 'imagePlaylist');
    return url;
  }

  @override
  Future<String?> uploadFile(String filePath, String folder) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const CustomHttpException(
          ErrorMessage.FILE_NOT_EXIST, HttpStatus.badRequest,);
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..fields['api_key'] = apiKey
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return data['secure_url'] as String?;
    } else {
      throw const CustomHttpException(
          ErrorMessage.UPLOAD_FAIL, HttpStatus.badRequest,);
    }
  }
}
