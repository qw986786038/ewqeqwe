import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 客户订单文件详情（`/api/system/ad/file/customer_order`，ShowDoc 1585）
@jsonSerializable
class AdCustomerOrderFileEntity {
  /// 主订单文件信息
  AdCustomerOrderFileInfoEntity? file_info;

  /// 标签列表
  List? tag_list;

  /// 发布单信息列表
  List<AdCustomerOrderPublishInfoEntity>? publish_order_info;
}

/// 主订单文件信息
@jsonSerializable
class AdCustomerOrderFileInfoEntity {
  /// 客户名称
  String? name;

  /// 侧栏头像图标（http URL 或模版 JSON）
  String? avatar_icon;

  /// 订单天数
  int? order_days;

  /// 计费类型（如「付费」）
  String? charge_type;
}

/// 发布单信息
@jsonSerializable
class AdCustomerOrderPublishInfoEntity {
  /// 播放形式（如「轮播」）
  String? play_type;

  /// 播放频次（如「120次/天」）
  String? play_frequency;

  /// 订单天数
  int? order_days;

  /// 播放模式（如「正常播放」）
  String? play_mode;

  /// 上刊日期
  String? publish_date_start;

  /// 下刊日期
  String? publish_date_end;

  /// 订单状态
  int? order_status;

  /// 进度（0–100）
  int? progress;
}
