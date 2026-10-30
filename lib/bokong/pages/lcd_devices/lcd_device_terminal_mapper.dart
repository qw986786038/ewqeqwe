import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_create_entity.dart';

/// 解析开关机时段：优先用 [time_slots]，否则从 [open_on_time] / [shutdown_time] 回退。
List<LcdDeviceTimeSlotEntity> lcdDeviceTimeSlotsOf(LcdDeviceEntity device) {
  final slots = device.time_slots;
  if (slots != null && slots.isNotEmpty) return slots;
  if (device.open_on_time?.trim().isNotEmpty == true ||
      device.shutdown_time?.trim().isNotEmpty == true) {
    return [
      LcdDeviceTimeSlotEntity()
        ..start_time = device.open_on_time
        ..end_time = device.shutdown_time,
    ];
  }
  return const [];
}

/// 开关机时段展示文案（每行一个时段）。
String lcdDevicePowerScheduleText(LcdDeviceEntity device) {
  final slots = lcdDeviceTimeSlotsOf(device);
  if (slots.isEmpty) return '';
  return slots
      .map((slot) => '${slot.start_time ?? ''}-${slot.end_time ?? ''}')
      .join('\n');
}

/// 将多行 `09:00-12:00` 文本解析为时段列表。
List<LcdDeviceTimeSlotEntity> lcdDeviceTimeSlotsFromText(String text) {
  final slots = <LcdDeviceTimeSlotEntity>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final parts = line.split('-');
    slots.add(
      LcdDeviceTimeSlotEntity()
        ..start_time = parts.first.trim()
        ..end_time = parts.length > 1 ? parts.sublist(1).join('-').trim() : '',
    );
  }
  return slots;
}

/// 分辨率展示文案。
String lcdDeviceResolutionText(LcdDeviceEntity device) {
  final w = device.screen_width;
  final h = device.screen_height;
  if (w != null && h != null) return '${w}x$h';
  return '';
}

/// 解析 `1920x1080` 分辨率文本。
(int? width, int? height) lcdDeviceResolutionFromText(String text) {
  final parts = text.toLowerCase().split('x');
  if (parts.length != 2) return (null, null);
  return (int.tryParse(parts[0].trim()), int.tryParse(parts[1].trim()));
}

/// 将设备详情转为修改接口请求体，保留当前全部可提交字段。
LcdTerminalCreateEntity lcdTerminalCreateFromDevice(LcdDeviceEntity device) {
  return LcdTerminalCreateEntity()
    ..device_type = device.device_type ?? 'LCD'
    ..point_name = device.point_name
    ..device_no = device.device_no
    ..city = device.city
    ..city_id = device.city_id
    ..district = device.district
    ..district_id = device.district_id
    ..road_name = device.road_name
    ..detailed_address = device.detailed_address
    ..lng = device.lng
    ..lat = device.lat
    ..building = device.building
    ..media_address = device.media_address
    ..media_size = device.media_size
    ..screen_width = device.screen_width
    ..screen_height = device.screen_height
    ..network_type = device.network_type
    ..time_slots = lcdDeviceTimeSlotsOf(device)
    ..accounting_date = int.tryParse(device.accounting_date ?? '')
    ..power_price = device.power_price?.toString()
    ..screen_brand = device.screen_brand
    ..brand_model = device.brand_model
    ..system_type = device.system_type ?? device.system_os
    ..maintenance_company = device.maintenance_company
    ..maintenance_person = device.maintenance_person
    ..maintenance_phone = device.maintenance_phone
    ..inspector = device.inspector
    ..inspection_department = device.inspection_department
    ..inspection_phone = device.inspection_phone
    ..property_name = device.property_name
    ..property_person = device.property_person
    ..property_phone = device.property_phone
    ..scene_pic = device.scene_pic
    ..remark = device.remark
    ..play_sound = device.play_sound
    ..is_volume =
        device.is_volume ??
        ((device.play_sound == true)
            ? 1
            : (device.play_sound == false ? 0 : null));
}

/// 将修改请求体中的字段合并回设备详情（接口响应字段不完整时保证界面与提交一致）。
LcdDeviceEntity lcdDeviceMergeTerminalParam(
  LcdDeviceEntity device,
  LcdTerminalCreateEntity param,
) {
  return device
    ..device_type = param.device_type ?? device.device_type
    ..point_name = param.point_name ?? device.point_name
    ..device_no = param.device_no ?? device.device_no
    ..city = param.city ?? device.city
    ..city_id = param.city_id ?? device.city_id
    ..district = param.district ?? device.district
    ..district_id = param.district_id ?? device.district_id
    ..road_name = param.road_name ?? device.road_name
    ..detailed_address = param.detailed_address ?? device.detailed_address
    ..lng = param.lng ?? device.lng
    ..lat = param.lat ?? device.lat
    ..building = param.building ?? device.building
    ..media_address = param.media_address ?? device.media_address
    ..media_size = param.media_size ?? device.media_size
    ..screen_width = param.screen_width ?? device.screen_width
    ..screen_height = param.screen_height ?? device.screen_height
    ..network_type = param.network_type ?? device.network_type
    ..time_slots = param.time_slots ?? device.time_slots
    ..accounting_date =
        param.accounting_date?.toString() ?? device.accounting_date
    ..power_price =
        double.tryParse(param.power_price ?? '') ?? device.power_price
    ..screen_brand = param.screen_brand ?? device.screen_brand
    ..brand_model = param.brand_model ?? device.brand_model
    ..system_type = param.system_type ?? device.system_type
    ..system_os = param.system_type ?? device.system_os
    ..maintenance_company =
        param.maintenance_company ?? device.maintenance_company
    ..maintenance_person = param.maintenance_person ?? device.maintenance_person
    ..maintenance_phone = param.maintenance_phone ?? device.maintenance_phone
    ..inspector = param.inspector ?? device.inspector
    ..inspection_department =
        param.inspection_department ?? device.inspection_department
    ..inspection_phone = param.inspection_phone ?? device.inspection_phone
    ..property_name = param.property_name ?? device.property_name
    ..property_person = param.property_person ?? device.property_person
    ..property_phone = param.property_phone ?? device.property_phone
    ..scene_pic = param.scene_pic ?? device.scene_pic
    ..remark = param.remark ?? device.remark
    ..play_sound = param.play_sound ?? device.play_sound
    ..is_volume =
        param.is_volume ??
        device.is_volume ??
        ((param.play_sound ?? device.play_sound) == true
            ? 1
            : ((param.play_sound ?? device.play_sound) == false ? 0 : null));
}

String lcdDeviceTextOrDash(String? value) {
  final text = value?.trim();
  return (text == null || text.isEmpty) ? '-' : text;
}

/// 是否允许音量（与列表筛选 `is_volume` 一致）。
bool lcdDeviceIsVolumeEnabled(LcdDeviceEntity device) => device.is_volume == 1;

String lcdDeviceNumOrDash(num? value) => value?.toString() ?? '-';

/// 次数类文案：空或非数字显示 `0`。
String lcdDeviceCountOrZero(String? value) {
  final n = int.tryParse(value?.trim() ?? '');
  return '${n ?? 0}';
}

/// 数值带单位；空值仍为 `-`（不带单位）。
String lcdDeviceNumWithUnit(num? value, String unit) {
  if (value == null) return '-';
  return '$value$unit';
}

/// 文本带单位；空值仍为 `-`；已含单位后缀则不重复追加。
String lcdDeviceTextWithUnit(String? value, String unit) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '-';
  if (text.endsWith(unit)) return text;
  return '$text$unit';
}
