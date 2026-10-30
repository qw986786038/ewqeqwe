import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 主软件接口调试日志（仅 [kDebugMode]）。
abstract final class ApiLog {
  static const int _maxBodyChars = 4000;

  static void request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[API] → $method $uri');
    if (headers != null && headers.isNotEmpty) {
      debugPrint('[API]   headers: ${_safeHeaders(headers)}');
    }
    if (body != null && body.isNotEmpty) {
      debugPrint('[API]   req: ${_truncate(body)}');
    }
  }

  static void response(http.Response response) {
    if (!kDebugMode) return;
    final url = response.request?.url;
    debugPrint('[API] ← ${response.statusCode}${url == null ? '' : ' $url'}');
    if (response.body.isNotEmpty) {
      debugPrint('[API]   res: ${_truncate(response.body)}');
    }
  }

  static void error(String method, Uri uri, Object error) {
    if (!kDebugMode) return;
    debugPrint('[API] ✕ $method $uri → $error');
  }

  static Map<String, String> _safeHeaders(Map<String, String> headers) {
    final out = <String, String>{};
    for (final e in headers.entries) {
      final key = e.key.toLowerCase();
      if (key == 'authorization' || key == 'token' || key == 'cookie') {
        final v = e.value;
        out[e.key] = v.length <= 16 ? '***' : '${v.substring(0, 12)}…';
      } else {
        out[e.key] = e.value;
      }
    }
    return out;
  }

  static String _truncate(String raw) {
    final text = raw.trim();
    if (text.length <= _maxBodyChars) return text;
    return '${text.substring(0, _maxBodyChars)}…(+${text.length - _maxBodyChars})';
  }
}

/// 带日志的 http 封装，供 `lib/services/*` 使用。
abstract final class ApiHttp {
  static const Duration defaultTimeout = Duration(seconds: 20);

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = defaultTimeout,
  }) {
    return _run('GET', uri, () => http.get(uri, headers: headers), timeout);
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) {
    return _run(
      'POST',
      uri,
      () => http.post(uri, headers: headers, body: body, encoding: encoding),
      timeout,
      body: body is String ? body : (body == null ? null : '$body'),
      headers: headers,
    );
  }

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) {
    return _run(
      'PUT',
      uri,
      () => http.put(uri, headers: headers, body: body, encoding: encoding),
      timeout,
      body: body is String ? body : (body == null ? null : '$body'),
      headers: headers,
    );
  }

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = defaultTimeout,
  }) {
    return _run(
      'DELETE',
      uri,
      () => http.delete(uri, headers: headers, body: body, encoding: encoding),
      timeout,
      body: body is String ? body : (body == null ? null : '$body'),
      headers: headers,
    );
  }

  static Future<http.Response> send(
    http.BaseRequest request, {
    Duration timeout = defaultTimeout,
  }) async {
    final method = request.method;
    final uri = request.url;
    String? body;
    if (request is http.Request) {
      body = request.body;
    } else if (request is http.MultipartRequest) {
      body =
          'multipart fields=${request.fields.keys.toList()} '
          'files=${request.files.map((f) => f.filename).toList()}';
    }
    ApiLog.request(method, uri, headers: request.headers, body: body);
    try {
      final streamed = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      ApiLog.response(response);
      return response;
    } catch (e) {
      ApiLog.error(method, uri, e);
      rethrow;
    }
  }

  static Future<http.Response> _run(
    String method,
    Uri uri,
    Future<http.Response> Function() call,
    Duration timeout, {
    Map<String, String>? headers,
    String? body,
  }) async {
    ApiLog.request(method, uri, headers: headers, body: body);
    try {
      final response = await call().timeout(timeout);
      ApiLog.response(response);
      return response;
    } catch (e) {
      ApiLog.error(method, uri, e);
      rethrow;
    }
  }
}
