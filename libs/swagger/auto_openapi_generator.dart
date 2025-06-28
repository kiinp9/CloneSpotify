import 'dart:io';
import 'dart:convert';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

import '../../model/router_infor.dart';
import '../../ultis/helpers/schema_helper.dart';
import 'route_file_analyzed.dart';
import 'tag_helper.dart';

class EnhancedAutoOpenAPIGenerator {
  final Map<String, List<RouteInfo>> _routesByTag = {};
  final Set<String> _usedSchemas = <String>{};

  Future<void> generateFromRoutes(String routesDir) async {
    print('📁 Đang quét thư mục routes: $routesDir');

    final routes = await _scanRoutes(routesDir);
    _organizeRoutesByTag(routes);

    print(
        '🎯 Tìm thấy ${routes.length} routes trong ${_routesByTag.keys.length} tags');

    final openApiSpec = _generateOpenAPISpec();
    await _saveToFile(openApiSpec);

    print('✅ Đã tạo OpenAPI spec thành công!');
  }

  Future<List<RouteInfo>> _scanRoutes(String routesDir) async {
    final routes = <RouteInfo>[];
    final directory = Directory(routesDir);

    if (!directory.existsSync()) {
      throw Exception('Thư mục routes không tồn tại: $routesDir');
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final routeInfos = await _analyzeRouteFile(entity);
        routes.addAll(routeInfos);
      }
    }

