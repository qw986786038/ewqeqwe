import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/srm_supplier.dart';
import 'api_http.dart';
import 'auth_session.dart';

class SrmSupplierApiException implements Exception {
  SrmSupplierApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SrmSupplierQuery {
  String? keyword;
  String? searchKeyword;
  String? supplierType;
  String? supplyCategory;
  String? enterpriseNature;
  String? invoiceType;
  String? taxRate;
  String? province;
  String? city;
  String? district;
  String? regionName;
  String? blacklistStatus;
  String? status;
  String? cooperationMode;
  String? settlementMethod;
  int? teamSizeMin;
  int? teamSizeMax;
  String? addressKeyword;
  String? contactKeyword;
  String? staffKeyword;
  int pageNum;
  int pageSize;
  String? orderByColumn;
  String? isAsc;

  SrmSupplierQuery({
    this.keyword,
    this.searchKeyword,
    this.supplierType,
    this.supplyCategory,
    this.enterpriseNature,
    this.invoiceType,
    this.taxRate,
    this.province,
    this.city,
    this.district,
    this.regionName,
    this.blacklistStatus,
    this.status,
    this.cooperationMode,
    this.settlementMethod,
    this.teamSizeMin,
    this.teamSizeMax,
    this.addressKeyword,
    this.contactKeyword,
    this.staffKeyword,
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

    put('keyword', keyword);
    put('searchKeyword', searchKeyword);
    put('supplierType', supplierType);
    put('supplyCategory', supplyCategory);
    put('enterpriseNature', enterpriseNature);
    put('invoiceType', invoiceType);
    put('taxRate', taxRate);
    put('province', province);
    put('city', city);
    put('district', district);
    put('regionName', regionName);
    put('blacklistStatus', blacklistStatus);
    put('status', status);
    put('cooperationMode', cooperationMode);
    put('settlementMethod', settlementMethod);
    put('addressKeyword', addressKeyword);
    put('contactKeyword', contactKeyword);
    put('staffKeyword', staffKeyword);
    put('orderByColumn', orderByColumn);
    put('isAsc', isAsc);
    if (teamSizeMin != null) map['teamSizeMin'] = '$teamSizeMin';
    if (teamSizeMax != null) map['teamSizeMax'] = '$teamSizeMax';
    map['pageNum'] = '$pageNum';
    map['pageSize'] = '$pageSize';
    return map;
  }
}

class SrmSupplierListPage {
  SrmSupplierListPage({required this.total, required this.rows});

  final int total;
  final List<SrmSupplier> rows;
}

class SrmSupplierApi {
  Future<SrmSupplierKpi> fetchStats() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplierStats}');
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmSupplierApiException(body['msg']?.toString() ?? '供应商统计加载失');
    }
    final data = body['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return SrmSupplierKpi()
      ..total = _asInt(map['total']) ?? 0
      ..propertyLeaseCount = _asInt(map['propertyLeaseCount']) ?? 0
      ..mediaPurchaseCount = _asInt(map['mediaPurchaseCount']) ?? 0
      ..blacklistCount = _asInt(map['blacklistCount']) ?? 0;
  }

