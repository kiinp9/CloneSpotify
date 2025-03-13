import 'dart:io';

class HttpException implements IOException {
  final String message;
  final int statusCode;

  const HttpException(this.message, this.statusCode);

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}
