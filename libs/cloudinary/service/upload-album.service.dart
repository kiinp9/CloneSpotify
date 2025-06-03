import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../constant/config.message.dart';
import '../../../exception/config.exception.dart';

abstract class IUploadAlbumService {
  Future<Map<String, dynamic>> uploadAlbumFromFolder(
    String albumFolderPath,
    String avatarPath,
  );
}

class UploadAlbumService implements IUploadAlbumService {
  final env = DotEnv()..load();
  late final String cloudName = env['CLOUDINARY_CLOUD_NAME'] ?? '';
  late final String apiKey = env['CLOUDINARY_API_KEY'] ?? '';
  late final String uploadPreset = env['CLOUDINARY_UPLOAD_PRESET'] ?? '';


  @override
  Future<Map<String, dynamic>> uploadAlbumFromFolder(
      String albumFolderPath, String avatarPath,) async {
    final albumDirectory = Directory(albumFolderPath);

    if (!albumDirectory.existsSync()) {
      throw const CustomHttpException(
          ErrorMessage.FILE_NOT_EXIST, HttpStatus.badRequest,);
    }

    final albumName = albumDirectory.path.split(Platform.pathSeparator).last;

    final albumUploads = <String, dynamic>{
      'albumImage': null,
      'avatarImage': null,
      'songs': <String, Map<String, List<String?>>>{},
    };

    final allItems = albumDirectory.listSync().toList();

    final albumImageFile = allItems.whereType<File>().firstWhere(
      (file) {
        final ext = file.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext);
      },
      orElse: () => File(''),
    );

    if (albumImageFile.existsSync()) {
      final imageUrl = await _uploadFileToSpecificFolder(
        albumImageFile.path,
        '$albumName/albumImages',
      );
      albumUploads['albumImage'] = imageUrl;
    }

    if (avatarPath.isNotEmpty) {
      final avatarUrl = await _uploadFileToSpecificFolder(
        avatarPath,
        '$albumName/avatarImages',
      );

      albumUploads['avatarImage'] = avatarUrl;
    }

    final songFolders = allItems.whereType<Directory>().toList();

    for (final songDir in songFolders) {
      final songName = songDir.path.split(Platform.pathSeparator).last;
      final files =
          songDir.listSync().whereType<File>().toList();
      albumUploads['songs'][songName] = {
        'music': <String?>[],
      };

      for (final file in files) {
        final filePath = file.path;
        final folderType = _getFolderByFileType(filePath);

        final cloudFolder = '$albumName/$songName/$folderType';

        final uploadedUrl =
            await _uploadFileToSpecificFolder(filePath, cloudFolder);

        if (uploadedUrl != null) {
          albumUploads['songs'][songName]![folderType]?.add(uploadedUrl);
        }
      }
    }

    return albumUploads;
  }

  String _getFolderByFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    if (['mp3', 'wav', 'aac', 'flac'].contains(extension)) return 'music';
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension)) {
      return 'images';
    }

    return 'default';
  }

  Future<String?> _uploadFileToSpecificFolder(
      String filePath, String folder,) async {
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
