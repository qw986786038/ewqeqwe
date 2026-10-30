import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 监测反馈详情（创建 / 查询响应 data）
@jsonSerializable
class OrderMonitorFeedbackEntity {
  /// 订单明细 ID
  int? order_detail_id;

  /// 订单编号
  String? order_no;

  /// 上刊日期
  String? send_time;

  /// 下刊日期
  String? send_end_time;

  /// 剩余天数
  int? remaining_days;

  /// 上刊状态
  int? send_status;

  /// 配置是否可编辑
  bool? editable;

  /// 监测配置
  OrderMonitorConfigEntity? config;

  /// 拍摄组合列定义
  List<OrderMonitorComboColumnEntity>? combo_columns;

  /// 各监测期次
  List<OrderMonitorPeriodEntity>? periods;

  /// 总体进度
  OrderMonitorProgressEntity? progress;
}

/// 监测配置
@jsonSerializable
class OrderMonitorConfigEntity {
  int? id;

  /// 监测次数
  int? monitor_count;

  /// 基准日期
  String? base_date;

  /// 间隔天数
  int? interval_days;

  /// 时段类型
  List<int>? time_types;

  /// 拍摄距离类型
  List<int>? distance_types;

  /// 水印类型
  List<int>? watermark_types;

  /// 水印样式
  int? watermark_style;

  /// 其他要求
  String? other_remark;

  /// 各次监测开始日期
  List<String>? period_starts;

  int? status;
}

/// 拍摄组合列
@jsonSerializable
class OrderMonitorComboColumnEntity {
  int? col_index;

  int? sort;

  int? time_type;

  String? time_label;

  int? distance_type;

  String? distance_label;

  int? watermark_type;

  String? watermark_label;
}

/// 监测期次
@jsonSerializable
class OrderMonitorPeriodEntity {
  int? plan_id;

  int? period_index;

  String? monitor_date;

  String? monitor_end_date;

  String? date_label;

  String? job_code;

  int? status;

  /// 该期次下的拍摄分组
  List<OrderMonitorPeriodGroupEntity>? groups;
}

/// 监测期次拍摄分组
@jsonSerializable
class OrderMonitorPeriodGroupEntity {
  int? group_id;

  int? plan_id;

  String? job_code;

  int? col_index;

  int? sort;

  int? time_type;

  String? time_label;

  int? distance_type;

  String? distance_label;

  int? watermark_type;

  String? watermark_label;

  int? watermark_style;

  String? watermark_style_label;

  String? group_name;

  int? required_count;

  int? max_upload_count;

  int? completed_count;

  int? media_count;

  bool? is_completed;

  int? status;
}

/// 监测总体进度
@jsonSerializable
class OrderMonitorProgressEntity {
  int? completed;

  int? total;

  String? percent;
}

/// 修改监测期次日期
@jsonSerializable
class OrderMonitorUpdatePeriodEntity {
  String? order_no;

  int? order_detail_id;

  int? plan_id;

  int? period_index;

  String? monitor_date;

  String? monitor_end_date;
}
