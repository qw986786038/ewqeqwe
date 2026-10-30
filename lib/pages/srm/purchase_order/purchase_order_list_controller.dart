import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/srm_purchase_order.dart';
import '../../../services/srm_purchase_order_api.dart';

class PurchaseOrderListController extends LxController {
  final _api = SrmPurchaseOrderApi();

  final topSearchCtrl = TextEditingController();
  final hiddenColumnIds = <String>{}.obs;
  final selectedIds = <String>{}.obs;

  final kpi = SrmPurchaseOrderKpi().obs;
  final rows = <SrmPurchaseOrder>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;
  final loading = false.obs;
  final exporting = false.obs;
  final errorMessage = Rxn<String>();

  /// 列头已应用的多选筛选：columnId → 选中值。
  final columnFilters = <String, Set<String>>{}.obs;

  static const columnBrandOptions = [
    '雪碧',
    '可口可乐',
    '百事',
    '其它',
  ];

  static const columnContractTypeOptions = [
    '设备采购',
    '媒介采购',
    '物业租赁',
    '维保运维',
    '技术服务',
    '其它',
  ];

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onDispose() {
    topSearchCtrl.dispose();
    super.onDispose();
  }

  bool isColumnVisible(String id) => !hiddenColumnIds.contains(id);

  void setColumnVisible(String id, bool visible) {
    if (visible) {
      hiddenColumnIds.remove(id);
    } else {
      hiddenColumnIds.add(id);
    }
    hiddenColumnIds.refresh();
  }

  void setAllColumnsVisible(Iterable<String> ids, bool visible) {
    if (visible) {
      hiddenColumnIds.removeAll(ids);
    } else {
      hiddenColumnIds.addAll(ids);
    }
    hiddenColumnIds.refresh();
  }

  void setSelectedRows(List<SrmPurchaseOrder> selected) {
    selectedIds
      ..clear()
      ..addAll(
        selected
            .map((e) => e.id?.trim())
            .whereType<String>()
            .where((id) => id.isNotEmpty),
      );
    selectedIds.refresh();
  }

  void clearSelection() {
    if (selectedIds.isEmpty) return;
    selectedIds.clear();
    selectedIds.refresh();
  }

  int get totalPages {
    final size = pageSize.value;
    if (size <= 0) return 1;
    final t = total.value;
    if (t <= 0) return 1;
    return ((t + size - 1) / size).floor();
  }

  Set<String> columnFilterOf(String id) =>
      columnFilters[id] ?? const <String>{};

  Future<void> applyColumnFilter(String id, Set<String> selected) async {
    if (selected.isEmpty) {
      columnFilters.remove(id);
    } else {
      columnFilters[id] = Set<String>.from(selected);
    }
    columnFilters.refresh();
    pageNum.value = 1;
    await refreshAll(clearSelected: true);
  }

  String? _joinedColumnFilter(String id) {
    final set = columnFilterOf(id);
    if (set.isEmpty) return null;
    return set.join(',');
  }

  SrmPurchaseOrderQuery _listQuery({int? page}) {
    return SrmPurchaseOrderQuery(
      keyword:
          topSearchCtrl.text.trim().isEmpty ? null : topSearchCtrl.text.trim(),
      brandName: _joinedColumnFilter('brand'),
      contractType: _joinedColumnFilter('contractType'),
      pageNum: page ?? pageNum.value,
      pageSize: pageSize.value,
    );
  }

  Future<void> refreshAll({bool clearSelected = false}) async {
    if (clearSelected) clearSelection();
    loading.value = true;
    errorMessage.value = null;
    try {
      final query = _listQuery();
      final listFuture = _api.fetchList(query);
      final kpiFuture = _api.fetchKpi(query);
      final page = await listFuture;
      total.value = page.total;
      rows
        ..clear()
        ..addAll(page.rows);
      kpi.value = await kpiFuture;
    } catch (e) {
      errorMessage.value = e.toString();
      rows.clear();
      total.value = 0;
    } finally {
      loading.value = false;
    }
  }

  Future<void> search() async {
    pageNum.value = 1;
    await refreshAll(clearSelected: true);
  }

  Future<void> goPage(int page) async {
    final target = page.clamp(1, totalPages);
    if (target == pageNum.value) return;
    pageNum.value = target;
    await refreshAll(clearSelected: true);
  }

  Future<void> changePageSize(int size) async {
    if (size == pageSize.value) return;
    pageSize.value = size;
    pageNum.value = 1;
    await refreshAll(clearSelected: true);
  }

  /// 导出当前勾选采购订单；返回文件字节与建议文件名。
  Future<({Uint8List bytes, String fileName})> exportSelected() async {
    final ids = <int>[];
    for (final raw in selectedIds) {
      final id = int.tryParse(raw);
      if (id != null) ids.add(id);
    }
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请先勾选要导出的采购订单');
    }
    exporting.value = true;
    try {
      return await _api.export(
        ids: ids,
        keyword: topSearchCtrl.text.trim().isEmpty
            ? null
            : topSearchCtrl.text.trim(),
        brandName: _joinedColumnFilter('brand'),
      );
    } finally {
      exporting.value = false;
    }
  }
}
