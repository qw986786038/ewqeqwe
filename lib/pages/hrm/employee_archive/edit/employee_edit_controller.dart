import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee_assign.dart';
import '../../../../models/hrm_employee_contact.dart';
import '../../../../models/hrm_employee_contract.dart';
import '../../../../models/hrm_employee_edu.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_employee_skill.dart';
import '../../../../models/hrm_employee_work.dart';
import '../../../../models/hrm_nation.dart';
import '../../../../models/hrm_office_location.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../models/hrm_skill_group.dart';
import '../../../../services/ad_code_api.dart';
import '../../../../services/hrm_api.dart';

/// 任职条目（来自 employee-assign/on-duty，可本地增删改）。
class EmployeeAssignDraft {
  EmployeeAssignDraft({required this.localKey, this.id});

  final String localKey;
  String? id;
  bool isPrimary = true;
  String? deptId;
  String? postId;
  String? postSeqId;
  String? postSeqLevelId;
  String? positionId;
  /// HIRE / REGULARIZATION / PROMOTION
  String startType = 'HIRE';
  String reportTo = '由席位自动带出';
  String dottedReport = '由席位自动带出';
  DateTime? startDate;
}

/// 紧急联系人（本地编辑）。
class EmployeeContactDraft {
  EmployeeContactDraft({required this.localKey, this.id});

  final String localKey;
  String? id;
  String name = '';
  String relation = '';
  String phone = '';
}

/// 教育经历（本地编辑）。
class EmployeeEduDraft {
  EmployeeEduDraft({
    required this.localKey,
    this.id,
    this.isHighest = false,
  });

  final String localKey;
  String? id;
  DateTime? startDate;
  DateTime? endDate;
  String school = '';
  String major = '';
  String degree = '';
  bool isHighest;
}

/// 工作经历（本地编辑）。
class EmployeeWorkDraft {
  EmployeeWorkDraft({required this.localKey, this.id});

  final String localKey;
  String? id;
  DateTime? startDate;
  DateTime? endDate;
  String company = '';
  String position = '';
  String duties = '';
}

/// 合同（本地编辑）。
class EmployeeContractDraft {
  EmployeeContractDraft({required this.localKey, this.id});

  final String localKey;
  String? id;
  String type = '';
  String contractNo = '';
  String signParty = '';
  DateTime? effectiveDate;
  DateTime? expireDate;
  DateTime? signDate;
  String attachmentName = '';
}

class EmployeeEditController extends LxController {
  /// [userId] 为空时为新增模式。
  EmployeeEditController({this.userId});

  final int? userId;
  bool get isCreate => userId == null;

  final _api = HrmApi();
  final _adCodeApi = AdCodeApi();
  final form = AppFormController();

  final loading = true.obs;
  final saving = false.obs;
  final errorMessage = Rxn<String>();
  final loaded = false.obs;
  final loadToken = 0.obs;

  final profile = Rxn<HrmEmployeeProfile>();
  final nations = <HrmNation>[].obs;
  final officeLocations = <HrmOfficeLocation>[].obs;
  final skillGroups = <HrmSkillGroup>[].obs;
  final depts = <HrmDept>[].obs;
  final posts = <HrmPost>[].obs;
  final postSeqs = <HrmPostSeq>[].obs;
  final postSeqLevels = <HrmPostSeqLevel>[].obs;
  final positions = <HrmPosition>[].obs;

  final assigns = <EmployeeAssignDraft>[].obs;
  final contacts = <EmployeeContactDraft>[].obs;
  final educations = <EmployeeEduDraft>[].obs;
  final workExperiences = <EmployeeWorkDraft>[].obs;
  final contracts = <EmployeeContractDraft>[].obs;
  final selectedSkillTagIds = <int>{}.obs;

  /// 全量在任，用于按席位反查汇报对象姓名。
  final List<HrmEmployeeAssign> _allOnDuty = [];
  final Map<String, HrmPosition> _positionById = {};
  final Map<String, HrmPost> _postById = {};
  final Map<String, String> _deptNameById = {};
  final Map<String, HrmPostSeqLevel> _levelById = {};
  final Map<int, String> _employeeNameByUserId = {};
  final Map<String, HrmEmployeeAssign> _assignByPositionId = {};

