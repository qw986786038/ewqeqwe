import 'package:dio/dio.dart';

typedef LemonJson = Map<String, dynamic>;
typedef LemonDataDecoder<T> = T Function(Object? data);

abstract interface class LemonResponseParser {
  T parse<T>(Response<dynamic> response, LemonDataDecoder<T> decoder);
}

final class LemonHttpException implements Exception {
  const LemonHttpException(this.statusCode, this.body);
  final int? statusCode;
  final Object? body;
}

final class LemonBusinessException implements Exception {
  const LemonBusinessException(this.code, this.message, this.body);
  final Object? code;
  final String message;
  final Object? body;
}

final class LemonFormatException implements Exception {
  const LemonFormatException(this.message, [this.body]);
  final String message;
  final Object? body;
}

/// Parses the common `{code, message, data}` JSON envelope.
final class LemonJsonResponseParser implements LemonResponseParser {
  const LemonJsonResponseParser({
    this.codeKey = 'code',
    this.messageKey = 'message',
    this.dataKey = 'data',
    this.successCodes = const {0},
  });

  final String codeKey;
  final String messageKey;
  final String dataKey;
  final Set<Object?> successCodes;

  @override
  T parse<T>(Response<dynamic> response, LemonDataDecoder<T> decoder) {
    final status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      throw LemonHttpException(status, response.data);
    }
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw LemonFormatException('Expected a JSON object response.', body);
    }
    final code = body[codeKey];
    if (!successCodes.contains(code)) {
      throw LemonBusinessException(
        code,
        body[messageKey]?.toString() ?? 'Request failed.',
        body,
      );
    }
    return decoder(body[dataKey]);
  }
}
