import 'package:lemon_net/lemon_net.dart';
import 'package:yidivination/bokong/entity/app_resp_entity.dart';
import 'package:yidivination/bokong/entity/system/file_presign_entity.dart';
import 'package:yidivination/bokong/utils/file_content_type.dart';

import 'common_api.dart';

class SystemFileApi {
  SystemFileApi._();

  static const String _defaultPathPrefix = 'media';

  /// 获取文件上传预签名（媒体库直传 OSS 第一步）
  static Future<AppRespEntity<FilePresignEntity>> presign({
    required String filename,
    required String contentType,
    String pathPrefix = _defaultPathPrefix,
  }) {
    return CommonApi.post<FilePresignEntity>(
      '/api/system/file/presign/',
      params: <String, dynamic>{
        'filename': filename,
        'content_type': contentType,
        'path_prefix': pathPrefix,
      },
    );
  }

  /// 使用预签名信息将文件字节直传 OSS（第二步），返回响应头中的 ETag（已去掉引号）。
  static Future<String> uploadDirect({
    required FilePresignEntity presign,
    required List<int> bytes,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final String? uploadUrl = presign.upload_url;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw StateError('预签名 upload_url 为空');
    }

    final Map<String, dynamic> headers = <String, dynamic>{};
    presign.required_headers?.forEach((String key, dynamic value) {
      if (value != null) headers[key] = value.toString();
    });

    await CommonApi.ensureInitialized();
    final Response<dynamic> response = await LemonNet.instance.put<dynamic>(
      uploadUrl,
      data: bytes,
      skipAuth: true,
      options: Options(
        headers: headers,
        responseType: ResponseType.plain,
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 2),
      ),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );

    final int? status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      throw StateError('OSS 直传失败：HTTP $status');
    }

    final String? etag = _parseEtag(response);
    if (etag == null || etag.isEmpty) {
      throw StateError('OSS 直传成功但未返回 ETag');
    }
    return etag;
  }

  static String? _parseEtag(Response<dynamic> response) {
    final String? raw = response.headers.value('etag');
    if (raw == null || raw.isEmpty) return null;
    if (raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')) {
      return raw.substring(1, raw.length - 1);
    }
    return raw;
  }

  /// 接口要求的 ETag 格式（带双引号，如 `"abc123"`）。
  static String formatEtagForApi(String etag) {
    final String trimmed = etag.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      return trimmed;
    }
    return '"$trimmed"';
  }

  /// 直传 OSS 完成后登记文件（第三步）
  static Future<AppRespEntity<String>> directComplete({
    required String objectKey,
    required String fileUrl,
    required String name,
    required int size,
    required String mimeType,
    required int fileType,
    required String etag,
  }) {
    return CommonApi.post<String>(
      '/api/system/file/direct_complete/',
      params: <String, dynamic>{
        'object_key': objectKey,
        'file_url': fileUrl,
        'name': name,
        'size': size,
        'mime_type': mimeType,
        'file_type': fileType,
        'etag': formatEtagForApi(etag),
      },
    );
  }

  /// 预签名并直传 OSS，返回预签名结果与 OSS ETag。
  static Future<({FilePresignEntity presign, String etag})> presignAndUpload({
    required String filename,
    required String contentType,
    required List<int> bytes,
    String pathPrefix = _defaultPathPrefix,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final AppRespEntity<FilePresignEntity> resp = await presign(
      filename: filename,
      contentType: contentType,
      pathPrefix: pathPrefix,
    );
    final FilePresignEntity? presignData = resp.data;
    if (presignData == null) {
      throw StateError('预签名响应 data 为空');
    }

    if (presignData.use_direct != true) {
      throw StateError('当前预签名不支持客户端直传');
    }

    final String etag = await uploadDirect(
      presign: presignData,
      bytes: bytes,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );

    return (presign: presignData, etag: etag);
  }

  /// 预签名 → 直传 OSS → 登记文件（三步合一）
  static Future<({FilePresignEntity presign, String etag, String? message})>
  presignUploadAndComplete({
    required String filename,
    required String contentType,
    required List<int> bytes,
    String pathPrefix = _defaultPathPrefix,
    int? fileType,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final ({FilePresignEntity presign, String etag}) upload =
        await presignAndUpload(
          filename: filename,
          contentType: contentType,
          bytes: bytes,
          pathPrefix: pathPrefix,
          onSendProgress: onSendProgress,
          cancelToken: cancelToken,
        );

    final FilePresignEntity presign = upload.presign;
    final String? objectKey = presign.object_key;
    final String? fileUrl = presign.public_url;
    if (objectKey == null || objectKey.isEmpty) {
      throw StateError('预签名 object_key 为空');
    }
    if (fileUrl == null || fileUrl.isEmpty) {
      throw StateError('预签名 public_url 为空');
    }

    final AppRespEntity<String> resp = await directComplete(
      objectKey: objectKey,
      fileUrl: fileUrl,
      name: presign.client_name?.isNotEmpty == true
          ? presign.client_name!
          : filename,
      size: bytes.length,
      mimeType: contentType,
      fileType:
          fileType ??
          presign.file_type_hint ??
          guessFileTypeFromMimeType(contentType) ??
          0,
      etag: upload.etag,
    );

    return (presign: presign, etag: upload.etag, message: resp.msg);
  }
}
