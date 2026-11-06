import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_dept.dart';
import '../../../models/hrm_dept_summary.dart';
import '../../../models/hrm_employee.dart';
import '../../../models/hrm_employee_assign.dart';
import '../../../models/hrm_employee_profile.dart';
import '../../../models/hrm_position.dart';
import '../../../models/hrm_post.dart';
import '../../../services/hrm_api.dart';

enum OrgChartViewMode { department, reportChain }

enum OrgChartLayout { vertical, horizontal }

class OrgDeptNode {
  OrgDeptNode(this.dept);

  final HrmDept dept;
  final List<OrgDeptNode> children = [];

  String? get id => dept.deptId?.trim();

  int get onDuty => dept.onDuty ?? 0;

  int get headcount => dept.headcount ?? 0;

  int get vacancy {
    final v = headcount - onDuty;
    return v > 0 ? v : 0;
  }

  /// 含下级在岗：本级 + 全部子部门。
  /// 接口若已是「含下级」（≥ 子树合计）则用接口值，避免重复累加；否则本级与子树相加。
  int get subtreeOnDuty {
    if (children.isEmpty) return onDuty;
    final childSum = children.fold<int>(0, (s, c) => s + c.subtreeOnDuty);
    if (onDuty >= childSum) return onDuty;
    return onDuty + childSum;
  }

  /// 含下级编制：本级 + 全部子部门（规则同 [subtreeOnDuty]）。
  int get subtreeHeadcount {
    if (children.isEmpty) return headcount;
    final childSum = children.fold<int>(0, (s, c) => s + c.subtreeHeadcount);
    if (headcount >= childSum) return headcount;
    return headcount + childSum;
  }

  /// 含下级空缺。
  int get subtreeVacancy {
    final v = subtreeHeadcount - subtreeOnDuty;
    return v > 0 ? v : 0;
  }

  /// 本部门或下级有在岗人数。
  bool get hasPeople => subtreeOnDuty > 0;

  /// 是否展示（含无人部门）。
  bool get shouldShow => true;

  /// 组织图 / 左树用的可见子节点（含无人部门）。
  List<OrgDeptNode> get visibleChildren => List<OrgDeptNode>.of(children);
}

/// 汇报链人员节点（编制编制 ↔ 员工 titleList）。
class OrgPersonNode {
  OrgPersonNode({
    required this.positionId,
    required this.name,
    required this.postName,
    required this.deptName,
    this.deptId,
    this.userId,
    this.levelName,
    this.statusLabel,
    this.coverCount,
  });

  final String positionId;
  final String name;
  final String postName;
  final String deptName;
  final String? deptId;
  final int? userId;
  /// 职级展示名，如 P11。
  final String? levelName;
  /// 状态角标，如「调动中」。
  final String? statusLabel;
  /// 根节点覆盖人数（可选）。
  final int? coverCount;
  final List<OrgPersonNode> children = [];

  String get avatarChar {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1);
  }

  String get subtitle {
    final parts = <String>[
      if (postName.trim().isNotEmpty) postName.trim(),
      if (levelName != null && levelName!.trim().isNotEmpty) levelName!.trim(),
      if (statusLabel != null && statusLabel!.trim().isNotEmpty)
        statusLabel!.trim(),
    ];
    return parts.join(' · ');
  }
}

class OrgStructureController extends LxController {
  final _api = HrmApi();

  final searchCtrl = TextEditingController();
  final transformCtrl = TransformationController();

  /// 组织图导出截图层（包在 InteractiveViewer 子树外层）。
  final chartExportKey = GlobalKey();
  final exporting = false.obs;

  final loading = false.obs;
  final errorMessage = Rxn<String>();
  final roots = <OrgDeptNode>[].obs;
  final flatDepts = <HrmDept>[].obs;

  /// 左树展开的部门 id。
  final expandedIds = <String>{}.obs;

  /// 当前选中部门（右图蓝框：自身 + 上级链路）。
  final selectedDeptId = Rxn<String>();

  /// 选中链路（从根到当前选中，含自身），用于组织图蓝框。
  final selectionPathIds = <String>{}.obs;

  /// 汇报链：选中编制 id。
  final selectedPositionId = Rxn<String>();

  /// 汇报链：从根到选中编制的路径。
  final reportPathIds = <String>{}.obs;

  /// 汇报链森林根节点。
  final reportRoots = <OrgPersonNode>[].obs;

  final viewMode = OrgChartViewMode.department.obs;
  final layout = OrgChartLayout.vertical.obs;
  final zoom = 1.0.obs;
  /// 蓝框高亮汇报链 / 选中路径；默认开启。
  final highlightReport = true.obs;
  final searchQuery = ''.obs;

