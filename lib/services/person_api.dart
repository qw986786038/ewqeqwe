import 'dart:convert';

import '../config/api_config.dart';
import '../models/oac_person.dart';
import 'api_http.dart';
import 'auth_session.dart';

class PersonApiException implements Exception {
  PersonApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PersonApi {
  Future<OacPersonOverview> fetchOverview([OacPersonQuery? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.personOverview}')
        .replace(queryParameters: _filterParams(query));

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw PersonApiException(body['msg']?.toString() ?? 'KPI 加载失败');
    }

    final data = body['data'];
    if (data is! Map) {
      return OacPersonOverview();
    }
    return _parseOverview(Map<String, dynamic>.from(data));
  }

  Future<OacPersonListPage> fetchList([OacPersonQuery? query]) async {
    final q = query ?? OacPersonQuery();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.personList}')
        .replace(queryParameters: q.toQueryParameters());

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw PersonApiException(body['msg']?.toString() ?? '联系人列表加载失败');
    }

    final rowsRaw = body['rows'] ?? body['data'];
    final rows = <OacPerson>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parsePerson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rowsRaw is Map) {
      final nested = rowsRaw['rows'] ?? rowsRaw['list'] ?? rowsRaw['records'];
      if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            rows.add(_parsePerson(Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    final total = _asInt(body['total']) ??
        _asInt(body['data'] is Map ? (body['data'] as Map)['total'] : null) ??
        rows.length;

    return OacPersonListPage(total: total, rows: rows);
  }

  Map<String, String>? _filterParams(OacPersonQuery? query) {
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
        throw PersonApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw PersonApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw PersonApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PersonApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on PersonApiException {
      rethrow;
    } on FormatException {
      throw PersonApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is PersonApiException) rethrow;
      throw PersonApiException('网络请求失败：$e');
    }
  }
}

OacPersonOverview _parseOverview(Map<String, dynamic> json) =>
    OacPersonOverview()
      ..contactCount = _asInt(json['contactCount'])
      ..relatedBrandCount = _asInt(json['relatedBrandCount'])
      ..relatedEnterpriseCount = _asInt(json['relatedEnterpriseCount'])
      ..relatedAgencyCount = _asInt(json['relatedAgencyCount'])
      ..totalOrderCount = _asInt(json['totalOrderCount'])
      ..totalOrderAmount = _asString(json['totalOrderAmount'])
      ..contactNewThisWeek = _asInt(json['contactNewThisWeek'])
      ..avgBrandPerContact = _asString(json['avgBrandPerContact'])
      ..internationalAgencyContactCount =
          _asInt(json['internationalAgencyContactCount'])
      ..latestOrderTime = _asString(json['latestOrderTime'])
      ..latestOrderContactName = _asString(json['latestOrderContactName'])
      ..dataAsOf = _asString(json['dataAsOf']);

OacPerson _parsePerson(Map<String, dynamic> json) => OacPerson()
  ..id = _asString(json['id'])
  ..tenantId = _asString(json['tenantId'])
  ..avatarUrl = _asString(json['avatarUrl'])
  ..name = _asString(json['name'])
  ..title = _asString(json['title'])
  ..latestEmployer = _asString(json['latestEmployer'])
  ..enterpriseId = _asString(json['enterpriseId'])
  ..customerId = _asString(json['customerId']) ??
      _asString(json['customer_id'])
  ..enterpriseType = _asString(json['enterpriseType'])
  ..city = _asString(json['city'])
  ..address = _asString(json['address'])
  ..sameEnterpriseContactCount = _asInt(json['sameEnterpriseContactCount'])
  ..sameEnterpriseContactNames =
      _asStringList(json['sameEnterpriseContactNames'])
  ..brandCount = _asInt(json['brandCount'])
  ..brandNames = _asString(json['brandNames'])
  ..brandNameList = _asStringList(json['brandNameList']) ??
      _splitCsv(_asString(json['brandNames']))
  ..brandIdList = _asStringList(json['brandIdList'])
  ..brandIndustrySummary = _asString(json['brandIndustrySummary'])
  ..enterpriseCount = _asInt(json['enterpriseCount'])
  ..enterpriseNameList = _asStringList(json['enterpriseNameList'])
  ..agencyCount = _asInt(json['agencyCount'])
  ..agencyNameList = _asStringList(json['agencyNameList'])
  ..orderCount = _asInt(json['orderCount'])
  ..orderAmount = _asString(json['orderAmount'])
  ..orderAmountYoyRate = _asString(json['orderAmountYoyRate'])
  ..latestOrderTime = _asString(json['latestOrderTime'])
  ..influenceScore = _asInt(json['influenceScore'])
  ..keyDecisionMaker = _asBool(json['keyDecisionMaker'])
  ..personCode = _asString(json['personCode'])
  ..realNameVerified = _asBool(json['realNameVerified'])
  ..canDecide = _asBool(json['canDecide'])
  ..status = _asString(json['status'])
  ..createTime = _asString(json['createTime'])
  ..updateTime = _asString(json['updateTime']);

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = '$v'.trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return null;
}

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
