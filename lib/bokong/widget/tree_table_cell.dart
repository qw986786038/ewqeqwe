import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

/// 树表格单元格文本：一级行加粗，子级保持常规字重。
Widget treeTableCellText(
  BuildContext context,
  Object? value, {
  required bool topLevel,
  Alignment alignment = Alignment.center,
}) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) {
    return Align(alignment: alignment, child: const SizedBox.shrink());
  }
  final base = DefaultTextStyle.of(context).style;
  return Align(
    alignment: alignment,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(fontWeight: topLevel ? FontWeight.w600 : null),
    ),
  );
}

/// 树表格文本列：默认按 [isTopLevel] 控制一级加粗。
AppDataGridColumn<T> treeTableTextColumn<T>({
  required String id,
  required String title,
  required Object? Function(T row) value,
  required bool Function(T row) isTopLevel,
  AppDataGridColumnType type = AppDataGridColumnType.text,
  double width = 160,
  double minWidth = 80,
  AppDataGridColumnWidthMode? widthMode,
  double flex = 1,
  AppDataGridColumnPin pin = AppDataGridColumnPin.none,
  bool sortable = true,
  bool filterable = true,
  Alignment alignment = Alignment.center,
  Alignment? titleAlignment,
}) {
  return AppDataGridColumn<T>(
    id: id,
    title: title,
    value: value,
    type: type,
    width: width,
    minWidth: minWidth,
    widthMode: widthMode,
    flex: flex,
    pin: pin,
    sortable: sortable,
    filterable: filterable,
    alignment: alignment,
    titleAlignment: titleAlignment,
    cellBuilder: (context, row, cellValue) => treeTableCellText(
      context,
      cellValue,
      topLevel: isTopLevel(row),
      alignment: alignment,
    ),
  );
}
