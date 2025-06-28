import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../../model/router_infor.dart';

class RouteContentAnalyzer extends GeneralizingAstVisitor<void> {
  final String fileContent;
  final Set<String> detectedMethods = <String>{};
  final List<QueryParam> queryParams = [];
  final List<RequestBodyField> requestBodyFields = [];
  bool hasAuthCheck = false;

  RouteContentAnalyzer(this.fileContent);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name.toLowerCase();

    // Detect HTTP methods
    if (_httpMethods.contains(methodName)) {
      detectedMethods.add(methodName.toUpperCase());
    }

    // Detect methods on 'request'
    if (node.target?.toString() == 'request') {
      switch (methodName) {
        case 'method':
          _analyzeRequestMethod(node);
          break;
        case 'query':
          _analyzeQueryParams(node);
          break;
        case 'json':
          _analyzeRequestBody();
          break;
        case 'headers':
          _checkAuthHeaders(node);
          break;
      }
    }

    // Detect auth usage
    if (methodName.contains('auth')) {
      hasAuthCheck = true;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    final condition = node.expression.toString().toLowerCase();
    if (_authKeywords.any(condition.contains)) {
      hasAuthCheck = true;
    }
    super.visitIfStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (node.expression.toString().contains('method')) {
      for (final switchCase in node.members.whereType<SwitchCase>()) {
        final caseValue = switchCase.expression
            .toString()
            .replaceAll(RegExp(r'''["']'''), '')
            .toUpperCase();
        if (_httpMethodsUpper.contains(caseValue)) {
          detectedMethods.add(caseValue);
        }
      }
    }
    super.visitSwitchStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer?.toString() ?? '';

    if (initializer.contains('request.query')) {
      _extractQueryParamFromVariable(node.name.lexeme, initializer);
    }

    if (initializer.contains('request.json') || initializer.contains('body')) {
      _extractBodyFieldFromVariable(node.name.lexeme, initializer);
    }

    super.visitVariableDeclaration(node);
  }

  void _analyzeRequestMethod(MethodInvocation node) {
    final parent = node.parent;
    if (parent is IfStatement) {
      final condition = parent.expression.toString();
      for (final method in _httpMethodsUpper) {
        if (condition.contains("'$method'") ||
            condition.contains('"$method"')) {
          detectedMethods.add(method);
        }
      }
    }
  }

