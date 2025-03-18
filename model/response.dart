import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

class AppResponse {
  Response ok(int status, dynamic data) {
    return Response(
      statusCode: status,
      body: jsonEncode(
          {'status_code': status, 'message': 'success', 'data': data}),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
  }

  Response success(int status) {
    return Response(
      statusCode: status,
      body: jsonEncode({'status_code': status, 'message': 'success'}),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
  }

  Response error(int status, String message) {
    return Response(
      statusCode: status,
      body: jsonEncode({
        'status_code': status,
        'message': message,
      }),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
  }
}
