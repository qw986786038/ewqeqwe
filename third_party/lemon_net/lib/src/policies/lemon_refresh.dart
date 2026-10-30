import 'dart:async';

import 'package:dio/dio.dart';

typedef LemonTokenRefresher = FutureOr<bool> Function();
typedef LemonRefreshFailure = FutureOr<void> Function();

/// Configuration for single-flight token refresh and one-time request replay.
final class LemonRefreshPolicy {
  const LemonRefreshPolicy({
    required this.refresh,
    this.statusCodes = const {401},
    this.onRefreshFailed,
  });

  final LemonTokenRefresher refresh;
  final Set<int> statusCodes;
  final LemonRefreshFailure? onRefreshFailed;
}

final class LemonRefreshInterceptor extends Interceptor {
  LemonRefreshInterceptor(this.dio, this.policy);

  final Dio dio;
  final LemonRefreshPolicy policy;
  Future<bool>? _refreshing;
  int _generation = 0;

  static const _replayedKey = '_lemon_net.refresh_replayed';
  static const _generationKey = '_lemon_net.refresh_generation';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra.putIfAbsent(_generationKey, () => _generation);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (!policy.statusCodes.contains(response.statusCode) ||
        options.extra['_lemon_net.skip_auth'] == true ||
        options.extra[_replayedKey] == true ||
        !_isReplayable(options.data)) {
      handler.next(response);
      return;
    }

    try {
      final requestGeneration = options.extra[_generationKey] as int? ?? 0;
      final refreshed = requestGeneration < _generation
          ? true
          : await _singleFlightRefresh();
      if (!refreshed) {
        await policy.onRefreshFailed?.call();
        handler.next(response);
        return;
      }
      options.extra[_replayedKey] = true;
      options.headers.removeWhere(
        (key, _) => key.toLowerCase() == 'authorization',
      );
      handler.resolve(await dio.fetch<dynamic>(options));
    } catch (error, stackTrace) {
      await policy.onRefreshFailed?.call();
      handler.reject(
        DioException(
          requestOptions: options,
          response: response,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<bool> _singleFlightRefresh() {
    final active = _refreshing;
    if (active != null) return active;
    final future = Future<bool>.sync(policy.refresh).then((success) {
      if (success) _generation++;
      return success;
    });
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }
}

bool _isReplayable(Object? data) =>
    data == null ||
    data is String ||
    data is num ||
    data is bool ||
    data is List<Object?> ||
    data is Map<String, Object?>;
