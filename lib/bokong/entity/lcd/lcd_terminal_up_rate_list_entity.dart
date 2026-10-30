import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 终端上刊率区间对比（`/api/system/ad/v2/terminal_up_rate_list`）
@jsonSerializable
class LcdTerminalUpRateListEntity {
  /// 时间范围标识（如 custom）
  String? timeRange;

  /// 开始日期
  String? startDate;

  /// 结束日期
  String? endDate;

  /// 汇总指标
  LcdTerminalUpRateListSummaryEntity? summary;

  /// 趋势图
  LcdTerminalUpRateListTrendEntity? trendChart;
}

/// 区间汇总
@jsonSerializable
class LcdTerminalUpRateListSummaryEntity {
  /// 此设备平均上刊率
  String? deviceAvgRate;

  /// TOP1 设备平均上刊率
  String? top1AvgRate;

  /// 与 TOP1 的差值
  String? gapWithTop1;
}

/// 趋势图
@jsonSerializable
class LcdTerminalUpRateListTrendEntity {
  /// 日期列表
  List<String>? dateList;

  /// 当前设备序列
  LcdTerminalUpRateListSeriesEntity? currentDevice;

  /// TOP1 设备序列
  LcdTerminalUpRateListSeriesEntity? top1Device;
}

/// 趋势序列
@jsonSerializable
class LcdTerminalUpRateListSeriesEntity {
  /// 设备名称
  String? name;

  /// 上刊率列表（与 dateList 对齐，0~100）
  List<double>? rateList;
}
