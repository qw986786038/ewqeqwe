import 'dart:convert';

import '../config/api_config.dart';
import '../models/oac_brand.dart';
import '../models/oac_brand_detail.dart';
import 'api_http.dart';
import 'auth_session.dart';

class BrandApiException implements Exception {
  BrandApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BrandApi {
  Future<OacBrandOverview> fetchOverview([OacBrandQuery? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.brandOverview}')
        .replace(queryParameters: _filterParams(query));

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw BrandApiException(body['msg']?.toString() ?? 'KPI 加载失败');
    }

    final data = body['data'];
    if (data is! Map) {
      return OacBrandOverview();
    }
    return _parseOverview(Map<String, dynamic>.from(data));
  }

  Future<OacBrandListPage> fetchList([OacBrandQuery? query]) async {
    final q = query ?? OacBrandQuery();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.brandList}')
        .replace(queryParameters: q.toQueryParameters());

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw BrandApiException(body['msg']?.toString() ?? '品牌列表加载失败');
    }

    final rowsRaw = body['rows'];
    final rows = <OacBrand>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parseBrand(Map<String, dynamic>.from(item)));
        }
      }
    }

    return OacBrandListPage(
      total: _asInt(body['total']) ?? rows.length,
      rows: rows,
    );
  }

  Future<OacBrandDetail> fetchDetail(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.brandDetail(id)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw BrandApiException(body['msg']?.toString() ?? '品牌详情加载失败');
    }
    final data = body['data'];
    if (data is! Map) {
      return OacBrandDetail();
    }
    return _parseDetail(Map<String, dynamic>.from(data));
  }

  Map<String, String>? _filterParams(OacBrandQuery? query) {
    if (query == null) return null;
    final map = query.toQueryParameters();
    map.remove('pageNum');
    map.remove('pageSize');
    map.remove('orderByColumn');
    map.remove('isAsc');
    return map.isEmpty ? null : map;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );

      if (response.body.isEmpty) {
        throw BrandApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw BrandApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw BrandApiException(decoded['msg']?.toString() ?? '未登录或登录已过期');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BrandApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on BrandApiException {
      rethrow;
    } on FormatException {
      throw BrandApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is BrandApiException) rethrow;
      throw BrandApiException('网络请求失败：$e');
    }
  }
}

OacBrandOverview _parseOverview(Map<String, dynamic> json) {
  return OacBrandOverview()
    ..totalOrderCount = _asInt(json['totalOrderCount'])
    ..totalOrderAmount = _asString(json['totalOrderAmount'])
    ..orderCountMomRate = _asString(json['orderCountMomRate'])
    ..orderAmountMomRate = _asString(json['orderAmountMomRate'])
    ..relatedEnterpriseCount = _asInt(json['relatedEnterpriseCount'])
    ..relatedAgencyCount = _asInt(json['relatedAgencyCount'])
    ..internationalAgencyCount = _asInt(json['internationalAgencyCount'])
    ..contactCount = _asInt(json['contactCount'])
    ..contactNewThisWeek = _asInt(json['contactNewThisWeek'])
    ..latestOrderTime = _asString(json['latestOrderTime'])
    ..latestOrderBrandName = _asString(json['latestOrderBrandName'])
    ..industryCount = _asInt(json['industryCount'])
    ..dataAsOf = _asString(json['dataAsOf']);
}

OacBrandDetail _parseDetail(Map<String, dynamic> json) {
  final detail = OacBrandDetail();
  final brand = json['brand'];
  if (brand is Map) {
    detail.brand = _parseBrand(Map<String, dynamic>.from(brand));
  }
  detail.subBrands = _asStringList(json['subBrands']) ?? const [];
  detail.enterprises = _parseList(json['enterprises'], _parseEnterprise);
  detail.agencies = _parseList(json['agencies'], _parseAgency);
  detail.contacts = _parseList(json['contacts'], _parseContact);
  detail.orders = _parseList(json['orders'], _parseOrder);
  detail.mediaFormats = _parseList(json['mediaFormats'], _parseMediaFormat);
  detail.monthlyTrend = _parseList(json['monthlyTrend'], _parseMonthAmount);
  final graph = json['relationGraph'];
  if (graph is Map) {
    detail.relationGraph = _parseRelationGraph(Map<String, dynamic>.from(graph));
  }
  final hq = json['hqLocation'];
  if (hq is Map) {
    detail.hqLocation = _parseHq(Map<String, dynamic>.from(hq));
  }
  detail.orderAmountYoyRate = _asString(json['orderAmountYoyRate']);
  detail.orderAmountMomRate = _asString(json['orderAmountMomRate']);
  return detail;
}

