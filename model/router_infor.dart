class RouteInfo {
  final String apiPath;
  final String method;
  final String tag;
  final String summary;
  final String description;
  final List<String> pathParams;
  final List<QueryParam> queryParams;
  final List<RequestBodyField> requestBodyFields;
  final bool requiresAuth;

  RouteInfo({
    required this.apiPath,
    required this.method,
    required this.tag,
    required this.summary,
    required this.description,
    required this.pathParams,
    required this.queryParams,
    required this.requestBodyFields,
    required this.requiresAuth,
  });

  @override
  String toString() {
    return 'RouteInfo(method: $method, path: $apiPath, tag: $tag, auth: $requiresAuth)';
  }
}

class QueryParam {
  final String name;
  final String type;
  final bool required;
  final dynamic defaultValue;
  final dynamic example;
  final String? description;

  QueryParam({
    required this.name,
    required this.type,
    required this.required,
    this.defaultValue,
    this.example,
    this.description,
  });
}

class RequestBodyField {
  final String name;
  final String type;
  final bool required;
  final dynamic example;
  final String? description;

  RequestBodyField({
    required this.name,
    required this.type,
    required this.required,
    this.example,
    this.description,
  });
}
