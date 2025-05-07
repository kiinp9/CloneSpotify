import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import '../interface/file.interface.dart';

/// Implementation của service thao tác file
class FileService implements IFileService {
  @override
  Future<Uint8List> readBytes(String path) async {
    return await File(path).readAsBytes();
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    await File(path).writeAsBytes(bytes);
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  // ignore: strict_raw_type
  Future createBlankImage(
      {required String path,
      required int width,
      required int height,
      int color = 0xFFFFFFFF}) async {
    final image = img.Image(width: width, height: height);
    img.fill(image,
        color: img.ColorRgba8(
            (color >> 16) & 0xFF, // Red
            (color >> 8) & 0xFF, // Green
            color & 0xFF, // Blue
            (color >> 24) & 0xFF // Alpha
            ));

    final pngBytes = img.encodePng(image);
    await File(path).writeAsBytes(pngBytes);
  }
}
