import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/customer_archive.dart';
import 'api_http.dart';
import 'auth_session.dart';

class CustomerApiException implements Exception {
  CustomerApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 客户档案列表筛选（仅填非空才会作为 Query 发出）。
class OacCustomerQuery {
  String? id;
  String? tenantId;
  String? customerCode;
  String? customerType;
  String? marketScale;
  String? name;
  String? iconUrl;
  String? industry;
  String? brandNature;
  String? revenueScale;
  String? marketingBudget;
  String? staffScale;
  String? spokesperson;
  String? serviceAgencyId;
  String? website;
  String? weight;
  String? latestDynamic;
  String? ownerNames;
  String? status;
  String? remark;
  String? keyword;
  int pageNum;
  int pageSize;
  String? orderByColumn;
  String? isAsc;

  OacCustomerQuery({
    this.id,
    this.tenantId,
    this.customerCode,
    this.customerType,
    this.marketScale,
    this.name,
    this.iconUrl,
    this.industry,
    this.brandNature,
    this.revenueScale,
    this.marketingBudget,
    this.staffScale,
    this.spokesperson,
    this.serviceAgencyId,
    this.website,
    this.weight,
    this.latestDynamic,
    this.ownerNames,
    this.status,
    this.remark,
    this.keyword,
    this.pageNum = 1,
    this.pageSize = 20,
    this.orderByColumn,
    this.isAsc,
  });

  Map<String, String> toQueryParameters({bool includePaging = true}) {
    final map = <String, String>{};
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) map[key] = v;
    }

    put('id', id);
    put('tenantId', tenantId);
    put('customerCode', customerCode);
    put('customerType', customerType);
    put('marketScale', marketScale);
    put('name', name);
    put('iconUrl', iconUrl);
    put('industry', industry);
    put('brandNature', brandNature);
    put('revenueScale', revenueScale);
    put('marketingBudget', marketingBudget);
    put('staffScale', staffScale);
    put('spokesperson', spokesperson);
    put('serviceAgencyId', serviceAgencyId);
    put('website', website);
    put('weight', weight);
    put('latestDynamic', latestDynamic);
    put('ownerNames', ownerNames);
    put('status', status);
    put('remark', remark);
    put('keyword', keyword);
    put('orderByColumn', orderByColumn);
    put('isAsc', isAsc);
    if (includePaging) {
      map['pageNum'] = '$pageNum';
      map['pageSize'] = '$pageSize';
    }
    return map;
  }
}

class OacCustomerListPage {
  OacCustomerListPage({required this.total, required this.rows});

  final int total;
  final List<CustomerArchive> rows;
}

