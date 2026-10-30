import 'package:yidivination/bokong/constant.dart';
import 'package:yidivination/bokong/http/sp.dart';

/// JWT access / refresh 本地读写与 Authorization 头格式。
class AuthToken {
  AuthToken._();

  /// DVAdmin 默认：`Authorization: JWT <access>`
  static const String authScheme = 'JWT';

  static const _noAuthPaths = ['/api/login/', '/api/captcha/'];

  static Future<void> saveTokens({
    required String access,
    String? refresh,
  }) async {
    await Sp.set(Constant.SP_ACCESS_TOKEN, access);
    if (refresh != null && refresh.isNotEmpty) {
      await Sp.set(Constant.SP_REFRESH_TOKEN, refresh);
    }
  }

  static String? get accessToken => Sp.get<String>(Constant.SP_ACCESS_TOKEN);

  static String? get refreshToken => Sp.get<String>(Constant.SP_REFRESH_TOKEN);

  /// 去掉 `JWT ` / `Bearer ` 前缀后的 access token，供 lemon_net 认证使用。
  static String? get loadableAccessToken {
    final access = accessToken?.trim();
    if (access == null || access.isEmpty) return null;
    const jwt = '$authScheme ';
    if (access.startsWith(jwt)) return access.substring(jwt.length);
    if (access.startsWith('Bearer ')) return access.substring('Bearer '.length);
    return access;
  }

  static Future<void> saveFromAuthorizationHeader(String raw) async {
    var access = raw.trim();
    if (access.isEmpty) return;
    const jwt = '$authScheme ';
    if (access.startsWith(jwt)) {
      access = access.substring(jwt.length);
    } else if (access.startsWith('Bearer ')) {
      access = access.substring('Bearer '.length);
    }
    await saveTokens(access: access);
  }

  static String authorizationHeaderValue(String access) {
    final trimmed = access.trim();
    if (trimmed.isEmpty) return trimmed;
    final prefix = '$authScheme ';
    if (trimmed.startsWith(prefix) || trimmed.startsWith('Bearer ')) {
      return trimmed;
    }
    return '$prefix$trimmed';
  }

  static bool shouldAttachToken(String path) {
    final normalized = path.endsWith('/') ? path : '$path/';
    return !_noAuthPaths.any(normalized.endsWith);
  }

  static Future<void> clear() async {
    await Sp.remove(Constant.SP_ACCESS_TOKEN);
    await Sp.remove(Constant.SP_REFRESH_TOKEN);
  }
}
