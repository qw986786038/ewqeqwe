/// HRM 公司整体配置（对接 desktop/hrm/dept/summary，HrmDeptSummaryVo）。
class HrmDeptSummary {
  int? headcount;
  int? onDuty;
  int? vacancy;
  int? manageOnDuty;
  int? professionalOnDuty;

  /// 编制满足率，百分比整数（如 85 表示 85%）。
  int? fillRate;
}