  /// deptId → 职务名称 → 在岗人数。
  final postTagsByDept = <String, Map<String, int>>{}.obs;

  /// deptId → 空缺编制数（编制无在任）。
  final vacancyByDept = <String, int>{}.obs;

  final chartLoading = false.obs;

  final posts = <HrmPost>[];
  final positions = <HrmPosition>[];
  final assigns = <HrmEmployeeAssign>[];
  final employees = <HrmEmployeeProfile>[];

  final Map<String, HrmPost> _postById = {};
  final Map<String, HrmPosition> _positionById = {};
  final Map<int, HrmEmployeeProfile> _employeeByUserId = {};
  final Map<String, HrmEmployeeAssign> _assignByPositionId = {};
  final Map<String, String> _deptNameById = {};

  /// deptId → 该部门下员工姓名（用于搜索）。
  final Map<String, List<String>> _namesByDept = {};

  /// deptId → 负责人姓名（主岗优先）。
  final Map<String, String> _leaderByDept = {};

  /// 编制 → 汇报上级编制（仅填充在任节点间）。
  final Map<String, String> _reportParentOf = {};

  /// title 侧汇报上级（优先于编制表 reportPositionId）。
  final Map<String, String> _titleReportParentOf = {};

  /// 全量在任人员（扁平，无 children）；展示树由 [_applyReportDeptFilter] 生成。
  final Map<String, OrgPersonNode> _allPersonByPos = {};

  /// 组织图展示根（可能把「总经办」提为图根；与左树真实父子可不同）。
  OrgDeptNode? _displayChartRoot;

  /// 公司整体配置（`/desktop/hrm/dept/summary`）。
  final deptSummary = Rxn<HrmDeptSummary>();

  /// 顶部「部门筛选」多选 id；空 = 全部部门。
  final filterDeptIds = <String>{}.obs;

  int get orgCount => flatDepts.length;

  int get companyOnDuty {
    final s = deptSummary.value?.onDuty;
    if (s != null) return s;
    if (roots.isEmpty) return 0;
    final rootDuty = roots.first.dept.onDuty;
    if (rootDuty != null) return rootDuty;
    return roots.fold<int>(0, (sum, n) => sum + n.subtreeOnDuty);
  }

  int get companyHeadcount {
    final s = deptSummary.value?.headcount;
    if (s != null) return s;
    if (roots.isEmpty) return 0;
    final rootHc = roots.first.dept.headcount;
    if (rootHc != null) return rootHc;
    return roots.fold<int>(0, (sum, n) => sum + n.subtreeHeadcount);
  }

  int get companyVacancy {
    final s = deptSummary.value?.vacancy;
    if (s != null) return s;
    final v = companyHeadcount - companyOnDuty;
    return v > 0 ? v : 0;
  }

  /// 0～1，供进度条；接口 `fillRate` 为百分比整数。
  double get fillRate {
    final pct = deptSummary.value?.fillRate;
    if (pct != null) return (pct / 100).clamp(0.0, 1.0);
    final hc = companyHeadcount;
    if (hc <= 0) return 0;
    return (companyOnDuty / hc).clamp(0.0, 1.0);
  }

  static const _managePostNames = {
    '董事长',
    '总经理',
    '副总',
    '部门负责人',
  };

  int get manageCount {
    final s = deptSummary.value?.manageOnDuty;
    if (s != null) return s;
    var n = 0;
    for (final tags in postTagsByDept.values) {
      for (final e in tags.entries) {
        if (_managePostNames.contains(e.key) ||
            e.key.contains('管理') ||
            e.key.contains('负责')) {
          n += e.value;
        }
      }
    }
    return n;
  }

  int get professionalCount {
    final s = deptSummary.value?.professionalOnDuty;
    if (s != null) return s;
    var n = 0;
    for (final tags in postTagsByDept.values) {
      for (final e in tags.entries) {
        if (_managePostNames.contains(e.key) ||
            e.key.contains('管理') ||
            e.key.contains('负责')) {
          continue;
        }
        n += e.value;
      }
    }
    return n;
  }

  OrgDeptNode? get selectedNode {
    final id = selectedDeptId.value;
    if (id == null) return null;
    return findNode(id);
  }

  /// 组织图固定根（不随左侧点选切换，避免视角/整树跳变）。
  OrgDeptNode? get chartRoot => _displayChartRoot;

  bool isInSelectionPath(String? id) {
    if (id == null || id.isEmpty) return false;
    return selectionPathIds.contains(id);
  }

