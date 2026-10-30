import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 内容分组（排他行业）
@jsonSerializable
class AdContentGroupEntity {
  int? id;

  /// 父级 ID（0 为一级）
  int? parent_id;

  /// 分类名称
  String? category_name;

  /// 分类编码
  String? category_code;

  /// 描述
  String? description;

  /// 排序
  int? sort_order;

  int? status;

  /// 是否删除
  int? is_delete;

  /// 创建时间
  String? create_time;

  /// 更新时间
  String? update_time;

  /// 子级
  List<AdContentGroupEntity>? children;
}
