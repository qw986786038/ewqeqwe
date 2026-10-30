import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析设备维度综合数据（`/api/system/ad/v2/data_analysis_comprehensive`）
@jsonSerializable
class AdDataAnalysisComprehensiveEntity {
  /// 仪表盘区块（设备情况 / 设备使用效率）
  List<AdDataAnalysisComprehensiveDashboardEntity>? dashboard;

  /// 环图等图表
  List<AdDataAnalysisComprehensiveChartEntity>? charts;
}

/// 仪表盘区块
@jsonSerializable
class AdDataAnalysisComprehensiveDashboardEntity {
  /// 标题
  String? title;

  /// 类型：`list` / `cards`
  String? type;

  /// 条目
  List<AdDataAnalysisComprehensiveItemEntity>? items;
}

/// 仪表盘条目
@jsonSerializable
class AdDataAnalysisComprehensiveItemEntity {
  /// 标签
  String? label;

  /// 数值
  num? value;

  /// 单位
  String? unit;

  /// 图标标识（list 类型）
  String? icon;
}

/// 图表区块
@jsonSerializable
class AdDataAnalysisComprehensiveChartEntity {
  /// 标题
  String? title;

  /// 类型：`donut`
  String? type;

  /// 合计
  num? total;

  /// 合计标签
  String? totalLabel;

  /// 图例
  List<AdDataAnalysisComprehensiveLegendEntity>? legend;
}

/// 环图图例
@jsonSerializable
class AdDataAnalysisComprehensiveLegendEntity {
  /// 标签
  String? label;

  /// 数值
  num? value;

  /// 占比（0~100）
  num? percent;
}
