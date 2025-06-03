import '../constant/config.constant.dart';
import 'roles.dart';

class User {
  User({
    required this.email, this.id,
    this.fullName,
    this.userName,
    this.password,
    this.gender = GenderE.preferNotToSay,
    this.birthday,
    this.status = 1,
    this.roleId,
    this.createdAt,
    this.updatedAt,
    this.GoogleStatus,
    this.role,
  });

  int? id;
  String? fullName;
  String? userName;
  String email;
  String? password;
  int? status;
  int? roleId;
  DateTime? createdAt;
  DateTime? updatedAt;
  Role? role;
  GenderE gender;
  DateTime? birthday;
  int? GoogleStatus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'password': password,
        'gender': gender.name,
        'status': status,
        'roleId': roleId,
        'birthday': birthday?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'GoogleStatus': GoogleStatus,
        'role': role?.toJson(),
      };
  User copyWith({
    String? fullName,
    GenderE? gender,
    DateTime? birthday,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      userName: userName,
      email: email,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      status: status,
      roleId: roleId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      GoogleStatus: GoogleStatus,
      role: role,
    );
  }

  @override
  String toString() {
    return '''
  {id= $id, fullName= $fullName, userName= $userName,email =$email,password= $password, status =$status,roleId=$roleId,createdAt= $createdAt,updatedAt= $updatedAt, role= $role,gender= ${gender.name}, birthday = $birthday, GoogleStatus= $GoogleStatus}''';
  }
}
