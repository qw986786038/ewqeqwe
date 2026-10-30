/// HRM 能力标签分组（对接 desktop/hrm/skill-group）。
class HrmSkillGroup {
  String? id;
  String? name;
  int? orderNum;
  List<HrmSkillTag>? tags;
}

/// 分组内标签。
class HrmSkillTag {
  String? id;
  String? name;
  int? orderNum;
}
