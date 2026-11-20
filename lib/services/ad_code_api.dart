import 'dart:convert';

import '../config/api_config.dart';
import '../models/ad_code.dart';
import 'api_http.dart';
import 'auth_session.dart';

class AdCodeApiException implements Exception {
  AdCodeApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdCodeApi {
  /// [parentCode] 缺省 100000（中国）查省份；传入省/市编码查下级。
  Future<List<AdCodeItem>> fetchChildren({int parentCode = 100000}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adCodeList}')
        .replace(queryParameters: {'parentCode': '$parentCode'});
    return _parseList(await _getJson(uri), failLabel: '行政区划加载失败');
  }

  /// 全国城市：`GET /desktop/common/ad-code/cities`。
  Future<List<AdCodeItem>> fetchCities() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adCodeCities}');
    return _parseList(await _getJson(uri), failLabel: '城市列表加载失败');
  }

  List<AdCodeItem> _parseList(
    Map<String, dynamic> body, {
    required String failLabel,
  }) {
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw AdCodeApiException(body['msg']?.toString() ?? failLabel);
    }

    final raw = body['data'];
    final list = <AdCodeItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parse(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  AdCodeItem _parse(Map<String, dynamic> json) {
    return AdCodeItem()
      ..id = _asInt(json['id'])
      ..code = _asInt(json['code'])
      ..chName = json['chName']?.toString()
      ..enName = json['enName']?.toString()
      ..parentCode = _asInt(json['parentCode']);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );
      if (response.body.isEmpty) {
        throw AdCodeApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AdCodeApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw AdCodeApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AdCodeApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on AdCodeApiException {
      rethrow;
    } catch (e) {
      throw AdCodeApiException(e.toString());
    }
  }

  int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
