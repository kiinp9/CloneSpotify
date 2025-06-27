import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    final file = File('public/swagger/index.html');
    if (!await file.exists()) {
      return Response(
        statusCode: 404,
        body:
            'Swagger UI not found. Please ensure index.html exists in public/swagger/',
      );
    }

    final html = await file.readAsString();
    return Response(
      body: html,
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache',
      },
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: 'Error loading Swagger UI: $e',
    );
  }
}
