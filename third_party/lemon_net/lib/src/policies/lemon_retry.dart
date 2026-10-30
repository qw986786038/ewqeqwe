import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';

typedef LemonRetryDecider =
    bool Function(
      RequestOptions request,
      Response<dynamic>? response,
      DioException? error,
    );

/// Retries replayable, idempotent requests with exponential backoff.
final class LemonRetryPolicy {
  const LemonRetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 3),
    this.methods = const {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'},
    this.statusCodes = const {408, 425, 429, 500, 502, 503, 504},
    this.shouldRetry,
  }) : assert(maxAttempts >= 1);

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Set<String> methods;
  final Set<int> statusCodes;
  final LemonRetryDecider? shouldRetry;
}

final class LemonRetryInterceptor extends Interceptor {
  LemonRetryInterceptor(this.dio, this.policy);

  final Dio dio;
  final LemonRetryPolicy policy;

  static const _attemptKey = '_lemon_net.retry_attempt';

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(response.requestOptions, response, null)) {
      handler.next(response);
      return;
    }
    try {
      handler.resolve(await _retry(response.requestOptions));
    } catch (error) {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err.requestOptions, err.response, err)) {
      handler.next(err);
      return;
    }
    try {
      handler.resolve(await _retry(err.requestOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(
    RequestOptions options,
    Response<dynamic>? response,
    DioException? error,
  ) {
    final attempt = options.extra[_attemptKey] as int? ?? 1;
    if (attempt >= policy.maxAttempts || !_isReplayable(options.data)) {
      return false;
    }
    final custom = policy.shouldRetry;
    if (custom != null) return custom(options, response, error);
    if (!policy.methods.contains(options.method.toUpperCase())) {
      return false;
    }
    if (response != null) {
      return policy.statusCodes.contains(response.statusCode);
    }
    return error != null &&
        error.type != DioExceptionType.cancel &&
        error.type != DioExceptionType.badCertificate;
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final attempt = options.extra[_attemptKey] as int? ?? 1;
    options.extra[_attemptKey] = attempt + 1;
    final milliseconds = math.min(
      policy.baseDelay.inMilliseconds * math.pow(2, attempt - 1).toInt(),
      policy.maxDelay.inMilliseconds,
    );
    if (milliseconds > 0) {
      await Future<void>.delayed(Duration(milliseconds: milliseconds));
    }
    return dio.fetch<dynamic>(options);
  }
}

bool _isReplayable(Object? data) =>
    data == null ||
    data is String ||
    data is num ||
    data is bool ||
    data is List<Object?> ||
    data is Map<String, Object?>;
