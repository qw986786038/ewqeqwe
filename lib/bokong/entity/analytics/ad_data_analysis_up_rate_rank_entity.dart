import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析上刊率排行（`/api/system/ad/v2/data_analysis_up_rate_daily_rank`）
@jsonSerializable
class AdDataAnalysisUpRateRankEntity {
  /// 标题
  String? title;

  /// TOP 条数
  int? topType;

  /// 排行列表
  List<AdDataAnalysisUpRateRankItemEntity>? list;
}

/// 上刊率排行单项
@jsonSerializable
class AdDataAnalysisUpRateRankItemEntity {
  /// 名次
  int? rank;

  /// 名称
  String? name;

  /// 上刊率数值（如 100.0、4.6）
  num? total;

  /// 进度条分段
  List<AdDataAnalysisUpRateRankBarEntity>? progressBars;
}

/// 上刊率排行进度条
@jsonSerializable
class AdDataAnalysisUpRateRankBarEntity {
  /// 模块 key（如 `publish_rate`）
  String? key;

  /// 标签
  String? label;

  /// 数值
  num? value;

  /// 占比文案（如 `100.0%`）
  String? percentage;
}
