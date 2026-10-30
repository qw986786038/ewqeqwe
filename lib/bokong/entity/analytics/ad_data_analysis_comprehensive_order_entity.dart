import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 客户订单维度订单状态（`/api/system/ad/v2/data_analysis_comprehensive_order`）
@jsonSerializable
class AdDataAnalysisComprehensiveOrderEntity {
  /// 标题
  String? title;

  /// 总订单数
  num? total;

  /// 合计标签
  String? totalLabel;

  /// 状态分布
  List<AdDataAnalysisOrderStatusItemEntity>? statusDistribution;

  /// 到期卡片
  List<AdDataAnalysisOrderExpiringCardEntity>? expiringCards;
}

/// 订单状态分布项
@jsonSerializable
class AdDataAnalysisOrderStatusItemEntity {
  /// key（executing / completed / paused）
  String? key;

  /// 名称
  String? name;

  /// 数值
  num? value;

  /// 占比文案（如 `13.7%`）
  String? percentage;
}

/// 到期订单卡片
@jsonSerializable
class AdDataAnalysisOrderExpiringCardEntity {
  /// key（today / within_3_days / …）
  String? key;

  /// 标签
  String? label;

  /// 数值
  num? value;
}
