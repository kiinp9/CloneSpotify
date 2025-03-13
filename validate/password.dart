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
