import 'package:dio/dio.dart';

/// The response and final local path of a directory-based download.
final class LemonDownloadResult {
  const LemonDownloadResult({required this.response, required this.savePath});

  final Response<dynamic> response;
  final String savePath;
}

/// Resolves an untrusted download filename using headers, URL and fallbacks.
abstract final class LemonDownloadFileName {
  static String resolve({
    required Headers headers,
    required String requestPath,
    String? fallbackFileName,
  }) {
    final disposition = headers.value('content-disposition');
    final effectiveUri = headers.value('uri') ?? requestPath;
    final candidates = <String?>[
      _encodedFromDisposition(disposition),
      _plainFromDisposition(disposition),
      _fromUri(effectiveUri),
      fallbackFileName,
    ];

    String? selected;
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        selected = candidate;
        break;
      }
    }

    selected ??= 'download_${DateTime.now().millisecondsSinceEpoch}';
    return _appendExtension(
      _sanitize(selected),
      headers.value(Headers.contentTypeHeader),
    );
  }

  static String? _encodedFromDisposition(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'''(?:^|;)\s*filename\*\s*=\s*(?:([^']*)'[^']*')?([^;]+)''',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;

    final charset = match.group(1)?.trim().toLowerCase();
    if (charset != null && charset.isNotEmpty && charset != 'utf-8') {
      return null;
    }
    final encoded = match.group(2)?.trim().replaceAll('"', '');
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return Uri.decodeComponent(encoded);
    } on FormatException {
      return null;
    }
  }

  static String? _plainFromDisposition(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'''(?:^|;)\s*filename\s*=\s*(?:"([^"]+)"|([^;]+))''',
      caseSensitive: false,
    ).firstMatch(value);
    return (match?.group(1) ?? match?.group(2))?.trim();
  }

  static String? _fromUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final segment = uri.pathSegments.last;
    if (segment.isEmpty) return null;
    try {
      return Uri.decodeComponent(segment);
    } on FormatException {
      return segment;
    }
  }

  static String _sanitize(String value) {
    var name = value.split(RegExp(r'[/\\]')).last.trim();
    name = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (name.isEmpty || name == '.' || name == '..') {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
    return name;
  }

  static String _appendExtension(String name, String? contentType) {
    if (RegExp(r'\.[A-Za-z0-9]{1,10}$').hasMatch(name)) return name;
    final mime = contentType?.split(';').first.trim().toLowerCase();
    return '$name${_extensions[mime] ?? '.bin'}';
  }

  static const _extensions = <String, String>{
    'application/pdf': '.pdf',
    'application/zip': '.zip',
    'application/json': '.json',
    'application/octet-stream': '.bin',
    'text/plain': '.txt',
    'text/csv': '.csv',
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'application/msword': '.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        '.docx',
    'application/vnd.ms-excel': '.xls',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        '.xlsx',
  };
}
