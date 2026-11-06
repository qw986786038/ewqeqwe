import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../models/dict_data.dart';
import '../models/oac_agency.dart';
import '../models/oac_brand.dart';
import '../models/oac_enterprise.dart';
import '../models/oac_person.dart';
import '../services/agency_api.dart';
import '../services/auth_session.dart';
import '../services/brand_api.dart';
import '../services/dict_api.dart';
import '../services/enterprise_api.dart';
import '../services/person_api.dart';

/// 订单管理列表排序项（与工具栏「排序」菜单一致）。
class BrandListSortOption {
  const BrandListSortOption({
    required this.column,
    required this.asc,
    required this.label,
  });

  final String column;
  final bool asc;
  final String label;

  String get key => '$column:${asc ? 'asc' : 'desc'}';
}

const kBrandListSortOptions = <BrandListSortOption>[
  BrandListSortOption(
    column: 'orderAmount',
    asc: false,
    label: '订单金额 ↓',
  ),
  BrandListSortOption(
    column: 'orderAmount',
    asc: true,
    label: '订单金额 ↑',
  ),
  BrandListSortOption(
    column: 'orderCount',
    asc: false,
    label: '订单数量 ↓',
  ),
  BrandListSortOption(
    column: 'orderCount',
    asc: true,
    label: '订单数量 ↑',
  ),
  BrandListSortOption(
    column: 'latestOrderTime',
    asc: false,
    label: '最新订单时间 ↓',
  ),
  BrandListSortOption(
    column: 'latestOrderTime',
    asc: true,
    label: '最新订单时间 ↑',
  ),
];

class HomeController extends LxController {
  HomeController({Map<String, dynamic>? loginData}) {
    if (loginData != null && AuthSession.accessToken == null) {
      AuthSession.saveFromLogin(loginData);
    }
  }

  final _api = BrandApi();
  final _enterpriseApi = EnterpriseApi();
  final _agencyApi = AgencyApi();
  final _personApi = PersonApi();
  final _dictApi = DictApi();

  final keywordCtrl = TextEditingController();
  final amountMinCtrl = TextEditingController();
  final amountMaxCtrl = TextEditingController();

  /// 筛选项（下拉 / 日期）；提交时写入 [_buildQuery]。
  final industry = Rxn<String>();
  final city = Rxn<String>();
  final tags = Rxn<String>();
  final mediaType = Rxn<String>();
  final relationType = Rxn<String>();
  final ownerNames = Rxn<String>();
  final enterpriseType = Rxn<String>();
  final latestEmployer = Rxn<String>();
  final orderTimeBegin = Rxn<DateTime>();
  final orderTimeEnd = Rxn<DateTime>();

  final industryOptions = <({String value, String label})>[].obs;
  final cityOptions = <String>[].obs;
  final tagOptions = <String>[].obs;
  final relationTypeOptions = <({String value, String label})>[].obs;
  final ownerOptions = <String>[].obs;
  final enterpriseTypeOptions = <String>[].obs;
  final employerOptions = <String>[].obs;

  /// 企业视角 · 媒体类型（与筛选下拉一致）。
  static const mediaTypeOptions = <String>[
    '楼宇电梯',
    '地铁灯箱',
    '高铁',
    '机场',
    '候车亭',
    '商圈 LED',
  ];

  /// 行业 dictValue / dictLabel → 中文展示。
  final _industryLabels = <String, String>{};

  /// 标签 dictValue / dictLabel → 中文展示。
  final _tagLabels = <String, String>{};

  /// 关联关系 dictValue / dictLabel → 中文展示。
  final _relationTypeLabels = <String, String>{};

  final overview = Rxn<OacBrandOverview>();
  final brands = <OacBrand>[].obs;
  final enterpriseOverview = Rxn<OacEnterpriseOverview>();
  final enterprises = <OacEnterprise>[].obs;
  final agencyOverview = Rxn<OacAgencyOverview>();
  final agencies = <OacAgency>[].obs;
  final personOverview = Rxn<OacPersonOverview>();
  final persons = <OacPerson>[].obs;
  final total = 0.obs;
  final pageNum = 1.obs;
  final pageSize = 20.obs;
  final quickTag = Rxn<String>();
  /// 0 品牌 / 1 企业 / 2 4A / 3 人
  final entityTab = 0.obs;

  bool get isBrandTab => entityTab.value == 0;
  bool get isEnterpriseTab => entityTab.value == 1;
  bool get isAgencyTab => entityTab.value == 2;
  bool get isPersonTab => entityTab.value == 3;

  /// 左侧菜单：`orders` / `customers` / `hrm_*` / `srm_*` 等。
  final sideMenu = 'orders'.obs;

  final List<String> _menuBack = [];
  final List<String> _menuForward = [];

  /// 侧栏切页，并记入面包屑前进 / 后退。
  void openSideMenu(String id) {
    if (id == sideMenu.value) return;
    _menuBack.add(sideMenu.value);
    _menuForward.clear();
    sideMenu.value = id;
  }

  /// 面包屑「向后」。没有更早的页面时返回 false。
  bool goSideMenuBack() {
    if (_menuBack.isEmpty) return false;
    _menuForward.add(sideMenu.value);
    sideMenu.value = _menuBack.removeLast();
    return true;
  }

