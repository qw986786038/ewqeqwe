import 'dart:convert';

import '../config/api_config.dart';
import '../models/dict_data.dart';
import 'api_http.dart';
import 'auth_session.dart';

class DictApiException implements Exception {
  DictApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DictApi {
  Future<List<DictDataItem>> fetchByType(String dictType) async {
    final type = dictType.trim();
    if (type.isEmpty) {
      throw DictApiException('字典类型不能为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.dictDataByType(type)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw DictApiException(body['msg']?.toString() ?? '字典加载失败');
    }

    final raw = body['data'];
    final list = <DictDataItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(_parse(Map<String, dynamic>.from(item)));
        }
      }
    }
    list.sort((a, b) => (a.dictSort ?? 0).compareTo(b.dictSort ?? 0));
    return list
        .where((e) {
          final s = e.status?.trim();
          return s == null || s.isEmpty || s == '0';
        })
        .toList();
  }

  /// 批量拉取多种字典；单项失败不影响其它类型。
  Future<Map<String, List<DictDataItem>>> fetchMany(
    Iterable<String> types,
  ) async {
    final result = <String, List<DictDataItem>>{};
    await Future.wait([
      for (final t in types)
        () async {
          try {
            result[t] = await fetchByType(t);
          } catch (_) {
            result[t] = const [];
          }
        }(),
    ]);
    return result;
  }

  DictDataItem _parse(Map<String, dynamic> json) {
    return DictDataItem()
      ..dictCode = _asInt(json['dictCode'])
      ..dictSort = _asInt(json['dictSort'])
      ..dictLabel = json['dictLabel']?.toString()
      ..dictValue = json['dictValue']?.toString()
      ..dictType = json['dictType']?.toString()
      ..cssClass = json['cssClass']?.toString()
      ..listClass = json['listClass']?.toString()
      ..isDefault = json['isDefault']?.toString()
      ..status = json['status']?.toString()
      ..remark = json['remark']?.toString()
      ..createTime = json['createTime']?.toString();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );
      if (response.body.isEmpty) {
        throw DictApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw DictApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw DictApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DictApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on DictApiException {
      rethrow;
    } catch (e) {
      throw DictApiException(e.toString());
    }
  }

  int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
