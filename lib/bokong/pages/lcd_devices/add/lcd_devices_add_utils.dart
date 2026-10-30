import 'package:lemon_shadcn/shadcn.dart' show TimeOfDay;

import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_power_period.dart';

String lcdDevicesFormatTimeOfDay(TimeOfDay? time) {
  if (time == null) return '';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? lcdDevicesParseTimeOfDay(String? text) {
  final parts = (text ?? '').trim().split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

List<LcdDeviceTimeSlotEntity> lcdDevicesTimeSlotsFromPeriods(
  List<LcdDevicesAddPowerPeriod> periods,
) {
  final slots = <LcdDeviceTimeSlotEntity>[];
  for (final period in periods) {
    final start = lcdDevicesFormatTimeOfDay(period.onTime);
    final end = lcdDevicesFormatTimeOfDay(period.offTime);
    if (start.isEmpty && end.isEmpty) continue;
    slots.add(
      LcdDeviceTimeSlotEntity()
        ..start_time = start
        ..end_time = end,
    );
  }
  return slots;
}
