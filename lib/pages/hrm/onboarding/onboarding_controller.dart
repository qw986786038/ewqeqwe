import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/dict_data.dart';
import '../../../models/hrm_dept.dart';
import '../../../models/hrm_employee_profile.dart';
import '../../../models/hrm_position.dart';
import '../../../models/hrm_post.dart';
import '../../../models/hrm_post_seq.dart';
import '../../../models/hrm_post_seq_level.dart';
import '../../../services/dict_api.dart';
import '../../../services/hrm_api.dart';
import '../employee_archive/employee_archive_controller.dart';

enum OnboardingTab { pending, cancelled }

class OnboardingController extends LxController {
  final _api = HrmApi();
  final _dictApi = DictApi();
  final keywordCtrl = TextEditingController();

  final loading = false.obs;
  final statsLoading = false.obs;
  final errorMessage = Rxn<String>();
  final stats = HrmEmployeePendingActiveStats().obs;
  final rows = <HrmEmployeeProfile>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;
  final tab = OnboardingTab.pending.obs;

  final depts = <HrmDept>[].obs;
  final posts = <HrmPost>[].obs;
  final positions = <HrmPosition>[].obs;
  final levels = <HrmPostSeqLevel>[].obs;
  final seqs = <HrmPostSeq>[].obs;
  final dicts = <String, List<DictDataItem>>{}.obs;

  String _keyword = '';

  int get totalPages {
    final size = pageSize.value;
    if (size <= 0) return 1;
    return ((total.value + size - 1) / size).ceil().clamp(1, 999999);
  }

