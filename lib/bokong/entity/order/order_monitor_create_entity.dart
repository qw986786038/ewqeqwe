import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 创建 / 更新监测要求请求体
@jsonSerializable
class OrderMonitorCreateEntity {
  /// 订单编号
  String? order_no;

  /// 订单明细 ID（发布单 id）
  int? order_detail_id;

  /// 监测次数
  int? monitor_count;

  /// 基准日期（上刊时间）
  String? base_date;

  /// 间隔天数
  int? interval_days;

  /// 各次监测开始日期
  List<String>? period_starts;

  /// 时段类型（1 白天、2 夜间等）
  List<int>? time_types;

  /// 拍摄距离类型（1 远景、2 中景、3 近景）
  List<int>? distance_types;

  /// 水印类型（1 有水印、2 无水印等）
  List<int>? watermark_types;

  /// 水印样式
  int? watermark_style;

  /// 其他要求
  String? other_remark;
}
