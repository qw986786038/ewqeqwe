import 'oac_brand.dart';

/// 订单管理详情聚合视角（品牌 / 企业 / 4A 入口文案与取值不同）。
enum OacDetailPerspective {
  brand,
  enterprise,
  agency,
}

class OacBrandDetail {
  OacBrand? brand;
  List<String> subBrands = const [];
  List<EnterpriseItem> enterprises = const [];
  /// 企业视角关联品牌（接口 `brands`）；品牌视角可为空。
  List<RelatedBrandItem> brands = const [];
  List<AgencyItem> agencies = const [];
  List<ContactItem> contacts = const [];
  List<SalesItem> salesList = const [];
  List<OrderItem> orders = const [];
  List<MediaFormatItem> mediaFormats = const [];
  List<MonthAmountItem> monthlyTrend = const [];
  RelationGraph? relationGraph;
  HqLocation? hqLocation;
  String? orderAmountYoyRate;
  String? orderAmountMomRate;
}

class EnterpriseItem {
  String? id;
  String? name;
  String? type;
  String? entityNature;
  String? city;
  String? address;
  String? province;
}

class RelatedBrandItem {
  String? id;
  String? name;
  String? industry;
}

class AgencyItem {
  String? id;
  String? name;
}

class ContactItem {
  String? id;
  String? name;
  String? title;
  String? orgName;
  String? phone;
  String? email;
  String? enterpriseId;
}

class SalesItem {
  String? id;
  int? userId;
  String? name;
  String? nameEn;
  String? gender;
  String? deptTitle;
  String? assignTime;
}

class OrderItem {
  String? id;
  String? name;
  String? orderNo;
  String? tag;
  String? enterprise;
  String? signEnterpriseId;
  String? relation;
  String? relationLabel;
  String? contractType;
  String? amount;
  String? orderTime;
  String? periodStart;
  String? periodEnd;
  int? durationDays;
  String? contact;
  String? agencyId;
  String? agencyName;
  String? brandId;
  String? brandName;
  String? industry;
  String? city;
  String? customerType;
  String? salesPerson;
  String? remark;
}

class MediaFormatItem {
  String? name;
  num? percent;
  String? tone;
}

class MonthAmountItem {
  String? month;
  String? amount;
}

class RelationGraph {
  List<RelationNode> nodes = const [];
  List<RelationLink> links = const [];
}

class RelationNode {
  String? id;
  String? name;
  String? category;
}

class RelationLink {
  String? source;
  String? target;
  String? label;
}

class HqLocation {
  String? region;
  String? name;
  String? address;
  double? lng;
  double? lat;
}

/// 销售员展示项（优先 `salesList`，图谱角色作兜底）。
class SalesPersonView {
  SalesPersonView({
    required this.name,
    required this.role,
    this.deptTitle,
  });

  final String name;
  final String role;
  final String? deptTitle;
}
