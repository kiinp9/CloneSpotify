import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../constant/config.message.dart';
import '../../../controllers/search_controller.dart';
import '../../../exception/config.exception.dart';
import '../../../model/response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'GET') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  try {
    final searchController = context.read<SearchController>();
    final body = await context.request.json();

    final query = body['query'] as String?;

    if (query == null || query.trim().isEmpty) {
      return AppResponse()
          .error(HttpStatus.badRequest, ErrorMessage.MISSING_QUERY_PARAM);
    }

    final searchResults = await searchController.search(query);

    return AppResponse().ok(HttpStatus.ok, searchResults);
  } catch (e) {
    if (e is CustomHttpException) {
      return AppResponse().error(e.statusCode, e.message);
    }
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
