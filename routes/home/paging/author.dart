import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/author_controller.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse().error(
      HttpStatus.methodNotAllowed,
      ErrorMessage.MSG_METHOD_NOT_ALLOW,
    );
  }
  final authorController = context.read<AuthorController>();
  final offset =
      int.tryParse(context.request.uri.queryParameters['offset'] ?? '0') ?? 0;
  final limit =
      int.tryParse(context.request.uri.queryParameters['limit'] ?? '8') ?? 8;
  try {
    final authors =
        await authorController.showAuthorPaging(offset: offset, limit: limit);
    final authorJson = authors.map((author) {
      return {
        'id': author.id,
        'name': author.name,
        'avatarUrl': author.avatarUrl,
      };
    }).toList();
    return AppResponse().ok(HttpStatus.ok, {'author': authorJson});
  } catch (e) {
    return AppResponse().error(
      HttpStatus.internalServerError,
      e.toString(),
    );
  }
}
