import 'dart:convert';

import '../config/api_config.dart';
import '../models/oac_agency.dart';
import 'api_http.dart';
import 'auth_session.dart';

class AgencyApiException implements Exception {
  AgencyApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AgencyApi {
  Future<OacAgencyOverview> fetchOverview([OacAgencyQuery? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agencyOverview}')
        .replace(queryParameters: _filterParams(query));

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw AgencyApiException(body['msg']?.toString() ?? 'KPI 加载失败');
    }

    final data = body['data'];
    if (data is! Map) {
      return OacAgencyOverview();
    }
    return _parseOverview(Map<String, dynamic>.from(data));
  }

  Future<OacAgencyListPage> fetchList([OacAgencyQuery? query]) async {
    final q = query ?? OacAgencyQuery();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agencyList}')
        .replace(queryParameters: q.toQueryParameters());

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw AgencyApiException(body['msg']?.toString() ?? '4A 列表加载失败');
    }

    final rowsRaw = body['rows'] ?? body['data'];
    final rows = <OacAgency>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parseAgency(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rowsRaw is Map) {
      final nested = rowsRaw['rows'] ?? rowsRaw['list'] ?? rowsRaw['records'];
      if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            rows.add(_parseAgency(Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    final total = _asInt(body['total']) ??
        _asInt(body['data'] is Map ? (body['data'] as Map)['total'] : null) ??
        rows.length;

    return OacAgencyListPage(total: total, rows: rows);
  }

  Map<String, String>? _filterParams(OacAgencyQuery? query) {
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
        throw AgencyApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AgencyApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw AgencyApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AgencyApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on AgencyApiException {
      rethrow;
    } on FormatException {
      throw AgencyApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is AgencyApiException) rethrow;
      throw AgencyApiException('网络请求失败：$e');
    }
  }
}

OacAgencyOverview _parseOverview(Map<String, dynamic> json) =>
    OacAgencyOverview()
      ..totalOrderCount = _asInt(json['totalOrderCount'])
      ..totalOrderAmount = _asString(json['totalOrderAmount'])
      ..orderCountMomRate = _asString(json['orderCountMomRate'])
      ..orderAmountMomRate = _asString(json['orderAmountMomRate'])
      ..relatedBrandCount = _asInt(json['relatedBrandCount']) ??
          _asInt(json['brandCount'])
      ..relatedEnterpriseCount = _asInt(json['relatedEnterpriseCount']) ??
          _asInt(json['enterpriseCount'])
      ..contactCount = _asInt(json['contactCount'])
      ..contactNewThisWeek = _asInt(json['contactNewThisWeek'])
      ..latestOrderTime = _asString(json['latestOrderTime'])
      ..latestOrderAgencyName = _asString(json['latestOrderAgencyName']) ??
          _asString(json['latestOrderName'])
      ..avgBrandPerAgency = _asString(json['avgBrandPerAgency'])
      ..dataAsOf = _asString(json['dataAsOf']);

OacAgency _parseAgency(Map<String, dynamic> json) => OacAgency()
  ..id = _asString(json['id'])
  ..tenantId = _asString(json['tenantId'])
  ..name = _asString(json['name']) ??
      _asString(json['fullName']) ??
      _asString(json['agencyName'])
  ..shortName = _asString(json['shortName'])
  ..city = _asString(json['city'])
  ..province = _asString(json['province'])
  ..address = _asString(json['address'])
  ..relationType = _asString(json['relationType'])
  ..tags = _asString(json['tags'])
  ..tagList = _asStringList(json['tagList']) ??
      _splitCsv(_asString(json['tags']))
  ..clientTag = _asString(json['clientTag'])
  ..weight = _asInt(json['weight'])
  ..iconUrl = _asString(json['iconUrl'])
  ..ownerNames = _asString(json['ownerNames'])
  ..ownerNameList = _asStringList(json['ownerNameList']) ??
      _splitCsv(_asString(json['ownerNames']))
  ..latestDynamic = _asString(json['latestDynamic'])
  ..orderCount = _asInt(json['orderCount'])
  ..orderAmount = _asString(json['orderAmount'])
  ..brandCount = _asInt(json['brandCount']) ??
      _asInt(json['relatedBrandCount'])
  ..brandNames = _asString(json['brandNames']) ??
      _asString(json['relatedBrandNames'])
  ..brandNameList = _asStringList(json['brandNameList']) ??
      _splitCsv(_asString(json['brandNames']))
  ..enterpriseCount = _asInt(json['enterpriseCount']) ??
      _asInt(json['relatedEnterpriseCount'])
  ..enterpriseNames = _asString(json['enterpriseNames']) ??
      _asString(json['relatedEnterpriseNames'])
  ..enterpriseNameList = _asStringList(json['enterpriseNameList']) ??
      _splitCsv(_asString(json['enterpriseNames']))
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
