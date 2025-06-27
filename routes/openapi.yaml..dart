import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    print(
        '📄 Root OpenAPI: ${context.request.method.name} ${context.request.uri.path}');

    if (context.request.method != HttpMethod.get) {
      return Response(
        statusCode: 405,
        body: 'Method not allowed',
      );
    }

    // Đọc file từ public/swagger/openapi.yaml
    final file = File('public/swagger/openapi.yaml');
    if (!await file.exists()) {
      return Response(
        statusCode: 404,
        body: 'OpenAPI spec not found at public/swagger/openapi.yaml',
      );
    }

    final yaml = await file.readAsString();

    return Response(
      body: yaml,
      headers: {
        'content-type': 'application/yaml; charset=utf-8',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Cache-Control': 'no-cache',
      },
    );
  } catch (e) {
    print('Error loading OpenAPI spec: $e');
    return Response(
      statusCode: 500,
      body: 'Error: $e',
    );
  }
}
