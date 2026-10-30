/// HRM 员工合同与协议（`HrmEmployeeContractVo`）。
class HrmEmployeeContract {
  String? id;
  /// 接口字段 `employeeUserId`。
  int? userId;
  /// 合同编号（接口 `no`）。
  String? contractNo;
  String? type;
  /// 合同甲方（接口 `partyA`）。
  String? signParty;
  /// 生效日期（接口 `startDate`）。
  String? effectiveDate;
  /// 到期日期（接口 `endDate`）。
  String? expireDate;
  /// 签署日期（接口 `signingDate`）。
  String? signDate;
  /// 附件（接口 `file`）。
  String? attachmentUrl;
  int? orderNum;
}
