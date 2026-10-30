import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'lemon_file_io.dart';

final class LemonResumableDownloadResult {
  const LemonResumableDownloadResult({
    required this.response,
    required this.savePath,
    required this.resumedFrom,
  });

  final Response<dynamic> response;
  final String savePath;
  final int resumedFrom;
}

/// Downloads with an HTTP Range request and safely overwrites when the server
/// ignores Range instead of appending a full response to a partial file.
Future<LemonResumableDownloadResult> lemonResumableDownload(
  Dio dio,
  String urlPath,
  String savePath, {
  Map<String, dynamic>? queryParameters,
  Options? options,
  CancelToken? cancelToken,
  ProgressCallback? onReceiveProgress,
}) async {
  final existing = await lemonFileLength(savePath);
  final headers = <String, dynamic>{...?options?.headers};
  if (existing > 0) headers['range'] = 'bytes=$existing-';
  final requestOptions = (options ?? Options()).copyWith(
    headers: headers,
    responseType: ResponseType.stream,
  );
  final response = await dio.request<ResponseBody>(
    urlPath,
    queryParameters: queryParameters,
    options: requestOptions,
    cancelToken: cancelToken,
  );
  final status = response.statusCode;
  if (status != 200 && status != 206) {
    throw DioException.badResponse(
      statusCode: status ?? 0,
      requestOptions: response.requestOptions,
      response: response,
    );
  }
  final append = existing > 0 && status == 206;
  final resumedFrom = append ? existing : 0;
  final body = response.data;
  if (body == null) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Download response body is empty.',
    );
  }
  final remaining = int.tryParse(
    response.headers.value(Headers.contentLengthHeader) ?? '',
  );
  final total = remaining == null ? -1 : resumedFrom + remaining;
  var received = resumedFrom;
  final stream = body.stream.map<List<int>>((chunk) {
    received += chunk.length;
    onReceiveProgress?.call(received, total);
    return chunk;
  });
  await lemonWriteFile(savePath, stream, append: append);
  return LemonResumableDownloadResult(
    response: response,
    savePath: savePath,
    resumedFrom: resumedFrom,
  );
}

final class LemonUploadChunk {
  const LemonUploadChunk({
    required this.uploadId,
    required this.index,
    required this.offset,
    required this.totalBytes,
    required this.bytes,
    required this.isLast,
  });

  final String uploadId;
  final int index;
  final int offset;
  final int totalBytes;
  final List<int> bytes;
  final bool isLast;

  String get contentRange =>
      'bytes $offset-${offset + bytes.length - 1}/$totalBytes';
}

typedef LemonChunkUploader = Future<void> Function(LemonUploadChunk chunk);

/// Splits a local file into replayable chunks. The application maps each chunk
/// to its server-specific upload endpoint and resume protocol.
Future<void> lemonUploadFileInChunks(
  String filePath, {
  required String uploadId,
  required LemonChunkUploader uploadChunk,
  int chunkSize = 2 * 1024 * 1024,
  int startOffset = 0,
  ProgressCallback? onProgress,
}) async {
  if (chunkSize <= 0) throw ArgumentError.value(chunkSize, 'chunkSize');
  final total = await lemonFileLength(filePath);
  if (startOffset < 0 || startOffset > total) {
    throw RangeError.range(startOffset, 0, total, 'startOffset');
  }
  var offset = startOffset;
  var index = offset ~/ chunkSize;
  while (offset < total) {
    final end = (offset + chunkSize < total) ? offset + chunkSize : total;
    final bytes = await lemonReadFile(
      filePath,
      start: offset,
      end: end,
    ).expand((chunk) => chunk).toList();
    await uploadChunk(
      LemonUploadChunk(
        uploadId: uploadId,
        index: index,
        offset: offset,
        totalBytes: total,
        bytes: bytes,
        isLast: end == total,
      ),
    );
    offset = end;
    index++;
    onProgress?.call(offset, total);
  }
}

Future<String> lemonFileSha256(String filePath) async {
  final digest = await sha256.bind(lemonReadFile(filePath)).first;
  return digest.toString();
}
