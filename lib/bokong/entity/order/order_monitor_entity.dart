import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 订单监测要求分组
@jsonSerializable
class OrderMonitorGroupEntity {
  /// 分组键
  String? item_key;

  /// 日期模式：single / range
  String? date_mode;

  /// 开始日期
  String? date_start;

  /// 结束日期
  String? date_end;

  /// 时段类型
  List<int>? time_types;

  /// 时段类型标签
  List<String>? time_type_labels;

  /// 拍摄距离类型
  int? distance_type;

  /// 拍摄距离标签
  String? distance_label;

  /// 条件要求类型
  List<int>? requirement_types;

  /// 条件要求标签
  List<String>? requirement_labels;

  /// 自定义要求
  String? custom_value;

  /// 排序
  int? sort;
}

/// 订单监测要求项
@jsonSerializable
class OrderMonitorItemEntity {
  /// 监测要求 ID
  int? id;

  /// 关联计划 ID 列表
  List<int>? plan_ids;

  /// 开始日期
  String? date_start;

  /// 结束日期
  String? date_end;

  /// 时段类型
  List<int>? time_types;

  /// 时段类型标签
  List<String>? time_type_labels;

  /// 备注
  String? remark;

  /// 监测分组
  List<OrderMonitorGroupEntity>? groups;

  /// 创建时间
  String? create_time;
}

/// 订单监测要求
@jsonSerializable
class OrderMonitorEntity {
  /// 订单 ID
  int? order_id;

  /// 订单编号
  String? order_no;

  /// 监测要求列表
  List<OrderMonitorItemEntity>? items;
}
