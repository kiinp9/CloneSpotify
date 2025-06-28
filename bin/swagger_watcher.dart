import 'dart:io';
import 'dart:async';
import '../libs/swagger/auto_openapi_generator.dart';

class SwaggerWatcher {
  Timer? _debounceTimer;
  bool _isGenerating = false;

  Future<void> startWatching() async {
    print('🔍 Khởi động file watcher cho routes...');
    print('📁 Đang theo dõi: routes/ directory');
    print('📄 Output: public/swagger/openapi.yaml');
    print('🌐 Swagger UI: http://localhost:8080/swagger');
    print('');

    // Tạo OpenAPI ban đầu
    await _generateOpenAPI();

    // Theo dõi thay đổi file
    _watchDirectory('routes');

    // Giữ process hoạt động
    print('👀 Đang theo dõi thay đổi... (Nhấn Ctrl+C để dừng)');
    await _keepAlive();
  }

  void _watchDirectory(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      print('❌ Không tìm thấy thư mục routes: $path');
      return;
    }

    directory.watch(recursive: true).listen((event) {
      if (event.path.endsWith('.dart') && !event.path.contains('_middleware')) {
        final fileName = event.path.split(Platform.pathSeparator).last;
        print('📝 File thay đổi: $fileName');
        _debounceGeneration();
      }
    });
  }

  void _debounceGeneration() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!_isGenerating) {
        _generateOpenAPI();
      }
    });
  }

  Future<void> _generateOpenAPI() async {
    if (_isGenerating) return;

    _isGenerating = true;
    print('⚙️ Đang tạo lại OpenAPI spec...');

    try {
      final generator = EnhancedAutoOpenAPIGenerator();
      await generator.generateFromRoutes('routes');
      print('✅ Cập nhật OpenAPI thành công!');
      print('🔗 Xem tại: http://localhost:8080/swagger');
    } catch (e) {
      print('❌ Lỗi khi tạo OpenAPI: $e');
    } finally {
      _isGenerating = false;
    }
  }

  Future<void> _keepAlive() async {
    final completer = Completer<void>();

    ProcessSignal.sigint.watch().listen((signal) {
      print('\n👋 Đang dừng watcher...');
      _debounceTimer?.cancel();
      completer.complete();
    });

    return completer.future;
  }
}

void main() async {
  try {
    final watcher = SwaggerWatcher();
    await watcher.startWatching();
  } catch (e) {
    print('❌ Lỗi khởi động watcher: $e');
    exit(1);
  }
}