  Future<SrmSupplierListPage> fetchList([SrmSupplierQuery? query]) async {
    final q = query ?? SrmSupplierQuery();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplierList}')
        .replace(queryParameters: q.toQueryParameters());
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmSupplierApiException(body['msg']?.toString() ?? '供应商列表加载失');
    }
    final rowsRaw = body['rows'];
    final rows = <SrmSupplier>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parseSupplier(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SrmSupplierListPage(
      total: _asInt(body['total']) ?? rows.length,
      rows: rows,
    );
  }

  /// 详情（主+ 银行/开联系对接品类子表）。
  Future<SrmSupplier> fetchDetail(String id) async {
    final sid = id.trim();
    if (sid.isEmpty) {
      throw SrmSupplierApiException('供应ID 无效');
    }
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplierDetail(sid)}');
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmSupplierApiException(body['msg']?.toString() ?? '供应商详情加载失');
    }
    final data = body['data'];
    if (data is! Map) {
      throw SrmSupplierApiException('供应商详情为');
    }
    return _parseSupplier(Map<String, dynamic>.from(data), withChildren: true);
  }

  /// 导出勾选供应商Excel。未传 [ids] 时服务端返回「请先勾选要导出的供应商」。
  Future<({Uint8List bytes, String fileName})> export({
    required List<int> ids,
    String? keyword,
    String? supplierType,
    String? status,
  }) async {
    if (ids.isEmpty) {
      throw SrmSupplierApiException('请先勾选要导出的供应商');
    }
    final params = <String, String>{
      'ids': ids.join(','),
    };
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) params[key] = v;
    }

    put('keyword', keyword);
    put('supplierType', supplierType);
    put('status', status);

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplierExport}')
        .replace(queryParameters: params);
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      return _parseExcelResponse(
        response,
        fallbackName: '供应商导xls',
        failLabel: '导出',
      );
    } on SrmSupplierApiException {
      rethrow;
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
    }
  }

  /// 批量导入建档。`file` Excel；成功返回导入条数
  Future<int> importExcel({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw SrmSupplierApiException('请选择要导入的 Excel 文件');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplierImport}');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.trim().isEmpty ? 'suppliers.xls' : fileName.trim(),
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 120),
      );
      if (response.body.isEmpty) {
        throw SrmSupplierApiException('服务器返回为');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw SrmSupplierApiException('服务器返回数据格式错');
      }
      final msg = decoded['msg']?.toString();
      if (response.statusCode == 401) {
        throw SrmSupplierApiException(msg ?? '未登录或登录已过期');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SrmSupplierApiException(msg ?? '导入失败(${response.statusCode})');
      }
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw SrmSupplierApiException(msg ?? '导入失败');
      }
      return _asInt(decoded['data']) ?? 0;
    } on SrmSupplierApiException {
      rethrow;
    } on FormatException {
      throw SrmSupplierApiException('服务器返回数据格式错');
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
    }
  }

  /// 营业执照 OCR（multipart `file`）。
  Future<SrmBusinessLicenseOcrResult> ocrBusinessLicense({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw SrmSupplierApiException('请选择营业执照图片');
    }
    // jpg 的标准类型是 image/jpeg，和扩展名 jpg 对不上时服务端会报「图片类型不匹配」。
    // 先转成 png 再上传，类型与扩展名一致。
    final upload = await _ocrImageFile(bytes, fileName);
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.srmSupplierOcrBusinessLicense}',
    );
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          upload.bytes,
          filename: upload.fileName,
          contentType: upload.contentType,
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 60),
      );
      final body = _decodeJsonMap(response);
      final code = body['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw SrmSupplierApiException(
          body['msg']?.toString() ?? '营业执照识别失败',
        );
      }
      final data = body['data'];
      var map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final success = map['success'];
      if (success == false) {
        throw SrmSupplierApiException(
          map['message']?.toString() ??
              body['msg']?.toString() ??
              '营业执照识别失败',
        );
      }
      // 证照字段有时再包一层 data / result，或落在 kvData。
      final nested = map['data'] ?? map['result'] ?? map['ocrResult'];
      if (nested is Map &&
          map['companyName'] == null &&
          map['creditCode'] == null) {
        map = {...map, ...Map<String, dynamic>.from(nested)};
      }
      final kv = map['kvData'];
      if (kv is Map) {
        map = {...Map<String, dynamic>.from(kv), ...map};
      }
      return SrmBusinessLicenseOcrResult.fromJson(map);
    } on SrmSupplierApiException {
      rethrow;
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
    }
  }

  /// jpg/jpeg 转成 png 再传，避免扩展名 jpg 与 image/jpeg 被判成类型不匹配。
  static Future<
      ({Uint8List bytes, String fileName, http.MediaType contentType})>
      _ocrImageFile(Uint8List bytes, String fileName) async {
    final name = fileName.trim().isEmpty ? 'business_license.jpg' : fileName.trim();
    if (!_isJpeg(bytes, name)) {
      return (
        bytes: bytes,
        fileName: name,
        contentType: _imageContentType(name),
      );
    }
    final png = await _jpegToPng(bytes);
    final base = _fileBaseName(name);
    if (png == null) {
      return (
        bytes: bytes,
        fileName: '$base.jpeg',
        contentType: http.MediaType('image', 'jpeg'),
      );
    }
    return (
      bytes: png,
      fileName: '$base.png',
      contentType: http.MediaType('image', 'png'),
    );
  }

  static bool _isJpeg(Uint8List bytes, String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return true;
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  static String _fileBaseName(String name) {
    final slash = name.replaceAll('\\', '/');
    final file = slash.split('/').last;
    final dot = file.lastIndexOf('.');
    if (dot <= 0) return file;
    return file.substring(0, dot);
  }

  static http.MediaType _imageContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return http.MediaType('image', 'png');
    if (lower.endsWith('.webp')) return http.MediaType('image', 'webp');
    if (lower.endsWith('.bmp')) return http.MediaType('image', 'bmp');
    if (lower.endsWith('.gif')) return http.MediaType('image', 'gif');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return http.MediaType('image', 'jpeg');
    }
    return http.MediaType('application', 'octet-stream');
  }

  static Future<Uint8List?> _jpegToPng(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  /// 上传文件OSS，返回相对路径（用于 logo / 合同 / 执照附件）
  Future<String> uploadOssFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw SrmSupplierApiException('文件内容为空');
    }
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resourceOssUpload}');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.trim().isEmpty ? 'file.bin' : fileName.trim(),
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 60),
      );
      final body = _decodeJsonMap(response);
      final code = body['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw SrmSupplierApiException(body['msg']?.toString() ?? '文件上传失败');
      }
      final data = body['data'];
      final path = _pickOssPath(data);
      if (path == null || path.isEmpty) {
        throw SrmSupplierApiException('上传成功但未返回文件路径');
      }
      return path;
    } on SrmSupplierApiException {
      rethrow;
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
    }
  }

  /// 联行· 省列表。
  Future<List<SrmCnapsTreeNode>> fetchCnapsProvinces() async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmCnapsProvinces}');
    return _fetchCnapsNodes(uri);
  }

  /// 联行· 市列表。
  Future<List<SrmCnapsTreeNode>> fetchCnapsCities(String provinceName) async {
    final name = provinceName.trim();
    if (name.isEmpty) return const [];
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmCnapsCities}')
        .replace(queryParameters: {'provinceName': name});
    return _fetchCnapsNodes(uri);
  }

  /// 联行· 支行列表。
  Future<List<SrmCnapsTreeNode>> fetchCnapsBranches({
    required String provinceName,
    required String cityName,
    String? keyword,
    int limit = 100,
  }) async {
    final province = provinceName.trim();
    final city = cityName.trim();
    if (province.isEmpty || city.isEmpty) return const [];
    final params = <String, String>{
      'provinceName': province,
      'cityName': city,
      'limit': '$limit',
    };
    final kw = keyword?.trim();
    if (kw != null && kw.isNotEmpty) params['keyword'] = kw;
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmCnapsBranches}')
        .replace(queryParameters: params);
    return _fetchCnapsNodes(uri);
  }

  /// 联行· 关键词搜索支行。
  Future<List<SrmCnapsItem>> searchCnaps({
    String? keyword,
    int limit = 20,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    final kw = keyword?.trim();
    if (kw != null && kw.isNotEmpty) params['keyword'] = kw;
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmCnapsSearch}')
        .replace(queryParameters: params);
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmSupplierApiException(body['msg']?.toString() ?? '联行号搜索失');
    }
    final data = body['data'];
    if (data is! List) return const [];
    final out = <SrmCnapsItem>[];
    for (final item in data) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      out.add(
        SrmCnapsItem()
          ..id = _asString(m['id'])
          ..name = _asString(m['name'])
          ..bankCode = _asString(m['bankCode'])
          ..bankName = _asString(m['bankName'])
          ..bankId = _asString(m['bankId'])
          ..cityCode = _asString(m['cityCode'])
          ..cityName = _asString(m['cityName'])
          ..provinceName = _asString(m['provinceName'])
          ..provinceCode = _asString(m['provinceCode']),
      );
    }
    return out;
  }

  Future<List<SrmCnapsTreeNode>> _fetchCnapsNodes(Uri uri) async {
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw SrmSupplierApiException(body['msg']?.toString() ?? '联行号加载失');
    }
    final data = body['data'];
    if (data is! List) return const [];
    final out = <SrmCnapsTreeNode>[];
    for (final item in data) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      out.add(
        SrmCnapsTreeNode()
          ..value = _asString(m['value'])
          ..label = _asString(m['label'])
          ..leaf = m['leaf'] == true
          ..bankCode = _asString(m['bankCode']),
      );
    }
    return out;
  }

  /// 新建供应商（主表 + 子表），返回新主id
  Future<String> createSupplier(Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplier}');
    final resp = await _sendJson('POST', uri, body);
    final data = resp['data'];
    if (data is Map) {
      final id = _asString(data['id']);
      if (id != null) return id;
    }
    final id = _asString(data);
    if (id != null) return id;
    throw SrmSupplierApiException('创建成功但未返回主键');
  }

  /// 更新供应商（主表 + 子表全量替换）
  Future<void> updateSupplier(Map<String, dynamic> body) async {
    final id = _asString(body['id']);
    if (id == null) {
      throw SrmSupplierApiException('更新时主键 id 必传');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplier}');
    await _sendJson('PUT', uri, body);
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
        throw SrmSupplierApiException(map['msg']?.toString() ?? '操作失败');
      }
      return map;
    } on SrmSupplierApiException {
      rethrow;
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
    }
  }

  Map<String, dynamic> _decodeJsonMap(http.Response response) {
    if (response.body.isEmpty) {
      throw SrmSupplierApiException('服务器返回为');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SrmSupplierApiException('服务器返回数据格式错');
    }
    if (response.statusCode == 401) {
      throw SrmSupplierApiException(
        decoded['msg']?.toString() ?? '未登录或登录已过期',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SrmSupplierApiException(
        decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
      );
    }
    return decoded;
  }

  static String? _pickOssPath(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final s = data.trim();
      return s.isEmpty ? null : s;
    }
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    for (final key in [
      'fileName',
      'url',
      'ossId',
      'path',
      'filePath',
      'relativePath',
    ]) {
      final v = map[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// 下载导入模板（Excel 文件流）。
  Future<({Uint8List bytes, String fileName})> downloadImportTemplate() async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.srmSupplierImportTemplate}');
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      return _parseExcelResponse(
        response,
        fallbackName: '供应商导入模xls',
        failLabel: '下载模板',
      );
    } on SrmSupplierApiException {
      rethrow;
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
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
        throw SrmSupplierApiException(msg ?? '未登录或登录已过期');
      }
      throw SrmSupplierApiException(
        msg ?? '$failLabel失败(${response.statusCode})',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SrmSupplierApiException('$failLabel失败(${response.statusCode})');
    }
    if (bytes.isEmpty) {
      throw SrmSupplierApiException('$failLabel文件为空');
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

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );
      if (response.body.isEmpty) {
        throw SrmSupplierApiException('服务器返回为');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw SrmSupplierApiException('服务器返回数据格式错');
      }
      if (response.statusCode == 401) {
        throw SrmSupplierApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SrmSupplierApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on SrmSupplierApiException {
      rethrow;
    } on FormatException {
      throw SrmSupplierApiException('服务器返回数据格式错');
    } catch (e) {
      if (e is SrmSupplierApiException) rethrow;
      throw SrmSupplierApiException('网络请求失败：$e');
    }
  }
}

