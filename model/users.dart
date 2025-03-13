import 'roles.dart';
import '../constant/config.constant.dart';

class User {
  User({
    this.id,
    this.fullName,
    this.userName,
    required this.email,
    this.password,
    this.gender = GenderE.preferNotToSay,
    this.birthday,
    this.status = 1,
    this.roleId,
    this.createdAt,
    this.updatedAt,
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

  /// ✅ **Đã sửa lỗi `gender`**
  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'password': password,
        'gender': gender.name, // ✅ Chỉ lấy giá trị của user hiện tại
        'status': status,
        'roleId': roleId,
        'birthday': birthday?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'role': role?.toJson(),
      };

  @override
  String toString() {
    return '''
  {id= $id, fullName= $fullName, userName= $userName,email =$email,password= $password, status =$status,roleId=$roleId,createdAt= $createdAt,updatedAt= $updatedAt, role= $role,gender= ${gender.name}, birthday = $birthday}''';
  }
}
