import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/pages/preview/preview_image_view.dart';
import 'package:yidivination/bokong/pages/preview/preview_video_view.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 增值服务素材预览项。
class OrderVasMediaViewItem {
  const OrderVasMediaViewItem({
    required this.displayPath,
    this.isVideo = false,
    this.duration,
    this.name,
  });

  /// 本地路径或公网 URL。
  final String displayPath;
  final bool isVideo;
  final String? duration;
  final String? name;

  bool get isRemote =>
      displayPath.startsWith('http://') || displayPath.startsWith('https://');
}

/// 打开增值服务素材查看弹窗。
void showOrderVasMediaDialog(
  BuildContext context, {
  required List<OrderVasMediaViewItem> items,
  String title = '查看素材',
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1080, initialHeight),
    builder: (_) => OrderVasMediaDialog(items: items, title: title),
  );
}

/// 增值服务素材弹窗：缩略图网格，双击预览。
class OrderVasMediaDialog extends StatelessWidget {
  const OrderVasMediaDialog({
    required this.items,
    this.title = '查看素材',
    super.key,
  });

  final List<OrderVasMediaViewItem> items;
  final String title;

  Future<void> _preview(
    BuildContext context,
    OrderVasMediaViewItem item,
  ) async {
    final path = item.displayPath.trim();
    if (path.isEmpty) {
      showWarn('暂无预览地址');
      return;
    }
    final label = item.name?.trim();
    final previewTitle = (label != null && label.isNotEmpty)
        ? label
        : (item.isVideo ? '视频预览' : '图片预览');
    if (item.isVideo) {
      await showVideoPreviewDialog(
        context: context,
        videoPath: path,
        title: previewTitle,
      );
      return;
    }
    await showImagePreviewDialog(
      context: context,
      imagePath: path,
      title: previewTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: Text(title),
      constraints: const BoxConstraints(maxWidth: 1080),
      content: SizedBox(
        width: 1040,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: items.isEmpty
                    ? const Center(child: AppEmptyState())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 16.0;
                          const minWidth = 180.0;
                          final cols =
                              ((constraints.maxWidth + gap) / (minWidth + gap))
                                  .floor()
                                  .clamp(1, 5);
                          final itemWidth =
                              (constraints.maxWidth - gap * (cols - 1)) / cols;

                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (var i = 0; i < items.length; i++)
                                AppCard(
                                  borderWidth: 0,
                                  padding: EdgeInsets.zero,
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 16 / 10,
                                        child: AppInkWell(
                                          onDoubleTap: () =>
                                              _preview(context, items[i]),
                                          child: _VasMediaPreviewThumb(
                                            item: items[i],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          10,
                                          10,
                                          12,
                                        ),
                                        child: Column(
                                          spacing: 4,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppText.label(
                                              items[i].name
                                                          ?.trim()
                                                          .isNotEmpty ==
                                                      true
                                                  ? items[i].name!.trim()
                                                  : '素材${i + 1}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            AppText.caption(
                                              items[i].displayPath,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: colors.mutedForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ).width(itemWidth),
                            ],
                          ).scroll();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }
}

class _VasMediaPreviewThumb extends StatelessWidget {
  const _VasMediaPreviewThumb({required this.item});

  final OrderVasMediaViewItem item;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final path = item.displayPath.trim();
    final remote = item.isRemote ? path : null;
    final file = remote == null && path.isNotEmpty ? File(path) : null;
    final exists = file?.existsSync() == true;

    Widget preview;
    if (!item.isVideo && remote != null) {
      preview = ExtendedImage.network(
        remote,
        fit: BoxFit.cover,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.completed) {
            return null;
          }
          return ColoredBox(
            color: colors.muted,
            child: Icon(
              AppLucideIcons.image,
              size: 36,
              color: colors.mutedForeground,
            ).center(),
          );
        },
      );
    } else if (!item.isVideo && exists) {
      preview = ExtendedImage(
        image: FileImage(file!),
        fit: BoxFit.cover,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.completed) {
            return null;
          }
          return ColoredBox(
            color: colors.muted,
            child: Icon(
              AppLucideIcons.image,
              size: 36,
              color: colors.mutedForeground,
            ).center(),
          );
        },
      );
    } else {
      preview = ColoredBox(
        color: const Color(0xFF64748B),
        child: Icon(
          item.isVideo ? AppLucideIcons.video : AppLucideIcons.image,
          size: 36,
          color: const Color(0x66FFFFFF),
        ).center(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        if (item.isVideo) const Center(child: MediaThumbPlayOverlay()),
        if (item.duration != null && item.duration!.isNotEmpty)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: MediaThumbOverlayTextBadge(label: item.duration!),
            ),
          ),
      ],
    );
  }
}
