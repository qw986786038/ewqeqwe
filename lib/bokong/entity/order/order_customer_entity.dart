import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 订单关联客户
@jsonSerializable
class OrderCustomerEntity {
  /// 客户 ID
  int? customer_id;

  /// 客户编号
  String? customer_no;

  /// 客户名称
  String? customer_name;

  /// 头像图标（http URL 或模版 JSON）
  String? avatar_icon;

  /// 行业主类名称
  String? industry;

  /// 行业子类名称（所选为子类时返回，仅父类时为空）
  String? sub_industry;

  /// 客户类型：0 渠道，1 直客，2 代理公司
  int? type;

  /// 客户类型文案
  String? type_text;

  /// 行业标签色值（接口 `color`，如 `#5394D6`）
  String? color;

  /// 素材数量
  int? media_count;

  /// 订单总数
  int? order_total_count;

  /// 已完成数量
  int? finished_count;

  /// 播放中数量
  int? playing_count;

  /// 暂停数量
  int? paused_count;

  /// 最后下单时间
  String? order_time;
}
