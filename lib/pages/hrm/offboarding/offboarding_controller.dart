import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import '../../../services/hrm_api.dart';
import '../employee_archive/employee_archive_controller.dart';

enum OffboardingTab { pending, left }

class OffboardingController extends LxController {
  final _api = HrmApi();
  final keywordCtrl = TextEditingController();

  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final rows = <HrmEmployeeProfile>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;
  final tab = OffboardingTab.pending.obs;
  final viewingEmployeeId = Rxn<String>();

  String _keyword = '';

  int get totalPages {
    final size = pageSize.value;
    if (size <= 0) return 1;
    return ((total.value + size - 1) / size).ceil().clamp(1, 999999);
  }

  String get empStatus =>
      tab.value == OffboardingTab.pending ? 'PENDING_LEAVE' : 'LEAVE';

  @override
  void onInit() {
    super.onInit();
    loadPage(page: 1);
  }

  @override
  void onDispose() {
    keywordCtrl.dispose();
    super.onDispose();
  }

  Future<void> refreshAll() => loadPage(page: pageNum.value);

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

  void switchTab(OffboardingTab next) {
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

  void openDetail(String employeeId) {
    final id = employeeId.trim();
    if (id.isEmpty) return;
    viewingEmployeeId.value = id;
  }

  void closeDetail() {
    viewingEmployeeId.value = null;
  }

  Future<void> revokeLeave(HrmEmployeeProfile row) async {
    final id = row.id?.trim() ?? '';
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    await _api.revokeEmployeeLeave(id);
    await loadPage(page: pageNum.value);
  }

  static String dash(String? value) {
    final text = EmployeeArchiveController.displayOrDash(value);
    return text == '-' ? '—' : text;
  }

  static String dateText(String? raw) {
    final text = EmployeeArchiveController.dateText(raw);
    return text == '-' ? '—' : text;
  }

  static String phoneText(String? mobile) {
    final s = mobile?.trim() ?? '';
    if (s.isEmpty) return '—';
    if (s.startsWith('+')) return s;
    return '+86 $s';
  }

  static String typeLabel(String? type) {
    final text = EmployeeArchiveController.typeLabel(type);
    return text == '-' ? '—' : text;
  }

  static String leaveTypeLabel(String? type) {
    switch (type?.trim().toUpperCase()) {
      case 'VOLUNTARY':
        return '主动';
      case 'INVOLUNTARY':
        return '被动';
      case 'OTHER':
        return '其他';
      default:
        return dash(type);
    }
  }

  static String deptLabel(HrmEmployeeProfile row) {
    final text = EmployeeArchiveController.titleField(row, (t) => t.deptName);
    return text == '-' ? '—' : text;
  }
}
