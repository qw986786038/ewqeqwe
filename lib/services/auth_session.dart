import '../config/api_config.dart';

/// 主软件登录态（内存）。播控模块有独立鉴权，互不共用。
class AuthSession {
  AuthSession._();

  static Map<String, dynamic>? loginData;
  static String? accessToken;

  static void saveFromLogin(Map<String, dynamic>? data) {
    loginData = data;
    final token = data?['access_token']?.toString().trim();
    accessToken = (token != null && token.isNotEmpty) ? token : null;
  }

  static void clear() {
    loginData = null;
    accessToken = null;
  }

  static Map<String, String> headers({bool json = false}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'clientid': ApiConfig.clientId,
      if (accessToken != null && accessToken!.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }
}
