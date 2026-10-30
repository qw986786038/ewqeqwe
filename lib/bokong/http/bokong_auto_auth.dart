import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:yidivination/bokong/api/login_api.dart';
import 'package:yidivination/bokong/constant.dart';
import 'package:yidivination/bokong/http/auth_token.dart';
import 'package:yidivination/bokong/http/sp.dart';
import 'package:yidivination/bokong/utils/ext.dart';

/// 播控临时写死账号：无感登录 / 401 时重新调 `/api/login/` 刷 token。
class BokongAutoAuth {
  BokongAutoAuth._();

  static const username = 'superadmin';
  static const password = 'admin123456';

  static Future<bool>? _inflight;

  /// 静默登录。成功写入 token 后返回 `true`；失败不弹提示。
  static Future<bool> loginSilently() {
    final active = _inflight;
    if (active != null) return active;
    final future = _doLogin();
    _inflight = future;
    return future.whenComplete(() {
      if (identical(_inflight, future)) _inflight = null;
    });
  }

  static Future<bool> _doLogin() async {
    try {
      final resp = await LoginApi.login(
        params: {
          'username': username,
          'password': password.md5Hex(),
        },
      );
      final user = resp.data;
      final access = user?.access;
      if (access == null || access.isEmpty) return false;

      await AuthToken.saveTokens(access: access, refresh: user?.refresh);
      await Sp.set(Constant.SP_USER, JsonMapper.serialize(user));
      return true;
    } catch (_) {
      return false;
    }
  }
}
