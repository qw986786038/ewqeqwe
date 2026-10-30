import 'package:flutter/material.dart';

/// 仅按宽度区分：手机、平板、桌面（用于 [AppLayout]）。
enum AppDevice { phone, tablet, desktop }

/// 左-中-右：手机只显示 [start]；平板 [start]+[main]；桌面再加可选 [end]。
class AppLayout extends StatelessWidget {
  const AppLayout({
    super.key,
    required this.start,
    required this.main,
    this.end,
    this.startWidth = 280,
    this.endWidth = 300,
    this.paneGap = 8,
    this.maxContentWidth = 1440,
    this.phonePadding = const EdgeInsets.symmetric(horizontal: 16),
    this.widePadding = const EdgeInsets.symmetric(horizontal: 24),
  });

  static const double _phoneBelow = 600;
  static const double _tabletBelow = 900;

  final Widget start;
  final Widget main;
  final Widget? end;
  final double startWidth;
  final double endWidth;
  final double paneGap;
  final double maxContentWidth;

  /// 手机宽度下的外边距（可 `EdgeInsets.fromLTRB` 分别设上下左右）。
  final EdgeInsets phonePadding;

  /// 平板、桌面宽度下的外边距。
  final EdgeInsets widePadding;

  static AppDevice deviceOf(BuildContext context) =>
      deviceForWidth(MediaQuery.sizeOf(context).width);

  static AppDevice deviceForWidth(double width) {
    if (width < _phoneBelow) {
      return AppDevice.phone;
    }
    if (width < _tabletBelow) {
      return AppDevice.tablet;
    }
    return AppDevice.desktop;
  }

  static double contentWidthOf(
    BuildContext context, {
    double maxContentWidth = 1440,
    EdgeInsets phonePadding = const EdgeInsets.symmetric(horizontal: 16),
    EdgeInsets widePadding = const EdgeInsets.symmetric(horizontal: 24),
  }) {
    final double w = MediaQuery.sizeOf(context).width;
    final EdgeInsets p = deviceForWidth(w) == AppDevice.phone
        ? phonePadding
        : widePadding;
    return (w - p.horizontal).clamp(0.0, maxContentWidth);
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final AppDevice d = deviceForWidth(w);
    final EdgeInsets pad = d == AppDevice.phone ? phonePadding : widePadding;

    return Padding(
      padding: pad,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth.clamp(0.0, maxContentWidth);
          final Widget body = switch (d) {
            AppDevice.phone => start,
            AppDevice.tablet => _row(includeEnd: false),
            AppDevice.desktop => _row(includeEnd: end != null),
          };
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : null,
              child: body,
            ),
          );
        },
      ),
    );
  }

  Widget _pane({double? width, required Widget child}) {
    final Widget pane = ClipRect(clipBehavior: Clip.none, child: child);
    if (width != null) return SizedBox(width: width, child: pane);
    return Expanded(child: pane);
  }

  Widget _row({required bool includeEnd}) {
    return ClipRect(
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pane(width: startWidth, child: start),
          SizedBox(width: paneGap),
          _pane(child: main),
          if (includeEnd) ...[
            SizedBox(width: paneGap),
            _pane(width: endWidth, child: end!),
          ],
        ],
      ),
    );
  }
}