    return routes;
  }

  Future<List<RouteInfo>> _analyzeRouteFile(File file) async {
    try {
      final content = await file.readAsString();
      final routesPath = _extractRoutePath(file.path);
      final fileName = file.path.split(Platform.pathSeparator).last;

      print('🔍 Phân tích file: $fileName -> $routesPath');

      final parseResult = parseString(
        content: content,
        featureSet: FeatureSet.latestLanguageVersion(),
      );

      if (parseResult.errors.isNotEmpty) {
        print('⚠️ Lỗi parse file ${file.path}:');
        for (final error in parseResult.errors) {
          print('   ${error.message}');
        }
        return [];
      }

      final analyzer = RouteFileAnalyzer(routesPath, fileName, content);
      parseResult.unit.visitChildren(analyzer);

      return analyzer.routes;
    } catch (e) {
      print('❌ Lỗi phân tích file ${file.path}: $e');
      return [];
    }
  }

  String _extractRoutePath(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final routesIndex = normalized.indexOf('/routes/');

    if (routesIndex == -1) return '';

    String path =
        normalized.substring(routesIndex + 8); // '/routes/'.length = 8
    path = path.replaceAll('.dart', '');

    // Xử lý index files
    if (path.endsWith('/index')) {
      path = path.substring(0, path.length - 6); // '/index'.length = 6
    }

    return '/$path';
  }

  void _organizeRoutesByTag(List<RouteInfo> routes) {
    _routesByTag.clear();

    for (final route in routes) {
      _routesByTag.putIfAbsent(route.tag, () => []).add(route);
    }
  }

  Map<String, dynamic> _generateOpenAPISpec() {
    final paths = <String, dynamic>{};
    final tags = <Map<String, String>>[];

    // Tạo tags
    for (final tag in _routesByTag.keys) {
      tags.add({
        'name': tag,
        'description': TagHelper.getTagDescription(tag),
      });
    }

    // Tạo paths
    for (final entry in _routesByTag.entries) {
      for (final route in entry.value) {
        final pathKey = route.apiPath;
        paths.putIfAbsent(pathKey, () => <String, dynamic>{});
        paths[pathKey][route.method.toLowerCase()] =
            _generatePathOperation(route);
      }
    }

    return {
      'openapi': '3.0.3',
      'info': {
        'title': 'Music API Documentation',
        'description': 'API documentation được tạo tự động từ routes',
        'version': '1.0.0',
        'contact': {'name': 'API Support', 'email': 'support@example.com'}
      },
      'servers': [
        {'url': 'http://localhost:8080', 'description': 'Development server'}
      ],
      'tags': tags,
      'paths': paths,
      'components': {
        'schemas': _getUsedSchemas(),
        'securitySchemes': {
          'bearerAuth': {
            'type': 'http',
            'scheme': 'bearer',
            'bearerFormat': 'JWT'
          }
        }
      }
    };
  }

  Map<String, dynamic> _generatePathOperation(RouteInfo route) {
    final operation = <String, dynamic>{
      'tags': [route.tag],
      'summary': route.summary,
      'description': route.description,
      'responses': _generateResponses(route),
    };

    // Thêm security nếu cần auth
    if (route.requiresAuth) {
      operation['security'] = [
        {'bearerAuth': <dynamic>[]}
      ];
    }

    // Thêm parameters
    final parameters = <Map<String, dynamic>>[];

    // Path parameters
    for (final param in route.pathParams) {
      parameters.add({
        'name': param,
        'in': 'path',
        'required': true,
        'schema': {'type': 'string'},
        'description': 'ID của ${param}',
        'example': '${param}-123'
      });
    }

    // Query parameters
    for (final param in route.queryParams) {
      parameters.add({
        'name': param.name,
        'in': 'query',
        'required': param.required,
        'schema': {
          'type': param.type,
          if (param.defaultValue != null) 'default': param.defaultValue,
        },
        if (param.description != null) 'description': param.description,
        if (param.example != null) 'example': param.example,
      });
    }

    if (parameters.isNotEmpty) {
      operation['parameters'] = parameters;
    }

    // Thêm request body cho POST, PUT, PATCH
    if (['POST', 'PUT', 'PATCH'].contains(route.method) &&
        route.requestBodyFields.isNotEmpty) {
      operation['requestBody'] = _generateRequestBody(route);
    }

    return operation;
  }

  Map<String, dynamic> _generateRequestBody(RouteInfo route) {
    final schemaName = _getRequestBodySchemaName(route);
    _usedSchemas.add(schemaName);

    return {
      'required': true,
      'content': {
        'application/json': {
          'schema': {'\$ref': '#/components/schemas/$schemaName'}
        }
      }
    };
  }

  String _getRequestBodySchemaName(RouteInfo route) {
    // Sử dụng schema có sẵn nếu có
    SchemaHelper.getDefaultSchemas();

    if (route.apiPath.contains('/auth/register')) return 'AuthRegisterRequest';
    if (route.apiPath.contains('/auth/login')) return 'AuthLoginRequest';
    if (route.apiPath.contains('/playlist') && route.method == 'POST')
      return 'CreatePlaylistRequest';
    if (route.apiPath.contains('/music') && route.method == 'POST')
      return 'CreateMusicRequest';
    if (route.apiPath.contains('/album') && route.method == 'POST')
      return 'CreateAlbumRequest';

    // Tạo schema động
    return '${route.tag}${route.method.toLowerCase().capitalize()}Request';
  }

  Map<String, dynamic> _generateResponses(RouteInfo route) {
    final responses = <String, dynamic>{
      '200': {
        'description': 'Thành công',
        'content': {
          'application/json': {
            'schema': {'\$ref': '#/components/schemas/SuccessResponse'}
          }
        }
      },
      '400': {
        'description': 'Lỗi request không hợp lệ',
        'content': {
          'application/json': {
            'schema': {'\$ref': '#/components/schemas/ErrorResponse'}
          }
        }
      },
      '500': {
        'description': 'Lỗi server nội bộ',
        'content': {
          'application/json': {
            'schema': {'\$ref': '#/components/schemas/ErrorResponse'}
          }
        }
      }
    };

    // Thêm response 401 cho routes cần auth
    if (route.requiresAuth) {
      responses['401'] = {
        'description': 'Không có quyền truy cập',
        'content': {
          'application/json': {
            'schema': {'\$ref': '#/components/schemas/ErrorResponse'}
          }
        }
      };
    }

    // Thêm các response code đặc biệt
    if (route.method == 'POST') {
      responses['201'] = {
        'description': 'Tạo thành công',
        'content': {
          'application/json': {
            'schema': {'\$ref': '#/components/schemas/SuccessResponse'}
          }
        }
      };
    }

    if (route.method == 'DELETE') {
      responses['204'] = {
        'description': 'Xóa thành công',
      };
    }

    // Đánh dấu các schema được sử dụng
    _usedSchemas.addAll(['SuccessResponse', 'ErrorResponse']);

    return responses;
  }

  Map<String, dynamic> _getUsedSchemas() {
    final allSchemas = SchemaHelper.getDefaultSchemas();
    final usedSchemas = <String, dynamic>{};

    // Thêm các schema được sử dụng
    for (final schemaName in _usedSchemas) {
      if (allSchemas.containsKey(schemaName)) {
        usedSchemas[schemaName] = allSchemas[schemaName];
      }
    }

    // Luôn thêm các schema cơ bản
    usedSchemas['SuccessResponse'] = allSchemas['SuccessResponse'];
    usedSchemas['ErrorResponse'] = allSchemas['ErrorResponse'];

    // Tạo schema động cho các request body không có sẵn
    for (final entry in _routesByTag.entries) {
      for (final route in entry.value) {
        if (['POST', 'PUT', 'PATCH'].contains(route.method) &&
            route.requestBodyFields.isNotEmpty) {
          final schemaName = _getRequestBodySchemaName(route);
          if (!usedSchemas.containsKey(schemaName)) {
            usedSchemas[schemaName] =
                _generateDynamicSchema(route.requestBodyFields);
          }
        }
      }
    }

    return usedSchemas;
  }

  Map<String, dynamic> _generateDynamicSchema(List<RequestBodyField> fields) {
    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final field in fields) {
      properties[field.name] = {
        'type': field.type,
        if (field.example != null) 'example': field.example,
        if (field.description != null) 'description': field.description,
      };

      if (field.required) {
        required.add(field.name);
      }
    }

    return {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }

  Future<void> _saveToFile(Map<String, dynamic> spec) async {
    // Tạo thư mục nếu chưa có
    final outputDir = Directory('public/swagger');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // Lưu file YAML
    final yamlFile = File('public/swagger/openapi.yaml');
    final yamlContent = _convertToYaml(spec);
    await yamlFile.writeAsString(yamlContent);

    // Lưu file JSON để debug
    final jsonFile = File('public/swagger/openapi.json');
    const encoder = JsonEncoder.withIndent('  ');
    await jsonFile.writeAsString(encoder.convert(spec));

    print('📄 Đã lưu file:');
    print('   - ${yamlFile.path}');
    print('   - ${jsonFile.path}');
  }

  String _convertToYaml(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    _writeYaml(buffer, data, 0);
    return buffer.toString();
  }

  void _writeYaml(StringBuffer buffer, dynamic data, int indent) {
    final spaces = '  ' * indent;

    if (data is Map) {
      data.forEach((key, value) {
        buffer.writeln('${spaces}$key:');
        if (value is String && value.contains('\n')) {
          buffer.writeln('${spaces}  |');
          for (final line in value.split('\n')) {
            buffer.writeln('${spaces}  $line');
          }
        } else if (value is Map || value is List) {
          _writeYaml(buffer, value, indent + 1);
        } else {
          buffer.writeln('${spaces}  $value');
        }
      });
    } else if (data is List) {
      for (final item in data) {
        buffer.write('${spaces}- ');
        if (item is Map || item is List) {
          buffer.writeln();
          _writeYaml(buffer, item, indent + 1);
        } else {
          buffer.writeln(item);
        }
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
