import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;

/// 删除确认弹窗默认宽度。
const kAppDeleteConfirmDialogWidth = 350.0;

/// 带固定宽度的删除确认弹窗。
class AppDeleteConfirmAlertDialog extends StatelessWidget {
  const AppDeleteConfirmAlertDialog({
    super.key,
    this.title,
    required this.content,
    required this.actions,
  });

  final Widget? title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = shad.Theme.of(context);
    final scaling = theme.scaling;
    final densityGap = theme.density.baseGap * scaling;
    final dialogRadius = AppTheme.maybeOf(context)?.dialogRadius;
    final borderRadius = dialogRadius == null
        ? theme.borderRadiusXxl
        : BorderRadius.circular(dialogRadius);

    Widget surface = shad.ModalContainer(
      fillColor: theme.colorScheme.popover,
      filled: true,
      borderRadius: borderRadius,
      borderWidth: 1 * scaling,
      borderColor: theme.colorScheme.muted,
      // 与上游 AppFormDialog / AppAlertDialog 默认外边距一致。
      padding: const EdgeInsets.all(20),
      surfaceBlur: theme.surfaceBlur,
      surfaceOpacity: theme.surfaceOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) title!.large().semiBold(),
              if (title != null) SizedBox(height: densityGap),
              content.small().muted(),
            ],
          ),
          SizedBox(height: densityGap * 2),
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: shad
                  .join(actions, SizedBox(width: densityGap))
                  .toList(),
            ),
          ),
        ],
      ),
    );

    return shad.ModalBackdrop(
      borderRadius: borderRadius,
      barrierColor: AppOverlayStyle.modalBarrier(context),
      surfaceClip: shad.ModalBackdrop.shouldClipSurface(theme.surfaceOpacity),
      child: SizedBox(width: kAppDeleteConfirmDialogWidth, child: surface),
    );
  }
}

/// 通用删除确认弹窗；确认返回 `true`。
Future<bool> showAppDeleteConfirmDialog(
  BuildContext context, {
  String title = '确认删除',
  required String message,
}) {
  return showAppWindowDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDeleteConfirmAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(dialogContext, false),
          child: const Text('取消'),
        ),
        AppButton.destructive(
          onPressed: () => AppOverlay.close(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  ).future.then((value) => value == true);
}
