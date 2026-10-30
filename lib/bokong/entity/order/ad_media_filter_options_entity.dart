import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 素材筛选：整型 value + label
@jsonSerializable
class AdMediaFilterIntOptionEntity {
  /// 选项值
  int? value;

  /// 选项文案
  String? label;
}

/// 素材筛选：字符串 value（可无 label）
@jsonSerializable
class AdMediaFilterStringOptionEntity {
  /// 选项值
  String? value;

  /// 选项文案
  String? label;
}

/// 素材筛选：行业（可含子级）
@jsonSerializable
class AdMediaFilterIndustryOptionEntity {
  /// 行业 ID
  int? value;

  /// 行业名称
  String? label;

  /// 子行业
  List<AdMediaFilterIntOptionEntity>? children;
}

/// 素材库筛选选项（`/api/system/ad/media/filter_options/`）
@jsonSerializable
class AdMediaFilterOptionsEntity {
  /// 媒体类型
  List<AdMediaFilterIntOptionEntity>? media_type;

  /// 所属行业
  List<AdMediaFilterIndustryOptionEntity>? industry;

  /// 客户
  List<AdMediaFilterIntOptionEntity>? customer;

  /// 分辨率
  List<AdMediaFilterStringOptionEntity>? resolution;

  /// 文件格式
  List<AdMediaFilterStringOptionEntity>? file_format;
}
