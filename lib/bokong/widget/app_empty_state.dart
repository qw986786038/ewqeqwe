import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 业务空态：插图 + 文案（默认「暂无数据」）。
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title = const Text('暂无数据'),
    this.description,
    this.action,
    this.imageWidth = 192,
    this.padding = const EdgeInsets.all(24),
  });

  static const asset = 'assets/images/empty_state.png';

  /// 资源原始宽度（勿放大超过此值，否则会糊）。
  static const sourceWidth = 384.0;

  final Widget title;
  final Widget? description;
  final Widget? action;
  final double imageWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding.resolve(Directionality.of(context));
        final reservedForText =
            (description != null ? 56.0 : 36.0) + (action != null ? 52.0 : 0.0);
        var displayWidth = imageWidth.clamp(0.0, sourceWidth / dpr);

        final maxHeight = constraints.maxHeight;
        if (maxHeight.isFinite) {
          final maxImageHeight =
              maxHeight - resolvedPadding.vertical - reservedForText;
          if (maxImageHeight <= 0) {
            displayWidth = 0;
          } else if (maxImageHeight < displayWidth) {
            displayWidth = maxImageHeight;
          }
        }

        final cacheWidth = displayWidth > 0
            ? (displayWidth * dpr).round()
            : null;

        return Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (displayWidth > 0)
                Image.asset(
                  asset,
                  width: displayWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  cacheWidth: cacheWidth,
                ),
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
                child: title,
              ),
              if (description != null) ...[
                const SizedBox(height: 6),
                DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                  textAlign: TextAlign.center,
                  child: description!,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        );
      },
    );
  }
}
