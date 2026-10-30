import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 行政区划字典
@jsonSerializable
class AreaEntity {
  int? id;

  /// 名称
  String? name;

  /// 区划编码
  String? code;

  /// 层级：1 省、2 市、3 区县
  int? level;

  /// 上级区划编码
  String? pcode;

  bool? hasChild;
}
