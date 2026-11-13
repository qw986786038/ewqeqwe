import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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

  /// 按当前筛选导出品牌 Excel：`POST /desktop/oac/brand/export`。
  Future<({Uint8List bytes, String fileName})> export([
    OacBrandQuery? query,
  ]) async {
    final params = (query ?? OacBrandQuery()).toQueryParameters()
      ..remove('pageNum')
      ..remove('pageSize');
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.brandExport}')
        .replace(queryParameters: params.isEmpty ? null : params);
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      final stamp = DateTime.now().millisecondsSinceEpoch;
      return _parseExcelResponse(
        response,
        fallbackName: 'oac_brand_$stamp.xlsx',
        failLabel: '导出',
      );
    } on BrandApiException {
      rethrow;
    } catch (e) {
      if (e is BrandApiException) rethrow;
      throw BrandApiException('网络请求失败：$e');
    }
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

  static ({Uint8List bytes, String fileName}) _parseExcelResponse(
    http.Response response, {
    required String fallbackName,
    required String failLabel,
  }) {
    // Excel 为二进制，禁止用 response.body（会按 UTF-8 解码并抛 FormatException）。
    final bytes = response.bodyBytes;
    final contentType = response.headers['content-type'] ?? '';
    // 服务端若误标 application/json，仍以文件魔数优先按 Excel 处理。
    final isExcelBinary = _bytesLookLikeExcel(bytes);
    final looksJson = !isExcelBinary &&
        (contentType.contains('json') || _bytesLookLikeJson(bytes));
    if (looksJson) {
      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(utf8.decode(bytes));
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {}
      final msg = decoded?['msg']?.toString();
      if (response.statusCode == 401) {
        throw BrandApiException(msg ?? '未登录或登录已过期');
      }
      throw BrandApiException(
        msg ?? '$failLabel失败(${response.statusCode})',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BrandApiException('$failLabel失败(${response.statusCode})');
    }
    if (bytes.isEmpty) {
      throw BrandApiException('$failLabel文件为空');
    }
    return (
      bytes: bytes,
      fileName: _fileNameFromDisposition(
            response.headers['content-disposition'],
          ) ??
          fallbackName,
    );
  }

  /// 不解码全文，仅看首个非空白字节是否为 `{` / `[`。
  static bool _bytesLookLikeJson(Uint8List bytes) {
    for (final b in bytes) {
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) continue;
      return b == 0x7B || b == 0x5B;
    }
    return false;
  }

  /// `.xlsx`（ZIP/`PK`）或旧版 `.xls`（OLE）。
  static bool _bytesLookLikeExcel(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      return true;
    }
    return bytes.length >= 8 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0;
  }

  static String? _fileNameFromDisposition(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final utf8Name = RegExp(
      r"filename\*\s*=\s*UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(raw);
    if (utf8Name != null) {
      try {
        return Uri.decodeComponent(utf8Name.group(1)!.trim());
      } catch (_) {
        return utf8Name.group(1)!.trim();
      }
    }
    final plain = RegExp(
      r'filename\s*=\s*"?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(raw);
    final name = plain?.group(1)?.trim();
    return (name == null || name.isEmpty) ? null : name;
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
  final brand = json['brand'] ?? json['enterprise'] ?? json['customer'];
  if (brand is Map) {
    detail.brand = _parseBrand(Map<String, dynamic>.from(brand));
  }
  detail.subBrands = _asStringList(json['subBrands']) ?? const [];
  detail.enterprises = _parseList(json['enterprises'], _parseEnterprise);
  detail.brands = _parseList(json['brands'], _parseRelatedBrand);
  detail.agencies = _parseList(json['agencies'], _parseAgency);
  detail.contacts = _parseList(json['contacts'], _parseContact);
  detail.salesList = _parseList(json['salesList'], _parseSales);
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
    ..customerType = _asString(json['customerType'])
    ..relationType = _asString(json['relationType'])
    ..entityNature = _asString(json['entityNature'])
    ..industry = _asString(json['industry'])
    ..industryLabel = _asString(json['industryLabel'])
    ..city = _asString(json['city'])
    ..tags = _asString(json['tags'])
    ..tagList = _asStringList(json['tagList'])
    ..clientTag = _asString(json['clientTag'])
    ..clientTagLabel = _asString(json['clientTagLabel'])
    ..spokesperson = _asString(json['spokesperson'])
    ..weight = _asInt(json['weight'])
    ..healthScore = _asInt(json['healthScore'])
    ..healthLabel = _asString(json['healthLabel'])
    ..topRank = _asInt(json['topRank'])
    ..iconUrl = _asString(json['iconUrl'])
    ..ownerNames = _asString(json['ownerNames'])
    ..ownerNameList = _asStringList(json['ownerNameList'])
    ..latestDynamic = _asString(json['latestDynamic'])
    ..orderCount = _asInt(json['orderCount'])
    ..orderAmount = _asString(json['orderAmount'])
    ..enterpriseCount = _asInt(json['enterpriseCount'])
    ..brandCount = _asInt(json['brandCount']) ??
        _asInt(json['relatedBrandCount'])
    ..agencyCount = _asInt(json['agencyCount'])
    ..agencyNames = _asString(json['agencyNames'])
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
  ..entityNature = _asString(json['entityNature'])
  ..city = _asString(json['city'])
  ..address = _asString(json['address'])
  ..province = _asString(json['province']);

RelatedBrandItem _parseRelatedBrand(Map<String, dynamic> json) =>
    RelatedBrandItem()
      ..id = _asString(json['id'])
      ..name = _asString(json['name'])
      ..industry = _asString(json['industry']) ??
          _asString(json['industryLabel']);

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

SalesItem _parseSales(Map<String, dynamic> json) => SalesItem()
  ..id = _asString(json['id'])
  ..userId = _asInt(json['userId'])
  ..name = _asString(json['name'])
  ..nameEn = _asString(json['nameEn'])
  ..gender = _asString(json['gender'])
  ..deptTitle = _asString(json['deptTitle'])
  ..assignTime = _asString(json['assignTime']);

OrderItem _parseOrder(Map<String, dynamic> json) => OrderItem()
  ..id = _asString(json['id'])
  ..name = _asString(json['name'])
  ..orderNo = _asString(json['orderNo'])
  ..tag = _asString(json['tag'])
  ..enterprise = _asString(json['enterprise']) ??
      _asString(json['enterpriseName'])
  ..signEnterpriseId = _asString(json['signEnterpriseId']) ??
      _asString(json['enterpriseId'])
  ..relation = _asString(json['relation']) ??
      _asString(json['dealRelation'])
  ..relationLabel = _asString(json['relationLabel'])
  ..contractType = _asString(json['contractType'])
  ..amount = _asString(json['amount'])
  ..orderTime = _asString(json['orderTime']) ?? _asString(json['signDate'])
  ..periodStart = _asString(json['periodStart'])
  ..periodEnd = _asString(json['periodEnd'])
  ..durationDays = json['durationDays'] is int
      ? json['durationDays'] as int
      : int.tryParse('${json['durationDays'] ?? ''}')
  ..contact = _asString(json['contact']) ?? _asString(json['contactName'])
  ..agencyId = _asString(json['agencyId']) ??
      _asString(json['agencyCustomerId'])
  ..agencyName = _asString(json['agencyName'])
  ..brandId = _asString(json['brandId'])
  ..brandName = _asString(json['brandName'])
  ..industry = _asString(json['industry'])
  ..city = _asString(json['city'])
  ..customerType = _asString(json['customerType'])
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

HqLocation _parseHq(Map<String, dynamic> json) {
  double? asDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    final s = '$raw'.trim();
    if (s.isEmpty || s == 'null') return null;
    return double.tryParse(s);
  }

  // 兼容 lng/lat、longitude/latitude、lon，以及嵌套 location。
  final loc = json['location'];
  final locMap = loc is Map ? Map<String, dynamic>.from(loc) : null;
  return HqLocation()
    ..region = _asString(json['region']) ??
        _asString(json['city']) ??
        _asString(json['province'])
    ..name = _asString(json['name']) ?? _asString(json['companyName'])
    ..address = _asString(json['address']) ??
        _asString(json['fullAddress']) ??
        _asString(json['officeAddress'])
    ..lng = asDouble(json['lng']) ??
        asDouble(json['longitude']) ??
        asDouble(json['lon']) ??
        asDouble(locMap?['lng']) ??
        asDouble(locMap?['longitude']) ??
        asDouble(locMap?['lon'])
    ..lat = asDouble(json['lat']) ??
        asDouble(json['latitude']) ??
        asDouble(locMap?['lat']) ??
        asDouble(locMap?['latitude']);
}

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
