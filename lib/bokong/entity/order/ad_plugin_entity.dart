import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 广告插件（素材添加「插件」Tab 选择用）
@jsonSerializable
class AdPluginEntity {
  int? id;

  /// 插件名称
  String? name;

  int? type;

  /// 插件内容地址
  String? content;

  /// 预览图地址（接口字段 prview_url）
  String? prview_url;

  /// 创建时间
  String? create_time;
}
