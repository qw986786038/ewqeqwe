import 'dart:convert';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:yidivination/bokong/entity/page_entity.dart';

class AppRespEntity<T> {
  int? code;
  String? msg;

  PageEntity? page;
  T? data;
  dynamic obj;

  AppRespEntity(this.code, this.msg, this.data, {this.page, this.obj});

  AppRespEntity.fromJson(json) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(json as Map);

    if (map['code'] != null) {
      code = map['code']?.toInt();
    }
    if (map['msg'] != null) {
      msg = map['msg']?.toString();
    }

    page = PageEntity.tryFromResponse(map);

    if (map['data'] != null) {
      final dynamic payload = map['data'];
      if (payload is Map && payload['data'] is List) {
        page =
            PageEntity.tryFromResponse(Map<String, dynamic>.from(payload)) ??
            page;
      }
      data = _generateOBJ(payload);
    }

    if (map["obj"] != null) {
      obj = map['obj'];
    }
  }

  bool isSuccess() => code == 200;

  String info() => msg ?? "操作失败";

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> resp = <String, dynamic>{};
    resp['code'] = code;
    resp['msg'] = msg;
    if (page != null) {
      resp.addAll(page!.toJson());
    }
    if (data is String) {
      resp['data'] = data;
    } else if (data is Map<dynamic, dynamic>) {
      resp['data'] = data;
    } else {
      resp['data'] = json.decode(JsonMapper.serialize(data));
    }
    return resp;
  }

  @override
  String toString() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['code'] = code;
    map['msg'] = msg;
    map['page'] = page?.toString();
    map['data'] = data.toString();
    map['obj'] = obj.toString();

    return map.toString();
  }

  T? _generateOBJ(mJson) {
    if (T == String) {
      return mJson?.toString() as T?;
    } else if (T == Map<dynamic, dynamic>) {
      return mJson as T?;
    } else if (T == dynamic) {
      return mJson as T?;
    } else {
      /// List / 实体等由 JsonMapper 按泛型 T 反序列化
      return JsonMapper.deserialize<T>(
        json.encode(_normalizeJsonPayload(mJson)),
      );
    }
  }

  /// 仅当目标类型是 List 时，才把 `{ "list": [...] }` / 分页 `{ "data": [...] }`
  /// 拆成数组。对象实体（如 `{ "kpiCards": [...] }`）不可拆，否则会把 List
  /// 误喂给需要 Map 的反序列化。
  dynamic _normalizeJsonPayload(dynamic mJson) {
    if (!_isListTargetType) return mJson;
    if (mJson is Map && mJson.length == 1 && mJson.values.first is List) {
      return mJson.values.first;
    }
    if (mJson is Map && mJson['data'] is List) {
      return mJson['data'];
    }
    return mJson;
  }

  bool get _isListTargetType {
    final name = T.toString();
    return name.startsWith('List<') || name == 'List';
  }
}
