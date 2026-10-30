import 'package:flutter/widgets.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';

/// 设备在线 / 离线 / 异常状态图标（圆形实心 PNG）。
///
/// 不要放进会 `ColorFiltered(srcIn)` 整层染色的祖先（当前上游 [AppTabs] 选中态仍会），
/// 否则白 X / 勾会被染成与圆环同色。修法见上游去掉 ColorFiltered，**不要**为此换掉本组件。
class LcdDeviceStatusIcon extends StatelessWidget {
  const LcdDeviceStatusIcon({super.key, required this.status, this.size = 14});

  const LcdDeviceStatusIcon.online({super.key, this.size = 14})
    : status = LcdDeviceStatus.online;

  const LcdDeviceStatusIcon.offline({super.key, this.size = 14})
    : status = LcdDeviceStatus.offline;

  const LcdDeviceStatusIcon.abnormal({super.key, this.size = 14})
    : status = LcdDeviceStatus.abnormal;

  final LcdDeviceStatus status;
  final double size;

  static const onlineAsset = 'assets/images/lcd/lcd_device_status_online.png';
  static const offlineAsset = 'assets/images/lcd/lcd_device_status_offline.png';
  static const abnormalAsset = 'assets/images/lcd/lcd_device_status_error.png';

  String get _asset => switch (status) {
    LcdDeviceStatus.online => onlineAsset,
    LcdDeviceStatus.offline => offlineAsset,
    LcdDeviceStatus.abnormal => abnormalAsset,
  };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}
