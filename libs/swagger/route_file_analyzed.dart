import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../../model/router_infor.dart';
import 'route_content_analyzed.dart';
import 'tag_helper.dart';

class RouteFileAnalyzer extends GeneralizingAstVisitor<void> {
  final String routePath;
  final String fileName;
  final String fileContent;
  List<RouteInfo> routes = [];

  RouteFileAnalyzer(this.routePath, this.fileName, this.fileContent);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == 'onRequest') {
      routes.addAll(_analyzeRouteFunction(node));
    }
    super.visitFunctionDeclaration(node);
  }

  List<RouteInfo> _analyzeRouteFunction(FunctionDeclaration node) {
    final analyzer = RouteContentAnalyzer(fileContent);
    node.visitChildren(analyzer);

    final routeInfos = <RouteInfo>[];
    final apiPath = _buildApiPath();

    if (analyzer.detectedMethods.isNotEmpty) {
      for (final method in analyzer.detectedMethods) {
        routeInfos.add(_createRouteInfo(apiPath, method, analyzer));
      }
    } else {
      // Default to GET if no method detected
      routeInfos.add(_createRouteInfo(apiPath, 'GET', analyzer));
    }

    return routeInfos;
  }

  RouteInfo _createRouteInfo(
      String apiPath, String method, RouteContentAnalyzer analyzer) {
    final tag = TagHelper.extractTag(apiPath);

    return RouteInfo(
      apiPath: apiPath,
      method: method,
      tag: tag,
      summary: _generateSummary(apiPath, method),
      description: _generateDescription(apiPath, method),
      pathParams: _extractPathParams(apiPath),
      queryParams: analyzer.queryParams,
      requestBodyFields: analyzer.requestBodyFields,
      requiresAuth: analyzer.hasAuthCheck,
    );
  }

  String _buildApiPath() {
    String path = routePath;

    // Chuyển đổi [id] thành {id}
    path = path.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (match) {
      return '{${match.group(1)}}';
    });

    // Xử lý index files
    if (fileName == 'index.dart') {
      if (path.isEmpty) path = '/';
    } else {
      final nameWithoutExt = fileName.replaceAll('.dart', '');
      if (nameWithoutExt != 'index') {
        path = path.isEmpty ? '/$nameWithoutExt' : '$path/$nameWithoutExt';
      }
    }

    return path;
  }

  List<String> _extractPathParams(String path) {
    final params = <String>[];
    final matches = RegExp(r'\{([^}]+)\}').allMatches(path);
    for (final match in matches) {
      params.add(match.group(1)!);
    }
    return params;
  }

  String _generateSummary(String path, String method) {
    // Custom summaries cho các endpoints đã biết
    if (path.contains('/auth/register')) return 'Đăng ký tài khoản';
    if (path.contains('/auth/login')) return 'Đăng nhập';
    if (path.contains('/auth/logout')) return 'Đăng xuất';
    if (path.contains('/auth') && method == 'GET')
      return 'Lấy thông tin xác thực';
    if (path.contains('/auth') && method == 'PUT')
      return 'Cập nhật thông tin xác thực';

    if (path.contains('/user') && method == 'GET')
      return 'Lấy thông tin người dùng';
    if (path.contains('/user') && method == 'PUT')
      return 'Cập nhật thông tin người dùng';
    if (path.contains('/user') && method == 'PATCH')
      return 'Cập nhật một phần thông tin người dùng';
    if (path.contains('/user') && method == 'DELETE') return 'Xóa người dùng';
    if (path.contains('/user') && method == 'POST') return 'Tạo người dùng mới';

    if (path.contains('/music/play')) return 'Phát nhạc';
    if (path.contains('/music/next')) return 'Chuyển bài tiếp theo';
    if (path.contains('/music/rewind')) return 'Chuyển bài trước';
    if (path.contains('/music') && method == 'GET') return 'Lấy danh sách nhạc';
    if (path.contains('/music') && method == 'POST') return 'Tạo bài hát mới';
    if (path.contains('/music') && method == 'PATCH') return 'Cập nhật bài hát';
    if (path.contains('/music') && method == 'PUT')
      return 'Cập nhật toàn bộ thông tin bài hát';
    if (path.contains('/music') && method == 'DELETE') return 'Xóa bài hát';

    if (path.contains('/playlist') && method == 'GET')
      return 'Lấy danh sách playlist';
    if (path.contains('/playlist') && method == 'POST')
      return 'Tạo playlist mới';
    if (path.contains('/playlist') && method == 'PUT')
      return 'Cập nhật playlist';
    if (path.contains('/playlist') && method == 'DELETE') return 'Xóa playlist';
    if (path.contains('/playlist') && method == 'PATCH')
      return 'Cập nhật một phần playlist';

    if (path.contains('/album') && method == 'GET')
      return 'Lấy danh sách album';
    if (path.contains('/album') && method == 'POST') return 'Tạo album mới';
    if (path.contains('/album') && method == 'PUT') return 'Cập nhật album';
    if (path.contains('/album') && method == 'DELETE') return 'Xóa album';

    if (path.contains('/author') && method == 'GET')
      return 'Lấy danh sách nghệ sĩ';
    if (path.contains('/author') && method == 'POST') return 'Tạo nghệ sĩ mới';
    if (path.contains('/author') && method == 'PUT')
      return 'Cập nhật thông tin nghệ sĩ';
    if (path.contains('/author') && method == 'DELETE') return 'Xóa nghệ sĩ';

    if (path.contains('/category') && method == 'GET')
      return 'Lấy danh sách danh mục';
    if (path.contains('/category') && method == 'POST')
      return 'Tạo danh mục mới';
    if (path.contains('/category') && method == 'PUT')
      return 'Cập nhật danh mục';
    if (path.contains('/category') && method == 'DELETE') return 'Xóa danh mục';

    if (path.contains('/history') && method == 'GET')
      return 'Lấy lịch sử nghe nhạc';
    if (path.contains('/history') && method == 'POST')
      return 'Thêm vào lịch sử';
    if (path.contains('/history') && method == 'DELETE') return 'Xóa lịch sử';

    if (path.contains('/search')) return 'Tìm kiếm';

    if (path.contains('/follow') && method == 'GET')
      return 'Lấy danh sách theo dõi';
    if (path.contains('/follow') && method == 'POST') return 'Theo dõi nghệ sĩ';
    if (path.contains('/follow') && method == 'DELETE') return 'Hủy theo dõi';

    if (path.contains('/like') && method == 'GET')
      return 'Lấy danh sách yêu thích';
    if (path.contains('/like') && method == 'POST') return 'Thêm vào yêu thích';
    if (path.contains('/like') && method == 'DELETE')
      return 'Xóa khỏi yêu thích';

    if (path.contains('/home') && method == 'GET')
      return 'Lấy nội dung trang chủ';

    // Generic summaries
    switch (method) {
      case 'GET':
        return path.contains('{') ? 'Lấy thông tin chi tiết' : 'Lấy danh sách';
      case 'POST':
        return 'Tạo mới';
      case 'PUT':
        return 'Cập nhật toàn bộ';
      case 'PATCH':
        return 'Cập nhật một phần';
      case 'DELETE':
        return 'Xóa';
      default:
        return '$method ${path.split('/').last}';
    }
  }

  String _generateDescription(String path, String method) {
    // Custom descriptions cho các endpoints đã biết
    if (path.contains('/auth/register'))
      return 'Đăng ký tài khoản người dùng mới với thông tin cơ bản';
    if (path.contains('/auth/login'))
      return 'Đăng nhập vào hệ thống với email/username và mật khẩu';
    if (path.contains('/auth/logout'))
      return 'Đăng xuất khỏi hệ thống và hủy token';
    if (path.contains('/auth') && method == 'GET')
      return 'Lấy thông tin xác thực hiện tại của người dùng';

    if (path.contains('/user') && method == 'GET') {
      return path.contains('{')
          ? 'Lấy thông tin chi tiết của một người dùng cụ thể'
          : 'Lấy danh sách tất cả người dùng';
    }
    if (path.contains('/user') && method == 'PUT')
      return 'Cập nhật toàn bộ thông tin người dùng';
    if (path.contains('/user') && method == 'PATCH')
      return 'Cập nhật một phần thông tin người dùng';

    if (path.contains('/music/play')) return 'Phát một bài hát cụ thể';
    if (path.contains('/music/next'))
      return 'Chuyển sang bài hát tiếp theo trong danh sách phát';
    if (path.contains('/music/rewind')) return 'Quay lại bài hát trước đó';
    if (path.contains('/music') && method == 'GET') {
      return path.contains('{')
          ? 'Lấy thông tin chi tiết của một bài hát'
          : 'Lấy danh sách các bài hát với tùy chọn lọc và phân trang';
    }
    if (path.contains('/music') && method == 'POST')
      return 'Tạo bài hát mới với thông tin cơ bản';
    if (path.contains('/music') && method == 'PUT')
      return 'Cập nhật toàn bộ thông tin của một bài hát';

    if (path.contains('/playlist') && method == 'GET') {
      return path.contains('{')
          ? 'Lấy thông tin chi tiết của một playlist'
          : 'Lấy danh sách các playlist của người dùng';
    }
    if (path.contains('/playlist') && method == 'POST')
      return 'Tạo playlist mới';
    if (path.contains('/playlist') && method == 'PUT')
      return 'Cập nhật thông tin playlist';

    if (path.contains('/album') && method == 'GET') {
      return path.contains('{')
          ? 'Lấy thông tin chi tiết của một album'
          : 'Lấy danh sách các album';
    }
    if (path.contains('/album') && method == 'POST') return 'Tạo album mới';

    if (path.contains('/author') && method == 'GET') {
      return path.contains('{')
          ? 'Lấy thông tin chi tiết của một nghệ sĩ'
          : 'Lấy danh sách các nghệ sĩ';
    }
    if (path.contains('/author') && method == 'POST') return 'Tạo nghệ sĩ mới';

    if (path.contains('/category') && method == 'GET')
      return 'Lấy danh sách các danh mục nhạc';
    if (path.contains('/category') && method == 'POST')
      return 'Tạo danh mục mới';

    if (path.contains('/history') && method == 'GET')
      return 'Lấy lịch sử nghe nhạc của người dùng';
    if (path.contains('/history') && method == 'POST')
      return 'Thêm bài hát vào lịch sử nghe';

    if (path.contains('/search'))
      return 'Tìm kiếm bài hát, album, nghệ sĩ theo từ khóa';

    if (path.contains('/follow') && method == 'GET')
      return 'Lấy danh sách các nghệ sĩ đang theo dõi';
    if (path.contains('/follow') && method == 'POST')
      return 'Theo dõi một nghệ sĩ';
    if (path.contains('/follow') && method == 'DELETE')
      return 'Hủy theo dõi một nghệ sĩ';

    if (path.contains('/like') && method == 'GET')
      return 'Lấy danh sách các bài hát yêu thích';
    if (path.contains('/like') && method == 'POST')
      return 'Thêm bài hát vào danh sách yêu thích';
    if (path.contains('/like') && method == 'DELETE')
      return 'Xóa bài hát khỏi danh sách yêu thích';

    if (path.contains('/home'))
      return 'Lấy nội dung trang chủ bao gồm bài hát trending, đề xuất';

    // Generic descriptions
    final resourceName = _extractResourceName(path);
    switch (method) {
      case 'GET':
        return path.contains('{')
            ? 'Lấy thông tin chi tiết của $resourceName'
            : 'Lấy danh sách $resourceName với tùy chọn lọc và phân trang';
      case 'POST':
        return 'Tạo $resourceName mới';
      case 'PUT':
        return 'Cập nhật toàn bộ thông tin $resourceName';
      case 'PATCH':
        return 'Cập nhật một phần thông tin $resourceName';
      case 'DELETE':
        return 'Xóa $resourceName';
      default:
        return 'Thực hiện $method trên $resourceName';
    }
  }

  String _extractResourceName(String path) {
    final segments = path
        .split('/')
        .where((s) => s.isNotEmpty && !s.startsWith('{'))
        .toList();
    if (segments.isEmpty) return 'resource';

    final lastSegment = segments.last.toLowerCase();
    final resourceNames = {
      'auth': 'xác thực',
      'user': 'người dùng',
      'music': 'bài hát',
      'playlist': 'playlist',
      'album': 'album',
      'author': 'nghệ sĩ',
      'category': 'danh mục',
      'history': 'lịch sử',
      'search': 'tìm kiếm',
      'follow': 'theo dõi',
      'like': 'yêu thích',
      'home': 'trang chủ',
    };

    return resourceNames[lastSegment] ?? lastSegment;
  }

  // Static method to analyze a single route file
  static Future<List<RouteInfo>> analyzeFile(
      File file, String routePath, String fileName) async {
    try {
      final content = await file.readAsString();
      final analyzer = RouteFileAnalyzer(routePath, fileName, content);

      // Parse the file and extract routes
      // This would typically use the Dart analyzer to parse AST
      // For now, we'll use a simple approach
      final routes = <RouteInfo>[];

      // Analyze the content for HTTP methods and other patterns
      final contentAnalyzer = RouteContentAnalyzer(content);

      // Build API path
      final apiPath = analyzer._buildApiPath();

      // If no methods detected, assume GET
      final methods = contentAnalyzer.detectedMethods.isNotEmpty
          ? contentAnalyzer.detectedMethods
          : {'GET'};

      for (final method in methods) {
        routes.add(analyzer._createRouteInfo(apiPath, method, contentAnalyzer));
      }

      return routes;
    } catch (e) {
      print('Error analyzing file ${file.path}: $e');
      return [];
    }
  }
}
