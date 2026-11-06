import 'hrm_employee.dart';
import 'hrm_employee_contract.dart';

/// HRM 员工档案行（对接 desktop/hrm/employee 分页列表及详情 `HrmEmployeeVo` / `V2`）。
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
  /// 转正状态：NOT_REQUIRED / PENDING / CONVERTED。
  String? conversionStatus;
  /// FULL_TIME / PART_TIME
  String? timeType;
  String? hireDate;
  /// 预计转正日期。
  String? regularizationDate;
  String? leaveDate;
  String? leaveType;
  String? leaveRemark;

  String? birthDate;
  String? nation;
  String? province;
  String? city;
  String? district;
  String? householdAddress;
  String? residence;
  String? politicalStatus;
  String? maritalStatus;
  String? firstWorkDate;
  String? socialSecurityAccount;
  String? housingFundAccount;
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
  String? businessTripCity;

  /// 合同与协议（详情接口 `contracts` 回填）。
  List<HrmEmployeeContract> contracts = [];

  /// 在任头衔（列表 `HrmEmployeeVoV2.titleList`）。
  List<HrmEmployeeTitle> titleList = const [];

  /// 主岗头衔；无主岗时取列表首项。
  HrmEmployeeTitle? get primaryTitle {
    for (final t in titleList) {
      if (t.isPrimary == 1) return t;
    }
    return titleList.isEmpty ? null : titleList.first;
  }
}

/// 员工分页结果：`GET /desktop/hrm/employee`。
class HrmEmployeesPage {
  const HrmEmployeesPage({required this.total, required this.rows});

  final int total;
  final List<HrmEmployeeProfile> rows;
}

/// 员工统计：`GET /desktop/hrm/employee/stats` → `HrmEmployeeStatsVo`。
class HrmEmployeeStats {
  int totalCount = 0;
  int activeCount = 0;
  int probationCount = 0;
  int pendingActiveCount = 0;
  String? nearestPendingHireDate;
  int leaveCount = 0;
  int monthHireCount = 0;
  int lastMonthHireCount = 0;
  int monthLeaveCount = 0;
  int monthLeaveVoluntaryCount = 0;
  int monthLeaveInvoluntaryCount = 0;
  int monthLeaveOtherCount = 0;
  int contractExpiringCount = 0;
  int contractExpiringDays = 90;
}

/// 待入职统计：`GET /desktop/hrm/employee/stats/pending-active`。
class HrmEmployeePendingActiveStats {
  int totalCount = 0;
  int todayCount = 0;
  int monthCount = 0;
}

/// 待转正统计：`GET /desktop/hrm/employee/stats/pending-regularization`。
class HrmEmployeePendingRegularizationStats {
  int totalCount = 0;
  int overdueCount = 0;
  int monthCount = 0;
  int nextMonthCount = 0;
}
