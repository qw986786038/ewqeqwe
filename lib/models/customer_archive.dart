/// 客户档案列表行（对接 OacCustomerVo）。
class CustomerArchive {
  String? id;
  String? archiveCode;
  String? customerType;
  String? marketLevel;
  String? iconLetter;
  String? iconUrl;
  String? brandName;
  String? brandSub;
  String? industry;
  int? entityCount;
  String? entityName;
  String? relation;
  String? entityNature;
  String? city;
  String? address;
  String? contact;
  String? salesperson;
  String? serviceAgencyId;
  String? createTime;
  String? latestDynamic;
  /// 负责人（列表展示；与 salesperson 同源时可复用）。
  String? owner;
  String? assignTime;
  int? assignDays;
  String? status;
  String? remark;
}

/// 客户档案顶部统计（对接 `OacCustomerOverviewVo`）。
class CustomerArchiveStats {
  /// 品牌数量卡片：`brandCount`。
  int brandEnterprise = 0;
  /// 关联主体：`enterpriseTotalCount`。
  int relatedEntityCount = 0;
  int publicSea = 0;
  int privateSea = 0;
  int pendingAssign = 0;
  String? dataAsOf;
}
