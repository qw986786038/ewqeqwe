import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../models/customer_archive.dart';
import '../../models/dict_data.dart';
import '../../models/oac_brand.dart';
import '../../models/oac_brand_detail.dart';
import '../../services/brand_api.dart';
import '../../services/customer_api.dart';
import '../../services/dict_api.dart';
import '../../services/order_api.dart';

class BrandDetailController extends LxController {
  BrandDetailController({required this.brandId});

  final String brandId;
  final _api = BrandApi();
  final _customerApi = CustomerApi();
  final _orderApi = OrderApi();
  final _dictApi = DictApi();

  final detail = Rxn<OacBrandDetail>();
  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final orderKeywordCtrl = TextEditingController();
  final orderKeyword = ''.obs;
  final dictVersion = 0.obs;

  /// 关联 4A 下拉（`customerType=agency&status=0`）。
  final agencyOptions = <CustomerArchive>[].obs;
  final agencyOptionsLoading = false.obs;
  final updatingAgencyOrderIds = <String>{}.obs;

  final _labelMaps = <String, Map<String, String>>{};

  static const _relationFallback = <String, String>{
    'operating_entity': '经营主体',
    'operatingEntity': '经营主体',
    'operator': '经营主体',
    'agency': '关联4A',
    'media': '媒体主',
  };

  /// 客户标签编码兜底（接口常回 code，字典未就绪时也能显示中文）。
  static const _tagFallback = <String, String>{
    'listed_company': '上市公司',
    'private_enterprise': '民营企业',
    'public_enterprise': '国有企业',
    'foreign_enterprise': '外资企业',
    'international': '国际',
  };

  static const _industryFallback = <String, String>{
    'dairy': '乳制品',
  };

  static const _clientTagFallback = <String, String>{
    'international': '国际',
  };

  @override
  void onInit() {
    super.onInit();
    orderKeywordCtrl.addListener(() {
      orderKeyword.value = orderKeywordCtrl.text.trim();
    });
    load();
    loadAgencyOptions();
    _loadDicts();
  }

