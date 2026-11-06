import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/srm_supplier.dart';
import '../../../services/srm_supplier_api.dart';

class SupplierListController extends LxController {
  final _api = SrmSupplierApi();

  final topSearchCtrl = TextEditingController();
  final keywordCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final staffCtrl = TextEditingController();
  final teamSizeMinCtrl = TextEditingController();
  final teamSizeMaxCtrl = TextEditingController();

  final supplierType = Rxn<String>();
  final cooperationMode = Rxn<String>();
  final settlementMethod = Rxn<String>();
  final status = Rxn<String>();
  final blacklistStatus = Rxn<String>();
  final filterExpanded = false.obs;
  final hiddenColumnIds = <String>{}.obs;
  /// 表格勾选行主键（字符串形式的 int64）。
  final selectedIds = <String>{}.obs;

  final kpi = SrmSupplierKpi().obs;
  final rows = <SrmSupplier>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 10.obs;
  final loading = false.obs;
  final exporting = false.obs;
  final errorMessage = Rxn<String>();

  static const supplierTypeOptions = <(String? value, String label)>[
    (null, '全部'),
    ('设备采购', '设备采购'),
    ('媒介采购', '媒介采购'),
    ('物业租赁', '物业租赁'),
    ('维保运维', '维保运维'),
    ('灵活用工', '灵活用工'),
    ('技术服务', '技术服务'),
    ('物料制作', '物料制作'),
    ('工程施工', '工程施工'),
    ('其它', '其它'),
  ];

  static const cooperationModeOptions = <(String? value, String label)>[
    (null, '全部'),
    ('框架协议', '框架协议'),
    ('单次采购', '单次采购'),
  ];

  static const settlementMethodOptions = <(String? value, String label)>[
    ('30天', '30天'),
    ('60天', '60天'),
    ('90天', '90天'),
    ('按次结算', '按次结算'),
  ];

  /// 列头已应用的多选筛选：columnId → 选中值。
  final columnFilters = <String, Set<String>>{}.obs;

  /// 列头可选项：同一列表接口里该列已经出现的值。
  final columnOptions = <String, List<String>>{}.obs;

  static const statusOptions = <(String? value, String label)>[
    (null, '全部'),
    ('0', '草稿'),
    ('1', '启用'),
    ('2', '停用'),
  ];

  static const blacklistOptions = <(String? value, String label)>[
    (null, '全部'),
    ('0', '否'),
    ('1', '是'),
  ];

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onDispose() {
    topSearchCtrl.dispose();
    keywordCtrl.dispose();
    addressCtrl.dispose();
    contactCtrl.dispose();
    staffCtrl.dispose();
    teamSizeMinCtrl.dispose();
    teamSizeMaxCtrl.dispose();
    super.onDispose();
  }

