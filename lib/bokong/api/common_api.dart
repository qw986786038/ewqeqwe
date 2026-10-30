import 'dart:convert';

import 'package:dio/dio.dart'
    show ErrorInterceptorHandler, ResponseInterceptorHandler;
import 'package:flutter/foundation.dart';
import 'package:lemon_net/lemon_net.dart';
import 'package:path/path.dart' as p;
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/http/auth_token.dart';
import 'package:yidivination/bokong/http/bokong_auto_auth.dart';
import 'package:yidivination/bokong/http/cookie_storage.dart';
import 'package:yidivination/bokong/utils/ext.dart';

import '../constant.dart';
import '../http/app_exceptions.dart';

class CommonApi {
  CommonApi._();

  /// 调试时打印接口返回 body（紧凑 JSON，无缩进）。
  static const bool logApiResponseBody = true;

  static const Duration _defaultTimeout = Duration(milliseconds: 15000);

  /// 请求 path 必须以 `/` 结尾。
  static String _normalizePath(String path) {
    return path;
  }

  static bool _skipAuth(String path) => !AuthToken.shouldAttachToken(path);

  static Options _options({
    Duration sendTimeout = _defaultTimeout,
    Duration receiveTimeout = _defaultTimeout,
    ResponseType? responseType,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      responseType: responseType,
      headers: headers,
    );
  }

