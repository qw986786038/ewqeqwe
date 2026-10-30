import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 终端单日上刊率（`/api/system/ad/v2/terminal_up_rate_daily`）
@jsonSerializable
class LcdTerminalUpRateDailyEntity {
  /// 设备编号
  String? deviceId;

  /// 设备名称
  String? deviceName;

  /// 楼栋
  String? building;

  /// 楼层
  String? floor;

  /// 在线状态
  int? onlineStatus;

  /// 在线状态文案
  String? onlineStatusText;

  /// 上刊率
  double? publishRate;

  /// 执行状态
  int? executeStatus;

  /// 执行状态文案
  String? executeStatusText;

  /// 查询日期
  String? queryDate;

  /// 统计明细
  LcdTerminalUpRateDailyStatisticsEntity? statistics;
}

/// 单日上刊统计
@jsonSerializable
class LcdTerminalUpRateDailyStatisticsEntity {
  /// 应上刊次数
  int? shouldPublishCount;

  /// 已上刊次数
  int? publishedCount;

  /// 未上刊次数
  int? unpublishedCount;
}
