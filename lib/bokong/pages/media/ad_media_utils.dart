import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';

String adMediaTypeLabel(int? mediaType) {
  return switch (mediaType) {
    1 => '图片',
    2 => '视频',
    4 => '网页',
    5 => '直播',
    6 => '插件',
    _ => '其他',
  };
}

String adMediaStatusLabel(int? status) {
  return switch (status) {
    1 => '启用',
    0 => '停用',
    _ => '未知',
  };
}

String adMediaPushStatusLabel(int? pushStatus) {
  return switch (pushStatus) {
    1 => '已推送',
    0 => '待推送',
    _ => '未知',
  };
}

String adMediaResolution(AdMediaEntity media) {
  final int? width = media.screen_width;
  final int? height = media.screen_height;
  if (width == null || height == null) return '-';
  return '${width}x$height';
}

String adMediaDurationLabel(int? seconds) {
  if (seconds == null || seconds <= 0) return '-';
  return '$seconds 秒';
}

/// 网格卡片角标：mm:ss。
String adMediaDurationClock(int? seconds) {
  if (seconds == null || seconds <= 0) return '';
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String adMediaFileSizeLabel(String? size) {
  final String value = size?.trim() ?? '';
  if (value.isEmpty) return '';
  final String lower = value.toLowerCase();
  if (lower.endsWith('b') ||
      lower.endsWith('kb') ||
      lower.endsWith('mb') ||
      lower.endsWith('gb')) {
    return value;
  }
  return '${value}MB';
}

bool adMediaIsWebType(int? mediaType) =>
    mediaType == 4 || mediaType == 5 || mediaType == 6;

bool adMediaShowPlayOverlay(int? mediaType) => mediaType == 2 || mediaType == 5;

/// 解析素材预览地址（优先 [preview_path]，否则 [file_path]）。
String? resolveAdMediaPreviewPath(AdMediaEntity media) {
  final String? preview = media.preview_path?.trim();
  if (preview != null && preview.isNotEmpty) return preview;
  final String? file = media.file_path?.trim();
  if (file != null && file.isNotEmpty) return file;
  return null;
}

/// 素材播放/预览地址（使用 [file_path]）。
String? resolveAdMediaPlayPath(AdMediaEntity media) {
  final String? path = media.file_path?.trim();
  if (path == null || path.isEmpty) return null;
  return path;
}

/// 网格缩略图地址（网页类不展示预览图）。
String? resolveAdMediaGridThumbPath(AdMediaEntity media) {
  if (isProgramMaterialWebPreview(media.media_type)) return null;
  return resolveAdMediaPreviewPath(media);
}

String adMediaPreviewTitle(AdMediaEntity media) {
  if (media.title?.isNotEmpty == true) return media.title!;
  if (media.media_no?.isNotEmpty == true) return media.media_no!;
  return '素材预览';
}

String? validateAdMediaUrl(String? value) {
  final String url = value?.trim() ?? '';
  if (url.isEmpty) return '请输入 URL';
  final Uri? uri = Uri.tryParse(url);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return '请输入有效的 URL';
  }
  return null;
}
