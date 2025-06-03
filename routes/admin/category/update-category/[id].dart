import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../constant/config.message.dart';
import '../../../../controllers/category_controller.dart';
import '../../../../exception/config.exception.dart';

import '../../../../model/response.dart';
import '../../../../model/users.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }
  final categoryController = context.read<CategoryController>();
  final user = context.read<User?>();
  if (user == null || user.role?.name != 'admin') {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }

  final categoryId = int.tryParse(context.request.uri.pathSegments.last);
  if (categoryId == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_CATEGORY_ID);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final updateFields = <String, dynamic>{};

    if (body.containsKey('name')) {
      updateFields['name'] = body['name'].toString();
    }

    if (body.containsKey('description')) {
      updateFields['description'] = body['description'].toString();
    }

    if (updateFields.isEmpty) {
      return AppResponse()
          .error(HttpStatus.badRequest, ErrorMessage.EMPTY_FIELD);
    }

    final result =
        await categoryController.updateCategory(categoryId, updateFields);

    return AppResponse().ok(HttpStatus.ok, result.toJson());
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
