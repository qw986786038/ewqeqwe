import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 添加客户订单请求体
@jsonSerializable
class OrderCreateEntity {
  /// 客户 ID
  int? customer_id;

  /// 订单明细
  List<OrderCreateItemEntity>? items;
}

/// 添加订单明细项
@jsonSerializable
class OrderCreateItemEntity {
  /// 明细项 ID（编辑时传，对应 detail.items[].id）
  int? id;

  /// 素材 ID
  int? media_id;

  /// 素材标题
  String? media_title;

  /// 开始日期
  String? start_time;

  /// 结束日期
  String? end_time;

  /// 上刊日期
  String? send_time;

  /// 实际结束日期
  String? send_end_time;

  /// 单条播放时长
  int? duration;

  /// 播放频次
  int? order_frequency;

  /// 赠送频次
  int? give_frequency;

  /// 排他行业 ID 列表
  List<int>? exclusive_industry;

  /// 排他时长（秒）
  int? exclusive_rule;

  /// 循环间隔（秒）
  int? loop_rule;

  /// 付费类型
  int? order_pay;

  /// 播放规则
  int? play_rule;

  /// 播放模式：1 正常播放，2 弹性播放
  int? play_model;

  /// 终端 ID 列表（逗号分隔）
  String? terminal_ids;

  /// 覆盖开始时间
  String? cover_start_time;

  /// 覆盖结束时间
  String? cover_end_time;

  /// 溢出天数
  int? out_days;
}
