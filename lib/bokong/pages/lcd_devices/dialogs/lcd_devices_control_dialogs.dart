import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show SliderValue;
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/device_detail/dialogs/device_power_schedule_dialog.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_terminal_mapper.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

/// 批量控制调节弹窗（列表多选设备后）。
void showLcdDevicesBatchControlDialog(
  BuildContext context,
  LcdDevicesController controller,
) {
  final nos = controller.takeControlDeviceNos();
  if (nos == null) return;
  final source = controller.firstSelectedDevice;
  final volume = (source?.volume_normal ?? 60).clamp(1, 100).toDouble();
  final brightness = (source?.brightness ?? 80).clamp(1, 100).toDouble();

  showAppWindowDialog<void>(
    context: context,
    builder: (dialogContext) => _BatchControlDialog(
      volume: volume,
      brightness: brightness,
      onVolume: (value) => controller.setDevicesVolume(nos, value),
      onBrightness: (value) => controller.setDevicesBrightness(nos, value),
      onScreenPower: (on) => controller.setDevicesScreenPower(nos, on ? 1 : 2),
      onRestart: () => controller.rebootDevices(nos),
    ),
  );
}

/// 重启设备确认弹窗。
void showLcdDeviceRestartDialog(
  BuildContext context,
  LcdDevicesController controller, {
  List<String>? deviceNos,
}) {
  final nos = deviceNos ?? controller.takeControlDeviceNos();
  if (nos == null) return;

  showAppWindowDialog<void>(
    context: context,
    builder: (dialogContext) => _RestartConfirmDialog(
      count: nos.length,
      onConfirm: () async {
        await controller.rebootDevices(nos);
        AppOverlay.close(dialogContext);
      },
    ),
  );
}

/// 调节音量弹窗（单设备详情等）。
void showLcdDeviceVolumeDialog(
  BuildContext context,
  LcdDevicesController controller, {
  List<String>? deviceNos,
  LcdDeviceEntity? device,
}) {
  final nos = deviceNos ?? controller.takeControlDeviceNos();
  if (nos == null) return;
  final source = device ?? controller.firstSelectedDevice;
  final initial = (source?.volume_normal ?? 60).clamp(1, 100).toDouble();
  _showLevelDialog(
    context,
    title: '音量调节',
    leadingIcon: AppLucideIcons.volumeX,
    trailingIcon: AppLucideIcons.volume2,
    initial: initial,
    min: 1,
    max: 100,
    onSubmit: (value) => controller.setDevicesVolume(nos, value),
  );
}

/// 调节亮度弹窗（单设备详情等）。
void showLcdDeviceBrightnessDialog(
  BuildContext context,
  LcdDevicesController controller, {
  List<String>? deviceNos,
  LcdDeviceEntity? device,
}) {
  final nos = deviceNos ?? controller.takeControlDeviceNos();
  if (nos == null) return;
  final source = device ?? controller.firstSelectedDevice;
  final initial = (source?.brightness ?? 80).clamp(1, 100).toDouble();
  _showLevelDialog(
    context,
    title: '亮度调节',
    leadingIcon: AppLucideIcons.sunDim,
    trailingIcon: AppLucideIcons.sun,
    initial: initial,
    min: 1,
    max: 100,
    onSubmit: (value) => controller.setDevicesBrightness(nos, value),
  );
}

/// 批量设置开关机时间（ShowDoc 1586，强制覆盖原时段）。
void showLcdDevicesPowerScheduleDialog(
  BuildContext context,
  LcdDevicesController controller, {
  List<String>? deviceNos,
}) {
  final nos = deviceNos ?? controller.takeScheduleDeviceNos();
  if (nos == null) return;
  final source = controller.firstSelectedDevice;
  final initial = source == null ? '' : lcdDevicePowerScheduleText(source);
  showDevicePowerScheduleDialog(
    context,
    initial: initial,
    forceOverwrite: true,
    deviceCount: nos.length,
  ).then((text) {
    if (text == null) return;
    controller.setDevicesPowerSchedule(nos, text);
  });
}

/// 屏幕开关弹窗。
void showLcdDeviceScreenPowerDialog(
  BuildContext context,
  LcdDevicesController controller, {
  List<String>? deviceNos,
}) {
  final nos = deviceNos ?? controller.takeControlDeviceNos();
  if (nos == null) return;

  showAppWindowDialog<void>(
    context: context,
    builder: (dialogContext) => _ScreenPowerDialog(
      count: nos.length,
      onSubmit: (on) async {
        await controller.setDevicesScreenPower(nos, on ? 1 : 2);
        AppOverlay.close(dialogContext);
      },
    ),
  );
}

void _showLevelDialog(
  BuildContext context, {
  required String title,
  required IconData leadingIcon,
  required IconData trailingIcon,
  required double initial,
  double min = 0,
  double max = 100,
  required Future<void> Function(int value) onSubmit,
}) {
  showAppWindowDialog<void>(
    context: context,
    builder: (dialogContext) => _LevelDialog(
      title: title,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      initial: initial,
      min: min,
      max: max,
      onSubmit: onSubmit,
    ),
  );
}

Widget _controlIcon(String name, double size) => Image.asset(
  'assets/images/device_control/$name.png',
  width: size,
  height: size,
  filterQuality: FilterQuality.medium,
);

class _BatchControlDialog extends StatelessWidget {
  const _BatchControlDialog({
    required this.volume,
    required this.brightness,
    required this.onVolume,
    required this.onBrightness,
    required this.onScreenPower,
    required this.onRestart,
  });

