import 'dart:io';

class RouteScanner {
  static Future<List<RouteFile>> scanRoutes(String routesPath) async {
    final routes = <RouteFile>[];
    final directory = Directory(routesPath);

    if (!directory.existsSync()) {
      throw Exception('Routes directory not found: $routesPath');
    }

    await _scanRecursively(directory, '', routes);
    return routes;
  }

  static Future<void> _scanRecursively(
      Directory dir, String currentPath, List<RouteFile> routes) async {
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final dirName = entity.path.split(Platform.pathSeparator).last;
        if (!dirName.startsWith('.') && dirName != 'public') {
          await _scanRecursively(entity, '$currentPath/$dirName', routes);
        }
      } else if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = entity.path.split(Platform.pathSeparator).last;

        // Skip middleware files
        if (fileName.contains('_middleware')) continue;

        routes.add(RouteFile(
          file: entity,
          routePath: currentPath,
          fileName: fileName,
        ));
      }
    }
  }
}

class RouteFile {
  final File file;
  final String routePath;
  final String fileName;

  RouteFile({
    required this.file,
    required this.routePath,
    required this.fileName,
  });

  String get apiPath {
    String path = routePath;

    // Convert [id] to {id}
    path = path.replaceAllMapped(RegExp(r'\\[([^\\]]+)\\]'), (match) {
      return '{${match.group(1)}}';
    });

    // Handle index files
    if (fileName == 'index.dart' && path.isNotEmpty) {
      // Keep the path as is for index files
    } else if (fileName != 'index.dart') {
      // Add filename to path if not index
      final nameWithoutExt = fileName.replaceAll('.dart', '');
      if (nameWithoutExt != 'index') {
        path = '$path/$nameWithoutExt';
      }
    }

    if (path.isEmpty) path = '/';

    return path;
  }
}
