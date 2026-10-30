import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show TimeOfDay;

import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_power_period.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_utils.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_terminal_mapper.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 编辑开关机时段；确认返回时段文案，取消返回 `null`。
///
/// [forceOverwrite] 为批量强制覆盖时，弹窗会写明将替换所选设备原时段。
Future<String?> showDevicePowerScheduleDialog(
  BuildContext context, {
  required String initial,
  bool forceOverwrite = false,
  int? deviceCount,
}) {
  return showAppWindowDialog<String>(
    context: context,
    builder: (_) => DevicePowerScheduleDialog(
      initial: initial,
      forceOverwrite: forceOverwrite,
      deviceCount: deviceCount,
    ),
  ).future;
}

/// 设备详情 / 批量 · 开关机时间弹窗（时段选择，对齐新建设备）。
class DevicePowerScheduleDialog extends StatefulWidget {
  const DevicePowerScheduleDialog({
    required this.initial,
    this.forceOverwrite = false,
    this.deviceCount,
    super.key,
  });

  final String initial;
  final bool forceOverwrite;
  final int? deviceCount;

  @override
  State<DevicePowerScheduleDialog> createState() =>
      _DevicePowerScheduleDialogState();
}

class _DevicePowerScheduleDialogState extends State<DevicePowerScheduleDialog> {
  late final List<LcdDevicesAddPowerPeriod> _periods;

  @override
  void initState() {
    super.initState();
    _periods = _periodsFromText(widget.initial);
  }

  List<LcdDevicesAddPowerPeriod> _periodsFromText(String text) {
    final slots = lcdDeviceTimeSlotsFromText(text);
    if (slots.isEmpty) {
      return [
        LcdDevicesAddPowerPeriod(
          onTime: const TimeOfDay(hour: 8, minute: 0),
          offTime: const TimeOfDay(hour: 22, minute: 0),
        ),
      ];
    }
    return [
      for (final slot in slots)
        LcdDevicesAddPowerPeriod(
          onTime: lcdDevicesParseTimeOfDay(slot.start_time),
          offTime: lcdDevicesParseTimeOfDay(slot.end_time),
        ),
    ];
  }

  void _addPeriod() {
    setState(() => _periods.add(LcdDevicesAddPowerPeriod()));
  }

  Future<void> _removePeriod(int index) async {
    if (_periods.length <= 1) return;
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '删除时段',
      message: '确定删除该开关机时段吗？',
    );
    if (!confirmed || !mounted) return;
    setState(() => _periods.removeAt(index));
  }

  void _submit() {
    final slots = lcdDevicesTimeSlotsFromPeriods(_periods);
    if (slots.isEmpty) {
      showWarn('请至少填写一组开关机时段');
      return;
    }
    final text = slots
        .map((slot) => '${slot.start_time ?? ''}-${slot.end_time ?? ''}')
        .join('\n');
    AppOverlay.close<String>(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final title = widget.forceOverwrite ? '批量设置开关机时间' : '编辑开关机时间';
    final count = widget.deviceCount;
    final overwriteHint = count == null
        ? '此次为强制覆盖：保存后所选设备的原有开关机时段将被全部替换，无法按设备保留原设置。'
        : '此次为强制覆盖：保存后所选 $count 台设备的原有开关机时段将被全部替换，无法按设备保留原设置。';

    return AppFormDialog(
      title: Text(title),
      constraints: const BoxConstraints(maxWidth: 420),
      content: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.forceOverwrite)
            AppText.caption(
              overwriteHint,
              style: TextStyle(color: colors.destructive),
            ),
          for (var i = 0; i < _periods.length; i++)
            Row(
              spacing: 8,
              children: [
                AppTimePickerFormField(
                  hintText: '开机',
                  initialValue: _periods[i].onTime,
                  use24HourFormat: true,
                  onChanged: (v) => _periods[i].onTime = v,
                ).expanded(),
                AppText.caption(
                  '-',
                  style: TextStyle(color: colors.mutedForeground),
                ),
                AppTimePickerFormField(
                  hintText: '关机',
                  initialValue: _periods[i].offTime,
                  use24HourFormat: true,
                  onChanged: (v) => _periods[i].offTime = v,
                ).expanded(),
                if (i == 0)
                  AppIconButton(
                    icon: Icon(
                      AppLucideIcons.plus,
                      size: 16,
                      color: colors.primary,
                    ),
                    tooltip: '添加时段',
                    variant: AppButtonVariant.outline,
                    onPressed: _addPeriod,
                  )
                else
                  AppIconButton(
                    icon: Icon(
                      AppLucideIcons.minus,
                      size: 16,
                      color: colors.destructive,
                    ),
                    tooltip: '删除时段',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _removePeriod(i),
                  ),
              ],
            ),
        ],
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close<String>(context),
          child: const Text('取消'),
        ),
        AppButton.primary(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