SrmSupplier _parseSupplier(
  Map<String, dynamic> json, {
  bool withChildren = false,
}) {
  final s = SrmSupplier()
    ..id = _asString(json['id'])
    ..supplierCode = _asString(json['supplierCode'])
    ..weight = _asInt(json['weight'])
    ..shortName = _asString(json['shortName'])
    ..fullName = _asString(json['fullName'])
    ..supplierType = _asString(json['supplierType'])
    ..supplyCategoryText = _asString(json['supplyCategoryText']) ??
        _asString(json['categoryExportText'])
    ..enterpriseNature = _asString(json['enterpriseNature'])
    ..teamSize = _asInt(json['teamSize'])
    ..cooperationMode = _asString(json['cooperationMode'])
    ..settlementMethod = _asString(json['settlementMethod'])
    ..regionName = _asString(json['regionName'])
    ..city = _asString(json['city'])
    ..businessAddress = _asString(json['businessAddress'])
    ..contactInfoText = _asString(json['contactInfoText']) ??
        _asString(json['contactExportText'])
    ..staffInfoText =
        _asString(json['staffInfoText']) ?? _asString(json['staffExportText'])
    ..createTime = _asString(json['createTime'])
    ..latestDynamic = _asString(json['latestDynamic'])
    ..logoFile = _asString(json['logoFile'])
    ..blacklistStatus = _asString(json['blacklistStatus'])
    ..blacklistStatusText = _asString(json['blacklistStatusText'])
    ..status = _asString(json['status'])
    ..statusText = _asString(json['statusText'])
    ..entityFile = _asString(json['entityFile'])
    ..province = _asString(json['province'])
    ..district = _asString(json['district'])
    ..website = _asString(json['website'])
    ..creditCode = _asString(json['creditCode'])
    ..legalPerson = _asString(json['legalPerson'])
    ..registeredCapital = _asNum(json['registeredCapital'])
    ..establishDate = _asString(json['establishDate'])
    ..licenseValidStart = _asString(json['licenseValidStart'])
    ..licenseValidEnd = _asString(json['licenseValidEnd'])
    ..registeredAddress = _asString(json['registeredAddress'])
    ..businessScope = _asString(json['businessScope'])
    ..paymentTermDays = _asInt(json['paymentTermDays'])
    ..paymentCondition = _asString(json['paymentCondition'])
    ..rebatePolicy = _asString(json['rebatePolicy'])
    ..serviceArea = _asString(json['serviceArea'])
    ..invoiceType = _asString(json['invoiceType'])
    ..taxRate = _asString(json['taxRate'])
    ..deliveryCapacity = _asString(json['deliveryCapacity'])
    ..coreAdvantage = _asString(json['coreAdvantage'])
    ..remark = _asString(json['remark'])
    ..categoryExportText = _asString(json['categoryExportText'])
    ..bankExportText = _asString(json['bankExportText'])
    ..invoiceExportText = _asString(json['invoiceExportText'])
    ..contactExportText = _asString(json['contactExportText'])
    ..staffExportText = _asString(json['staffExportText'])
    ..abnormalRecord = _asString(json['abnormalRecord'])
    ..penaltyHistory = _asString(json['penaltyHistory'])
    ..licenseFile = _asString(json['licenseFile'])
    ..contractTemplate = _asString(json['contractTemplate'])
    ..invoiceTypeText = _asString(json['invoiceTypeText'])
    ..taxRateText = _asString(json['taxRateText']);

  if (withChildren) {
    s.bankList = _parseList(json['bankList'], _parseBank);
    s.invoiceList = _parseList(json['invoiceList'], _parseInvoice);
    s.contactList = _parseList(json['contactList'], _parseContact);
    s.staffList = _parseList(json['staffList'], _parseStaff);
    s.categoryList = _parseList(json['categoryList'], _parseCategory);
  }
  return s;
}

