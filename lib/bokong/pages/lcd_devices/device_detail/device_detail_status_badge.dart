import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/widget/lcd_device_status_icon.dart';

/// 详情顶栏状态徽标：14 号、不加粗。
Widget deviceDetailStatusBadge(LcdDeviceStatus status) {
  const size = AppBadgeSize(
    fontSize: 14,
    height: 20,
    padding: EdgeInsets.zero,
    iconSize: 12,
    contentGap: 4,
  );
  return switch (status) {
    LcdDeviceStatus.online => AppBadge.success(
      size: size,
      appearance: AppBadgeStyle.plain,
      leading: const LcdDeviceStatusIcon.online(size: 12),
      child: const Text('在线'),
    ),
    LcdDeviceStatus.offline => AppBadge.secondary(
      size: size,
      appearance: AppBadgeStyle.plain,
      leading: const LcdDeviceStatusIcon.offline(size: 12),
      child: const Text('离线'),
    ),
    LcdDeviceStatus.abnormal => AppBadge.destructive(
      size: size,
      appearance: AppBadgeStyle.plain,
      leading: const LcdDeviceStatusIcon.abnormal(size: 12),
      child: const Text('异常'),
    ),
  };
}
