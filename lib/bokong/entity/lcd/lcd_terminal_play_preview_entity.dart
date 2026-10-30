import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 设备正在播放内容预览（ShowDoc 1515 `/api/system/ad/terminal/play_preview`）
@jsonSerializable
class LcdTerminalPlayPreviewEntity {
  /// 节目单 ID
  int? program_id;

  /// 素材 ID
  int? media_id;

  /// 素材类型（与素材库一致：1 图片 / 2 视频 / 4 网页 / 5 直播 / 6 插件；接口晚些会补）
  int? media_type;

  /// 节目单名称
  String? program_name;

  /// 播放时长（秒）
  int? play_duration;

  /// 素材路径
  String? material_path;

  /// 素材宽度（用于预览比例自适应；接口晚些会补）
  int? screen_width;

  /// 素材高度（用于预览比例自适应；接口晚些会补）
  int? screen_height;

  /// 播放开始时间
  String? play_start_time;

  /// 创建时间
  String? create_time;
}
