import 'package:dio/dio.dart';

typedef LemonLogPrinter = void Function(String message);

final class LemonLogInterceptor extends Interceptor {
  LemonLogInterceptor({
    required this.print,
    Iterable<String> sensitiveHeaders = const [],
  }) : _sensitiveHeaders = {
         'authorization',
         'cookie',
         'set-cookie',
         ...sensitiveHeaders.map((header) => header.toLowerCase()),
       };

  final LemonLogPrinter print;
  final Set<String> _sensitiveHeaders;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('--> ${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) {
      print('headers: ${_redact(options.headers)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    print('<-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('<-- ERROR ${err.type.name} ${err.requestOptions.uri}');
    handler.next(err);
  }

  Map<String, Object?> _redact(Map<String, dynamic> headers) => {
    for (final entry in headers.entries)
      entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase())
          ? '<redacted>'
          : entry.value,
  };
}
