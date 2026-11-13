import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../models/dict_data.dart';
import '../../models/oac_brand.dart';
import '../../models/oac_brand_detail.dart';
import '../../models/oac_agency.dart';
import '../../models/oac_enterprise.dart';
import '../../services/agency_api.dart';
import '../../services/brand_api.dart';
import '../../services/customer_api.dart';
import '../../services/dict_api.dart';
import '../../services/enterprise_api.dart';

class BrandDetailController extends LxController {
  BrandDetailController({
    required this.brandId,
    this.perspective = OacDetailPerspective.brand,
    this.enterpriseSeed,
    this.agencySeed,
  });

  final String brandId;
  final OacDetailPerspective perspective;
  /// 企业列表行（企业视角优先用此字段；load 时按 keyword 刷新）。
  OacEnterprise? enterpriseSeed;
  /// 4A 列表行（4A 视角优先用此字段；load 时按 keyword 刷新）。
  OacAgency? agencySeed;

  bool get isEnterprise => perspective == OacDetailPerspective.enterprise;
  bool get isAgency => perspective == OacDetailPerspective.agency;

  /// 编辑客户档案用 id：入口传入的即为 `customerId`（企业/4A 优先 seed）。
  String get editCustomerId {
    if (isEnterprise) {
      final id = enterpriseSeed?.customerId?.trim() ??
          enterpriseSeed?.id?.trim() ??
          brandId.trim();
      return id;
    }
    if (isAgency) {
      final id = agencySeed?.customerId?.trim() ??
          agencySeed?.id?.trim() ??
          brandId.trim();
      return id;
    }
    return brandId.trim();
  }
  final _api = BrandApi();
  final _enterpriseApi = EnterpriseApi();
  final _agencyApi = AgencyApi();
  final _customerApi = CustomerApi();
  final _dictApi = DictApi();

