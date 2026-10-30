import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:yidivination/bokong/api/system_file_api.dart';
import 'package:yidivination/bokong/entity/system/file_presign_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_upload.dart';
import 'package:yidivination/bokong/utils/file_content_type.dart';

/// 选中的本地文件及 OSS 上传结果。
class AdMediaPickedFile {
  AdMediaPickedFile({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.mediaType,
    required this.fileFormat,
    required this.fileSizeBytes,
    required this.presign,
    required this.etag,
    this.width,
    this.height,
  });

  final String localPath;
  final String fileName;
  final String mimeType;
  final int mediaType;
  final String fileFormat;
  final int fileSizeBytes;
  final FilePresignEntity presign;
  final String etag;
  final int? width;
  final int? height;

  String? get publicUrl => presign.public_url;
  String? get objectKey => presign.object_key;

  bool get isImage => mediaType == 1;

  /// 接口 [file_size] 使用 MB 数值（如 0.24）。
  double get fileSizeMb =>
      double.parse((fileSizeBytes / (1024 * 1024)).toStringAsFixed(2));

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String titleSuggestionFromPath(String path) =>
      p.basenameWithoutExtension(path);

  static Future<({int width, int height})?> _readImageSize(
    List<int> bytes,
  ) async {
    try {
      final Uint8List data = bytes is Uint8List
          ? bytes
          : Uint8List.fromList(bytes);
      final ui.Codec codec = await ui.instantiateImageCodec(data);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final int width = image.width;
      final int height = image.height;
      image.dispose();
      return (width: width, height: height);
    } catch (_) {
      return null;
    }
  }

  static Future<AdMediaPickedFile> pickUploadAndParse() async {
    final String? path = await pickAdMediaFilePath();
    if (path == null) {
      throw StateError('cancelled');
    }
    return loadUploadAndParse(path);
  }

  static Future<AdMediaPickedFile> loadUploadAndParse(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw StateError('文件不存在');
    }

    final String fileName = p.basename(path);
    final String mimeType =
        guessContentTypeFromFilename(fileName) ?? 'application/octet-stream';
    final int mediaType = guessFileTypeFromMimeType(mimeType) ?? 0;
    final String fileFormat = p
        .extension(fileName)
        .replaceFirst('.', '')
        .toUpperCase();
    final List<int> bytes = await file.readAsBytes();
    final int fileSizeBytes = bytes.length;

    int? width;
    int? height;
    if (mimeType.startsWith('image/')) {
      final ({int width, int height})? size = await _readImageSize(bytes);
      if (size != null) {
        width = size.width;
        height = size.height;
      }
    }

    final ({FilePresignEntity presign, String etag, String? message}) upload =
        await SystemFileApi.presignUploadAndComplete(
          filename: fileName,
          contentType: mimeType,
          bytes: bytes,
        );

    final String? publicUrl = upload.presign.public_url;
    if (publicUrl == null || publicUrl.isEmpty) {
      throw StateError('上传后文件地址为空');
    }

    return AdMediaPickedFile(
      localPath: path,
      fileName: fileName,
      mimeType: mimeType,
      mediaType: mediaType,
      fileFormat: fileFormat,
      fileSizeBytes: fileSizeBytes,
      presign: upload.presign,
      etag: upload.etag,
      width: width,
      height: height,
    );
  }
}
