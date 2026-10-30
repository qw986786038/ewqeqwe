import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/theme/theme.dart';

WidgetStateProperty<Color?> _listItemOverlay() =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed))
        return const Color(0xFF4197FF).withValues(alpha: 0.10);
      if (states.contains(WidgetState.hovered))
        return const Color(0xFF4197FF).withValues(alpha: 0.06);
      if (states.contains(WidgetState.focused))
        return const Color(0xFF4197FF).withValues(alpha: 0.08);
      return null;
    });

/// 可点击的列表项，带 hover / 点击反馈。
class GlassListItem extends StatefulWidget {
  const GlassListItem({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.margin,
    this.boxShadow = const [],
    this.borderColor = Colors.transparent,
    this.trailing,
    this.hoverTrailing,
    this.cornerCheck = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  /// 描边色；默认透明。选中 / 悬停时不自动切换为主题色。
  final Color borderColor;

  /// 尾部（如箭头）；悬停且提供了 [hoverTrailing] 时替换为后者。
  final Widget? trailing;

  /// 鼠标划入时显示的尾部；仅在提供 [trailing] 时生效。
  final Widget? hoverTrailing;

  /// 为 true 且 [selected] 时，在左上角显示勾选角标。
  final bool cornerCheck;

  @override
  State<GlassListItem> createState() => _GlassListItemState();
}

class _GlassListItemState extends State<GlassListItem> {
  bool _hovered = false;

  /// 选中/悬停叠色必须为不透明色，否则 [AnimatedContainer] 在「半透明 primary ↔ 白」之间插值时
  /// 中间帧 alpha 升高，会出现「先变深再消失」。
  Color _surfaceColor(ThemeData theme) {
    const Color base = Colors.white;
    if (!widget.selected && !_hovered) return base;
    return Color.alphaBlend(
      theme.colorScheme.primary.withValues(
        alpha: widget.selected ? 0.12 : 0.08,
      ),
      base,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget item = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          overlayColor: _listItemOverlay(),
          child: widget.cornerCheck && widget.selected
              ? AppCornerBadge(
                  position: AppCornerBadgePosition.topLeft,
                  overlap: 1,
                  ignorePointer: true,
                  badge: AppBadge.custom(
                    color: kSelectedCornerBadgeColor,
                    appearance: AppBadgeStyle.solid,
                    shape: AppBadgeShape.square,
                    size: const AppBadgeSize(
                      fontSize: 10,
                      height: 16,
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      iconSize: 14,
                      contentGap: 0,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16),
                    ),
                    child: const Icon(Icons.check, color: Color(0xFFFFFFFF)),
                  ),
                  child: AppCard(
                    filled: true,
                    fillColor: _surfaceColor(theme),
                    borderColor: widget.borderColor,
                    child: _buildContent(),
                  ),
                )
              : AppCard(
                  filled: true,
                  fillColor: _surfaceColor(theme),
                  borderColor: widget.borderColor,
                  child: _buildContent(),
                ),
        ),
      ),
    );

    if (widget.margin == null) return item;
    return Padding(padding: widget.margin!, child: item);
  }

  Widget _buildContent() {
    final ThemeData theme = Theme.of(context);
    final TextStyle? baseTitle = theme.listTileTheme.titleTextStyle;
    final Widget? trailing = widget.trailing;

    final Widget body = trailing == null
        ? widget.child
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: widget.child),
              _hovered && widget.hoverTrailing != null
                  ? widget.hoverTrailing!
                  : trailing,
            ],
          );

    return Theme(
      data: theme.copyWith(
        listTileTheme: theme.listTileTheme.copyWith(
          titleTextStyle: baseTitle?.copyWith(
            color: widget.selected
                ? theme.colorScheme.primary
                : (baseTitle.color ?? Colors.black),
          ),
        ),
      ),
      child: body,
    );
  }
}
