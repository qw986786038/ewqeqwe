import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 素材库左侧内容分类树
@jsonSerializable
class AdContentCategoryEntity {
  /// 分类 ID（根 / 行业 / 叶子节点）
  int? category_id;

  /// 客户 ID（兼容旧字段；树选择与列表筛选改用 [category_id]）
  int? customer_id;

  /// 名称
  String? name;

  /// 素材总数（根节点「全部文件」）
  int? total;

  /// 素材数量（行业 / 分类节点）
  int? count;

  /// 子节点
  List<AdContentCategoryEntity>? children;
}
