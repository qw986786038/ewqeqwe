import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_address_field.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_power_period.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_constants.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/amap/amap_location_pick_result.dart';

/// 添加设备 ·「基本信息」Tab。
class LcdDevicesAddBasicTab extends StatelessWidget {
  const LcdDevicesAddBasicTab({
    required this.periods,
    required this.onAddPeriod,
    required this.onRemovePeriod,
    required this.mediaSizeOptions,
    required this.yesNoOptions,
    required this.location,
    required this.regionLabel,
    required this.onLocationPicked,
    super.key,
  });

  final List<LcdDevicesAddPowerPeriod> periods;
  final VoidCallback onAddPeriod;
  final ValueChanged<int> onRemovePeriod;
  final List<AppOption<String>> mediaSizeOptions;
  final List<AppOption<bool>> yesNoOptions;
  final AmapLocationPickResult? location;
  final String? regionLabel;
  final ValueChanged<AmapLocationPickResult> onLocationPicked;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextFormField(
          name: 'point_name',
          label: '点位名称',
          required: true,
          hintText: '请输入点位名称',
          inputFormatters: lcdMaxLengthFormatters(kLcdPointNameMaxLength),
          validator: AppValidators.compose([
            AppValidators.required(message: '不能为空'),
            (value) => lcdMaxLengthError(value, kLcdPointNameMaxLength),
          ]),
        ),
        LcdDevicesAddAddressField(
          location: location,
          regionLabel: regionLabel,
          onPicked: onLocationPicked,
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextFormField(
              name: 'building',
              label: '楼栋',
              required: true,
              hintText: '请输入楼栋',
              validator: AppValidators.required(message: '不能为空'),
            ).expanded(),
            AppTextFormField(
              name: 'media_address',
              label: '媒体位置',
              required: true,
              hintText: '请输入媒体位置',
              inputFormatters: lcdMaxLengthFormatters(kLcdMediaAddressMaxLength),
              validator: AppValidators.compose([
                AppValidators.required(message: '不能为空'),
                (value) => lcdMaxLengthError(value, kLcdMediaAddressMaxLength),
              ]),
            ).expanded(),
          ],
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSelectFormField<String>(
              name: 'media_size',
              label: '媒体尺寸',
              required: true,
              hintText: '请选择',
              options: mediaSizeOptions,
            ).expanded(),
            AppField(
              label: '分辨率',
              required: true,
              child: Row(
                spacing: 8,
                children: [
                  AppNumberInputFormField(
                    name: 'screen_width',
                    initialValue: 1920,
                    min: 1,
                    max: 7680,
                    inputWidth: 88,
                  ).expanded(),
                  AppText.caption(
                    '×',
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                  AppNumberInputFormField(
                    name: 'screen_height',
                    initialValue: 1080,
                    min: 1,
                    max: 4320,
                    inputWidth: 88,
                  ).expanded(),
                ],
              ),
            ).expanded(),
          ],
        ),
        AppField(
          label: '开关机时段',
          required: true,
          child: Builder(
            builder: (context) {
              return Column(
                spacing: 8,
                children: [
                  for (var i = 0; i < periods.length; i++)
                    Row(
                      spacing: 8,
                      children: [
                        AppTimePickerFormField(
                          hintText: '开机',
                          initialValue: periods[i].onTime,
                          use24HourFormat: true,
                          onChanged: (v) => periods[i].onTime = v,
                        ).expanded(),
                        AppText.caption(
                          '-',
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                        AppTimePickerFormField(
                          hintText: '关机',
                          initialValue: periods[i].offTime,
                          use24HourFormat: true,
                          onChanged: (v) => periods[i].offTime = v,
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
                            onPressed: onAddPeriod,
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
                            onPressed: () => onRemovePeriod(i),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        AppRadioGroupFormField<bool>(
          name: 'play_sound',
          label: '是否允许音量',
          required: true,
          valueDirection: Axis.horizontal,
          spacing: 24,
          initialValue: true,
          options: yesNoOptions,
        ),
      ],
    );
  }
}
