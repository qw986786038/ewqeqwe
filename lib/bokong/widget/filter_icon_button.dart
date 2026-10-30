import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/theme/theme.dart';

/// 筛选图标按钮：有筛选项时图标变主色，右上角显示数量角标。
///
/// 用上游 [AppIconButton] + [AppCornerBadge.count] 组合。
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    super.key,
    required this.count,
    required this.onPressed,
    this.tooltip = '筛选',
  });

  /// 当前生效的筛选项数量；`0` 时为默认灰色、无角标。
  final int count;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final active = count > 0;
    final button = AppIconButton(
      icon: Icon(
        AppLucideIcons.listFilter,
        size: 16,
        color: active ? colors.primary : kIconButtonForeground,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
    if (!active) return button;
    return AppCornerBadge.count(
      count: count,
      color: colors.primary,
      foregroundColor: const Color(0xffffffff),
      size: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: button,
    );
  }
}
