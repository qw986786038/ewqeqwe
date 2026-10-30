import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 客户订单经营趋势（`/api/system/ad/v2/data_analysis_trends_order`）
@jsonSerializable
class AdDataAnalysisTrendsOrderEntity {
  /// 标题
  String? title;

  /// X 轴类目（如 `09-04`）
  List<String>? categories;

  /// 序列
  List<AdDataAnalysisTrendsOrderSeriesEntity>? series;
}

/// 经营趋势序列
@jsonSerializable
class AdDataAnalysisTrendsOrderSeriesEntity {
  /// 序列 key（如 `count`）
  String? key;

  /// 与 [AdDataAnalysisTrendsOrderEntity.categories] 对齐的数值
  List<num>? data;
}
