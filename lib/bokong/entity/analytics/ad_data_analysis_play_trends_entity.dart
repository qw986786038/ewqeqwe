import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析播放趋势（`/api/system/ad/v2/data_analysis_play_trends`）
@jsonSerializable
class AdDataAnalysisPlayTrendsEntity {
  /// 标题
  String? title;

  /// 区间文案（如「近7天」）
  String? range;

  /// X 轴类目（如 `09-04`）
  List<String>? categories;

  /// 序列
  List<AdDataAnalysisPlayTrendsSeriesEntity>? series;
}

/// 播放趋势序列
@jsonSerializable
class AdDataAnalysisPlayTrendsSeriesEntity {
  /// 序列 key
  String? key;

  /// 名称
  String? name;

  /// 单位
  String? unit;

  /// 与 [AdDataAnalysisPlayTrendsEntity.categories] 对齐的数值
  List<num>? data;
}
