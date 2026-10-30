import 'package:lemon_shadcn/shadcn.dart' show TimeOfDay;

/// 添加设备 · 开关机时段。
class LcdDevicesAddPowerPeriod {
  LcdDevicesAddPowerPeriod({this.onTime, this.offTime});

  TimeOfDay? onTime;
  TimeOfDay? offTime;
}
