import 'dart:async';
import 'dart:io';
import '../constant/config.message.dart';
import '../model/users.dart';
import '../security/password.security.dart';
import '../validate/email.dart';
import '../validate/password.dart';
import '../repository/user_repository.dart';
import '../exception/config.exception.dart';
import '../validate/strings.dart';
import '../security/jwt.security.dart';

class UserController {
  UserController(this._userRepository, this._jwtService);
  final JwtService _jwtService;
  final UserRepository _userRepository;
  Future<User> Login(String? identifier, String password) async {
    try {
      if (isNullOrEmpty(identifier)) {
        throw const CustomHttpException(
            ErrorMessage.EMAIL_OR_USERNAME_REQUIRED, HttpStatus.badRequest);
      }
      if (isNullOrEmpty(password)) {
        throw const CustomHttpException(
            ErrorMessage.PASSWORD_REQUIRED, HttpStatus.badRequest);
      }
      //if (!isValidPassword(password)) {
      //throw const CustomHttpException(
      // ErrorMessage.PASSWORD_IS_NOT_LONG_ENOUGH, HttpStatus.badRequest);
      //}

      User? userDb;
      if (isValidEmail(identifier)) {
        userDb =
            await _userRepository.findUserByEmail(identifier!, showPass: true);
      } else {
        userDb = await _userRepository.findUserByUserName(identifier!,
            showPass: true);
      }

      if (userDb == null || userDb.password == null) {
        throw const CustomHttpException(
            ErrorMessage.USER_NOT_FOUND, HttpStatus.notFound);
      }

      if (!verifyPassword(password, userDb.password!)) {
        throw const CustomHttpException(
            ErrorMessage.PASSWORD_INCORRECT, HttpStatus.badRequest);
      }

      // ignore: join_return_with_assignment
      userDb = userDb.copyWith();
      return userDb;
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }

      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }
  }

  Future<User> Register(User user) async {
    final completer = Completer<User>();
    final errMsgList = <String>[];

    if (!isValidEmail(user.email)) {
      errMsgList.add(ErrorMessage.EMAIL_INVALID);
    }
    if (isNullOrEmpty(user.fullName)) {
      errMsgList.add(ErrorMessage.FULL_NAME_REQUIRED);
    }
    if (isNullOrEmpty(user.password)) {
      errMsgList.add(ErrorMessage.PASSWORD_REQUIRED);
    }
    if (!isValidPassword(user.password)) {
      errMsgList.add(ErrorMessage.PASSWORD_IS_NOT_LONG_ENOUGH);
    }
    if (!isStrongPassword(user.password)) {
      errMsgList.add(ErrorMessage.PASSWORD_INVALID);
    }

    if (errMsgList.isNotEmpty) {
      final errors = errMsgList.join('; ');
      return Future.error(CustomHttpException(errors, HttpStatus.badRequest));
    }
    try {
      user.password = genPassword(user.password!);
      final result = await _userRepository.saveUser(user);
      if (result > 0) {
        if (user.email == null) {
          throw const CustomHttpException(
              ErrorMessage.EMAIL_REQUIRED, HttpStatus.badRequest);
        }
        final userDb = await _userRepository.findUserByEmail(user.email!);

        final token = _jwtService.generateTokenJwt(userDb!);
        completer.complete(userDb);
      }
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }
      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }

    return completer.future;
  }

  Future<User?> findUserById(int id, {bool showPass = false}) async {
    final user = await _userRepository.findUserById(id, showPass: showPass);

    return user;
  }

  Future<User?> findUserByEmail(String email, {bool showPass = false}) async {
    final user =
        await _userRepository.findUserByEmail(email, showPass: showPass);

    return user;
  }

  Future<User?> updateUser(User user) async {
    final updatedUser = await _userRepository.updateUser(user);
    return updatedUser;
  }

  Future<void> resetPassword(int id, String currentPassword, String newPassword,
      String confirmPassword) async {
    final completer = Completer<void>();
    final errMsgList = <String>[];

    if (isNullOrEmpty(currentPassword)) {
      errMsgList.add(ErrorMessage.REQUIRED);
    }
    if (isNullOrEmpty(newPassword)) {
      errMsgList.add(ErrorMessage.REQUIRED);
    }
    if (isNullOrEmpty(confirmPassword)) {
      errMsgList.add(ErrorMessage.REQUIRED);
    }
    if (!isValidPassword(newPassword)) {
      errMsgList.add(ErrorMessage.PASSWORD_IS_NOT_LONG_ENOUGH);
    }
    if (!isStrongPassword(newPassword)) {
      errMsgList.add(ErrorMessage.PASSWORD_INVALID);
    }
    if (newPassword != confirmPassword) {
      errMsgList.add(ErrorMessage.PASSWORDS_DO_NOT_MATCH);
    }
    if (currentPassword == newPassword) {
      errMsgList.add(ErrorMessage.PASSWORD_CANNOT_BE_THE_SAME);
    }

    if (errMsgList.isNotEmpty) {
      final errors = errMsgList.join('; ');
      return Future.error(CustomHttpException(errors, HttpStatus.badRequest));
    }

    try {
      final userDb = await _userRepository.findUserById(id);
      if (userDb == null) {
        throw CustomHttpException(
            ErrorMessage.USER_NOT_FOUND, HttpStatus.notFound);
      }
      if (!verifyPassword(currentPassword, userDb.password!)) {
        throw CustomHttpException(
            ErrorMessage.OLD_PASSWORD_INCORRECT, HttpStatus.badRequest);
      }

      await _userRepository.updatePassword(id, genPassword(newPassword));

      completer.complete();
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }
      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }

    return completer.future;
  }

  Future<User> registerGoogleUser(User user) async {
    final completer = Completer<User>();
    final errMsgList = <String>[];

    if (!isValidEmail(user.email)) {
      errMsgList.add(ErrorMessage.EMAIL_INVALID);
    }

    if (errMsgList.isNotEmpty) {
      return Future.error(
          CustomHttpException(errMsgList.join('; '), HttpStatus.badRequest));
    }

    try {
      final existingUser = await _userRepository.findUserByEmail(user.email);
      if (existingUser != null) {
        throw const CustomHttpException(
            ErrorMessage.EMAIL_ALREADY_EXISTS, HttpStatus.badRequest);
      }

      user.password = null;
      final result = await _userRepository.saveUser(user);

      if (result <= 0) {
        throw const CustomHttpException(
            ErrorMessageSQL.SAVE_USER_FAILED, HttpStatus.internalServerError);
      }

      final userDb = await _userRepository.findUserByEmail(user.email);
      if (userDb == null) {
        throw const CustomHttpException(
            ErrorMessage.USER_NOT_FOUND, HttpStatus.internalServerError);
      }

      completer.complete(userDb);
    } catch (e) {
      if (e is CustomHttpException) {
        return Future.error(e);
      }
      return Future.error(CustomHttpException(
          "Lỗi máy chủ: ${e.toString()}", HttpStatus.internalServerError));
    }

    return completer.future;
  }
}
