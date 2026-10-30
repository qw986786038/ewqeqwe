/// 添加设备弹窗 Tab。
enum AddDeviceTab { basic, device, maintenance }

/// 添加设备表单：各 Tab 注册的 AppForm 字段名（用于跨 Tab 校验定位）。
abstract final class LcdDevicesAddTabFields {
  static const basic = [
    'point_name',
    'detailed_address',
    'building',
    'media_address',
    'media_size',
    'screen_width',
    'screen_height',
    'play_sound',
  ];

  static const device = [
    'device_no',
    'accounting_date',
    'power_price',
    'screen_brand',
    'brand_model',
    'system_type',
    'network_type',
  ];

  static const maintenance = [
    'property_name',
    'property_person',
    'property_phone',
    'maintenance_company',
    'maintenance_person',
    'maintenance_phone',
    'inspection_department',
    'inspector',
    'inspection_phone',
  ];

  static const tabOrder = [
    (AddDeviceTab.basic, basic),
    (AddDeviceTab.device, device),
    (AddDeviceTab.maintenance, maintenance),
  ];

  static String hintFor(AddDeviceTab tab) => switch (tab) {
    AddDeviceTab.basic => '请完善「基本信息」中的必填项',
    AddDeviceTab.device => '请完善「设备信息」中的必填项',
    AddDeviceTab.maintenance => '请完善「维保巡检」中的必填项',
  };

  static bool isEmptyRequired(String name, Map<String, Object?> values) {
    final value = values[name];
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }
}
