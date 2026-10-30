import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

typedef LemonCredentialLoader = FutureOr<String?> Function();
typedef LemonCredentialSaver = FutureOr<void> Function(String value);
typedef LemonCredentialClearer = FutureOr<void> Function();
typedef LemonScopedCredentialLoader =
    FutureOr<String?> Function(LemonAuthContext context);
typedef LemonScopedCredentialSaver =
    FutureOr<void> Function(LemonAuthContext context, String value);
typedef LemonScopedCredentialClearer =
    FutureOr<void> Function(LemonAuthContext? context);

/// Request context supplied to host-aware credential callbacks.
final class LemonAuthContext {
  const LemonAuthContext(this.uri);

  final Uri uri;

  String get host => uri.host;
  String get origin => uri.hasPort
      ? '${uri.scheme}://${uri.host}:${uri.port}'
      : '${uri.scheme}://${uri.host}';
}

/// Thrown when authentication providers would silently overwrite each other.
final class LemonAuthConflictException implements Exception {
  const LemonAuthConflictException(this.message);

  final String message;

  @override
  String toString() => 'LemonAuthConflictException: $message';
}

/// A composable authentication strategy.
abstract class LemonAuth {
  const LemonAuth(this.name, {this.allowHeaderOverride = false});

  static LemonAuth bearer(
    LemonCredentialLoader load, {
    String name = 'jwt',
    LemonCredentialClearer? clear,
    bool allowHeaderOverride = false,
  }) => BearerAuth(
    load,
    name: name,
    clearCredential: clear,
    allowHeaderOverride: allowHeaderOverride,
  );

  static LemonAuth token(
    LemonCredentialLoader load, {
    String name = 'token',
    String header = 'Authorization',
    String? prefix,
    String? responseHeader,
    LemonCredentialSaver? save,
    LemonCredentialClearer? clear,
    bool allowHeaderOverride = false,
  }) => TokenAuth(
    load,
    name: name,
    header: header,
    prefix: prefix,
    responseHeader: responseHeader,
    save: save,
    clearCredential: clear,
    allowHeaderOverride: allowHeaderOverride,
  );

  static LemonAuth scopedToken(
    LemonScopedCredentialLoader load, {
    String name = 'token',
    String header = 'Authorization',
    String? prefix,
    String? responseHeader,
    LemonScopedCredentialSaver? save,
    LemonScopedCredentialClearer? clear,
    bool allowHeaderOverride = false,
  }) => ScopedTokenAuth(
    load,
    name: name,
    header: header,
    prefix: prefix,
    responseHeader: responseHeader,
    save: save,
    clearCredential: clear,
    allowHeaderOverride: allowHeaderOverride,
  );

  static LemonAuth session({String name = 'session', CookieJar? cookieJar}) =>
      SessionAuth(name: name, cookieJar: cookieJar);

  final String name;
  final bool allowHeaderOverride;

  Iterable<String> get sensitiveHeaders => const [];

  Future<void> onRequest(RequestOptions options) async {}
  Future<void> onResponse(Response<dynamic> response) async {}
  Future<void> clear() async {}
}

class TokenAuth extends LemonAuth {
  TokenAuth(
    this.load, {
    String name = 'token',
    this.header = 'Authorization',
    this.prefix,
    this.responseHeader,
    this.save,
    this.clearCredential,
    bool allowHeaderOverride = false,
  }) : super(name, allowHeaderOverride: allowHeaderOverride);

  final LemonCredentialLoader load;
  final LemonCredentialSaver? save;
  final LemonCredentialClearer? clearCredential;
  final String header;
  final String? prefix;
  final String? responseHeader;

  @override
  Iterable<String> get sensitiveHeaders => [header, ?responseHeader];

  @override
  Future<void> onRequest(RequestOptions options) async {
    final token = await load();
    if (token == null || token.isEmpty) return;
    _writeHeader(options, header, _withPrefix(token), allowHeaderOverride);
  }

  @override
  Future<void> onResponse(Response<dynamic> response) async {
    final callback = save;
    final sourceHeader = responseHeader;
    if (callback == null || sourceHeader == null) return;
    final token = response.headers.value(sourceHeader);
    if (token != null && token.isNotEmpty) await callback(token);
  }

  String _withPrefix(String token) {
    final value = prefix;
    return value == null || value.isEmpty ? token : '$value $token';
  }

  @override
  Future<void> clear() async => clearCredential?.call();
}

final class BearerAuth extends TokenAuth {
  BearerAuth(
    super.load, {
    super.name = 'jwt',
    super.clearCredential,
    super.allowHeaderOverride,
  }) : super(header: 'Authorization', prefix: 'Bearer');
}

final class ScopedTokenAuth extends LemonAuth {
  ScopedTokenAuth(
    this.load, {
    String name = 'token',
    this.header = 'Authorization',
    this.prefix,
    this.responseHeader,
    this.save,
    this.clearCredential,
    bool allowHeaderOverride = false,
  }) : super(name, allowHeaderOverride: allowHeaderOverride);

  final LemonScopedCredentialLoader load;
  final LemonScopedCredentialSaver? save;
  final LemonScopedCredentialClearer? clearCredential;
  final String header;
  final String? prefix;
  final String? responseHeader;

  @override
  Iterable<String> get sensitiveHeaders => [header, ?responseHeader];

  @override
  Future<void> onRequest(RequestOptions options) async {
    final token = await load(LemonAuthContext(options.uri));
    if (token == null || token.isEmpty) return;
    final value = prefix == null || prefix!.isEmpty ? token : '$prefix $token';
    _writeHeader(options, header, value, allowHeaderOverride);
  }

  @override
  Future<void> onResponse(Response<dynamic> response) async {
    final callback = save;
    final sourceHeader = responseHeader;
    if (callback == null || sourceHeader == null) return;
    final token = response.headers.value(sourceHeader);
    if (token == null || token.isEmpty) return;
    await callback(LemonAuthContext(response.requestOptions.uri), token);
  }

  @override
  Future<void> clear() async => clearCredential?.call(null);
}

final class SessionAuth extends LemonAuth {
  SessionAuth({String name = 'session', CookieJar? cookieJar})
    : cookieJar = cookieJar ?? CookieJar(ignoreExpires: false),
      super(name);

  final CookieJar cookieJar;
  late final CookieManager? _manager = _isWeb ? null : CookieManager(cookieJar);

  @override
  Iterable<String> get sensitiveHeaders => const ['cookie', 'set-cookie'];

  @override
  Future<void> onRequest(RequestOptions options) async {
    options.extra['withCredentials'] = true;
    final manager = _manager;
    if (manager == null) return;
    final cookies = await manager.loadCookies(options);
    if (cookies.isNotEmpty) options.headers['cookie'] = cookies;
  }

  @override
  Future<void> onResponse(Response<dynamic> response) async {
    await _manager?.saveCookies(response);
  }

  @override
  Future<void> clear() => cookieJar.deleteAll();
}

const _isWeb =
    bool.fromEnvironment('dart.library.js_interop') ||
    bool.fromEnvironment('dart.library.js_util');

void _writeHeader(
  RequestOptions options,
  String name,
  String value,
  bool allowOverride,
) {
  String? existingKey;
  for (final key in options.headers.keys) {
    if (key.toLowerCase() == name.toLowerCase()) {
      existingKey = key;
      break;
    }
  }
  if (existingKey != null && options.headers[existingKey] != value) {
    if (!allowOverride) {
      throw LemonAuthConflictException(
        'Authentication provider attempted to overwrite header "$name".',
      );
    }
    options.headers.remove(existingKey);
  }
  options.headers[name] = value;
}
