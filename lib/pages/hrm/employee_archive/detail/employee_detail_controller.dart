import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee_assign.dart';
import '../../../../models/hrm_employee_contact.dart';
import '../../../../models/hrm_employee_contract.dart';
import '../../../../models/hrm_employee_edu.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_employee_work.dart';
import '../../../../models/hrm_office_location.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../services/hrm_api.dart';

/// 人事档案详情 Tab。
enum EmployeeDetailTab {
  overview,
  basic,
  assign,
  contract,
  salary,
  onboarding,
  promotion,
  sales,
  directory,
  attachment,
  oplog,
}

extension EmployeeDetailTabX on EmployeeDetailTab {
  String get label => switch (this) {
        EmployeeDetailTab.overview => '概览',
        EmployeeDetailTab.basic => '基础信息',
        EmployeeDetailTab.assign => '任职组织',
        EmployeeDetailTab.contract => '合同信息',
        EmployeeDetailTab.salary => '薪资与档案',
        EmployeeDetailTab.onboarding => '入职登记表',
        EmployeeDetailTab.promotion => '晋升与职级',
        EmployeeDetailTab.sales => '销售/订单与客户',
        EmployeeDetailTab.directory => '通讯录展示',
        EmployeeDetailTab.attachment => '附件',
        EmployeeDetailTab.oplog => '操作日志',
      };
}

/// 人事档案 · 详情（只读展示；编辑走独立编辑页）。
class EmployeeDetailController extends LxController {
  EmployeeDetailController(this.employeeId);

  /// 员工主键，详情走 `GET /desktop/hrm/employee/{id}`。
  final String employeeId;
  final _api = HrmApi();

  final loading = true.obs;
  final errorMessage = Rxn<String>();
  final tab = EmployeeDetailTab.overview.obs;

  final profile = Rxn<HrmEmployeeProfile>();
  final contacts = <HrmEmployeeContact>[].obs;
  final educations = <HrmEmployeeEdu>[].obs;
  final workExperiences = <HrmEmployeeWork>[].obs;
  final contracts = <HrmEmployeeContract>[].obs;

  /// 当前员工在任（从全量 on-duty 过滤）。
  final assigns = <HrmEmployeeAssign>[].obs;

  final officeLocations = <HrmOfficeLocation>[].obs;
  final Map<String, HrmPosition> positionById = {};
  final Map<String, HrmPost> postById = {};
  final Map<String, HrmPostSeqLevel> levelById = {};
  final Map<String, String> deptNameById = {};
  final Map<int, String> employeeNameByUserId = {};
  final Map<String, HrmEmployeeAssign> assignByPositionId = {};

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final id = employeeId.trim();
      if (id.isEmpty) {
        throw HrmApiException('员工 id 不能为空');
      }
      final p = await _api.fetchEmployeeById(id);
      final uid = p.userId;
      final results = await Future.wait([
        _api.fetchEmployeeContacts(id),
        _api.fetchEmployeeEducations(id),
        _api.fetchEmployeeWorkExperiences(id),
        _api.fetchEmployeeContracts(id),
        _api.fetchOnDutyAssigns(),
        _api.fetchOfficeLocations(),
        _api.fetchPositions(),
        _api.fetchPosts(),
        _api.fetchPostSeqLevels(),
        _api.fetchDepts(),
        _api.fetchEmployeeProfiles(pageNum: 1, pageSize: 10000),
      ]);

      profile.value = p;
      contacts
        ..clear()
        ..addAll(results[0] as List<HrmEmployeeContact>);
      educations
        ..clear()
        ..addAll(results[1] as List<HrmEmployeeEdu>);
      workExperiences
        ..clear()
        ..addAll(results[2] as List<HrmEmployeeWork>);
      final nested = p.contracts;
      final fromApi = results[3] as List<HrmEmployeeContract>;
      contracts
        ..clear()
        ..addAll(nested.isNotEmpty ? nested : fromApi);

      officeLocations
        ..clear()
        ..addAll(results[5] as List<HrmOfficeLocation>);

      final positions = results[6] as List<HrmPosition>;
      final posts = results[7] as List<HrmPost>;
      final levels = results[8] as List<HrmPostSeqLevel>;
      final depts = results[9] as List<HrmDept>;
      final employees = results[10] as List<HrmEmployeeProfile>;

