import 'package:lemon_x/lemon_x.dart';

import '../../../models/dict_data.dart';
import '../../../services/customer_api.dart';
import '../../../services/dict_api.dart';

class CustomerBrandDetailController extends LxController {
  CustomerBrandDetailController({required this.customerId});

  final String customerId;
  final _api = CustomerApi();
  final _dictApi = DictApi();

  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final raw = Rxn<Map<String, dynamic>>();

  final _labelMaps = <String, Map<String, String>>{};

  static const _fallbackCustomerType = {
    'brand': '品牌企业',
    'agency': '4A公司',
    'channel': '渠道广告公司',
    'gov': '政务单位',
    'dsp': 'DSP/API',
  };

  static const _mediaTypeLabel = {
    'wechat_mp': '微信公众号',
    'weibo': '微博',
    'douyin': '抖音',
    'xiaohongshu': '小红书',
    'bilibili': 'B站',
    'video': '视频号',
    'channels': '视频号',
  };

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      await Future.wait([_loadDicts(), _loadDetail()]);
    } catch (e) {
      errorMessage.value = e.toString();
      raw.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadDetail() async {
    raw.value = await _api.fetchCustomerDetail(customerId);
  }

  Future<void> _loadDicts() async {
    final maps = await _dictApi.fetchMany([
      OacDictTypes.customerType,
      OacDictTypes.brandNature,
      OacDictTypes.revenueScale,
      OacDictTypes.marketingBudget,
      OacDictTypes.relationType,
      OacDictTypes.entityNature,
      OacDictTypes.industry,
      OacDictTypes.tenure,
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
  }

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

  String get brandName {
    final n = _str(raw.value?['name']);
    return n.isEmpty ? '品牌详情' : n;
  }

  String get archiveCode => _str(raw.value?['customerCode']);

  int get weight {
    final v = raw.value?['weight'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  String get createTime => _dash(_str(raw.value?['createTime']));

  String get customerTypeLabel =>
      labelOf(OacDictTypes.customerType, _str(raw.value?['customerType']));

  String get subBrandsText {
    final list = raw.value?['subBrands'];
    if (list is List) {
      final parts = list
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('；');
    }
    final named = _str(raw.value?['subBrandNames']);
    return named.isEmpty ? '-' : named;
  }

  String get industryLabel =>
      labelOf(OacDictTypes.industry, _str(raw.value?['industry']));

  String get brandNatureLabel =>
      labelOf(OacDictTypes.brandNature, _str(raw.value?['brandNature']));

  String get revenueLabel =>
      labelOf(OacDictTypes.revenueScale, _str(raw.value?['revenueScale']));

  String get marketingLabel => labelOf(
        OacDictTypes.marketingBudget,
        _str(raw.value?['marketingBudget']),
      );

  String get spokesperson => _dash(_str(raw.value?['spokesperson']));

  String get website => _dash(_str(raw.value?['website']));

  String get serviceAgencyName {
    final names = raw.value?['relatedAgencyNames'];
    if (names is List && names.isNotEmpty) {
      return names.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).join('；');
    }
    final single = _str(raw.value?['serviceAgencyName']);
    return single.isEmpty ? '-' : single;
  }

  String get wechatAccount => _mediaAccount(
        const {'wechat_mp', '微信公众号', 'wechat'},
      );

  String get videoAccount => _mediaAccount(
        const {'video', 'channels', '视频号', 'wechat_channels'},
      );

  String get douyinAccount => _mediaAccount(
        const {'douyin', '抖音'},
      );

  String _mediaAccount(Set<String> keys) {
    final list = raw.value?['mediaList'];
    if (list is! List) return '-';
    for (final rawItem in list) {
      if (rawItem is! Map) continue;
      final m = Map<String, dynamic>.from(rawItem);
      final type = _str(m['mediaType']);
      final label = _mediaTypeLabel[type] ?? type;
      if (keys.contains(type) || keys.contains(label)) {
        final name = _str(m['accountName']);
        if (name.isNotEmpty) return name;
        final url = _str(m['accountUrl']);
        if (url.isNotEmpty) return url;
      }
    }
    return '-';
  }

  List<Map<String, dynamic>> get enterprises {
    final list = raw.value?['enterprises'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  List<Map<String, dynamic>> get contacts {
    final list = raw.value?['contacts'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  List<Map<String, dynamic>> get salesList {
    final list = raw.value?['salesList'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  String get ownerNamesText {
    final fromField = _str(raw.value?['ownerNames']);
    if (fromField.isNotEmpty) return fromField;
    final names = <String>[];
    for (final s in salesList) {
      final n = _str(s['name']);
      if (n.isNotEmpty) names.add(n);
    }
    return names.isEmpty ? '-' : names.join('；');
  }

  /// 主体行上展示的联系人：按关联主体名称匹配。
  List<Map<String, dynamic>> contactsOfEnterprise(String? fullName) {
    final key = fullName?.trim() ?? '';
    if (key.isEmpty) return const [];
    return [
      for (final c in contacts)
        if (_str(c['relatedEnterprise']) == key) c,
    ];
  }

  String genderLabel(dynamic raw) {
    final s = '$raw'.trim();
    return switch (s) {
      '1' => '男',
      '2' => '女',
      '男' || '女' => s,
      _ => s.isEmpty ? '-' : s,
    };
  }

  String tenureLabel(dynamic raw) =>
      labelOf(OacDictTypes.tenure, raw?.toString());

  String relationLabel(dynamic raw) =>
      labelOf(OacDictTypes.relationType, raw?.toString());

  String entityNatureLabel(dynamic raw) =>
      labelOf(OacDictTypes.entityNature, raw?.toString());

  String brandsText(dynamic raw) {
    if (raw is List) {
      final parts = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return parts.isEmpty ? '-' : parts.join('，');
    }
    final s = _str(raw);
    return s.isEmpty ? '-' : s;
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  static String _dash(String s) => s.isEmpty ? '-' : s;
}
