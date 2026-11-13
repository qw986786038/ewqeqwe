import 'dart:convert';

import '../config/api_config.dart';
import '../models/oac_enterprise.dart';
import 'api_http.dart';
import 'auth_session.dart';

class EnterpriseApiException implements Exception {
  EnterpriseApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EnterpriseApi {
  Future<OacEnterpriseOverview> fetchOverview([OacEnterpriseQuery? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.enterpriseOverview}')
        .replace(queryParameters: _filterParams(query));

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw EnterpriseApiException(body['msg']?.toString() ?? 'KPI 加载失败');
    }

    final data = body['data'];
    if (data is! Map) {
      return OacEnterpriseOverview();
    }
    return _parseOverview(Map<String, dynamic>.from(data));
  }

  Future<OacEnterpriseListPage> fetchList([OacEnterpriseQuery? query]) async {
    final q = query ?? OacEnterpriseQuery();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.enterpriseList}')
        .replace(queryParameters: q.toQueryParameters());

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw EnterpriseApiException(body['msg']?.toString() ?? '企业列表加载失败');
    }

    final rowsRaw = body['rows'] ?? body['data'];
    final rows = <OacEnterprise>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parseEnterprise(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rowsRaw is Map) {
      final nested = rowsRaw['rows'] ?? rowsRaw['list'] ?? rowsRaw['records'];
      if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            rows.add(_parseEnterprise(Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    final total = _asInt(body['total']) ??
        _asInt(body['data'] is Map ? (body['data'] as Map)['total'] : null) ??
        rows.length;

    return OacEnterpriseListPage(total: total, rows: rows);
  }

  Map<String, String>? _filterParams(OacEnterpriseQuery? query) {
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
        throw EnterpriseApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw EnterpriseApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw EnterpriseApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EnterpriseApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on EnterpriseApiException {
      rethrow;
    } on FormatException {
      throw EnterpriseApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is EnterpriseApiException) rethrow;
      throw EnterpriseApiException('网络请求失败：$e');
    }
  }
}

OacEnterpriseOverview _parseOverview(Map<String, dynamic> json) =>
    OacEnterpriseOverview()
      ..totalOrderCount = _asInt(json['totalOrderCount'])
      ..totalOrderAmount = _asString(json['totalOrderAmount'])
      ..orderCountMomRate = _asString(json['orderCountMomRate'])
      ..orderAmountMomRate = _asString(json['orderAmountMomRate'])
      ..relatedBrandCount = _asInt(json['relatedBrandCount']) ??
          _asInt(json['brandCount'])
      ..relatedAgencyCount = _asInt(json['relatedAgencyCount']) ??
          _asInt(json['agencyCount'])
      ..internationalAgencyCount = _asInt(json['internationalAgencyCount'])
      ..contactCount = _asInt(json['contactCount'])
      ..contactNewThisWeek = _asInt(json['contactNewThisWeek'])
      ..latestOrderTime = _asString(json['latestOrderTime'])
      ..latestOrderEnterpriseName = _asString(json['latestOrderEnterpriseName']) ??
          _asString(json['latestOrderName'])
      ..latestOrderBrandName = _asString(json['latestOrderBrandName'])
      ..industryCount = _asInt(json['industryCount'])
      ..dataAsOf = _asString(json['dataAsOf']);

OacEnterprise _parseEnterprise(Map<String, dynamic> json) => OacEnterprise()
  ..id = _asString(json['id'])
  ..customerId = _asString(json['customerId']) ??
      _asString(json['customer_id'])
  ..tenantId = _asString(json['tenantId'])
  ..enterpriseCode = _asString(json['enterpriseCode'])
  ..name = _asString(json['name']) ??
      _asString(json['fullName']) ??
      _asString(json['enterpriseName'])
  ..shortName = _asString(json['shortName'])
  ..industry = _asString(json['industry'])
  ..city = _asString(json['city'])
  ..province = _asString(json['province'])
  ..address = _asString(json['address'])
  ..relationType = _asString(json['relationType'])
  ..entityNature = _asString(json['entityNature'])
  ..tags = _asString(json['tags'])
  ..tagList = _asStringList(json['tagList']) ??
      _splitCsv(_asString(json['tags']))
  ..clientTag = _asString(json['clientTag'])
  ..weight = _asInt(json['weight'])
  ..coverageScore = _asInt(json['coverageScore'])
  ..coverageGrade = _asString(json['coverageGrade'])
  ..iconUrl = _asString(json['iconUrl'])
  ..ownerNames = _asString(json['ownerNames'])
  ..ownerNameList = _asStringList(json['ownerNameList']) ??
      _splitCsv(_asString(json['ownerNames']))
  ..latestDynamic = _asString(json['latestDynamic'])
  ..orderCount = _asInt(json['orderCount'])
  ..orderAmount = _asString(json['orderAmount'])
  ..orderAmountYoyRate = _asString(json['orderAmountYoyRate'])
  ..deptPerfShareRate = _asString(json['deptPerfShareRate'])
  ..brandCount = _asInt(json['brandCount']) ??
      _asInt(json['relatedBrandCount'])
  ..brandNames = _asString(json['brandNames']) ??
      _asString(json['relatedBrandNames'])
  ..brandNameList = _asStringList(json['brandNameList']) ??
      _splitCsv(_asString(json['brandNames']))
  ..brandIdList = _asStringList(json['brandIdList'])
  ..agencyCount = _asInt(json['agencyCount']) ??
      _asInt(json['relatedAgencyCount'])
  ..agencyNames = _asString(json['agencyNames'])
  ..agencyNameList = _asStringList(json['agencyNameList']) ??
      _splitCsv(_asString(json['agencyNames']))
  ..contactCount = _asInt(json['contactCount'])
  ..latestOrderTime = _asString(json['latestOrderTime'])
  ..status = _asString(json['status'])
  ..remark = _asString(json['remark'])
  ..createTime = _asString(json['createTime'])
  ..updateTime = _asString(json['updateTime']);

String? _asString(dynamic v) {
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

List<String>? _asStringList(dynamic v) {
  if (v is! List) return null;
  final out = <String>[
    for (final e in v)
      if ('$e'.trim().isNotEmpty) '$e'.trim(),
  ];
  return out.isEmpty ? null : out;
}

List<String>? _splitCsv(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw
      .split(RegExp(r'[,，;；、/|]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.isEmpty ? null : parts;
}
