import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;

/// 非末级层级文字色。
const Color kBreadcrumbColor = Color(0xFF86909C);

/// 末级（当前）层级文字色。
const Color kBreadcrumbCurrentColor = Color(0xFF4E5969);

/// 页面面包屑：[AppBreadcrumb] + 项目配色。
///
/// 待上游：`BreadcrumbTheme` 补 `color` / `currentColor` 后回收，
/// 现通过局部覆盖 `mutedForeground` / `foreground` 实现。
///
/// ```dart
/// PageBreadcrumb(children: [Text('订单管理'), Text(name)])
/// ```
class PageBreadcrumb extends StatelessWidget {
  const PageBreadcrumb({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = shad.Theme.of(context);
    return shad.Theme(
      data: theme.copyWith(
        colorScheme: () => theme.colorScheme.copyWith(
          mutedForeground: () => kBreadcrumbColor,
          foreground: () => kBreadcrumbCurrentColor,
        ),
      ),
      child: AppBreadcrumb(padding: padding, children: children),
    );
  }
}
