import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 添加客户请求体
@jsonSerializable
class AdCustomerCreateEntity {
  int? status;

  /// 客户类型：0 渠道，1 直客，2 代理公司
  int? type;

  /// 客户名称
  String? customer_name;

  /// 行业 ID（接口字段 industry）
  int? industry;

  /// 行业 ID
  int? industry_id;

  /// 采购时间
  String? purchase_time;

  /// 生效时间
  String? effective_time;

  /// 到期时间
  String? expire_time;

  /// 联系人
  String? contact_person;

  /// 联系电话
  String? contact_phone;

  /// 邮箱
  String? email;

  /// 地址
  String? address;

  /// 备注
  String? remark;
}
