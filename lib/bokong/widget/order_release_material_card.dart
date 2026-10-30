import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';

/// 订单发布单物料卡片（与上方发布单列表联动选中；删除对应发布单行）。
class OrderReleaseMaterialCard extends StatelessWidget {
  const OrderReleaseMaterialCard({
    super.key,
    required this.item,
    this.selected = false,
    this.fillCell = false,
    this.industryLabel,
    this.onTap,
    this.onDoubleTap,
    this.onDelete,
    this.onEdit,
  });

  static const Color metaColor = Color(0xFF6B7280);
  static const double bottomHeight = 64;
  static const double thumbHeight = 206;
  static const double aspectRatio = 4 / 3;
  static const double width = thumbHeight * aspectRatio;
  static const double height = thumbHeight + bottomHeight;

  final OrderItemEntity item;
  final bool selected;
  final bool fillCell;
  final String? industryLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final format = orderReleaseMaterialFormat(item);
    final duration = adMediaDurationClock(item.duration);
    final title = orderReleaseMaterialTitle(item);
    final metaTime = orderReleaseMaterialTime(item);
    final statusBadge = orderReleaseMaterialStatusBadge(item: item);
    final isWeb = adMediaIsWebType(item.media_type);
    final showPlay = adMediaShowPlayOverlay(item.media_type);
    final industry = industryLabel?.trim();

    final thumb = Stack(
      fit: StackFit.expand,
      children: [
        _OrderReleaseMaterialThumb(item: item, isWeb: isWeb),
        if (statusBadge != null)
          Positioned(top: 0, left: 0, child: statusBadge),
        if (format != null)
          Positioned(
            top: 8,
            right: 8,
            child: MediaThumbOverlayTextBadge(label: format),
          ),
        if (showPlay) const Center(child: MediaThumbPlayOverlay()),
        if (duration.isNotEmpty || (industry != null && industry.isNotEmpty))
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(
              spacing: 6,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (duration.isNotEmpty)
                  MediaThumbOverlayTextBadge(label: duration),
                if (industry != null && industry.isNotEmpty)
                  MediaThumbOverlayTextBadge(label: industry),
              ],
            ),
          ),
        if (onDelete != null)
          Positioned(
            right: 8,
            bottom: 8,
            child: MediaThumbDeleteButton(onPressed: onDelete),
          ),
      ],
    );

    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        spacing: 6,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppText.label(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ).expanded(),
              if (onEdit != null)
                MediaEditIcon(onPressed: onEdit, color: metaColor),
            ],
          ),
          AppText.caption(metaTime, style: const TextStyle(color: metaColor)),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AppCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadow: false,
        borderWidth: 1,
        borderColor: selected ? const Color(0xFF22C55E) : colors.border,
        child: fillCell
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [thumb.expanded(), footer],
              )
            : SizedBox(
                width: width,
                height: height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 底部文案行高随字体略有浮动，缩略图吃剩余高度，避免 1px overflow。
                    thumb.expanded(),
                    footer,
                  ],
                ),
              ),
      ),
    );
  }
}

class _OrderReleaseMaterialThumb extends StatelessWidget {
  const _OrderReleaseMaterialThumb({required this.item, required this.isWeb});

  final OrderItemEntity item;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xFF94A3B8);
    final path = resolveOrderReleaseMaterialThumbPath(item);
    final isVideo = adMediaShowPlayOverlay(item.media_type);

    if (path == null || path.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFE8EEF3),
        child: Center(
          child: Icon(
            isWeb
                ? AppLucideIcons.globe
                : (isVideo ? AppLucideIcons.circlePlay : AppLucideIcons.image),
            size: 34,
            color: hintColor,
          ),
        ),
      );
    }

    return ExtendedImage.network(
      path,
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        if (state.extendedImageLoadState == LoadState.loading) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: AppCircularProgressIndicator(),
            ),
          );
        }
        if (state.extendedImageLoadState == LoadState.failed) {
          return ColoredBox(
            color: const Color(0xFFE8EEF3),
            child: Center(
              child: Icon(
                isVideo ? AppLucideIcons.circlePlay : AppLucideIcons.imageOff,
                size: 34,
                color: hintColor,
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}

/// 物料角标：已下刊优先；在刊物料显示绿色「播放中」（与设备 Tab 物料卡片一致）。
Widget? orderReleaseMaterialStatusBadge({required OrderItemEntity item}) {
  if (item.status == 3) {
    return const MediaThumbCornerStatusBadge(
      label: '已下刊',
      color: Color(0xFF6B7280),
    );
  }
  return const MediaThumbCornerStatusBadge(
    label: '播放中',
    color: Color(0xFF22C55E),
  );
}

String orderReleaseMaterialTitle(OrderItemEntity item) {
  final title = item.media_title?.trim();
  if (title != null && title.isNotEmpty) return title;
  if (item.media_id != null) return '素材 #${item.media_id}';
  return '未命名素材';
}

String orderReleaseMaterialTime(OrderItemEntity item) {
  final time =
      item.send_time?.trim() ??
      item.cover_start_time?.trim() ??
      item.start_time?.trim();
  if (time != null && time.isNotEmpty) return time;
  return adMediaTypeLabel(item.media_type);
}

String? orderReleaseMaterialFormat(OrderItemEntity item) {
  final path = item.file_path?.trim();
  if (path != null && path.contains('.')) {
    final ext = path.split('.').last.trim();
    if (ext.isNotEmpty) return ext.toUpperCase();
  }
  return switch (item.media_type) {
    2 => 'MP4',
    1 => 'IMG',
    _ => null,
  };
}

String? resolveOrderReleaseMaterialThumbPath(OrderItemEntity item) {
  if (isProgramMaterialWebPreview(item.media_type)) return null;
  final preview = item.preview_path?.trim();
  if (preview != null && preview.isNotEmpty) return preview;
  final file = item.file_path?.trim();
  if (file == null || file.isEmpty) return null;
  if (isProgramMaterialVideoPreview(item.media_type) ||
      isProgramMaterialPluginPreview(item.media_type, file)) {
    return null;
  }
  return file;
}

AdMediaEntity orderReleaseToAdMedia(OrderItemEntity item) {
  return AdMediaEntity()
    ..id = item.media_id
    ..title = item.media_title
    ..file_path = item.file_path
    ..preview_path = item.preview_path
    ..media_type = item.media_type
    ..duration = item.duration;
}