  static Future<void> ensureInitialized() async {
    if (LemonNet.isInitialized) return;
    LemonNet.init(
      Constant.baseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 60000),
      logger: kDebugMode ? print : null,
      interceptors: (logApiResponseBody && kDebugMode)
          ? const [_ApiResponseBodyLogInterceptor()]
          : const [],
      auth: [
        LemonAuth.session(
          cookieJar: PersistCookieJar(storage: CookieStorage()),
        ),
        LemonAuth.token(
          () => AuthToken.loadableAccessToken,
          name: 'jwt',
          header: 'Authorization',
          prefix: AuthToken.authScheme,
          responseHeader: 'Authorization',
          save: AuthToken.saveFromAuthorizationHeader,
          clear: AuthToken.clear,
        ),
      ],
    );
  }

  static dynamic _bodyOf(Response<dynamic> response) {
    final status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      throw AppException.fromStatus(status, response.statusMessage);
    }
    return response.data;
  }

  static Future<dynamic> _send(Future<Response<dynamic>> request) async {
    try {
      return _bodyOf(await request);
    } on DioException catch (e) {
      throw AppException.create(e);
    }
  }

  static Future<AppRespEntity<T>> _parseResponse<T>(Future<dynamic> request) {
    return request.then((value) {
      try {
        final AppRespEntity<T> data = AppRespEntity.fromJson(value);
        if (data.code == 200) {
          return Future.value(data);
        }
        return Future.error(data);
      } catch (e) {
        if (e is AppException) {
          return Future.error(e);
        }
        if (kDebugMode) {
          print(e.toString());
        }
        return Future.error(AppException(500, '对象转换异常'));
      }
    });
  }

  static bool _isUnauthorized(Object e) {
    if (e is AppException && e.code == 401) return true;
    if (e is AppRespEntity && e.code == 401) return true;
    return false;
  }

  /// HTTP / 业务码 401 时静默重登并重试一次（登录等 skipAuth 路径不重试）。
  static Future<T> _withTokenRefresh<T>(
    String path,
    Future<T> Function() run,
  ) async {
    try {
      return await run();
    } catch (e) {
      if (_skipAuth(path) || !_isUnauthorized(e)) rethrow;
      if (!await BokongAutoAuth.loginSilently()) rethrow;
      return await run();
    }
  }

  //公共请求方法
  static Future<AppRespEntity<T>> post<T>(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    await ensureInitialized();
    final normalized = _normalizePath(path);
    return _withTokenRefresh(
      normalized,
      () => _parseResponse<T>(
        _send(
          LemonNet.instance.post<dynamic>(
            normalized,
            data: params,
            skipAuth: _skipAuth(normalized),
            options: _options(),
          ),
        ),
      ),
    );
  }

  //公共请求方法
  static Future<AppRespEntity<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    await ensureInitialized();
    final normalized = _normalizePath(path);
    return _withTokenRefresh(
      normalized,
      () => _parseResponse<T>(
        _send(
          LemonNet.instance.get<dynamic>(
            normalized,
            queryParameters: params,
            skipAuth: _skipAuth(normalized),
            options: _options(),
          ),
        ),
      ),
    );
  }

  //公共请求方法
  static Future<AppRespEntity<T>> postForm<T>(
    String path, {
    Map<String, dynamic>? params,
    List<String>? files,
  }) async {
    await ensureInitialized();
    final normalized = _normalizePath(path);
    return _withTokenRefresh(normalized, () async {
      final fileParams = <String, dynamic>{...params ?? {}};
      await Future.forEach<String>(files ?? <String>[], (element) async {
        final index = files?.indexOf(element);
        fileParams["file$index"] = await MultipartFile.fromFile(
          element,
          filename:
              "img_${DateTime.now().millisecondsSinceEpoch.date("yyyyMMddHHmmssSSS")}.jpg",
        );
      });

      return _parseResponse<T>(
        _send(
          LemonNet.instance.post<dynamic>(
            normalized,
            data: FormData.fromMap(fileParams),
            skipAuth: _skipAuth(normalized),
            options: _options(),
          ),
        ),
      );
    });
  }

  /// PUT 请求
  static Future<AppRespEntity<T>> put<T>(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    await ensureInitialized();
    final normalized = _normalizePath(path);
    return _withTokenRefresh(
      normalized,
      () => _parseResponse<T>(
        _send(
          LemonNet.instance.put<dynamic>(
            normalized,
            data: params,
            skipAuth: _skipAuth(normalized),
            options: _options(),
          ),
        ),
      ),
    );
  }

  /// DELETE 请求
  static Future<AppRespEntity<T>> delete<T>(
    String path, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? data,
  }) async {
    await ensureInitialized();
    final normalized = _normalizePath(path);
    return _withTokenRefresh(
      normalized,
      () => _parseResponse<T>(
        _send(
          LemonNet.instance.delete<dynamic>(
            normalized,
            queryParameters: params,
            data: data,
            skipAuth: _skipAuth(normalized),
            options: _options(),
          ),
        ),
      ),
    );
  }

  static Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    await ensureInitialized();
    params?.removeWhere((key, value) => value == null);
    final normalized = _normalizePath(path);
    final data = await _withTokenRefresh(
      normalized,
      () => _send(
        LemonNet.instance.get<dynamic>(
          normalized,
          queryParameters: params,
          skipAuth: _skipAuth(normalized),
          options: _options(
            sendTimeout: const Duration(milliseconds: 30000),
            receiveTimeout: const Duration(milliseconds: 60000),
            responseType: ResponseType.bytes,
          ),
        ),
      ),
    );
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Future.error(AppException(500, '文件下载异常'));
  }

  /// 下载完整 URL（CDN / OSS 等），不携带业务认证。
  static Future<Uint8List> getRemoteBytes(String url) async {
    await ensureInitialized();
    final data = await _send(
      LemonNet.instance.get<dynamic>(
        url,
        skipAuth: true,
        options: _options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
          responseType: ResponseType.bytes,
        ),
      ),
    );
    if (data is Uint8List) {
      if (data.isEmpty) throw AppException(500, '文件下载异常');
      return data;
    }
    if (data is List<int>) {
      if (data.isEmpty) throw AppException(500, '文件下载异常');
      return Uint8List.fromList(data);
    }
    return Future.error(AppException(500, '文件下载异常'));
  }

  //下载
  static Future download(
    String path,
    String dir, {
    String? fileName,
    Map<String, dynamic>? params,
    ProgressCallback? onReceiveProgress,
  }) async {
    await ensureInitialized();
    params?.removeWhere((key, value) => value == null);
    final normalized = _normalizePath(path);
    final query = params == null
        ? null
        : <String, dynamic>{'params': json.encode(params)};
    final options = _options(
      sendTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 60000),
    );
    if (fileName != null && fileName.isNotEmpty) {
      return LemonNet.instance.download(
        normalized,
        p.join(dir, fileName),
        queryParameters: query,
        skipAuth: _skipAuth(normalized),
        options: options,
        onReceiveProgress: onReceiveProgress,
      );
    }
    return LemonNet.instance.downloadToDirectory(
      normalized,
      dir,
      queryParameters: query,
      skipAuth: _skipAuth(normalized),
      options: options,
      onReceiveProgress: onReceiveProgress,
    );
  }

  //下载
  static Future download2(
    String path,
    savePath, {
    Map<String, dynamic>? params,
    ProgressCallback? onReceiveProgress,
  }) async {
    await ensureInitialized();
    params?.removeWhere((key, value) => value == null);
    final normalized = _normalizePath(path);
    return LemonNet.instance.download(
      normalized,
      savePath,
      queryParameters: params == null
          ? null
          : <String, dynamic>{'params': json.encode(params)},
      skipAuth: _skipAuth(normalized),
      options: _options(
        sendTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 60000),
      ),
      onReceiveProgress: onReceiveProgress,
    );
  }
}

/// Debug：打印接口返回 body（紧凑 JSON，无缩进；仅 [kDebugMode] 注册）。
final class _ApiResponseBodyLogInterceptor extends Interceptor {
  const _ApiResponseBodyLogInterceptor();

  static String _bodyAsJson(dynamic data) {
    if (data == null) return 'null';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    print('<-- ${response.requestOptions.uri} ${_bodyAsJson(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    if (data != null) {
      print('<-- error ${err.requestOptions.uri} ${_bodyAsJson(data)}');
    }
    handler.next(err);
  }
}