class CustomerApi {
  Future<OacCustomerListPage> fetchList([OacCustomerQuery? query]) async {
    final q = query ?? OacCustomerQuery();
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerList}')
        .replace(queryParameters: q.toQueryParameters());

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '客户列表加载失败');
    }

    final rowsRaw = body['rows'];
    final rows = <CustomerArchive>[];
    if (rowsRaw is List) {
      for (final item in rowsRaw) {
        if (item is Map) {
          rows.add(_parseCustomer(Map<String, dynamic>.from(item)));
        }
      }
    }

    return OacCustomerListPage(
      total: _asInt(body['total']) ?? rows.length,
      rows: rows,
    );
  }

  /// 仅取 total（用于 KPI 卡片）。
  Future<int> fetchTotal(OacCustomerQuery query) async {
    final page = await fetchList(
      OacCustomerQuery(
        customerType: query.customerType,
        marketScale: query.marketScale,
        industry: query.industry,
        status: query.status,
        keyword: query.keyword,
        ownerNames: query.ownerNames,
        pageNum: 1,
        pageSize: 1,
      ),
    );
    return page.total;
  }

  /// KPI 概览：`GET /desktop/oac/customer/overview`（`OacCustomerOverviewVo`）。
  Future<CustomerArchiveStats> fetchOverview([OacCustomerQuery? query]) async {
    final params = _overviewParams(query);
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerOverview}')
        .replace(queryParameters: params);

    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '客户概览加载失败');
    }

    final data = body['data'];
    if (data is! Map) {
      return CustomerArchiveStats();
    }
    final map = Map<String, dynamic>.from(data);
    return CustomerArchiveStats()
      ..brandEnterprise = _asInt(map['brandCount']) ?? 0
      ..relatedEntityCount = _asInt(map['enterpriseTotalCount']) ?? 0
      ..publicSea = _asInt(map['publicSeaCount']) ?? 0
      ..privateSea = _asInt(map['privateSeaCount']) ?? 0
      ..pendingAssign = _asInt(map['pendingAssignCount']) ?? 0
      ..dataAsOf = _asString(map['dataAsOf']);
  }

  Map<String, String>? _overviewParams(OacCustomerQuery? query) {
    if (query == null) return null;
    final map = query.toQueryParameters();
    map.remove('orderByColumn');
    map.remove('isAsc');
    return map.isEmpty ? null : map;
  }

  /// 客户档案详情：`GET /desktop/oac/customer/{id}`。
  Future<Map<String, dynamic>> fetchCustomerDetail(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.customerDetail(id)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '客户详情加载失败');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw CustomerApiException('客户详情数据为空');
  }

  /// 联系人详情：`GET /desktop/oac/contact/{id}`。
  Future<Map<String, dynamic>> fetchContactDetail(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw CustomerApiException('缺少联系人 ID');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.contactDetail(trimmed)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '联系人详情加载失败');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw CustomerApiException('联系人详情数据为空');
  }

  /// 品牌名称联想：`GET /desktop/oac/brandLibrary/nameOptions?brandName=`。
  Future<List<Map<String, dynamic>>> fetchBrandLibraryNameOptions(
    String brandName,
  ) async {
    final q = brandName.trim();
    if (q.isEmpty) return const [];
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.brandLibraryNameOptions}',
    ).replace(queryParameters: {'brandName': q});
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '品牌联想加载失败');
    }
    final data = body['data'];
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// 品牌库详情（客户档案选中后回填）：`GET /desktop/oac/brandLibrary/nameOptions/{id}`。
  Future<Map<String, dynamic>> fetchBrandLibraryNameOptionDetail(
    String id,
  ) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw CustomerApiException('缺少品牌库 ID');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.brandLibraryNameOptionDetail(trimmed)}',
    );
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '品牌库详情加载失败');
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw CustomerApiException('品牌库详情数据为空');
  }

  /// 下载「导入联系人」模板：`POST /desktop/oac/customer/importContactTemplate`。
  Future<({Uint8List bytes, String fileName})> downloadContactImportTemplate() =>
      _downloadImportTemplate(
        path: ApiConfig.customerImportContactTemplate,
        fallbackName: '导入联系人模板.xls',
      );

  /// 解析联系人导入文件：`POST /desktop/oac/customer/importContact/preview`。
  ///
  /// 兼容 `data` 为列表，或 `contacts` / `list` / `rows`；
  /// 以及上级 / 下级独立数组（按主联系人姓名挂到对应联系人）。
  Future<List<Map<String, dynamic>>> previewContactImport({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final data = await _postImportPreview(
      path: ApiConfig.customerImportContactPreview,
      bytes: bytes,
      fileName: fileName,
      emptyFileMessage: '请选择要导入的联系人 Excel 文件',
      failLabel: '解析联系人导入文件',
    );
    return _parseContactImportPreview(data);
  }

  /// 确认导入联系人：`POST /desktop/oac/customer/importContact/confirm`。
  ///
  /// 请求体为顶层 `{ contacts, superiors, subordinates }`，
  /// 上级/下级通过 `contactName` 关联主联系人，不嵌套在 contacts 内。
  Future<void> confirmContactImport({
    required List<Map<String, dynamic>> contacts,
    List<Map<String, dynamic>> superiors = const [],
    List<Map<String, dynamic>> subordinates = const [],
  }) =>
      _postImportConfirm(
        path: ApiConfig.customerImportContactConfirm,
        body: {
          'contacts': contacts,
          'superiors': superiors,
          'subordinates': subordinates,
        },
        failLabel: '导入联系人',
      );

  /// 下载「导入经营主体」模板：`POST /desktop/oac/customer/importEnterpriseTemplate`。
  Future<({Uint8List bytes, String fileName})>
      downloadEnterpriseImportTemplate() => _downloadImportTemplate(
        path: ApiConfig.customerImportEnterpriseTemplate,
        fallbackName: '导入经营主体模板.xls',
      );

  /// 解析经营主体导入文件：`POST /desktop/oac/customer/importEnterprise/preview`。
  Future<List<Map<String, dynamic>>> previewEnterpriseImport({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final data = await _postImportPreview(
      path: ApiConfig.customerImportEnterprisePreview,
      bytes: bytes,
      fileName: fileName,
      emptyFileMessage: '请选择要导入的经营主体 Excel 文件',
      failLabel: '解析经营主体导入文件',
    );
    final list = _asMapList(data['enterprises']);
    if (list.isNotEmpty) return list;
    return _asMapList(data['items'] ?? data['list'] ?? data['rows']);
  }

  /// 确认导入经营主体：`POST /desktop/oac/customer/importEnterprise/confirm`。
  Future<void> confirmEnterpriseImport(
    List<Map<String, dynamic>> enterprises,
  ) =>
      _postImportConfirm(
        path: ApiConfig.customerImportEnterpriseConfirm,
        body: {'enterprises': enterprises},
        failLabel: '导入经营主体',
      );

  Future<({Uint8List bytes, String fileName})> _downloadImportTemplate({
    required String path,
    required String fallbackName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      return _parseExcelResponse(
        response,
        fallbackName: fallbackName,
        failLabel: '下载模板',
      );
    } on CustomerApiException {
      rethrow;
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  Future<Map<String, dynamic>> _postImportPreview({
    required String path,
    required Uint8List bytes,
    required String fileName,
    required String emptyFileMessage,
    required String failLabel,
  }) async {
    if (bytes.isEmpty) {
      throw CustomerApiException(emptyFileMessage);
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.trim().isEmpty ? 'import.xls' : fileName.trim(),
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 120),
      );
      final body = _decodeJsonBody(response);
      final code = body['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw CustomerApiException(body['msg']?.toString() ?? '$failLabel失败');
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      // 部分接口直接返回列表。
      if (data is List) return <String, dynamic>{'items': data};
      return <String, dynamic>{};
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  /// 联系人导入预览：归一化字段名，并把独立上级/下级 sheet 挂回主联系人。
  static List<Map<String, dynamic>> _parseContactImportPreview(
    Map<String, dynamic> data,
  ) {
    var contacts = _asMapList(data['contacts']);
    if (contacts.isEmpty) {
      contacts = _asMapList(
        data['items'] ?? data['list'] ?? data['rows'] ?? data['records'],
      );
    }
    final topSuperiors = _asMapList(
      data['superiors'] ??
          data['superiorList'] ??
          data['superiorContacts'] ??
          data['contactSuperiors'],
    );
    final topSubordinates = _asMapList(
      data['subordinates'] ??
          data['subordinateList'] ??
          data['subordinateContacts'] ??
          data['contactSubordinates'],
    );

    return [
      for (final raw in contacts) _normalizeContactImportRow(
        raw,
        topSuperiors: topSuperiors,
        topSubordinates: topSubordinates,
      ),
    ];
  }

  static Map<String, dynamic> _normalizeContactImportRow(
    Map<String, dynamic> raw, {
    List<Map<String, dynamic>> topSuperiors = const [],
    List<Map<String, dynamic>> topSubordinates = const [],
  }) {
    final out = Map<String, dynamic>.from(raw);

    String? pick(List<String> keys) {
      for (final key in keys) {
        if (!raw.containsKey(key) && !out.containsKey(key)) continue;
        final v = raw[key] ?? out[key];
        final text = _importCellText(v);
        if (text != null) return text;
      }
      return null;
    }

    void fill(String key, List<String> aliases) {
      final current = _importCellText(out[key]);
      if (current != null) {
        out[key] = current;
        return;
      }
      final v = pick(aliases);
      if (v != null) out[key] = v;
    }

    fill('name', const ['name', 'nameZh', 'contactName', '姓名']);
    fill('nameEn', const ['nameEn', 'englishName', 'Name', '英文名']);
    fill('gender', const ['gender', 'sex', 'genderLabel', '性别']);
    fill('ageDesc', const ['ageDesc', 'age', '年龄段', '年龄']);
    fill('relatedEnterprise', const [
      'relatedEnterprise',
      'enterpriseName',
      'enterpriseFullName',
      'orgName',
      'companyName',
      '关联企业',
    ]);
    fill('city', const ['city', '所在城市', '城市']);
    fill('address', const ['address', 'detailAddress', '详细地址', '住址']);
    fill('deptTitle', const [
      'deptTitle',
      'title',
      'position',
      '部门/职位',
      '职位',
      '职务',
    ]);
    fill('jobDesc', const ['jobDesc', 'job', 'role', '职能描述', '职能']);
    fill('marketScope', const [
      'marketScope',
      'responsibleMarket',
      '负责市场范围',
      '市场范围',
    ]);
    fill('responsibleBrands', const [
      'responsibleBrands',
      'brands',
      'brandNames',
      '负责品牌',
    ]);
    fill('tenure', const ['tenure', '在职时间']);
    fill('phones', const [
      'phones',
      'phone',
      'mobile',
      'mobilePhone',
      'phoneNumber',
      '手机号',
      '手机',
    ]);
    fill('tel', const [
      'tel',
      'telephone',
      'landline',
      'fixedPhone',
      '电话',
      '座机',
      '固话',
    ]);
    fill('emails', const ['emails', 'email', 'mail', '邮箱', '电子邮箱']);
    fill('remark', const ['remark', 'remarks', '备注']);

    var superiors = _asMapList(
      raw['superiors'] ??
          raw['superiorList'] ??
          raw['superiorContacts'] ??
          raw['contactSuperiors'],
    );
    var subordinates = _asMapList(
      raw['subordinates'] ??
          raw['subordinateList'] ??
          raw['subordinateContacts'] ??
          raw['contactSubordinates'],
    );

    final selfName = _importCellText(out['name']) ?? '';
    if (superiors.isEmpty && topSuperiors.isNotEmpty && selfName.isNotEmpty) {
      superiors = [
        for (final s in topSuperiors)
          if ((_importCellText(s['contactName']) ??
                  _importCellText(s['mainContactName']) ??
                  _importCellText(s['ownerName']) ??
                  '') ==
              selfName)
            s,
      ];
    }
    if (subordinates.isEmpty &&
        topSubordinates.isNotEmpty &&
        selfName.isNotEmpty) {
      subordinates = [
        for (final s in topSubordinates)
          if ((_importCellText(s['contactName']) ??
                  _importCellText(s['mainContactName']) ??
                  _importCellText(s['ownerName']) ??
                  '') ==
              selfName)
            s,
      ];
    }

    out['superiors'] = [
      for (final s in superiors) _normalizeContactRelationRow(s),
    ];
    out['subordinates'] = [
      for (final s in subordinates) _normalizeContactRelationRow(s),
    ];
    return out;
  }

  static Map<String, dynamic> _normalizeContactRelationRow(
    Map<String, dynamic> raw,
  ) {
    final out = Map<String, dynamic>.from(raw);
    String? pick(List<String> keys) {
      for (final key in keys) {
        final text = _importCellText(raw[key] ?? out[key]);
        if (text != null) return text;
      }
      return null;
    }

    void fill(String key, List<String> aliases) {
      final current = _importCellText(out[key]);
      if (current != null) {
        out[key] = current;
        return;
      }
      final v = pick(aliases);
      if (v != null) out[key] = v;
    }

    fill('contactName', const [
      'contactName',
      'mainContactName',
      'ownerName',
      '主联系人姓名',
      '主联系人',
    ]);
    fill('name', const ['name', 'nameZh', '姓名']);
    fill('nameEn', const ['nameEn', 'englishName', 'Name', '英文名']);
    fill('gender', const ['gender', 'sex', 'genderLabel', '性别']);
    fill('ageDesc', const ['ageDesc', 'age', '年龄段', '年龄']);
    fill('relatedEnterprise', const [
      'relatedEnterprise',
      'enterpriseName',
      'orgName',
      'companyName',
      '关联企业',
    ]);
    fill('city', const ['city', '所在城市', '城市']);
    fill('address', const ['address', 'detailAddress', '详细地址']);
    fill('deptTitle', const ['deptTitle', 'title', 'position', '部门/职位', '职位']);
    fill('jobDesc', const ['jobDesc', 'job', 'role', '职能描述']);
    fill('marketScope', const ['marketScope', '负责市场范围', '市场范围']);
    fill('responsibleBrands', const ['responsibleBrands', 'brands', '负责品牌']);
    fill('tenure', const ['tenure', '在职时间']);
    fill('phones', const ['phones', 'phone', 'mobile', '手机号', '手机']);
    fill('tel', const ['tel', 'telephone', '电话', '座机']);
    fill('emails', const ['emails', 'email', '邮箱']);
    fill('remark', const ['remark', 'remarks', '备注']);
    return out;
  }

  static String? _importCellText(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }
    if (raw is num || raw is bool) return raw.toString();
    if (raw is Iterable) {
      final parts = <String>[
        for (final e in raw)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
      if (parts.isEmpty) return null;
      return parts.join(',');
    }
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _postImportConfirm({
    required String path,
    required Map<String, dynamic> body,
    required String failLabel,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    try {
      final response = await ApiHttp.post(
        uri,
        headers: {
          ...AuthSession.headers(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
        timeout: const Duration(seconds: 120),
      );
      final decoded = _decodeJsonBody(response);
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '$failLabel失败',
        );
      }
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  Map<String, dynamic> _decodeJsonBody(http.Response response) {
    if (response.body.isEmpty) {
      throw CustomerApiException('服务器返回为空');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw CustomerApiException('服务器返回数据格式错误');
    }
    if (response.statusCode == 401) {
      throw CustomerApiException(
        decoded['msg']?.toString() ?? '未登录或登录已过期',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerApiException(
        decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
      );
    }
    return decoded;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// 导出客户档案 Excel：`POST /desktop/oac/customer/export`。
  /// [exportColumns] 为当前可见数据列字段名（逗号分隔）；序号由服务端固定导出。
  Future<({Uint8List bytes, String fileName})> export({
    OacCustomerQuery? query,
    required String exportColumns,
  }) async {
    final cols = exportColumns.trim();
    if (cols.isEmpty) {
      throw CustomerApiException('没有可导出的列，请先在列设置中勾选');
    }
    final params = (query ?? OacCustomerQuery()).toQueryParameters(
      includePaging: false,
    );
    params['exportColumns'] = cols;
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerExport}')
        .replace(queryParameters: params);
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 60),
      );
      return _parseExcelResponse(
        response,
        fallbackName: '客户档案导出.xls',
        failLabel: '导出',
      );
    } on CustomerApiException {
      rethrow;
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  static ({Uint8List bytes, String fileName}) _parseExcelResponse(
    http.Response response, {
    required String fallbackName,
    required String failLabel,
  }) {
    // Excel 为二进制，禁止用 response.body（会按 UTF-8 解码并抛 FormatException）。
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
        throw CustomerApiException(msg ?? '未登录或登录已过期');
      }
      throw CustomerApiException(
        msg ?? '$failLabel失败(${response.statusCode})',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerApiException('$failLabel失败(${response.statusCode})');
    }
    if (bytes.isEmpty) {
      throw CustomerApiException('$failLabel文件为空');
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

  /// 阿里云统一识别 RecognizeAllText：`POST /desktop/oac/ocr/allText/upload`。
  /// [type] 默认 `Advanced`，也可 `IdCard`、`BankCard` 等。
  Future<OacGeneralOcrResult> ocrAllTextUpload({
    required Uint8List bytes,
    required String fileName,
    String type = 'Advanced',
  }) async {
    if (bytes.isEmpty) {
      throw CustomerApiException('请选择要识别的图片');
    }
    final t = type.trim().isEmpty ? 'Advanced' : type.trim();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.oacOcrAllTextUpload}',
    ).replace(queryParameters: {'type': t});
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename:
              fileName.trim().isEmpty ? 'contact_ocr.jpg' : fileName.trim(),
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 90),
      );
      if (response.body.isEmpty) {
        throw CustomerApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CustomerApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '图片文字识别失败',
        );
      }
      final data = decoded['data'];
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      if (map['success'] == false) {
        throw CustomerApiException(
          map['message']?.toString() ??
              decoded['msg']?.toString() ??
              '图片文字识别失败',
        );
      }
      return OacGeneralOcrResult.fromJson(map);
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  /// 开户许可证 / 基本存款账户 OCR：`POST /desktop/oac/ocr/bankAccountLicense/upload`。
  Future<OacBankAccountLicenseOcrResult> ocrBankAccountLicense({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw CustomerApiException('请选择开户许可证或基本存款账户信息图片');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.oacOcrBankAccountLicense}',
    );
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthSession.headers());
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.trim().isEmpty
              ? 'bank_account_license.jpg'
              : fileName.trim(),
        ),
      );
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 60),
      );
      if (response.body.isEmpty) {
        throw CustomerApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CustomerApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '开户许可证识别失败',
        );
      }
      final data = decoded['data'];
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      if (map['success'] == false) {
        throw CustomerApiException(
          map['message']?.toString() ??
              decoded['msg']?.toString() ??
              '开户许可证识别失败',
        );
      }
      return OacBankAccountLicenseOcrResult.fromJson(map);
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  /// 营业执照 OCR：`GET /desktop/oac/ocr/businessLicense?url=`（公网图片 URL）。
  Future<OacBusinessLicenseOcrResult> ocrBusinessLicenseByUrl({
    required String imageUrl,
  }) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      throw CustomerApiException('请先上传营业执照图片');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.oacOcrBusinessLicense}',
    ).replace(queryParameters: {'url': url});
    final body = await _getJson(uri);
    final biz = body['code'];
    final ok = biz == null || biz == 200 || biz == 0 || biz == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '营业执照识别失败');
    }
    final data = body['data'];
    var map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    if (map['success'] == false) {
      throw CustomerApiException(
        map['message']?.toString() ??
            body['msg']?.toString() ??
            '营业执照识别失败',
      );
    }
    // 部分实现把证照字段再包一层 data / result。
    final nested = map['data'] ?? map['result'] ?? map['ocrResult'];
    if (nested is Map &&
        (map['companyName'] == null && map['creditCode'] == null)) {
      map = {
        ...map,
        ...Map<String, dynamic>.from(nested),
      };
    }
    return OacBusinessLicenseOcrResult.fromJson(map);
  }

  /// 上传文件到 OSS，返回路径 / URL（供营业执照 OCR 等使用）。
  Future<String> uploadOssFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) {
      throw CustomerApiException('文件内容为空');
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
      if (response.body.isEmpty) {
        throw CustomerApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CustomerApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '文件上传失败',
        );
      }
      final path = _pickOssPath(decoded['data']);
      if (path == null || path.isEmpty) {
        throw CustomerApiException('上传成功但未返回文件路径');
      }
      return path;
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
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
      'url',
      'fileName',
      'ossId',
      'path',
      'filePath',
      'relativePath',
      'publicUrl',
    ]) {
      final v = map[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// 企业模糊搜索：`GET /desktop/oac/ocr/searchCompany?keyword=&page=`。
  Future<List<Map<String, dynamic>>> searchCompany({
    required String keyword,
    int? page,
  }) async {
    final q = keyword.trim();
    if (q.isEmpty) return const [];
    final params = <String, String>{'keyword': q};
    if (page != null) params['page'] = '$page';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.oacOcrSearchCompany}',
    ).replace(queryParameters: params);
    final body = await _getJson(uri);
    final code = body['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '企业模糊搜索失败');
    }
    final data = body['data'];
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// 经营异常 / 企业风险查询：`GET /desktop/oac/ocr/entRiskQuery?creditCode=`。
  Future<OacEntRiskQueryResult> fetchEntRiskQuery({
    required String creditCode,
  }) async {
    final code = creditCode.trim();
    if (code.isEmpty) {
      throw CustomerApiException('请先填写统一社会信用代码');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.oacOcrEntRiskQuery}',
    ).replace(queryParameters: {'creditCode': code});
    final body = await _getJson(uri);
    final biz = body['code'];
    final ok = biz == null || biz == 200 || biz == 0 || biz == '200';
    if (!ok) {
      throw CustomerApiException(body['msg']?.toString() ?? '经营异常查询失败');
    }
    return OacEntRiskQueryResult.fromData(body['data'], body['msg']?.toString());
  }

  /// 新建客户档案：`POST /desktop/oac/customer`。
  Future<void> createCustomer(Map<String, dynamic> body) async {
    await _mutateCustomer(
      method: 'POST',
      uri: Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerCreate}'),
      body: body,
      failMessage: '创建客户档案失败',
    );
  }

  /// 更新客户档案：`PUT /desktop/oac/customer`（body 含 id）。
  Future<void> updateCustomer(Map<String, dynamic> body) async {
    await _mutateCustomer(
      method: 'PUT',
      uri: Uri.parse('${ApiConfig.baseUrl}${ApiConfig.customerCreate}'),
      body: body,
      failMessage: '更新客户档案失败',
    );
  }

  Future<void> _mutateCustomer({
    required String method,
    required Uri uri,
    required Map<String, dynamic> body,
    required String failMessage,
  }) async {
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(AuthSession.headers(json: true))
        ..body = jsonEncode(body);
      final response = await ApiHttp.send(
        request,
        timeout: const Duration(seconds: 30),
      );

      if (response.body.isEmpty) {
        throw CustomerApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CustomerApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      final code = decoded['code'];
      final ok = code == null || code == 200 || code == 0 || code == '200';
      if (!ok) {
        throw CustomerApiException(decoded['msg']?.toString() ?? failMessage);
      }
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
      );

      if (response.body.isEmpty) {
        throw CustomerApiException('服务器返回为空');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw CustomerApiException('服务器返回数据格式错误');
      }
      if (response.statusCode == 401) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '未登录或登录已过期',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CustomerApiException(
          decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
        );
      }
      return decoded;
    } on CustomerApiException {
      rethrow;
    } on FormatException {
      throw CustomerApiException('服务器返回数据格式错误');
    } catch (e) {
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException('网络请求失败：$e');
    }
  }
}

