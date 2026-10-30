import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_constants.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';

/// 新建设备 ·「设备信息」Tab。
class LcdDevicesAddDeviceTab extends StatelessWidget {
  const LcdDevicesAddDeviceTab({required this.systemOptions, super.key});

  final List<AppOption<String>> systemOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextFormField(
          name: 'terminal_code',
          label: '设备编号',
          hintText: '请输入内容',
        ),
        AppTextFormField(
          name: 'device_no',
          label: '播控绑定ID',
          required: true,
          hintText: '请输入内容',
          validator: AppValidators.required(message: '不能为空'),
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNumberInputFormField(
              name: 'accounting_date',
              label: '计费日期(每月)',
              required: true,
              initialValue: 1,
              min: 1,
              max: 31,
            ).expanded(),
            AppTextFormField(
              name: 'power_price',
              label: '电价/度',
              required: true,
              hintText: '数字',
              validator: AppValidators.required(message: '不能为空'),
            ).expanded(),
          ],
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextFormField(
              name: 'screen_brand',
              label: '屏幕品牌',
              required: true,
              hintText: '请输入内容',
              validator: AppValidators.required(message: '不能为空'),
            ).expanded(),
            AppTextFormField(
              name: 'brand_model',
              label: '品牌型号',
              required: true,
              hintText: '请输入内容',
              validator: AppValidators.required(message: '不能为空'),
            ).expanded(),
          ],
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSelectFormField<String>(
              name: 'system_type',
              label: '系统',
              required: true,
              hintText: '请选择',
              options: systemOptions,
            ).expanded(),
            AppSelectFormField<String>(
              name: 'network_type',
              label: '联网方式',
              required: true,
              hintText: '请选择',
              initialValue: '流量卡',
              options: kLcdNetworkTypeOptions,
            ).expanded(),
          ],
        ),
      ],
    );
  }
}
