import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class UserEntity {
  int? id;
  String? username;
  String? name;
  String? mobile;
  int? user_type;
  int? gender;
  String? email;
  String? avatar;
  int? dept;
  bool? is_superuser;
  List<int>? role;
  int? pwd_change_count;
  DeptInfoEntity? dept_info;
  List<RoleInfoEntity>? role_info;

  /// 登录响应可能返回
  String? refresh;
  String? access;
  int? userId;

  /// 登录请求用，响应体通常不包含
  String? captcha;
  int? captchaKey;
  String? password;
}

@jsonSerializable
class DeptInfoEntity {
  int? dept_id;
  String? dept_name;
}

@jsonSerializable
class RoleInfoEntity {
  int? id;
  String? name;
  String? key;
}
