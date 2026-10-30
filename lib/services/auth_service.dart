import 'dart:convert';
import 'dart:typed_data';

import '../config/api_config.dart';
import 'api_http.dart';

class LoginResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const LoginResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// `/desktop/code` 返回的验证码数据。
class CaptchaResult {
  final bool success;
  final String message;
  final bool captchaEnabled;
  final String? uuid;
  final Uint8List? imageBytes;

  const CaptchaResult({
    required this.success,
    required this.message,
    this.captchaEnabled = true,
    this.uuid,
    this.imageBytes,
  });
}

/// 登录前按用户名返回的租户项（`DesktopTenantItemVO`）。
class DesktopTenantItem {
  const DesktopTenantItem({
    required this.tenantId,
    this.companyName,
    this.domain,
  });

  final String tenantId;
  final String? companyName;
  final String? domain;

  String get displayLabel {
    final name = companyName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final d = domain?.trim() ?? '';
    if (d.isNotEmpty) return d;
    return tenantId;
  }
}

/// `GET /desktop/tenant/listByUsername` 结果（`DesktopLoginTenantVO`）。
class TenantListByUsernameResult {
  const TenantListByUsernameResult({
    required this.success,
    required this.message,
    this.tenantEnabled = false,
    this.voList = const [],
  });

  final bool success;
  final String message;
  final bool tenantEnabled;
  final List<DesktopTenantItem> voList;
}

class AuthService {
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'clientid': ApiConfig.clientId,
      };

  /// 按用户名查租户：`GET /desktop/tenant/listByUsername?username=`。
  Future<TenantListByUsernameResult> fetchTenantsByUsername(
    String username,
  ) async {
    final q = username.trim();
    if (q.isEmpty) {
      return const TenantListByUsernameResult(
        success: true,
        message: 'ok',
        tenantEnabled: false,
        voList: [],
      );
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.tenantListByUsername}',
    ).replace(queryParameters: {'username': q});

    try {
      final response = await ApiHttp.get(
        uri,
        headers: _jsonHeaders,
        timeout: const Duration(seconds: 15),
      );

      final body = _decodeBody(response.body);
      final code = body['code'];
      final msg = body['msg']?.toString() ??
          body['message']?.toString() ??
          '查询租户失败';
      final ok = response.statusCode == 200 &&
          (code == null || code == 200 || code == 0 || code == '200');
      if (!ok) {
        return TenantListByUsernameResult(success: false, message: msg);
      }

      final data = body['data'];
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final enabledRaw = map['tenantEnabled'];
      final tenantEnabled = enabledRaw is bool
          ? enabledRaw
          : enabledRaw?.toString().toLowerCase() == 'true';

      final rawList = map['voList'];
      final voList = <DesktopTenantItem>[];
      if (rawList is List) {
        for (final e in rawList) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final id = m['tenantId']?.toString().trim() ?? '';
          if (id.isEmpty) continue;
          voList.add(
            DesktopTenantItem(
              tenantId: id,
              companyName: m['companyName']?.toString(),
              domain: m['domain']?.toString(),
            ),
          );
        }
      }

      return TenantListByUsernameResult(
        success: true,
        message: msg == '查询租户失败' ? 'ok' : msg,
        tenantEnabled: tenantEnabled,
        voList: voList,
      );
    } on FormatException {
      return const TenantListByUsernameResult(
        success: false,
        message: '租户数据格式错误',
      );
    } catch (e) {
      return TenantListByUsernameResult(
        success: false,
        message: '查询租户失败：$e',
      );
    }
  }

  /// 拉取图形验证码：`GET/POST /desktop/code` → uuid + Base64 img。
  Future<CaptchaResult> fetchCaptcha() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.captchaCode}');

    try {
      final response = await ApiHttp.get(
        uri,
        headers: _jsonHeaders,
        timeout: const Duration(seconds: 15),
      );

      final body = _decodeBody(response.body);
      final code = body['code'];
      final msg = body['msg']?.toString() ??
          body['message']?.toString() ??
          '获取验证码失败';

      final ok = response.statusCode == 200 &&
          (code == null || code == 200 || code == 0 || code == '200');

      if (!ok) {
        return CaptchaResult(success: false, message: msg);
      }

      final data = body['data'];
      final map = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{};

      final enabledRaw = map['captchaEnabled'];
      final captchaEnabled = enabledRaw is bool
          ? enabledRaw
          : enabledRaw?.toString().toLowerCase() != 'false';

      final uuid = map['uuid']?.toString();
      final img = map['img']?.toString();

      return CaptchaResult(
        success: true,
        message: msg == '获取验证码失败' ? 'ok' : msg,
        captchaEnabled: captchaEnabled,
        uuid: uuid,
        imageBytes: _decodeBase64Image(img),
      );
    } on FormatException {
      return const CaptchaResult(
        success: false,
        message: '验证码数据格式错误',
      );
    } catch (e) {
      return CaptchaResult(success: false, message: '获取验证码失败：$e');
    }
  }

  Future<LoginResult> passwordLogin({
    required String username,
    required String password,
    required String code,
    required String uuid,
    String tenantId = ApiConfig.tenantId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.passwordLogin}');

    try {
      final response = await ApiHttp.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode({
          'tenantId': tenantId,
          'username': username,
          'password': password,
          'code': code,
          'uuid': uuid,
        }),
        timeout: const Duration(seconds: 15),
      );

      final body = _decodeBody(response.body);

      final codeVal = body['code'];
      final msg = body['msg']?.toString() ??
          body['message']?.toString() ??
          '登录失败';

      // 常见 RuoYi / 自研接口：code == 200 表示成功
      final ok = response.statusCode == 200 &&
          (codeVal == null ||
              codeVal == 200 ||
              codeVal == 0 ||
              codeVal == '200');

      if (ok) {
        return LoginResult(
          success: true,
          message: msg == '登录失败' ? '登录成功' : msg,
          data: body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body,
        );
      }

      return LoginResult(success: false, message: msg, data: body);
    } on FormatException {
      return const LoginResult(success: false, message: '服务器返回数据格式错误');
    } catch (e) {
      return LoginResult(success: false, message: '网络请求失败：$e');
    }
  }

  Map<String, dynamic> _decodeBody(String raw) {
    if (raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Uint8List? _decodeBase64Image(String? img) {
    if (img == null || img.trim().isEmpty) return null;
    var raw = img.trim();
    final marker = raw.indexOf('base64,');
    if (marker >= 0) {
      raw = raw.substring(marker + 7);
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }
}