  final detail = Rxn<OacBrandDetail>();
  final loading = false.obs;
  final errorMessage = Rxn<String>();
  /// 企业 / 4A 行刷新后触发头部 / 指标重建。
  final enterpriseVersion = 0.obs;
  final agencyVersion = 0.obs;
  /// 客户档案补充字段（4A：`marketScale` / 地址等）。
  final customerMarketScale = Rxn<String>();
  final customerAddress = Rxn<String>();
  final orderKeywordCtrl = TextEditingController();
  final orderKeyword = ''.obs;
  final dictVersion = 0.obs;
  /// 客户档案附件（备注与附件区；来自 `GET /desktop/oac/customer/{id}`）。
  final attachments = <BrandAttachmentItem>[].obs;

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
      if (isEnterprise) {
        await _refreshEnterpriseSeed();
      }
      if (isAgency) {
        await Future.wait([
          _refreshAgencySeed(),
          _refreshAgencyCustomer(),
        ]);
      }
      detail.value = await _api.fetchDetail(brandId);
      if (!isEnterprise && !isAgency) {
        await _refreshAttachments();
      } else {
        attachments.clear();
      }
    } catch (e) {
      errorMessage.value = e.toString();
      detail.value = null;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _refreshAttachments() async {
    final id = brandId.trim();
    if (id.isEmpty) {
      attachments.clear();
      return;
    }
    try {
      final customer = await _customerApi.fetchCustomerDetail(id);
      attachments
        ..clear()
        ..addAll(_parseAttachments(customer['attachments']));
    } catch (_) {
      attachments.clear();
    }
  }

  List<BrandAttachmentItem> _parseAttachments(dynamic raw) {
    if (raw is! List) return const [];
    final out = <BrandAttachmentItem>[];
    for (final e in raw) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final name = (m['name'] ?? m['fileName'] ?? m['originalName'])
            ?.toString()
            .trim();
        final fileId =
            (m['fileId'] ?? m['ossId'] ?? m['id'])?.toString().trim();
        final url = (m['url'] ??
                m['fileUrl'] ??
                m['ossUrl'] ??
                m['displayUrl'] ??
                m['previewUrl'])
            ?.toString()
            .trim();
        if ((name == null || name.isEmpty) &&
            (fileId == null || fileId.isEmpty) &&
            (url == null || url.isEmpty)) {
          continue;
        }
        out.add(
          BrandAttachmentItem(
            fileId: fileId,
            name: (name != null && name.isNotEmpty)
                ? name
                : (fileId ?? url ?? '附件'),
            url: url,
          ),
        );
      } else {
        final s = '$e'.trim();
        if (s.isEmpty) continue;
        out.add(BrandAttachmentItem(fileId: s, name: s));
      }
    }
    return out;
  }

  /// 企业视角：`GET /desktop/oac/enterprise/list?keyword=` 重新取行字段。
  Future<void> _refreshEnterpriseSeed() async {
    final seed = enterpriseSeed;
    final keyword = seed?.name?.trim();
    final id = seed?.id?.trim();
    final customerId = seed?.customerId?.trim() ?? brandId.trim();
    final queryKeyword = (keyword != null && keyword.isNotEmpty)
        ? keyword
        : (id != null && id.isNotEmpty ? id : customerId);
    if (queryKeyword.isEmpty) return;
    try {
      final page = await _enterpriseApi.fetchList(
        OacEnterpriseQuery(
          keyword: queryKeyword,
          pageNum: 1,
          pageSize: 200,
        ),
      );
      OacEnterprise? matched;
      if (id != null && id.isNotEmpty) {
        for (final row in page.rows) {
          if (row.id?.trim() == id) {
            matched = row;
            break;
          }
        }
      }
      if (matched == null &&
          customerId.isNotEmpty &&
          customerId != id) {
        for (final row in page.rows) {
          if (row.customerId?.trim() == customerId) {
            matched = row;
            break;
          }
        }
      }
      if (matched == null && keyword != null && keyword.isNotEmpty) {
        for (final row in page.rows) {
          if (row.name?.trim() == keyword) {
            matched = row;
            break;
          }
        }
      }
      matched ??= page.rows.isNotEmpty ? page.rows.first : null;
      if (matched != null) {
        enterpriseSeed = matched;
        enterpriseVersion.value++;
      }
    } catch (_) {
      // 列表刷新失败时保留进入页时的 seed，不影响 brand detail。
    }
  }

  /// 企业视角展示名：列表企业名优先于品牌详情名。
  String enterpriseDisplayName(OacBrand? brand) {
    final fromSeed = enterpriseSeed?.name?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.name?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return '企业详情';
  }

  int enterpriseWeight(OacBrand? brand) =>
      enterpriseSeed?.weight ?? brand?.weight ?? 0;

  String? enterpriseIconUrl(OacBrand? brand) {
    final fromSeed = enterpriseSeed?.iconUrl?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.iconUrl?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return null;
  }

  String enterpriseCity(OacBrand? brand) {
    final fromSeed = enterpriseSeed?.city?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.city?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return '';
  }

  String? enterpriseCoverageText() {
    final score = enterpriseSeed?.coverageScore;
    final grade = enterpriseSeed?.coverageGrade?.trim();
    if (score == null && (grade == null || grade.isEmpty)) return null;
    if (score != null && grade != null && grade.isNotEmpty) {
      return '覆盖评分 $score · $grade';
    }
    if (score != null) return '覆盖评分 $score';
    return '覆盖评分 $grade';
  }

  String? enterpriseOrderAmount() =>
      enterpriseSeed?.orderAmount ?? detail.value?.brand?.orderAmount;

  int? enterpriseOrderCount() =>
      enterpriseSeed?.orderCount ??
      detail.value?.brand?.orderCount ??
      detail.value?.orders.length;

  String? enterpriseOrderAmountYoyRate() =>
      enterpriseSeed?.orderAmountYoyRate?.trim();

  String? enterpriseDeptPerfShareRate() =>
      enterpriseSeed?.deptPerfShareRate?.trim();

  int enterpriseBrandCount(OacBrandDetail? detail) {
    final fromSeed = enterpriseSeed?.brandCount;
    if (fromSeed != null) return fromSeed;
    if (detail != null) return relatedBrandNames(detail).length;
    return 0;
  }

  int enterpriseAgencyCount(OacBrandDetail? detail) {
    final fromSeed = enterpriseSeed?.agencyCount;
    if (fromSeed != null) return fromSeed;
    return detail?.brand?.agencyCount ?? detail?.agencies.length ?? 0;
  }

  String enterpriseAgencySubtitle(OacBrandDetail detail) {
    final names = [
      ...?enterpriseSeed?.agencyNameList,
      if (enterpriseSeed?.agencyNames?.trim().isNotEmpty == true)
        ...enterpriseSeed!.agencyNames!
            .split(RegExp(r'[,，/;|、]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
    ];
    final seen = <String>{};
    final unique = <String>[
      for (final n in names)
        if (seen.add(n)) n,
    ];
    if (unique.isEmpty) {
      final fromDetail = [
        for (final a in detail.agencies)
          if (a.name?.trim().isNotEmpty == true) a.name!.trim(),
      ];
      if (fromDetail.isEmpty) return '-';
      if (fromDetail.length == 1) return fromDetail.first;
      return '${fromDetail.first}等 ${fromDetail.length} 家';
    }
    if (unique.length == 1) return unique.first;
    return '${unique.first}等 ${unique.length} 家';
  }

  int enterpriseContactCount(OacBrandDetail detail) =>
      enterpriseSeed?.contactCount ??
      detail.brand?.contactCount ??
      detail.contacts.length;

  String enterpriseLatestOrderTime(OacBrand? brand) {
    final raw = enterpriseSeed?.latestOrderTime?.trim() ??
        brand?.latestOrderTime?.trim();
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 19 ? raw.substring(0, 19) : raw;
  }

  List<String> enterpriseOwnerNames(OacBrand? brand) {
    final fromSeed = enterpriseSeed?.ownerNameList;
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final csv = enterpriseSeed?.ownerNames?.trim();
    if (csv != null && csv.isNotEmpty) {
      return csv
          .split(RegExp(r'[,，/;|、]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final fromBrand = brand?.ownerNameList;
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    final brandCsv = brand?.ownerNames?.trim();
    if (brandCsv == null || brandCsv.isEmpty) return const [];
    return brandCsv
        .split(RegExp(r'[,，/;|、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// 4A 视角：`GET /desktop/oac/agency/list?keyword=` 重新取行字段。
  Future<void> _refreshAgencySeed() async {
    final seed = agencySeed;
    final keyword = seed?.name?.trim();
    final id = seed?.id?.trim() ?? brandId.trim();
    final customerId = seed?.customerId?.trim() ?? brandId.trim();
    final queryKeyword = (keyword != null && keyword.isNotEmpty)
        ? keyword
        : (id.isNotEmpty ? id : customerId);
    if (queryKeyword.isEmpty) return;
    try {
      final page = await _agencyApi.fetchList(
        OacAgencyQuery(
          keyword: queryKeyword,
          pageNum: 1,
          pageSize: 200,
        ),
      );
      OacAgency? matched;
      if (id.isNotEmpty) {
        for (final row in page.rows) {
          if (row.id?.trim() == id || row.customerId?.trim() == id) {
            matched = row;
            break;
          }
        }
      }
      if (matched == null &&
          customerId.isNotEmpty &&
          customerId != id) {
        for (final row in page.rows) {
          if (row.customerId?.trim() == customerId ||
              row.id?.trim() == customerId) {
            matched = row;
            break;
          }
        }
      }
      if (matched == null && keyword != null && keyword.isNotEmpty) {
        for (final row in page.rows) {
          if (row.name?.trim() == keyword) {
            matched = row;
            break;
          }
        }
      }
      matched ??= page.rows.isNotEmpty ? page.rows.first : null;
      if (matched != null) {
        agencySeed = matched;
        agencyVersion.value++;
      }
    } catch (_) {
      // 列表刷新失败时保留进入页时的 seed。
    }
  }

  /// 4A：`GET /desktop/oac/customer/{id}` 取规模 / 地址。
  Future<void> _refreshAgencyCustomer() async {
    final id = (agencySeed?.customerId ?? agencySeed?.id ?? brandId).trim();
    if (id.isEmpty) return;
    try {
      final data = await _customerApi.fetchCustomerDetail(id);
      final scale = data['marketScale']?.toString().trim();
      customerMarketScale.value =
          (scale != null && scale.isNotEmpty) ? scale : null;
      String? address;
      final ents = data['enterprises'];
      if (ents is List) {
        for (final e in ents) {
          if (e is! Map) continue;
          final a = e['address']?.toString().trim();
          if (a != null && a.isNotEmpty) {
            address = a;
            break;
          }
        }
      }
      address ??= data['address']?.toString().trim();
      customerAddress.value =
          (address != null && address.isNotEmpty) ? address : null;
      agencyVersion.value++;
    } catch (_) {
      // 客户档案失败不影响列表 / brand detail。
    }
  }

  String agencyDisplayName(OacBrand? brand) {
    final fromSeed = agencySeed?.name?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.name?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return '4A详情';
  }

  int agencyWeight(OacBrand? brand) =>
      agencySeed?.weight ?? brand?.weight ?? 0;

  String? agencyIconUrl(OacBrand? brand) {
    final fromSeed = agencySeed?.iconUrl?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.iconUrl?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return null;
  }

  String agencyCity(OacBrand? brand) {
    final fromSeed = agencySeed?.city?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.city?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return '';
  }

  String? agencyCode(OacBrand? brand) {
    final fromSeed = agencySeed?.agencyCode?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final fromBrand = brand?.brandCode?.trim();
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    return agencySeed?.id?.trim();
  }

  String? agencyAddress() {
    final fromCustomer = customerAddress.value?.trim();
    if (fromCustomer != null && fromCustomer.isNotEmpty) return fromCustomer;
    final fromSeed = agencySeed?.address?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final hq = detail.value?.hqLocation?.address?.trim();
    if (hq != null && hq.isNotEmpty) return hq;
    return null;
  }

  /// 总部地图用：优先接口 `hqLocation`，缺地址时回退经营主体 / 列表行。
  HqLocation? resolvedHqLocation() {
    final d = detail.value;
    final hq = d?.hqLocation;
    String? pick(Iterable<String?> values) {
      for (final v in values) {
        final t = v?.trim();
        if (t != null && t.isNotEmpty && t != '-') return t;
      }
      return null;
    }

    final address = pick([
      hq?.address,
      if (isEnterprise) enterpriseSeed?.address,
      if (isAgency) agencyAddress(),
      for (final e in d?.enterprises ?? const <EnterpriseItem>[]) e.address,
    ]);
    final region = pick([
      hq?.region,
      if (isEnterprise) enterpriseSeed?.city,
      if (isAgency) agencySeed?.city,
      d?.brand?.city,
      for (final e in d?.enterprises ?? const <EnterpriseItem>[]) e.city,
    ]);
    final name = pick([
      hq?.name,
      if (isEnterprise) enterpriseSeed?.name,
      if (isAgency) agencySeed?.name,
      d?.brand?.name,
    ]);
    if (address == null &&
        hq?.lng == null &&
        hq?.lat == null &&
        name == null &&
        region == null) {
      return hq;
    }
    return HqLocation()
      ..name = name ?? hq?.name
      ..address = address ?? hq?.address
      ..region = region ?? hq?.region
      ..lng = hq?.lng
      ..lat = hq?.lat;
  }

  /// 合作评级：优先健康分映射字母级，否则健康文案。
  String? agencyCooperationRating(OacBrand? brand) {
    final score = brand?.healthScore;
    if (score != null) {
      final grade = score >= 90
          ? 'A'
          : score >= 75
              ? 'B'
              : score >= 60
                  ? 'C'
                  : 'D';
      return '$grade级';
    }
    final label = brand?.healthLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return null;
  }

  String? agencyMarketScale() {
    final scale = customerMarketScale.value?.trim();
    if (scale != null && scale.isNotEmpty) return scale;
    return null;
  }

  String? agencyOrderAmount() =>
      agencySeed?.orderAmount ?? detail.value?.brand?.orderAmount;

  int? agencyOrderCount() =>
      agencySeed?.orderCount ??
      detail.value?.brand?.orderCount ??
      detail.value?.orders.length;

  String? agencyOrderAmountYoyRate() =>
      agencySeed?.orderAmountYoyRate?.trim();

  String? agencyDeptPerfShareRate() =>
      agencySeed?.deptPerfShareRate?.trim();

  String? agencyQ4ExpectedYoyRate() =>
      agencySeed?.q4ExpectedYoyRate?.trim();

  int agencyBrandCount(OacBrandDetail? detail) {
    final fromSeed = agencySeed?.brandCount;
    if (fromSeed != null) return fromSeed;
    if (detail != null) return relatedBrandNames(detail).length;
    return 0;
  }

  String agencyBrandSubtitle(OacBrandDetail detail) {
    final summary = agencySeed?.brandIndustrySummary?.trim();
    if (summary != null && summary.isNotEmpty) return summary;
    final names = relatedBrandNames(detail);
    if (names.isEmpty) return '-';
    return names.take(3).join('、');
  }

  int agencyEnterpriseCount(OacBrandDetail? detail) {
    final fromSeed = agencySeed?.enterpriseCount;
    if (fromSeed != null) return fromSeed;
    if (detail != null) {
      return detail.brand?.enterpriseCount ??
          relatedEnterpriseNames(detail).length;
    }
    return 0;
  }

  String agencyEnterpriseSubtitle(OacBrandDetail detail) {
    final names = relatedEnterpriseNames(detail);
    if (names.isEmpty) return '-';
    return names.take(3).join('、');
  }

  int agencyContactCount(OacBrandDetail detail) =>
      agencySeed?.contactCount ??
      detail.brand?.contactCount ??
      detail.contacts.length;

  String agencyLatestOrderTime(OacBrand? brand) {
    final raw = agencySeed?.latestOrderTime?.trim() ??
        brand?.latestOrderTime?.trim();
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 19 ? raw.substring(0, 19) : raw;
  }

  List<String> agencyOwnerNames(OacBrand? brand) {
    final fromSeed = agencySeed?.ownerNameList;
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final csv = agencySeed?.ownerNames?.trim();
    if (csv != null && csv.isNotEmpty) {
      return csv
          .split(RegExp(r'[,，/;|、]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final fromBrand = brand?.ownerNameList;
    if (fromBrand != null && fromBrand.isNotEmpty) return fromBrand;
    final brandCsv = brand?.ownerNames?.trim();
    if (brandCsv == null || brandCsv.isEmpty) return const [];
    return brandCsv
        .split(RegExp(r'[,，/;|、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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

  String clientTagLabel(String? raw, {String? label}) {
    final preferred = label?.trim();
    if (preferred != null && preferred.isNotEmpty) return preferred;
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '-';
    final map = {
      ...?_labelMaps[OacDictTypes.brandNature],
      ...?_labelMaps[OacDictTypes.customerTag],
      ..._clientTagFallback,
    };
    return map[text] ?? text;
  }

  String industryDisplay(OacBrand? brand) {
    final label = brand?.industryLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return industryLabel(brand?.industry);
  }

  String entityNatureLabel(String? raw) =>
      labelOf(OacDictTypes.entityNature, raw);

  /// 企业画像「企业类型」：关系类型，缺省「经营主体」。
  String enterpriseTypeDisplay(OacBrand? brand) {
    for (final raw in [
      brand?.relationType,
      enterpriseSeed?.relationType,
    ]) {
      final rel = raw?.trim();
      if (rel == null || rel.isEmpty) continue;
      final labeled = relationLabel(rel);
      if (labeled != '-') return labeled;
    }
    return '经营主体';
  }

  /// 企业画像「企业标签」：主体性质 / 客户标签。
  List<String> enterpriseTagDisplays(OacBrand? brand) {
    final out = <String>[];
    final seen = <String>{};
    void add(String? raw, {String Function(String?)? map}) {
      final text = raw?.trim() ?? '';
      if (text.isEmpty) return;
      final label = map?.call(text) ?? text;
      if (label == '-' || label.isEmpty) return;
      if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(label)) return;
      if (!seen.add(label)) return;
      out.add(label);
    }

    add(brand?.entityNature, map: entityNatureLabel);
    add(enterpriseSeed?.entityNature, map: entityNatureLabel);
    for (final t in [
      ...?brand?.tagList,
      ...?enterpriseSeed?.tagList,
    ]) {
      add(t, map: tagLabel);
    }
    add(
      brand?.clientTag ?? enterpriseSeed?.clientTag,
      map: (v) => clientTagLabel(v, label: brand?.clientTagLabel),
    );
    return out;
  }

  String orderRelationDisplay(OrderItem order) {
    final label = order.relationLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return relationLabel(order.relation);
  }

  /// 关联品牌名（企业 / 4A：优先 `brands`，再订单 / 列表行去重）。
  List<String> relatedBrandNames(OacBrandDetail detail) {
    final fromApi = [
      for (final b in detail.brands)
        if (b.name?.trim().isNotEmpty == true) b.name!.trim(),
    ];
    if (fromApi.isNotEmpty) return fromApi;
    final seen = <String>{};
    final out = <String>[];
    for (final o in detail.orders) {
      final n = o.brandName?.trim();
      if (n == null || n.isEmpty || !seen.add(n)) continue;
      out.add(n);
    }
    if (out.isNotEmpty) return out;
    for (final n in [
      ...?enterpriseSeed?.brandNameList,
      ...?agencySeed?.brandNameList,
      if (enterpriseSeed?.brandNames?.trim().isNotEmpty == true)
        ...enterpriseSeed!.brandNames!
            .split(RegExp(r'[,，/;|、]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      if (agencySeed?.brandNames?.trim().isNotEmpty == true)
        ...agencySeed!.brandNames!
            .split(RegExp(r'[,，/;|、]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
    ]) {
      if (!seen.add(n)) continue;
      out.add(n);
    }
    return out;
  }

  /// 4A 画像服务标签。
  List<String> agencyTagDisplays(OacBrand? brand) {
    final out = <String>[];
    final seen = <String>{};
    void add(String? raw, {String Function(String?)? map}) {
      final text = raw?.trim() ?? '';
      if (text.isEmpty) return;
      final label = map?.call(text) ?? text;
      if (label == '-' || label.isEmpty) return;
      if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(label)) return;
      if (!seen.add(label)) return;
      out.add(label);
    }

    add(brand?.entityNature, map: entityNatureLabel);
    for (final t in [...?brand?.tagList, ...?agencySeed?.tagList]) {
      add(t, map: tagLabel);
    }
    add(
      brand?.clientTag ?? agencySeed?.clientTag,
      map: (v) => clientTagLabel(v, label: brand?.clientTagLabel),
    );
    return out;
  }

  /// 4A / 企业关联企业名。
  List<String> relatedEnterpriseNames(OacBrandDetail detail) {
    final fromApi = [
      for (final e in detail.enterprises)
        if (e.name?.trim().isNotEmpty == true) e.name!.trim(),
    ];
    if (fromApi.isNotEmpty) return fromApi;
    final seen = <String>{};
    final out = <String>[];
    for (final o in detail.orders) {
      final n = o.enterprise?.trim();
      if (n == null || n.isEmpty || !seen.add(n)) continue;
      out.add(n);
    }
    if (out.isNotEmpty) return out;
    for (final n in [
      ...?agencySeed?.enterpriseNameList,
      if (agencySeed?.enterpriseNames?.trim().isNotEmpty == true)
        ...agencySeed!.enterpriseNames!
            .split(RegExp(r'[,，/;|、]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
    ]) {
      if (!seen.add(n)) continue;
      out.add(n);
    }
    return out;
  }

  /// 头部展示用标签（中文；过滤纯英文）。
  List<String> headerDisplayTags(OacBrand? brand) {
    final industryText = industryDisplay(brand);
    final raw = <String>[
      ...?brand?.tagList,
      if (industryText != '-') industryText,
    ];
    final seen = <String>{};
    final out = <String>[];
    for (final t in raw) {
      final key = t.trim();
      if (key.isEmpty) continue;
      final isIndustry = key == industryText;
      final label = isIndustry ? key : tagLabel(key);
      if (label == '-' || label.isEmpty) continue;
      if (!RegExp(r'[\u4e00-\u9fff]').hasMatch(label)) continue;
      if (!seen.add(label)) continue;
      out.add(label);
    }
    return out;
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
    final fromList = <SalesPersonView>[
      for (final s in d.salesList)
        if (s.name?.trim().isNotEmpty == true)
          SalesPersonView(
            name: s.name!.trim(),
            role: roleByName[s.name!.trim()] ?? '销售',
            deptTitle: s.deptTitle,
          ),
    ];
    // 4A 列表负责人可能多于 salesList（如 李季兰 + 张三）。
    if (isAgency) {
      final seen = {for (final p in fromList) p.name};
      final merged = [...fromList];
      for (final name in agencyOwnerNames(d.brand)) {
        if (!seen.add(name)) continue;
        merged.add(
          SalesPersonView(
            name: name,
            role: roleByName[name] ?? '销售',
          ),
        );
      }
      if (merged.isNotEmpty) return merged;
    } else if (fromList.isNotEmpty) {
      return fromList;
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
    for (final o in detail.value?.orders ?? const []) {
      final label = orderRelationDisplay(o);
      if (label == '-' || label.isEmpty) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    if (counts.isNotEmpty) return counts;
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

/// 品牌详情「备注与附件」列表项。
class BrandAttachmentItem {
  BrandAttachmentItem({
    required this.name,
    this.fileId,
    this.url,
  });

  final String name;
  final String? fileId;
  final String? url;
}