  OrgDeptNode? findNode(String id) {
    OrgDeptNode? walk(OrgDeptNode n) {
      if (n.id == id) return n;
      for (final c in n.children) {
        final hit = walk(c);
        if (hit != null) return hit;
      }
      return null;
    }

    for (final r in roots) {
      final hit = walk(r);
      if (hit != null) return hit;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onDispose() {
    searchCtrl.dispose();
    transformCtrl.dispose();
    super.onDispose();
  }

  Future<void> refreshAll() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      // 部门 / 职务 / 员工（含 titleList）/ 公司汇总并行；编制列表随后按部门拉取。
      final summaryFuture = _api.fetchDeptSummary();
      final results = await Future.wait([
        _api.fetchDepts(),
        _api.fetchPosts(),
        _api.fetchEmployeesPage(pageNum: 1, pageSize: 10000),
      ]);
      final list = results[0] as List<HrmDept>;
      posts
        ..clear()
        ..addAll(results[1] as List<HrmPost>);
      final empPage = results[2] as HrmEmployeesPage;
      employees
        ..clear()
        ..addAll(empPage.rows);
      // 在任关系改由员工 titleList 推导，不再依赖 on-duty 接口。
      assigns
        ..clear()
        ..addAll(_assignsFromTitles(employees));

      try {
        deptSummary.value = await summaryFuture;
      } catch (_) {
        deptSummary.value = null;
      }

      final tree = _buildTree(list);
      flatDepts
        ..clear()
        ..addAll(list);
      roots
        ..clear()
        ..addAll(tree);
      flatDepts.refresh();
      roots.refresh();

      expandAllDepts();

      // 刷新后去掉已不存在的筛选 id。
      if (filterDeptIds.isNotEmpty) {
        final valid = {
          for (final d in list)
            if (d.deptId != null && d.deptId!.trim().isNotEmpty)
              d.deptId!.trim(),
        };
        filterDeptIds.removeWhere((id) => !valid.contains(id));
        filterDeptIds.refresh();
      }

      String? selectId = tree.isNotEmpty ? tree.first.id : null;
      selectedDeptId.value = selectId;
      _rebuildChartRoot();
      _updateSelectionPath(selectId);
      loading.value = false;

      chartLoading.value = true;
      try {
        // 先尝试无参拉全量编制；失败或为空则按部门（必要时再带职务）补拉。
        var allPositions = <HrmPosition>[];
        try {
          allPositions = await _api.fetchPositions();
        } catch (_) {
          allPositions = const [];
        }
        if (allPositions.isEmpty) {
          allPositions = await _api.fetchPositionsForDepts(
            [
              for (final d in list)
                if (d.deptId != null) d.deptId!,
            ],
            postIds: [
              for (final p in posts)
                if (p.id != null) p.id!,
            ],
          );
        }
        positions
          ..clear()
          ..addAll(allPositions);
        _rebuildIndexes();
        _rebuildPostTags();
        _rebuildReportTree();
      } finally {
        chartLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      loading.value = false;
      chartLoading.value = false;
    }
  }

  /// 从员工 `titleList` 生成在任映射（编制 → 员工）。
  List<HrmEmployeeAssign> _assignsFromTitles(List<HrmEmployeeProfile> list) {
    final out = <HrmEmployeeAssign>[];
    _titleReportParentOf.clear();
    for (final emp in list) {
      final uid = emp.userId;
      for (final t in emp.titleList) {
        final posId = t.positionId?.trim();
        if (posId == null || posId.isEmpty) continue;
        out.add(
          HrmEmployeeAssign()
            ..id = t.id
            ..employeeUserId = uid
            ..positionId = posId
            ..postSeqLevelId = t.postSeqLevelId
            ..isPrimary = t.isPrimary,
        );
        final reportId = t.reportPositionId?.trim();
        if (reportId != null && reportId.isNotEmpty && reportId != posId) {
          _titleReportParentOf[posId] = reportId;
        }
      }
    }
    return out;
  }

  void _rebuildIndexes() {
    _postById
      ..clear()
      ..addEntries([
        for (final p in posts)
          if (p.id != null && p.id!.trim().isNotEmpty) MapEntry(p.id!.trim(), p),
      ]);
    _positionById
      ..clear()
      ..addEntries([
        for (final p in positions)
          if (p.id != null && p.id!.trim().isNotEmpty) MapEntry(p.id!.trim(), p),
      ]);
    _employeeByUserId
      ..clear()
      ..addEntries([
        for (final e in employees)
          if (e.userId != null) MapEntry(e.userId!, e),
      ]);
    _assignByPositionId
      ..clear()
      ..addEntries([
        for (final a in assigns)
          if (a.positionId != null && a.positionId!.trim().isNotEmpty)
            MapEntry(a.positionId!.trim(), a),
      ]);

    _deptNameById
      ..clear()
      ..addEntries([
        for (final d in flatDepts)
          if (d.deptId != null && d.deptId!.trim().isNotEmpty)
            MapEntry(d.deptId!.trim(), (d.deptName ?? '').trim()),
      ]);

    _namesByDept.clear();
    _leaderByDept.clear();
    final leaderScore = <String, int>{};

    for (final emp in employees) {
      final name = emp.name?.trim();
      if (name == null || name.isEmpty) continue;
      for (final t in emp.titleList) {
        final deptId = t.sysDeptId?.trim() ??
            _positionById[t.positionId?.trim() ?? '']?.sysDeptId?.trim();
        if (deptId == null || deptId.isEmpty) continue;
        _namesByDept.putIfAbsent(deptId, () => <String>[]).add(name);
        final score = (t.isPrimary == 1 ? 100000 : 0) +
            (t.postOrderNum ?? 0) * 100 +
            (t.postSeqLeveOrderNum ?? 0);
        final prev = leaderScore[deptId] ?? -1;
        if (score >= prev) {
          leaderScore[deptId] = score;
          _leaderByDept[deptId] = name;
        }
      }
    }

    // title 未带部门时，退回编制表 + 在任映射。
    for (final a in assigns) {
      final posId = a.positionId?.trim();
      final uid = a.employeeUserId;
      if (posId == null || uid == null) continue;
      final pos = _positionById[posId];
      final deptId = pos?.sysDeptId?.trim();
      final name = _employeeByUserId[uid]?.name?.trim();
      if (deptId == null || deptId.isEmpty || name == null || name.isEmpty) {
        continue;
      }
      final names = _namesByDept.putIfAbsent(deptId, () => <String>[]);
      if (!names.contains(name)) names.add(name);
      if (!_leaderByDept.containsKey(deptId)) {
        _leaderByDept[deptId] = name;
      }
    }
  }

  /// 部门负责人展示名。
  String? leaderNameOf(String? deptId) {
    if (deptId == null || deptId.isEmpty) return null;
    return _leaderByDept[deptId];
  }

  /// 按编制 + 员工 titleList 构建全量在任人员索引，再按左侧部门筛选展示树。
  void _rebuildReportTree() {
    _allPersonByPos.clear();
    _reportParentOf.clear();

    // 先按 titleList 建人（可补全职级 / 状态）；再扫编制表补漏。
    final titleByPos = <String, HrmEmployeeTitle>{};
    final empByPos = <String, HrmEmployeeProfile>{};
    for (final emp in employees) {
      for (final t in emp.titleList) {
        final posId = t.positionId?.trim();
        if (posId == null || posId.isEmpty) continue;
        titleByPos[posId] = t;
        empByPos[posId] = emp;
      }
    }

    void putPerson({
      required String posId,
      required String name,
      required int? uid,
      String? postName,
      String? deptId,
      String? deptName,
      String? levelName,
      String? statusLabel,
    }) {
      final resolvedDeptId =
          deptId ?? _positionById[posId]?.sysDeptId?.trim();
      final resolvedPostId = _positionById[posId]?.postId?.trim();
      final resolvedPostName = (postName != null && postName.isNotEmpty)
          ? postName
          : (resolvedPostId != null
              ? (_postById[resolvedPostId]?.name?.trim() ?? '')
              : '');
      final resolvedDeptName = (deptName != null && deptName.isNotEmpty)
          ? deptName
          : (resolvedDeptId != null
              ? (_deptNameById[resolvedDeptId] ?? '')
              : '');
      _allPersonByPos[posId] = OrgPersonNode(
        positionId: posId,
        name: name,
        postName: resolvedPostName,
        deptName: resolvedDeptName,
        deptId: resolvedDeptId,
        userId: uid,
        levelName: levelName,
        statusLabel: statusLabel,
      );
    }

    for (final e in titleByPos.entries) {
      final posId = e.key;
      final t = e.value;
      final emp = empByPos[posId];
      final name = emp?.name?.trim();
      if (name == null || name.isEmpty) continue;
      putPerson(
        posId: posId,
        name: name,
        uid: emp?.userId,
        postName: t.postName?.trim(),
        deptId: t.sysDeptId?.trim(),
        deptName: t.deptName?.trim(),
        levelName: t.postSeqLeveName?.trim(),
        statusLabel: _statusLabelOf(emp?.empStatus),
      );
    }

    for (final pos in positions) {
      final posId = pos.id?.trim();
      if (posId == null || posId.isEmpty) continue;
      if (_allPersonByPos.containsKey(posId)) continue;
      final assign = _assignByPositionId[posId];
      if (assign == null) continue;
      final uid = assign.employeeUserId;
      final emp = uid != null ? _employeeByUserId[uid] : null;
      final name = emp?.name?.trim();
      if (name == null || name.isEmpty) continue;
      putPerson(
        posId: posId,
        name: name,
        uid: uid,
        deptId: pos.sysDeptId?.trim(),
        statusLabel: _statusLabelOf(emp?.empStatus),
      );
    }

    for (final posId in _allPersonByPos.keys) {
      final fromTitle = _titleReportParentOf[posId];
      final fromPos = _positionById[posId]?.reportPositionId?.trim();
      final reportId = (fromTitle != null && fromTitle.isNotEmpty)
          ? fromTitle
          : fromPos;
      if (reportId == null ||
          reportId.isEmpty ||
          reportId == posId ||
          !_allPersonByPos.containsKey(reportId)) {
        continue;
      }
      _reportParentOf[posId] = reportId;
    }

    _applyReportDeptFilter();
  }

  static String? _statusLabelOf(String? status) {
    switch (status?.trim().toUpperCase()) {
      case 'PENDING_LEAVE':
        return '调动中';
      case 'PENDING_ACTIVE':
        return '待入职';
      case 'LEAVE':
        return '已离职';
      default:
        return null;
    }
  }

  /// 选中部门及其全部下级部门 id。
  Set<String> _deptSubtreeIds(String deptId) {
    final node = findNode(deptId);
    if (node == null) return {deptId};
    final out = <String>{};
    void walk(OrgDeptNode n) {
      final id = n.id;
      if (id != null && id.isNotEmpty) out.add(id);
      for (final c in n.children) {
        walk(c);
      }
    }

    walk(node);
    return out;
  }

  /// 租户根 / 未选：不筛选，展示全公司汇报链。
  bool _isCompanyWideReportFilter(String? deptId) {
    if (deptId == null || deptId.isEmpty) return true;
    if (roots.isEmpty) return true;
    return roots.first.id == deptId;
  }

  /// 顶部多选 ∪ 左侧选中 → 允许的部门 id（含下级）；空表示全公司。
  Set<String>? _reportAllowedDeptIds() {
    if (filterDeptIds.isNotEmpty) {
      final out = <String>{};
      for (final id in filterDeptIds) {
        out.addAll(_deptSubtreeIds(id));
      }
      return out;
    }
    final filterDept = selectedDeptId.value;
    if (_isCompanyWideReportFilter(filterDept)) return null;
    return _deptSubtreeIds(filterDept!);
  }

  /// 按顶部部门筛选 / 左侧部门筛选汇报链。
  void _applyReportDeptFilter() {
    final allowed = _reportAllowedDeptIds();
    final Set<String> include;
    if (allowed == null) {
      include = _allPersonByPos.keys.toSet();
    } else {
      include = <String>{};
      for (final e in _allPersonByPos.entries) {
        final d = e.value.deptId;
        if (d == null || !allowed.contains(d)) continue;
        var cur = e.key;
        while (true) {
          if (!include.add(cur)) break;
          final parent = _reportParentOf[cur];
          if (parent == null || !_allPersonByPos.containsKey(parent)) break;
          cur = parent;
        }
      }
    }

    final copies = <String, OrgPersonNode>{};
    for (final id in include) {
      final src = _allPersonByPos[id];
      if (src == null) continue;
      copies[id] = OrgPersonNode(
        positionId: src.positionId,
        name: src.name,
        postName: src.postName,
        deptName: src.deptName,
        deptId: src.deptId,
        userId: src.userId,
        levelName: src.levelName,
        statusLabel: src.statusLabel,
        coverCount: src.coverCount,
      );
    }

    final childIds = <String>{};
    for (final id in include) {
      final parent = _reportParentOf[id];
      if (parent == null || !copies.containsKey(parent)) continue;
      copies[parent]!.children.add(copies[id]!);
      childIds.add(id);
    }

    void sortRec(OrgPersonNode n) {
      n.children.sort((a, b) {
        final pa =
            _postById[_positionById[a.positionId]?.postId?.trim() ?? ''];
        final pb =
            _postById[_positionById[b.positionId]?.postId?.trim() ?? ''];
        final oa = pa?.orderNum ?? 0;
        final ob = pb?.orderNum ?? 0;
        if (oa != ob) return oa.compareTo(ob);
        return a.name.compareTo(b.name);
      });
      for (final c in n.children) {
        sortRec(c);
      }
    }

    final rootsOut = <OrgPersonNode>[
      for (final e in copies.entries)
        if (!childIds.contains(e.key)) e.value,
    ];
    for (final r in rootsOut) {
      sortRec(r);
    }
    rootsOut.sort((a, b) => a.name.compareTo(b.name));

    reportRoots
      ..clear()
      ..addAll(rootsOut);
    reportRoots.refresh();

    final sel = selectedPositionId.value;
    if (sel != null && copies.containsKey(sel)) {
      _updateReportPath(sel);
    } else if (rootsOut.isNotEmpty) {
      selectedPositionId.value = rootsOut.first.positionId;
      _updateReportPath(rootsOut.first.positionId);
    } else {
      selectedPositionId.value = null;
      reportPathIds
        ..clear()
        ..refresh();
    }
  }

  /// 按截图：职务标签为「该职务编制总数」；空缺为未在任编制数。
  void _rebuildPostTags() {
    final seats = <String, Map<String, int>>{};
    final vacant = <String, int>{};

    for (final pos in positions) {
      final deptId = pos.sysDeptId?.trim();
      final postId = pos.postId?.trim();
      final posId = pos.id?.trim();
      if (deptId == null || deptId.isEmpty || postId == null || posId == null) {
        continue;
      }
      final postName = _postById[postId]?.name?.trim();
      if (postName == null || postName.isEmpty) continue;

      final bucket = seats.putIfAbsent(deptId, () => <String, int>{});
      bucket[postName] = (bucket[postName] ?? 0) + 1;
      if (!_assignByPositionId.containsKey(posId)) {
        vacant[deptId] = (vacant[deptId] ?? 0) + 1;
      }
    }

    postTagsByDept
      ..clear()
      ..addAll(seats);
    vacancyByDept
      ..clear()
      ..addAll(vacant);
    postTagsByDept.refresh();
    vacancyByDept.refresh();
  }

  /// 组织图根：优先「总经办」；若与中心部门同级，则提为图根并把兄弟挂到其下。
  void _rebuildChartRoot() {
    if (roots.isEmpty) {
      _displayChartRoot = null;
      return;
    }
    final root = roots.first;
    final rootName = root.dept.deptName ?? '';
    if (rootName.contains('总经办')) {
      _displayChartRoot = root;
      return;
    }
    if (root.children.length == 1) {
      _displayChartRoot = root.children.first;
      return;
    }

    OrgDeptNode? gm;
    for (final c in root.children) {
      if ((c.dept.deptName ?? '').contains('总经办')) {
        gm = c;
        break;
      }
    }
    if (gm == null) {
      _displayChartRoot = root;
      return;
    }

    final hub = OrgDeptNode(gm.dept);
    final kids = <OrgDeptNode>[
      for (final c in root.children)
        if (c.id != gm.id && c.shouldShow) c,
      for (final c in gm.children)
        if (c.shouldShow) c,
    ];
    kids.sort(
      (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
    );
    hub.children.addAll(kids);
    _displayChartRoot = hub;
  }

  List<OrgDeptNode> _buildTree(List<HrmDept> depts) {
    final nodes = <String, OrgDeptNode>{};
    for (final d in depts) {
      final id = d.deptId?.trim();
      if (id == null || id.isEmpty) continue;
      nodes[id] = OrgDeptNode(d);
    }
    final out = <OrgDeptNode>[];
    for (final node in nodes.values) {
      final parentId = node.dept.parentId?.trim();
      if (parentId == null ||
          parentId.isEmpty ||
          parentId == '0' ||
          !nodes.containsKey(parentId)) {
        out.add(node);
      } else {
        nodes[parentId]!.children.add(node);
      }
    }
    void sortRec(OrgDeptNode n) {
      n.children.sort(
        (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
      );
      for (final c in n.children) {
        sortRec(c);
      }
    }

    out.sort(
      (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
    );
    for (final r in out) {
      sortRec(r);
    }
    return out;
  }

  void toggleExpand(String id) {
    if (expandedIds.contains(id)) {
      expandedIds.remove(id);
    } else {
      expandedIds.add(id);
    }
    expandedIds.refresh();
  }

  /// 展开左侧部门树全部节点。
  void expandAllDepts() {
    final expand = <String>{};
    void walk(OrgDeptNode n) {
      final id = n.id;
      if (id != null && id.isNotEmpty) expand.add(id);
      for (final c in n.children) {
        walk(c);
      }
    }

    for (final r in roots) {
      walk(r);
    }
    expandedIds
      ..clear()
      ..addAll(expand);
    expandedIds.refresh();
  }

  bool get hasDeptFilter => filterDeptIds.isNotEmpty;

  /// 组织图子节点（应用顶部多选筛选；空筛选则全部）。
  List<OrgDeptNode> chartChildrenOf(OrgDeptNode node) {
    if (!hasDeptFilter) return node.visibleChildren;
    final allowed = _chartAllowedDeptIds();
    return [
      for (final c in node.visibleChildren)
        if (c.id != null && allowed.contains(c.id)) c,
    ];
  }

  /// 选中部门及其下级 + 到根的祖先（保证树形连线不断）。
  Set<String> _chartAllowedDeptIds() {
    final out = <String>{};
    for (final id in filterDeptIds) {
      out.addAll(_deptSubtreeIds(id));
      out.addAll(_ancestorIds(id));
    }
    return out;
  }

  List<String> _ancestorIds(String deptId) {
    final path = _pathIdsTo(deptId);
    if (path.isEmpty) return const [];
    return [for (final id in path) if (id != deptId) id];
  }

  void toggleFilterDept(String deptId) {
    final id = deptId.trim();
    if (id.isEmpty) return;
    if (filterDeptIds.contains(id)) {
      filterDeptIds.remove(id);
    } else {
      filterDeptIds.add(id);
    }
    filterDeptIds.refresh();
    _onDeptFilterChanged();
  }

  /// 「全部部门」：清空多选，恢复全量展示。
  void clearDeptFilter() {
    if (filterDeptIds.isEmpty) return;
    filterDeptIds.clear();
    filterDeptIds.refresh();
    _onDeptFilterChanged();
  }

  void _onDeptFilterChanged() {
    roots.refresh();
    if (viewMode.value == OrgChartViewMode.reportChain) {
      _applyReportDeptFilter();
    }
  }

  Future<void> createDept({
    required String parentId,
    required String deptName,
    int? orderNum,
    String? status,
  }) async {
    await _api.createDept(
      parentId: parentId,
      deptName: deptName,
      orderNum: orderNum,
      status: status,
    );
    await refreshAll();
  }

  Future<void> updateDept({
    required String deptId,
    required String parentId,
    required String deptName,
    int? orderNum,
    String? status,
  }) async {
    await _api.updateDept(
      deptId: deptId,
      parentId: parentId,
      deptName: deptName,
      orderNum: orderNum,
      status: status,
    );
    await refreshAll();
  }

  Future<void> deleteDept(String deptId) async {
    await _api.deleteDept(deptId);
    await refreshAll();
  }

  Future<void> selectDept(String id) async {
    if (id.isEmpty) return;
    if (selectedDeptId.value == id) {
      _updateSelectionPath(id);
      return;
    }
    // 部门视图：只更新选中链路与蓝框；汇报链视图：按部门（含下级）筛人。
    selectedDeptId.value = id;
    _updateSelectionPath(id);
    if (viewMode.value == OrgChartViewMode.reportChain) {
      _applyReportDeptFilter();
    }
    try {
      final detail = await _api.fetchDeptDetail(id);
      final node = findNode(id);
      if (node != null) {
        node.dept
          ..deptName = detail.deptName ?? node.dept.deptName
          ..headcount = detail.headcount ?? node.dept.headcount
          ..onDuty = detail.onDuty ?? node.dept.onDuty
          ..status = detail.status ?? node.dept.status
          ..orderNum = detail.orderNum ?? node.dept.orderNum;
        // 仅刷新节点数据，不触碰 transformCtrl。
        roots.refresh();
      }
    } catch (_) {
      // 详情失败不阻断选中与图展示。
    }
  }

  void _updateSelectionPath(String? id) {
    selectionPathIds
      ..clear()
      ..addAll(_pathIdsTo(id));
    selectionPathIds.refresh();
  }

  /// 从树根走到 [id] 的路径（含自身）；图根为总经办 hub 时把其并入蓝框链路。
  List<String> _pathIdsTo(String? id) {
    if (id == null || id.isEmpty) return const [];
    List<String>? walk(OrgDeptNode n, List<String> acc) {
      final nid = n.id;
      if (nid == null) return null;
      final next = [...acc, nid];
      if (nid == id) return next;
      for (final c in n.children) {
        final hit = walk(c, next);
        if (hit != null) return hit;
      }
      return null;
    }

    List<String> real = const [];
    for (final r in roots) {
      final hit = walk(r, const []);
      if (hit != null) {
        real = hit;
        break;
      }
    }
    if (real.isEmpty) return const [];

    final hubId = _displayChartRoot?.id;
    final tenantId = roots.first.id;
    if (hubId == null || hubId.isEmpty) return real;
    if (real.contains(hubId)) return real;

    // 真实路径经租户根、图中以总经办为根时：蓝框链路用「总经办 + 其后节点」。
    return [
      hubId,
      for (final x in real)
        if (x != tenantId && x != hubId) x,
    ];
  }

  /// 叶子卡片职务标签（有子部门的中心节点改展示编制行，不走此方法）。
  List<({String label, int count, bool vacancy})> tagsFor(OrgDeptNode node) {
    final id = node.id;
    final out = <({String label, int count, bool vacancy})>[];
    if (id == null) return out;
    final tags = postTagsByDept[id];
    if (tags != null) {
      final entries = tags.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in entries.take(5)) {
        out.add((label: e.key, count: e.value, vacancy: false));
      }
    }
    final seatVacancy = vacancyByDept[id] ?? 0;
    if (seatVacancy > 0) {
      out.add((label: '空缺', count: seatVacancy, vacancy: true));
    }
    return out;
  }

  /// 中心节点「编制 / 空缺」：含下级汇总；空缺也可用本部门编制空缺兜底。
  (int headcount, int vacancy) staffingLine(OrgDeptNode node) {
    final hc = node.subtreeHeadcount;
    var vac = node.subtreeVacancy;
    if (vac <= 0) {
      final id = node.id;
      if (id != null) vac = vacancyByDept[id] ?? 0;
    }
    return (hc, vac);
  }

  void setViewMode(OrgChartViewMode mode) {
    viewMode.value = mode;
    if (mode == OrgChartViewMode.reportChain) {
      _applyReportDeptFilter();
    }
  }

  void setLayout(OrgChartLayout value) => layout.value = value;

  void selectPerson(String positionId) {
    if (positionId.isEmpty) return;
    selectedPositionId.value = positionId;
    _updateReportPath(positionId);
  }

  void _updateReportPath(String? positionId) {
    reportPathIds
      ..clear()
      ..addAll(_reportPathIdsTo(positionId));
    reportPathIds.refresh();
  }

  List<String> _reportPathIdsTo(String? positionId) {
    if (positionId == null || positionId.isEmpty) return const [];
    final path = <String>[];
    var cur = positionId;
    final seen = <String>{};
    while (true) {
      if (!seen.add(cur)) break;
      path.add(cur);
      final parent = _reportParentOf[cur];
      if (parent == null || parent.isEmpty) break;
      cur = parent;
    }
    return path.reversed.toList();
  }

  bool isInReportPath(String? positionId) {
    if (positionId == null || positionId.isEmpty) return false;
    return reportPathIds.contains(positionId);
  }

  bool matchesPersonSearch(OrgPersonNode node) {
    final q = searchQuery.value;
    if (q.isEmpty) return false;
    return node.name.contains(q) ||
        node.postName.contains(q) ||
        node.deptName.contains(q);
  }

  void setZoom(double value) {
    final next = value.clamp(0.5, 1.8);
    zoom.value = next;
    transformCtrl.value = Matrix4.identity()..scaleByDouble(next, next, 1, 1);
  }

  void zoomIn() => setZoom(zoom.value + 0.1);

  void zoomOut() => setZoom(zoom.value - 0.1);

  void resetView() {
    zoom.value = 1;
    transformCtrl.value = Matrix4.identity();
    highlightReport.value = true;
    searchCtrl.clear();
    searchQuery.value = '';
  }

  void setSearch(String value) => searchQuery.value = value.trim();

  /// 将当前组织图（部门视图 / 汇报链）渲染为 PNG 字节。
  Future<Uint8List> captureChartPng({double pixelRatio = 2}) async {
    final ctx = chartExportKey.currentContext;
    if (ctx == null) {
      throw StateError('暂无可导出的架构图');
    }
    final boundary = ctx.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('架构图尚未就绪');
    }
    // 等本帧布局完成后再截图，避免空白或尺寸不准。
    await Future<void>.delayed(Duration.zero);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('生成 PNG 失败');
    }
    return bytes.buffer.asUint8List();
  }

  /// 开启蓝框高亮（汇报链 / 选中路径）。
  void enableHighlightReport() => highlightReport.value = true;

  void clearHighlight() => highlightReport.value = false;

  bool matchesSearch(OrgDeptNode node) {
    final q = searchQuery.value;
    if (q.isEmpty) return false;
    final name = node.dept.deptName ?? '';
    if (name.contains(q)) return true;
    final id = node.id;
    if (id == null) return false;
    final names = _namesByDept[id];
    if (names == null) return false;
    for (final n in names) {
      if (n.contains(q)) return true;
    }
    // 职务名命中
    final tags = postTagsByDept[id];
    if (tags != null) {
      for (final postName in tags.keys) {
        if (postName.contains(q)) return true;
      }
    }
    return false;
  }
}
