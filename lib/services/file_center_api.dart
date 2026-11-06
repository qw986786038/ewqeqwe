import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_http.dart';
import 'auth_session.dart';

class FileCenterApiException implements Exception {
  FileCenterApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 预签名结果（`FilePresignVo`）。
class FilePresignVo {
  String? uploadUrl;
  String? objectKey;
  String? contentType;
  int? expires;
  String? accessKeyId;
  int? expiresAt;
  String? signature;
  Map<String, String>? headers;
  String? publicUrl;
  String? moduleCode;
  String? categoryCode;
  int? folderId;
}

/// 登记完成后的上传结果（`FileUploadVo`）。
class FileUploadVo {
  String? fileId;
  String? fileName;
  String? originalName;
  String? fileSuffix;
  int? fileSize;
  String? contentType;
  int? width;
  int? height;
  int? folderId;
  String? createTime;
  int? status;
  String? previewUrl;
  String? relativeUrl;
  String? objectUrl;
  String? objectRelativeUrl;
  String? displayUrl;
  String? displayRelativeUrl;
  String? thumbnailUrl;
  String? thumbnailRelativeUrl;
  String? url;
  String? videoCoverUrl;
  String? videoCoverRelativeUrl;
}

/// 文件详情（`FileDetailVo`）。
class FileDetailVo {
  String? fileId;
  String? fileName;
  String? originalName;
  String? contentType;
  int? fileSize;
  int? width;
  int? height;
  int? status;
  String? objectKey;
  String? objectUrl;
  String? objectRelativeUrl;
  String? relativeUrl;
  String? url;
  String? displayUrl;
  String? displayRelativeUrl;
  String? previewUrl;
  String? thumbnailUrl;
  String? thumbnailRelativeUrl;
}

/// 预签名直传并登记后的汇总结果。
class FileCenterUploadResult {
  FileCenterUploadResult({
    required this.fileId,
    required this.publicUrl,
    this.objectKey,
    this.displayUrl,
    this.previewUrl,
    this.relativeUrl,
    this.detail,
  });

