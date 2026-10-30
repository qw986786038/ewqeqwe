import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/srm_purchase_order.dart';
import 'api_http.dart';
import 'auth_session.dart';

class SrmPurchaseOrderApiException implements Exception {
  SrmPurchaseOrderApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SrmPurchaseOrderQuery {
  String? id;
  String? keyword;
  String? brandName;
  int? supplierId;
  String? contractType;
  String? status;
  int? excludeSupplierId;
  bool? unboundOnly;
  num? orderAmountMin;
  num? orderAmountMax;
  String? orderTimeBegin;
  String? orderTimeEnd;
  int pageNum;
  int pageSize;
  String? orderByColumn;
  String? isAsc;

  SrmPurchaseOrderQuery({
    this.id,
    this.keyword,
    this.brandName,
    this.supplierId,
    this.contractType,
    this.status,
    this.excludeSupplierId,
    this.unboundOnly,
    this.orderAmountMin,
    this.orderAmountMax,
    this.orderTimeBegin,
    this.orderTimeEnd,
    this.pageNum = 1,
    this.pageSize = 10,
    this.orderByColumn,
    this.isAsc,
  });

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) map[key] = v;
    }

    put('id', id);
    put('keyword', keyword);
    put('brandName', brandName);
    put('contractType', contractType);
    put('status', status);
    put('orderTimeBegin', orderTimeBegin);
    put('orderTimeEnd', orderTimeEnd);
    put('orderByColumn', orderByColumn);
    put('isAsc', isAsc);
    if (supplierId != null) map['supplierId'] = '$supplierId';
    if (excludeSupplierId != null) {
      map['excludeSupplierId'] = '$excludeSupplierId';
    }
    if (unboundOnly != null) map['unboundOnly'] = '$unboundOnly';
    if (orderAmountMin != null) map['orderAmountMin'] = '$orderAmountMin';
    if (orderAmountMax != null) map['orderAmountMax'] = '$orderAmountMax';
    map['pageNum'] = '$pageNum';
    map['pageSize'] = '$pageSize';
    return map;
  }
}

class SrmPurchaseOrderListPage {
  SrmPurchaseOrderListPage({required this.total, required this.rows});

  final int total;
  final List<SrmPurchaseOrder> rows;
}

