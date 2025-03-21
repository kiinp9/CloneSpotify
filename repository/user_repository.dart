import 'dart:async';
import 'dart:convert'; // Thư viện decode dữ liệu từ bytes
import 'dart:io';
import 'dart:typed_data';
import 'package:postgres/postgres.dart';
import '../database/postgres.dart';
import '../model/roles.dart';
import '../model/users.dart';
import '../constant/config.message.dart';
import '../exception/config.exception.dart';
import '../constant/config.constant.dart';

abstract class IUserRepo {
  Future<int> saveUser(User user);
  Future<User?> findUserById(int id, {bool showPass = false});
  Future<User?> findUserByEmail(String email, {bool showPass = false});
  Future<User?> findUserByUserName(String userName, {bool showPass = false});
  Future<User?> updateUser(User user);
}

class UserRepository implements IUserRepo {
  UserRepository(this._db);
  final Database _db;

  @override
  Future<int> saveUser(User user) async {
    final existingUser = await findUserByEmail(user.email);
    if (existingUser != null) {
      throw const CustomHttpException(
          ErrorMessage.EMAIL_ALREADY_EXISTS, HttpStatus.badRequest);
    }

    final result = await _db.executor.execute(
      Sql.named('''
    INSERT INTO users (fullName, userName, email, password, gender, birthday, status, roleId, createdAt, updatedAt, GoogleStatus)
    VALUES (@fullName, @userName, @email, @password, @gender, @birthday, @status, @roleId, @createdAt, @updatedAt, @GoogleStatus)
    RETURNING id
  '''),
      parameters: {
        'fullName': user.fullName,
        'userName': user.userName,
        'email': user.email,
        'password': user.password,
        'gender': user.gender.name,
        'birthday': user.birthday?.toIso8601String(),
        'status': user.status ?? 1,
        'roleId': user.roleId,
        'createdAt': user.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updatedAt': user.updatedAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'GoogleStatus': user.GoogleStatus,
      },
    );

    if (result.isEmpty || result.first.isEmpty) {
      throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
    }

    final insertedId = result.first[0];
    if (insertedId == null) {
      throw const CustomHttpException(
          ErrorMessageSQL.SQL_QUERY_ERROR, HttpStatus.internalServerError);
    }

    return insertedId as int;
  }

