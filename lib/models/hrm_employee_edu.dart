/// HRM 员工教育经历（`HrmEmployeeEduVo`）。
class HrmEmployeeEdu {
  String? id;
  /// 接口字段 `employeeUserId`。
  int? userId;
  String? startDate;
  String? endDate;
  String? school;
  String? major;
  /// 学历（接口 `education`：大专 / 本科 / 硕士 / 博士 / 其他）。
  String? degree;
  /// 是否最高学历（接口 `isHighest`：0 / 1）。
  int? isHighest;
}
