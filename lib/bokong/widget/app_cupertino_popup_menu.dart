import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 苹果风格弹出菜单项。
class AppCupertinoPopupMenuItem<T> {
  const AppCupertinoPopupMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  final T value;
  final String label;

  /// 左侧图标；为 null 时仅显示文案。
  final IconData? icon;

  /// 为 true 时未悬停使用破坏性红色（如删除）；悬停后仍为白字蓝底。
  final bool destructive;
  final bool enabled;
}

/// 苹果风格 [PopupMenuButton]：圆角菜单、系统背景色、图标 + 蓝底悬停选中。
///
/// ```dart
/// AppCupertinoPopupMenu<String>(
///   items: const [
///     AppCupertinoPopupMenuItem(value: 'edit', label: '编辑', icon: CupertinoIcons.square_pencil),
///     AppCupertinoPopupMenuItem(value: 'detail', label: '明细', icon: CupertinoIcons.doc_text),
///     AppCupertinoPopupMenuItem(value: 'delete', label: '删除', icon: CupertinoIcons.trash, destructive: true),
///   ],
///   onSelected: (value) {},
/// )
/// ```
class AppCupertinoPopupMenu<T> extends StatelessWidget {
  const AppCupertinoPopupMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.tooltip = '操作',
    this.offset = const Offset(0, 28),
    this.child,
    this.iconColor,
    this.iconSize = 20,
  });

  final List<AppCupertinoPopupMenuItem<T>> items;
  final ValueChanged<T>? onSelected;
  final String tooltip;
  final Offset offset;

  /// 触发按钮；默认 [CupertinoIcons.ellipsis]。
  final Widget? child;
  final Color? iconColor;
  final double iconSize;

  static const double itemHeight = 36;
  static const double menuRadius = 12;
  static const double itemRadius = 6;
  static const double fontSize = 15;
  static const double itemIconSize = 18;
  static const Color highlightColor = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        offset: offset,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        elevation: 12,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(menuRadius),
        ),
        menuPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<T>>[
            for (final AppCupertinoPopupMenuItem<T> item in items)
              PopupMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                height: itemHeight,
                padding: EdgeInsets.zero,
                child: _AppCupertinoPopupMenuTile(
                  label: item.label,
                  icon: item.icon,
                  destructive: item.destructive,
                ),
              ),
          ];
        },
        child:
            child ??
            Icon(
              CupertinoIcons.ellipsis,
              size: iconSize,
              color: iconColor ?? theme.hintColor,
            ),
      ),
    );
  }
}

class _AppCupertinoPopupMenuTile extends StatefulWidget {
  const _AppCupertinoPopupMenuTile({
    required this.label,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final bool destructive;

  @override
  State<_AppCupertinoPopupMenuTile> createState() =>
      _AppCupertinoPopupMenuTileState();
}

class _AppCupertinoPopupMenuTileState
    extends State<_AppCupertinoPopupMenuTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color foreground = _hovered
        ? Colors.white
        : (widget.destructive
              ? CupertinoColors.destructiveRed.resolveFrom(context)
              : CupertinoColors.label.resolveFrom(context));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: AppCupertinoPopupMenu.itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _hovered
              ? AppCupertinoPopupMenu.highlightColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppCupertinoPopupMenu.itemRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: AppCupertinoPopupMenu.itemIconSize,
                color: foreground,
              ),
              const Gap(8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: AppCupertinoPopupMenu.fontSize,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