List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) parse,
) {
  if (raw is! List) return <T>[];
  final out = <T>[];
  for (final item in raw) {
    if (item is Map) {
      out.add(parse(Map<String, dynamic>.from(item)));
    }
  }
  return out;
}

SrmSupplierBank _parseBank(Map<String, dynamic> json) {
  return SrmSupplierBank()
    ..id = _asString(json['id'])
    ..supplierId = _asString(json['supplierId'])
    ..bankName = _asString(json['bankName'])
    ..bankAccount = _asString(json['bankAccount'])
    ..invoiceInfo = _asString(json['invoiceInfo'])
    ..sort = _asInt(json['sort'])
    ..remark = _asString(json['remark']);
}

SrmSupplierInvoice _parseInvoice(Map<String, dynamic> json) {
  return SrmSupplierInvoice()
    ..id = _asString(json['id'])
    ..supplierId = _asString(json['supplierId'])
    ..invoiceName = _asString(json['invoiceName'])
    ..taxNo = _asString(json['taxNo'])
    ..registerAddress = _asString(json['registerAddress'])
    ..registerPhone = _asString(json['registerPhone'])
    ..bankName = _asString(json['bankName'])
    ..bankAccount = _asString(json['bankAccount'])
    ..invoiceType = _asString(json['invoiceType'])
    ..taxRate = _asString(json['taxRate'])
    ..sort = _asInt(json['sort'])
    ..remark = _asString(json['remark']);
}