  /// 面包屑「向前」。没有更新的页面时返回 false。
  bool goSideMenuForward() {
    if (_menuForward.isEmpty) return false;
    _menuBack.add(sideMenu.value);
    sideMenu.value = _menuForward.removeLast();
    return true;
  }

  /// 品牌列表工具栏：是否显示行内搜索框
  final tableSearchVisible = false.obs;

  /// 列设置：隐藏的列 id（序号 / 操作固定显示）。
  final hiddenColumnIds = <String>{}.obs;

  /// 当前排序（默认订单金额降序，对齐设计稿）。
  final sortKey = kBrandListSortOptions.first.key.obs;

  final overviewLoading = false.obs;
  final listLoading = false.obs;
  final exporting = false.obs;
  final errorMessage = Rxn<String>();

  /// 顶栏全局搜索（UI 占位，列表筛选用下方关键词）
  final topSearchCtrl = TextEditingController();

  String get displayName {
    final data = AuthSession.loginData;
    if (data == null) return '用户';
    final user = data['user'];
    if (user is Map) {
      final nick = user['nickName']?.toString() ?? user['nickname']?.toString();
      if (nick != null && nick.isNotEmpty) return nick;
      final name = user['userName']?.toString() ?? user['username']?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
    return '用户';
  }

  BrandListSortOption get currentSort {
    for (final o in kBrandListSortOptions) {
      if (o.key == sortKey.value) return o;
    }
    return kBrandListSortOptions.first;
  }

  @override
  void onInit() {
    super.onInit();
    _loadFilterOptions();
    refreshAll();
  }

  @override
  void onDispose() {
    topSearchCtrl.dispose();
    keywordCtrl.dispose();
    amountMinCtrl.dispose();
    amountMaxCtrl.dispose();
    super.onDispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final maps = await _dictApi.fetchMany(const [
        OacDictTypes.industry,
        OacDictTypes.customerTag,
        OacDictTypes.relationType,
      ]);
      final industryItems = maps[OacDictTypes.industry] ?? const <DictDataItem>[];
      _industryLabels
        ..clear()
        ..addEntries([
          for (final i in industryItems)
            if ((i.dictLabel?.trim().isNotEmpty ?? false)) ...[
              if (i.dictValue?.trim().isNotEmpty ?? false)
                MapEntry(i.dictValue!.trim(), i.dictLabel!.trim()),
              MapEntry(i.dictLabel!.trim(), i.dictLabel!.trim()),
            ],
        ]);
      // 行业筛选与档案一致：接口存 dictLabel。
      industryOptions.replaceAll([
        for (final i in industryItems)
          if (i.dictLabel?.trim().isNotEmpty ?? false)
            (
              value: i.dictLabel!.trim(),
              label: i.dictLabel!.trim(),
            ),
      ]);

      final tagItems =
          maps[OacDictTypes.customerTag] ?? const <DictDataItem>[];
      _tagLabels
        ..clear()
        ..addEntries([
          for (final i in tagItems)
            if ((i.dictLabel?.trim().isNotEmpty ?? false)) ...[
              if (i.dictValue?.trim().isNotEmpty ?? false)
                MapEntry(i.dictValue!.trim(), i.dictLabel!.trim()),
              MapEntry(i.dictLabel!.trim(), i.dictLabel!.trim()),
            ],
        ]);
      // 标签筛选 / 多选：展示与提交均用 dictLabel。
      tagOptions.replaceAll([
        for (final i in tagItems)
          if (i.dictLabel?.trim().isNotEmpty ?? false) i.dictLabel!.trim(),
      ]);

      final relationItems =
          maps[OacDictTypes.relationType] ?? const <DictDataItem>[];
      _relationTypeLabels
        ..clear()
        ..addEntries([
          for (final i in relationItems)
            if ((i.dictLabel?.trim().isNotEmpty ?? false)) ...[
              if (i.dictValue?.trim().isNotEmpty ?? false)
                MapEntry(i.dictValue!.trim(), i.dictLabel!.trim()),
              MapEntry(i.dictLabel!.trim(), i.dictLabel!.trim()),
            ],
        ]);
      relationTypeOptions.replaceAll([
        for (final i in relationItems)
          if (i.dictLabel?.trim().isNotEmpty ?? false)
            (
              value: (i.dictValue?.trim().isNotEmpty ?? false)
                  ? i.dictValue!.trim()
                  : i.dictLabel!.trim(),
              label: i.dictLabel!.trim(),
            ),
      ]);
    } catch (_) {
      // 字典失败时仍可用列表数据推导的其它筛选项。
    }
  }

  String relationTypeLabel(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '';
    return _relationTypeLabels[text] ?? text;
  }

