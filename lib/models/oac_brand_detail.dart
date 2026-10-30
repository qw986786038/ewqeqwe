import 'oac_brand.dart';

class OacBrandDetail {
  OacBrand? brand;
  List<String> subBrands = const [];
  List<EnterpriseItem> enterprises = const [];
  List<AgencyItem> agencies = const [];
  List<ContactItem> contacts = const [];
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
  String? city;
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

class OrderItem {
  String? id;
  String? name;
  String? orderNo;
  String? tag;
  String? enterprise;
  String? relation;
  String? contractType;
  String? amount;
  String? orderTime;
  String? contact;
  String? agencyId;
  String? agencyName;
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

/// 从关系图谱推导的销售员展示项
class SalesPersonView {
  SalesPersonView({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;
}
