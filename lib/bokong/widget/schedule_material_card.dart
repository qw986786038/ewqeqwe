import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';

/// 排期广告物料卡片（与素材库 / 弹窗内网格一致）。
class ScheduleMaterialCard extends StatelessWidget {
  const ScheduleMaterialCard({
    super.key,
    required this.material,
    this.selected = false,
    this.fillCell = false,
    this.borderWidth = 1,
    this.onTap,
    this.onDoubleTap,
  });

  static const Color metaColor = Color(0xFF6B7280);
  static const double bottomHeight = 64;
  static const double thumbHeight = 206;
  static const double aspectRatio = 4 / 3;
  static const double width = thumbHeight * aspectRatio;
  static const double height = thumbHeight + bottomHeight;

  final LcdProgramMaterialEntity material;
  final bool selected;
  final bool fillCell;
  final double borderWidth;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final format = material.file_format?.trim().isNotEmpty == true
        ? material.file_format!.trim().toUpperCase()
        : null;
    final duration = adMediaDurationClock(
      material.media_duration ?? material.duration,
    );
    final title =
        material.media_title ?? material.order_no ?? material.media_no ?? '-';
    final metaTime =
        material.create_time ??
        material.order_detail_send_time ??
        material.start_time ??
        '-';
    final industry = material.customer_industry?.trim();
    final isWeb = isProgramMaterialWebPreview(material.media_type);
    final showPlay =
        isProgramMaterialVideoPreview(material.media_type) ||
        material.media_type == 5;
    final statusBadge = scheduleMaterialStatusBadge(material);

    final thumb = Stack(
      fit: StackFit.expand,
      children: [
        _ScheduleMaterialThumb(material: material, isWeb: isWeb),
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
      ],
    );

    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        spacing: 6,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.label(title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        borderWidth: borderWidth,
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
                    SizedBox(height: thumbHeight, child: thumb),
                    footer,
                  ],
                ),
              ),
      ),
    );
  }
}

Widget? scheduleMaterialStatusBadge(LcdProgramMaterialEntity material) {
  if (material.is_delete == 1) {
    return const MediaThumbCornerStatusBadge(
      label: '已下刊',
      color: Color(0xFF6B7280),
    );
  }
  return switch (material.program_status) {
    2 => const MediaThumbCornerStatusBadge(
      label: '暂停',
      color: Color(0xFFF59E0B),
    ),
    3 => const MediaThumbCornerStatusBadge(
      label: '已结束',
      color: Color(0xFF6B7280),
    ),
    _ => const MediaThumbCornerStatusBadge(
      label: '播放中',
      color: Color(0xFF22C55E),
    ),
  };
}

class _ScheduleMaterialThumb extends StatelessWidget {
  const _ScheduleMaterialThumb({required this.material, required this.isWeb});

  final LcdProgramMaterialEntity material;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xFF94A3B8);
    final path = resolveProgramMaterialPreviewPath(material);
    final isVideo = isProgramMaterialVideoPreview(material.media_type);

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

    if (isProgramMaterialVideoPreview(material.media_type) ||
        isProgramMaterialWebPreview(material.media_type) ||
        isProgramMaterialPluginPreview(material.media_type, path)) {
      return ColoredBox(
        color: const Color(0xFFE8EEF3),
        child: Center(
          child: Icon(
            isWeb ? AppLucideIcons.globe : AppLucideIcons.circlePlay,
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
          return const ColoredBox(
            color: Color(0xFFE8EEF3),
            child: Center(
              child: Icon(AppLucideIcons.imageOff, size: 34, color: hintColor),
            ),
          );
        }
        return null;
      },
    );
  }
}
