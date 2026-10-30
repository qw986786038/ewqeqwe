import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

extension WidgetSizeX on Widget {
  /// 固定宽度。
  Widget width(double width) => SizedBox(width: width, child: this);

  /// 固定高度。
  Widget height(double height) => SizedBox(height: height, child: this);

  /// 固定宽高（可只传其一）。
  ///
  /// 待上游回收：建议与 `.width()` / `.height()` 一并进 `lemon_shadcn`。
  Widget size({double? width, double? height}) =>
      SizedBox(width: width, height: height, child: this);

  /// 包一层 [Expanded]。
  Widget expanded({Key? key, int flex = 1}) =>
      Expanded(key: key, flex: flex, child: this);

  /// 包一层 [Flexible]。
  Widget flexible({Key? key, int flex = 1, FlexFit fit = FlexFit.loose}) =>
      Flexible(key: key, flex: flex, fit: fit, child: this);

  /// 包一层 [Center]。
  ///
  /// 待上游回收：建议与 `.expanded()` / `.scroll()` 一并进 `lemon_shadcn`。
  Widget center({Key? key, double? widthFactor, double? heightFactor}) =>
      Center(
        key: key,
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: this,
      );

  /// 包一层带滚动条的可滚动视图（高度随内容，超出父级上限才滚动）。
  ///
  /// 默认裁剪视口（避免画到弹窗外）。整页滚动请显式传 [padding]
  ///（如 `EdgeInsets.all(8)`）给卡片阴影留空，并与顶栏外边距对齐。
  ///
  /// 待上游回收：建议 `lemon_shadcn` 在 [AppScrollbarView] 旁提供
  /// `Widget.scroll(...)` 一等扩展；默认 shrink-wrap，避免在 [Flexible]/[Expanded]
  /// 内被撑满。
  Widget scroll({
    Key? key,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    Clip clipBehavior = Clip.hardEdge,
    bool? thumbVisibility,
    bool? trackVisibility,
    double? thickness,
    Radius? radius,
    Color? color,
    bool? interactive,
    ScrollbarOrientation? scrollbarOrientation,
  }) {
    return _ShrinkWrapScrollbar(
      key: key,
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      padding: padding,
      physics: physics,
      clipBehavior: clipBehavior,
      thumbVisibility: thumbVisibility,
      trackVisibility: trackVisibility,
      thickness: thickness,
      radius: radius,
      color: color,
      interactive: interactive,
      scrollbarOrientation: scrollbarOrientation,
      child: this,
    );
  }
}

/// 高度取 `min(内容高度, 父级 max)`，避免 [AppScrollbarView]（内部
/// [SingleChildScrollView]）在弹性布局里被拉满。
class _ShrinkWrapScrollbar extends StatefulWidget {
  const _ShrinkWrapScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.physics,
    this.clipBehavior = Clip.hardEdge,
    this.thumbVisibility,
    this.trackVisibility,
    this.thickness,
    this.radius,
    this.color,
    this.interactive,
    this.scrollbarOrientation,
  });

  final Widget child;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Clip clipBehavior;
  final bool? thumbVisibility;
  final bool? trackVisibility;
  final double? thickness;
  final Radius? radius;
  final Color? color;
  final bool? interactive;
  final ScrollbarOrientation? scrollbarOrientation;

  @override
  State<_ShrinkWrapScrollbar> createState() => _ShrinkWrapScrollbarState();
}

class _ShrinkWrapScrollbarState extends State<_ShrinkWrapScrollbar> {
  ScrollController? _owned;

  ScrollController get _controller =>
      widget.controller ?? (_owned ??= ScrollController());

  @override
  void didUpdateWidget(covariant _ShrinkWrapScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null && widget.controller != null) {
      _owned?.dispose();
      _owned = null;
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // 保留视口裁剪；padding 默认 0（卡片内滚动勿加边距）。整页滚动由调用方传入。
    // 可拖动弹窗测量阶段可能给出无限交叉轴约束；shrink-wrap ListView 必须有限宽/高。
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = widget.scrollDirection == Axis.vertical;
        final media = MediaQuery.sizeOf(context);
        final boundCrossAxis = vertical
            ? constraints.hasBoundedWidth
            : constraints.hasBoundedHeight;
        Widget view = AppScrollbar(
          controller: controller,
          thumbVisibility: widget.thumbVisibility,
          trackVisibility: widget.trackVisibility,
          thickness: widget.thickness,
          radius: widget.radius,
          color: widget.color,
          interactive: widget.interactive,
          scrollbarOrientation: widget.scrollbarOrientation,
          child: ListView(
            controller: controller,
            primary: false,
            shrinkWrap: true,
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            padding: widget.padding ?? EdgeInsets.zero,
            physics: widget.physics,
            clipBehavior: widget.clipBehavior,
            children: [widget.child],
          ),
        );
        if (!boundCrossAxis) {
          // 可拖动弹窗测量阶段常见；用屏宽上限兜底，避免表单被撑满整屏。
          final fallback = vertical
              ? media.width.clamp(280.0, 720.0)
              : media.height.clamp(200.0, 800.0);
          view = SizedBox(
            width: vertical ? fallback : null,
            height: vertical ? null : fallback,
            child: view,
          );
        }
        return view;
      },
    );
  }
}
