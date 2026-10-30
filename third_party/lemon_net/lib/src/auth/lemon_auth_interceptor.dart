import 'package:dio/dio.dart';

import 'lemon_auth.dart';

const lemonSkipAuthKey = '_lemon_net.skip_auth';
const lemonAuthNamesKey = '_lemon_net.auth_names';

final class LemonAuthInterceptor extends Interceptor {
  LemonAuthInterceptor(Iterable<LemonAuth> providers)
    : providers = List.unmodifiable(providers) {
    final names = <String>{};
    for (final provider in this.providers) {
      if (provider.name.isEmpty) {
        throw ArgumentError.value(provider.name, 'name', 'Cannot be empty.');
      }
      if (!names.add(provider.name)) {
        throw ArgumentError('Duplicate authentication name: ${provider.name}');
      }
    }
  }

  final List<LemonAuth> providers;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      for (final provider in _selected(options)) {
        await provider.onRequest(options);
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      for (final provider in _selected(response.requestOptions)) {
        await provider.onResponse(response);
      }
      handler.next(response);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (response == null) {
      handler.next(err);
      return;
    }
    try {
      for (final provider in _selected(err.requestOptions)) {
        await provider.onResponse(response);
      }
      handler.next(err);
    } catch (error, stackTrace) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Iterable<LemonAuth> _selected(RequestOptions options) {
    if (options.extra[lemonSkipAuthKey] == true) return const [];
    final requested = options.extra[lemonAuthNamesKey];
    if (requested == null) return providers;
    final names = (requested as Iterable<Object?>).cast<String>().toSet();
    final known = providers.map((provider) => provider.name).toSet();
    final unknown = names.difference(known);
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Unknown authentication names: ${unknown.join(', ')}',
      );
    }
    return providers.where((provider) => names.contains(provider.name));
  }

  Future<void> clear() async {
    for (final provider in providers) {
      await provider.clear();
    }
  }
}
