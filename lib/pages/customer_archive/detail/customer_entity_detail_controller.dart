import 'package:lemon_x/lemon_x.dart';

import '../../../models/dict_data.dart';
import '../../../services/customer_api.dart';
import '../../../services/dict_api.dart';

/// 关联主体详情：按客户档案 ID + 主体全称定位一条 enterprise。
class CustomerEntityDetailController extends LxController {
  CustomerEntityDetailController({
    required this.customerId,
    required this.enterpriseName,
  });

  final String customerId;
  final String enterpriseName;
  final _api = CustomerApi();
  final _dictApi = DictApi();

  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final raw = Rxn<Map<String, dynamic>>();
  final enterprise = Rxn<Map<String, dynamic>>();

  /// 联系人表「列设置」中勾掉的列 id（序号 / 操作始终显示）。
  final contactHiddenColumnIds = <String>{}.obs;

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
      enterprise.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _loadDetail() async {
    final data = await _api.fetchCustomerDetail(customerId);
    raw.value = data;
    enterprise.value = _matchEnterprise(data);
    if (enterprise.value == null) {
      errorMessage.value = '未找到关联主体「$enterpriseName」';
    }
  }

  Future<void> _loadDicts() async {
    final maps = await _dictApi.fetchMany([
      OacDictTypes.customerType,
      OacDictTypes.brandNature,
      OacDictTypes.revenueScale,
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

  Map<String, dynamic>? _matchEnterprise(Map<String, dynamic> data) {
    final list = data['enterprises'];
    if (list is! List) return null;
    final key = enterpriseName.trim();
    if (key.isEmpty) return null;
    Map<String, dynamic>? fallback;
    for (final rawItem in list) {
      if (rawItem is! Map) continue;
      final e = Map<String, dynamic>.from(rawItem);
      final name = _str(e['fullName']);
      if (name == key) return e;
      if (fallback == null && name.contains(key)) fallback = e;
    }
    return fallback;
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
    return n.isEmpty ? '-' : n;
  }

  String get entityFullName {
    final n = _str(enterprise.value?['fullName']);
    return n.isEmpty ? enterpriseName : n;
  }

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
      // 对齐网页端：金典; 优酸乳
      if (parts.isNotEmpty) return parts.join('; ');
    }
    final named = _str(raw.value?['subBrandNames']);
    return named.isEmpty ? '-' : named;
  }

  String get industryLabel =>
      labelOf(OacDictTypes.industry, _str(raw.value?['industry']));

  String get revenueLabel =>
      labelOf(OacDictTypes.revenueScale, _str(raw.value?['revenueScale']));

  String get website => _dash(_str(raw.value?['website']));

  String get staffScale {
    final a = _str(enterprise.value?['staffScale']);
    if (a.isNotEmpty) return a;
    final b = _str(enterprise.value?['personnelScale']);
    if (b.isNotEmpty) return b;
    return _dash(_str(raw.value?['staffScale']));
  }

  String get entityRelationLabel {
    final rawRel = _str(enterprise.value?['relationType']);
    if (rawRel.isEmpty) return '-';
    // 接口可能已是中文文案（如「总部品牌中心」），字典无命中则原样展示。
    final labeled = labelOf(OacDictTypes.relationType, rawRel);
    return labeled;
  }

  String relationLabel(dynamic raw) =>
      labelOf(OacDictTypes.relationType, raw?.toString());

  String get entityNatureLabel => labelOf(
        OacDictTypes.entityNature,
        _str(enterprise.value?['entityNature']),
      );

  String get cityText {
    final city = _str(enterprise.value?['city']);
    if (city.isNotEmpty) return city;
    final prov = _str(enterprise.value?['province']);
    return prov.isEmpty ? '-' : prov;
  }

  String get address => _dash(_str(enterprise.value?['address']));

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

  // —— 基本信息 ——
  String get creditCode => _entField('creditCode', 'unifiedSocialCreditCode');
  String get legalPerson => _entField('legalPerson');
  String get regCapital {
    final a = _str(enterprise.value?['regCapital']);
    if (a.isNotEmpty) return a;
    final b = _str(enterprise.value?['registeredCapital']);
    return b.isEmpty ? '-' : b;
  }

  String get establishDate =>
      _entField('establishDate', 'establishedDate', 'foundDate');

  String get licenseExpire {
    final period = _str(enterprise.value?['licenseValidPeriod']);
    if (period.isNotEmpty) return period;
    final one = _str(enterprise.value?['licenseExpire']);
    if (one.isNotEmpty) return one;
    final two = _str(enterprise.value?['businessLicenseExpire']);
    if (two.isNotEmpty) return two;
    final s = _str(enterprise.value?['licenseStart']).isNotEmpty
        ? _str(enterprise.value?['licenseStart'])
        : _str(enterprise.value?['businessLicenseStart']);
    final e = _str(enterprise.value?['licenseEnd']).isNotEmpty
        ? _str(enterprise.value?['licenseEnd'])
        : _str(enterprise.value?['businessLicenseEnd']);
    if (s.isEmpty && e.isEmpty) return '-';
    if (s.isEmpty) return e;
    if (e.isEmpty) return s;
    return '$s 至 $e';
  }

  String get regAddress => _entField('regAddress', 'registeredAddress');
  String get businessScope => _entField('businessScope', 'bizScope');
  String get abnormalRecord =>
      _entField('abnormalRecord', 'businessAbnormal', 'abnormal');
  String get penaltyHistory =>
      _entField('penaltyHistory', 'adminPenalty', 'punishmentHistory');
  String get remark => _entField('remark', 'remarks');
  String get attachmentText {
    final ossId = _str(enterprise.value?['licenseOssId']);
    if (ossId.isNotEmpty) return '电子营业执照 · $ossId';
    final a = _str(enterprise.value?['attachmentName']);
    if (a.isNotEmpty) return a;
    final b = _str(enterprise.value?['licenseFileName']);
    if (b.isNotEmpty) return b;
    final list = enterprise.value?['attachments'];
    if (list is List && list.isNotEmpty) {
      final parts = list
          .map((e) => e is Map ? _str(e['name'] ?? e['fileName']) : _str(e))
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('；');
    }
    return '-';
  }

  bool get hasLicenseAttachment =>
      _str(enterprise.value?['licenseOssId']).isNotEmpty ||
      attachmentText != '-';

  /// 银税条目（`taxList`）；空则回退主体顶层银行/开票字段。
  List<Map<String, dynamic>> get taxEntries {
    final list = enterprise.value?['taxList'];
    if (list is List && list.isNotEmpty) {
      return [
        for (final e in list)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    final fallback = <String, dynamic>{
      'bankName': enterprise.value?['bankName'],
      'bankAccount': enterprise.value?['bankAccount'],
      'invoiceName': enterprise.value?['invoiceName'],
      'taxNo': enterprise.value?['taxNo'],
      'invoiceRegAddress': enterprise.value?['invoiceRegAddress'],
      'invoiceRegPhone': enterprise.value?['invoiceRegPhone'],
      'invoiceBank': enterprise.value?['invoiceBank'],
      'invoiceBankAccount': enterprise.value?['invoiceBankAccount'],
    };
    final hasAny = fallback.values.any((v) => _str(v).isNotEmpty);
    return hasAny ? [fallback] : const [];
  }

  Map<String, dynamic>? get primaryTax =>
      taxEntries.isEmpty ? null : taxEntries.first;

  // —— 银税（默认展示第一条） ——
  String get bankName => _dash(
        _firstNonEmpty([
          _str(primaryTax?['bankName']),
          _str(enterprise.value?['bankName']),
          _str(enterprise.value?['bankOfDeposit']),
        ]),
      );

  String get bankAccount => _dash(
        _firstNonEmpty([
          _str(primaryTax?['bankAccount']),
          _str(enterprise.value?['bankAccount']),
          _str(enterprise.value?['bankAccountNo']),
        ]),
      );

  String get invoiceName => _dash(
        _firstNonEmpty([
          _str(primaryTax?['invoiceName']),
          _str(enterprise.value?['invoiceName']),
          entityFullName,
        ]),
      );

  String get taxNo => _dash(
        _firstNonEmpty([
          _str(primaryTax?['taxNo']),
          _str(enterprise.value?['taxNo']),
          creditCode == '-' ? '' : creditCode,
        ]),
      );

  String get invoiceAddress => _dash(
        _firstNonEmpty([
          _str(primaryTax?['invoiceRegAddress']),
          _str(enterprise.value?['invoiceRegAddress']),
          _str(enterprise.value?['invoiceAddress']),
          regAddress == '-' ? '' : regAddress,
        ]),
      );

  String get invoicePhone => _dash(
        _firstNonEmpty([
          _str(primaryTax?['invoiceRegPhone']),
          _str(enterprise.value?['invoiceRegPhone']),
          _str(enterprise.value?['invoicePhone']),
          _str(enterprise.value?['regPhone']),
        ]),
      );

  String get invoiceBank => _dash(
        _firstNonEmpty([
          _str(primaryTax?['invoiceBank']),
          _str(enterprise.value?['invoiceBank']),
          bankName == '-' ? '' : bankName,
        ]),
      );

  String get invoiceAccount => _dash(
        _firstNonEmpty([
          _str(primaryTax?['invoiceBankAccount']),
          _str(enterprise.value?['invoiceBankAccount']),
          _str(enterprise.value?['invoiceAccount']),
          bankAccount == '-' ? '' : bankAccount,
        ]),
      );

  List<Map<String, dynamic>> get contacts {
    final list = raw.value?['contacts'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  List<Map<String, dynamic>> get entityContacts {
    final key = entityFullName.trim();
    if (key.isEmpty || key == '-') return const [];
    return [
      for (final c in contacts)
        if (_str(c['relatedEnterprise']) == key) c,
    ];
  }

  String get ownerNamesText {
    final fromField = _str(raw.value?['ownerNames']);
    if (fromField.isNotEmpty) return fromField;
    final sales = raw.value?['salesList'];
    if (sales is! List) return '-';
    final names = <String>[];
    for (final s in sales) {
      if (s is! Map) continue;
      final n = _str(s['name']);
      if (n.isNotEmpty) names.add(n);
    }
    return names.isEmpty ? '-' : names.join('；');
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

  bool isContactColumnVisible(String id) =>
      !contactHiddenColumnIds.contains(id);

  void setContactColumnVisible(String id, bool visible) {
    if (visible) {
      contactHiddenColumnIds.remove(id);
    } else {
      contactHiddenColumnIds.add(id);
    }
    contactHiddenColumnIds.refresh();
  }

  String _entField(String key, [String? alt1, String? alt2]) {
    final a = _str(enterprise.value?[key]);
    if (a.isNotEmpty) return a;
    if (alt1 != null) {
      final b = _str(enterprise.value?[alt1]);
      if (b.isNotEmpty) return b;
    }
    if (alt2 != null) {
      final c = _str(enterprise.value?[alt2]);
      if (c.isNotEmpty) return c;
    }
    return '-';
  }

  static String _firstNonEmpty(List<String> parts) {
    for (final p in parts) {
      if (p.trim().isNotEmpty && p.trim() != '-') return p.trim();
    }
    return '';
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  static String _dash(String s) => s.isEmpty ? '-' : s;
}
