import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 数据分析下半部分（排行 / 趋势）
@jsonSerializable
class AdDataAnalysisRankEntity {
  /// 上刊率排行（设备管理 type=1）
  AdDataAnalysisRankBlockEntity? publicationRateRanking;

  /// 物业公司关联设备数量排行（设备管理 type=1）
  AdDataAnalysisRankBlockEntity? propertyCompanyDeviceRanking;

  /// 客户订单排行
  AdDataAnalysisRankBlockEntity? customerOrderRanking;

  /// 所属行业订单排行
  AdDataAnalysisRankBlockEntity? industryOrderRanking;

  /// 物业(写字楼)订单排行
  AdDataAnalysisRankBlockEntity? propertyOrderRanking;

  /// 客户订单趋势图
  AdDataAnalysisRankTrendEntity? customerOrderTrend;
}

/// 单个排行区块
@jsonSerializable
class AdDataAnalysisRankBlockEntity {
  /// 标题
  String? title;

  /// TOP 文案（如 TOP20）
  String? top;

  /// 分页
  AdDataAnalysisRankPaginationEntity? pagination;

  /// 排行列表
  List<AdDataAnalysisRankRowEntity>? list;
}

/// 排行分页
@jsonSerializable
class AdDataAnalysisRankPaginationEntity {
  /// 当前页
  int? currentPage;

  /// 总页数
  int? totalPages;
}

/// 排行列表行（各榜字段名不同，统一可空）
@jsonSerializable
class AdDataAnalysisRankRowEntity {
  /// 名次
  int? rank;

  /// 媒体位置 / 点位 / 物业名称（设备下半排行）
  String? mediaLocation;

  /// 上刊率（如 100.00%）
  String? rate;

  /// 设备数量
  int? deviceCount;

  /// 客户名称
  String? customerName;

  /// 行业名称
  String? industryName;

  /// 物业名称
  String? propertyName;

  /// 订单数量
  int? orderCount;

  /// 单位
  String? unit;
}

/// 趋势图
@jsonSerializable
class AdDataAnalysisRankTrendEntity {
  /// 标题
  String? title;

  /// X 轴
  AdDataAnalysisRankTrendXAxisEntity? xAxis;

  /// Y 轴
  AdDataAnalysisRankTrendYAxisEntity? yAxis;

  /// 序列
  List<AdDataAnalysisRankTrendSeriesEntity>? series;

  /// 提示默认值
  AdDataAnalysisRankTrendTooltipEntity? tooltip;
}

/// 趋势 X 轴
@jsonSerializable
class AdDataAnalysisRankTrendXAxisEntity {
  /// 类型（如 date）
  String? type;

  /// 格式（如 MM-DD）
  String? format;
}

/// 趋势 Y 轴
@jsonSerializable
class AdDataAnalysisRankTrendYAxisEntity {
  /// 客户订单数量轴
  AdDataAnalysisRankTrendAxisMetricEntity? orderCount;

  /// 客户数量轴
  AdDataAnalysisRankTrendAxisMetricEntity? customerCount;
}

/// 趋势 Y 轴指标
@jsonSerializable
class AdDataAnalysisRankTrendAxisMetricEntity {
  /// 标签
  String? label;

  /// 单位
  String? unit;
}

/// 趋势序列
@jsonSerializable
class AdDataAnalysisRankTrendSeriesEntity {
  /// 序列名称
  String? name;

  /// 颜色
  String? color;

  /// 数据点
  List<AdDataAnalysisRankTrendPointEntity>? data;
}

/// 趋势数据点
@jsonSerializable
class AdDataAnalysisRankTrendPointEntity {
  /// 日期（如 08-01）
  String? date;

  /// 数值
  int? value;
}

/// 趋势 tooltip
@jsonSerializable
class AdDataAnalysisRankTrendTooltipEntity {
  /// 日期
  String? date;

  /// 订单数量
  int? orderCount;

  /// 客户数量
  int? customerCount;
}
