import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

/// 预览弹窗内容区水平留白。
const double previewDialogHorizontalInset = 64;

/// 预览弹窗内容区最小 / 最大宽度。
const double previewDialogMinContentWidth = 400;
const double previewDialogMaxContentWidth = 960;

/// 预览弹窗相对内容区的额外宽度（左右内边距）。
const double previewDialogWidthPadding = 48;

/// 预览弹窗内容区最大高度（与标题/按钮区内边距对齐）。
double previewDialogMaxContentHeight(BuildContext context) {
  final MediaQueryData media = MediaQuery.of(context);
  const double dialogInset = 48;
  const double contentPaddingVertical = 36;
  const double titleAndActions = 107;
  final double available =
      media.size.height -
      media.viewInsets.bottom -
      dialogInset -
      contentPaddingVertical -
      titleAndActions;
  return available.clamp(280, media.size.height * 0.82);
}

/// 预览弹窗内容区统一宽度。
double previewDialogContentWidth(BuildContext context) {
  return (MediaQuery.sizeOf(context).width - previewDialogHorizontalInset)
      .clamp(previewDialogMinContentWidth, previewDialogMaxContentWidth);
}

/// 按统一宽度与给定比例计算预览内容区尺寸（超出最大高度时等比缩小）。
Size previewAspectContentSize(
  BuildContext context, {
  required double aspectWidth,
  required double aspectHeight,
}) {
  final double maxHeight = previewDialogMaxContentHeight(context);
  double width = previewDialogContentWidth(context);
  double height = width * aspectHeight / aspectWidth;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * aspectWidth / aspectHeight;
  }
  return Size(width, height);
}

/// 预览弹窗最小宽度。
double previewDialogMinWidth(Size contentSize) =>
    contentSize.width + previewDialogWidthPadding;

/// 竖屏预览区域尺寸（宽:高 = 9:16）。
Size previewPortrait169Size(BuildContext context) {
  return previewAspectContentSize(context, aspectWidth: 9, aspectHeight: 16);
}

/// 素材预览弹窗（图片 / 视频 / 网页共用壳）。
Future<void> showPreviewDialog({
  required BuildContext context,
  required String title,
  required Widget child,
}) async {
  final Size contentSize = previewPortrait169Size(context);
  await showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(
      previewDialogMinWidth(contentSize),
      contentSize.height + 140,
    ),
    builder: (dialogContext) => AppFormDialog(
      title: Text(title),
      constraints: BoxConstraints(minWidth: previewDialogMinWidth(contentSize)),
      content: SizedBox(
        width: contentSize.width,
        height: contentSize.height,
        child: child,
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<void>(dialogContext),
          child: const Text('关闭'),
        ),
      ],
    ),
  ).future;
}