  String get empStatus => tab.value == OnboardingTab.pending
      ? 'PENDING_ACTIVE'
      : 'CANCEL_ACTIVE';

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onDispose() {
    keywordCtrl.dispose();
    super.onDispose();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadStats(),
      loadPage(page: pageNum.value),
      _loadOptions(),
    ]);
  }

  Future<void> loadStats() async {
    statsLoading.value = true;
    try {
      stats.value = await _api.fetchPendingActiveStats();
    } catch (_) {
      // 统计失败不阻断列表。
    } finally {
      statsLoading.value = false;
    }
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _api.fetchDepts(),
        _api.fetchPosts(),
        _api.fetchPositions(used: 0),
        _api.fetchPostSeqLevels(),
        _api.fetchPostSeqs(),
        _dictApi.fetchMany(HrmDictTypes.all),
      ]);
      depts
        ..clear()
        ..addAll(results[0] as List<HrmDept>);
      posts
        ..clear()
        ..addAll(results[1] as List<HrmPost>);
      positions
        ..clear()
        ..addAll(results[2] as List<HrmPosition>);
      levels
        ..clear()
        ..addAll(results[3] as List<HrmPostSeqLevel>);
      seqs
        ..clear()
        ..addAll(results[4] as List<HrmPostSeq>);
      dicts
        ..clear()
        ..addAll(results[5] as Map<String, List<DictDataItem>>);
      depts.refresh();
      posts.refresh();
      positions.refresh();
      levels.refresh();
      seqs.refresh();
      dicts.refresh();
    } catch (_) {
      // 选项失败时表单里再提示。
    }
  }

  Future<void> loadPage({int? page}) async {
    if (page != null) pageNum.value = page;
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _api.fetchEmployeesPage(
        keyword: _keyword,
        empStatus: empStatus,
        pageNum: pageNum.value,
        pageSize: pageSize.value,
      );
      total.value = result.total;
      final maxPage = totalPages;
      if (pageNum.value > maxPage) {
        pageNum.value = maxPage;
        if (result.total > 0 && page != null) {
          await loadPage(page: maxPage);
          return;
        }
      }
      rows
        ..clear()
        ..addAll(result.rows);
      rows.refresh();
    } catch (e) {
      errorMessage.value = e.toString();
      if (rows.isEmpty) total.value = 0;
    } finally {
      loading.value = false;
    }
  }

  void search() {
    _keyword = keywordCtrl.text.trim();
    loadPage(page: 1);
  }

  void switchTab(OnboardingTab next) {
    if (tab.value == next) return;
    tab.value = next;
    loadPage(page: 1);
  }

  void goPage(int page) {
    final target = page.clamp(1, totalPages);
    if (target == pageNum.value && rows.isNotEmpty) return;
    loadPage(page: target);
  }

  void changePageSize(int size) {
    if (size == pageSize.value) return;
    pageSize.value = size;
    loadPage(page: 1);
  }

  String seqLabel(HrmEmployeeProfile row) {
    final title = row.primaryTitle;
    if (title == null) return '-';
    final direct = title.postSeqName?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final levelId = title.postSeqLevelId?.trim();
    if (levelId == null || levelId.isEmpty) return '-';
    String? seqId;
    for (final level in levels) {
      if (level.id?.trim() == levelId) {
        seqId = level.postSeqId?.trim();
        break;
      }
    }
    if (seqId == null || seqId.isEmpty) return '-';
    for (final seq in seqs) {
      if (seq.id?.trim() == seqId && seq.name?.trim().isNotEmpty == true) {
        return seq.name!.trim();
      }
    }
    return '-';
  }

  List<HrmPosition> positionsOf({String? deptId, String? postId}) {
    final dept = deptId?.trim();
    final post = postId?.trim();
    return [
      for (final item in positions)
        if (item.id?.trim().isNotEmpty == true &&
            item.postId?.trim().isNotEmpty == true &&
            (dept == null || dept.isEmpty || item.sysDeptId?.trim() == dept) &&
            (post == null || post.isEmpty || item.postId?.trim() == post))
          item,
    ];
  }

  /// 有空编且挂了职务的部门；父部门保留，方便树还连得上。
  List<HrmDept> seatDepts() {
    final byId = <String, HrmDept>{
      for (final dept in depts)
        if (dept.deptId?.trim().isNotEmpty == true) dept.deptId!.trim(): dept,
    };
    final keep = <String>{};
    for (final item in positionsOf()) {
      var id = item.sysDeptId?.trim();
      while (id != null && id.isNotEmpty && id != '0' && keep.add(id)) {
        final parent = byId[id]?.parentId?.trim();
        id = parent;
      }
    }
    return [
      for (final dept in depts)
        if (keep.contains(dept.deptId?.trim())) dept,
    ];
  }

  List<HrmPost> postsOfDept(String? deptId) {
    final ids = <String>{
      for (final item in positionsOf(deptId: deptId))
        if (item.postId?.trim().isNotEmpty == true) item.postId!.trim(),
    };
    return [
      for (final post in posts)
        if (ids.contains(post.id?.trim())) post,
    ];
  }

  /// 字典中文在前；和现在的文案不同时，括号里保留现在的。
  String dictText(String? code, {String? current}) {
    final now = (current ?? code)?.trim() ?? '';
    final zh = _dictLabel(code);
    if (zh == null || zh.isEmpty) return now.isEmpty ? '-' : now;
    if (now.isEmpty || now == zh) return zh;
    return '$zh（$now）';
  }

  String? _dictLabel(String? code) {
    final value = code?.trim();
    if (value == null || value.isEmpty) return null;
    for (final items in dicts.values) {
      for (final item in items) {
        if (item.dictValue?.trim() == value) {
          final label = item.dictLabel?.trim();
          if (label != null && label.isNotEmpty) return label;
        }
      }
    }
    return null;
  }

  String positionLabel(HrmPosition item) {
    final dept = _named(item.deptName, _deptName(item.sysDeptId));
    final post = _named(item.postName, _postName(item.postId));
    final current = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
    ].join(' / ');
    final shown = current.isEmpty ? (item.id?.trim() ?? '-') : current;
    final typeZh = _dictLabel(item.type) ?? _seatTypeText(item.type);
    if (typeZh.isEmpty || typeZh == shown) return shown;
    return '$typeZh（$shown）';
  }

  String _named(String? primary, String fallback) {
    final text = primary?.trim() ?? '';
    if (text.isNotEmpty) return text;
    return fallback;
  }

  String _deptName(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return '';
    for (final dept in depts) {
      if (dept.deptId?.trim() == key) return dept.deptName?.trim() ?? '';
    }
    return '';
  }

  String _postName(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return '';
    for (final post in posts) {
      if (post.id?.trim() == key) return post.name?.trim() ?? '';
    }
    return '';
  }

  String _seatTypeText(String? type) {
    return switch (type?.trim().toUpperCase()) {
      'REGULAR' => '正式',
      'RESERVE' => '储备',
      'OUTSOURCE' => '外包',
      _ => type?.trim() ?? '',
    };
  }

  Future<void> addPending(OnboardingFormValue value) async {
    final assign = _assignOrNull(value);
    await _api.createPendingEmployee(
      name: value.name,
      mobile: value.mobile,
      expectedHireDate: value.expectedHireDate,
      empType: value.empType,
      personalEmail: value.personalEmail,
      sysDeptId: int.tryParse(value.sysDeptId ?? ''),
      sysPostId: int.tryParse(value.sysPostId ?? ''),
      positionId: assign?['positionId'] as int?,
      postSeqLevelId: assign?['postSeqLevelId'] as int?,
    );
    await refreshAll();
  }

  Future<void> updatePending(
    HrmEmployeeProfile row,
    OnboardingFormValue value,
  ) async {
    final id = row.id?.trim() ?? '';
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    final info = <String, dynamic>{
      'name': value.name,
      'mobile': value.mobile,
      'empType': value.empType,
      'empStatus': 'PENDING_ACTIVE',
      'hireDate': value.expectedHireDate,
    };
    final no = row.no?.trim();
    if (no != null && no.isNotEmpty) info['no'] = no;
    final email = value.personalEmail?.trim();
    if (email != null && email.isNotEmpty) info['personalEmail'] = email;
    await _api.updateEmployee(id: id, info: info);
    await refreshAll();
  }

  Future<void> confirmHire(HrmEmployeeProfile row, OnboardingFormValue value) async {
    final id = row.id?.trim() ?? '';
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    await _api.hireEmployee(
      id: id,
      name: value.name,
      mobile: value.mobile,
      expectedHireDate: value.expectedHireDate,
      empType: value.empType,
      personalEmail: value.personalEmail,
      sysDeptId: int.tryParse(value.sysDeptId ?? ''),
      sysPostId: int.tryParse(value.sysPostId ?? ''),
      positionId: int.tryParse(value.positionId ?? ''),
      postSeqLevelId: int.tryParse(value.postSeqLevelId ?? ''),
    );
    await refreshAll();
  }

  Future<void> revokeHire(HrmEmployeeProfile row) async {
    final id = row.id?.trim() ?? '';
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    await _api.revokeHire(id);
    await refreshAll();
  }

  Future<void> restoreHire(HrmEmployeeProfile row) async {
    final id = row.id?.trim() ?? '';
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    await _api.restoreHire(id);
    await refreshAll();
  }

  Map<String, dynamic>? _assignOrNull(OnboardingFormValue value) {
    final position = value.positionId?.trim() ?? '';
    final level = value.postSeqLevelId?.trim() ?? '';
    if (position.isEmpty && level.isEmpty) return null;
    if (position.isEmpty || level.isEmpty) {
      throw HrmApiException('编制与职级需同时填写');
    }
    final positionId = int.tryParse(position);
    final levelId = int.tryParse(level);
    if (positionId == null || levelId == null) {
      throw HrmApiException('编制或职级无效');
    }
    return {
      'positionId': positionId,
      'postSeqLevelId': levelId,
      'isPrimary': 1,
      'startDate': value.expectedHireDate,
    };
  }

  static String typeLabel(String? code) =>
      EmployeeArchiveController.typeLabel(code);

  static String dateText(String? raw) =>
      EmployeeArchiveController.dateText(raw);

  static String phoneText(String? mobile) {
    final s = mobile?.trim() ?? '';
    if (s.isEmpty) return '-';
    if (s.startsWith('+')) return s;
    return '+86 $s';
  }
}

class OnboardingFormValue {
  const OnboardingFormValue({
    required this.name,
    required this.mobile,
    required this.expectedHireDate,
    required this.empType,
    this.personalEmail,
    this.sysDeptId,
    this.sysPostId,
    this.positionId,
    this.postSeqLevelId,
  });

  final String name;
  final String mobile;
  final String? personalEmail;
  final String expectedHireDate;
  final String empType;
  final String? sysDeptId;
  final String? sysPostId;
  final String? positionId;
  final String? postSeqLevelId;
}
