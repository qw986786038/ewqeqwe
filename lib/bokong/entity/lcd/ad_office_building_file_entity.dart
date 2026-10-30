import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 写字楼文件详情（`/api/system/ad/file/office_building`）
@jsonSerializable
class AdOfficeBuildingFileEntity {
  /// 写字楼基础信息
  AdOfficeBuildingFileInfoEntity? file_info;

  /// 上刊率 TOP3
  List<AdOfficeBuildingPublishRateTopEntity>? publish_rate_top3;

  /// 标签
  List? tag_info;

  /// 设备占比
  AdOfficeBuildingDeviceProportionEntity? device_proportion;
}

/// 写字楼基础信息
@jsonSerializable
class AdOfficeBuildingFileInfoEntity {
  /// 写字楼名称
  String? name;

  /// 侧栏头像图标（http URL 或模版 JSON）
  String? avatar_icon;

  /// 设备总数
  int? device_total;

  /// 98 寸数量
  int? size_98_count;

  /// 86 寸数量
  int? size_86_count;

  /// 在线设备
  int? online_device;

  /// 离线设备
  int? offline_device;

  /// 异常设备
  int? abnormal_device;

  /// 运营天数
  int? operation_days;
}

/// 上刊率排行项
@jsonSerializable
class AdOfficeBuildingPublishRateTopEntity {
  /// 序号
  int? serial_number;

  /// 媒体位置
  String? media_position;

  /// 上刊率
  String? publish_rate;
}

/// 设备占比
@jsonSerializable
class AdOfficeBuildingDeviceProportionEntity {
  /// 设备总量
  int? total_device;

  /// 尺寸占比列表
  List<AdOfficeBuildingDeviceProportionItemEntity>? list;

  /// 今日播放量
  int? today_play_volume;

  /// 播放量较昨日
  int? play_volume_compare_yesterday;

  /// 设备总量较昨日
  int? device_total_compare_yesterday;
}

/// 设备占比项
@jsonSerializable
class AdOfficeBuildingDeviceProportionItemEntity {
  /// 指标 key
  String? key;

  /// 名称
  String? name;

  /// 数量
  int? count;

  /// 占比文案
  String? percent;
}
