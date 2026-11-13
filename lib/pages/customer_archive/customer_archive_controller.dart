import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../models/customer_archive.dart';
import '../../models/dict_data.dart';
import '../../services/customer_api.dart';
import '../../services/dict_api.dart';

/// 列表列 id → 导出接口 `exportColumns` 字段名（序号由服务端固定导出，不含操作/日志）。
const kCustomerArchiveExportColumnKeys = <String, String>{
  'type': 'customerType',
  'market': 'marketScale',
  'icon': 'iconUrl',
  'brand': 'name',
  'industry': 'industry',
  'entityCount': 'enterpriseCount',
  'entityName': 'enterpriseNames',
  'relation': 'relationTypes',
  'nature': 'entityNatures',
  'city': 'cities',
  'address': 'addresses',
  'contact': 'contactNames',
  'createTime': 'createTime',
  'dynamic': 'latestDynamic',
  'owner': 'ownerNames',
  'assignTime': 'assignTime',
  'assignDays': 'assignDays',
  'status': 'status',
  'remark': 'remark',
};

/// Tab / 下拉选项：接口用 [value]（字典键），界面用 [label]（字典标签）。
class ArchiveDictOption {
  const ArchiveDictOption({required this.value, required this.label});
  final String value;
  final String label;
}

class CustomerArchiveController extends LxController {
  final topSearchCtrl = TextEditingController();
  final keywordCtrl = TextEditingController();
  final salespersonCtrl = TextEditingController();
  final _api = CustomerApi();
  final _dictApi = DictApi();

  final typeTab = 0.obs;
  final marketLevel = Rxn<String>();
  final industry = Rxn<String>();
  final status = Rxn<String>();
  final tableSearchVisible = false.obs;

  /// 列表「列设置」中勾掉的列 id（序号 / 操作始终显示）。
  final hiddenColumnIds = <String>{}.obs;
  final selectedIds = <String>{}.obs;

  final stats = CustomerArchiveStats().obs;
  final rows = <CustomerArchive>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 20.obs;
  final loading = false.obs;
  final exporting = false.obs;
  final dataAsOf = ''.obs;
  final errorMessage = Rxn<String>();

  /// 含「全部」；[ArchiveDictOption.value] 为空表示全部。
  final typeTabs = <ArchiveDictOption>[
    const ArchiveDictOption(value: '', label: '全部'),
    const ArchiveDictOption(value: 'brand', label: '品牌企业'),
    const ArchiveDictOption(value: 'channel', label: '渠道广告公司'),
    const ArchiveDictOption(value: 'agency', label: '4A公司'),
    const ArchiveDictOption(value: 'gov', label: '政务单位'),
    const ArchiveDictOption(value: 'dsp', label: 'DSP/API'),
  ].obs;

  final marketOptions = <ArchiveDictOption>[].obs;
  final industryOptions = <ArchiveDictOption>[].obs;
  final statusOptions = <ArchiveDictOption>[
    const ArchiveDictOption(value: '正常', label: '正常'),
    const ArchiveDictOption(value: '停用', label: '停用'),
  ].obs;

  /// dictType → (dictValue → dictLabel)
  final _labelMaps = <String, Map<String, String>>{};

  /// 字典加载完成后递增，驱动列表标签刷新。
  final dictVersion = 0.obs;

  static const _fallbackCustomerType = {
    'brand': '品牌企业',
    'agency': '4A公司',
    'channel': '渠道广告公司',
    'gov': '政务单位',
    'dsp': 'DSP/API',
  };

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onDispose() {
    topSearchCtrl.dispose();
    keywordCtrl.dispose();
    salespersonCtrl.dispose();
    super.onDispose();
  }

  Future<void> _bootstrap() async {
    await _loadDicts();
    await refreshAll();
  }

  Future<void> _loadDicts() async {
    final maps = await _dictApi.fetchMany(const [
      OacDictTypes.customerType,
      OacDictTypes.marketScale,
      OacDictTypes.industry,
      OacDictTypes.relationType,
      OacDictTypes.entityNature,
    ]);
    _labelMaps
      ..clear()
      ..addEntries(
        maps.entries.map(
          (e) => MapEntry(e.key, {
            for (final i in e.value)
              if ((i.dictValue?.trim().isNotEmpty ?? false) &&
                  (i.dictLabel?.trim().isNotEmpty ?? false))
                i.dictValue!.trim(): i.dictLabel!.trim(),
          }),
        ),
      );

    final types = maps[OacDictTypes.customerType] ?? const [];
    if (types.isNotEmpty) {
      typeTabs.replaceAll([
        const ArchiveDictOption(value: '', label: '全部'),
        for (final i in types)
          if (i.dictValue?.trim().isNotEmpty ?? false)
            ArchiveDictOption(
              value: i.dictValue!.trim(),
              label: i.dictLabel?.trim().isNotEmpty == true
                  ? i.dictLabel!.trim()
                  : i.dictValue!.trim(),
            ),
      ]);
    }

    // 市场级别 / 行业筛选：接口存 dictLabel，选项 value 取标签文案。
    marketOptions.replaceAll([
      for (final i in maps[OacDictTypes.marketScale] ?? const <DictDataItem>[])
        if (i.dictLabel?.trim().isNotEmpty ?? false)
          ArchiveDictOption(
            value: i.dictLabel!.trim(),
            label: i.dictLabel!.trim(),
          ),
    ]);
    industryOptions.replaceAll([
      for (final i in maps[OacDictTypes.industry] ?? const <DictDataItem>[])
        if (i.dictLabel?.trim().isNotEmpty ?? false)
          ArchiveDictOption(
            value: i.dictLabel!.trim(),
            label: i.dictLabel!.trim(),
          ),
    ]);
    dictVersion.value++;
  }

