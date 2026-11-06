import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import '../../../services/hrm_api.dart';
import '../employee_archive/employee_archive_controller.dart';

class RegularizationController extends LxController {
  final _api = HrmApi();
  final keywordCtrl = TextEditingController();

  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final stats = HrmEmployeePendingRegularizationStats().obs;
  final rows = <HrmEmployeeProfile>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;

  String _keyword = '';

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
    try {
      stats.value = await _api.fetchPendingRegularizationStats();
    } catch (_) {
      // 统计失败不阻断列表。
    }
  }

  Future<void> loadPage({int? page}) async {
    if (page != null) pageNum.value = page;
    loading.value = true;
    errorMessage.value = null;
    try {
      final result = await _api.fetchEmployeesPage(
        keyword: _keyword,
        empStatus: 'ACTIVE',
        conversionStatus: 'PENDING',
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

  Future<void> regularize(HrmEmployeeProfile row, String date) async {
    final id = row.id?.trim() ?? '';
    if (id.isEmpty) throw HrmApiException('员工 id 不能为空');
    await _api.regularizeEmployee(id: id, regularizationDate: date);
    await refreshAll();
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