  int _localSeq = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onDispose() {
    form.dispose();
    super.onDispose();
  }

  /// 户籍省市区初始路径（行政区划 code 字符串）。
  List<String> hukouInitialPath([HrmEmployeeProfile? p]) {
    final src = p ?? profile.value;
    return [
      for (final code in [src?.province, src?.city, src?.district])
        if (code?.trim().isNotEmpty == true) code!.trim(),
    ];
  }

  /// `GET /desktop/common/ad-code` 按父级加载下级。
  Future<List<AppCascadeOption<String>>> loadRegionOptions(
    AppRegionLevel level,
    List<String> path,
  ) async {
    final parentCode = switch (level) {
      AppRegionLevel.province => 100000,
      AppRegionLevel.city =>
        int.tryParse(path.isNotEmpty ? path.first : '') ?? 0,
      AppRegionLevel.county =>
        int.tryParse(path.length > 1 ? path[1] : '') ?? 0,
    };
    if (level != AppRegionLevel.province && parentCode <= 0) {
      return const [];
    }
    final items = await _adCodeApi.fetchChildren(parentCode: parentCode);
    return [
      for (final e in items)
        if (e.code != null && e.chName?.trim().isNotEmpty == true)
          AppCascadeOption(value: '${e.code}', label: e.chName!.trim()),
    ];
  }