  /// 将接口行业字段（编码或中文、可多值）转成中文展示。
  String industryLabel(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '-';
    final parts = text
        .split(RegExp(r'[,，/;|、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '-';
    return parts.map((p) => _industryLabels[p] ?? p).join('、');
  }

  /// 单条标签编码 / 文案 → 中文展示。
  String tagLabel(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '';
    return _tagLabels[text] ?? text;
  }

  /// 列表内改标签（暂无后端保存接口时仅更新本地行）。
  void applyBrandTags(OacBrand row, List<String> tags) {
    final cleaned = [
      for (final t in tags)
        if (t.trim().isNotEmpty) t.trim(),
    ];
    row.tagList = cleaned;
    row.tags = cleaned.isEmpty ? null : cleaned.join(',');
    brands.refresh();
  }

  Future<void> selectEntityTab(int index) async {
    if (entityTab.value == index) return;
    entityTab.value = index;
    pageNum.value = 1;
    errorMessage.value = null;
    // 销售员 / 人视角筛选项随列表重建，切换时先清空以免串视角。
    ownerOptions.clear();
    ownerNames.value = null;
    enterpriseTypeOptions.clear();
    employerOptions.clear();
    enterpriseType.value = null;
    latestEmployer.value = null;
    if (index >= 0 && index <= 3) {
      await refreshAll();
    } else {
      overview.value = null;
      enterpriseOverview.value = null;
      agencyOverview.value = null;
      personOverview.value = null;
      brands.clear();
      enterprises.clear();
      agencies.clear();
      persons.clear();
      total.value = 0;
    }
  }

  void _mergeCityFacetOptions(Iterable<String?> citiesIn) {
    final cities = {...cityOptions};
    for (final c in citiesIn) {
      final v = c?.trim();
      if (v != null && v.isNotEmpty) cities.add(v);
    }
    final sortedCities = cities.toList()..sort();
    cityOptions.replaceAll(sortedCities);
  }

  /// 销售员筛选项：仅取当前视角本次列表行中的人员（去重排序，整表替换）。
  void _replaceOwnerOptionsFromList({
    required Iterable<List<String>?> ownerLists,
    required Iterable<String?> ownerNamesRaw,
  }) {
    final owners = <String>{};
    for (final ownerList in ownerLists) {
      if (ownerList == null) continue;
      for (final n in ownerList) {
        final v = n.trim();
        if (v.isNotEmpty) owners.add(v);
      }
    }
    for (final raw in ownerNamesRaw) {
      final text = raw?.trim();
      if (text == null || text.isEmpty) continue;
      for (final part in text.split(RegExp(r'[,，;；、/|]+'))) {
        final v = part.trim();
        if (v.isNotEmpty) owners.add(v);
      }
    }
    final selected = ownerNames.value?.trim();
    if (selected != null &&
        selected.isNotEmpty &&
        !owners.contains(selected)) {
      // 已选人不在本页时仍保留筛选值，避免翻页/刷新把条件冲掉。
      owners.add(selected);
    }
    final sorted = owners.toList()..sort();
    ownerOptions.replaceAll(sorted);
  }

  void _mergeBrandFacetOptions(List<OacBrand> rows) {
    _mergeCityFacetOptions(rows.map((e) => e.city));
    _replaceOwnerOptionsFromList(
      ownerLists: rows.map((e) => e.ownerNameList),
      ownerNamesRaw: rows.map((e) => e.ownerNames),
    );
  }

  void _mergeEnterpriseFacetOptions(List<OacEnterprise> rows) {
    _mergeCityFacetOptions(rows.map((e) => e.city));
    _replaceOwnerOptionsFromList(
      ownerLists: rows.map((e) => e.ownerNameList),
      ownerNamesRaw: rows.map((e) => e.ownerNames),
    );
  }

  void _mergeAgencyFacetOptions(List<OacAgency> rows) {
    _mergeCityFacetOptions(rows.map((e) => e.city));
    _replaceOwnerOptionsFromList(
      ownerLists: rows.map((e) => e.ownerNameList),
      ownerNamesRaw: rows.map((e) => e.ownerNames),
    );
  }

  void _mergePersonFacetOptions(List<OacPerson> rows) {
    _mergeCityFacetOptions(rows.map((e) => e.city));
    final types = <String>{...enterpriseTypeOptions};
    final employers = <String>{...employerOptions};
    for (final row in rows) {
      final t = row.enterpriseType?.trim();
      if (t != null && t.isNotEmpty) types.add(t);
      final e = row.latestEmployer?.trim();
      if (e != null && e.isNotEmpty) employers.add(e);
    }
    enterpriseTypeOptions.replaceAll(types.toList()..sort());
    employerOptions.replaceAll(employers.toList()..sort());
  }

  static String? _apiDate(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
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

  Future<void> applySort(BrandListSortOption option) async {
    if (sortKey.value == option.key) return;
    sortKey.value = option.key;
    pageNum.value = 1;
    await loadList(resetPage: false);
  }

  /// 表格列头排序：点同一列切换升降序，换列默认降序（与工具栏「排序」同源）。
  Future<void> applyGridColumnSort(String columnId) async {
    final apiColumn = switch (columnId) {
      'orders' => 'orderCount',
      'amount' => 'orderAmount',
      'latestOrder' => 'latestOrderTime',
      'brandCount' => 'brandCount',
      _ => null,
    };
    if (apiColumn == null) return;
    final cur = currentSort;
    final nextAsc = cur.column == apiColumn ? !cur.asc : false;
    BrandListSortOption? matched;
    for (final o in kBrandListSortOptions) {
      if (o.column == apiColumn && o.asc == nextAsc) {
        matched = o;
        break;
      }
    }
    matched ??= BrandListSortOption(
      column: apiColumn,
      asc: nextAsc,
      label: apiColumn,
    );
    await applySort(matched);
  }

  OacBrandQuery _buildBrandQuery({int? page, int? size}) {
    final sort = currentSort;
    return OacBrandQuery(
      keyword: keywordCtrl.text,
      industry: industry.value,
      city: city.value,
      tags: tags.value,
      ownerNames: ownerNames.value,
      quickTag: quickTag.value,
      amountMin: amountMinCtrl.text,
      amountMax: amountMaxCtrl.text,
      orderTimeBegin: _apiDate(orderTimeBegin.value),
      orderTimeEnd: _apiDate(orderTimeEnd.value),
      pageNum: page ?? pageNum.value,
      pageSize: size ?? pageSize.value,
      orderByColumn: sort.column,
      isAsc: sort.asc ? 'asc' : 'desc',
    );
  }

  OacEnterpriseQuery _buildEnterpriseQuery({int? page, int? size}) {
    final sort = currentSort;
    return OacEnterpriseQuery(
      keyword: keywordCtrl.text,
      industry: industry.value,
      city: city.value,
      tags: tags.value,
      mediaType: mediaType.value,
      ownerNames: ownerNames.value,
      quickTag: quickTag.value,
      amountMin: amountMinCtrl.text,
      amountMax: amountMaxCtrl.text,
      orderTimeBegin: _apiDate(orderTimeBegin.value),
      orderTimeEnd: _apiDate(orderTimeEnd.value),
      pageNum: page ?? pageNum.value,
      pageSize: size ?? pageSize.value,
      orderByColumn: sort.column,
      // 与接口示例 isAsc=descending 对齐（升序用 ascending）。
      isAsc: sort.asc ? 'ascending' : 'descending',
    );
  }

  OacAgencyQuery _buildAgencyQuery({int? page, int? size}) {
    final sort = currentSort;
    return OacAgencyQuery(
      keyword: keywordCtrl.text,
      city: city.value,
      tags: tags.value,
      relationType: relationType.value,
      ownerNames: ownerNames.value,
      quickTag: quickTag.value,
      amountMin: amountMinCtrl.text,
      amountMax: amountMaxCtrl.text,
      orderTimeBegin: _apiDate(orderTimeBegin.value),
      orderTimeEnd: _apiDate(orderTimeEnd.value),
      pageNum: page ?? pageNum.value,
      pageSize: size ?? pageSize.value,
      orderByColumn: sort.column,
      isAsc: sort.asc ? 'ascending' : 'descending',
    );
  }

  OacPersonQuery _buildPersonQuery({int? page, int? size}) {
    final sort = currentSort;
    return OacPersonQuery(
      keyword: keywordCtrl.text,
      enterpriseType: enterpriseType.value,
      city: city.value,
      latestEmployer: latestEmployer.value,
      orderTimeBegin: _apiDate(orderTimeBegin.value),
      orderTimeEnd: _apiDate(orderTimeEnd.value),
      pageNum: page ?? pageNum.value,
      pageSize: size ?? pageSize.value,
      orderByColumn: sort.column,
      isAsc: sort.asc ? 'ascending' : 'descending',
    );
  }

  Future<void> refreshAll() async {
    await Future.wait([loadOverview(), loadList(resetPage: false)]);
  }

  Future<void> search() async {
    pageNum.value = 1;
    await Future.wait([loadOverview(), loadList(resetPage: false)]);
  }

  Future<void> resetFilters() async {
    keywordCtrl.clear();
    industry.value = null;
    city.value = null;
    tags.value = null;
    mediaType.value = null;
    relationType.value = null;
    ownerNames.value = null;
    enterpriseType.value = null;
    latestEmployer.value = null;
    amountMinCtrl.clear();
    amountMaxCtrl.clear();
    orderTimeBegin.value = null;
    orderTimeEnd.value = null;
    quickTag.value = null;
    pageNum.value = 1;
    await refreshAll();
  }

  Future<void> selectQuickTag(String tag) async {
    quickTag.value = quickTag.value == tag ? null : tag;
    pageNum.value = 1;
    await Future.wait([loadOverview(), loadList(resetPage: false)]);
  }

  Future<void> changePageSize(int size) async {
    if (size == pageSize.value) return;
    pageSize.value = size;
    pageNum.value = 1;
    await loadList(resetPage: false);
  }

  Future<void> goPage(int page) async {
    if (page < 1) return;
    final maxPage = totalPages;
    if (page > maxPage) return;
    pageNum.value = page;
    await loadList(resetPage: false);
  }

  int get totalPages {
    final size = pageSize.value;
    if (size <= 0) return 1;
    final t = total.value;
    if (t <= 0) return 1;
    return ((t + size - 1) / size).floor();
  }

  Future<void> loadOverview() async {
    if (entityTab.value > 3) {
      overview.value = null;
      enterpriseOverview.value = null;
      agencyOverview.value = null;
      personOverview.value = null;
      return;
    }
    overviewLoading.value = true;
    try {
      if (isPersonTab) {
        personOverview.value =
            await _personApi.fetchOverview(_buildPersonQuery());
        overview.value = null;
        enterpriseOverview.value = null;
        agencyOverview.value = null;
      } else if (isAgencyTab) {
        agencyOverview.value =
            await _agencyApi.fetchOverview(_buildAgencyQuery());
        overview.value = null;
        enterpriseOverview.value = null;
        personOverview.value = null;
      } else if (isEnterpriseTab) {
        enterpriseOverview.value =
            await _enterpriseApi.fetchOverview(_buildEnterpriseQuery());
        overview.value = null;
        agencyOverview.value = null;
        personOverview.value = null;
      } else {
        overview.value = await _api.fetchOverview(_buildBrandQuery());
        enterpriseOverview.value = null;
        agencyOverview.value = null;
        personOverview.value = null;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      overviewLoading.value = false;
    }
  }

  Future<void> loadList({bool resetPage = true}) async {
    if (resetPage) pageNum.value = 1;
    if (entityTab.value > 3) {
      brands.clear();
      enterprises.clear();
      agencies.clear();
      persons.clear();
      total.value = 0;
      return;
    }
    listLoading.value = true;
    try {
      if (isPersonTab) {
        final page = await _personApi.fetchList(_buildPersonQuery());
        persons.replaceAll(page.rows);
        brands.clear();
        enterprises.clear();
        agencies.clear();
        total.value = page.total;
        _mergePersonFacetOptions(page.rows);
      } else if (isAgencyTab) {
        final page = await _agencyApi.fetchList(_buildAgencyQuery());
        agencies.replaceAll(page.rows);
        brands.clear();
        enterprises.clear();
        persons.clear();
        total.value = page.total;
        _mergeAgencyFacetOptions(page.rows);
      } else if (isEnterpriseTab) {
        final page =
            await _enterpriseApi.fetchList(_buildEnterpriseQuery());
        enterprises.replaceAll(page.rows);
        brands.clear();
        agencies.clear();
        persons.clear();
        total.value = page.total;
        _mergeEnterpriseFacetOptions(page.rows);
      } else {
        final page = await _api.fetchList(_buildBrandQuery());
        brands.replaceAll(page.rows);
        enterprises.clear();
        agencies.clear();
        persons.clear();
        total.value = page.total;
        _mergeBrandFacetOptions(page.rows);
      }
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value = e.toString();
      brands.clear();
      enterprises.clear();
      agencies.clear();
      persons.clear();
      total.value = 0;
    } finally {
      listLoading.value = false;
    }
  }

  /// 按当前筛选/排序导出 Excel（SpreadsheetML `.xls`，Excel 可直接打开）。
  /// [columns]：可见数据列 `(id, title)`，不含序号/操作。
  Future<({Uint8List bytes, String fileName})> exportExcel({
    required List<(String id, String title)> columns,
  }) async {
    if (exporting.value) {
      throw BrandApiException('正在导出，请稍候');
    }
    if (columns.isEmpty) {
      throw BrandApiException('没有可导出的列，请先在列设置中勾选');
    }
    exporting.value = true;
    try {
      if (isPersonTab) {
        final page = await _personApi.fetchList(
          _buildPersonQuery(page: 1, size: 5000),
        );
        final rows = page.rows;
        if (rows.isEmpty) {
          throw BrandApiException('暂无数据可导出');
        }
        final bytes = _buildPersonSpreadsheetMl(
          sheetName: '联系人汇总',
          columns: columns,
          rows: rows,
        );
        final stamp = DateTime.now();
        final name =
            '联系人汇总_${stamp.year}${_pad2(stamp.month)}${_pad2(stamp.day)}_'
            '${_pad2(stamp.hour)}${_pad2(stamp.minute)}.xls';
        return (bytes: bytes, fileName: name);
      }
      if (isAgencyTab) {
        final page = await _agencyApi.fetchList(
          _buildAgencyQuery(page: 1, size: 5000),
        );
        final rows = page.rows;
        if (rows.isEmpty) {
          throw BrandApiException('暂无数据可导出');
        }
        final bytes = _buildAgencySpreadsheetMl(
          sheetName: '4A公司主体汇总',
          columns: columns,
          rows: rows,
          tagLabel: tagLabel,
        );
        final stamp = DateTime.now();
        final name =
            '4A公司主体汇总_${stamp.year}${_pad2(stamp.month)}${_pad2(stamp.day)}_'
            '${_pad2(stamp.hour)}${_pad2(stamp.minute)}.xls';
        return (bytes: bytes, fileName: name);
      }
      if (isEnterpriseTab) {
        final page = await _enterpriseApi.fetchList(
          _buildEnterpriseQuery(page: 1, size: 5000),
        );
        final rows = page.rows;
        if (rows.isEmpty) {
          throw BrandApiException('暂无数据可导出');
        }
        final bytes = _buildEnterpriseSpreadsheetMl(
          sheetName: '企业主体汇总',
          columns: columns,
          rows: rows,
          tagLabel: tagLabel,
        );
        final stamp = DateTime.now();
        final name =
            '企业主体汇总_${stamp.year}${_pad2(stamp.month)}${_pad2(stamp.day)}_'
            '${_pad2(stamp.hour)}${_pad2(stamp.minute)}.xls';
        return (bytes: bytes, fileName: name);
      }

      final page = await _api.fetchList(
        _buildBrandQuery(page: 1, size: 5000),
      );
      final rows = page.rows;
      if (rows.isEmpty) {
        throw BrandApiException('暂无数据可导出');
      }
      final bytes = _buildSpreadsheetMl(
        sheetName: '品牌主体汇总',
        columns: columns,
        rows: rows,
        industryLabel: industryLabel,
        tagLabel: tagLabel,
      );
      final stamp = DateTime.now();
      final name =
          '品牌主体汇总_${stamp.year}${_pad2(stamp.month)}${_pad2(stamp.day)}_'
          '${_pad2(stamp.hour)}${_pad2(stamp.minute)}.xls';
      return (bytes: bytes, fileName: name);
    } finally {
      exporting.value = false;
    }
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String _xmlEscape(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _exportCell(
  OacBrand row,
  String id, {
  String Function(String?)? industryLabel,
  String Function(String?)? tagLabel,
}) {
  switch (id) {
    case 'weight':
      return '${row.weight ?? ''}';
    case 'icon':
      return row.iconUrl?.trim() ?? '';
    case 'name':
      return row.name?.trim() ?? '';
    case 'industry':
      final labeled = industryLabel?.call(row.industry);
      if (labeled != null && labeled != '-') return labeled;
      return row.industry?.trim() ?? '';
    case 'tags':
      final rawList = <String>[];
      final list = row.tagList;
      if (list != null && list.isNotEmpty) {
        for (final e in list) {
          final v = e.trim();
          if (v.isNotEmpty) rawList.add(v);
        }
      } else {
        final raw = row.tags?.trim();
        if (raw != null && raw.isNotEmpty) {
          for (final part in raw.split(RegExp(r'[,，;；\s]+'))) {
            final v = part.trim();
            if (v.isNotEmpty) rawList.add(v);
          }
        }
      }
      if (tagLabel == null) return rawList.join('、');
      return [
        for (final t in rawList)
          if (tagLabel(t).isNotEmpty) tagLabel(t),
      ].join('、');
    case 'spokesperson':
      return row.spokesperson?.trim() ?? '';
    case 'agency':
      return '${row.agencyCount ?? ''}';
    case 'enterprise':
      return '${row.enterpriseCount ?? ''}';
    case 'orders':
      return '${row.orderCount ?? ''}';
    case 'amount':
      return row.orderAmount?.trim() ?? '';
    case 'latestOrder':
      return row.latestOrderTime?.trim() ?? '';
    case 'contact':
      return row.contactCount == null ? '' : '${row.contactCount}';
    case 'sales':
      return row.ownerNames?.trim() ?? '';
    case 'dynamic':
      return row.latestDynamic?.trim() ?? '';
    default:
      return '';
  }
}

String _exportEnterpriseCell(
  OacEnterprise row,
  String id, {
  String Function(String?)? tagLabel,
}) {
  switch (id) {
    case 'weight':
      return '${row.weight ?? ''}';
    case 'icon':
      return row.iconUrl?.trim() ?? '';
    case 'name':
      return row.name?.trim() ?? '';
    case 'tags':
      final rawList = <String>[];
      final list = row.tagList;
      if (list != null && list.isNotEmpty) {
        for (final e in list) {
          final v = e.trim();
          if (v.isNotEmpty) rawList.add(v);
        }
      } else {
        final raw = row.tags?.trim();
        if (raw != null && raw.isNotEmpty) {
          for (final part in raw.split(RegExp(r'[,，;；\s]+'))) {
            final v = part.trim();
            if (v.isNotEmpty) rawList.add(v);
          }
        }
      }
      if (tagLabel == null) return rawList.join('、');
      return [
        for (final t in rawList)
          if (tagLabel(t).isNotEmpty) tagLabel(t),
      ].join('、');
    case 'city':
      return row.city?.trim() ?? '';
    case 'brandCount':
    case 'brand':
      return '${row.brandCount ?? ''}';
    case 'brandNames':
      final list = row.brandNameList;
      if (list != null && list.isNotEmpty) {
        return [
          for (final e in list)
            if (e.trim().isNotEmpty) e.trim(),
        ].join('、');
      }
      return row.brandNames?.trim() ?? '';
    case 'agency':
      return '${row.agencyCount ?? ''}';
    case 'orders':
      return '${row.orderCount ?? ''}';
    case 'amount':
      return row.orderAmount?.trim() ?? '';
    case 'latestOrder':
      return row.latestOrderTime?.trim() ?? '';
    case 'contact':
      return row.contactCount == null ? '' : '${row.contactCount}';
    case 'sales':
      return row.ownerNames?.trim() ?? '';
    case 'dynamic':
      return row.latestDynamic?.trim() ?? '';
    default:
      return '';
  }
}

Uint8List _buildEnterpriseSpreadsheetMl({
  required String sheetName,
  required List<(String id, String title)> columns,
  required List<OacEnterprise> rows,
  String Function(String?)? tagLabel,
}) {
  final sb = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<?mso-application progid="Excel.Sheet"?>')
    ..writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    )
    ..writeln('<Worksheet ss:Name="${_xmlEscape(sheetName)}">')
    ..writeln('<Table>');

  sb.write('<Row>');
  sb.write(
    '<Cell><Data ss:Type="String">${_xmlEscape('序号')}</Data></Cell>',
  );
  for (final (_, title) in columns) {
    sb.write(
      '<Cell><Data ss:Type="String">${_xmlEscape(title)}</Data></Cell>',
    );
  }
  sb.writeln('</Row>');

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    sb.write('<Row>');
    sb.write(
      '<Cell><Data ss:Type="Number">${i + 1}</Data></Cell>',
    );
    for (final (id, _) in columns) {
      final text = _exportEnterpriseCell(
        row,
        id,
        tagLabel: tagLabel,
      );
      final asNum = num.tryParse(text);
      if (asNum != null &&
          (id == 'weight' ||
              id == 'agency' ||
              id == 'brand' ||
              id == 'brandCount' ||
              id == 'orders' ||
              id == 'amount' ||
              id == 'contact')) {
        sb.write(
          '<Cell><Data ss:Type="Number">$asNum</Data></Cell>',
        );
      } else {
        sb.write(
          '<Cell><Data ss:Type="String">${_xmlEscape(text)}</Data></Cell>',
        );
      }
    }
    sb.writeln('</Row>');
  }

  sb
    ..writeln('</Table>')
    ..writeln('</Worksheet>')
    ..writeln('</Workbook>');
  return Uint8List.fromList(utf8.encode(sb.toString()));
}

String _exportAgencyCell(
  OacAgency row,
  String id, {
  String Function(String?)? tagLabel,
}) {
  switch (id) {
    case 'weight':
      return '${row.weight ?? ''}';
    case 'icon':
      return row.iconUrl?.trim() ?? '';
    case 'name':
      return row.name?.trim() ?? '';
    case 'tags':
      final rawList = <String>[];
      final list = row.tagList;
      if (list != null && list.isNotEmpty) {
        for (final e in list) {
          final v = e.trim();
          if (v.isNotEmpty) rawList.add(v);
        }
      } else {
        final raw = row.tags?.trim();
        if (raw != null && raw.isNotEmpty) {
          for (final part in raw.split(RegExp(r'[,，;；\s]+'))) {
            final v = part.trim();
            if (v.isNotEmpty) rawList.add(v);
          }
        }
      }
      if (tagLabel == null) return rawList.join('、');
      return [
        for (final t in rawList)
          if (tagLabel(t).isNotEmpty) tagLabel(t),
      ].join('、');
    case 'city':
      return row.city?.trim() ?? '';
    case 'brandCount':
      return '${row.brandCount ?? ''}';
    case 'brandNames':
      final list = row.brandNameList;
      if (list != null && list.isNotEmpty) {
        return [
          for (final e in list)
            if (e.trim().isNotEmpty) e.trim(),
        ].join('、');
      }
      return row.brandNames?.trim() ?? '';
    case 'enterpriseCount':
      return '${row.enterpriseCount ?? ''}';
    case 'orders':
      return '${row.orderCount ?? ''}';
    case 'amount':
      return row.orderAmount?.trim() ?? '';
    case 'latestOrder':
      return row.latestOrderTime?.trim() ?? '';
    case 'contact':
      return row.contactCount == null ? '' : '${row.contactCount}';
    case 'sales':
      return row.ownerNames?.trim() ?? '';
    case 'dynamic':
      return row.latestDynamic?.trim() ?? '';
    default:
      return '';
  }
}

Uint8List _buildAgencySpreadsheetMl({
  required String sheetName,
  required List<(String id, String title)> columns,
  required List<OacAgency> rows,
  String Function(String?)? tagLabel,
}) {
  final sb = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<?mso-application progid="Excel.Sheet"?>')
    ..writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    )
    ..writeln('<Worksheet ss:Name="${_xmlEscape(sheetName)}">')
    ..writeln('<Table>');

  sb.write('<Row>');
  sb.write(
    '<Cell><Data ss:Type="String">${_xmlEscape('序号')}</Data></Cell>',
  );
  for (final (_, title) in columns) {
    sb.write(
      '<Cell><Data ss:Type="String">${_xmlEscape(title)}</Data></Cell>',
    );
  }
  sb.writeln('</Row>');

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    sb.write('<Row>');
    sb.write(
      '<Cell><Data ss:Type="Number">${i + 1}</Data></Cell>',
    );
    for (final (id, _) in columns) {
      final text = _exportAgencyCell(row, id, tagLabel: tagLabel);
      final asNum = num.tryParse(text);
      if (asNum != null &&
          (id == 'weight' ||
              id == 'brandCount' ||
              id == 'enterpriseCount' ||
              id == 'orders' ||
              id == 'amount' ||
              id == 'contact')) {
        sb.write(
          '<Cell><Data ss:Type="Number">$asNum</Data></Cell>',
        );
      } else {
        sb.write(
          '<Cell><Data ss:Type="String">${_xmlEscape(text)}</Data></Cell>',
        );
      }
    }
    sb.writeln('</Row>');
  }

  sb
    ..writeln('</Table>')
    ..writeln('</Worksheet>')
    ..writeln('</Workbook>');
  return Uint8List.fromList(utf8.encode(sb.toString()));
}

Uint8List _buildSpreadsheetMl({
  required String sheetName,
  required List<(String id, String title)> columns,
  required List<OacBrand> rows,
  String Function(String?)? industryLabel,
  String Function(String?)? tagLabel,
}) {
  final sb = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<?mso-application progid="Excel.Sheet"?>')
    ..writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    )
    ..writeln('<Worksheet ss:Name="${_xmlEscape(sheetName)}">')
    ..writeln('<Table>');

  sb.write('<Row>');
  sb.write(
    '<Cell><Data ss:Type="String">${_xmlEscape('序号')}</Data></Cell>',
  );
  for (final (_, title) in columns) {
    sb.write(
      '<Cell><Data ss:Type="String">${_xmlEscape(title)}</Data></Cell>',
    );
  }
  sb.writeln('</Row>');

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    sb.write('<Row>');
    sb.write(
      '<Cell><Data ss:Type="Number">${i + 1}</Data></Cell>',
    );
    for (final (id, _) in columns) {
      final text = _exportCell(
        row,
        id,
        industryLabel: industryLabel,
        tagLabel: tagLabel,
      );
      final asNum = num.tryParse(text);
      if (asNum != null &&
          (id == 'weight' ||
              id == 'agency' ||
              id == 'enterprise' ||
              id == 'orders' ||
              id == 'amount' ||
              id == 'contact')) {
        sb.write(
          '<Cell><Data ss:Type="Number">$asNum</Data></Cell>',
        );
      } else {
        sb.write(
          '<Cell><Data ss:Type="String">${_xmlEscape(text)}</Data></Cell>',
        );
      }
    }
    sb.writeln('</Row>');
  }

  sb
    ..writeln('</Table>')
    ..writeln('</Worksheet>')
    ..writeln('</Workbook>');
  return Uint8List.fromList(utf8.encode(sb.toString()));
}

String _exportPersonCell(OacPerson row, String id) {
  switch (id) {
    case 'icon':
      return row.avatarUrl?.trim() ?? '';
    case 'name':
      final name = row.name?.trim() ?? '';
      final title = row.title?.trim() ?? '';
      if (name.isEmpty) return title;
      if (title.isEmpty) return name;
      return '$name / $title';
    case 'employer':
      return row.latestEmployer?.trim() ?? '';
    case 'enterpriseType':
      return row.enterpriseType?.trim() ?? '';
    case 'city':
      return row.city?.trim() ?? '';
    case 'address':
      return row.address?.trim() ?? '';
    case 'sameContact':
      return '${row.sameEnterpriseContactCount ?? ''}';
    case 'brandCount':
      return '${row.brandCount ?? ''}';
    case 'brandNames':
      final list = row.brandNameList;
      if (list != null && list.isNotEmpty) {
        return [
          for (final e in list)
            if (e.trim().isNotEmpty) e.trim(),
        ].join('、');
      }
      return row.brandNames?.trim() ?? '';
    case 'enterpriseCount':
      return '${row.enterpriseCount ?? ''}';
    case 'agencyCount':
      return '${row.agencyCount ?? ''}';
    case 'orders':
      return '${row.orderCount ?? ''}';
    case 'amount':
      return row.orderAmount?.trim() ?? '';
    case 'latestOrder':
      return row.latestOrderTime?.trim() ?? '';
    default:
      return '';
  }
}

Uint8List _buildPersonSpreadsheetMl({
  required String sheetName,
  required List<(String id, String title)> columns,
  required List<OacPerson> rows,
}) {
  final sb = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<?mso-application progid="Excel.Sheet"?>')
    ..writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    )
    ..writeln('<Worksheet ss:Name="${_xmlEscape(sheetName)}">')
    ..writeln('<Table>');

