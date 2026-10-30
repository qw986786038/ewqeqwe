/// HRM 员工紧急联系人（`HrmEmployeeContactVo`）。
class HrmEmployeeContact {
  String? id;
  /// 接口字段 `employeeUserId`（兼容旧 `userId`）。
  int? userId;
  String? name;
  String? relation;
  /// 联系电话（接口 `mobile`）。
  String? phone;
  /// 是否主要联系人（接口 `isPrimary`：0 / 1）。
  String? isPrimary;
  int? orderNum;
}