  final String fileId;
  final String publicUrl;
  final String? objectKey;
  final String? displayUrl;
  final String? previewUrl;
  final String? relativeUrl;
  final FileDetailVo? detail;
}

/// 文件中心：presign → PUT OSS → directComplete → info。
class FileCenterApi {
  /// [fetchDetail] 为 false 时只走前三步：presign → PUT → directComplete。
  Future<FileCenterUploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
    String moduleCode = ApiConfig.fileCenterModuleCode,
    bool fetchDetail = true,
  }) async {
    if (bytes.isEmpty) {
      throw FileCenterApiException('文件内容为空');
    }
    final name = fileName.trim().isEmpty ? 'file.bin' : fileName.trim();
    final mime = (contentType?.trim().isNotEmpty == true)
        ? contentType!.trim()
        : _guessMimeType(name);

    final size = await _readImageSize(bytes);
    final presign = await _presign(
      filename: name,
      contentType: mime,
      moduleCode: moduleCode,
    );
    final uploadUrl = presign.uploadUrl?.trim() ?? '';
    if (uploadUrl.isEmpty) {
      throw FileCenterApiException('预签名未返回 uploadUrl');
    }
    final objectKey = presign.objectKey?.trim() ?? '';
    if (objectKey.isEmpty) {
      throw FileCenterApiException('预签名未返回 objectKey');
    }
    final publicUrl = presign.publicUrl?.trim() ?? '';
    if (publicUrl.isEmpty) {
      throw FileCenterApiException('预签名未返回 publicUrl');
    }
    final folderId = presign.folderId;
    if (folderId == null) {
      throw FileCenterApiException('预签名未返回 folderId');
    }

    final putContentType =
        (presign.contentType?.trim().isNotEmpty == true)
            ? presign.contentType!.trim()
            : mime;
    final etag = await _putToOss(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: putContentType,
      headers: presign.headers,
    );

    final uploaded = await _directComplete(
      objectKey: objectKey,
      fileUrl: publicUrl,
      name: name,
      size: bytes.length,
      mimeType: putContentType,
      etag: etag,
      moduleCode: moduleCode,
      folderId: folderId,
      width: size?.width ?? 0,
      height: size?.height ?? 0,
    );

    final fileId = uploaded.fileId?.trim() ?? '';
    if (fileId.isEmpty) {
      throw FileCenterApiException('登记成功但未返回 fileId');
    }

    FileDetailVo? detail;
    if (fetchDetail) {
      try {
        detail = await fetchInfo(fileId);
      } catch (_) {
        // 详情失败不阻断上传；展示地址回退到登记结果 / 预签名。
      }
    }

    final resolvedPublic = _firstUrl([
      detail?.objectUrl,
      detail?.url,
      detail?.displayUrl,
      detail?.previewUrl,
      uploaded.objectUrl,
      uploaded.url,
      uploaded.displayUrl,
      uploaded.previewUrl,
      publicUrl,
    ]);
    if (resolvedPublic == null || resolvedPublic.isEmpty) {
      throw FileCenterApiException('上传成功但未获得可访问地址');
    }

    return FileCenterUploadResult(
      fileId: fileId,
      publicUrl: resolvedPublic,
      objectKey: objectKey,
      displayUrl: _firstUrl([
        detail?.displayUrl,
        detail?.previewUrl,
        detail?.thumbnailUrl,
        uploaded.displayUrl,
        uploaded.previewUrl,
        uploaded.thumbnailUrl,
        resolvedPublic,
      ]),
      previewUrl: _firstUrl([
        detail?.previewUrl,
        detail?.displayUrl,
        uploaded.previewUrl,
        uploaded.displayUrl,
        resolvedPublic,
      ]),
      relativeUrl: _firstNonEmpty([
        detail?.relativeUrl,
        detail?.objectRelativeUrl,
        uploaded.relativeUrl,
        uploaded.objectRelativeUrl,
        objectKey,
      ]),
      detail: detail,
    );
  }

  Future<FileDetailVo> fetchInfo(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty) {
      throw FileCenterApiException('fileId 为空');
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.fileCenterInfo(id)}',
    );
    final map = await _getDataMap(uri);
    return _detailFromJson(map);
  }

  Future<FilePresignVo> _presign({
    required String filename,
    required String contentType,
    required String moduleCode,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.fileCenterPresign}',
    );
    final map = await _postDataMap(uri, {
      'filename': filename,
      'contentType': contentType,
      'moduleCode': moduleCode,
    });
    return _presignFromJson(map);
  }

  Future<String> _putToOss({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? headers,
  }) async {
    final merged = <String, String>{
      ...?headers,
      'Content-Type': contentType,
    };
    // OSS 预签名一般不带业务 Authorization。
    merged.remove('Authorization');
    merged.remove('authorization');

    final response = await ApiHttp.put(
      Uri.parse(uploadUrl),
      headers: merged,
      body: bytes,
      timeout: const Duration(minutes: 2),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FileCenterApiException('OSS 直传失败：HTTP ${response.statusCode}');
    }
    final etag = _parseEtag(response);
    if (etag == null || etag.isEmpty) {
      throw FileCenterApiException('OSS 直传成功但未返回 ETag');
    }
    return etag;
  }

  Future<FileUploadVo> _directComplete({
    required String objectKey,
    required String fileUrl,
    required String name,
    required int size,
    required String mimeType,
    required String etag,
    required String moduleCode,
    required int folderId,
    required int width,
    required int height,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.fileCenterDirectComplete}',
    );
    final map = await _postDataMap(uri, {
      'objectKey': objectKey,
      'fileUrl': fileUrl,
      'name': name,
      'size': size,
      'mimeType': mimeType,
      'etag': _formatEtag(etag),
      'moduleCode': moduleCode,
      'folderId': folderId,
      'width': width,
      'height': height,
    });
    return _uploadFromJson(map);
  }

  Future<Map<String, dynamic>> _postDataMap(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await ApiHttp.post(
        uri,
        headers: AuthSession.headers(json: true),
        body: jsonEncode(body),
        timeout: const Duration(seconds: 60),
      );
      return _decodeBizData(response, failMessage: '文件中心请求失败');
    } on FileCenterApiException {
      rethrow;
    } catch (e) {
      if (e is FileCenterApiException) rethrow;
      throw FileCenterApiException('网络请求失败：$e');
    }
  }

  Future<Map<String, dynamic>> _getDataMap(Uri uri) async {
    try {
      final response = await ApiHttp.get(
        uri,
        headers: AuthSession.headers(),
        timeout: const Duration(seconds: 30),
      );
      return _decodeBizData(response, failMessage: '查询文件详情失败');
    } on FileCenterApiException {
      rethrow;
    } catch (e) {
      if (e is FileCenterApiException) rethrow;
      throw FileCenterApiException('网络请求失败：$e');
    }
  }

  Map<String, dynamic> _decodeBizData(
    http.Response response, {
    required String failMessage,
  }) {
    if (response.body.isEmpty) {
      throw FileCenterApiException('服务器返回为空');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw FileCenterApiException('服务器返回数据格式错误');
    }
    if (response.statusCode == 401) {
      throw FileCenterApiException(
        decoded['msg']?.toString() ?? '未登录或登录已过期',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FileCenterApiException(
        decoded['msg']?.toString() ?? '请求失败(${response.statusCode})',
      );
    }
    final code = decoded['code'];
    final ok = code == null || code == 200 || code == 0 || code == '200';
    if (!ok) {
      throw FileCenterApiException(
        decoded['msg']?.toString() ?? failMessage,
      );
    }
    final data = decoded['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  static String? _parseEtag(http.Response response) {
    final raw = response.headers['etag'] ?? response.headers['ETag'];
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  static String _formatEtag(String etag) {
    final t = etag.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) return t;
    return '"$t"';
  }

  static String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  static Future<({int width, int height})?> _readImageSize(
    Uint8List bytes,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (width: image.width, height: image.height);
      image.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  static String? _firstUrl(List<String?> candidates) {
    for (final c in candidates) {
      final v = c?.trim();
      if (v == null || v.isEmpty) continue;
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
    }
    return _firstNonEmpty(candidates);
  }

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final c in candidates) {
      final v = c?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static FilePresignVo _presignFromJson(Map<String, dynamic> json) {
    Map<String, String>? headers;
    final rawHeaders = json['headers'];
    if (rawHeaders is Map) {
      headers = {
        for (final e in rawHeaders.entries)
          if (e.key != null && e.value != null)
            e.key.toString(): e.value.toString(),
      };
    }
    return FilePresignVo()
      ..uploadUrl = _asString(json['uploadUrl'])
      ..objectKey = _asString(json['objectKey'])
      ..contentType = _asString(json['contentType'])
      ..expires = _asInt(json['expires'])
      ..accessKeyId = _asString(json['accessKeyId'])
      ..expiresAt = _asInt(json['expiresAt'])
      ..signature = _asString(json['signature'])
      ..headers = headers
      ..publicUrl = _asString(json['publicUrl'])
      ..moduleCode = _asString(json['moduleCode'])
      ..categoryCode = _asString(json['categoryCode'])
      ..folderId = _asInt(json['folderId']);
  }

  static FileUploadVo _uploadFromJson(Map<String, dynamic> json) {
    return FileUploadVo()
      ..fileId = _asString(json['fileId'])
      ..fileName = _asString(json['fileName'])
      ..originalName = _asString(json['originalName'])
      ..fileSuffix = _asString(json['fileSuffix'])
      ..fileSize = _asInt(json['fileSize'])
      ..contentType = _asString(json['contentType'])
      ..width = _asInt(json['width'])
      ..height = _asInt(json['height'])
      ..folderId = _asInt(json['folderId'])
      ..createTime = _asString(json['createTime'])
      ..status = _asInt(json['status'])
      ..previewUrl = _asString(json['previewUrl'])
      ..relativeUrl = _asString(json['relativeUrl'])
      ..objectUrl = _asString(json['objectUrl'])
      ..objectRelativeUrl = _asString(json['objectRelativeUrl'])
      ..displayUrl = _asString(json['displayUrl'])
      ..displayRelativeUrl = _asString(json['displayRelativeUrl'])
      ..thumbnailUrl = _asString(json['thumbnailUrl'])
      ..thumbnailRelativeUrl = _asString(json['thumbnailRelativeUrl'])
      ..url = _asString(json['url'])
      ..videoCoverUrl = _asString(json['videoCoverUrl'])
      ..videoCoverRelativeUrl = _asString(json['videoCoverRelativeUrl']);
  }

  static FileDetailVo _detailFromJson(Map<String, dynamic> json) {
    return FileDetailVo()
      ..fileId = _asString(json['fileId'])
      ..fileName = _asString(json['fileName'])
      ..originalName = _asString(json['originalName'])
      ..contentType = _asString(json['contentType'])
      ..fileSize = _asInt(json['fileSize'])
      ..width = _asInt(json['width'])
      ..height = _asInt(json['height'])
      ..status = _asInt(json['status'])
      ..objectKey = _asString(json['objectKey'])
      ..objectUrl = _asString(json['objectUrl'])
      ..objectRelativeUrl = _asString(json['objectRelativeUrl'])
      ..relativeUrl = _asString(json['relativeUrl'])
      ..url = _asString(json['url'])
      ..displayUrl = _asString(json['displayUrl'])
      ..displayRelativeUrl = _asString(json['displayRelativeUrl'])
      ..previewUrl = _asString(json['previewUrl'])
      ..thumbnailUrl = _asString(json['thumbnailUrl'])
      ..thumbnailRelativeUrl = _asString(json['thumbnailRelativeUrl']);
  }
}