/// 企业风险 / 经营异常查询结果。
class OacEntRiskQueryResult {
  String? abnormalRecord;
  String? penaltyHistory;
  String? message;

  static OacEntRiskQueryResult fromData(dynamic data, [String? fallbackMsg]) {
    final out = OacEntRiskQueryResult();
    if (data == null) {
      out.message = fallbackMsg;
      return out;
    }
    if (data is String) {
      final t = data.trim();
      if (t.isNotEmpty) out.abnormalRecord = t;
      out.message = fallbackMsg;
      return out;
    }
    if (data is List) {
      final lines = <String>[];
      for (final item in data) {
        if (item is Map) {
          final line = _riskItemLine(Map<String, dynamic>.from(item));
          if (line != null) lines.add(line);
        } else {
          final s = item.toString().trim();
          if (s.isNotEmpty) lines.add(s);
        }
      }
      if (lines.isNotEmpty) out.abnormalRecord = lines.join('\n');
      out.message = fallbackMsg;
      return out;
    }
    if (data is! Map) {
      out.message = fallbackMsg;
      return out;
    }
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false) {
      throw CustomerApiException(
        map['message']?.toString() ?? fallbackMsg ?? '经营异常查询失败',
      );
    }
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = map[k];
        if (v == null) continue;
        if (v is List) {
          final lines = <String>[];
          for (final item in v) {
            if (item is Map) {
              final line = _riskItemLine(Map<String, dynamic>.from(item));
              if (line != null) lines.add(line);
            } else {
              final s = item.toString().trim();
              if (s.isNotEmpty) lines.add(s);
            }
          }
          if (lines.isNotEmpty) return lines.join('\n');
          continue;
        }
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    out.abnormalRecord = pick(const [
      'abnormalRecord',
      'businessAbnormal',
      'abnormal',
      'abnormalOperation',
      'entRisk',
      'riskInfo',
      'content',
      'text',
      'message',
    ]);
    out.penaltyHistory = pick(const [
      'penaltyHistory',
      'adminPenalty',
      'punishment',
      'penalties',
    ]);
    out.message = pick(const ['tip', 'msg']) ?? fallbackMsg;
    return out;
  }
}

