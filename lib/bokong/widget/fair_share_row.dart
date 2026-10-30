import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 横向排列；放得下时各按原宽，放不下时短的保持原宽、长的平分剩余宽度。
///
/// 子项需自行处理收缩后的省略（如 `AppBadge` 默认单行省略）。
///
/// ```dart
/// FairShareRow(
///   spacing: 6,
///   children: [AppBadge(child: Text(a)), AppBadge(child: Text(b))],
/// )
/// ```
///
/// 待上游：建议 lemon_shadcn 提供同类布局（如 `AppTagRow`）后回收。
class FairShareRow extends MultiChildRenderObjectWidget {
  const FairShareRow({super.key, this.spacing = 0, super.children});

  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFairShareRow(spacing);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderFairShareRow).spacing = spacing;
  }
}

class _FairShareParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFairShareRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _FairShareParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _FairShareParentData> {
  _RenderFairShareRow(this._spacing);

  double _spacing;

  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FairShareParentData) child.parentData = _FairShareParentData();
  }

  double get _gaps => childCount > 1 ? _spacing * (childCount - 1) : 0;

  List<double> _allocate(List<RenderBox> children, double maxWidth) {
    final natural = [for (final c in children) c.getMaxIntrinsicWidth(double.infinity)];
    final available = maxWidth - _gaps;
    if (!available.isFinite || natural.fold<double>(0, (a, b) => a + b) <= available) return natural;
    final order = List<int>.generate(children.length, (i) => i)..sort((a, b) => natural[a].compareTo(natural[b]));
    final widths = List<double>.filled(children.length, 0);
    var remaining = math.max(0.0, available);
    var left = children.length;
    for (final i in order) {
      final w = math.min(natural[i], remaining / left);
      widths[i] = w;
      remaining -= w;
      left--;
    }
    return widths;
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final children = getChildrenAsList();
    if (children.isEmpty) return constraints.smallest;
    final widths = _allocate(children, constraints.maxWidth);
    final sizes = [
      for (var i = 0; i < children.length; i++)
        () {
          final c = BoxConstraints(maxWidth: widths[i], maxHeight: constraints.maxHeight);
          if (dry) return children[i].getDryLayout(c);
          children[i].layout(c, parentUsesSize: true);
          return children[i].size;
        }(),
    ];
    final height = sizes.fold<double>(0, (a, s) => math.max(a, s.height));
    var x = 0.0;
    for (var i = 0; i < children.length; i++) {
      if (!dry) (children[i].parentData! as _FairShareParentData).offset = Offset(x, (height - sizes[i].height) / 2);
      x += sizes[i].width + (i < children.length - 1 ? _spacing : 0);
    }
    return constraints.constrain(Size(x, height));
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      getChildrenAsList().fold<double>(_gaps, (a, c) => a + c.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      getChildrenAsList().fold<double>(0, (a, c) => math.max(a, c.getMinIntrinsicHeight(double.infinity)));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      getChildrenAsList().fold<double>(0, (a, c) => math.max(a, c.getMaxIntrinsicHeight(double.infinity)));

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
