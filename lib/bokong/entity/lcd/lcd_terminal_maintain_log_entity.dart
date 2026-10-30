import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 终端维保 / 巡检记录附件
@jsonSerializable
class LcdTerminalMaintainLogFileEntity {
  /// 附件 ID
  int? id;

  /// 文件地址
  String? url;

  /// 文件名
  String? file_name;

  /// 文件类型（如 image）
  String? file_type;

  /// 时长（秒）
  int? duration_sec;

  /// 排序
  int? sort;
}

/// 终端维保 / 巡检记录
@jsonSerializable
class LcdTerminalMaintainLogEntity {
  /// 记录 ID
  int? id;

  /// 终端 ID
  int? terminal_id;

  /// 类型（1 维保 / 其它巡检等）
  int? type;

  /// 类型文案
  String? type_label;

  /// 标题
  String? title;

  /// 备注
  String? remark;

  /// 父记录 ID（回复时指向主记录）
  int? parent_id;

  /// 创建时间
  String? create_time;

  /// 附件列表
  List<LcdTerminalMaintainLogFileEntity>? files;

  /// 回复列表
  List<LcdTerminalMaintainLogEntity>? replies;
}

/// 新建维保 / 巡检记录请求体
@jsonSerializable
class LcdTerminalMaintainLogCreateEntity {
  /// 终端 ID
  int? terminal_id;

  /// 类型（1 维保）
  int? type;

  /// 标题
  String? title;

  /// 备注
  String? remark;

  /// 父记录 ID（0 表示新建主记录）
  int? parent_id;

  /// 附件列表
  List<LcdTerminalMaintainLogFileEntity>? files;
}
