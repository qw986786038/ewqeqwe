import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 终端设备播放日志
@jsonSerializable
class LcdTerminalPlayLogEntity {
  /// 日志编号
  String? log_no;

  /// 设备编号
  String? device_no;

  int? play_type;

  /// 排期日期
  String? schedule_date;

  /// 素材标题
  String? media_title;

  /// 播放开始时间
  String? play_start_time;

  /// 播放结束时间
  String? play_end_time;

  /// 播放时长（秒）
  int? play_duration;
}
