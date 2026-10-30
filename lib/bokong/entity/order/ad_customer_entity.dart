import 'package:dart_json_mapper/dart_json_mapper.dart';

/// 客户（订单添加选择用）
@jsonSerializable
class AdCustomerEntity {
  int? id;

  /// 行业
  String? industry;

  /// 客户编号
  String? customer_no;

  /// 客户名称
  String? customer_name;

  /// 行业 ID
  int? industry_id;

  /// 采购时间
  String? purchase_time;

  /// 生效时间
  String? effective_time;

  /// 到期时间
  String? expire_time;

  /// 播放设置
  int? play_setting;

  int? status;

  /// 客户类型：0 渠道，1 直客，2 代理公司
  int? type;

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

  /// 是否删除
  int? is_delete;

  /// 创建时间
  String? create_time;

  /// 更新时间
  String? update_time;

  /// 创建人
  String? create_by;

  /// 更新人
  String? update_by;
}
