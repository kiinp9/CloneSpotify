import 'dart:io';

class CustomHttpException implements IOException {
  final String message;
  final int statusCode;

  const CustomHttpException(this.message, this.statusCode);

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}