  void _analyzeQueryParams(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.isNotEmpty && args.first is StringLiteral) {
      final paramName = (args.first as StringLiteral).stringValue ?? '';
      if (paramName.isNotEmpty) {
        queryParams.add(QueryParam(
          name: paramName,
          type: 'string',
          required: false,
          description: 'Query parameter $paramName',
        ));
      }
    }
  }

  void _checkAuthHeaders(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.isNotEmpty && args.first is StringLiteral) {
      final headerName =
          (args.first as StringLiteral).stringValue?.toLowerCase() ?? '';
      if (_authKeywords.any(headerName.contains)) {
        hasAuthCheck = true;
      }
    }
  }

  void _extractQueryParamFromVariable(String varName, String initializer) {
    for (final entry in _commonParams.entries) {
      if (varName.toLowerCase().contains(entry.key) ||
          initializer.contains("'${entry.key}'") ||
          initializer.contains('"${entry.key}"')) {
        if (!queryParams.any((p) => p.name == entry.value.name)) {
          queryParams.add(entry.value);
        }
      }
    }
  }

  void _extractBodyFieldFromVariable(String varName, String initializer) {
    for (final entry in _commonFields.entries) {
      if (varName.toLowerCase().contains(entry.key) ||
          initializer.contains("'${entry.key}'") ||
          initializer.contains('"${entry.key}"')) {
        if (!requestBodyFields.any((f) => f.name == entry.value.name)) {
          requestBodyFields.add(entry.value);
        }
      }
    }
  }

  void _analyzeRequestBody() {
    final List<String> lines = fileContent.split('\n');
    final List<RegExp> patterns = [
      RegExp(r"body\[['\" "](\w+)['\"]\]"),
      RegExp(r"json\[['\" "](\w+)['\"]\]"),
      RegExp(r"data\[['\" "](\w+)['\"]\]"),
      RegExp(r"request\.json\(\)\[['\" "](\w+)['\"]\]"),
    ];

    for (final String line in lines) {
      for (final RegExp pattern in patterns) {
        final Iterable<RegExpMatch> matches = pattern.allMatches(line);
        for (final RegExpMatch match in matches) {
          final String? fieldName = match.group(1);
          if (fieldName != null &&
              fieldName.isNotEmpty &&
              !requestBodyFields
                  .any((RequestBodyField f) => f.name == fieldName)) {
            requestBodyFields.add(RequestBodyField(
              name: fieldName,
              type: _inferFieldType(fieldName),
              required: _isFieldRequired(fieldName),
              example: _getFieldExample(fieldName),
            ));
          }
        }
      }
    }

    if (fileContent.contains('offset') ||
        fileContent.contains('limit') ||
        fileContent.contains('page')) {
      _addPaginationParams();
    }
  }

  String _inferFieldType(String fieldName) {
    if (_intFields.any((f) => fieldName.toLowerCase().contains(f)))
      return 'integer';
    if (_boolFields.any((f) => fieldName.toLowerCase().contains(f)))
      return 'boolean';
    if (_dateFields.any((f) => fieldName.toLowerCase().contains(f)))
      return 'string';
    return 'string';
  }

  bool _isFieldRequired(String fieldName) {
    return _requiredFields.contains(fieldName);
  }

  String? _getFieldExample(String fieldName) {
    return _examples[fieldName];
  }

  void _addPaginationParams() {
    for (final param in _paginationParams) {
      if (!queryParams.any((p) => p.name == param.name)) {
        queryParams.add(param);
      }
    }
  }

  // === Static/shared values ===

  static const _httpMethods = [
    'get',
    'post',
    'put',
    'patch',
    'delete',
    'head',
    'options'
  ];
  static const _httpMethodsUpper = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS'
  ];

  static const _authKeywords = ['auth', 'token', 'jwt', 'bearer'];

  static const _intFields = [
    'id',
    'age',
    'count',
    'limit',
    'offset',
    'page',
    'duration'
  ];
  static const _boolFields = ['ispublic', 'isactive', 'enabled', 'verified'];
  static const _dateFields = ['date', 'time', 'birthday', 'created', 'updated'];

  static const _requiredFields = [
    'email',
    'password',
    'title',
    'name',
    'id',
    'authorId'
  ];

  static const _examples = {
    'email': 'user@example.com',
    'password': 'mypassword',
    'title': 'Title Example',
    'description': 'Description example',
    'name': 'Name Example',
    'id': 'id-123',
    'authorId': 'author-id-123',
    'albumId': 'album-id-123',
    'categoryId': 'category-id-123',
    'musicId': 'music-id-123',
    'playlistId': 'playlist-id-123',
  };

  static final _commonParams = {
    'offset': QueryParam(
        name: 'offset', type: 'integer', required: false, defaultValue: 0),
    'limit': QueryParam(
        name: 'limit', type: 'integer', required: false, defaultValue: 10),
    'page': QueryParam(
        name: 'page', type: 'integer', required: false, defaultValue: 1),
    'search': QueryParam(name: 'search', type: 'string', required: false),
    'filter': QueryParam(name: 'filter', type: 'string', required: false),
    'sort': QueryParam(name: 'sort', type: 'string', required: false),
    'order': QueryParam(name: 'order', type: 'string', required: false),
  };

  static final _commonFields = {
    'email': RequestBodyField(
        name: 'email',
        type: 'string',
        required: true,
        example: 'user@example.com'),
    'password': RequestBodyField(
        name: 'password',
        type: 'string',
        required: true,
        example: 'mypassword'),
    'title': RequestBodyField(
        name: 'title', type: 'string', required: true, example: 'Title'),
    'description': RequestBodyField(
        name: 'description',
        type: 'string',
        required: false,
        example: 'Description'),
    'name': RequestBodyField(
        name: 'name', type: 'string', required: true, example: 'Name'),
    'id': RequestBodyField(
        name: 'id', type: 'string', required: true, example: 'id-123'),
  };

  static final _paginationParams = [
    QueryParam(
        name: 'offset',
        type: 'integer',
        required: false,
        defaultValue: 0,
        description: 'Số lượng bản ghi bỏ qua'),
    QueryParam(
        name: 'limit',
        type: 'integer',
        required: false,
        defaultValue: 10,
        description: 'Số lượng bản ghi tối đa trả về'),
    QueryParam(
        name: 'page',
        type: 'integer',
        required: false,
        defaultValue: 1,
        description: 'Số trang'),
  ];
}
