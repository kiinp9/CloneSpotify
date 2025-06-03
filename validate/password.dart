import '../constant/config.constant.dart';
import 'strings.dart';

bool isValidPassword(String? pass) {
  if (isNullOrEmpty(pass)) {
    return false;
  }

  if (pass!.length < AuthRequire.lengthPass) {
    return false;
  }
  return true;
}

bool isStrongPassword(String? pass) {
  final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$',);

  if (!regex.hasMatch(pass!)) {
    return false;
  }

  return true;
}