      positionById
        ..clear()
        ..addEntries([
          for (final p in positions)
            if (p.id?.trim().isNotEmpty == true) MapEntry(p.id!.trim(), p),
        ]);
      postById
        ..clear()
        ..addEntries([
          for (final p in posts)
            if (p.id?.trim().isNotEmpty == true) MapEntry(p.id!.trim(), p),
        ]);
      levelById
        ..clear()
        ..addEntries([
          for (final l in levels)
            if (l.id?.trim().isNotEmpty == true) MapEntry(l.id!.trim(), l),
        ]);
      deptNameById
        ..clear()
        ..addEntries([
          for (final d in depts)
            if (d.deptId?.trim().isNotEmpty == true)
              MapEntry(d.deptId!.trim(), (d.deptName ?? '').trim()),
        ]);
      employeeNameByUserId
        ..clear()
        ..addEntries([
          for (final e in employees)
            if (e.userId != null && e.name?.trim().isNotEmpty == true)
              MapEntry(e.userId!, e.name!.trim()),
        ]);

      final onDuty = results[4] as List<HrmEmployeeAssign>;
      assignByPositionId
        ..clear()
        ..addEntries([
          for (final a in onDuty)
            if (a.positionId?.trim().isNotEmpty == true)
              MapEntry(a.positionId!.trim(), a),
        ]);
      assigns
        ..clear()
        ..addAll([
          for (final a in onDuty)
            if (a.employeeUserId == uid) a,
        ]);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void selectTab(EmployeeDetailTab value) => tab.value = value;

  HrmEmployeeAssign? get primaryAssign {
    for (final a in assigns) {
      if (a.isPrimary == 1) return a;
    }
    return assigns.isEmpty ? null : assigns.first;
  }

  String? officeLocationLabel() {
    final p = profile.value;
    final name = p?.officeLocationName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = p?.officeLocation?.trim();
    if (id == null || id.isEmpty) return null;
    for (final loc in officeLocations) {
      if (loc.id?.toString() == id) {
        final n = loc.name?.trim();
        if (n != null && n.isNotEmpty) return n;
      }
    }
    return null;
  }

  String? assignDeptName(HrmEmployeeAssign a) {
    final pos = positionById[a.positionId?.trim() ?? ''];
    final fromPos = pos?.deptName?.trim();
    if (fromPos != null && fromPos.isNotEmpty) return fromPos;
    final deptId = pos?.sysDeptId?.trim();
    if (deptId == null || deptId.isEmpty) return null;
    final n = deptNameById[deptId];
    return (n != null && n.isNotEmpty) ? n : null;
  }

  String? assignPostName(HrmEmployeeAssign a) {
    final pos = positionById[a.positionId?.trim() ?? ''];
    final fromPos = pos?.postName?.trim();
    if (fromPos != null && fromPos.isNotEmpty) return fromPos;
    final postId = pos?.postId?.trim();
    if (postId == null || postId.isEmpty) return null;
    final post = postById[postId];
    final n = post?.name?.trim();
    return (n != null && n.isNotEmpty) ? n : null;
  }

  String? assignLevelName(HrmEmployeeAssign a) {
    final level = levelById[a.postSeqLevelId?.trim() ?? ''];
    final n = level?.code?.trim();
    return (n != null && n.isNotEmpty) ? n : null;
  }

  String? assignReportName(HrmEmployeeAssign a) {
    final pos = positionById[a.positionId?.trim() ?? ''];
    final reportPosId = pos?.reportPositionId?.trim();
    if (reportPosId == null || reportPosId.isEmpty) return null;
    final reportAssign = assignByPositionId[reportPosId];
    final uid = reportAssign?.employeeUserId;
    if (uid == null) return null;
    return employeeNameByUserId[uid];
  }

  static String dash(String? value) {
    final s = value?.trim();
    if (s == null || s.isEmpty) return '—';
    return s;
  }

  static String statusLabel(String? code) {
    return switch (code?.trim()) {
      'PENDING' => '待入职',
      'PROBATION' => '试用',
      'ACTIVE' => '在职',
      'LEFT' => '离职',
      'UNPAID_LEAVE' => '停薪留职',
      _ => dash(code),
    };
  }

  static String typeLabel(String? code) {
    return switch (code?.trim()) {
      'EMPLOYEE' => '劳动合同',
      'FULL_TIME' => '全职',
      'PART_TIME' => '兼职',
      'INTERN' => '实习',
      'OUTSOURCE' => '外包',
      'CONSULTANT' => '顾问',
      _ => dash(code),
    };
  }

  static String genderLabel(String? code) {
    return switch (code?.trim()) {
      '0' => '男',
      '1' => '女',
      '2' => '未知',
      _ => dash(code),
    };
  }

  static String maritalLabel(String? code) {
    return switch (code?.trim()) {
      '0' => '未婚',
      '1' => '已婚',
      '3' => '离异',
      '9' => '其他',
      _ => dash(code),
    };
  }

  int? ageYears() {
    final raw = profile.value?.birthDate?.trim();
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month ||
        (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age < 0 ? null : age;
  }
}
