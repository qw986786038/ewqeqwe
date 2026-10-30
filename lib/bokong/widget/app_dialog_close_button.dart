import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;

/// 弹窗右上角窗口按钮边长。
const double kDialogWindowButtonSize = 32;

const AppButtonConfig _kDialogWindowButtonConfig = AppButtonConfig(
  height: kDialogWindowButtonSize,
);

/// 弹窗右上角关闭按钮（主色圆形）。
///
/// 待上游回收：建议 `AppFormDialog` 提供默认关闭（如 `showClose: true` /
/// `AppDialogCloseButton`），业务只决定是否展示。
class AppDialogCloseButton extends StatelessWidget {
  const AppDialogCloseButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = ShadcnTheme.of(context).colorScheme.primaryForeground;
    return AppIconButton.circle(
      icon: const Icon(AppLucideIcons.x, size: 16),
      tooltip: '关闭',
      variant: AppButtonVariant.primary,
      color: fg,
      config: _kDialogWindowButtonConfig,
      onPressed: onPressed ?? () => AppOverlay.close(context),
    );
  }
}

/// 可拖动弹窗右上角：关闭（主色圆形，对齐 [AppDialogCloseButton]）。
///
/// 不展示最大化按钮。
///
/// 待上游回收：默认 [AppDialogWindowActions] 改为主色圆形（当前仍为 ghost）。
class AppDialogWindowControls extends StatelessWidget {
  const AppDialogWindowControls({super.key, required this.interaction});

  final AppDialogInteraction interaction;

  @override
  Widget build(BuildContext context) {
    if (!interaction.closable) return const SizedBox.shrink();
    return AppDialogCloseButton(onPressed: interaction.close);
  }
}

/// 业务可拖动弹窗（主色窗口按钮）。
///
/// 默认：可拖动、不可缩放、不可最大化（不展示最大化按钮）。
/// 大内容窗传 [resizable] / [initialSize]。
///
/// 返回值与 [AppDialog.show] 相同（可 `.future`）。
shad.OverlayCompleter<T?> showAppWindowDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  bool movable = true,
  bool resizable = false,
  bool closable = true,
  Size? initialSize,
  Offset? initialOffset,
  BoxConstraints resizeConstraints = AppDialog.defaultResizeConstraints,
  Widget? controls,
  AppDialogControlsBuilder? controlsBuilder,
}) {
  return AppDialog.show<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    movable: movable,
    resizable: resizable,
    maximizable: false,
    closable: closable,
    initialSize: initialSize,
    initialOffset: initialOffset,
    resizeConstraints: resizeConstraints,
    controls: controls,
    controlsBuilder:
        controlsBuilder ??
        (context, interaction) =>
            AppDialogWindowControls(interaction: interaction),
  );
}
