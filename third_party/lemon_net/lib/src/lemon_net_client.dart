import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'auth/lemon_auth.dart';
import 'auth/lemon_auth_interceptor.dart';
import 'lemon_download.dart';
import 'lemon_log_interceptor.dart';
import 'policies/lemon_refresh.dart';
import 'policies/lemon_request_control.dart';
import 'policies/lemon_retry.dart';
import 'serialization/lemon_response_parser.dart';
import 'transfer/lemon_transfer.dart';

/// A small Dio client with optional singleton access and composable auth.
final class LemonNet {
  LemonNet(
    String baseUrl, {
    List<LemonAuth> auth = const [],
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 60),
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    List<Interceptor> interceptors = const [],
    LemonLogPrinter? logger,
    LemonRefreshPolicy? refreshPolicy,
    LemonRetryPolicy? retryPolicy,
    LemonCachePolicy? cachePolicy,
    bool deduplicateRequests = false,
    int? maxConcurrentRequests,
    LemonResponseParser? responseParser,
  }) : this._(
         Dio(
           BaseOptions(
             baseUrl: baseUrl,
             connectTimeout: connectTimeout,
             receiveTimeout: receiveTimeout,
             sendTimeout: sendTimeout,
             headers: headers,
             receiveDataWhenStatusError: true,
             validateStatus: _acceptEveryHttpStatus,
           ),
         ),
         auth: auth,
         interceptors: interceptors,
         logger: logger,
         ownsDio: true,
         refreshPolicy: refreshPolicy,
         retryPolicy: retryPolicy,
         cachePolicy: cachePolicy,
         deduplicateRequests: deduplicateRequests,
         maxConcurrentRequests: maxConcurrentRequests,
         responseParser: responseParser,
       );

  LemonNet.fromDio(
    Dio dio, {
    List<LemonAuth> auth = const [],
    List<Interceptor> interceptors = const [],
    LemonLogPrinter? logger,
    bool closeDio = false,
    bool acceptEveryHttpStatus = true,
    LemonRefreshPolicy? refreshPolicy,
    LemonRetryPolicy? retryPolicy,
    LemonCachePolicy? cachePolicy,
    bool deduplicateRequests = false,
    int? maxConcurrentRequests,
    LemonResponseParser? responseParser,
  }) : this._(
         dio,
         auth: auth,
         interceptors: interceptors,
         logger: logger,
         ownsDio: closeDio,
         acceptEveryHttpStatus: acceptEveryHttpStatus,
         refreshPolicy: refreshPolicy,
         retryPolicy: retryPolicy,
         cachePolicy: cachePolicy,
         deduplicateRequests: deduplicateRequests,
         maxConcurrentRequests: maxConcurrentRequests,
         responseParser: responseParser,
       );

  LemonNet._(
    this.dio, {
    required List<LemonAuth> auth,
    required List<Interceptor> interceptors,
    required LemonLogPrinter? logger,
    required this._ownsDio,
    bool acceptEveryHttpStatus = false,
    LemonRefreshPolicy? refreshPolicy,
    LemonRetryPolicy? retryPolicy,
    LemonCachePolicy? cachePolicy,
    bool deduplicateRequests = false,
    int? maxConcurrentRequests,
    this.responseParser,
  }) : _authInterceptor = LemonAuthInterceptor(auth) {
    if (maxConcurrentRequests != null && maxConcurrentRequests <= 0) {
      throw ArgumentError.value(
        maxConcurrentRequests,
        'maxConcurrentRequests',
        'Must be greater than zero.',
      );
    }
    if (acceptEveryHttpStatus) {
      dio.options
        ..validateStatus = _acceptEveryHttpStatus
        ..receiveDataWhenStatusError = true;
    }
    dio.interceptors.add(_authInterceptor);
    if (cachePolicy != null) {
      final cache = LemonMemoryCacheInterceptor(cachePolicy);
      _cacheInterceptor = cache;
      dio.interceptors.add(cache);
    }
    if (deduplicateRequests) {
      dio.interceptors.add(LemonDeduplicationInterceptor());
    }
    if (maxConcurrentRequests != null) {
      dio.interceptors.add(LemonConcurrencyInterceptor(maxConcurrentRequests));
    }
    if (refreshPolicy != null) {
      dio.interceptors.add(LemonRefreshInterceptor(dio, refreshPolicy));
    }
    if (retryPolicy != null) {
      dio.interceptors.add(LemonRetryInterceptor(dio, retryPolicy));
    }
    dio.interceptors.addAll(interceptors);
    if (logger != null) {
      dio.interceptors.add(
        LemonLogInterceptor(
          print: logger,
          sensitiveHeaders: auth.expand(
            (provider) => provider.sensitiveHeaders,
          ),
        ),
      );
    }
  }

  static LemonNet? _global;

  static LemonNet get instance =>
      _global ??
      (throw StateError(
        'LemonNet is not initialized. Call LemonNet.init(...) first.',
      ));

  static bool get isInitialized => _global != null;

  static LemonNet init(
    String baseUrl, {
    List<LemonAuth> auth = const [],
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 60),
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
    List<Interceptor> interceptors = const [],
    LemonLogPrinter? logger,
    LemonRefreshPolicy? refreshPolicy,
    LemonRetryPolicy? retryPolicy,
    LemonCachePolicy? cachePolicy,
    bool deduplicateRequests = false,
    int? maxConcurrentRequests,
    LemonResponseParser? responseParser,
  }) {
    _global?.close();
    return _global = LemonNet(
      baseUrl,
      auth: auth,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: headers,
      interceptors: interceptors,
      logger: logger,
      refreshPolicy: refreshPolicy,
      retryPolicy: retryPolicy,
      cachePolicy: cachePolicy,
      deduplicateRequests: deduplicateRequests,
      maxConcurrentRequests: maxConcurrentRequests,
      responseParser: responseParser,
    );
  }

  static void reset() {
    _global?.close();
    _global = null;
  }

  final Dio dio;
  final bool _ownsDio;
  final LemonAuthInterceptor _authInterceptor;
  final LemonResponseParser? responseParser;
  LemonMemoryCacheInterceptor? _cacheInterceptor;
  bool _closed = false;

  bool get isClosed => _closed;

  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool skipAuth = false,
    Set<String>? authNames,
  }) {
    _ensureOpen();
    return dio.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _authOptions(options, skipAuth, authNames),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool skipAuth = false,
    Set<String>? authNames,
  }) => request<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: _methodOptions(options, 'GET'),
    cancelToken: cancelToken,
    onReceiveProgress: onReceiveProgress,
    skipAuth: skipAuth,
    authNames: authNames,
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool skipAuth = false,
    Set<String>? authNames,
  }) => request<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: _methodOptions(options, 'POST'),
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    skipAuth: skipAuth,
    authNames: authNames,
  );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool skipAuth = false,
    Set<String>? authNames,
  }) => request<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: _methodOptions(options, 'PUT'),
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    skipAuth: skipAuth,
    authNames: authNames,
  );

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool skipAuth = false,
    Set<String>? authNames,
  }) => request<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: _methodOptions(options, 'PATCH'),
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    skipAuth: skipAuth,
    authNames: authNames,
  );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool skipAuth = false,
    Set<String>? authNames,
  }) => request<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: _methodOptions(options, 'DELETE'),
    cancelToken: cancelToken,
    skipAuth: skipAuth,
    authNames: authNames,
  );

  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Object? data,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
    bool skipAuth = false,
    Set<String>? authNames,
  }) {
    _ensureOpen();
    return dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      data: data,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      options: _authOptions(options, skipAuth, authNames),
    );
  }

  /// Downloads a file into [directoryPath] and resolves its name from the
  /// response headers, final URL, [fallbackFileName], or a generated default.
  Future<LemonDownloadResult> downloadToDirectory(
    String urlPath,
    String directoryPath, {
    String? fallbackFileName,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Object? data,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
    bool skipAuth = false,
    Set<String>? authNames,
  }) async {
    String? resolvedPath;
    final response = await download(
      urlPath,
      (Headers headers) {
        final fileName = LemonDownloadFileName.resolve(
          headers: headers,
          requestPath: urlPath,
          fallbackFileName: fallbackFileName,
        );
        return resolvedPath = p.join(directoryPath, fileName);
      },
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      data: data,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      options: options,
      skipAuth: skipAuth,
      authNames: authNames,
    );
    return LemonDownloadResult(response: response, savePath: resolvedPath!);
  }

  Future<LemonResumableDownloadResult> downloadResumable(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool skipAuth = false,
    Set<String>? authNames,
  }) {
    _ensureOpen();
    return lemonResumableDownload(
      dio,
      urlPath,
      savePath,
      queryParameters: queryParameters,
      options: _authOptions(options, skipAuth, authNames),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  T parse<T>(Response<dynamic> response, LemonDataDecoder<T> decoder) {
    final parser = responseParser;
    if (parser == null) {
      throw StateError('No LemonResponseParser was configured.');
    }
    return parser.parse(response, decoder);
  }

  void clearCache() => _cacheInterceptor?.clear();

  Future<void> clearAuth() async {
    await _authInterceptor.clear();
    clearCache();
  }

  void close({bool force = false}) {
    if (_closed) return;
    _closed = true;
    if (_ownsDio) dio.close(force: force);
  }

  void _ensureOpen() {
    if (_closed) throw StateError('LemonNet client has already been closed.');
  }

  static Options _methodOptions(Options? source, String method) {
    final options = source ?? Options();
    options.method = method;
    return options;
  }

  static Options _authOptions(
    Options? source,
    bool skipAuth,
    Set<String>? authNames,
  ) {
    if (skipAuth && authNames != null) {
      throw ArgumentError('skipAuth and authNames cannot be used together.');
    }
    final options = source ?? Options();
    options.extra ??= <String, dynamic>{};
    if (skipAuth) options.extra![lemonSkipAuthKey] = true;
    if (authNames != null) {
      options.extra![lemonAuthNamesKey] = authNames.toList(growable: false);
    }
    return options;
  }
}

bool _acceptEveryHttpStatus(int? status) => status != null;
