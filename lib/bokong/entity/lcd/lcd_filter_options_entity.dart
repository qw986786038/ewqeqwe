import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class LcdFilterIntOptionEntity {
  /// 选项值
  int? value;

  /// 选项文案
  String? label;
}

@jsonSerializable
class LcdFilterDistrictOptionEntity {
  /// 区县 ID
  int? value;

  /// 区县名称
  String? label;

  /// 所属城市 ID
  int? city_value;

  /// 所属城市名称
  String? city_label;
}

@jsonSerializable
class LcdFilterStringOptionEntity {
  /// 选项值
  String? value;

  /// 选项文案
  String? label;
}

@jsonSerializable
class LcdFilterPropertyOptionEntity {
  /// 物业 ID
  int? property_id;

  /// 楼栋 ID（旧 `propertys` 列表若已改为楼栋时使用）
  int? office_id;

  /// 物业 / 楼栋名称
  String? name;
}

@jsonSerializable
class LcdFilterOfficeOptionEntity {
  /// 楼栋 ID
  int? office_id;

  /// 楼栋名称
  String? name;
}

/// LCD 设备管理筛选选项
@jsonSerializable
class LcdFilterOptionsEntity {
  /// 城市
  List<LcdFilterIntOptionEntity>? cities;

  /// 区县
  List<LcdFilterDistrictOptionEntity>? districts;

  /// 道路
  List<LcdFilterStringOptionEntity>? roads;

  /// 物业
  List<LcdFilterPropertyOptionEntity>? propertys;

  /// 楼栋
  List<LcdFilterOfficeOptionEntity>? office_building;

  /// 媒体位置
  List<LcdFilterStringOptionEntity>? media_address;

  /// 媒体尺寸
  List<LcdFilterStringOptionEntity>? media_size;

  /// 点位名称
  List<LcdFilterStringOptionEntity>? point_names;
}