  @override
  void onDispose() {
    orderKeywordCtrl.dispose();
    super.onDispose();
  }

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      detail.value = await _api.fetchDetail(brandId);
    } catch (e) {
      errorMessage.value = e.toString();
      detail.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadAgencyOptions() async {
    agencyOptionsLoading.value = true;
    try {
      final page = await _customerApi.fetchList(
        OacCustomerQuery(
          customerType: 'agency',
          status: '0',
          pageNum: 1,
          pageSize: 500,
        ),
      );
      agencyOptions
        ..clear()
        ..addAll([
          for (final row in page.rows)
            if (row.id?.trim().isNotEmpty == true) row,
        ]);
    } catch (_) {
      // 下拉失败不阻断详情；单元格仍可展示已有关联名。
    } finally {
      agencyOptionsLoading.value = false;
    }
  }

  Future<void> _loadDicts() async {
    final maps = await _dictApi.fetchMany(const [
      OacDictTypes.relationType,
      OacDictTypes.contractType,
      OacDictTypes.customerTag,
      OacDictTypes.entityNature,
      OacDictTypes.industry,
      OacDictTypes.brandNature,
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
    dictVersion.value++;
  }

  String labelOf(String dictType, String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '-';
    final map = {
      ...?_labelMaps[dictType],
      if (dictType == OacDictTypes.relationType) ..._relationFallback,
      if (dictType == OacDictTypes.customerTag) ..._tagFallback,
      if (dictType == OacDictTypes.industry) ..._industryFallback,
      if (dictType == OacDictTypes.brandNature) ..._clientTagFallback,
    };
    final parts = text
        .split(RegExp(r'[,，/;|、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '-';
    return parts.map((p) => map[p] ?? p).join('、');
  }

  String relationLabel(String? raw) =>
      labelOf(OacDictTypes.relationType, raw);

  String contractTypeLabel(String? raw) =>
      labelOf(OacDictTypes.contractType, raw);

  String tagLabel(String? raw) => labelOf(OacDictTypes.customerTag, raw);

  String industryLabel(String? raw) => labelOf(OacDictTypes.industry, raw);

  String clientTagLabel(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '-';
    final map = {
      ...?_labelMaps[OacDictTypes.brandNature],
      ...?_labelMaps[OacDictTypes.customerTag],
      ..._clientTagFallback,
    };
    return map[text] ?? text;
  }

  /// 头部展示用标签（中文；过滤纯英文）。
  List<String> headerDisplayTags(OacBrand? brand) {
    final raw = <String>[
      ...?brand?.tagList,
      if (brand?.industry?.trim().isNotEmpty == true) brand!.industry!,
    ];
    final seen = <String>{};
    final out = <String>[];
    for (final t in raw) {
      final key = t.trim();
      if (key.isEmpty) continue;
      final isIndustry = key == brand?.industry?.trim();
      final label = isIndustry ? industryLabel(key) : tagLabel(key);
      if (label == '-' || label.isEmpty) continue;
      if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(label)) continue;
      if (!seen.add(label)) continue;
      out.add(label);
    }
    return out;
  }

  /// 解析订单当前选中的 4A 客户 id（优先 agencyId，其次按名称匹配选项）。
  String? resolveAgencyValue(OrderItem row) {
    final id = row.agencyId?.trim();
    if (id != null && id.isNotEmpty) return id;
    final name = row.agencyName?.trim();
    if (name == null || name.isEmpty) return null;
    for (final a in agencyOptions) {
      if (a.brandName?.trim() == name) return a.id;
    }
    return null;
  }

  String? agencyLabelOf(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return null;
    for (final a in agencyOptions) {
      if (a.id == key) return a.brandName?.trim();
    }
    return null;
  }

  /// 更新订单关联 4A；`agencyCustomerId` 为空则清空。
  Future<void> updateOrderAgency({
    required OrderItem order,
    String? agencyCustomerId,
  }) async {
    final orderId = order.id?.trim();
    if (orderId == null || orderId.isEmpty) {
      throw OrderApiException('订单缺少 id，无法更新关联 4A');
    }
    final nextId = agencyCustomerId?.trim() ?? '';
    final current = resolveAgencyValue(order) ?? '';
    if (nextId == current) return;

    updatingAgencyOrderIds.add(orderId);
    updatingAgencyOrderIds.refresh();
    try {
      await _orderApi.updateOrderAgency(
        id: orderId,
        agencyCustomerId: nextId.isEmpty ? null : nextId,
      );
      order
        ..agencyId = nextId.isEmpty ? null : nextId
        ..agencyName =
            nextId.isEmpty ? null : (agencyLabelOf(nextId) ?? order.agencyName);
      detail.refresh();
    } finally {
      updatingAgencyOrderIds.remove(orderId);
      updatingAgencyOrderIds.refresh();
    }
  }

  /// 客户档案详情：`GET /desktop/oac/customer/{id}`。
  Future<Map<String, dynamic>> fetchCustomerDetail(String customerId) =>
      _customerApi.fetchCustomerDetail(customerId);

  List<OrderItem> get filteredOrders {
    final orders = detail.value?.orders ?? const <OrderItem>[];
    final kw = orderKeyword.value.toLowerCase();
    if (kw.isEmpty) return orders;
    return orders.where((o) {
      final hay = [
        o.name,
        o.orderNo,
        o.tag,
        o.enterprise,
        o.relation,
        o.agencyName,
        o.contractType,
        o.contact,
        o.salesPerson,
        o.remark,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(kw);
    }).toList();
  }

  double get ordersTotalAmount {
    var sum = 0.0;
    for (final o in detail.value?.orders ?? const <OrderItem>[]) {
      sum += num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
    }
    return sum;
  }

  List<SalesPersonView> get salesPeople {
    final d = detail.value;
    if (d == null) return const [];
    final graph = d.relationGraph;
    final roleByName = <String, String>{};
    if (graph != null) {
      final nodeName = <String, String>{
        for (final n in graph.nodes)
          if (n.id != null && n.name != null) n.id!: n.name!,
      };
      for (final link in graph.links) {
        final target = link.target;
        if (target == null || !target.startsWith('sales-')) continue;
        final name = nodeName[target];
        if (name == null || name.isEmpty) continue;
        roleByName[name] = link.label ?? '销售';
      }
    }
    final names = d.brand?.ownerNameList;
    if (names != null && names.isNotEmpty) {
      return [
        for (final name in names)
          SalesPersonView(
            name: name,
            role: roleByName[name] ?? '销售',
          ),
      ];
    }
    return [
      for (final e in roleByName.entries)
        SalesPersonView(name: e.key, role: e.value),
    ];
  }

  Map<String, int> get relationLabelCounts {
    final counts = <String, int>{};
    for (final link in detail.value?.relationGraph?.links ?? const []) {
      final label = link.label?.trim();
      if (label == null || label.isEmpty) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get contractTypeCounts {
    final counts = <String, int>{};
    for (final o in detail.value?.orders ?? const []) {
      final t = o.contractType?.trim();
      if (t == null || t.isEmpty) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }
}
