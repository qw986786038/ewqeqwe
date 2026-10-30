import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:yidivination/bokong/entity/lcd/lcd_device_scene_pic_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_picked_file.dart';
import 'package:yidivination/bokong/pages/preview/preview_image_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_video_view.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 现场照片允许上传的扩展名（小写、不含点）。
const kLcdDeviceScenePicUploadExtensions = [
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'mp4',
  'mov',
  'avi',
  'mkv',
  'webm',
  'm4v',
  'flv',
  'wmv',
];

/// 合并为 [scene_pic] 字段值。
String? lcdDeviceScenePicValue(List<String> paths) {
  if (paths.isEmpty) return '';
  return paths.join(',');
}

/// 从列表项提取 [scene_pic] 字段值。
String? lcdDeviceScenePicValueFromItems(List<LcdDeviceScenePicEntity> items) {
  final paths = items
      .map((e) => e.path?.trim())
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .toList();
  return lcdDeviceScenePicValue(paths);
}

/// 上传完成后写入 [scene_pic] 的存储路径（与接口 `/media/...` 格式一致）。
String lcdDeviceScenePicStoragePath(AdMediaPickedFile file) {
  final key = file.objectKey?.trim();
  if (key != null && key.isNotEmpty) {
    return key.startsWith('/') ? key : '/$key';
  }
  final url = file.publicUrl?.trim();
  if (url != null && url.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.path.isNotEmpty) return uri.path;
  }
  throw StateError('无法解析上传文件路径');
}

/// 选择现场照片 / 视频文件，返回本地路径。
Future<String?> pickLcdDeviceScenePicFilePath() async {
  // 让出一帧，避免嵌套弹窗刚刷新完立刻调原生选择器失败。
  await Future<void>.delayed(Duration.zero);
  try {
    await FilePicker.clearTemporaryFiles();
  } catch (_) {}

  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: kLcdDeviceScenePicUploadExtensions,
    dialogTitle: '选择照片或视频',
    windowsOptions: const WindowsOptions(lockParentWindow: true),
  );
  if (file == null) return null;
  final path = file.path;
  if (path == null || path.isEmpty) return null;

  final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
  if (!kLcdDeviceScenePicUploadExtensions.contains(ext)) return null;
  return path;
}

const _kLcdDeviceScenePicVideoExtensions = [
  '.mp4',
  '.mov',
  '.avi',
  '.webm',
  '.mkv',
  '.m4v',
  '.flv',
  '.wmv',
];

/// 现场照片/视频预览地址（优先 [url]，否则 [path]）。
String? resolveLcdDeviceScenePicPreviewPath(LcdDeviceScenePicEntity item) {
  final url = item.url?.trim();
  if (url != null && url.isNotEmpty) return url;
  final path = item.path?.trim();
  if (path != null && path.isNotEmpty) return path;
  return null;
}

bool isLcdDeviceScenePicVideo(LcdDeviceScenePicEntity item) {
  final kind = item.kind?.trim().toLowerCase();
  if (kind == 'video') return true;
  final source = (item.path ?? item.url ?? item.name ?? '').toLowerCase();
  return _kLcdDeviceScenePicVideoExtensions.any(source.endsWith);
}

String lcdDeviceScenePicPreviewTitle(LcdDeviceScenePicEntity item) {
  final name = item.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return isLcdDeviceScenePicVideo(item) ? '视频预览' : '图片预览';
}

Future<void> showLcdDeviceScenePicPreview({
  required BuildContext context,
  required LcdDeviceScenePicEntity item,
}) async {
  final previewPath = resolveLcdDeviceScenePicPreviewPath(item);
  if (previewPath == null) {
    showWarn('暂无预览地址');
    return;
  }

  final title = lcdDeviceScenePicPreviewTitle(item);
  if (isLcdDeviceScenePicVideo(item)) {
    await showVideoPreviewDialog(
      context: context,
      videoPath: previewPath,
      title: title,
    );
    return;
  }

  await showImagePreviewDialog(
    context: context,
    imagePath: previewPath,
    title: title,
  );
}
