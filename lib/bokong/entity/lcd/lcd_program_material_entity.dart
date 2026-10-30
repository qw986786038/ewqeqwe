import 'package:dart_json_mapper/dart_json_mapper.dart';

/// LCD 节目排期素材列表项
@jsonSerializable
class LcdProgramMaterialEntity {
  int? id;

  /// 排期 ID
  int? schedule_id;

  /// 订单详情 ID
  int? order_detail_id;

  /// 播放排序
  int? play_sort;

  /// 当前频次
  int? now_frequency;

  /// 当前已播频次
  int? now_play_frequency;

  /// 节目状态（播放状态：1=播放中，2=暂停，3=已结束）
  int? program_status;

  int? row_status;

  /// 是否删除
  int? is_delete;

  /// 订单类型（1 商业 / 2 公益）
  int? param_rule;

  /// 付费类型
  int? order_pay;

  /// 付费类型标签
  String? order_pay_label;

  /// 创建人
  String? create_by;

  /// 创建时间
  String? create_time;

  /// 更新人
  String? update_by;

  /// 更新时间
  String? update_time;

  /// 行业分类标签颜色
  String? color;

  /// 订单详情状态（0=未执行，1=执行中，2=已完结）
  int? order_detail_status;

  /// 订单详情播放规则
  int? order_detail_play_rule;

  /// 订单详情上刊时间
  String? order_detail_send_time;

  /// 订单详情覆盖开始
  String? order_detail_cover_start;

  /// 订单详情覆盖结束
  String? order_detail_cover_end;

  /// 订单编号
  String? order_no;

  /// 开始时间
  String? start_time;

  /// 结束时间
  String? end_time;

  /// 订单天数
  int? order_days;

  /// 剩余天数
  int? remain_days;

  /// 上刊天数
  int? publish_days;

  /// 时长（秒）
  int? duration;

  /// 订单频次
  int? order_frequency;

  /// 订单状态
  int? order_status;

  /// 订单状态文案
  String? order_status_text;

  /// 客户编号
  String? customer_no;

  /// 轮播规则
  int? loop_rule;

  /// 独占行业
  String? exclusive_industry;

  /// 独占行业 ID 列表
  List<int>? exclusive_industry_ids;

  /// 独占规则
  String? exclusive_rule;

  /// 客户 ID
  int? customer_id;

  /// 客户名称
  String? customer_name;

  /// 客户行业
  String? customer_industry;

  /// 客户行业 ID
  int? customer_industry_id;

  /// 素材编号
  String? media_no;

  /// 素材库 ID
  int? media_id;

  /// 素材标题
  String? media_title;

  /// 素材时长（秒）
  int? media_duration;

  /// 素材文件路径
  String? media_file_path;

  /// 素材预览路径
  String? media_preview_path;

  /// 分类 ID
  int? category_id;

  /// 播放模式
  int? play_model;

  /// 媒体类型
  int? media_type;

  /// 文件格式
  String? file_format;

  /// 播放总当前频次
  int? play_total_now_frequency;

  /// 播放总溢出频次
  int? play_total_out_frequency;

  /// 插播时长
  int? insert_duration;

  /// 播放总溢出占比
  double? play_total_out_per;

  /// 实际轮播间隔
  int? actual_loop_interval;

  /// 实际轮播间隔是否达标
  bool? actual_loop_interval_ok;

  /// 上刊时段
  String? publish_slots;

  /// 设置时段
  String? set_slots;

  /// 当前频次
  int? current_frequency;

  /// 点位编码
  String? point_code;

  /// 当日任务是否使用新排期 ID
  bool? task_daily_uses_new_schedule_id;

  /// 订单状态
  int? status;

  /// 当前播放日志
  bool? play_log_current;

  /// 是否满足排期要求
  bool? satisfy;

  /// 不满足原因
  String? reason;

  /// 预览：本条在展开列表中的第几次出现（从 1 开始）
  int? preview_cell_index;

  /// 预览：本条在展开列表中共出现几次
  int? preview_cell_quota;

  /// 预览：列表是否已按格子展开
  bool? preview_expanded;

  /// 预览：是否为填充项
  bool? preview_is_fill;

  /// 预览：展开列表中的全局播放顺序
  int? preview_seq;

  /// 预览：间隔建议
  String? preview_gap_advice;
}
