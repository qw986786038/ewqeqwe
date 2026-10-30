import 'package:dart_json_mapper/dart_json_mapper.dart';

/// LCD 终端设备详情
@jsonSerializable
class LcdDeviceEntity {
  /// 设备 ID
  int? id;

  /// 分组名称
  String? group_name;

  /// 开机时段列表
  List<LcdDeviceTimeSlotEntity>? time_slots;

  /// 时段数量
  int? time_slot_count;

  /// 能耗
  double? energy_consumption;

  /// 电费
  double? electricity_fee;

  /// 时段总时长（小时）
  double? slot_duration_hours_total;

  /// 累计在线时长文案
  String? total_history_time;

  /// 运营周期文案
  String? operational_period;

  /// 设备播放预览图（相对路径或 URL）
  List<String>? device_play_preview;

  /// 侧边栏设备信息摘要
  LcdDeviceInfoSummaryEntity? device_info;

  /// 节目单列表
  List<LcdDeviceProgramListItemEntity>? program_list;

  /// 上刊率
  LcdDevicePublishRateEntity? publish_rate;

  /// 订单数量
  int? order_num;

  double? playlog_tovc;

  /// CO₂
  double? playlog_co2;

  /// 空气质量指数
  double? playlog_aqi;

  /// 温度
  double? playlog_temp;

  /// 湿度
  double? playlog_humi;

  /// 电压
  double? playlog_voltage;

  /// 电流
  double? playlog_current;

  /// 功率
  double? playlog_power;

  /// 电量
  double? playlog_energy;

  /// 播控数据记录时间
  String? playlog_create_time;

  /// 预约重启时间
  String? reserve_restart_time;

  /// 设备类型
  String? device_type;

  /// 设备编号
  String? device_no;

  /// 点位编码
  String? point_code;

  /// 点位名称
  String? point_name;

  /// 所属楼宇 ID
  int? office_id;

  /// 绑定用户
  dynamic bind_user;

  /// 城市 ID
  int? city_id;

  /// 区县 ID
  int? district_id;

  /// 城市
  String? city;

  /// 区县
  String? district;

  /// 道路名称
  String? road_name;

  /// 物业名称
  String? property_name;

  /// 楼栋
  String? building;

  /// 媒体位置
  String? media_address;

  /// 详细地址
  String? detailed_address;

  /// 经度
  double? lng;

  /// 纬度
  double? lat;

  /// 媒体尺寸
  String? media_size;

  /// 屏幕宽度
  int? screen_width;

  /// 屏幕高度
  int? screen_height;

  /// 联网方式
  String? network_type;

  /// 总时长
  String? total_duration;

  /// 电费计费日期
  String? accounting_date;

  /// 电价
  double? power_price;

  /// 屏幕品牌
  String? screen_brand;

  /// 品牌型号
  String? brand_model;

  /// 系统类型
  String? system_type;

  /// 操作系统
  String? system_os;

  /// App 版本号
  String? app_version;

  /// App 版本 Code
  int? app_version_code;

  /// App 最近校验时间
  String? app_check_time;

  String? screen_level;
  String? screen_standard;

  /// 宽
  int? width;

  /// 高
  int? height;

  /// 数量
  int? quantity;

  /// 运营状态
  String? operation_status;

  int? status;

  /// 设备状态（如在线、离线）
  String? device_status;

  /// 亮度
  int? brightness;

  /// 日常音量
  int? volume_normal;

  /// 应急音量
  int? volume_emergency;

  /// IP 地址
  String? ip_address;

  /// MAC 地址
  String? mac_address;

  String? imei;
  String? tac;

  /// 最后在线时间
  String? last_online_time;

  /// 维保公司
  String? maintenance_company;

  /// 维保联系人
  String? maintenance_person;

  /// 维保电话
  String? maintenance_phone;

  /// 物业联系人
  String? property_person;

  /// 物业电话
  String? property_phone;

  /// 巡检部门
  String? inspection_department;

  /// 巡检人
  String? inspector;

  /// 巡检电话
  String? inspection_phone;

  /// 最后巡检时间
  String? last_inspection_time;

  /// 备注
  String? remark;

  /// 设备头像图标
  String? avatar_icon;

  /// 是否删除
  int? is_delete;

  /// 创建人
  dynamic create_by;

  /// 创建时间
  String? created_time;

  /// 更新时间
  String? updated_time;

  /// 开机时间
  String? open_on_time;

  /// 关机时间
  String? shutdown_time;

  /// 媒体系统二维码
  String? media_sys_qrcode;

  /// 现场照片（逗号分隔路径）
  String? scene_pic;

  /// 是否播放声音
  bool? play_sound;

  /// 是否允许音量：0 否，1 是
  int? is_volume;
}

@jsonSerializable
class LcdDeviceTimeSlotEntity {
  /// 时段序号
  int? slot_index;

  /// 开始时间
  String? start_time;

  /// 结束时间
  String? end_time;
}

/// 终端列表侧边栏 · 设备信息摘要
@jsonSerializable
class LcdDeviceInfoSummaryEntity {
  /// 设备名称
  String? device_name;

  /// 节目单数量
  int? program_count;

  /// 设备尺寸
  String? device_size;

  /// 今日播放次数
  int? today_play_count;

  /// 在线时长
  String? online_duration;
}

/// 终端列表侧边栏 · 节目单行
@jsonSerializable
class LcdDeviceProgramListItemEntity {
  /// 节目名称
  String? program_name;

  /// 广告时长（秒）
  int? ad_duration;

  /// 日播频次
  int? daily_play_frequency;

  /// 行业类型
  String? industry;
}

/// 终端列表侧边栏 · 上刊率
@jsonSerializable
class LcdDevicePublishRateEntity {
  /// 已上刊次数
  int? published_count;

  /// 未上刊次数
  int? unpublished_count;

  /// 上刊率文案（如 100.00%）
  String? rate;
}
