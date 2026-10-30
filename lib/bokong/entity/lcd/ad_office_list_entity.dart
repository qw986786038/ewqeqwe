import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 写字楼列表（含汇总）
@jsonSerializable
class AdOfficeListDataEntity {
  /// 设备汇总
  AdOfficeListInfoEntity? info;

  /// 写字楼列表
  List<AdOfficeListItemEntity>? list;
}

/// 写字楼列表汇总
@jsonSerializable
class AdOfficeListInfoEntity {
  /// 设备总数
  int? deviceCount;

  /// 在线总数
  int? totalOnline;

  /// 离线总数
  int? totalOffline;

  /// 异常总数
  int? totalAbnormal;
}

/// 写字楼列表行
@jsonSerializable
class AdOfficeListItemEntity {
  /// 写字楼 ID
  int? office_id;

  /// 写字楼名称
  String? name;

  /// 头像图标（http URL 或模版 JSON）
  String? avatar_icon;

  /// 所属区域
  String? region;

  /// 地址
  String? address;

  int? status;

  /// 状态文案
  String? status_label;

  /// 在线设备数
  int? online;

  /// 离线设备数
  int? offline;

  /// 异常设备数
  int? abnormal;

  /// 楼栋
  String? building;

  /// 媒体位置
  String? media_address;

  /// 设备数
  int? deviceCount;

  /// 终端编号列表
  List<String>? terminal_list;
}
