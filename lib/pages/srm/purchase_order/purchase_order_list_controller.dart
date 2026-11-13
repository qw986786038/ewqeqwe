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

  /// 列头可选项：从列表数据里出现过的值收集，不写死。
  final columnOptions = <String, List<String>>{}.obs;

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
    setSelectedKeys({
      for (final e in selected)
        if ((e.id?.trim() ?? '').isNotEmpty) e.id!.trim(),
    });
  }

  void setSelectedKeys(Set<Object> keys) {
    selectedIds
      ..clear()
      ..addAll(
        keys
            .map((e) => e.toString().trim())
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

  /// 当前列已有值，并保留仍勾选、但本页没出现的项。
  List<String> columnOptionsOf(String id) {
    final values = <String>{
      ...?columnOptions[id],
      ...columnFilterOf(id),
    };
    final list = values.toList()..sort();
    return list;
  }

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
      final optionsFuture = _loadColumnOptions();
      final page = await listFuture;
      total.value = page.total;
      rows
        ..clear()
        ..addAll(page.rows);
      kpi.value = await kpiFuture;
      await optionsFuture;
    } catch (e) {
      errorMessage.value = e.toString();
      rows.clear();
      total.value = 0;
    } finally {
      loading.value = false;
    }
  }

  /// 用同一列表接口、去掉列筛选，收集关联品牌和合同类型里已经出现的值。
  Future<void> _loadColumnOptions() async {
    try {
      final keyword = topSearchCtrl.text.trim();
      final query = SrmPurchaseOrderQuery(
        keyword: keyword.isEmpty ? null : keyword,
        pageNum: 1,
        pageSize: 200,
      );
      var page = await _api.fetchList(query);
      if (page.total > page.rows.length) {
        page = await _api.fetchList(
          SrmPurchaseOrderQuery(
            keyword: query.keyword,
            pageNum: 1,
            pageSize: page.total.clamp(1, 5000),
          ),
        );
      }
      final brands = <String>{};
      final types = <String>{};
      for (final row in page.rows) {
        final brand = row.brandName?.trim();
        if (brand != null && brand.isNotEmpty) brands.add(brand);
        final type = row.contractType?.trim();
        if (type != null && type.isNotEmpty) types.add(type);
      }
      columnOptions['brand'] = (brands.toList()..sort());
      columnOptions['contractType'] = (types.toList()..sort());
      columnOptions.refresh();
    } catch (_) {
      // 可选项加载失败时保留上一次的结果，列表本身仍可用。
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
