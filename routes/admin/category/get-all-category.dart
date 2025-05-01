import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/category_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final categoryController = context.read<CategoryController>();

  try {
    final categories = await categoryController.getAllCategory();

    final result = categories.map((c) => c.toJson()).toList();

    return AppResponse().ok(HttpStatus.ok, result);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
