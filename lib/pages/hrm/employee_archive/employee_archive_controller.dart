import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import '../../../services/hrm_api.dart';

class EmployeeArchiveController extends LxController {
  final _api = HrmApi();

  final nameCtrl = TextEditingController();
  final noCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();

  final loading = false.obs;
  final errorMessage = Rxn<String>();

  final rows = <HrmEmployeeProfile>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;

  final filterEmpStatus = Rxn<String>();
  final filterEmpType = Rxn<String>();

  final showDetail = false.obs;
  final viewingUserId = Rxn<int>();

  final showEdit = false.obs;
  final editingUserId = Rxn<int>();

  String _nameQuery = '';
  String _noQuery = '';
  String _mobileQuery = '';

  /// 筛选 / 展示用员工状态。
  static const statusOptions = <(String, String)>[
    ('PENDING', '待入职'),
    ('PROBATION', '试用'),
    ('ACTIVE', '在职'),
    ('LEFT', '离职'),
    ('UNPAID_LEAVE', '停薪留职'),
  ];

  /// 筛选 / 展示用员工类型（与接口枚举对齐；EMPLOYEE 展示为劳动合同）。
  static const typeOptions = <(String, String)>[
    ('EMPLOYEE', '劳动合同'),
    ('FULL_TIME', '全职'),
    ('PART_TIME', '兼职'),
    ('INTERN', '实习'),
    ('OUTSOURCE', '外包'),
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
    loadPage();
  }

  @override
  void onDispose() {
    nameCtrl.dispose();
    noCtrl.dispose();
    mobileCtrl.dispose();
    super.onDispose();
  }

  Future<void> loadPage({int? page}) async {
    if (page != null) pageNum.value = page;
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _api.fetchEmployeesPage(
        name: _nameQuery,
        no: _noQuery,
        mobile: _mobileQuery,
        empStatus: filterEmpStatus.value,
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

  Future<void> refreshAll() => loadPage(page: pageNum.value);

  void search() {
    _nameQuery = nameCtrl.text.trim();
    _noQuery = noCtrl.text.trim();
    _mobileQuery = mobileCtrl.text.trim();
    loadPage(page: 1);
  }

  void resetSearch() {
    nameCtrl.clear();
    noCtrl.clear();
    mobileCtrl.clear();
    _nameQuery = '';
    _noQuery = '';
    _mobileQuery = '';
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
    return status!.trim();
  }

  static String typeLabel(String? type) {
    final key = type?.trim().toUpperCase();
    if (key == null || key.isEmpty) return '-';
    for (final o in typeOptions) {
      if (o.$1 == key) return o.$2;
    }
    return type!.trim();
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

  void openDetail(int? userId) {
    if (userId == null) return;
    viewingUserId.value = userId;
    showDetail.value = true;
  }

  void closeDetail() {
    showDetail.value = false;
    viewingUserId.value = null;
  }

  void openEdit(int? userId) {
    if (userId == null) return;
    editingUserId.value = userId;
    showEdit.value = true;
  }

  void openCreate() {
    editingUserId.value = null;
    showEdit.value = true;
  }

  void closeEdit() {
    showEdit.value = false;
    editingUserId.value = null;
  }
}
