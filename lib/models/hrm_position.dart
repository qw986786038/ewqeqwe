/// HRM 编制（对接 desktop/hrm/position 与 position/list）。
class HrmPosition {
  String? id;
  String? sysDeptId;
  String? postId;
  /// REGULAR / RESERVE / OUTSOURCE
  String? type;
  String? reportPositionId;
  String? dottedPositionId;

  /// 接口若直接返回展示名则优先使用。
  String? deptName;
  String? postName;
}

/// 编制分页结果：`GET /desktop/hrm/position`。
class HrmPositionsPage {
  const HrmPositionsPage({required this.total, required this.rows});

  final int total;
  final List<HrmPosition> rows;
}
