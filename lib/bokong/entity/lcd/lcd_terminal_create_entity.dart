import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'lcd_device_entity.dart';

/// 添加 LCD 终端设备请求体
@jsonSerializable
class LcdTerminalCreateEntity {
  /// 设备类型
  String? device_type;

  /// 城市 ID
  int? city_id;

  /// 城市
  String? city;

  /// 区县 ID
  int? district_id;

  /// 区县
  String? district;

  /// 道路名称
  String? road_name;

  /// 详细地址
  String? detailed_address;

  /// 经度
  double? lng;

  /// 纬度
  double? lat;

  /// 媒体尺寸
  String? media_size;

  /// 楼栋
  String? building;

  /// 媒体位置
  String? media_address;

  /// 点位名称
  String? point_name;

  /// 播控绑定 ID
  String? device_no;

  /// 屏幕宽度
  int? screen_width;

  /// 屏幕高度
  int? screen_height;

  /// 联网方式
  String? network_type;

  /// 开机时段列表
  List<LcdDeviceTimeSlotEntity>? time_slots;

  /// 电费计费日期
  int? accounting_date;

  /// 电价
  String? power_price;

  /// 屏幕品牌
  String? screen_brand;

  /// 品牌型号
  String? brand_model;

  /// 系统类型
  String? system_type;

  /// 维保公司
  String? maintenance_company;

  /// 维保联系人
  String? maintenance_person;

  /// 维保电话
  String? maintenance_phone;

  /// 巡检人
  String? inspector;

  /// 巡检部门
  String? inspection_department;

  /// 巡检电话
  String? inspection_phone;

  /// 物业名称
  String? property_name;

  /// 物业联系人
  String? property_person;

  /// 物业电话
  String? property_phone;

  /// 现场照片（逗号分隔路径）
  String? scene_pic;

  /// 备注
  String? remark;

  /// 是否播放声音
  bool? play_sound;

  /// 是否允许音量：0 否，1 是
  int? is_volume;
}
