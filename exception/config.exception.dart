import 'dart:io';

class CustomHttpException implements IOException {

  const CustomHttpException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}
