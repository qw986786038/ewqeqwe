import 'hrm_employee_contract.dart';

/// HRM 员工档案行（对接 desktop/hrm/employee 分页列表及详情 `HrmEmployeeVo`）。
class HrmEmployeeProfile {
  String? id;
  int? userId;
  String? no;
  String? name;
  String? pinYin;
  String? englishName;
  String? aliasName;
  String? gender;
  String? mobile;
  String? corpEmail;
  String? empStatus;
  String? empType;
  /// FULL_TIME / PART_TIME
  String? timeType;

  String? birthDate;
  String? nation;
  String? province;
  String? city;
  String? district;
  String? householdAddress;
  String? residence;
  String? politicalStatus;
  String? maritalStatus;
  String? idCardType;
  String? idCardNo;
  String? highestEducation;
  String? graduateSchool;
  String? major;
  String? personalEmail;
  String? imAccount;
  String? officePhone;
  String? officeExt;
  String? officeLocation;
  String? officeLocationName;
  String? workstation;
  int? showMobile;
  int? showEmail;
  int? showIm;
  int? showOffice;
  int? keepInDirectory;
  int? overtime;
  String? commonLanguage;
  String? dispatchCity;
  String? businessTrip;

  /// 合同与协议（详情接口 `contracts` 回填）。
  List<HrmEmployeeContract> contracts = [];
}

/// 员工分页结果：`GET /desktop/hrm/employee`。
class HrmEmployeesPage {
  const HrmEmployeesPage({required this.total, required this.rows});

  final int total;
  final List<HrmEmployeeProfile> rows;
}
