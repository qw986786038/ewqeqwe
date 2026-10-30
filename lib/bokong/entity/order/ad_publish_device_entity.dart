import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 发布终端（订单绑定终端）
@jsonSerializable
class AdPublishDeviceEntity {
  int? id;

  /// 终端 ID（订单 terminal_ids 绑定字段）
  int? terminal_id;

  /// 设备编号
  String? device_no;

  /// 设备名称
  String? device_name;

  int? status;

  /// 状态标签
  String? status_label;

  /// 屏幕宽度
  int? screen_width;

  /// 屏幕高度
  int? screen_height;

  /// 分辨率
  String? resolution;

  /// 分组 ID
  int? group_id;

  /// 分组名称
  String? group_name;

  /// 节目任务
  String? program_task;

  /// 节目进度
  String? program_progress;
}
