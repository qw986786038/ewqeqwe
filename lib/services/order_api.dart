import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_http.dart';
import 'auth_session.dart';

class OrderApiException implements Exception {
  OrderApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 新增订单请求体（OacOrderBo，仅填有值字段）。
class OacOrderCreateBody {
  int? id;
  int? brandId;
  int? agencyId;
  int? agencyCustomerId;
  int? signEnterpriseId;
  String? enterpriseName;
  String? dealRelation;
  String? customerType;
  String? industry;
  String? city;
  String? orderName;
  num? amount;
  String? signDate;
  String? orderTime;
  String? periodStart;
  String? periodEnd;
  int? durationDays;
  String? contactName;
  String? ownerNames;
  String? contractType;
  String? tags;
  String? remark;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      map[key] = value is String ? value.trim() : value;
    }

    put('id', id);
    put('brandId', brandId);
    put('agencyId', agencyId);
    put('agencyCustomerId', agencyCustomerId);
    put('signEnterpriseId', signEnterpriseId);
    put('enterpriseName', enterpriseName);
    put('dealRelation', dealRelation);
    put('customerType', customerType);
    put('industry', industry);
    put('city', city);
    put('orderName', orderName);
    put('amount', amount);
    put('signDate', signDate);
    put('orderTime', orderTime);
    put('periodStart', periodStart);
    put('periodEnd', periodEnd);
    put('durationDays', durationDays);
    put('contactName', contactName);
    put('ownerNames', ownerNames);
    put('contractType', contractType);
    put('tags', tags);
    put('remark', remark);
    return map;
  }
}

class OrderApi {
  Future<void> createOrder(OacOrderCreateBody body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createOrder}');
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(json: true),
        body: jsonEncode(body.toJson()),
      );
      _ensureOk(response, fallback: '创建订单失败');
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw OrderApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is OrderApiException) rethrow;
      throw OrderApiException('网络请求失败：$e');
    }
  }

  /// 更新订单：`PUT /desktop/oac/order`。
  Future<void> updateOrder(OacOrderCreateBody body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateOrder}');
    try {
      final response = await ApiHttp.put(
        uri,
        headers: AuthSession.headers(json: true),
        body: jsonEncode(body.toJson()),
      );
      _ensureOk(response, fallback: '更新订单失败');
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw OrderApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is OrderApiException) rethrow;
      throw OrderApiException('网络请求失败：$e');
    }
  }

  /// 更新订单关联 4A。`agencyCustomerId` 为空字符串或 null 时清空关联。
  Future<void> updateOrderAgency({
    required String id,
    String? agencyCustomerId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateOrderAgency}');
    final agency = agencyCustomerId?.trim() ?? '';
    try {
      final response = await ApiHttp.put(
        uri,
        headers: AuthSession.headers(json: true),
        body: jsonEncode({
          'id': id.trim(),
          'agencyCustomerId': agency,
          'agencyId': agency,
        }),
      );
      _ensureOk(response, fallback: '更新关联 4A 失败');
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw OrderApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is OrderApiException) rethrow;
      throw OrderApiException('网络请求失败：$e');
    }
  }

  void _ensureOk(http.Response response, {required String fallback}) {
    if (response.body.isEmpty) {
      throw OrderApiException('服务器返回为空');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OrderApiException('服务器返回数据格式错误');
    }
    if (response.statusCode == 401) {
      throw OrderApiException(decoded['msg']?.toString() ?? '未登录或登录已过期');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OrderApiException(
        decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
      );
    }
    final code = decoded['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw OrderApiException(decoded['msg']?.toString() ?? fallback);
    }
  }
}