class SrmPurchaseOrderApi {
  Future<SrmPurchaseOrderKpi> fetchKpi([SrmPurchaseOrderQuery? query]) async {
    final q = query ?? SrmPurchaseOrderQuery(pageNum: 1, pageSize: 1);
    final params = q.toQueryParameters()
      ..remove('pageNum')
      ..remove('pageSize')
      ..remove('orderByColumn')
      ..remove('isAsc');
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderKpi}')
        .replace(queryParameters: params.isEmpty ? null : params);
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmPurchaseOrderApiException(
        body['msg']?.toString() ?? '采购订单统计加载失败',
      );
    }
    final data = body['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return SrmPurchaseOrderKpi()
      ..orderCount = _asInt(map['orderCount']) ?? 0
      ..propertyLeaseCount = _asInt(map['propertyLeaseCount']) ?? 0
      ..mediaPurchaseCount = _asInt(map['mediaPurchaseCount']) ?? 0;
  }

  Future<SrmPurchaseOrderListPage> fetchList([
    SrmPurchaseOrderQuery? query,
  ]) async {
    final q = query ?? SrmPurchaseOrderQuery();
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderList}')
            .replace(queryParameters: q.toQueryParameters());
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmPurchaseOrderApiException(
        body['msg']?.toString() ?? '采购订单列表加载失败',
      );
    }
    final rowsRaw = body['rows'];
    final rows = <SrmPurchaseOrder>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parseOrder(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SrmPurchaseOrderListPage(
      total: _asInt(body['total']) ?? rows.length,
      rows: rows,
    );
  }

  /// 导出勾选采购订单为 Excel。未传 [ids] 时服务端返回「请先勾选要导出的采购订单」。
  Future<({Uint8List bytes, String fileName})> export({
    required List<int> ids,
    String? keyword,
    String? brandName,
    String? status,
  }) async {
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请先勾选要导出的采购订单');
    }
    final params = <String, String>{
      'ids': ids.join(','),
    };
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) params[key] = v;
    }

    put('keyword', keyword);
    put('brandName', brandName);
    put('status', status);

    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderExport}')
            .replace(queryParameters: params);
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      return _parseExcelResponse(
        response,
        fallbackName: '采购订单导出.xls',
        failLabel: '导出',
      );
    } on SrmPurchaseOrderApiException {
      rethrow;
    } catch (e) {
      if (e is SrmPurchaseOrderApiException) rethrow;
      throw SrmPurchaseOrderApiException('网络请求失败：$e');
    }
  }

  /// 批量导入。`file` Excel；成功返回导入条数
  Future<int> importExcel({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw SrmPurchaseOrderApiException('请选择要导入的 Excel 文件');
    }
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderImport}');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.trim().isEmpty
              ? 'purchase_orders.xls'
              : fileName.trim(),
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 120),
      );
      if (response.body.isEmpty) {
        throw SrmPurchaseOrderApiException('服务器返回为');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw SrmPurchaseOrderApiException('服务器返回数据格式错');
      }
      final msg = decoded['msg']?.toString();
      if (response.statusCode == 401) {
        throw SrmPurchaseOrderApiException(msg ?? '未登录或登录已过期');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SrmPurchaseOrderApiException(
          msg ?? '导入失败(${response.statusCode})',
        );
      }
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw SrmPurchaseOrderApiException(msg ?? '导入失败');
      }
      return _asInt(decoded['data']) ?? 0;
    } on SrmPurchaseOrderApiException {
      rethrow;
    } on FormatException {
      throw SrmPurchaseOrderApiException('服务器返回数据格式错');
    } catch (e) {
      if (e is SrmPurchaseOrderApiException) rethrow;
      throw SrmPurchaseOrderApiException('网络请求失败：$e');
    }
  }

  /// 下载导入模板（Excel 文件流）。
  Future<({Uint8List bytes, String fileName})> downloadImportTemplate() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderImportTemplate}',
    );
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      return _parseExcelResponse(
        response,
        fallbackName: '采购订单导入模板.xls',
        failLabel: '下载模板',
      );
    } on SrmPurchaseOrderApiException {
      rethrow;
    } catch (e) {
      if (e is SrmPurchaseOrderApiException) rethrow;
      throw SrmPurchaseOrderApiException('网络请求失败：$e');
    }
  }

  static ({Uint8List bytes, String fileName}) _parseExcelResponse(
    http.Response response, {
    required String fallbackName,
    required String failLabel,
  }) {
    // Excel 为二进制，禁止用 response.body（会UTF-8 解码并抛 FormatException）
    final bytes = response.bodyBytes;
    final contentType = response.headers['content-type'] ?? '';
    final looksJson = contentType.contains('json') || _bytesLookLikeJson(bytes);
    if (looksJson) {
      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(utf8.decode(bytes));
        if (raw is Map<String, dynamic>) decoded = raw;
      } catch (_) {}
      final msg = decoded?['msg']?.toString();
      if (response.statusCode == 401) {
        throw SrmPurchaseOrderApiException(msg ?? '未登录或登录已过期');
      }
      throw SrmPurchaseOrderApiException(
        msg ?? '$failLabel失败(${response.statusCode})',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SrmPurchaseOrderApiException(
        '$failLabel失败(${response.statusCode})',
      );
    }
    if (bytes.isEmpty) {
      throw SrmPurchaseOrderApiException('$failLabel文件为空');
    }
    return (
      bytes: bytes,
      fileName: _fileNameFromDisposition(
            response.headers['content-disposition'],
          ) ??
          fallbackName,
    );
  }

  /// 不解码全文，仅看首个非空白字节是否为 `{` / `[`
  static bool _bytesLookLikeJson(Uint8List bytes) {
    for (final b in bytes) {
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) continue;
      return b == 0x7B || b == 0x5B;
    }
    return false;
  }

  static String? _fileNameFromDisposition(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final utf8 = RegExp(
      r"filename\*\s*=\s*UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(raw);
    if (utf8 != null) {
      try {
        return Uri.decodeComponent(utf8.group(1)!.trim());
      } catch (_) {
        return utf8.group(1)!.trim();
      }
    }
    final plain = RegExp(
      r'filename\s*=\s*"?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(raw);
    final name = plain?.group(1)?.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  /// 详情。
  Future<SrmPurchaseOrder> fetchDetail(String id) async {
    final sid = id.trim();
    if (sid.isEmpty) {
      throw SrmPurchaseOrderApiException('采购订单 ID 无效');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderDetail(sid)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmPurchaseOrderApiException(
        body['msg']?.toString() ?? '采购订单详情加载失败',
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw SrmPurchaseOrderApiException('采购订单详情为空');
    }
    return _parseOrder(Map<String, dynamic>.from(data));
  }

  /// 新建采购订单，返回新主键（若有）
  Future<String?> create(Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrder}');
    final resp = await _sendJson('POST', uri, body);
    final data = resp['data'];
    if (data is Map) return _asString(data['id']);
    return _asString(data);
  }

  /// 更新采购订单（[body] 须含 id）
  Future<void> update(Map<String, dynamic> body) async {
    final id = _asString(body['id']);
    if (id == null) {
      throw SrmPurchaseOrderApiException('更新时主键 id 必传');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrder}');
    await _sendJson('PUT', uri, body);
  }

  /// 删除采购订单（ids 逗号分隔）
  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请选择要删除的采购订单');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderDelete(ids.join(','))}',
    );
    try {
      final response = await ApiHttp.delete(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 30),
      );
      final map = _decodeJsonMap(response);
      final code = map['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw SrmPurchaseOrderApiException(map['msg']?.toString() ?? '删除失败');
      }
    } on SrmPurchaseOrderApiException {
      rethrow;
    } catch (e) {
      if (e is SrmPurchaseOrderApiException) rethrow;
      throw SrmPurchaseOrderApiException('网络请求失败：$e');
    }
  }

  /// 关联供应商
  Future<void> bindSupplier({
    required int supplierId,
    required List<int> ids,
    String? supplierFullName,
  }) async {
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请选择要关联的采购订单');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderBindSupplier}',
    );
    final body = <String, dynamic>{
      'supplierId': supplierId,
      'ids': ids,
      if (supplierFullName != null && supplierFullName.trim().isNotEmpty)
        'supplierFullName': supplierFullName.trim(),
    };
    await _sendJson('PUT', uri, body);
  }

  /// 解除供应商关联。
  Future<void> unbindSupplier({
    required int supplierId,
    required List<int> ids,
  }) async {
    if (ids.isEmpty) {
      throw SrmPurchaseOrderApiException('请选择要解除关联的采购订单');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.srmPurchaseOrderUnbindSupplier}',
    );
    await _sendJson('PUT', uri, {
      'supplierId': supplierId,
      'ids': ids,
    });
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = {
        ...AuthSession.headers(),
        'Content-Type': 'application/json; charset=utf-8',
      };
      final encoded = jsonEncode(body);
      late http.Response response;
      if (method == 'PUT') {
        response = await ApiHttp.put(
            uri,
            headers: headers,
            body: encoded,
            timeout: const Duration(seconds: 30),
          );
      } else {
        response = await ApiHttp.post(
            uri,
            headers: headers,
            body: encoded,
            timeout: const Duration(seconds: 30),
          );
      }
      final map = _decodeJsonMap(response);
      final code = map['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw SrmPurchaseOrderApiException(map['msg']?.toString() ?? '操作失败');
      }
      return map;
    } on SrmPurchaseOrderApiException {
      rethrow;
    } catch (e) {
      if (e is SrmPurchaseOrderApiException) rethrow;
      throw SrmPurchaseOrderApiException('网络请求失败：$e');
    }
  }

  Map<String, dynamic> _decodeJsonMap(http.Response response) {
    if (response.body.isEmpty) {
      throw SrmPurchaseOrderApiException('服务器返回为');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SrmPurchaseOrderApiException('服务器返回数据格式错');
    }
    if (response.statusCode == 401) {
      throw SrmPurchaseOrderApiException(
        decoded['msg']?.toString() ?? '未登录或登录已过期',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SrmPurchaseOrderApiException(
        decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );
      return _decodeJsonMap(response);
    } on SrmPurchaseOrderApiException {
      rethrow;
    } on FormatException {
      throw SrmPurchaseOrderApiException('服务器返回数据格式错');
    } catch (e) {
      if (e is SrmPurchaseOrderApiException) rethrow;
      throw SrmPurchaseOrderApiException('网络请求失败：$e');
    }
  }
}

SrmPurchaseOrder _parseOrder(Map<String, dynamic> json) {
  return SrmPurchaseOrder()
    ..id = _asString(json['id'])
    ..orderNo = _asString(json['orderNo'])
    ..orderName = _asString(json['orderName'])
    ..orderTag = _asString(json['orderTag'])
    ..brandName = _asString(json['brandName'])
    ..supplierId = _asString(json['supplierId'])
    ..supplierFullName = _asString(json['supplierFullName'])
    ..contractType = _asString(json['contractType'])
    ..orderAmount = _asNum(json['orderAmount'])
    ..orderTime = _asString(json['orderTime'])
    ..settlementMethod = _asString(json['settlementMethod'])
    ..invoiceType = _asString(json['invoiceType'])
    ..taxRate = _asString(json['taxRate'])
    ..city = _asString(json['city'])
    ..contactName = _asString(json['contactName'])
    ..staffName = _asString(json['staffName'])
    ..supplyCategory = _asString(json['supplyCategory'])
    ..status = _asString(json['status'])
    ..remark = _asString(json['remark'])
    ..createTime = _asString(json['createTime']);
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}