String? _riskItemLine(Map<String, dynamic> item) {
  final parts = <String>[];
  void add(String? v) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty) parts.add(t);
  }

  add(item['inReason']?.toString() ??
      item['addReason']?.toString() ??
      item['enrolNmLstOrigofincd']?.toString() ??
      item['reason']?.toString());
  add(item['inDate']?.toString() ??
      item['addDate']?.toString() ??
      item['enrolNmLstDt']?.toString() ??
      item['date']?.toString());
  add(item['department']?.toString() ??
      item['decisionOffice']?.toString() ??
      item['enrolIdtfOrg']?.toString() ??
      item['org']?.toString());
  if (parts.isEmpty) {
    final s = item['abnormalRecord']?.toString().trim() ??
        item['content']?.toString().trim() ??
        item['message']?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
  return parts.join(' · ');
}

/// 营业执照 OCR 结果（`OcrBusinessLicenseResult`）。
class OacBusinessLicenseOcrResult {
  String? title;
  String? creditCode;
  String? companyName;
  String? companyType;
  String? businessAddress;
  String? legalPerson;
  String? businessScope;
  String? registeredCapital;
  String? registrationDate;
  String? validPeriod;
  String? validFromDate;
  String? validToDate;
  String? companyForm;
  String? issueDate;
  String? message;