  final double volume;
  final double brightness;
  final Future<void> Function(int value) onVolume;
  final Future<void> Function(int value) onBrightness;
  final Future<void> Function(bool on) onScreenPower;
  final Future<void> Function() onRestart;

  void _showScreenPower(BuildContext context) {
    showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => _ScreenPowerDialog(
        count: null,
        onSubmit: (on) async {
          await onScreenPower(on);
          AppOverlay.close(dialogContext);
        },
      ),
    );
  }

  void _showRestart(BuildContext context) {
    showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => _RestartConfirmDialog(
        count: null,
        onConfirm: () async {
          await onRestart();
          AppOverlay.close(dialogContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return AppFormDialog(
      title: const Text('控制调节'),
      constraints: const BoxConstraints(maxWidth: 420),
      content: Column(
        spacing: 24,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LevelSlider(
            leading: _controlIcon('volume', 16),
            trailing: _controlIcon('volume', 20),
            initial: volume,
            min: 1,
            max: 100,
            onSubmit: onVolume,
          ),
          _LevelSlider(
            leading: _controlIcon('brightness', 16),
            trailing: _controlIcon('brightness', 20),
            initial: brightness,
            min: 1,
            max: 100,
            onSubmit: onBrightness,
          ),
          Row(
            children: [
              AppText.body('开关机'),
              const SizedBox(width: 8),
              AppIconButton(
                icon: _controlIcon('power', 18),
                tooltip: '开关机',
                variant: AppButtonVariant.outline,
                color: colors.primary,
                onPressed: () => _showScreenPower(context),
              ),
              const Spacer(),
              AppText.body('重启设备'),
              const SizedBox(width: 8),
              AppIconButton(
                icon: _controlIcon('restart', 18),
                tooltip: '重启设备',
                variant: AppButtonVariant.outline,
                onPressed: () => _showRestart(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestartConfirmDialog extends StatelessWidget {
  const _RestartConfirmDialog({required this.count, required this.onConfirm});

  final int? count;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final tip = count == null
        ? '确认重启所选在线设备？设备将短暂离线，请确认当前无重要播放任务。'
        : '确认重启所选 $count 台在线设备？设备将短暂离线，请确认当前无重要播放任务。';

    return AppFormDialog(
      title: const Text('重启设备'),
      constraints: const BoxConstraints(maxWidth: 420),
      content: Column(
        spacing: 24,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tip),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton.primary(
                onPressed: onConfirm,
                child: const Text('确认重启'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelDialog extends StatelessWidget {
  const _LevelDialog({
    required this.title,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.initial,
    required this.min,
    required this.max,
    required this.onSubmit,
  });

  final String title;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final double initial;
  final double min;
  final double max;
  final Future<void> Function(int value) onSubmit;

  @override
  Widget build(BuildContext context) {
    final iconColor = ShadcnTheme.of(context).colorScheme.mutedForeground;
    return AppFormDialog(
      title: Text(title),
      constraints: const BoxConstraints(maxWidth: 420),
      content: _LevelSlider(
        leading: Icon(leadingIcon, size: 20, color: iconColor),
        trailing: Icon(trailingIcon, size: 20, color: iconColor),
        initial: initial,
        min: min,
        max: max,
        onSubmit: onSubmit,
      ),
    );
  }
}

/// 横向滑条：按下只预览，抬起再提交。
class _LevelSlider extends StatefulWidget {
  const _LevelSlider({
    required this.leading,
    required this.trailing,
    required this.initial,
    required this.min,
    required this.max,
    required this.onSubmit,
  });

  final Widget leading;
  final Widget trailing;
  final double initial;
  final double min;
  final double max;
  final Future<void> Function(int value) onSubmit;

  @override
  State<_LevelSlider> createState() => _LevelSliderState();
}

class _LevelSliderState extends State<_LevelSlider> {
  late double _value = widget.initial;
  double? _preview;

  double get _display => _preview ?? _value;

  void _commitOnRelease() {
    final next = (_preview ?? _value).clamp(widget.min, widget.max);
    final preview = _preview;
    _preview = null;
    if (preview == null || next.round() == _value.round()) {
      if (preview != null) setState(() {});
      return;
    }
    setState(() => _value = next);
    widget.onSubmit(next.round());
  }

  void _cancelPreview() {
    if (_preview == null) return;
    setState(() => _preview = null);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        widget.leading,
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerUp: (_) => _commitOnRelease(),
          onPointerCancel: (_) => _cancelPreview(),
          child: AppSlider(
            value: SliderValue.single(_display),
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).round(),
            onChanged: (value) => setState(() => _preview = value.start),
          ),
        ).expanded(),
        widget.trailing,
      ],
    );
  }
}

class _ScreenPowerDialog extends StatelessWidget {
  const _ScreenPowerDialog({required this.count, required this.onSubmit});

  final int? count;
  final Future<void> Function(bool on) onSubmit;

  @override
  Widget build(BuildContext context) {
    final title = count == null ? '屏幕开关' : '屏幕开关（$count 台）';

    return AppFormDialog(
      title: Text(title),
      constraints: const BoxConstraints(maxWidth: 320),
      content: Row(
        spacing: 12,
        children: [
          AppButton.primary(
            onPressed: () => onSubmit(true),
            child: const Text('开启'),
          ).expanded(),
          AppButton.outline(
            onPressed: () => onSubmit(false),
            child: const Text('关闭'),
          ).expanded(),
        ],
      ),
    );
  }
}
