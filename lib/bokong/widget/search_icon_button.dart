import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:yidivination/bokong/theme/theme.dart';

/// 顶栏搜索输入框灰底（[kSearchFieldBackground]）。
///
/// 待上游：`AppTextFormField` 支持 `fillColor` 后改为字段参数并删除本包装。
class SearchFieldBackground extends StatelessWidget {
  const SearchFieldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadcnTheme.of(context);
    return shad.Theme(
      data: theme.copyWith(
        colorScheme: () =>
            theme.colorScheme.copyWith(muted: () => kSearchFieldBackground),
      ),
      child: shad.ComponentTheme(
        data: const shad.TextFieldTheme(filled: true),
        child: child,
      ),
    );
  }
}

/// 搜索框触发按钮：圆形实心，色与列表「新建」一致（[kIconButtonForeground]）。
class SearchIconButton extends StatelessWidget {
  const SearchIconButton({
    super.key,
    required this.onPressed,
    this.size = AppButtonSize.xSmall,
    this.tooltip = '搜索',
    this.unifyTrailingInset = true,
  });

  final VoidCallback? onPressed;
  final AppButtonSize size;
  final String tooltip;

  /// 作为 [AppTextFormField.trailing] 时，把右间距拉齐到上下间距。
  ///
  /// 输入框本身有水平 padding，圆钮缩小后上下空隙更小，右侧会显得偏大；
  /// 开启后向右平移以统一「上 / 下 / 右」。独立摆放时请传 `false`。
  final bool unifyTrailingInset;

  @override
  Widget build(BuildContext context) {
    final button = AppIconButton.circle(
      size: size,
      variant: AppButtonVariant.primary,
      backgroundColor: kIconButtonForeground,
      color: const Color(0xffffffff),
      icon: const Icon(AppLucideIcons.search, size: 14),
      tooltip: tooltip,
      onPressed: onPressed,
    );
    if (!unifyTrailingInset) return button;

    final metrics = AppControlMetricsScope.resolve(context);
    final buttonExtent = metrics.buttonHeight * size.scale;
    final verticalInset = ((metrics.height - buttonExtent) / 2).clamp(
      0.0,
      metrics.horizontalPadding,
    );
    final pull = metrics.horizontalPadding - verticalInset;
    if (pull <= 0) return button;

    return Transform.translate(offset: Offset(pull, 0), child: button);
  }
}
