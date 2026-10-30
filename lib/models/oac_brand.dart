/// 品牌视角 KPI（OacBrandOverviewVo）
class OacBrandOverview {
  int? totalOrderCount;
  String? totalOrderAmount;
  String? orderCountMomRate;
  String? orderAmountMomRate;
  int? relatedEnterpriseCount;
  int? relatedAgencyCount;
  int? internationalAgencyCount;
  int? contactCount;
  int? contactNewThisWeek;
  String? latestOrderTime;
  String? latestOrderBrandName;
  int? industryCount;
  String? dataAsOf;
}

/// 品牌列表行（OacBrandVo）
class OacBrand {
  String? id;
  String? tenantId;
  String? brandCode;
  String? name;
  String? industry;
  String? city;
  String? tags;
  List<String>? tagList;
  String? clientTag;
  String? spokesperson;
  int? weight;
  String? iconUrl;
  String? ownerNames;
  List<String>? ownerNameList;
  String? latestDynamic;
  int? orderCount;
  String? orderAmount;
  int? enterpriseCount;
  int? agencyCount;
  int? contactCount;
  String? latestOrderTime;
  String? status;
  String? remark;
  String? createTime;
  String? updateTime;
}

class OacBrandListPage {
  int total;
  List<OacBrand> rows;

  OacBrandListPage({required this.total, required this.rows});
}

/// 列表/KPI 共用筛选（仅填非空才会作为 Query 发出）
class OacBrandQuery {
  String? keyword;
  String? industry;
  String? city;
  String? tags;
  String? clientTag;
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

  OacBrandQuery({
    this.keyword,
    this.industry,
    this.city,
    this.tags,
    this.clientTag,
    this.ownerNames,
    this.quickTag,
    this.amountMin,
    this.amountMax,
    this.orderTimeBegin,
    this.orderTimeEnd,
    this.pageNum = 1,
    this.pageSize = 10,
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
    put('clientTag', clientTag);
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
