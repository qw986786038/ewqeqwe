import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 物业列表（含汇总）
@jsonSerializable
class AdPropertyListDataEntity {
  /// 设备汇总
  AdPropertyListInfoEntity? info;

  /// 物业列表
  List<AdPropertyListItemEntity>? list;
}

/// 物业列表汇总
@jsonSerializable
class AdPropertyListInfoEntity {
  /// 设备总数
  int? deviceCount;

  /// 在线总数
  int? totalOnline;

  /// 离线总数
  int? totalOffline;

  /// 异常总数
  int? totalAbnormal;
}

/// 物业列表行
@jsonSerializable
class AdPropertyListItemEntity {
  /// 物业 ID
  int? property_id;

  /// 物业名称
  String? name;

  /// 所属区域
  String? region;

  /// 地址
  String? address;

  /// 在线数
  int? online;

  /// 离线数
  int? offline;

  /// 异常数
  int? abnormal;

  /// 设备数
  int? deviceCount;
}
