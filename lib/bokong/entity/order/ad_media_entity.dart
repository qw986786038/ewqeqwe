import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 广告素材（素材库 / 订单选择等）
@jsonSerializable
class AdMediaEntity {
  int? id;

  /// 分类名称
  String? category_name;

  /// 客户名称
  String? customer_name;

  /// 素材编号
  String? media_no;

  /// 素材标题
  String? title;

  /// 描述
  String? description;

  /// 客户 ID
  int? customer_id;

  /// 分类 ID
  int? category_id;

  /// 媒体类型
  int? media_type;

  /// 文件格式
  String? file_format;

  /// 文件路径
  String? file_path;

  /// 文件 MD5
  String? file_md5;

  /// 文件大小
  String? file_size;

  /// 时长（秒）
  int? duration;

  /// 屏幕宽度
  int? screen_width;

  /// 屏幕高度
  int? screen_height;

  /// 预览路径
  String? preview_path;

  /// 循环次数
  int? loop_count;

  /// 播放频次
  int? order_frequency;

  /// 当前频次
  int? now_frequency;

  /// 终端 ID 列表
  String? terminal_ids;

  int? status;

  /// 审核人
  String? audit_user;

  /// 审核时间
  String? audit_time;

  /// 审核备注
  String? audit_remark;

  /// 开始日期
  String? start_time;

  /// 结束日期
  String? end_time;

  /// 上刊日期
  String? send_time;

  /// 是否删除
  int? is_delete;

  /// 删除时间
  String? delete_time;

  /// 创建时间
  String? create_time;

  /// 更新时间
  String? update_time;

  /// 创建人
  String? create_by;

  /// 更新人
  String? update_by;

  /// 推送状态
  int? push_status;

  /// 播放模式
  int? play_model;
}
