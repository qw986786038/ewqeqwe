/// 字典数据项（`/desktop/oac/dict/data/type/{dictType}`）。
class DictDataItem {
  int? dictCode;
  int? dictSort;
  String? dictLabel;
  String? dictValue;
  String? dictType;
  String? cssClass;
  String? listClass;
  String? isDefault;
  String? status;
  String? remark;
  String? createTime;
}

/// 常用字典类型（与后台字典管理一致）。
abstract final class OacDictTypes {
  static const customerType = 'mm_crm_customer_type';
  static const marketScale = 'mm_crm_market_scale';
  static const brandNature = 'mm_crm_brand_nature';
  static const revenueScale = 'mm_crm_revenue_scale';
  static const marketingBudget = 'mm_crm_marketing_budget';
  static const relationType = 'mm_crm_relation_type';
  static const entityNature = 'mm_crm_entity_nature';
  static const marketScope = 'mm_crm_market_scope';
  static const tenure = 'mm_crm_tenure';
  static const contractType = 'mm_crm_contract_type';
  /// 自媒体矩阵平台：`wechat_mp` / `wechat_channels` / `douyin` / `xiaohongshu`…
  static const selfMediaMatrix = 'mm_crm_self_media_matrix';
  static const industry = 'mm_industry';
  /// 客户 / 品牌标签：`desktop/oac/dict/data/type/mm_crm_customer_tag`。
  static const customerTag = 'mm_crm_customer_tag';
}

/// HRM 字典类型。
abstract final class HrmDictTypes {
  static const empStatus = 'mm_hrm_emp_status';
  static const empType = 'mm_hrm_emp_type';
  static const conversionStatus = 'mm_hrm_conversion_status';
  static const leaveType = 'mm_hrm_leave_type';
  static const timeType = 'mm_hrm_time_type';
  static const education = 'mm_hrm_education';
  static const contractType = 'mm_hrm_contract_type';
  static const contactRelation = 'mm_hrm_contact_relation';
  static const fileType = 'mm_hrm_file_type';
  static const changeType = 'mm_hrm_change_type';
  static const postSeqChannel = 'mm_hrm_post_seq_channel';

  static const all = <String>[
    empStatus,
    empType,
    conversionStatus,
    leaveType,
    timeType,
    education,
    contractType,
    contactRelation,
    fileType,
    changeType,
    postSeqChannel,
  ];
}
