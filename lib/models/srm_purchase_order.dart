/// 采购订单 KPI 汇总（列表页顶部卡片）。
class SrmPurchaseOrderKpi {
  int orderCount = 0;
  int propertyLeaseCount = 0;
  int mediaPurchaseCount = 0;
}

/// 采购订单列表行（对接 SrmPurchaseOrderVo）。
class SrmPurchaseOrder {
  String? id;
  String? orderNo;
  String? orderName;
  String? orderTag;
  String? brandName;
  String? supplierId;
  String? supplierFullName;
  String? contractType;
  num? orderAmount;
  String? orderTime;
  String? settlementMethod;
  String? invoiceType;
  String? taxRate;
  String? city;
  String? contactName;
  String? staffName;
  String? supplyCategory;
  String? status;
  String? remark;
  String? createTime;
}
