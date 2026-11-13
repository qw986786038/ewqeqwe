/// 企业视角 KPI（OacEnterpriseOverviewVo）
class OacEnterpriseOverview {
  int? totalOrderCount;
  String? totalOrderAmount;
  String? orderCountMomRate;
  String? orderAmountMomRate;
  int? relatedBrandCount;
  int? relatedAgencyCount;
  int? internationalAgencyCount;
  int? contactCount;
  int? contactNewThisWeek;
  String? latestOrderTime;
  String? latestOrderEnterpriseName;
  String? latestOrderBrandName;
  int? industryCount;
  String? dataAsOf;
}

/// 企业列表行（OacEnterpriseVo）
class OacEnterprise {
  String? id;
  /// 客户档案 / 详情聚合入口（`GET /desktop/oac/brand/{customerId}/detail`）。
  String? customerId;
  String? tenantId;
  String? enterpriseCode;
  String? name;
  String? shortName;
  String? industry;
  String? city;
  String? province;
  String? address;
  String? relationType;
  String? entityNature;
  String? tags;
  List<String>? tagList;
  String? clientTag;
  int? weight;
  /// 覆盖评分（企业视角，不同于品牌健康度）。
  int? coverageScore;
  /// 覆盖等级，如 `B 级`。
  String? coverageGrade;
  String? iconUrl;
  String? ownerNames;
  List<String>? ownerNameList;
  String? latestDynamic;
  int? orderCount;
  String? orderAmount;
  /// 订单金额同比（%）。
  String? orderAmountYoyRate;
  /// 部门业绩占比（%）。
  String? deptPerfShareRate;
  int? brandCount;
  String? brandNames;
  List<String>? brandNameList;
  List<String>? brandIdList;
  int? agencyCount;
  String? agencyNames;
  List<String>? agencyNameList;
  int? contactCount;
  String? latestOrderTime;
  String? status;
  String? remark;
  String? createTime;
  String? updateTime;
}

class OacEnterpriseListPage {
  int total;
  List<OacEnterprise> rows;

  OacEnterpriseListPage({required this.total, required this.rows});
}

/// 企业列表筛选（与品牌视角查询参数对齐）。
class OacEnterpriseQuery {
  String? keyword;
  String? industry;
  String? city;
  String? tags;
  String? mediaType;
  String? ownerNames;
  String? quickTag;
  String? amountMin;
  String? amountMax;
  String? orderTimeBegin;
  String? orderTimeEnd;
  int pageNum;
  int pageSize;
  String? orderByColumn;
  String? isAsc;

  OacEnterpriseQuery({
    this.keyword,
    this.industry,
    this.city,
    this.tags,
    this.mediaType,
    this.ownerNames,
    this.quickTag,
    this.amountMin,
    this.amountMax,
    this.orderTimeBegin,
    this.orderTimeEnd,
    this.pageNum = 1,
    this.pageSize = 20,
    this.orderByColumn,
    this.isAsc,
  });

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) map[key] = v;
    }

    put('keyword', keyword);
    put('industry', industry);
    put('city', city);
    put('tags', tags);
    put('mediaType', mediaType);
    put('ownerNames', ownerNames);
    put('quickTag', quickTag);
    put('amountMin', amountMin);
    put('amountMax', amountMax);
    put('orderTimeBegin', orderTimeBegin);
    put('orderTimeEnd', orderTimeEnd);
    put('orderByColumn', orderByColumn);
    put('isAsc', isAsc);
    map['pageNum'] = '$pageNum';
    map['pageSize'] = '$pageSize';
    return map;
  }
}