SrmSupplierContact _parseContact(Map<String, dynamic> json) {
  return SrmSupplierContact()
    ..id = _asString(json['id'])
    ..supplierId = _asString(json['supplierId'])
    ..name = _asString(json['name'])
    ..nameEn = _asString(json['nameEn'])
    ..gender = _asString(json['gender'])
    ..ageGroup = _asString(json['ageGroup'])
    ..deptPost = _asString(json['deptPost'])
    ..dutyDesc = _asString(json['dutyDesc'])
    ..mobile = _asString(json['mobile'])
    ..email = _asString(json['email'])
    ..sort = _asInt(json['sort'])
    ..remark = _asString(json['remark']);
}

SrmSupplierStaff _parseStaff(Map<String, dynamic> json) {
  return SrmSupplierStaff()
    ..id = _asString(json['id'])
    ..supplierId = _asString(json['supplierId'])
    ..userId = _asString(json['userId'])
    ..name = _asString(json['name'])
    ..nameEn = _asString(json['nameEn'])
    ..gender = _asString(json['gender'])
    ..deptPost = _asString(json['deptPost'])
    ..sort = _asInt(json['sort'])
    ..remark = _asString(json['remark']);
}

SrmSupplierCategory _parseCategory(Map<String, dynamic> json) {
  return SrmSupplierCategory()
    ..id = _asString(json['id'])
    ..supplierId = _asString(json['supplierId'])
    ..supplyCategory = _asString(json['supplyCategory'])
    ..itemType = _asString(json['itemType'])
    ..itemDesc = _asString(json['itemDesc'])
    ..sort = _asInt(json['sort'])
    ..remark = _asString(json['remark']);
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
