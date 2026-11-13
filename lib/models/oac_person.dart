/// 人视角 KPI（OacPersonOverviewVo）
class OacPersonOverview {
  int? contactCount;
  int? relatedBrandCount;
  int? relatedEnterpriseCount;
  int? relatedAgencyCount;
  int? totalOrderCount;
  String? totalOrderAmount;
  int? contactNewThisWeek;
  String? avgBrandPerContact;
  int? internationalAgencyContactCount;
  String? latestOrderTime;
  String? latestOrderContactName;
  String? dataAsOf;
}

/// 人视角列表行（OacPersonVo）
class OacPerson {
  String? id;
  String? tenantId;
  String? avatarUrl;
  String? name;
  String? title;
  String? latestEmployer;
  String? enterpriseId;
  String? customerId;
  String? enterpriseType;
  String? city;
  String? address;
  int? sameEnterpriseContactCount;
  List<String>? sameEnterpriseContactNames;
  int? brandCount;
  String? brandNames;
  List<String>? brandNameList;
  List<String>? brandIdList;
  String? brandIndustrySummary;
  int? enterpriseCount;
  List<String>? enterpriseNameList;
  int? agencyCount;
  List<String>? agencyNameList;
  int? orderCount;
  String? orderAmount;
  String? orderAmountYoyRate;
  String? latestOrderTime;
  int? influenceScore;
  bool? keyDecisionMaker;
  String? personCode;
  bool? realNameVerified;
  bool? canDecide;
  String? status;
  String? createTime;
  String? updateTime;
}

class OacPersonListPage {
  int total;
  List<OacPerson> rows;

  OacPersonListPage({required this.total, required this.rows});
}

/// 人视角列表筛选。
class OacPersonQuery {
  String? keyword;
  String? enterpriseType;
  String? city;
  String? latestEmployer;
  String? orderTimeBegin;
  String? orderTimeEnd;
  int pageNum;
  int pageSize;
  String? orderByColumn;
  String? isAsc;

  OacPersonQuery({
    this.keyword,
    this.enterpriseType,
    this.city,
    this.latestEmployer,
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
    put('enterpriseType', enterpriseType);
    put('city', city);
    put('latestEmployer', latestEmployer);
    put('orderTimeBegin', orderTimeBegin);
    put('orderTimeEnd', orderTimeEnd);
    put('orderByColumn', orderByColumn);
    put('isAsc', isAsc);
    map['pageNum'] = '$pageNum';
    map['pageSize'] = '$pageSize';
    return map;
  }
}
