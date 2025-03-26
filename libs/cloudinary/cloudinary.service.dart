import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "di6hah0gf";
  final String apiKey = "374432928571719";
  final String apiSecret = "omwe7k3PhRjQeSYcGYtVkWlyW98";

  /// 🆙 **Upload một file lên Cloudinary**
  Future<String?> uploadFile(String filePath,
      {String folder = "default"}) async {
    File file = File(filePath);

    if (!file.existsSync()) {
      print("⚠️ File không tồn tại: $filePath");
      return null;
    }

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] =
          "ml_default" // Thay bằng upload preset của bạn
      ..fields["folder"] = folder
      ..fields["api_key"] = apiKey
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      print("✅ Upload thành công: ${data["secure_url"]}");
      return data["secure_url"] as String?;
    } else {
      print("❌ Upload thất bại: ${data["error"]["message"]}");
      return null;
    }
  }

  /// 📂 **Upload tất cả file trong một thư mục**
  Future<List<String>> uploadFolder(String folderPath,
      {String cloudFolder = "default"}) async {
    Directory directory = Directory(folderPath);

    if (!directory.existsSync()) {
      print("⚠️ Thư mục không tồn tại: $folderPath");
      return [];
    }

    List<String> uploadedUrls = [];

    // Lấy danh sách tất cả file trong thư mục
    List<FileSystemEntity> files = directory.listSync();

    for (var file in files) {
      if (file is File) {
        String? url = await uploadFile(file.path, folder: cloudFolder);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
    }

    print("📂 ✅ Upload hoàn tất. Tổng số file: ${uploadedUrls.length}");
    return uploadedUrls;
  }
}
