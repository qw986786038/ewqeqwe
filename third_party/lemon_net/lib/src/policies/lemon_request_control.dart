import 'dart:async';

import 'package:dio/dio.dart';

final class LemonCachePolicy {
  const LemonCachePolicy({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 100,
  }) : assert(maxEntries > 0);

  final Duration ttl;
  final int maxEntries;
}

final class LemonMemoryCacheInterceptor extends Interceptor {
  LemonMemoryCacheInterceptor(this.policy);

  final LemonCachePolicy policy;
  final Map<String, _CacheEntry> _entries = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }
    final key = _requestKey(options);
    final entry = _entries[key];
    if (entry == null || DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      handler.next(options);
      return;
    }
    handler.resolve(_copyResponse(entry.response, options, fromCache: true));
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final status = response.statusCode;
    if (options.method.toUpperCase() == 'GET' &&
        status != null &&
        status >= 200 &&
        status < 300) {
      if (_entries.length >= policy.maxEntries && _entries.isNotEmpty) {
        _entries.remove(_entries.keys.first);
      }
      _entries[_requestKey(options)] = _CacheEntry(
        response,
        DateTime.now().add(policy.ttl),
      );
    }
    handler.next(response);
  }

  void clear() => _entries.clear();
}

final class LemonDeduplicationInterceptor extends Interceptor {
  final Map<String, Completer<Response<dynamic>>> _pending = {};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method.toUpperCase() != 'GET' || options.cancelToken != null) {
      handler.next(options);
      return;
    }
    final key = _requestKey(options);
    final active = _pending[key];
    if (active != null) {
      try {
        final response = await active.future;
        handler.resolve(_copyResponse(response, options));
      } on DioException catch (error) {
        handler.reject(error);
      }
      return;
    }
    _pending[key] = Completer<Response<dynamic>>();
    options.extra[_dedupeKey] = key;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.extra.remove(_dedupeKey) as String?;
    final completer = key == null ? null : _pending.remove(key);
    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = err.requestOptions.extra.remove(_dedupeKey) as String?;
    final completer = key == null ? null : _pending.remove(key);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(err);
    }
    handler.next(err);
  }

  static const _dedupeKey = '_lemon_net.dedupe_key';
}

final class LemonConcurrencyInterceptor extends Interceptor {
  LemonConcurrencyInterceptor(int maxConcurrent)
    : _semaphore = _Semaphore(maxConcurrent);

  final _Semaphore _semaphore;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _semaphore.acquire();
    options.extra[_acquiredKey] = true;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _release(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _release(err.requestOptions);
    handler.next(err);
  }

  void _release(RequestOptions options) {
    if (options.extra.remove(_acquiredKey) == true) _semaphore.release();
  }

  static const _acquiredKey = '_lemon_net.concurrency_acquired';
}

final class _Semaphore {
  _Semaphore(this._available) : assert(_available > 0);

  int _available;
  final List<Completer<void>> _waiters = [];

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _available++;
    }
  }
}

final class _CacheEntry {
  const _CacheEntry(this.response, this.expiresAt);
  final Response<dynamic> response;
  final DateTime expiresAt;
}

String _requestKey(RequestOptions options) {
  final headers =
      options.headers.entries
          .map((entry) => '${entry.key.toLowerCase()}:${entry.value}')
          .toList()
        ..sort();
  return '${options.method.toUpperCase()}|${options.uri}|${headers.join('|')}';
}

Response<dynamic> _copyResponse(
  Response<dynamic> source,
  RequestOptions requestOptions, {
  bool fromCache = false,
}) => Response<dynamic>(
  data: source.data,
  headers: source.headers,
  requestOptions: requestOptions,
  statusCode: source.statusCode,
  statusMessage: source.statusMessage,
  redirects: source.redirects,
  isRedirect: source.isRedirect,
  extra: {...source.extra, if (fromCache) 'lemonNetFromCache': true},
);
