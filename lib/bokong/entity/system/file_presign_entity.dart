import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 文件上传预签名响应
@jsonSerializable
class FilePresignEntity {
  /// OSS 直传地址（带签名 query）
  String? upload_url;

  /// 上传完成后的公开访问地址
  String? public_url;

  /// OSS 对象键
  String? object_key;

  /// 直传时必须携带的请求头
  Map<String, dynamic>? required_headers;

  /// 签名有效期（秒）
  int? expires_in;

  /// 是否客户端直传 OSS
  bool? use_direct;

  /// 客户端原始文件名
  String? client_name;

  /// 文件类型提示
  int? file_type_hint;
}
