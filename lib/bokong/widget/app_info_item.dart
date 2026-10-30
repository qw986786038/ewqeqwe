import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/widget/app_text.dart';

/// 带分割线信息行中的单列数据。
///
/// 标签与内容默认在列内水平居中；默认各显示 1 行，超长省略。
///
/// ```dart
/// AppInfoLinedCell(label: '上刊时间', value: '2026-01-01')
/// AppInfoLinedCell(label: '播放时段', value: longText, valueMaxLines: 2)
/// ```
class AppInfoLinedCell {
  const AppInfoLinedCell({
    required this.label,
    required this.value,
    this.flex = 1,
    this.labelMaxLines = 1,
    this.valueMaxLines = 1,
    this.valueWidget,
  });

  final String label;
  final String value;
  final int flex;

  /// 标签最多行数，默认 1。
  final int labelMaxLines;

  /// 内容最多行数，默认 1；使用 [valueWidget] 时无效。
  final int valueMaxLines;

  /// 自定义内容区；为 null 时用 [value] 文本。
  final Widget? valueWidget;
}

/// 带分割线信息表：表头一行 + 共用横线 + 多行数据。
///
/// 横线由表级统一绘制，保证多列之间连线连续；不要给每列单独加 [Divider]。
class AppInfoLinedTable extends StatelessWidget {
  const AppInfoLinedTable({
    super.key,
    required this.cells,
    required this.rows,
    this.lineColor = const Color(0xFFE0E0E0),
    this.headerBackgroundColor = kTableHeaderBackground,
    this.borderRadius = 6,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  final List<AppInfoLinedCell> cells;
  final List<List<Widget>> rows;
  final Color lineColor;
  final Color headerBackgroundColor;
  final double borderRadius;
  final EdgeInsets cellPadding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: headerBackgroundColor,
              child: AppInfoLinedRow(
                cells: cells,
                showValues: false,
                lineColor: lineColor,
                cellPadding: cellPadding,
              ),
            ),
            Divider(height: 1, thickness: 1, color: lineColor),
            for (int i = 0; i < rows.length; i++) ...[
              AppInfoLinedDataRow(
                cells: cells,
                values: rows[i],
                cellPadding: cellPadding,
              ),
              if (i < rows.length - 1)
                Divider(height: 1, thickness: 1, color: lineColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// 横向多列 + 共用分割线：上方标签行、下方内容行。
class AppInfoLinedRow extends StatelessWidget {
  const AppInfoLinedRow({
    super.key,
    required this.cells,
    this.showValues = true,
    this.lineColor = const Color(0xFFE0E0E0),
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  final List<AppInfoLinedCell> cells;
  final bool showValues;
  final Color lineColor;
  final EdgeInsets cellPadding;

  @override
  Widget build(BuildContext context) {
    if (!showValues) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: cells[i].flex,
              child: Padding(
                padding: cellPadding,
                child: _LinedLabelText(
                  text: cells[i].label,
                  maxLines: cells[i].labelMaxLines,
                  color: AppText.colorPrimary,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < cells.length; i++)
              Expanded(
                flex: cells[i].flex,
                child: Padding(
                  padding: cellPadding.copyWith(bottom: 8),
                  child: _LinedLabelText(
                    text: cells[i].label,
                    maxLines: cells[i].labelMaxLines,
                    color: AppText.colorMuted,
                  ),
                ),
              ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: lineColor),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < cells.length; i++)
              Expanded(
                flex: cells[i].flex,
                child: Padding(
                  padding: cellPadding.copyWith(top: 8),
                  child: cells[i].valueWidget != null
                      ? Center(child: cells[i].valueWidget)
                      : _LinedValueText(
                          text: cells[i].value,
                          maxLines: cells[i].valueMaxLines,
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 标签文案：默认单行，超宽省略（关闭 softWrap，避免中文按字换行）。
class _LinedLabelText extends StatelessWidget {
  const _LinedLabelText({
    required this.text,
    required this.maxLines,
    this.fontWeight,
    this.color,
  });

  final String text;
  final int maxLines;
  final FontWeight? fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppText.small(
        text,
        fontWeight: fontWeight,
        color: color,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        softWrap: maxLines > 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 内容文案：默认单行，超宽省略。
class _LinedValueText extends StatelessWidget {
  const _LinedValueText({required this.text, required this.maxLines});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppText.body(
        text.replaceAll(RegExp(r'\s*\n\s*'), ' '),
        fontWeight: FontWeight.w600,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        softWrap: maxLines > 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// 带分割线信息表的数据行（仅内容，标签由表头统一展示）。
class AppInfoLinedDataRow extends StatelessWidget {
  const AppInfoLinedDataRow({
    super.key,
    required this.cells,
    required this.values,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  });

  final List<AppInfoLinedCell> cells;
  final List<Widget> values;
  final EdgeInsets cellPadding;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < values.length; i++)
          Expanded(
            flex: i < cells.length ? cells[i].flex : 1,
            child: Padding(
              padding: cellPadding,
              child: Center(child: values[i]),
            ),
          ),
      ],
    );
  }
}

/// 垂直信息项：上方标签、下方内容。
///
/// ```dart
/// AppInfoItem(label: '订单编号', value: '97778222220022')
/// AppInfoItem(label: '订单名称', value: name, width: 120, maxLines: 2)
/// ```
class AppInfoItem extends StatelessWidget {
  /// 竖向：上方标签、下方内容。
  const AppInfoItem({
    super.key,
    required this.label,
    required this.value,
    this.width,
    this.maxLines = 1,
    this.labelColor,
    this.valueColor,
    this.valueFontWeight,
    this.labelWidth = 72,
  }) : _direction = Axis.vertical;

  /// 横向：左侧标签、右侧内容。
  const AppInfoItem.horizontal({
    super.key,
    required this.label,
    required this.value,
    this.width,
    this.maxLines = 1,
    this.labelColor,
    this.valueColor,
    this.valueFontWeight,
    this.labelWidth = 72,
  }) : _direction = Axis.horizontal;

  final String label;
  final String value;
  final double? width;
  final int maxLines;

  /// 覆盖标签颜色；默认 [AppText.colorMuted]。
  final Color? labelColor;

  /// 覆盖内容颜色；默认 [AppText.colorPrimary]。
  final Color? valueColor;

  /// 覆盖内容字重；默认 [FontWeight.w600]。
  final FontWeight? valueFontWeight;
  final Axis _direction;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final Widget item = _direction == Axis.vertical
        ? _verticalItem()
        : _horizontalItem();

    if (width == null) return item;
    return SizedBox(width: width, child: item);
  }

  Widget _verticalItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.small(label, color: labelColor ?? AppText.colorMuted),
        const Gap(4),
        AppText.body(
          value,
          color: valueColor,
          fontWeight: valueFontWeight ?? FontWeight.w600,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _horizontalItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: AppText.small(label, color: labelColor ?? AppText.colorMuted),
        ),
        Expanded(
          child: AppText.body(
            value,
            color: valueColor,
            fontWeight: valueFontWeight ?? FontWeight.w600,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