  void toggleFilterExpanded() {
    filterExpanded.value = !filterExpanded.value;
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

  /// [ids] 为可开关列；[visible] 为 true 时全部显示，否则全部隐藏。
  void setAllColumnsVisible(Iterable<String> ids, bool visible) {
    if (visible) {
      hiddenColumnIds.removeAll(ids);
    } else {
      hiddenColumnIds.addAll(ids);
    }
    hiddenColumnIds.refresh();
  }

  void setSelectedRows(List<SrmSupplier> selected) {
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

  /// 当前列已有值，并保留仍勾选、但本次结果里没出现的项。
  List<String> columnOptionsOf(String id) {
    final values = <String>{
      ...?columnOptions[id],
      ...columnFilterOf(id),
    };
    final list = values.toList();
    if (id == 'teamSize') {
      list.sort((a, b) {
        final na = int.tryParse(a);
        final nb = int.tryParse(b);
        if (na != null && nb != null) return na.compareTo(nb);
        return a.compareTo(b);
      });
    } else {
      list.sort();
    }
    return list;
  }

  bool hasColumnFilter(String id) => columnFilterOf(id).isNotEmpty;

  Future<void> applyColumnFilter(String id, Set<String> selected) async {
    if (selected.isEmpty) {
      columnFilters.remove(id);
    } else {
      columnFilters[id] = Set<String>.from(selected);
    }
    columnFilters.refresh();
    // 与顶部单选筛选项对齐（取多选拼接）。
    switch (id) {
      case 'supplierType':
        supplierType.value =
            selected.isEmpty ? null : selected.join(',');
      case 'coop':
        cooperationMode.value =
            selected.isEmpty ? null : selected.join(',');
      case 'settle':
        settlementMethod.value =
            selected.isEmpty ? null : selected.join(',');
      case 'teamSize':
        final range = _teamSizeRange(selected);
        teamSizeMinCtrl.text = range.$1?.toString() ?? '';
        teamSizeMaxCtrl.text = range.$2?.toString() ?? '';
    }
    pageNum.value = 1;
    await refreshAll(clearSelected: true);
  }

  /// 勾选的是列里已有人数；查询仍走最小/最大人数。
  (int?, int?) _teamSizeRange(Set<String> selected) {
    if (selected.isEmpty) return (null, null);
    var minV = 1 << 30;
    var maxV = 0;
    var any = false;
    for (final s in selected) {
      final n = int.tryParse(s.trim());
      if (n == null) continue;
      any = true;
      minV = math.min(minV, n);
      maxV = math.max(maxV, n);
    }
    if (!any) return (null, null);
    return (minV, maxV);
  }

  String? _joinedColumnFilter(String id) {
    final set = columnFilterOf(id);
    if (set.isEmpty) return null;
    return set.join(',');
  }

  SrmSupplierQuery _listQuery({int? page}) {
    final typeFilter =
        _joinedColumnFilter('supplierType') ?? supplierType.value;
    final coopFilter =
        _joinedColumnFilter('coop') ?? cooperationMode.value;
    final settleFilter =
        _joinedColumnFilter('settle') ?? settlementMethod.value;
    final teamFromCol = _teamSizeRange(columnFilterOf('teamSize'));
    final teamMin = teamFromCol.$1 ?? int.tryParse(teamSizeMinCtrl.text.trim());
    final teamMax = teamFromCol.$2 ?? int.tryParse(teamSizeMaxCtrl.text.trim());

    return SrmSupplierQuery(
      keyword: keywordCtrl.text.trim().isEmpty ? null : keywordCtrl.text.trim(),
      searchKeyword:
          topSearchCtrl.text.trim().isEmpty ? null : topSearchCtrl.text.trim(),
      supplierType: typeFilter,
      supplyCategory: _joinedColumnFilter('category'),
      enterpriseNature: _joinedColumnFilter('nature'),
      city: _joinedColumnFilter('city'),
      cooperationMode: coopFilter,
      settlementMethod: settleFilter,
      status: status.value,
      blacklistStatus: blacklistStatus.value,
      teamSizeMin: teamMin,
      teamSizeMax: teamMax,
      addressKeyword:
          addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      contactKeyword:
          contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
      staffKeyword: staffCtrl.text.trim().isEmpty ? null : staffCtrl.text.trim(),
      pageNum: page ?? pageNum.value,
      pageSize: pageSize.value,
    );
  }

  Future<void> refreshAll({bool clearSelected = false}) async {
    if (clearSelected) clearSelection();
    loading.value = true;
    errorMessage.value = null;
    try {
      final listFuture = _api.fetchList(_listQuery());
      final statsFuture = _api.fetchStats();
      final optionsFuture = _loadColumnOptions();
      final page = await listFuture;
      total.value = page.total;
      rows
        ..clear()
        ..addAll(page.rows);
      kpi.value = await statsFuture;
      await optionsFuture;
    } catch (e) {
      errorMessage.value = e.toString();
      rows.clear();
      total.value = 0;
    } finally {
      loading.value = false;
    }
  }

  /// 去掉列筛选后拉取列表，收集各列已经出现的值。
  Future<void> _loadColumnOptions() async {
    try {
      final query = _listQuery(page: 1)
        ..supplierType = null
        ..supplyCategory = null
        ..enterpriseNature = null
        ..city = null
        ..cooperationMode = null
        ..settlementMethod = null
        ..teamSizeMin = null
        ..teamSizeMax = null
        ..pageSize = 200;
      var page = await _api.fetchList(query);
      if (page.total > page.rows.length) {
        query.pageSize = page.total.clamp(1, 5000);
        page = await _api.fetchList(query);
      }
      final types = <String>{};
      final categories = <String>{};
      final natures = <String>{};
      final teamSizes = <String>{};
      final coops = <String>{};
      final settles = <String>{};
      final cities = <String>{};
      for (final row in page.rows) {
        _addSplit(types, row.supplierType);
        _addSplit(categories, row.supplyCategoryText);
        _addText(natures, row.enterpriseNature);
        final size = row.teamSize;
        if (size != null) teamSizes.add('$size');
        _addText(coops, row.cooperationMode);
        _addText(settles, row.settlementMethod);
        final city = row.city?.trim();
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        } else {
          _addText(cities, row.regionName);
        }
      }
      columnOptions['supplierType'] = (types.toList()..sort());
      columnOptions['category'] = (categories.toList()..sort());
      columnOptions['nature'] = (natures.toList()..sort());
      columnOptions['teamSize'] = (teamSizes.toList()
        ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0)));
      columnOptions['coop'] = (coops.toList()..sort());
      columnOptions['settle'] = (settles.toList()..sort());
      columnOptions['city'] = (cities.toList()..sort());
      columnOptions.refresh();
    } catch (_) {
      // 可选项加载失败时保留上一次的结果，列表本身仍可用。
    }
  }

  void _addText(Set<String> into, String? raw) {
    final text = raw?.trim();
    if (text != null && text.isNotEmpty) into.add(text);
  }

  void _addSplit(Set<String> into, String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return;
    for (final part in text.split(RegExp(r'[,，、/|]'))) {
      final item = part.trim();
      if (item.isNotEmpty) into.add(item);
    }
  }

  /// 顶部结算方式：只接受固定项；自定义天数由列头筛选回写。
  void setSettlementFromTop(String? value) {
    settlementMethod.value = value;
    if (value == null || value.trim().isEmpty) {
      columnFilters.remove('settle');
    } else {
      columnFilters['settle'] = {value.trim()};
    }
    columnFilters.refresh();
  }

  Future<void> search() async {
    pageNum.value = 1;
    await refreshAll(clearSelected: true);
  }

  Future<void> resetFilters() async {
    keywordCtrl.clear();
    addressCtrl.clear();
    contactCtrl.clear();
    staffCtrl.clear();
    teamSizeMinCtrl.clear();
    teamSizeMaxCtrl.clear();
    supplierType.value = null;
    cooperationMode.value = null;
    settlementMethod.value = null;
    status.value = null;
    blacklistStatus.value = null;
    columnFilters.clear();
    columnFilters.refresh();
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

  /// 导出当前勾选供应商；返回文件字节与建议文件名。
  Future<({Uint8List bytes, String fileName})> exportSelected() async {
    final ids = <int>[];
    for (final raw in selectedIds) {
      final id = int.tryParse(raw);
      if (id != null) ids.add(id);
    }
    if (ids.isEmpty) {
      throw SrmSupplierApiException('请先勾选要导出的供应商');
    }
    exporting.value = true;
    try {
      return await _api.export(
        ids: ids,
        keyword: keywordCtrl.text.trim().isEmpty
            ? null
            : keywordCtrl.text.trim(),
        supplierType: supplierType.value,
        status: status.value,
      );
    } finally {
      exporting.value = false;
    }
  }
}
