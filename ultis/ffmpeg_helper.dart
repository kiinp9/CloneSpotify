import 'dart:convert';
import 'dart:io';

class FFmpegHelper {
  /// 📌 Lấy thời lượng của file nhạc (tính theo giây)
  static Future<int?> getAudioDuration(String filePath) async {
    try {
      // Chạy lệnh FFmpeg để lấy thông tin file nhạc
      final result = await Process.run(
        'ffmpeg',
        ['-i', filePath],
        stderrEncoding: utf8,
      );

      // Kiểm tra lỗi
      if (result.stderr is! String) {
        print("⚠️ FFmpeg không trả về kết quả hợp lệ.");
        return null;
      }

      final output = result.stderr as String;

      // Regex để lấy thời lượng từ output của FFmpeg
      final regex = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)');
      final match = regex.firstMatch(output);

      if (match == null) {
        print("❌ Không tìm thấy thông tin thời lượng file.");
        return null;
      }

      // Chuyển đổi thời lượng sang giây
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = double.parse(match.group(3)!);

      final durationInSeconds =
          (hours * 3600) + (minutes * 60) + seconds.toInt();

      print("✅ Thời lượng file: $durationInSeconds giây");
      return durationInSeconds;
    } catch (e) {
      print("❌ Lỗi khi lấy thời lượng file: $e");
      return null;
    }
  }
}
