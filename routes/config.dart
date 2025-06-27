import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  try {
    // Log request
    print(
        '⚙️ Swagger Config: ${context.request.method.name} ${context.request.uri.path}');

    // Kiểm tra method - chỉ cho phép GET
    if (context.request.method != HttpMethod.get) {
      return Response(
        statusCode: 405,
        body: 'Method not allowed',
      );
    }

    // Trả về config JSON cho Swagger UI
    final config = {
      'url': 'public/swagger/openapi.yaml',
      'dom_id': '#swagger-ui',
      'deepLinking': true,
      'presets': ['SwaggerUIBundle.presets.apis', 'SwaggerUIStandalonePreset'],
      'plugins': ['SwaggerUIBundle.plugins.DownloadUrl'],
      'layout': 'StandaloneLayout',
      'tryItOutEnabled': true,
      'supportedSubmitMethods': ['get', 'post', 'put', 'delete', 'patch'],
      'docExpansion': 'list',
      'defaultModelsExpandDepth': 1,
      'defaultModelExpandDepth': 1,
    };

    return Response.json(
      body: config,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
  } catch (e) {
    print('Error loading Swagger config: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Error loading Swagger config: $e'},
    );
  }
}
