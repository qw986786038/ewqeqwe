import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee.dart';
import '../../../models/hrm_employee_profile.dart';
import '../../../services/hrm_api.dart';

class EmployeeArchiveController extends LxController {
  final _api = HrmApi();

  final keywordCtrl = TextEditingController();

  final loading = false.obs;
  final statsLoading = false.obs;
  final errorMessage = Rxn<String>();

  final stats = HrmEmployeeStats().obs;
  final rows = <HrmEmployeeProfile>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;

  final filterEmpStatus = Rxn<String>();
  final filterEmpType = Rxn<String>();

  final showDetail = false.obs;
  final viewingEmployeeId = Rxn<String>();

  final showEdit = false.obs;
  final editingEmployeeId = Rxn<String>();
  final editingUserId = Rxn<int>();

  String _keyword = '';

  /// 筛选 / 展示用员工状态（对接 HrmEmployeeStatus）。
  static const statusOptions = <(String, String)>[
    ('PENDING_ACTIVE', '待入职'),
    ('ACTIVE', '在职'),
    ('PENDING_LEAVE', '待离职'),
    ('LEAVE', '离职'),
    ('CANCEL_ACTIVE', '取消入职'),
  ];

  /// 筛选 / 展示用员工类型（对接 HrmEmployeeType）。
  static const typeOptions = <(String, String)>[
    ('FORMAL', '正式'),
    ('INTERN', '实习'),
    ('OUTSOURCE', '外包'),
    ('LABOR', '劳务'),
    ('CONSULTANT', '顾问'),
  ];

  int get totalPages {
    final size = pageSize.value;
    if (size <= 0) return 1;
    return ((total.value + size - 1) / size).ceil().clamp(1, 999999);
  }

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
    await Future.wait([loadStats(), loadPage(page: pageNum.value)]);
  }

  Future<void> loadStats() async {
    statsLoading.value = true;
    try {
      stats.value = await _api.fetchEmployeeStats();
    } catch (_) {
      // 统计失败不阻断列表。
    } finally {
      statsLoading.value = false;
    }
  }

  Future<void> loadPage({int? page}) async {
    if (page != null) pageNum.value = page;
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _api.fetchEmployeesPage(
        keyword: _keyword,
        empStatus: filterEmpStatus.value ?? 'ACTIVE,PENDING_LEAVE',
        empType: filterEmpType.value,
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

  void resetSearch() {
    keywordCtrl.clear();
    _keyword = '';
    filterEmpStatus.value = null;
    filterEmpType.value = null;
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

  static String statusLabel(String? status) {
    final key = status?.trim().toUpperCase();
    if (key == null || key.isEmpty) return '-';
    for (final o in statusOptions) {
      if (o.$1 == key) return o.$2;
    }
    // 兼容旧枚举
    switch (key) {
      case 'PENDING':
        return '待入职';
      case 'PROBATION':
        return '试用';
      case 'LEFT':
        return '离职';
      case 'UNPAID_LEAVE':
        return '停薪留职';
      default:
        return status!.trim();
    }
  }

  static String typeLabel(String? type) {
    final key = type?.trim().toUpperCase();
    if (key == null || key.isEmpty) return '-';
    for (final o in typeOptions) {
      if (o.$1 == key) return o.$2;
    }
    switch (key) {
      case 'EMPLOYEE':
      case 'FULL_TIME':
        return '正式';
      case 'PART_TIME':
        return '兼职';
      default:
        return type!.trim();
    }
  }

  static String timeTypeLabel(String? timeType) {
    switch (timeType?.trim().toUpperCase()) {
      case 'FULL_TIME':
        return '全职';
      case 'PART_TIME':
        return '兼职';
      case null:
      case '':
        return '';
      default:
        return timeType!.trim();
    }
  }

  static String displayOrDash(String? value) {
    final s = value?.trim();
    if (s == null || s.isEmpty) return '-';
    return s;
  }

  static String dateText(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return '-';
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  /// 司龄：不足 30 天按天，不足 12 月按月，否则按年+月。
  static String tenureText(String? hireDate) {
    final raw = hireDate?.trim();
    if (raw == null || raw.isEmpty) return '-';
    final d = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
    if (d == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(d.year, d.month, d.day);
    final days = today.difference(start).inDays;
    if (days < 0) return '-';
    if (days < 30) return '$days天';
    var months =
        (today.year - start.year) * 12 + (today.month - start.month);
    if (today.day < start.day) months -= 1;
    if (months < 12) return '$months个月';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years年';
    return '$years年$rem个月';
  }

  static String titleField(
    HrmEmployeeProfile row,
    String? Function(HrmEmployeeTitle title) pick,
  ) {
    final t = row.primaryTitle;
    if (t == null) return '-';
    return displayOrDash(pick(t));
  }

  static String contractExpireText(HrmEmployeeProfile row) {
    DateTime? nearest;
    for (final c in row.contracts) {
      final raw = c.expireDate?.trim();
      if (raw == null || raw.isEmpty) continue;
      final d = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
      if (d == null) continue;
      if (nearest == null || d.isBefore(nearest)) nearest = d;
    }
    if (nearest == null) return '-';
    final y = nearest.year.toString().padLeft(4, '0');
    final m = nearest.month.toString().padLeft(2, '0');
    final d = nearest.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void openDetail(String employeeId) {
    final id = employeeId.trim();
    if (id.isEmpty) return;
    viewingEmployeeId.value = id;
    showDetail.value = true;
  }

  void closeDetail() {
    showDetail.value = false;
    viewingEmployeeId.value = null;
  }

  void openEdit({required String employeeId, int? userId}) {
    final id = employeeId.trim();
    if (id.isEmpty) return;
    editingEmployeeId.value = id;
    editingUserId.value = userId;
    showEdit.value = true;
  }

  void openCreate() {
    editingEmployeeId.value = null;
    editingUserId.value = null;
    showEdit.value = true;
  }

  void closeEdit() {
    showEdit.value = false;
    editingEmployeeId.value = null;
    editingUserId.value = null;
  }
}
