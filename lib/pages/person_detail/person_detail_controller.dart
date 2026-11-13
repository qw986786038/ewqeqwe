import 'package:lemon_x/lemon_x.dart';

import '../../models/oac_brand_detail.dart';
import '../../models/oac_person.dart';
import '../../services/brand_api.dart';
import '../../services/customer_api.dart';
import '../../services/person_api.dart';

/// 人视角详情：列表行 + `contact/{id}` + 关联品牌 detail 订单聚合。
class PersonDetailController extends LxController {
  PersonDetailController({
    required this.contactId,
    this.personSeed,
  });

  final String contactId;
  OacPerson? personSeed;

  final _personApi = PersonApi();
  final _customerApi = CustomerApi();
  final _brandApi = BrandApi();

  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final personVersion = 0.obs;

  /// `GET /desktop/oac/contact/{id}` 原始 data。
  final contactRaw = Rxn<Map<String, dynamic>>();
  /// 所属经营主体（客户档案 enterprises 中匹配到的一条；地址回退用）。
  final relatedEnterprise = Rxn<Map<String, dynamic>>();
  final orders = <OrderItem>[].obs;
  final monthlyTrend = <MonthAmountItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      await Future.wait([
        _refreshPersonSeed(),
        _loadContact(),
      ]);
      await Future.wait([
        _loadBrandOrders(),
        _loadRelatedEnterprise(),
      ]);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _refreshPersonSeed() async {
    final seed = personSeed;
    final keyword = seed?.name?.trim();
    final id = seed?.id?.trim() ?? contactId.trim();
    final queryKeyword =
        (keyword != null && keyword.isNotEmpty) ? keyword : id;
    if (queryKeyword.isEmpty) return;
    try {
      final page = await _personApi.fetchList(
        OacPersonQuery(keyword: queryKeyword, pageNum: 1, pageSize: 50),
      );
      OacPerson? matched;
      for (final row in page.rows) {
        if (row.id?.trim() == id) {
          matched = row;
          break;
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
        personSeed = matched;
        personVersion.value++;
      }
    } catch (_) {}
  }

  Future<void> _loadContact() async {
    final data = await _customerApi.fetchContactDetail(contactId);
    contactRaw.value = data;
    personVersion.value++;
  }

  /// 按联系人关联主体名，从客户档案 enterprises 中定位经营主体。
  Future<void> _loadRelatedEnterprise() async {
    final cid = customerId?.trim() ?? '';
    if (cid.isEmpty) {
      relatedEnterprise.value = null;
      return;
    }
    try {
      final data = await _customerApi.fetchCustomerDetail(cid);
      relatedEnterprise.value = _matchRelatedEnterprise(data);
      personVersion.value++;
    } catch (_) {
      relatedEnterprise.value = null;
    }
  }

  Map<String, dynamic>? _matchRelatedEnterprise(Map<String, dynamic> data) {
    final list = data['enterprises'];
    if (list is! List || list.isEmpty) return null;

    final keys = <String>{
      if (_str(contact?['relatedEnterprise']) case final v?) v,
      if (_str(primaryCareer?['enterpriseFullName']) case final v?) v,
      if (_str(primaryCareer?['enterpriseShortName']) case final v?) v,
      if (_str(primaryCareer?['relatedEnterprise']) case final v?) v,
      if (personSeed?.latestEmployer?.trim() case final v?
          when v.isNotEmpty)
        v,
      if (personSeed?.enterpriseId?.trim() case final v? when v.isNotEmpty) v,
    };
    if (keys.isEmpty) {
      // 无法识别所属主体时：仅一条经营主体则回退它，多条则不强绑。
      if (list.length == 1 && list.first is Map) {
        return Map<String, dynamic>.from(list.first as Map);
      }
      return null;
    }

    Map<String, dynamic>? fallback;
    for (final rawItem in list) {
      if (rawItem is! Map) continue;
      final e = Map<String, dynamic>.from(rawItem);
      final id = _str(e['id']);
      final fullName = _str(e['fullName']);
      final shortName = _str(e['shortName']);
      if ((id != null && keys.contains(id)) ||
          (fullName != null && keys.contains(fullName)) ||
          (shortName != null && keys.contains(shortName))) {
        return e;
      }
      if (fallback == null &&
          fullName != null &&
          keys.any((k) => fullName.contains(k) || k.contains(fullName))) {
        fallback = e;
      }
    }
    return fallback;
  }

  Future<void> _loadBrandOrders() async {
    final ids = <String>{
      ...?personSeed?.brandIdList,
      for (final e in brandIdListFromContact)
        if (e.isNotEmpty) e,
    };
    if (ids.isEmpty) {
      orders.clear();
      monthlyTrend.clear();
      return;
    }
    final name = displayName;
    final collected = <OrderItem>[];
    final monthMap = <String, double>{};
    for (final id in ids) {
      try {
        final detail = await _brandApi.fetchDetail(id);
        for (final o in detail.orders) {
          final contact = o.contact?.trim() ?? '';
          if (name.isEmpty || name == '-' || !contact.contains(name)) {
            continue;
          }
          collected.add(o);
          final monthKey = (o.orderTime?.trim().length ?? 0) >= 7
              ? o.orderTime!.trim().substring(0, 7)
              : null;
          if (monthKey != null) {
            monthMap[monthKey] = (monthMap[monthKey] ?? 0) +
                (num.tryParse(o.amount ?? '')?.toDouble() ?? 0);
          }
        }
      } catch (_) {}
    }
    collected.sort((a, b) {
      final ta = a.orderTime?.trim() ?? '';
      final tb = b.orderTime?.trim() ?? '';
      return tb.compareTo(ta);
    });
    orders.replaceAll(collected);
    final months = monthMap.keys.toList()..sort();
    monthlyTrend.replaceAll([
      for (final m in months)
        MonthAmountItem()
          ..month = m
          ..amount = monthMap[m]!.toStringAsFixed(2),
    ]);
    personVersion.value++;
  }

  List<String> get brandIdListFromContact {
    // contact 详情无 brandIdList，靠 person 行。
    return const [];
  }

  Map<String, dynamic>? get contact => contactRaw.value;

  /// 所属客户档案 id（添加同事 / 编辑档案用）。
  String? get customerId {
    final fromSeed = personSeed?.customerId?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    final raw = contact;
    for (final key in const [
      'customerId',
      'relatedCustomerId',
      'enterpriseCustomerId',
      'orgCustomerId',
    ]) {
      final v = raw?[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    final fromEnterprise = personSeed?.enterpriseId?.trim();
    if (fromEnterprise != null && fromEnterprise.isNotEmpty) {
      return fromEnterprise;
    }
    return null;
  }

  String get displayName {
    final fromContact = _str(contact?['name']);
    if (fromContact != null) return fromContact;
    return personSeed?.name?.trim().isNotEmpty == true
        ? personSeed!.name!.trim()
        : '-';
  }

  String get personCode {
    final fromContact = _str(contact?['personCode']);
    if (fromContact != null) return fromContact;
    return personSeed?.personCode?.trim() ?? '-';
  }

  bool get realNameVerified =>
      _asBool(contact?['realNameVerified']) ??
      personSeed?.realNameVerified ??
      false;

  int get influenceScore =>
      _asInt(contact?['influenceScore']) ??
      personSeed?.influenceScore ??
      0;

  bool get keyDecisionMaker =>
      _asBool(contact?['keyDecisionMaker']) ??
      personSeed?.keyDecisionMaker ??
      false;

  String get phone => _str(contact?['phones']) ?? '-';
  String get email => _str(contact?['emails']) ?? '-';

  /// 人所在城市：人有则用人的；否则用所属经营主体。
  String get city =>
      _personCity ?? _enterpriseCity ?? personSeed?.city?.trim() ?? '-';

  /// 人详细地址：人有则用人的；否则用所属经营主体。
  String get address =>
      _personAddress ??
      _enterpriseAddress ??
      personSeed?.address?.trim() ??
      '-';

  String? get _personCity =>
      _str(contact?['city']) ?? _str(primaryCareer?['city']);

  String? get _personAddress =>
      _str(contact?['address']) ?? _str(primaryCareer?['address']);

  String? get _enterpriseCity {
    final city = _str(relatedEnterprise.value?['city']);
    if (city != null) return city;
    return _str(relatedEnterprise.value?['province']);
  }

  String? get _enterpriseAddress =>
      _str(relatedEnterprise.value?['address']);

  String get remark => _str(contact?['remark']) ?? '-';

  Map<String, dynamic>? get primaryCareer {
    final list = contact?['careers'];
    if (list is! List || list.isEmpty) return null;
    final first = list.first;
    return first is Map ? Map<String, dynamic>.from(first) : null;
  }

  String get employer {
    final fromCareer = _str(primaryCareer?['enterpriseFullName']) ??
        _str(primaryCareer?['enterpriseShortName']);
    if (fromCareer != null) return fromCareer;
    return personSeed?.latestEmployer?.trim() ?? '-';
  }

  String get enterpriseType => personSeed?.enterpriseType?.trim() ?? '-';

  String get title {
    final fromCareer = _str(primaryCareer?['deptTitle']);
    if (fromCareer != null) return fromCareer;
    return personSeed?.title?.trim() ?? '-';
  }

  String get jobDesc => _str(primaryCareer?['jobDesc']) ?? '-';

  String get marketScope => _str(primaryCareer?['marketScope']) ?? '-';

  String get responsibleBrands =>
      _str(primaryCareer?['responsibleBrands']) ??
      personSeed?.brandNames?.trim() ??
      '-';

  String get archivePeriod => _str(primaryCareer?['archivePeriod']) ?? '-';

  String get ownerNames {
    final fromCareer = _str(primaryCareer?['ownerNames']);
    if (fromCareer != null) return fromCareer;
    final sales = <String>{};
    for (final o in orders) {
      final n = o.salesPerson?.trim();
      if (n != null && n.isNotEmpty) sales.add(n);
    }
    if (sales.isNotEmpty) return sales.join('、');
    return '-';
  }

  List<String> get brandNames {
    final list = personSeed?.brandNameList;
    if (list != null && list.isNotEmpty) {
      return [for (final e in list) if (e.trim().isNotEmpty) e.trim()];
    }
    final raw = personSeed?.brandNames?.trim();
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[,，;；、/|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String get brandIndustrySummary =>
      personSeed?.brandIndustrySummary?.trim() ?? '-';

  int get brandCount => personSeed?.brandCount ?? brandNames.length;

  int get enterpriseCount =>
      personSeed?.enterpriseCount ??
      (employer != '-' ? 1 : 0);

  int get agencyCount => personSeed?.agencyCount ?? 0;

  List<String> get agencyNames {
    final list = personSeed?.agencyNameList;
    if (list != null && list.isNotEmpty) {
      return [for (final e in list) if (e.trim().isNotEmpty) e.trim()];
    }
    return const [];
  }

  List<String> get sameEnterpriseContactNames {
    final list = personSeed?.sameEnterpriseContactNames;
    if (list != null && list.isNotEmpty) {
      return [for (final e in list) if (e.trim().isNotEmpty) e.trim()];
    }
    return const [];
  }

  int get sameEnterpriseContactCount =>
      personSeed?.sameEnterpriseContactCount ??
      sameEnterpriseContactNames.length;

  String? get orderAmountYoyRate => personSeed?.orderAmountYoyRate?.trim();

  int get orderCount =>
      personSeed?.orderCount ??
      _asInt(contact?['orderCount']) ??
      orders.length;

  String get orderAmount {
    final fromSeed = personSeed?.orderAmount?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    var sum = 0.0;
    for (final o in orders) {
      sum += num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
    }
    return sum.toStringAsFixed(2);
  }

  String get latestOrderTime {
    final fromSeed = personSeed?.latestOrderTime?.trim();
    if (fromSeed != null && fromSeed.isNotEmpty) return fromSeed;
    if (orders.isNotEmpty) return orders.first.orderTime?.trim() ?? '-';
    return '-';
  }

  OrderItem? get latestOrder => orders.isNotEmpty ? orders.first : null;

  List<Map<String, dynamic>> get aiBriefs {
    final list = contact?['aiBriefs'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  Map<String, int> get contractTypeCounts {
    final counts = <String, int>{};
    for (final o in orders) {
      final t = o.contractType?.trim();
      if (t == null || t.isEmpty) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get enterpriseOrderCounts {
    final counts = <String, int>{};
    for (final o in orders) {
      final n = o.enterprise?.trim();
      if (n == null || n.isEmpty) continue;
      counts[n] = (counts[n] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, ({int count, double amount})> get salesStats {
    final map = <String, ({int count, double amount})>{};
    for (final o in orders) {
      final name = o.salesPerson?.trim();
      if (name == null || name.isEmpty) continue;
      final prev = map[name];
      final amt = num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
      map[name] = (
        count: (prev?.count ?? 0) + 1,
        amount: (prev?.amount ?? 0) + amt,
      );
    }
    return map;
  }

  RelationGraph buildRelationGraph() {
    final nodes = <RelationNode>[];
    final links = <RelationLink>[];
    const centerId = 'person';
    nodes.add(
      RelationNode()
        ..id = centerId
        ..name = displayName
        ..category = 'contact',
    );
    void addLink(String id, String name, String category, String label) {
      if (name.isEmpty || name == '-') return;
      nodes.add(
        RelationNode()
          ..id = id
          ..name = name
          ..category = category,
      );
      links.add(
        RelationLink()
          ..source = centerId
          ..target = id
          ..label = label,
      );
    }

    final emp = employer;
    if (emp != '-') {
      final is4a = enterpriseType.contains('4A');
      addLink(
        is4a ? 'agency-emp' : 'ent-emp',
        emp,
        is4a ? 'agency' : 'enterprise',
        is4a ? '就职4A' : '就职企业',
      );
    }
    for (var i = 0; i < brandNames.length; i++) {
      addLink('brand-$i', brandNames[i], 'brand', '负责品牌');
    }
    for (var i = 0; i < agencyNames.length; i++) {
      if (agencyNames[i] == emp) continue;
      addLink('agency-$i', agencyNames[i], 'agency', '关联4A');
    }
    final owners = ownerNames
        .split(RegExp(r'[,，;；、/|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != '-')
        .toList();
    for (var i = 0; i < owners.length; i++) {
      addLink('sales-$i', owners[i], 'salesperson', '负责销售');
    }
    return RelationGraph()
      ..nodes = nodes
      ..links = links;
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = '$v'.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }
}