  /// 将接口字典键（可逗号分隔）转成标签；找不到则原样返回。
  String labelOf(String dictType, String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '-';
    final map = {
      ...?_labelMaps[dictType],
      if (dictType == OacDictTypes.customerType) ..._fallbackCustomerType,
    };
    final parts = text
        .split(RegExp(r'[,，/;|、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '-';
    return parts.map((p) => map[p] ?? p).join('、');
  }

  String customerTypeLabel(String? raw) =>
      labelOf(OacDictTypes.customerType, raw);

  String marketLabel(String? raw) => labelOf(OacDictTypes.marketScale, raw);

  String industryLabel(String? raw) => labelOf(OacDictTypes.industry, raw);

  String relationLabel(String? raw) => labelOf(OacDictTypes.relationType, raw);

  String entityNatureLabel(String? raw) =>
      labelOf(OacDictTypes.entityNature, raw);

  bool isColumnVisible(String id) => !hiddenColumnIds.contains(id);

  void setColumnVisible(String id, bool visible) {
    if (visible) {
      hiddenColumnIds.remove(id);
    } else {
      hiddenColumnIds.add(id);
    }
    hiddenColumnIds.refresh();
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

  String? get _keyword {
    final tableKw = keywordCtrl.text.trim();
    if (tableKw.isNotEmpty) return tableKw;
    final topKw = topSearchCtrl.text.trim();
    return topKw.isEmpty ? null : topKw;
  }

  String? get _selectedType {
    final tabs = typeTabs;
    if (typeTab.value < 0 || typeTab.value >= tabs.length) return null;
    final v = tabs[typeTab.value].value.trim();
    return v.isEmpty ? null : v;
  }

  String get selectedTypeTabLabel {
    final tabs = typeTabs;
    if (typeTab.value < 0 || typeTab.value >= tabs.length) return '全部';
    return tabs[typeTab.value].label;
  }

  OacCustomerQuery _listQuery() {
    return OacCustomerQuery(
      customerType: _selectedType,
      marketScale: marketLevel.value,
      industry: industry.value,
      status: status.value,
      keyword: _keyword,
      ownerNames: salespersonCtrl.text.trim().isEmpty
          ? null
          : salespersonCtrl.text.trim(),
      pageNum: pageNum.value,
      pageSize: pageSize.value,
    );
  }

  Future<void> refreshAll() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final listFuture = _api.fetchList(_listQuery());
      final statsFuture = _loadStats();
      final page = await listFuture;
      total.value = page.total;
      rows.replaceAll(page.rows);
      final overview = await statsFuture;
      stats.value = overview;
      final asOf = overview.dataAsOf?.trim();
      dataAsOf.value =
          (asOf != null && asOf.isNotEmpty) ? asOf : _nowText();
    } catch (e) {
      errorMessage.value = e.toString();
      rows.clear();
      total.value = 0;
    } finally {
      loading.value = false;
    }
  }

  Future<CustomerArchiveStats> _loadStats() async {
    // 与列表同筛选；类型 Tab 也传入，便于概览随 Tab 变化。
    return _api.fetchOverview(
      OacCustomerQuery(
        customerType: _selectedType,
        marketScale: marketLevel.value,
        industry: industry.value,
        status: status.value,
        keyword: _keyword,
        ownerNames: salespersonCtrl.text.trim().isEmpty
            ? null
            : salespersonCtrl.text.trim(),
        pageNum: 1,
        pageSize: 20,
      ),
    );
  }

  Future<void> search() async {
    pageNum.value = 1;
    await refreshAll();
  }

  Future<void> resetFilters() async {
    keywordCtrl.clear();
    salespersonCtrl.clear();
    marketLevel.value = null;
    industry.value = null;
    status.value = null;
    typeTab.value = 0;
    pageNum.value = 1;
    await refreshAll();
  }

  Future<void> selectTypeTab(int index) async {
    typeTab.value = index;
    pageNum.value = 1;
    await refreshAll();
  }

  Future<void> changePageSize(int size) async {
    if (size == pageSize.value) return;
    pageSize.value = size;
    pageNum.value = 1;
    await refreshAll();
  }

  Future<void> goPage(int page) async {
    if (page < 1 || page > totalPages) return;
    pageNum.value = page;
    await refreshAll();
  }

  /// 按当前筛选 + 可见列导出 Excel（序号由服务端固定导出）。
  Future<({Uint8List bytes, String fileName})> exportExcel() async {
    if (exporting.value) {
      throw CustomerApiException('正在导出，请稍候');
    }
    final columns = <String>[
      for (final entry in kCustomerArchiveExportColumnKeys.entries)
        if (isColumnVisible(entry.key)) entry.value,
    ];
    if (columns.isEmpty) {
      throw CustomerApiException('没有可导出的列，请先在列设置中勾选');
    }
    exporting.value = true;
    try {
      return await _api.export(
        query: _listQuery(),
        exportColumns: columns.join(','),
      );
    } finally {
      exporting.value = false;
    }
  }

  String _nowText() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)} ${two(n.hour)}:${two(n.minute)}';
  }
}
