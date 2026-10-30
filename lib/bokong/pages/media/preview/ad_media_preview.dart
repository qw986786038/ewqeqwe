import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/pages/preview/preview_image_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_plugin_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_video_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_webview.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 素材库「预览 / 详情」：图片 / 网页 / 视频（含直播）分流。
Future<void> showAdMediaPreviewDialog({
  required BuildContext context,
  required AdMediaEntity media,
}) async {
  final String? playPath = resolveAdMediaPlayPath(media);
  if (playPath == null) {
    showWarn('暂无预览地址');
    return;
  }

  if (media.media_type == 1) {
    await showImagePreviewDialog(
      context: context,
      imagePath: playPath,
      title: adMediaPreviewTitle(media),
    );
    return;
  }

  if (isProgramMaterialPluginPreview(media.media_type, playPath)) {
    await showPluginPreviewDialog(
      context: context,
      path: playPath,
      title: adMediaPreviewTitle(media),
    );
    return;
  }

  if (isProgramMaterialWebPreview(media.media_type) || media.media_type == 6) {
    await showWebPreviewDialog(
      context: context,
      url: playPath,
      title: adMediaPreviewTitle(media),
    );
    return;
  }

  if (isProgramMaterialVideoPreview(media.media_type)) {
    await showVideoPreviewDialog(
      context: context,
      videoPath: playPath,
      title: adMediaPreviewTitle(media),
    );
    return;
  }

  final String? thumbPath = resolveAdMediaPreviewPath(media);
  if (thumbPath != null) {
    await showImagePreviewDialog(
      context: context,
      imagePath: thumbPath,
      title: adMediaPreviewTitle(media),
    );
    return;
  }

  showWarn('暂不支持该类型预览');
}

/// 选择素材列表里的小缩略图；点击打开预览，不触发父级选中手势。
class AdMediaListThumb extends StatelessWidget {
  const AdMediaListThumb({required this.media, this.size = 40, super.key});

  final AdMediaEntity media;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = isProgramMaterialWebPreview(media.media_type);
    final String? thumb = resolveAdMediaGridThumbPath(media);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAdMediaPreviewDialog(context: context, media: media),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: _buildThumbContent(context, isWeb: isWeb, path: thumb),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbContent(
    BuildContext context, {
    required bool isWeb,
    required String? path,
  }) {
    if (path == null || path.isEmpty) {
      return Center(
        child: Icon(
          isWeb ? Icons.language_outlined : Icons.perm_media_outlined,
          size: size * 0.45,
          color: Theme.of(context).hintColor,
        ),
      );
    }

    return ExtendedImage.network(
      path,
      fit: BoxFit.cover,
      width: size,
      height: size,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.loading) {
          return const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (state.extendedImageLoadState == LoadState.failed) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: size * 0.45,
              color: Theme.of(context).hintColor,
            ),
          );
        }
        return null;
      },
    );
  }
}
