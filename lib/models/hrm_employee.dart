/// HRM 员工花名册（对接 desktop/hrm/employee-directory）。
class HrmEmployee {
  int? userId;
  String? no;
  String? name;
  String? englishName;
  String? aliasName;
  String? gender;
  String? empStatus;
  String? mobile;
  String? corpEmail;
  String? imAccount;
  List<HrmEmployeeTitle> titleList = const [];
}

class HrmEmployeeTitle {
  String? id;
  String? positionId;
  String? reportPositionId;
  int? reportEmployeeId;
  String? reportEmployeeName;
  String? sysDeptId;
  String? deptName;
  String? postId;
  String? postName;
  int? postOrderNum;
  String? postSeqLevelId;
  String? postSeqLeveName;
  String? postSeqId;
  String? postSeqName;
  int? postSeqLeveOrderNum;
  int? isPrimary;
  String? startDate;
}