OacBrand _parseBrand(Map<String, dynamic> json) {
  return OacBrand()
    ..id = _asString(json['id'])
    ..tenantId = _asString(json['tenantId'])
    ..brandCode = _asString(json['brandCode'])
    ..name = _asString(json['name'])
    ..industry = _asString(json['industry'])
    ..city = _asString(json['city'])
    ..tags = _asString(json['tags'])
    ..tagList = _asStringList(json['tagList'])
    ..clientTag = _asString(json['clientTag'])
    ..spokesperson = _asString(json['spokesperson'])
    ..weight = _asInt(json['weight'])
    ..iconUrl = _asString(json['iconUrl'])
    ..ownerNames = _asString(json['ownerNames'])
    ..ownerNameList = _asStringList(json['ownerNameList'])
    ..latestDynamic = _asString(json['latestDynamic'])
    ..orderCount = _asInt(json['orderCount'])
    ..orderAmount = _asString(json['orderAmount'])
    ..enterpriseCount = _asInt(json['enterpriseCount'])
    ..agencyCount = _asInt(json['agencyCount'])
    ..contactCount = _asInt(json['contactCount'])
    ..latestOrderTime = _asString(json['latestOrderTime'])
    ..status = _asString(json['status'])
    ..remark = _asString(json['remark'])
    ..createTime = _asString(json['createTime'])
    ..updateTime = _asString(json['updateTime']);
}

EnterpriseItem _parseEnterprise(Map<String, dynamic> json) => EnterpriseItem()
  ..id = _asString(json['id'])
  ..name = _asString(json['name'])
  ..type = _asString(json['relationType']) ?? _asString(json['type'])
  ..city = _asString(json['city']);

AgencyItem _parseAgency(Map<String, dynamic> json) => AgencyItem()
  ..id = _asString(json['id'])
  ..name = _asString(json['name']);

ContactItem _parseContact(Map<String, dynamic> json) => ContactItem()
  ..id = _asString(json['id'])
  ..name = _asString(json['name'])
  ..title = _asString(json['title'])
  ..orgName = _asString(json['orgName'])
  ..phone = _asString(json['phone'])
  ..email = _asString(json['email'])
  ..enterpriseId = _asString(json['enterpriseId']);

OrderItem _parseOrder(Map<String, dynamic> json) => OrderItem()
  ..id = _asString(json['id'])
  ..name = _asString(json['name'])
  ..orderNo = _asString(json['orderNo'])
  ..tag = _asString(json['tag'])
  ..enterprise = _asString(json['enterprise']) ??
      _asString(json['enterpriseName'])
  ..relation = _asString(json['relation']) ??
      _asString(json['dealRelation'])
  ..contractType = _asString(json['contractType'])
  ..amount = _asString(json['amount'])
  ..orderTime = _asString(json['orderTime']) ?? _asString(json['signDate'])
  ..contact = _asString(json['contact']) ?? _asString(json['contactName'])
  ..agencyId = _asString(json['agencyId']) ??
      _asString(json['agencyCustomerId'])
  ..agencyName = _asString(json['agencyName'])
  ..salesPerson = _asString(json['salesPerson']) ??
      _asString(json['salesperson']) ??
      _asString(json['sales']) ??
      _asString(json['ownerNames'])
  ..remark = _asString(json['remark']);

MediaFormatItem _parseMediaFormat(Map<String, dynamic> json) =>
    MediaFormatItem()
      ..name = _asString(json['name'])
      ..percent = json['percent'] is num
          ? json['percent'] as num
          : num.tryParse('${json['percent'] ?? ''}')
      ..tone = _asString(json['tone']);

MonthAmountItem _parseMonthAmount(Map<String, dynamic> json) =>
    MonthAmountItem()
      ..month = _asString(json['month'])
      ..amount = _asString(json['amount']);

RelationGraph _parseRelationGraph(Map<String, dynamic> json) {
  return RelationGraph()
    ..nodes = _parseList(json['nodes'], (m) {
      return RelationNode()
        ..id = _asString(m['id'])
        ..name = _asString(m['name'])
        ..category = _asString(m['category']);
    })
    ..links = _parseList(json['links'], (m) {
      return RelationLink()
        ..source = _asString(m['source'])
        ..target = _asString(m['target'])
        ..label = _asString(m['label']);
    });
}

HqLocation _parseHq(Map<String, dynamic> json) => HqLocation()
  ..region = _asString(json['region'])
  ..name = _asString(json['name'])
  ..address = _asString(json['address'])
  ..lng = json['lng'] is num
      ? (json['lng'] as num).toDouble()
      : double.tryParse('${json['lng'] ?? ''}')
  ..lat = json['lat'] is num
      ? (json['lat'] as num).toDouble()
      : double.tryParse('${json['lat'] ?? ''}');

List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) map,
) {
  if (raw is! List) return <T>[];
  final out = <T>[];
  for (final item in raw) {
    if (item is Map) {
      out.add(map(Map<String, dynamic>.from(item)));
    }
  }
  return out;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

List<String>? _asStringList(dynamic v) {
  if (v is! List) return null;
  return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}