  static OacBusinessLicenseOcrResult fromJson(Map<String, dynamic> json) {
    String? s(String key, [List<String> alts = const []]) {
      for (final k in [key, ...alts]) {
        final v = json[k];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
      return null;
    }

    return OacBusinessLicenseOcrResult()
      ..title = s('title')
      ..creditCode = s('creditCode', const [
        'unifiedSocialCreditCode',
        'regNum',
        'credit_code',
      ])
      ..companyName = s('companyName', const [
        'name',
        'entName',
        'enterpriseName',
        'company_name',
      ])
      ..companyType = s('companyType', const ['type', 'company_type'])
      ..businessAddress = s('businessAddress', const [
        'address',
        'business_address',
        'domicile',
      ])
      ..legalPerson = s('legalPerson', const [
        'person',
        'legal_person',
        'legalRepresentative',
      ])
      ..businessScope = s('businessScope', const [
        'bizScope',
        'business_scope',
        'scope',
      ])
      ..registeredCapital = s('registeredCapital', const [
        'regCapital',
        'capital',
        'registered_capital',
      ])
      ..registrationDate = s('registrationDate', const [
        'establishDate',
        'foundDate',
        'establishedDate',
        'registration_date',
      ])
      ..validPeriod = s('validPeriod', const [
        'licenseExpire',
        'businessLicenseExpire',
        'valid_period',
      ])
      ..validFromDate = s('validFromDate', const [
        'validFrom',
        'valid_from_date',
      ])
      ..validToDate = s('validToDate', const ['validTo', 'valid_to_date'])
      ..companyForm = s('companyForm', const ['company_form'])
      ..issueDate = s('issueDate', const ['issue_date'])
      ..message = s('message', const ['msg']);
  }

  /// 营业期限展示文案。
  String? get licenseExpireText {
    final period = validPeriod?.trim();
    if (period != null && period.isNotEmpty) return period;
    final from = validFromDate?.trim() ?? '';
    final to = validToDate?.trim() ?? '';
    if (from.isEmpty && to.isEmpty) return null;
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    return '$from 至 $to';
  }
}

/// 阿里云 RecognizeAllText 通用 OCR 结果。
class OacGeneralOcrResult {
  bool? success;
  String? message;
  String? type;
  String? content;
  int? wordCount;
  List<String> words = const [];
  Map<String, dynamic>? kvData;
  List<String> subTypes = const [];
  String? rawData;

