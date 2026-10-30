import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 增值服务保存请求（POST save_monitor_vas）
@jsonSerializable
class OrderMonitorVasSaveEntity {
  /// 订单明细 ID
  int? order_detail_id;

  /// 拍摄要求
  OrderMonitorVasShootingEntity? shooting;

  /// 自定义要求
  OrderMonitorVasCustomEntity? custom;

  /// 输出要求
  OrderMonitorVasOutputEntity? output;

  /// 传播要求
  OrderMonitorVasPublishEntity? publish;
}

/// 增值服务详情（GET get_monitor_vas）
@jsonSerializable
class OrderMonitorVasEntity {
  /// 该子订单是否已有增值包
  bool? exists;

  /// 增值包主键
  int? vas_id;

  /// 订单明细 ID
  int? order_detail_id;

  /// 客户订单编号
  String? order_no;

  /// 外部子订单号
  String? sub_order_no;

  /// 包状态：0 待执行、1 进行中、2 已完成
  int? status;

  /// 整包备注
  String? remark;

  /// 拍摄要求
  OrderMonitorVasShootingEntity? shooting;

  /// 自定义要求
  OrderMonitorVasCustomEntity? custom;

  /// 输出要求
  OrderMonitorVasOutputEntity? output;

  /// 传播要求
  OrderMonitorVasPublishEntity? publish;
}

/// 拍摄要求
@jsonSerializable
class OrderMonitorVasShootingEntity {
  /// 是否启用无人机（0/1）
  int? drone_enabled;

  /// 无人机镜头数量
  int? drone_lens_count;

  /// 无人机原片
  List<OrderMonitorVasMediaEntity>? drone_media;

  /// 是否启用延时（0/1）
  int? timelapse_enabled;

  /// 延时时长（分钟）
  int? timelapse_minutes;

  /// 延时原片
  List<OrderMonitorVasMediaEntity>? timelapse_media;
}

/// 自定义要求
@jsonSerializable
class OrderMonitorVasCustomEntity {
  /// 是否启用（0/1）
  int? enabled;

  /// 自定义条目
  List<OrderMonitorVasCustomItemEntity>? items;
}

/// 自定义要求条目
@jsonSerializable
class OrderMonitorVasCustomItemEntity {
  /// 该行主键
  int? id;

  /// 要求名称
  String? req_name;

  /// 要求内容
  String? req_content;

  /// 排序
  int? sort;

  /// 该行原片
  List<OrderMonitorVasMediaEntity>? media;
}

/// 输出要求
@jsonSerializable
class OrderMonitorVasOutputEntity {
  /// 是否启用（0/1）
  int? enabled;

  /// 成片条数
  int? count;

  /// 各成片条目
  List<OrderMonitorVasOutputItemEntity>? items;

  /// 输出成品视频
  List<OrderMonitorVasMediaEntity>? media;
}

/// 输出成片条目
@jsonSerializable
class OrderMonitorVasOutputItemEntity {
  /// 该行主键
  int? id;

  /// 剪辑时长（秒）
  int? edit_seconds;

  /// 备注
  String? remark;

  /// 排序
  int? sort;
}

/// 传播要求各平台开关（0/1）
@jsonSerializable
class OrderMonitorVasPublishEntity {
  /// 微信公众号
  int? wechat_mp;

  /// 微信视频号
  int? wechat_channels;

  /// 微信朋友圈
  int? wechat_moments;

  /// 今日头条
  int? toutiao;

  /// 抖音
  int? douyin;

  /// 网站
  int? website;

  /// 微博
  int? weibo;
}

/// 增值服务媒体项
@jsonSerializable
class OrderMonitorVasMediaEntity {
  /// 素材记录主键
  int? id;

  /// 文件访问地址
  String? url;

  /// 原始文件名
  String? file_name;

  /// 文件类型，如 image/video
  String? file_type;

  /// 视频时长（秒）
  int? duration_sec;

  /// 素材排序
  int? sort;
}

/// 增值服务保存响应 data
@jsonSerializable
class OrderMonitorVasSaveResultEntity {
  /// 增值服务记录 ID
  int? vas_id;

  /// 订单明细 ID
  int? order_detail_id;

  /// 订单编号
  String? order_no;

  /// 子订单编号
  String? sub_order_no;

  /// 无人机素材数量
  int? drone_media_count;

  /// 延时素材数量
  int? timelapse_media_count;

  /// 自定义要求条数
  int? custom_count;

  /// 输出成片条数
  int? output_count;

  /// 输出成品视频数量
  int? output_media_count;
}