  sb.write('<Row>');
  sb.write(
    '<Cell><Data ss:Type="String">${_xmlEscape('序号')}</Data></Cell>',
  );
  for (final (_, title) in columns) {
    sb.write(
      '<Cell><Data ss:Type="String">${_xmlEscape(title)}</Data></Cell>',
    );
  }
  sb.writeln('</Row>');

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    sb.write('<Row>');
    sb.write(
      '<Cell><Data ss:Type="Number">${i + 1}</Data></Cell>',
    );
    for (final (id, _) in columns) {
      final text = _exportPersonCell(row, id);
      final asNum = num.tryParse(text);
      if (asNum != null &&
          (id == 'sameContact' ||
              id == 'brandCount' ||
              id == 'enterpriseCount' ||
              id == 'agencyCount' ||
              id == 'orders' ||
              id == 'amount')) {
        sb.write(
          '<Cell><Data ss:Type="Number">$asNum</Data></Cell>',
        );
      } else {
        sb.write(
          '<Cell><Data ss:Type="String">${_xmlEscape(text)}</Data></Cell>',
        );
      }
    }
    sb.writeln('</Row>');
  }

  sb
    ..writeln('</Table>')
    ..writeln('</Worksheet>')
    ..writeln('</Workbook>');
  return Uint8List.fromList(utf8.encode(sb.toString()));
}