  /// 展平后的键值（字符串），供多字段回填。
  Map<String, String> get flatKv => flattenKvMap(kvData);

  /// 按候选键名取第一个非空值（精确匹配优先，其次包含匹配）。
  String? pickKv(List<String> keys) => pickFromKv(flatKv, keys);

  static OacGeneralOcrResult fromJson(Map<String, dynamic> json) {
    String? s(String key) {
      final v = json[key];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final wordsRaw = json['words'];
    final words = <String>[
      if (wordsRaw is List)
        for (final e in wordsRaw)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
    final subRaw = json['subTypes'];
    final subTypes = <String>[
      if (subRaw is List)
        for (final e in subRaw)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];

    final merged = <String, dynamic>{};
    void absorb(dynamic raw) {
      final map = coerceToMap(raw);
      if (map == null || map.isEmpty) return;
      merged.addAll(map);
    }

    absorb(json['kvData']);
    absorb(json['kvInfo']);
    absorb(json['KvInfo']);
    absorb(json['data']);
    absorb(json['result']);
    final rawData = s('rawData');
    if (rawData != null) {
      try {
        absorb(jsonDecode(rawData));
      } catch (_) {}
    }
    // 常见嵌套：raw / data 里再包一层 KvInfo.Data / kvDetails。
    for (final nestKey in const [
      'kvData',
      'kvInfo',
      'KvInfo',
      'data',
      'Data',
      'kvDetails',
      'KvDetails',
    ]) {
      absorb(merged[nestKey]);
    }

    final flat = flattenKvMap(merged);
    final kv = flat.isEmpty
        ? null
        : <String, dynamic>{for (final e in flat.entries) e.key: e.value};

    final wordCountRaw = json['wordCount'];
    int? wordCount;
    if (wordCountRaw is int) {
      wordCount = wordCountRaw;
    } else if (wordCountRaw is num) {
      wordCount = wordCountRaw.toInt();
    } else {
      wordCount = int.tryParse(wordCountRaw?.toString() ?? '');
    }

    return OacGeneralOcrResult()
      ..success = json['success'] is bool
          ? json['success'] as bool
          : json['success']?.toString().toLowerCase() != 'false'
      ..message = s('message')
      ..type = s('type')
      ..content = s('content')
      ..wordCount = wordCount
      ..words = words
      ..kvData = kv
      ..subTypes = subTypes
      ..rawData = rawData;
  }

  /// 将任意 kv 结构展平为 `字段名 -> 文本值`。
  static Map<String, String> flattenKvMap(dynamic raw) {
    final out = <String, String>{};
    void walk(dynamic node, {String? fallbackKey}) {
      if (node == null) return;
      if (node is String) {
        final decoded = coerceToMap(node);
        if (decoded != null) {
          walk(decoded);
          return;
        }
        final t = node.trim();
        if (t.isNotEmpty && fallbackKey != null && fallbackKey.isNotEmpty) {
          out.putIfAbsent(fallbackKey, () => t);
        }
        return;
      }
      if (node is num || node is bool) {
        if (fallbackKey != null && fallbackKey.isNotEmpty) {
          out.putIfAbsent(fallbackKey, () => '$node');
        }
        return;
      }
      if (node is List) {
        final parts = <String>[];
        for (final e in node) {
          if (e is Map) {
            walk(e);
            final v = _kvLeafValue(e);
            if (v != null) parts.add(v);
          } else {
            final t = e?.toString().trim() ?? '';
            if (t.isNotEmpty) parts.add(t);
          }
        }
        if (parts.isNotEmpty &&
            fallbackKey != null &&
            fallbackKey.isNotEmpty) {
          out.putIfAbsent(fallbackKey, () => parts.join('、'));
        }
        return;
      }
      if (node is! Map) return;
      final map = Map<String, dynamic>.from(node);
      final leaf = _kvLeafValue(map);
      final alias = map['keyName']?.toString().trim() ??
          map['KeyName']?.toString().trim() ??
          map['key']?.toString().trim();
      if (leaf != null) {
        if (fallbackKey != null && fallbackKey.isNotEmpty) {
          out.putIfAbsent(fallbackKey, () => leaf);
        }
        if (alias != null && alias.isNotEmpty) {
          out.putIfAbsent(alias, () => leaf);
        }
      }
      for (final e in map.entries) {
        final key = e.key.toString().trim();
        if (key.isEmpty) continue;
        final lower = key.toLowerCase();
        if (lower == 'value' ||
            lower == 'key' ||
            lower == 'keyname' ||
            lower == 'keyconfidence' ||
            lower == 'valueconfidence' ||
            lower == 'confidence' ||
            lower == 'kvcount' ||
            lower == 'data' && e.value is! Map) {
          continue;
        }
        final childLeaf = _kvLeafValue(e.value);
        if (childLeaf != null) {
          out.putIfAbsent(key, () => childLeaf);
          continue;
        }
        walk(e.value, fallbackKey: key);
      }
    }

    walk(raw);
    return out;
  }

  /// 从展平 kv / 正文「标签：值」行中取字段。
  static String? pickFromKv(Map<String, String> kv, List<String> keys) {
    if (kv.isEmpty || keys.isEmpty) return null;
    for (final want in keys) {
      final w = want.trim();
      if (w.isEmpty) continue;
      final exact = kv[w];
      if (exact != null && exact.trim().isNotEmpty) return exact.trim();
      for (final e in kv.entries) {
        if (e.key.toLowerCase() == w.toLowerCase() &&
            e.value.trim().isNotEmpty) {
          return e.value.trim();
        }
      }
    }
    for (final want in keys) {
      final w = want.trim();
      if (w.isEmpty) continue;
      for (final e in kv.entries) {
        if ((e.key.contains(w) || w.contains(e.key)) &&
            e.value.trim().isNotEmpty) {
          return e.value.trim();
        }
      }
    }
    return null;
  }

  /// 客户档案图片文字识别常见字段标签（匹配时按长度降序，避免「账号」误吃「银行账号」）。
  static const List<String> defaultOcrFieldLabels = [
    '统一社会信用代码',
    '基本存款账户编号',
    '基本存款账户账号',
    '开户银行账号',
    '纳税人识别号',
    '法定代表人',
    '注册电话',
    '联系电话',
    '注册地址',
    '注册资本',
    '注册资金',
    '注册日期',
    '成立日期',
    '出生日期',
    '详细地址',
    '办公地址',
    '经营地址',
    '企业名称',
    '公司名称',
    '主体全称',
    '企业简称',
    '企业类型',
    '企业性质',
    '品牌简称',
    '品牌名称',
    '品牌性质',
    '客户标签',
    '所属行业',
    '代言人信息',
    '营收规模/年',
    '营收规模',
    '人员规模',
    '开票名称',
    '发票抬头',
    '开户银行',
    '银行账号',
    '结算账号',
    '账户号码',
    '账号号码',
    '英文姓名',
    '中文姓名',
    '职能描述',
    '部门/职位',
    '关联企业',
    '就职企业',
    '所在城市',
    '移动电话',
    '电子邮箱',
    '年龄描述',
    '年龄段',
    '账号名',
    '开户行',
    '英文名',
    '中文名',
    '代言人',
    '信用代码',
    '营业执照',
    '手机号',
    'Name',
    '行业',
    '网址',
    '官网',
    '简称',
    '法人',
    '类型',
    '名称',
    '税号',
    '帐号',
    '账号',
    '平台',
    '链接',
    '姓名',
    '性别',
    '出生',
    '住址',
    '地址',
    '职位',
    '职务',
    '部门',
    '职能',
    '手机',
    '座机',
    '固话',
    '电话',
    '邮箱',
    '备注',
    '年龄',
    '城市',
    '单位',
    '公司',
    '企业',
  ];

  /// 从识别正文抽取「标签：值」以及「标签 值 标签 值」（空格分隔、遇下一标签截断）。
  static Map<String, String> parseLabeledFields(String text) {
    final out = <String, String>{};
    final normalized =
        text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return out;
    final lineRe = RegExp(
      r'^\s*([^:：\n]{1,40}?)\s*[:：]\s*(.+?)\s*$',
      multiLine: true,
    );
    for (final m in lineRe.allMatches(normalized)) {
      final key = m.group(1)?.trim() ?? '';
      final value = m.group(2)?.trim() ?? '';
      if (key.isEmpty || value.isEmpty) continue;
      if (key.length > 24) continue;
      out.putIfAbsent(key, () => value);
    }
    // 同行多组：姓名：张三 手机：138… 邮箱：a@b.com
    final inlineRe = RegExp(
      r'([^\s:：，,；;]{1,16})\s*[:：]\s*([^\s:：][^\n]*?)(?=(?:\s+[^\s:：，,；;]{1,16}\s*[:：])|$)',
    );
    for (final line in normalized.split('\n')) {
      final hits = inlineRe.allMatches(line).toList();
      if (hits.length < 2) continue;
      for (final m in hits) {
        final key = m.group(1)?.trim() ?? '';
        final value = m.group(2)?.trim() ?? '';
        if (key.isEmpty || value.isEmpty || key.length > 16) continue;
        out.putIfAbsent(key, () => value);
      }
    }
    // 同行无冒号：开户行 测试工商银行 银行账号 789
    for (final e in parseSpaceSeparatedLabeledFields(normalized).entries) {
      out.putIfAbsent(e.key, () => e.value);
    }
    return out;
  }

  /// 按已知标签切分「标签 值 标签 值」；值取到下一标签之前。
  static Map<String, String> parseSpaceSeparatedLabeledFields(
    String text, {
    List<String>? knownLabels,
  }) {
    final out = <String, String>{};
    final raw = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (raw.isEmpty) return out;
    final labels = [...(knownLabels ?? defaultOcrFieldLabels)]
      ..sort((a, b) => b.length.compareTo(a.length));
    if (labels.isEmpty) return out;

    final hits = <({int start, int end, String label})>[];
    var i = 0;
    while (i < raw.length) {
      var matched = false;
      for (final label in labels) {
        final end = i + label.length;
        if (end > raw.length) continue;
        if (raw.substring(i, end) != label) continue;
        final beforeOk = i == 0 || RegExp(r'[\s:：，,；;\n]').hasMatch(raw[i - 1]);
        final afterOk = end >= raw.length ||
            RegExp(r'[\s:：]').hasMatch(raw[end]);
        if (!beforeOk || !afterOk) continue;
        hits.add((start: i, end: end, label: label));
        i = end;
        matched = true;
        break;
      }
      if (!matched) i++;
    }
    if (hits.isEmpty) return out;

    for (var h = 0; h < hits.length; h++) {
      var vs = hits[h].end;
      while (vs < raw.length && RegExp(r'[\s:：]').hasMatch(raw[vs])) {
        vs++;
      }
      final ve = h + 1 < hits.length ? hits[h + 1].start : raw.length;
      if (vs >= ve) continue;
      final value = raw.substring(vs, ve).trim();
      if (value.isEmpty) continue;
      out.putIfAbsent(hits[h].label, () => value);
    }
    return out;
  }

  /// 取某组标签后的值，遇下一已知标签即停（可用于兜底正则之前）。
  static String? valueUntilNextLabel(
    String text,
    List<String> labels, {
    List<String>? stopLabels,
  }) {
    if (text.trim().isEmpty || labels.isEmpty) return null;
    final spaced = parseSpaceSeparatedLabeledFields(
      text,
      knownLabels: [
        ...labels,
        ...(stopLabels ?? defaultOcrFieldLabels),
      ],
    );
    return pickFromKv(spaced, labels);
  }

  static Map<String, dynamic>? coerceToMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty || (!t.startsWith('{') && !t.startsWith('['))) {
        return null;
      }
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static String? _kvLeafValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      if (t.startsWith('{') || t.startsWith('[')) {
        final map = coerceToMap(t);
        if (map != null) return _kvLeafValue(map);
      }
      return t;
    }
    if (raw is num || raw is bool) return '$raw';
    if (raw is List) {
      final parts = <String>[
        for (final e in raw)
          if (_kvLeafValue(e) != null) _kvLeafValue(e)!,
      ];
      if (parts.isEmpty) return null;
      return parts.join('、');
    }
    if (raw is Map) {
      for (final key in const [
        'value',
        'Value',
        'text',
        'Text',
        'content',
        'Content',
        'word',
        'Word',
      ]) {
        final v = raw[key];
        if (v == null) continue;
        final leaf = _kvLeafValue(v);
        if (leaf != null) return leaf;
      }
    }
    return null;
  }
}

