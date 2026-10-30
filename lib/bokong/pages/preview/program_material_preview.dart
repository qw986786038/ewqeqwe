import 'package:flutter/material.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/pages/preview/preview_image_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_plugin_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_video_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_webview.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 解析排期素材预览地址（使用 media_file_path）。
String? resolveProgramMaterialPreviewPath(LcdProgramMaterialEntity material) {
  final String? path = material.media_file_path?.trim();
  if (path == null || path.isEmpty) return null;
  return path;
}

bool isProgramMaterialWebPreview(int? mediaType) {
  switch (mediaType) {
    case 4: // 网页 / 水牌
      return true;
    default:
      return false;
  }
}

/// 插件入口是否为 ES Module（`.mjs`）。
bool isPluginMjsPreviewPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  final resourcePath = (uri != null && uri.path.isNotEmpty ? uri.path : trimmed)
      .toLowerCase();
  return resourcePath.endsWith('.mjs');
}

/// 插件素材预览：media_type == 6 且入口为 `.mjs`。
bool isProgramMaterialPluginPreview(int? mediaType, String path) =>
    mediaType == 6 && isPluginMjsPreviewPath(path);

/// 视频与直播同属视频预览。
bool isProgramMaterialVideoPreview(int? mediaType) {
  switch (mediaType) {
    case 2: // 视频
    case 5: // 直播
      return true;
    default:
      return false;
  }
}

String _resourcePathLower(String path) {
  final trimmed = path.trim();
  final uri = Uri.tryParse(trimmed);
  return (uri != null && uri.path.isNotEmpty ? uri.path : trimmed)
      .toLowerCase();
}

/// 接口尚未返回 [media_type] 时，按路径后缀临时推断（对齐素材库类型）。
int? inferMediaTypeFromPath(String path) {
  final resource = _resourcePathLower(path);
  if (resource.endsWith('.mjs')) return 6;
  if (RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp|svg)(\?|#|$)').hasMatch(resource)) {
    return 1;
  }
  if (RegExp(r'\.(mp4|webm|mov|m3u8|mkv|avi)(\?|#|$)').hasMatch(resource)) {
    return 2;
  }
  // 无后缀的 http(s) 地址（如水牌站点）按网页处理。
  final uri = Uri.tryParse(path.trim());
  if (uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty) {
    return 4;
  }
  return null;
}

String _videoPreviewTitle(LcdProgramMaterialEntity material) {
  if (material.media_title?.isNotEmpty == true) return material.media_title!;
  switch (material.media_type) {
    case 5:
      return '直播预览';
    default:
      return '视频预览';
  }
}

String _webPreviewTitle(LcdProgramMaterialEntity material) {
  if (material.media_title?.isNotEmpty == true) return material.media_title!;
  return '网页预览';
}

/// 按素材类型分流预览（与素材库一致）；[mediaType] 为空时按路径推断。
Future<void> showMediaPathPreviewDialog({
  required BuildContext context,
  required String path,
  int? mediaType,
  String? title,
  String? deviceNo,
}) async {
  final String previewPath = path.trim();
  if (previewPath.isEmpty) {
    showWarn('暂无预览地址');
    return;
  }
  final int? type = mediaType ?? inferMediaTypeFromPath(previewPath);

  if (type == 1) {
    await showImagePreviewDialog(
      context: context,
      imagePath: previewPath,
      title: title ?? '图片预览',
    );
    return;
  }

  if (isProgramMaterialPluginPreview(type, previewPath)) {
    await showPluginPreviewDialog(
      context: context,
      path: previewPath,
      title: title ?? '插件预览',
    );
    return;
  }

  if (isProgramMaterialWebPreview(type) || type == 6) {
    await showWebPreviewDialog(
      context: context,
      url: previewPath,
      title: title ?? '网页预览',
      deviceNo: deviceNo,
    );
    return;
  }

  if (isProgramMaterialVideoPreview(type)) {
    await showVideoPreviewDialog(
      context: context,
      videoPath: previewPath,
      title: title ?? (type == 5 ? '直播预览' : '视频预览'),
    );
    return;
  }

  showWarn('暂不支持该类型预览');
}

/// 内嵌预览（侧边栏等）；类型分流与 [showMediaPathPreviewDialog] 一致。
Widget buildMediaPathPreview({
  required String path,
  int? mediaType,
  Key? key,
  bool fitWebViewport = false,
  String? deviceNo,
}) {
  final String previewPath = path.trim();
  final int? type = mediaType ?? inferMediaTypeFromPath(previewPath);
  final Key viewKey = key ?? ValueKey('media-preview-$type-$previewPath');

  if (type == 1) {
    return PreviewImageView(key: viewKey, imagePath: previewPath);
  }
  if (isProgramMaterialPluginPreview(type, previewPath)) {
    return PreviewPluginView(key: viewKey, path: previewPath);
  }
  if (isProgramMaterialWebPreview(type) || type == 6) {
    return PreviewWebView(
      key: viewKey,
      url: previewPath,
      fitViewport: fitWebViewport,
      deviceNo: deviceNo,
    );
  }
  if (isProgramMaterialVideoPreview(type)) {
    return PreviewVideoView(key: viewKey, videoPath: previewPath);
  }
  return const SizedBox.shrink();
}

/// 排期素材列表「预览」：图片 / 网页 / 视频（含直播）分流。
Future<void> showProgramMaterialPreviewDialog({
  required BuildContext context,
  required LcdProgramMaterialEntity material,
}) async {
  final String? previewPath = resolveProgramMaterialPreviewPath(material);
  if (previewPath == null) {
    showWarn('暂无预览地址');
    return;
  }

  if (material.media_type == 1) {
    await showImagePreviewDialog(
      context: context,
      imagePath: previewPath,
      title: material.media_title ?? '图片预览',
    );
    return;
  }

  if (isProgramMaterialPluginPreview(material.media_type, previewPath)) {
    await showPluginPreviewDialog(
      context: context,
      path: previewPath,
      title: material.media_title ?? '插件预览',
    );
    return;
  }

  if (isProgramMaterialWebPreview(material.media_type) ||
      material.media_type == 6) {
    await showWebPreviewDialog(
      context: context,
      url: previewPath,
      title: _webPreviewTitle(material),
    );
    return;
  }

  if (isProgramMaterialVideoPreview(material.media_type)) {
    await showVideoPreviewDialog(
      context: context,
      videoPath: previewPath,
      title: _videoPreviewTitle(material),
    );
    return;
  }

  showWarn('暂不支持该类型预览');
}
