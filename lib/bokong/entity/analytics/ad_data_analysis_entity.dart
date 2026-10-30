import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析 KPI（`/api/system/ad/v2/data_analysis`）
@jsonSerializable
class AdDataAnalysisEntity {
  /// 统计日期
  String? date;

  /// 默认模块 key（接口字段名为 moudle）
  String? moudle;

  /// 概览指标卡（部分环境字段名）
  List<AdDataAnalysisOverviewEntity>? overview;

  /// 概览指标卡（线上返回 `kpiCards`）
  List<AdDataAnalysisOverviewEntity>? kpiCards;
}

/// 概览指标卡
@jsonSerializable
class AdDataAnalysisOverviewEntity {
  /// 指标 key
  String? key;

  /// 名称（订单 kpiCards）
  String? label;

  /// 名称（设备 overview 等）
  String? name;

  /// 数值
  int? value;

  /// 单位
  String? unit;

  /// 图标标识
  String? icon;

  /// 较昨日趋势
  AdDataAnalysisOverviewTrendEntity? trend;

  /// 占比（对象：label + value）
  AdDataAnalysisOverviewRatioEntity? ratio;
}

/// 概览趋势
@jsonSerializable
class AdDataAnalysisOverviewTrendEntity {
  /// 方向（up / down；订单字段）
  String? type;

  /// 方向（设备等旧字段）
  String? direction;

  /// 差值或百分比（接口可能是 int 或 String）
  dynamic value;

  /// 百分比文案（设备等旧字段）
  String? percent;

  /// 差值（设备等旧字段）
  int? diffValue;

  /// 对比说明（订单字段，如「较昨日」）
  String? compare;

  /// 对比说明（设备等旧字段）
  String? diffLabel;
}

/// 占比文案
@jsonSerializable
class AdDataAnalysisOverviewRatioEntity {
  /// 占比标签（如「占比」）
  String? label;

  /// 占比值（如 `90.9%`）
  String? value;
}
