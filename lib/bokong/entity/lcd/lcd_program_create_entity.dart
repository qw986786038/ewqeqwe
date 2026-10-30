import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'package:yidivination/bokong/entity/order/order_create_entity.dart';

/// 创建节目（排期）请求体
@jsonSerializable
class LcdProgramCreateEntity {
  /// 排期 ID
  int? schedule_id;

  /// 客户 ID
  int? customer_id;

  /// 排他行业 ID 列表
  List<int>? exclusive_industry;

  /// 排他规则
  int? exclusive_rule;

  /// 轮播规则
  int? loop_rule;

  /// 节目明细
  List<OrderCreateItemEntity>? items;

  /// 确认重新上刊
  int? confirm_relist;
}
