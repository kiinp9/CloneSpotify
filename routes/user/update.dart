import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../constant/config.constant.dart';
import '../../constant/config.message.dart';
import '../../controllers/user_controller.dart';
import '../../model/response.dart';
import '../../model/users.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method.value != 'PATCH') {
    return AppResponse()
        .error(HttpStatus.methodNotAllowed, ErrorMessage.MSG_METHOD_NOT_ALLOW);
  }

  // Lấy user từ middleware
  final user = context.read<User?>();
  if (user == null) {
    return AppResponse().error(HttpStatus.unauthorized, 'User not found.');
  }

  try {
    // Lấy body request
    final body = await context.request.body();
    final data = jsonDecode(body);

    // Tạo user mới với dữ liệu cập nhật
    final updatedUser = user.copyWith(
      fullName: data['fullName'] as String?,
      gender: data['gender'] != null
          ? GenderE.values.byName(data['gender'].toString())
          : user.gender,
      birthday: data['birthday'] != null
          ? DateTime.tryParse(data['birthday'].toString())
          : user.birthday,
    );

    // Gọi UserController để cập nhật user
    final userController = context.read<UserController>();
    final result = await userController.updateUser(updatedUser);

    if (result == null) {
      return AppResponse().error(HttpStatus.notFound, 'User update failed.');
    }

    return AppResponse().ok(HttpStatus.ok, result.toJson());
  } catch (e) {
    return AppResponse().error(HttpStatus.internalServerError, e.toString());
  }
}
