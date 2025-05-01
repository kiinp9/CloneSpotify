import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/category_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/category.dart';
import '../../../model/response.dart';
import '../../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'POST') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  final categoryController = context.read<CategoryController>();
  final user = context.read<User?>();
  if (user == null || user.role?.name != 'admin') {
    return AppResponse().error(HttpStatus.forbidden, ErrorMessage.FORBIDDEN);
  }
  final body = await context.request.json();
  final imagePath = body['imageCategoryPath']?.toString();
  if (imagePath == null) {
    return AppResponse()
        .error(HttpStatus.badRequest, ErrorMessage.INVALID_MUSIC_OR_IMAGE_FILE);
  }
  try {
    final category = Category(
      name: body['name'].toString(),
      description: body['description'].toString(),
      imageUrl: imagePath,
    );
    await categoryController.createCategory(category, imagePath);

    return AppResponse().success(HttpStatus.ok);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
