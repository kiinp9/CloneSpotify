import 'package:dbcrypt/dbcrypt.dart';

String genPassword(String plainPassword) {
  // hash and salt string.
  return DBCrypt().hashpw(plainPassword, DBCrypt().gensalt());
}

bool verifyPassword(String plainPassword, String dbPassword) {
  return DBCrypt().checkpw(plainPassword, dbPassword);
}
