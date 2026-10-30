import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析物业公司设备排行（`/api/system/ad/v2/data_analysis_property_rank`）
@jsonSerializable
class AdDataAnalysisPropertyRankEntity {
  /// 标题
  String? title;

  /// TOP 条数
  int? topType;

  /// 排行列表
  List<AdDataAnalysisPropertyRankItemEntity>? list;
}

/// 物业公司排行单项
@jsonSerializable
class AdDataAnalysisPropertyRankItemEntity {
  /// 名次
  int? rank;

  /// 名称
  String? name;

  /// 合计
  int? total;

  /// 进度条分段
  List<AdDataAnalysisPropertyRankBarEntity>? progressBars;
}

/// 物业公司排行进度条
@jsonSerializable
class AdDataAnalysisPropertyRankBarEntity {
  /// 模块 key
  String? key;

  /// 标签
  String? label;

  /// 数值
  int? value;

  /// 占比文案
  String? percentage;
}
