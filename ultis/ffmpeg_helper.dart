import 'dart:convert';
import 'dart:io';

class FFmpegHelper {
  /// Hàm lấy thời lượng của file âm thanh bằng cách sử dụng FFmpeg.
  ///
  /// - [filePath]: Đường dẫn của file âm thanh cần kiểm tra.
  /// - Trả về thời lượng file tính theo giây, hoặc `null` nếu có lỗi.
  static Future<int?> getAudioDuration(String filePath) async {
    try {
      // Lấy đường dẫn của FFmpeg
      final ffmpegPath = await _getFFmpegPath();
      if (ffmpegPath == null || !File(filePath).existsSync()) return null;

      // Định dạng lại đường dẫn file để tránh lỗi
      final safeFilePath = filePath.replaceAll(r'\', '/');

      // Chạy lệnh FFmpeg để lấy thông tin file
      final result = await Process.run(
        ffmpegPath,
        ['-i', safeFilePath],
        runInShell: true, // Chạy trong shell để đảm bảo tìm thấy FFmpeg
        stderrEncoding: utf8, // Đọc kết quả lỗi dưới dạng UTF-8
      );

      // Kiểm tra kết quả trả về từ FFmpeg
      if (result.stderr is! String) return null;
      final output = result.stderr as String;

      // Sử dụng regex để tìm thông tin thời lượng từ output của FFmpeg
      final regex = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)');
      final match = regex.firstMatch(output);
      if (match == null) return null;

      // Chuyển đổi thời gian từ định dạng HH:MM:SS.SSS sang giây
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = double.parse(match.group(3)!);

      return (hours * 3600) + (minutes * 60) + seconds.toInt();
    } catch (_) {
      return null; // Trả về null nếu có lỗi xảy ra
    }
  }

  /// Hàm lấy đường dẫn đầy đủ của FFmpeg trên hệ thống.
  ///
  /// - Trả về đường dẫn FFmpeg nếu tìm thấy, hoặc `'ffmpeg'` nếu không tìm thấy.
  static Future<String?> _getFFmpegPath() async {
    try {
      if (Platform.isWindows) {
        // Kiểm tra FFmpeg trong PATH trên Windows
        final whereResult =
            await Process.run('where', ['ffmpeg'], runInShell: true);
        if (whereResult.exitCode == 0 &&
            (whereResult.stdout as String).trim().isNotEmpty) {
          return (whereResult.stdout as String).split('\n').first.trim();
        }

        // Kiểm tra các vị trí phổ biến trên Windows
        final commonPaths = [
          r'C:\ffmpeg\bin\ffmpeg.exe',
          r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
          r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe',
        ];

        for (final path in commonPaths) {
          if (File(path).existsSync()) return path;
        }
      } else {
        // Kiểm tra FFmpeg trong PATH trên macOS/Linux
        final whichResult =
            await Process.run('which', ['ffmpeg'], runInShell: true);
        if (whichResult.exitCode == 0 &&
            (whichResult.stdout as String).trim().isNotEmpty) {
          return (whichResult.stdout as String).trim();
        }

        // Kiểm tra các vị trí phổ biến trên macOS/Linux
        final commonPaths = [
          '/usr/bin/ffmpeg',
          '/usr/local/bin/ffmpeg',
          '/opt/homebrew/bin/ffmpeg',
        ];

        for (final path in commonPaths) {
          if (File(path).existsSync()) return path;
        }
      }

      return 'ffmpeg'; // Trả về 'ffmpeg' nếu không tìm thấy
    } catch (_) {
      return 'ffmpeg'; // Trả về 'ffmpeg' nếu có lỗi xảy ra
    }
  }
}
