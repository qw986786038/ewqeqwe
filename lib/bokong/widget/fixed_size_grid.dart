import 'package:flutter/widgets.dart';

/// 主壳水平边距为 12；页面非网格区用 [kPageShellHPad] 补回，视觉仍相当于原 24。
///
/// 网格用 [kGridShellPad] 作 [GridView.padding]，把这 12 吃进裁切区内供上浮/描边。
const kPageShellInsetH = 12.0;

/// 网格内边距：水平抵消主壳让出的 12；垂直略留上浮。
const kGridShellPad = EdgeInsets.fromLTRB(kPageShellInsetH, 8, kPageShellInsetH, 8);

/// 固定 item 宽高与间距、整体左对齐的网格。
///
/// 列数按容器宽度计算；多余宽度留在右侧，不拉伸卡片、不摊进间距。
/// 末行不足一列时同样左侧排布、右侧留白。
///
/// [padding] 算进可排宽度，并作为 [GridView] 内边距（上浮/描边可画在裁切区内，
/// 勿把 clipBehavior 改成 none）。网格页推荐 [kGridShellPad]。
///
/// 待上游：建议 `AppGrid` 提供 `fixedItemSize` / `align: start` 一等 API。
class FixedSizeGrid extends StatelessWidget {
  const FixedSizeGrid({
    required this.itemWidth,
    required this.itemHeight,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 16,
    this.maxColumns = 24,
    this.shrinkWrap = false,
    this.physics,
    this.padding = EdgeInsets.zero,
    this.controller,
    super.key,
  }) : assert(itemWidth > 0),
       assert(itemHeight > 0),
       assert(spacing >= 0),
       assert(maxColumns > 0);

  final double itemWidth;
  final double itemHeight;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final int maxColumns;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding.resolve(Directionality.of(context));
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : itemWidth;
        final width = (maxW - resolvedPadding.horizontal).clamp(0.0, maxW);
        final cols = ((width + spacing) / (itemWidth + spacing)).floor().clamp(1, maxColumns);
        final gridWidth = cols * itemWidth + (cols - 1) * spacing + resolvedPadding.horizontal;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: gridWidth > maxW ? maxW : gridWidth,
            child: GridView.builder(
              padding: padding,
              controller: controller,
              shrinkWrap: shrinkWrap,
              physics: physics,
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisExtent: itemHeight, mainAxisSpacing: spacing, crossAxisSpacing: spacing),
              itemBuilder: (context, index) {
                return SizedBox(width: itemWidth, height: itemHeight, child: itemBuilder(context, index));
              },
            ),
          ),
        );
      },
    );
  }
}
