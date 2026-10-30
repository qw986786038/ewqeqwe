import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 素材缩略图角标（分辨率 / 格式 / 时长 / 删除 / 状态）统一规格。
abstract final class MediaThumbOverlayBadge {
  static const color = Color(0x80000000);

  static const borderRadius = BorderRadius.all(Radius.circular(6));

  static const boxHeight = 24.0;

  static const horizontalPadding = 6.0;

  static const fontSize = 12.0;

  static const verticalPadding = (boxHeight - fontSize) / 2;

  /// 删除角标边长（与文案角标 [boxHeight] 对齐）。
  static const deleteBoxSize = boxHeight;

  static const deleteIconSize = 14.0;

  static const deleteBorderRadius = borderRadius;

  /// 表单小缩略图「移除」角标边长（相对更小缩略图）。
  static const removeBoxSize = 16.0;

  static const removeIconSize = 10.0;

  /// 左上角状态角标：仅右下圆角，与卡片裁切配合。
  static const cornerStatusRadius = BorderRadius.only(
    bottomRight: Radius.circular(12),
  );

  static const cornerStatusHorizontalPadding = 12.0;

  /// 素材 item 中央播放按钮边长。
  static const playIconSize = 36.0;

  /// 素材 item 标题旁编辑图标边长。
  static const editIconSize = 14.0;
}

/// 半透明文案角标（分辨率 / 格式 / 时长）：固定高度 24，宽度随内容。
class MediaThumbOverlayTextBadge extends StatelessWidget {
  const MediaThumbOverlayTextBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: MediaThumbOverlayBadge.color,
        borderRadius: MediaThumbOverlayBadge.borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MediaThumbOverlayBadge.horizontalPadding,
          vertical: MediaThumbOverlayBadge.verticalPadding,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: MediaThumbOverlayBadge.fontSize,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 左上角状态角标：实心色（播放中绿 / 已暂停红 / 已完播·已下刊灰），固定高度 24。
class MediaThumbCornerStatusBadge extends StatelessWidget {
  const MediaThumbCornerStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: MediaThumbOverlayBadge.cornerStatusRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MediaThumbOverlayBadge.cornerStatusHorizontalPadding,
          vertical: MediaThumbOverlayBadge.verticalPadding,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: MediaThumbOverlayBadge.fontSize,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 素材 item 缩略图中央播放按钮：固定 [MediaThumbOverlayBadge.playIconSize]。
class MediaThumbPlayOverlay extends StatelessWidget {
  const MediaThumbPlayOverlay({super.key});

  static const assetPath = 'assets/images/media_play_icon.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: MediaThumbOverlayBadge.playIconSize,
      height: MediaThumbOverlayBadge.playIconSize,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// 素材 / 发布单等「笔+横线」编辑图标（自定义资源，非整套 Lucide）。
///
/// 传入 [onPressed] 时自带 [AppInkWell] 与内边距，避免悬停高亮贴死图标。
class MediaEditIcon extends StatelessWidget {
  const MediaEditIcon({
    super.key,
    this.size = MediaThumbOverlayBadge.editIconSize,
    this.color,
    this.onPressed,
  });

  static const assetPath = 'assets/images/media_edit_icon.png';

  final double size;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
    if (color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }
    if (onPressed == null) return image;
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(padding: const EdgeInsets.all(4), child: image),
    );
  }
}

/// 素材缩略图删除按钮：半透明底 + 垃圾桶，固定 [MediaThumbOverlayBadge.deleteBoxSize]。
class MediaThumbDeleteButton extends StatelessWidget {
  const MediaThumbDeleteButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: MediaThumbOverlayBadge.deleteBorderRadius,
      child: Container(
        width: MediaThumbOverlayBadge.deleteBoxSize,
        height: MediaThumbOverlayBadge.deleteBoxSize,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: MediaThumbOverlayBadge.color,
          borderRadius: MediaThumbOverlayBadge.deleteBorderRadius,
        ),
        child: const Icon(
          AppLucideIcons.trash2,
          size: MediaThumbOverlayBadge.deleteIconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 表单小缩略图右上角移除角标：红色圆形减号（配合 [AppCornerBadge]）。
class MediaThumbRemoveBadge extends StatelessWidget {
  const MediaThumbRemoveBadge({
    super.key,
    required this.onPressed,
    this.tooltip = '移除素材',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return AppTooltip(
      tooltip: (_) => Text(tooltip),
      child: AppInkWell(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(
          MediaThumbOverlayBadge.removeBoxSize / 2,
        ),
        child: Container(
          width: MediaThumbOverlayBadge.removeBoxSize,
          height: MediaThumbOverlayBadge.removeBoxSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.destructive,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            AppLucideIcons.minus,
            size: MediaThumbOverlayBadge.removeIconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