  String _nextKey() => 'local_${++_localSeq}';

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    loaded.value = false;
    try {
      if (isCreate) {
        await _loadCreate();
      } else {
        await _loadEdit(userId!);
      }
      loadToken.value++;
      loaded.value = true;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadCreate() async {
    final results = await Future.wait([
      _api.fetchNations(),
      _api.fetchOfficeLocations(),
      _api.fetchSkillGroups(),
      _api.fetchDepts(),
      _api.fetchPosts(),
      _api.fetchPostSeqs(),
      _api.fetchPostSeqLevels(),
      _api.fetchPositions(),
      _api.fetchOnDutyAssigns(),
      _api.fetchEmployeeProfiles(pageNum: 1, pageSize: 10000),
    ]);
    nations
      ..clear()
      ..addAll(results[0] as List<HrmNation>);
    officeLocations
      ..clear()
      ..addAll(results[1] as List<HrmOfficeLocation>);
    skillGroups
      ..clear()
      ..addAll(results[2] as List<HrmSkillGroup>);
    depts
      ..clear()
      ..addAll(results[3] as List<HrmDept>);
    posts
      ..clear()
      ..addAll(results[4] as List<HrmPost>);
    postSeqs
      ..clear()
      ..addAll(results[5] as List<HrmPostSeq>);
    postSeqLevels
      ..clear()
      ..addAll(results[6] as List<HrmPostSeqLevel>);
    positions
      ..clear()
      ..addAll(results[7] as List<HrmPosition>);

    profile.value = HrmEmployeeProfile()
      ..empStatus = 'PENDING'
      ..empType = 'EMPLOYEE'
      ..timeType = 'FULL_TIME'
      ..gender = '0'
      ..showMobile = 1
      ..showEmail = 1
      ..showIm = 1
      ..showOffice = 1
      ..keepInDirectory = 1;

    contacts.clear();
    educations.clear();
    workExperiences.clear();
    contracts.clear();
    assigns.clear();
    selectedSkillTagIds.clear();
    contacts.refresh();
    educations.refresh();
    workExperiences.refresh();
    contracts.refresh();
    assigns.refresh();
    selectedSkillTagIds.refresh();

    _rebuildLookupMaps(
      onDuty: results[8] as List<HrmEmployeeAssign>,
      employees: results[9] as List<HrmEmployeeProfile>,
    );
  }

  Future<void> _loadEdit(int uid) async {
    final results = await Future.wait([
      _api.fetchEmployeeByUser(uid),
      _api.fetchNations(),
      _api.fetchOfficeLocations(),
      _api.fetchSkillGroups(),
      _api.fetchDepts(),
      _api.fetchPosts(),
      _api.fetchPostSeqs(),
      _api.fetchPostSeqLevels(),
      _api.fetchPositions(),
      _api.fetchEmployeeContacts(uid),
      _api.fetchEmployeeEducations(uid),
      _api.fetchEmployeeWorkExperiences(uid),
      _api.fetchEmployeeContracts(uid),
      _api.fetchEmployeeSkills(uid),
      _api.fetchOnDutyAssigns(),
      _api.fetchEmployeeProfiles(pageNum: 1, pageSize: 10000),
    ]);

    final p = results[0] as HrmEmployeeProfile;
    profile.value = p;
    nations
      ..clear()
      ..addAll(results[1] as List<HrmNation>);
    officeLocations
      ..clear()
      ..addAll(results[2] as List<HrmOfficeLocation>);
    skillGroups
      ..clear()
      ..addAll(results[3] as List<HrmSkillGroup>);
    depts
      ..clear()
      ..addAll(results[4] as List<HrmDept>);
    posts
      ..clear()
      ..addAll(results[5] as List<HrmPost>);
    postSeqs
      ..clear()
      ..addAll(results[6] as List<HrmPostSeq>);
    postSeqLevels
      ..clear()
      ..addAll(results[7] as List<HrmPostSeqLevel>);
    positions
      ..clear()
      ..addAll(results[8] as List<HrmPosition>);

    _bindContacts(results[9] as List<HrmEmployeeContact>);
    _bindEducations(results[10] as List<HrmEmployeeEdu>);
    _bindWorks(results[11] as List<HrmEmployeeWork>);
    final nestedContracts = p.contracts;
    final apiContracts = results[12] as List<HrmEmployeeContract>;
    _bindContracts(
      nestedContracts.isNotEmpty ? nestedContracts : apiContracts,
    );

    final skills = results[13] as List<HrmEmployeeSkill>;
    selectedSkillTagIds
      ..clear()
      ..addAll([
        for (final s in skills)
          if (s.skillTagId != null) s.skillTagId!,
      ]);

    _rebuildLookupMaps(
      onDuty: results[14] as List<HrmEmployeeAssign>,
      employees: results[15] as List<HrmEmployeeProfile>,
    );
    _bindAssigns(_allOnDuty);
  }

  void _rebuildLookupMaps({
    required List<HrmEmployeeAssign> onDuty,
    required List<HrmEmployeeProfile> employees,
  }) {
    _allOnDuty
      ..clear()
      ..addAll(onDuty);
    _positionById
      ..clear()
      ..addEntries([
        for (final p in positions)
          if (p.id?.trim().isNotEmpty == true) MapEntry(p.id!.trim(), p),
      ]);
    _postById
      ..clear()
      ..addEntries([
        for (final p in posts)
          if (p.id?.trim().isNotEmpty == true) MapEntry(p.id!.trim(), p),
      ]);
    _deptNameById
      ..clear()
      ..addEntries([
        for (final d in depts)
          if (d.deptId?.trim().isNotEmpty == true)
            MapEntry(d.deptId!.trim(), (d.deptName ?? '').trim()),
      ]);
    _levelById
      ..clear()
      ..addEntries([
        for (final l in postSeqLevels)
          if (l.id?.trim().isNotEmpty == true) MapEntry(l.id!.trim(), l),
      ]);
    _employeeNameByUserId
      ..clear()
      ..addEntries([
        for (final e in employees)
          if (e.userId != null && e.name?.trim().isNotEmpty == true)
            MapEntry(e.userId!, e.name!.trim()),
      ]);
    _assignByPositionId
      ..clear()
      ..addEntries([
        for (final a in onDuty)
          if (a.positionId?.trim().isNotEmpty == true)
            MapEntry(a.positionId!.trim(), a),
      ]);
  }

  /// 当前员工在任：`GET /desktop/hrm/employee-assign/on-duty` 按 userId 过滤。
  void _bindAssigns(List<HrmEmployeeAssign> all) {
    final mine = [
      for (final a in all)
        if (a.employeeUserId == userId) a,
    ];
    mine.sort((a, b) {
      final pa = a.isPrimary == 1 ? 0 : 1;
      final pb = b.isPrimary == 1 ? 0 : 1;
      return pa.compareTo(pb);
    });
    assigns
      ..clear()
      ..addAll([
        for (final a in mine) _draftFromAssign(a),
      ]);
    assigns.refresh();
  }

  EmployeeAssignDraft _draftFromAssign(HrmEmployeeAssign a) {
    final startType = a.startType?.trim().toUpperCase();
    final draft = EmployeeAssignDraft(
      localKey: _nextKey(),
      id: a.id,
    )
      ..isPrimary = a.isPrimary == 1
      ..postSeqLevelId = a.postSeqLevelId?.trim()
      ..positionId = a.positionId?.trim()
      ..startType = (startType == 'HIRE' ||
              startType == 'REGULARIZATION' ||
              startType == 'PROMOTION')
          ? startType!
          : 'HIRE'
      ..startDate = _parseDate(a.startDate);
    final levelId = draft.postSeqLevelId;
    if (levelId != null) {
      draft.postSeqId = _levelById[levelId]?.postSeqId?.trim();
    }
    applyPositionToAssign(draft, draft.positionId);
    return draft;
  }

  /// 选中席位后回填部门 / 岗位 / 汇报对象（由席位配置带出）。
  void applyPositionToAssign(EmployeeAssignDraft draft, String? positionId) {
    final id = positionId?.trim();
    draft.positionId = id;
    if (id == null || id.isEmpty) {
      draft.reportTo = '由席位自动带出';
      draft.dottedReport = '由席位自动带出';
      return;
    }
    final pos = _positionById[id];
    if (pos == null) return;
    draft.deptId = pos.sysDeptId?.trim();
    draft.postId = pos.postId?.trim();
    draft.reportTo =
        _personNameOnPosition(pos.reportPositionId) ?? '由席位自动带出';
    draft.dottedReport =
        _personNameOnPosition(pos.dottedPositionId) ?? '由席位自动带出';
  }

  String? _personNameOnPosition(String? positionId) {
    final id = positionId?.trim();
    if (id == null || id.isEmpty) return null;
    final assign = _assignByPositionId[id];
    final uid = assign?.employeeUserId;
    if (uid == null) return null;
    final name = _employeeNameByUserId[uid]?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  void _bindContacts(List<HrmEmployeeContact> list) {
    final sorted = [...list]..sort(
        (a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0),
      );
    contacts
      ..clear()
      ..addAll([
        for (final c in sorted)
          EmployeeContactDraft(
            localKey: _nextKey(),
            id: c.id,
          )
            ..name = c.name ?? ''
            ..relation = c.relation ?? ''
            ..phone = c.phone ?? '',
      ]);
  }

  void _bindEducations(List<HrmEmployeeEdu> list) {
    educations
      ..clear()
      ..addAll([
        for (final e in list)
          EmployeeEduDraft(
            localKey: _nextKey(),
            id: e.id,
            isHighest: e.isHighest == 1,
          )
            ..startDate = _parseDate(e.startDate)
            ..endDate = _parseDate(e.endDate)
            ..school = e.school ?? ''
            ..major = e.major ?? ''
            ..degree = e.degree ?? '',
      ]);
    if (educations.isNotEmpty && !educations.any((e) => e.isHighest)) {
      educations.first.isHighest = true;
    }
  }

  void _bindWorks(List<HrmEmployeeWork> list) {
    workExperiences
      ..clear()
      ..addAll([
        for (final w in list)
          EmployeeWorkDraft(localKey: _nextKey(), id: w.id)
            ..startDate = _parseDate(w.startDate)
            ..endDate = _parseDate(w.endDate)
            ..company = w.company ?? ''
            ..position = w.position ?? ''
            ..duties = w.duties ?? '',
      ]);
  }

  void _bindContracts(List<HrmEmployeeContract> list) {
    contracts
      ..clear()
      ..addAll([
        for (final c in list)
          EmployeeContractDraft(localKey: _nextKey(), id: c.id)
            ..type = c.type ?? ''
            ..contractNo = c.contractNo ?? ''
            ..signParty = c.signParty ?? ''
            ..effectiveDate = _parseDate(c.effectiveDate)
            ..expireDate = _parseDate(c.expireDate)
            ..signDate = _parseDate(c.signDate)
            ..attachmentName = c.attachmentUrl ?? '',
      ]);
  }

  DateTime? _parseDate(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  bool isSkillSelected(int tagId) => selectedSkillTagIds.contains(tagId);

  void toggleSkill(int tagId) {
    if (selectedSkillTagIds.contains(tagId)) {
      selectedSkillTagIds.remove(tagId);
    } else {
      selectedSkillTagIds.add(tagId);
    }
    selectedSkillTagIds.refresh();
  }

  void addAssign() {
    assigns.add(
      EmployeeAssignDraft(localKey: _nextKey())..isPrimary = assigns.isEmpty,
    );
    assigns.refresh();
  }

  void removeAssign(String localKey) {
    assigns.removeWhere((e) => e.localKey == localKey);
    assigns.refresh();
  }

  void addContact() {
    if (contacts.length >= 3) return;
    contacts.add(EmployeeContactDraft(localKey: _nextKey()));
  }

  void removeContact(String localKey) {
    contacts.removeWhere((e) => e.localKey == localKey);
  }

  void addEducation() {
    educations.add(
      EmployeeEduDraft(
        localKey: _nextKey(),
        isHighest: educations.isEmpty,
      ),
    );
  }

  void removeEducation(String localKey) {
    EmployeeEduDraft? removed;
    for (final e in educations) {
      if (e.localKey == localKey) {
        removed = e;
        break;
      }
    }
    educations.removeWhere((e) => e.localKey == localKey);
    if (removed?.isHighest == true && educations.isNotEmpty) {
      educations.first.isHighest = true;
    }
  }

  void markHighestEducation(String localKey) {
    for (final e in educations) {
      e.isHighest = e.localKey == localKey;
    }
    educations.refresh();
  }

  void addWorkExperience() {
    workExperiences.add(EmployeeWorkDraft(localKey: _nextKey()));
  }

  void removeWorkExperience(String localKey) {
    workExperiences.removeWhere((e) => e.localKey == localKey);
  }

  void addContract() {
    contracts.add(EmployeeContractDraft(localKey: _nextKey()));
  }

  void removeContract(String localKey) {
    contracts.removeWhere((e) => e.localKey == localKey);
  }

  void pickContractFile(String localKey, String fileName) {
    EmployeeContractDraft? item;
    for (final e in contracts) {
      if (e.localKey == localKey) {
        item = e;
        break;
      }
    }
    if (item != null) {
      item.attachmentName = fileName;
      contracts.refresh();
    }
  }

  List<AppOption<String>> deptOptions() => [
        for (final d in depts)
          if (d.deptId?.trim().isNotEmpty == true &&
              d.deptName?.trim().isNotEmpty == true)
            AppOption(value: d.deptId!.trim(), label: d.deptName!.trim()),
      ];

  List<AppOption<String>> postOptions() => [
        for (final p in posts)
          if (p.id?.trim().isNotEmpty == true && p.name?.trim().isNotEmpty == true)
            AppOption(value: p.id!.trim(), label: p.name!.trim()),
      ];

  List<AppOption<String>> postSeqOptions() => [
        for (final s in postSeqs)
          if (s.id?.trim().isNotEmpty == true)
            AppOption(value: s.id!.trim(), label: postSeqOptionLabel(s)),
      ];

  List<AppOption<String>> postSeqLevelOptions([String? postSeqId]) {
    final seq = postSeqId?.trim();
    return [
      for (final l in postSeqLevels)
        if (l.id?.trim().isNotEmpty == true &&
            l.code?.trim().isNotEmpty == true &&
            (seq == null ||
                seq.isEmpty ||
                l.postSeqId?.trim() == seq))
          AppOption(value: l.id!.trim(), label: l.code!.trim()),
    ];
  }

  List<AppOption<String>> positionOptions([String? deptId]) {
    final dept = deptId?.trim();
    return [
      for (final p in positions)
        if (p.id?.trim().isNotEmpty == true &&
            (dept == null || dept.isEmpty || p.sysDeptId?.trim() == dept))
          AppOption(
            value: p.id!.trim(),
            label: _positionLabel(p),
          ),
    ];
  }

  List<AppOption<String>> nationOptions() => [
        for (final n in nations)
          if (n.name?.trim().isNotEmpty == true)
            AppOption(value: n.name!.trim(), label: n.name!.trim()),
      ];

  List<AppOption<String>> officeLocationOptions() => [
        for (final o in officeLocations)
          if (o.id?.trim().isNotEmpty == true &&
              o.name?.trim().isNotEmpty == true)
            AppOption(value: o.id!.trim(), label: o.name!.trim()),
      ];

  String _positionLabel(HrmPosition p) {
    final deptId = p.sysDeptId?.trim();
    final postId = p.postId?.trim();
    final dept = (p.deptName?.trim().isNotEmpty == true)
        ? p.deptName!.trim()
        : (deptId != null ? (_deptNameById[deptId] ?? '') : '');
    final post = (p.postName?.trim().isNotEmpty == true)
        ? p.postName!.trim()
        : (postId != null ? (_postById[postId]?.name?.trim() ?? '') : '');
    final type = _positionTypeLabel(p.type);
    final parts = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
      if (type.isNotEmpty) type,
    ];
    if (parts.isNotEmpty) return parts.join(' / ');
    return p.id?.trim() ?? '-';
  }

  static String _positionTypeLabel(String? type) {
    switch (type?.trim().toUpperCase()) {
      case 'REGULAR':
        return '正式';
      case 'RESERVE':
        return '储备';
      case 'OUTSOURCE':
        return '外包';
      default:
        return type?.trim() ?? '';
    }
  }

  String postSeqOptionLabel(HrmPostSeq seq) {
    final name = seq.name?.trim() ?? '';
    final ch = switch (seq.channel?.trim().toUpperCase()) {
      'M' => '管理岗',
      'T' => '技术岗',
      _ => seq.channel?.trim() ?? '',
    };
    if (name.isEmpty) return ch.isEmpty ? '-' : ch;
    if (ch.isEmpty) return name;
    return '$name（$ch）';
  }

  static bool checkboxFromInt(int? value) => value == 1;

  static int checkboxToInt(bool? value) => value == true ? 1 : 0;

  /// 新增 `POST /desktop/hrm/employee`；修改 `PUT /desktop/hrm/employee/{id}`。
  Future<void> save(Map<String, Object?> values) async {
    final p = profile.value ?? HrmEmployeeProfile();
    final id = p.id?.trim();
    if (!isCreate && (id == null || id.isEmpty)) {
      throw HrmApiException('员工 id 无效');
    }
    final name = _str(values['name']);
    final no = _str(values['no']);
    if (name == null || name.isEmpty) {
      throw HrmApiException('请填写姓名');
    }
    if (no == null || no.isEmpty) {
      throw HrmApiException('请填写工号');
    }

    final info = <String, dynamic>{
      'no': no,
      'name': name,
    };
    final uid = p.userId ?? userId;
    if (uid != null) info['userId'] = uid;
    void putStr(String key, Object? raw) {
      final s = _str(raw);
      if (s != null) info[key] = s;
    }

    putStr('pinYin', values['pinYin']);
    putStr('englishName', values['englishName']);
    putStr('aliasName', values['aliasName']);
    putStr('gender', values['gender']);
    putStr('nation', values['nation']);
    putStr('maritalStatus', values['maritalStatus']);
    putStr('idCardNo', values['idCardNo']);
    putStr('mobile', values['mobile']);
    putStr('corpEmail', values['corpEmail']);
    putStr('personalEmail', values['personalEmail']);
    putStr('imAccount', values['imAccount']);
    putStr('workstation', values['workstation']);
    putStr('officePhone', values['officePhone']);
    putStr('officeExt', values['officeExt']);
    putStr('householdAddress', values['householdAddress']);
    putStr('residence', values['residence'] ?? p.residence);
    putStr('politicalStatus', values['politicalStatus'] ?? p.politicalStatus);
    putStr('idCardType', values['idCardType'] ?? p.idCardType);
    putStr('highestEducation', p.highestEducation);
    putStr('graduateSchool', p.graduateSchool);
    putStr('major', p.major);
    putStr(
      'empStatus',
      p.empStatus?.trim().isNotEmpty == true ? p.empStatus : 'PENDING',
    );
    putStr(
      'empType',
      p.empType?.trim().isNotEmpty == true ? p.empType : 'EMPLOYEE',
    );
    putStr(
      'timeType',
      p.timeType?.trim().isNotEmpty == true ? p.timeType : 'FULL_TIME',
    );

    final birth = values['birthDate'];
    if (birth is DateTime) {
      info['birthDate'] = _fmtDate(birth);
    } else {
      putStr('birthDate', birth ?? p.birthDate);
    }

    final officeLoc = _str(values['officeLocation']) ?? p.officeLocation;
    final officeLocId = int.tryParse(officeLoc ?? '');
    if (officeLocId != null) {
      info['officeLocation'] = officeLocId;
    }

    final region = values['hukouRegion'];
    if (region is List) {
      final codes = <String>[
        for (final e in region)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
      if (codes.isNotEmpty) {
        final province = int.tryParse(codes[0]);
        if (province != null) info['province'] = province;
      }
      if (codes.length > 1) {
        final city = int.tryParse(codes[1]);
        if (city != null) info['city'] = city;
      }
      if (codes.length > 2) {
        final district = int.tryParse(codes[2]);
        if (district != null) info['district'] = district;
      }
    }

    info['showMobile'] = checkboxToInt(values['showMobile'] as bool?);
    info['showEmail'] = checkboxToInt(values['showEmail'] as bool?);
    info['showIm'] = checkboxToInt(values['showIm'] as bool?);
    info['showOffice'] = checkboxToInt(values['showOffice'] as bool?);
    info['keepInDirectory'] =
        checkboxToInt(values['keepInDirectory'] as bool?);

    final overtimeRaw = _str(values['overtime']);
    final overtime = int.tryParse(overtimeRaw ?? '') ?? p.overtime;
    if (overtime != null) info['overtime'] = overtime;

    final contactList = <Map<String, dynamic>>[];
    for (var i = 0; i < contacts.length; i++) {
      final item = contacts[i];
      final nameC =
          (_str(values['contact_name_${item.localKey}']) ?? item.name).trim();
      final relation =
          (_str(values['contact_relation_${item.localKey}']) ?? item.relation)
              .trim();
      final mobile =
          (_str(values['contact_phone_${item.localKey}']) ?? item.phone).trim();
      if (nameC.isEmpty && relation.isEmpty && mobile.isEmpty) continue;
      if (nameC.isEmpty || relation.isEmpty || mobile.isEmpty) {
        throw HrmApiException('紧急联系人姓名、关系、电话均需填写');
      }
      contactList.add({
        'name': nameC,
        'relation': relation,
        'mobile': mobile,
        'isPrimary': i == 0 ? '1' : '0',
        'orderNum': i + 1,
      });
    }

    final eduList = <Map<String, dynamic>>[];
    for (final item in educations) {
      final school =
          (_str(values['edu_school_${item.localKey}']) ?? item.school).trim();
      final education =
          (_str(values['edu_degree_${item.localKey}']) ?? item.degree).trim();
      final major =
          (_str(values['edu_major_${item.localKey}']) ?? item.major).trim();
      final start = values['edu_start_${item.localKey}'];
      final end = values['edu_end_${item.localKey}'];
      if (school.isEmpty && education.isEmpty) continue;
      if (school.isEmpty || education.isEmpty) {
        throw HrmApiException('教育经历需填写毕业院校与学历');
      }
      final row = <String, dynamic>{
        'school': school,
        'education': education,
        'isHighest': item.isHighest ? '1' : '0',
      };
      if (major.isNotEmpty) row['major'] = major;
      final startDate = start is DateTime ? start : item.startDate;
      final endDate = end is DateTime ? end : item.endDate;
      if (startDate != null) row['startDate'] = _fmtDate(startDate);
      if (endDate != null) row['endDate'] = _fmtDate(endDate);
      eduList.add(row);
    }

    final workList = <Map<String, dynamic>>[];
    for (final item in workExperiences) {
      final company =
          (_str(values['work_company_${item.localKey}']) ?? item.company)
              .trim();
      final position =
          (_str(values['work_position_${item.localKey}']) ?? item.position)
              .trim();
      final duty =
          (_str(values['work_duties_${item.localKey}']) ?? item.duties).trim();
      final start = values['work_start_${item.localKey}'];
      final end = values['work_end_${item.localKey}'];
      if (company.isEmpty && position.isEmpty) continue;
      if (company.isEmpty || position.isEmpty) {
        throw HrmApiException('工作经历需填写公司与职位');
      }
      final row = <String, dynamic>{
        'companyName': company,
        'positionName': position,
      };
      if (duty.isNotEmpty) row['duty'] = duty;
      final startDate = start is DateTime ? start : item.startDate;
      final endDate = end is DateTime ? end : item.endDate;
      if (startDate != null) row['startDate'] = _fmtDate(startDate);
      if (endDate != null) row['endDate'] = _fmtDate(endDate);
      workList.add(row);
    }

    final contractList = <Map<String, dynamic>>[];
    for (var i = 0; i < contracts.length; i++) {
      final item = contracts[i];
      final type =
          (_str(values['contract_type_${item.localKey}']) ?? item.type).trim();
      final noC =
          (_str(values['contract_no_${item.localKey}']) ?? item.contractNo)
              .trim();
      final partyA =
          (_str(values['contract_party_${item.localKey}']) ?? item.signParty)
              .trim();
      if (type.isEmpty && noC.isEmpty && partyA.isEmpty) continue;
      if (type.isEmpty || noC.isEmpty || partyA.isEmpty) {
        throw HrmApiException('合同需填写类型、编号与签约主体');
      }
      final row = <String, dynamic>{
        'type': type,
        'no': noC,
        'partyA': partyA,
        'orderNum': i + 1,
      };
      final effective = values['contract_effective_${item.localKey}'];
      final expire = values['contract_expire_${item.localKey}'];
      final sign = values['contract_sign_${item.localKey}'];
      final startDate =
          effective is DateTime ? effective : item.effectiveDate;
      final endDate = expire is DateTime ? expire : item.expireDate;
      final signingDate = sign is DateTime ? sign : item.signDate;
      if (startDate != null) row['startDate'] = _fmtDate(startDate);
      if (endDate != null) row['endDate'] = _fmtDate(endDate);
      if (signingDate != null) row['signingDate'] = _fmtDate(signingDate);
      final file =
          (_str(values['contract_file_${item.localKey}']) ?? item.attachmentName)
              .trim();
      if (file.isNotEmpty) row['file'] = file;
      contractList.add(row);
    }

    final assignAppoint = <Map<String, dynamic>>[];
    for (final item in assigns) {
      final primary = values['assign_primary_${item.localKey}'];
      final isPrimary = primary is bool ? primary : item.isPrimary;
      final positionId =
          (_str(values['assign_position_${item.localKey}']) ?? item.positionId)
              ?.trim();
      final levelId =
          (_str(values['assign_level_${item.localKey}']) ?? item.postSeqLevelId)
              ?.trim();
      final start = values['assign_start_${item.localKey}'];
      final startDate = start is DateTime ? start : item.startDate;
      if ((positionId == null || positionId.isEmpty) &&
          (levelId == null || levelId.isEmpty) &&
          startDate == null) {
        continue;
      }
      if (positionId == null ||
          positionId.isEmpty ||
          levelId == null ||
          levelId.isEmpty ||
          startDate == null) {
        throw HrmApiException('任职需填写席位、职级与开始日期');
      }
      final positionIdInt = int.tryParse(positionId);
      final levelIdInt = int.tryParse(levelId);
      if (positionIdInt == null || levelIdInt == null) {
        throw HrmApiException('任职席位或职级无效');
      }
      final row = <String, dynamic>{
        'positionId': positionIdInt,
        'postSeqLevelId': levelIdInt,
        'isPrimary': isPrimary ? 1 : 0,
        'startType': item.startType,
        'startDate': _fmtDate(startDate),
      };
      final assignUserId = p.userId ?? userId;
      if (assignUserId != null) {
        row['employeeUserId'] = assignUserId;
      }
      assignAppoint.add(row);
    }
    if (assignAppoint.isNotEmpty) {
      final primaryCount =
          assignAppoint.where((e) => e['isPrimary'] == 1).length;
      if (primaryCount != 1) {
        throw HrmApiException('任职须且仅能有一个主岗');
      }
    }

    saving.value = true;
    try {
      if (isCreate) {
        await _api.createEmployee(
          info: info,
          workList: workList,
          contactList: contactList,
          eduList: eduList,
          contracts: contractList,
          skillIds: selectedSkillTagIds.toList(),
          assignAppoint: assignAppoint,
        );
      } else {
        await _api.updateEmployee(
          id: id!,
          info: info,
          workList: workList,
          contactList: contactList,
          eduList: eduList,
          contracts: contractList,
          skillIds: selectedSkillTagIds.toList(),
          assignAppoint: assignAppoint,
        );
        await load();
      }
    } finally {
      saving.value = false;
    }
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