  @override
  Future<User?> findUserById(int id, {bool showPass = true}) async {
    final result = await _db.executor.execute(
      Sql.named('''
      SELECT u.id, u.fullName, u.userName, u.email, u.password, u.gender, u.birthday, 
             u.status, u.roleId, u.createdAt, u.updatedAt,u.GoogleStatus, 
             r.id as roleId, r.name, r.description, r.createdAt, r.updatedAt
      FROM users u
      LEFT JOIN roles r ON u.roleId = r.id
      WHERE u.id = @id
      LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first;

    final genderEnum = row[5] != null
        ? GenderE.values.byName(_decode(row[5]))
        : GenderE.preferNotToSay;

    return User(
      id: row[0] as int,
      fullName: _decode(row[1]),
      userName: _decode(row[2]),
      email: _decode(row[3]),
      password: showPass ? _decode(row[4]) : '',
      gender: genderEnum,
      birthday: row[6] != null ? DateTime.tryParse(row[6].toString()) : null,
      status: row[7] as int?,
      roleId: row[8] as int?,
      createdAt: row[9] != null ? DateTime.tryParse(row[9].toString()) : null,
      updatedAt: row[10] != null ? DateTime.tryParse(row[10].toString()) : null,
      GoogleStatus: row[11] as int,
      role: row[12] != null
          ? Role(
              id: row[12] as int,
              name: _decode(row[13]),
              description: _decode(row[14]),
              createdAt: row[15] != null
                  ? DateTime.tryParse(row[15].toString())
                  : null,
              updatedAt: row[16] != null
                  ? DateTime.tryParse(row[16].toString())
                  : null,
            )
          : null,
    );
  }

  @override
  Future<User?> findUserByEmail(String email, {bool showPass = false}) async {
    final result = await _db.executor.execute(
      Sql.named('''
      SELECT u.id, u.fullName, u.userName, u.email, u.password, u.gender, u.birthday, 
             u.status, u.roleId, u.createdAt, u.updatedAt,u.GoogleStatus, 
             r.id as roleId, r.name, r.description, r.createdAt, r.updatedAt
      FROM users u
      LEFT JOIN roles r ON u.roleId = r.id
      WHERE u.email = @email
      LIMIT 1
      '''),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;

    final row = result.first;

    final genderEnum = row[5] != null
        ? GenderE.values.byName(_decode(row[5]))
        : GenderE.preferNotToSay;

    return User(
      id: row[0] as int,
      fullName: _decode(row[1]),
      userName: _decode(row[2]),
      email: _decode(row[3]),
      password: showPass ? _decode(row[4]) : '',
      gender: genderEnum,
      birthday: row[6] != null ? DateTime.tryParse(row[6].toString()) : null,
      status: row[7] as int?,
      roleId: row[8] as int?,
      createdAt: row[9] != null ? DateTime.tryParse(row[9].toString()) : null,
      updatedAt: row[10] != null ? DateTime.tryParse(row[10].toString()) : null,
      GoogleStatus: row[11] as int,
      role: row[12] != null
          ? Role(
              id: row[12] as int,
              name: _decode(row[13]),
              description: _decode(row[14]),
              createdAt: row[15] != null
                  ? DateTime.tryParse(row[15].toString())
                  : null,
              updatedAt: row[16] != null
                  ? DateTime.tryParse(row[16].toString())
                  : null,
            )
          : null,
    );
  }

  Future<User?> findUserByUserName(String userName,
      {bool showPass = false}) async {
    final result = await _db.executor.execute(
      Sql.named('''
      SELECT * FROM users u
      LEFT JOIN roles r ON u.roleId = r.id
      WHERE LOWER(u.userName) = LOWER(@userName)
    '''),
      parameters: {'userName': userName},
    );

    if (result.isEmpty) return null;

    final row = result.first;

    final genderEnum = row[5] != null
        ? GenderE.values.byName(_decode(row[5]))
        : GenderE.preferNotToSay;

    return User(
      id: row[0] as int,
      fullName: _decode(row[1]),
      userName: _decode(row[2]),
      email: _decode(row[3]),
      password: showPass ? _decode(row[4]) : '',
      gender: genderEnum,
      birthday: row[6] != null ? DateTime.tryParse(row[6].toString()) : null,
      status: row[7] as int?,
      roleId: row[8] as int?,
      createdAt: row[9] != null ? DateTime.tryParse(row[9].toString()) : null,
      updatedAt: row[10] != null ? DateTime.tryParse(row[10].toString()) : null,
      GoogleStatus: row[11] as int,
      role: row[12] != null
          ? Role(
              id: row[12] as int,
              name: _decode(row[13]),
              description: _decode(row[14]),
              createdAt: row[15] != null
                  ? DateTime.tryParse(row[15].toString())
                  : null,
              updatedAt: row[16] != null
                  ? DateTime.tryParse(row[16].toString())
                  : null,
            )
          : null,
    );
  }

  Future<User?> updateUser(User user, {bool showPass = false}) async {
    final result = await _db.executor.execute(
      Sql.named('''
UPDATE users 
SET fullName = @fullName, gender = @gender, birthday = @birthday,     updatedAt = NOW() AT TIME ZONE 'UTC' + INTERVAL '7 hours'
WHERE id = @id
RETURNING id, fullName, userName, email, password, gender, birthday, status, roleId, createdAt, updatedAt,GoogleStatus
'''),
      parameters: {
        'id': user.id,
        'fullName': user.fullName,
        'gender': user.gender.name,
        'birthday': user.birthday
      },
    );

    if (result.isEmpty) return null;

    final row = result.first;

    final roleResult = await _db.executor.execute(
      Sql.named('''
SELECT id, name, description, createdAt, updatedAt 
FROM roles 
WHERE id = @roleId
'''),
      parameters: {'roleId': row[8]},
    );

    final role = roleResult.isNotEmpty
        ? Role(
            id: roleResult.first[0] as int,
            name: _decode(roleResult.first[1]),
            description: _decode(roleResult.first[2]),
            createdAt: roleResult.first[3] != null
                ? DateTime.tryParse(roleResult.first[3].toString())
                : null,
            updatedAt: roleResult.first[4] != null
                ? DateTime.tryParse(roleResult.first[4].toString())
                : null,
          )
        : null;

    final genderEnum = row.length > 5 && row[5] != null
        ? GenderE.values.byName(_decode(row[5]))
        : GenderE.preferNotToSay;

    return User(
      id: row[0] as int,
      fullName: _decode(row[1]),
      userName: _decode(row[2]),
      email: _decode(row[3]),
      password: showPass ? _decode(row[4]) : '',
      gender: genderEnum,
      birthday: row.length > 6 && row[6] != null
          ? DateTime.tryParse(row[6].toString())
          : null,
      status: row.length > 7 ? row[7] as int? : null,
      roleId: row.length > 8 ? row[8] as int? : null,
      createdAt: row.length > 9 && row[9] != null
          ? DateTime.tryParse(row[9].toString())
          : null,
      updatedAt: row.length > 10 && row[10] != null
          ? DateTime.parse(row[10].toString())
          : null,
      GoogleStatus: row[11] as int,
      role: role,
    );
  }

  Future<User?> updatePassword(int id, String newPassword,
      {bool showPass = false}) async {
    final result = await _db.executor.execute(
      Sql.named('''
      UPDATE users 
      SET password = @password, updatedAt = NOW() AT TIME ZONE 'UTC' + INTERVAL '7 hours'
      WHERE id = @id
      RETURNING id, fullName, userName, email, password, gender, birthday, status, roleId, createdAt, updatedAt
    '''),
      parameters: {'id': id, 'password': newPassword},
    );
    if (result.isEmpty) return null;

    final row = result.first;

    final roleResult = await _db.executor.execute(
      Sql.named('''
      SELECT id, name, description, createdAt, updatedAt 
      FROM roles 
      WHERE id = @roleId
    '''),
      parameters: {'roleId': row[8]},
    );

    if (roleResult.isEmpty) return null;

    final role = Role(
      id: roleResult.first[0] as int,
      name: _decode(roleResult.first[1]),
      description: _decode(roleResult.first[2]),
      createdAt: roleResult.first[3] != null
          ? DateTime.tryParse(roleResult.first[3].toString())
          : null,
      updatedAt: roleResult.first[4] != null
          ? DateTime.tryParse(roleResult.first[4].toString())
          : null,
    );

    final genderEnum = row.length > 5 && row[5] != null
        ? GenderE.values.byName(_decode(row[5]))
        : GenderE.preferNotToSay;

    return User(
      id: row[0] as int,
      fullName: _decode(row[1]),
      userName: _decode(row[2]),
      email: _decode(row[3]),
      password: showPass ? _decode(row[4]) : '',
      gender: genderEnum,
      birthday: row.length > 6 && row[6] != null
          ? DateTime.tryParse(row[6].toString())
          : null,
      status: row.length > 7 ? row[7] as int? : null,
      roleId: row.length > 8 ? row[8] as int? : null,
      createdAt: row.length > 9 && row[9] != null
          ? DateTime.tryParse(row[9].toString())
          : null,
      updatedAt: row.length > 10 && row[10] != null
          ? DateTime.parse(row[10].toString())
          : null,
      GoogleStatus: row[11] as int,
      role: role,
    );
  }

  String _decode(dynamic value) {
    if (value is String) return value;
    if (value is Uint8List) return utf8.decode(value);
    return value.toString();
  }
}
