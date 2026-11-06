/// 4A 公司视角 KPI（OacAgencyOverviewVo）
class OacAgencyOverview {
  int? totalOrderCount;
  String? totalOrderAmount;
  String? orderCountMomRate;
  String? orderAmountMomRate;
  int? relatedBrandCount;
  int? relatedEnterpriseCount;
  int? contactCount;
  int? contactNewThisWeek;
  String? latestOrderTime;
  String? latestOrderAgencyName;
  String? avgBrandPerAgency;
  String? dataAsOf;
}

/// 4A 公司列表行（OacAgencyVo）
class OacAgency {
  String? id;
  String? tenantId;
  String? name;
  String? shortName;
  String? city;
  String? province;
  String? address;
  String? relationType;
  String? tags;
  List<String>? tagList;
  String? clientTag;
  int? weight;
  String? iconUrl;
  String? ownerNames;
  List<String>? ownerNameList;
  String? latestDynamic;
  int? orderCount;
  String? orderAmount;
  int? brandCount;
  String? brandNames;
  List<String>? brandNameList;
  int? enterpriseCount;
  String? enterpriseNames;
  List<String>? enterpriseNameList;
  int? contactCount;
  String? latestOrderTime;
  String? status;
  String? remark;
  String? createTime;
  String? updateTime;
}

class OacAgencyListPage {
  int total;
  List<OacAgency> rows;

  OacAgencyListPage({required this.total, required this.rows});
}

/// 4A 列表筛选（与企业视角查询参数对齐，另含关联关系）。
class OacAgencyQuery {
  String? keyword;
  String? city;
  String? tags;
  String? relationType;
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

  OacAgencyQuery({
    this.keyword,
    this.city,
    this.tags,
    this.relationType,
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
    put('city', city);
    put('tags', tags);
    put('relationType', relationType);
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
