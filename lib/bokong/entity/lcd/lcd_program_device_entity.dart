import 'package:dart_json_mapper/dart_json_mapper.dart';

/// LCD 节目排期设备列表项
@jsonSerializable
class LcdProgramDeviceEntity {
  /// 排期 ID
  int? id;

  /// 排期编号
  String? schedule_no;

  /// 排期名称
  String? schedule_name;

  /// 终端 ID
  int? terminal_id;

  /// 排期日期
  String? schedule_date;

  /// 商业素材数
  int? business_num;

  /// 公益素材数
  int? public_num;

  /// 收费数量
  int? charge_num;

  /// 赠送数量
  int? gift_num;

  /// 素材总数
  int? total_num;

  /// 商业占比
  double? business_per;

  /// 公益占比
  double? public_per;

  /// 总上刊占比
  double? total_up_per;

  /// 总空刊占比
  double? total_empty_per;

  /// 公益空刊占比
  double? total_empty_public_per;

  int? status;

  /// 创建人
  String? create_by;

  /// 创建时间
  String? create_time;

  /// 终端设备编号
  String? terminal_device_no;

  /// 终端点位编码
  String? terminal_point_code;

  /// 终端点位名称
  String? terminal_point_name;

  /// 终端城市
  String? terminal_city;

  /// 终端区县
  String? terminal_district;

  /// 终端道路名称
  String? terminal_road_name;

  /// 终端详细地址
  String? terminal_detailed_address;

  /// 终端楼栋
  String? terminal_building;

  int? terminal_status;

  /// 终端设备状态
  String? terminal_device_status;

  /// 终端总时长
  String? terminal_total_duration;

  /// 当日任务是否使用新排期 ID
  bool? task_daily_uses_new_schedule_id;
}