/// 开户许可证 / 基本存款账户 OCR 结果。
class OacBankAccountLicenseOcrResult {
  String? title;
  String? approvalNumber;
  String? permitNumber;
  String? customerName;
  String? legalRepresentative;
  String? depositaryBank;
  String? bankAccount;
  String? message;

  static OacBankAccountLicenseOcrResult fromJson(Map<String, dynamic> json) {
    String? s(String key) {
      final v = json[key];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    return OacBankAccountLicenseOcrResult()
      ..title = s('title')
      ..approvalNumber = s('approvalNumber')
      ..permitNumber = s('permitNumber')
      ..customerName = s('customerName')
      ..legalRepresentative = s('legalRepresentative')
      ..depositaryBank = s('depositaryBank')
      ..bankAccount = s('bankAccount')
      ..message = s('message');
  }
}

CustomerArchive _parseCustomer(Map<String, dynamic> json) {
  final name = _asString(json['name']);
  final sales = _asString(json['salesNames']) ?? _asString(json['ownerNames']);
  return CustomerArchive()
    ..id = _asString(json['id'])
    ..archiveCode = _asString(json['customerCode'])
    ..customerType = _asString(json['customerType'])
    ..marketLevel = _asString(json['marketScale'])
    ..iconLetter = _iconLetter(name)
    ..iconUrl = _asString(json['iconUrl'])
    ..brandName = name
    ..brandSub = _subBrandText(json)
    ..industry = _asString(json['industry'])
    ..entityCount = _asInt(json['enterpriseCount'])
    ..entityName = _asString(json['enterpriseNames'])
    ..relation = _asString(json['relationTypes'])
    ..entityNature = _asString(json['entityNatures'])
    ..city = _asString(json['cities'])
    ..address = _asString(json['addresses'])
    ..contact = _asString(json['contactNames'])
    ..salesperson = sales
    ..serviceAgencyId = _asString(json['serviceAgencyId'])
    ..createTime = _asString(json['createTime'])
    ..latestDynamic = _asString(json['latestDynamic'])
    ..owner = _asString(json['ownerNames']) ?? sales
    ..assignTime = _asString(json['assignTime']) ??
        _asString(json['allocateTime'])
    ..assignDays = _asInt(json['assignDays']) ?? _asInt(json['allocateDays'])
    ..status = _asString(json['status'])
    ..remark = _asString(json['remark']);
}

String _iconLetter(String? name) {
  final t = name?.trim() ?? '';
  if (t.isEmpty) return '?';
  return String.fromCharCodes(t.runes.take(1));
}

/// 子品牌文案：优先 `subBrandNames` 字符串，否则拼接 `subBrands` 列表。
String? _subBrandText(Map<String, dynamic> json) {
  final named = _asString(json['subBrandNames']);
  if (named != null) return named;
  final list = json['subBrands'];
  if (list is! List) return null;
  final parts = list
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  return parts.join('；');
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
