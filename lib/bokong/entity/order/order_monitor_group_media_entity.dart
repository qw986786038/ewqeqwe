import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'order_monitor_feedback_entity.dart';

/// 监测拍摄分组媒体详情（GET group_media 响应 data）
@jsonSerializable
class OrderMonitorGroupMediaEntity {
  /// 拍摄分组信息
  OrderMonitorPeriodGroupEntity? group;

  /// 期次序号
  int? period_index;

  /// 已上传媒体列表
  List<OrderMonitorGroupMediaItemEntity>? items;
}

/// 监测拍摄分组媒体项
@jsonSerializable
class OrderMonitorGroupMediaItemEntity {
  int? id;

  int? group_id;

  int? plan_id;

  /// 文件访问地址
  String? file_url;

  /// 文件名
  String? file_name;

  /// 文件类型（如 image / video）
  String? file_type;

  /// 视频时长（秒）
  int? duration_sec;

  int? sort;

  /// 上传时间
  String? create_time;
}

/// 登记监测拍摄媒体（OSS 上传后 POST upload_media）
@jsonSerializable
class OrderMonitorUploadMediaEntity {
  String? order_no;

  int? order_detail_id;

  int? group_id;

  String? file_url;

  String? file_name;

  /// MIME 类型（如 image/png）
  String? file_type;
}
