import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析行政区域排行（`/api/system/ad/v2/data_analysis_district_rank`）
@jsonSerializable
class AdDataAnalysisDistrictRankEntity {
  /// 标题
  String? title;

  /// TOP 条数
  int? topType;

  /// 排行列表
  List<AdDataAnalysisDistrictRankItemEntity>? list;
}

/// 行政区域排行单项
@jsonSerializable
class AdDataAnalysisDistrictRankItemEntity {
  /// 名次
  int? rank;

  /// 名称
  String? name;

  /// 合计
  int? total;

  /// 进度条分段
  List<AdDataAnalysisDistrictRankBarEntity>? progressBars;
}

/// 行政区域排行进度条
@jsonSerializable
class AdDataAnalysisDistrictRankBarEntity {
  /// 模块 key
  String? key;

  /// 标签
  String? label;

  /// 数值
  int? value;

  /// 占比文案
  String? percentage;
}
