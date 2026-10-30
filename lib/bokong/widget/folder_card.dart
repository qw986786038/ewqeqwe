import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/theme/theme.dart';

/// 文件夹造型卡片（页签 + 白底主体）。
///
/// 待上游：建议 `lemon_shadcn` 提供 `AppFolderCard` / `AppCard.folder`。
///
/// ```dart
/// FolderCard(
///   color: Colors.teal,
///   selected: selected,
///   onPressed: onSelect,
///   onDoubleTap: onOpen,
///   child: Column(...),
/// )
/// ```
class FolderCard extends StatelessWidget {
  const FolderCard({
    required this.child,
    this.color,
    this.tabColor = const Color(0xFFE5E6EB),
    this.tabGradient,
    this.idleTabGradient,
    this.selected = false,
    this.onPressed,
    this.onDoubleTap,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.tabHeight = 14,
    this.tabWidthFactor = 0.4,
    this.borderRadius,
    super.key,
  });

  /// 内容区（白底内）。
  final Widget child;

  /// 选中描边 / 角标 / 浅底用的主题色；默认 primary。
  final Color? color;

  /// 未选中页签色；选中时改用 [color] 主题蓝。
  final Color tabColor;

  /// 选中页签的渐变色；为空时选中页签用 [color] 纯色。
  final Gradient? tabGradient;

  /// 未选中页签的渐变色；为空时未选中页签用 [tabColor] 纯色。
  final Gradient? idleTabGradient;

  /// 选中时加粗强调色描边。
  final bool selected;

  final VoidCallback? onPressed;
  final VoidCallback? onDoubleTap;

  final EdgeInsetsGeometry padding;

  /// 页签凸出高度（白卡上方可见部分）。
  final double tabHeight;

  /// 左侧高页签宽度占比。
  final double tabWidthFactor;

  final BorderRadius? borderRadius;

  /// 网格推荐高度（含页签）。
  static const preferredHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadcnTheme.of(context);
    final colors = theme.colorScheme;
    final accent = color ?? colors.primary;
    final radius = borderRadius ?? BorderRadius.circular(theme.radiusMd);
    final corner = radius.topLeft.x;
    // 选中：蓝页签（渐变色优先）+ 主色 3% 浅底 + 描边/角标；未选中：灰页签（渐变色优先）+ 白底。
    final effectiveTabColor = selected ? accent : tabColor;
    final effectiveTabGradient = selected ? tabGradient : idleTabGradient;
    final bodyColor = selected
        ? Color.lerp(colors.card, accent, 0.03) ?? colors.card
        : colors.card;
    final borderColor = selected ? accent : const Color(0xFFE5E6EB);
    const borderWidth = 1.0;
    final inkRadius = BorderRadius.only(
      topLeft: Radius.circular(corner + 2),
      topRight: Radius.circular(radius.topRight.x + 2),
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );
    // 蓝色背景必须伸进白卡至少一整段圆角半径，否则大圆角处会露出断层。
    final tabPaintHeight = tabHeight + corner;

    return AppInkWell(
      onPressed: onPressed,
      onDoubleTap: onDoubleTap,
      borderRadius: inkRadius,
      hoverOpacity: 0,
      pressedOpacity: 0,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: tabPaintHeight,
            child: CustomPaint(
              painter: _FolderTabPainter(
                color: effectiveTabColor,
                gradient: effectiveTabGradient,
                tabWidthFactor: tabWidthFactor,
                radius: corner,
              ),
            ),
          ),
          Positioned(
            top: tabHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: bodyColor,
                      borderRadius: radius,
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Padding(padding: padding, child: child),
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      // 外轮廓由 ClipRRect（白卡圆角）裁切，角标尺寸不变。
                      child: CustomPaint(
                        painter: const _FolderCornerCheckPainter(
                          color: kSelectedCornerBadgeColor,
                          innerRadius: 16,
                        ),
                        child: const SizedBox(
                          width: 30,
                          height: 24,
                          child: Padding(
                            padding: EdgeInsets.only(top: 8, right: 10),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Icon(
                                AppLucideIcons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 选中态右上角勾选块；外轮廓由白卡 ClipRRect 裁切，此处只画内侧圆角。
class _FolderCornerCheckPainter extends CustomPainter {
  const _FolderCornerCheckPainter({required this.color, this.innerRadius = 16});

  final Color color;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      bottomLeft: Radius.circular(innerRadius.clamp(0, size.shortestSide)),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _FolderCornerCheckPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.innerRadius != innerRadius;
  }
}

/// 左高右低、底部贯通的文件夹页签。
class _FolderTabPainter extends CustomPainter {
  const _FolderTabPainter({
    required this.color,
    required this.tabWidthFactor,
    required this.radius,
    this.gradient,
  });

  final Color color;

  /// 非空时以渐变着色（覆盖 [color]）。
  final Gradient? gradient;

  final double tabWidthFactor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tabW = (w * tabWidthFactor).clamp(56.0, w * 0.55);
    // 可见页签高度（白卡上方）；左上圆角用满卡片 radius，不再被可见高度压小。
    final visibleH = (h - radius).clamp(8.0, h);
    final r = radius.clamp(4.0, h - 2);
    // 右侧矮沿：偏下、偏细（相对白卡上方只留一条窄沿）。
    final ledgeTop = (visibleH * 0.78).clamp(8.0, visibleH * 0.88);
    // 右上圆角与卡片一致。
    final rRight = radius.clamp(4.0, (h - ledgeTop - 1).clamp(4.0, h));
    final curveW = (visibleH * 0.9).clamp(10.0, 22.0);
    final flatEnd = (tabW - curveW * 0.15).clamp(r + 8, w * 0.55);
    final curveEndX = (flatEnd + curveW).clamp(flatEnd + 10, w * 0.62);

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(flatEnd, 0)
      ..cubicTo(
        flatEnd + curveW * 0.38,
        0,
        curveEndX - curveW * 0.38,
        ledgeTop,
        curveEndX,
        ledgeTop,
      )
      ..lineTo(w - rRight, ledgeTop)
      ..quadraticBezierTo(w, ledgeTop, w, ledgeTop + rRight)
      ..lineTo(w, h)
      ..close();

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    final g = gradient;
    if (g != null) {
      paint.shader = g.createShader(Offset.zero & size);
    } else {
      paint.color = color;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FolderTabPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.gradient != gradient ||
        oldDelegate.tabWidthFactor != tabWidthFactor ||
        oldDelegate.radius != radius;
  }
}
