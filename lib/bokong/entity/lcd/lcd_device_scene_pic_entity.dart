import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 终端现场照片列表项
@jsonSerializable
class LcdDeviceScenePicEntity {
  /// 存储路径
  String? path;

  /// 访问地址
  String? url;

  /// 类型（如 image）
  String? kind;

  /// 文件名
  String? name;
}
