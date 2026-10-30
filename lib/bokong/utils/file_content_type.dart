/// 根据文件名后缀推断 MIME 类型（媒体库上传预签名用）。
String? guessContentTypeFromFilename(String filename) {
  final int dot = filename.lastIndexOf('.');
  if (dot < 0 || dot >= filename.length - 1) return null;

  return switch (filename.substring(dot + 1).toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'svg' => 'image/svg+xml',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'avi' => 'video/x-msvideo',
    'mkv' => 'video/x-matroska',
    'webm' => 'video/webm',
    'm4v' => 'video/x-m4v',
    'flv' => 'video/x-flv',
    'wmv' => 'video/x-ms-wmv',
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'pdf' => 'application/pdf',
    _ => null,
  };
}

/// 根据 MIME 推断文件类型（与预签名 file_type_hint / direct_complete file_type 对齐）。
int? guessFileTypeFromMimeType(String mimeType) {
  final String lower = mimeType.toLowerCase();
  if (lower.startsWith('image/')) return 1;
  if (lower.startsWith('video/')) return 2;
  if (lower.startsWith('audio/')) return 3;
  return null;
}
