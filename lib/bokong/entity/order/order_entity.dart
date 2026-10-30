import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 广告订单
@jsonSerializable
class OrderEntity {
  /// 订单 ID
  int? id;

  /// 订单编号
  String? order_no;

  /// 订单名称
  String? order_name;

  /// 侧栏头像图标（http URL 或模版 JSON）
  String? avatar_icon;

  /// 客户名称
  String? customer_name;

  /// 行业（历史字段；列表接口见 [customer_order.customer_industry]）
  String? industry;

  /// 上下刊状态
  int? status;

  /// 开始日期
  String? start_time;

  /// 结束日期
  String? end_time;

  /// 播放时段
  OrderPlayPeriodEntity? play_period;

  /// 播放规则
  int? play_rule;

  /// 播放规则标签
  String? play_rule_label;

  /// 单条播放时长
  int? duration;

  /// 播放频次
  int? order_frequency;

  /// 排他规则信息
  OrderExclusiveRuleInfoEntity? exclusive_rule_info;

  /// 当前频次
  int? now_frequency;

  /// 溢出频次
  int? out_frequency;

  /// 当前已播频次
  int? now_play_frequency;

  /// 溢出占比
  int? out_per;

  /// 订单天数
  int? order_days;

  /// 付费类型
  int? order_pay;

  /// 付费类型标签
  String? order_pay_label;

  /// 业务来源：1 媒花秀 2 楼经理 3 SAAS
  int? source_type;

  /// 业务来源名称
  String? source_type_label;

  /// 素材数量
  int? media_num;

  /// 订单标签（order_detail）
  List<String>? tags;

  /// 是否排他：明细 exclusive_industry 非空为「排它」，否则空字符串
  String? exclusive;

  /// 终端数量
  int? terminal_count;

  /// 设备编号列表
  List<String>? device_nos;

  /// 关联终端列表
  List<OrderTerminalEntity>? terminal_list;

  /// 订单明细（列表项内嵌）
  OrderDetailEntity? detail;

  /// 订单摘要
  OrderCustomerOrderSummaryEntity? customer_order;

  /// 订单明细项（历史字段，新接口见 [detail]）
  List<OrderItemEntity>? items;
}

/// 订单摘要（customer_order_list 内嵌）
@jsonSerializable
class OrderCustomerOrderSummaryEntity {
  /// 客户名称
  String? customer_name;

  /// 客户行业
  String? customer_industry;

  /// 订单编号
  String? order_no;

  /// 业务来源名称
  String? source_type_label;

  /// 订单总状态：0 未执行 1 执行中 2 已完结
  int? main_status;

  /// 平均进度（如 25.26%）
  String? average_per;
}

/// 订单内嵌明细
@jsonSerializable
class OrderDetailEntity {
  String? order_no;

  int? customer_id;

  String? customer_no;

  String? customer_name;

  /// 客户类型：1 渠道 2 直客 3 代理
  int? type;

  /// 客户类型名称
  String? type_text;

  /// 排他行业
  List<int>? exclusive_industry;

  /// 排他时长（秒）
  int? exclusive_rule;

  /// 循环间隔（秒）
  int? loop_rule;

  String? remark;

  /// 订单明细自增 ID（t_customer_order_detail.id）
  int? order_detail_id;

  List<OrderItemEntity>? items;
}

/// 订单关联终端（根级 terminal_list）
@jsonSerializable
class OrderTerminalEntity {
  /// 终端 ID
  int? terminal_id;

  /// 设备编号
  String? device_no;

  /// 设备名称
  String? device_name;
}

/// 订单明细项关联终端（items[].terminal_list）
@jsonSerializable
class OrderItemTerminalEntity {
  /// 终端 ID（旧字段）
  int? id;

  /// 终端 ID（order_detail 新接口）
  int? terminal_id;

  /// 设备编号
  String? device_no;

  /// 点位名称（旧字段）
  String? point_name;

  /// 设备名称（order_detail 新接口）
  String? device_name;

  /// 城市
  String? city;

  /// 区县
  String? district;

  /// 详细地址
  String? detailed_address;

  /// 楼栋
  String? building;

  /// 媒体位置
  String? media_address;

  /// 终端状态
  int? status;

  /// 上刊率等（order_detail 可选）
  String? average_per;
}

/// 订单明细项
@jsonSerializable
class OrderItemEntity {
  int? id;

  int? media_id;

  String? media_title;

  String? file_path;

  /// 预览图地址（仅图片 / 视频）
  String? preview_path;

  String? start_time;

  String? end_time;

  String? send_time;

  String? send_end_time;

  int? duration;

  int? order_frequency;

  int? give_frequency;

  int? now_frequency;

  /// 排他行业 ID 列表
  List<int>? exclusive_industry;

  /// 排他时长（秒）
  int? exclusive_rule;

  /// 循环间隔（秒）
  int? loop_rule;

  int? order_pay;

  int? play_rule;

  /// 播放模式：1 正常播放，2 弹性播放
  int? play_model;

  String? cover_start_time;

  String? cover_end_time;

  String? terminal_ids;

  /// 关联终端列表
  List<OrderItemTerminalEntity>? terminal_list;

  int? out_days;

  int? status;

  /// 订单天数
  int? order_days;

  /// 付费类型标签
  String? order_pay_label;

  /// 播放时段
  OrderPlayPeriodEntity? play_period;

  /// 媒体类型
  int? media_type;
}

/// 播放时段
@jsonSerializable
class OrderPlayPeriodEntity {
  /// 开始时间
  String? start_time;

  /// 结束时间
  String? end_time;
}

/// 排他规则信息
@jsonSerializable
class OrderExclusiveRuleInfoEntity {
  /// 排他行业
  String? exclusive_industry;

  /// 循环间隔（秒）
  int? loop_rule;

  /// 排他时长（秒）
  int? exclusive_duration;
}
