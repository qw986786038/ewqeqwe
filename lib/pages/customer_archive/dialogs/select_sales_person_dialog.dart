import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../models/hrm_dept.dart';
import '../../../models/hrm_employee.dart';
import '../../../models/hrm_employee_assign.dart';
import '../../../models/hrm_employee_profile.dart';
import '../../../models/hrm_position.dart';
import '../../../models/hrm_post.dart';
import '../../../services/hrm_api.dart';

const _kPrimary = Color(0xFF0958D9);
const _kTitle = Color(0xFF141414);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFD0D5DD);
const _kSelectedBg = Color(0xFFE8F3FF);
const _kBarrier = Color(0x99000000);

/// 打开「选择销售人员」弹窗；确定后返回选中员工列表。
///
/// 人员数据与 HRM 组织架构同源：部门树 + 在任任职 + 员工档案 + 席位/岗位，
/// 不再走 `employee-directory`。
Future<List<HrmEmployee>?> showSelectSalesPersonDialog(
  BuildContext context, {
  Set<int> alreadySelectedUserIds = const {},
}) {
  return AppDialog.show<List<HrmEmployee>>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: _kBarrier,
    builder: (dialogContext) {
      final mq = MediaQuery.of(dialogContext);
      return AppShadcnScope(
        config: AppThemeConfig.standard(
          primary: _kPrimary,
          themeMode: AppThemeMode.light,
          controls: const AppControlMetrics(
            height: 34,
            buttonHeight: 32,
            horizontalPadding: 10,
            fontSize: 12,
            iconSize: 14,
            contentGap: 6,
          ),
        ),
        child: MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.noScaling),
          child: _SelectSalesPersonDialog(
            alreadySelectedUserIds: alreadySelectedUserIds,
            onClose: () => AppOverlay.close<List<HrmEmployee>>(dialogContext),
            onConfirm: (list) =>
                AppOverlay.close<List<HrmEmployee>>(dialogContext, list),
          ),
        ),
      );
    },
  ).future;
}

class _DeptNode {
  _DeptNode(this.dept);
  final HrmDept dept;
  final List<_DeptNode> children = [];
  var expanded = true;
}

class _SelectSalesPersonDialog extends StatefulWidget {
  const _SelectSalesPersonDialog({
    required this.alreadySelectedUserIds,
    required this.onClose,
    required this.onConfirm,
  });

  final Set<int> alreadySelectedUserIds;
  final VoidCallback onClose;
  final ValueChanged<List<HrmEmployee>> onConfirm;

  @override
  State<_SelectSalesPersonDialog> createState() =>
      _SelectSalesPersonDialogState();
}

class _SelectSalesPersonDialogState extends State<_SelectSalesPersonDialog> {
  final _api = HrmApi();
  final _deptFilterCtrl = TextEditingController();
  final _nameFilterCtrl = TextEditingController();

  var _bootLoading = true;
  String? _bootError;
  List<_DeptNode> _roots = const [];
  String? _selectedDeptId;

  /// 与 HRM 组织架构同源：在任 + 员工档案 + 席位 + 岗位。
  List<HrmEmployeeAssign> _assigns = const [];
  final Map<int, HrmEmployeeProfile> _profileByUserId = {};
  final Map<String, HrmPosition> _positionById = {};
  final Map<String, String> _postNameById = {};
  final Map<String, String> _deptNameById = {};

  var _empLoading = false;
  String? _empError;
  List<HrmEmployee> _employees = const [];
  final Set<int> _selectedUserIds = {};
  final Map<int, HrmEmployee> _selectedMap = {};

  @override
  void initState() {
    super.initState();
    _selectedUserIds.addAll(widget.alreadySelectedUserIds);
    _bootstrap();
  }

  @override
  void dispose() {
    _deptFilterCtrl.dispose();
    _nameFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootLoading = true;
      _bootError = null;
    });
    try {
      // 数据源与组织架构 refreshAll 一致。
      final results = await Future.wait([
        _api.fetchDepts(),
        _api.fetchOnDutyAssigns(),
        _api.fetchEmployeeProfiles(pageNum: 1, pageSize: 10000),
        _api.fetchPosts(),
      ]);
      if (!mounted) return;
      final depts = results[0] as List<HrmDept>;
      _assigns = results[1] as List<HrmEmployeeAssign>;
      final profiles = results[2] as List<HrmEmployeeProfile>;
      final posts = results[3] as List<HrmPost>;

      _profileByUserId
        ..clear()
        ..addEntries([
          for (final e in profiles)
            if (e.userId != null) MapEntry(e.userId!, e),
        ]);
      _postNameById
        ..clear()
        ..addEntries([
          for (final p in posts)
            if (p.id != null && p.id!.trim().isNotEmpty)
              MapEntry(p.id!.trim(), (p.name ?? '').trim()),
        ]);
      _deptNameById
        ..clear()
        ..addEntries([
          for (final d in depts)
            if (d.deptId != null && d.deptId!.trim().isNotEmpty)
              MapEntry(d.deptId!.trim(), (d.deptName ?? '').trim()),
        ]);

      // 席位拉取与组织架构相同：先全量，空则按部门+岗位补拉。
      var positions = <HrmPosition>[];
      try {
        positions = await _api.fetchPositions();
      } catch (_) {
        positions = const [];
      }
      if (positions.isEmpty) {
        try {
          positions = await _api.fetchPositionsForDepts(
            [
              for (final d in depts)
                if (d.deptId != null) d.deptId!,
            ],
            postIds: [
              for (final p in posts)
                if (p.id != null) p.id!,
            ],
          );
        } catch (_) {
          positions = const [];
        }
      }
      if (!mounted) return;
      _positionById
        ..clear()
        ..addEntries([
          for (final p in positions)
            if (p.id != null && p.id!.trim().isNotEmpty)
              MapEntry(p.id!.trim(), p),
        ]);

      final roots = _buildTree(depts);
      String? firstId;
      if (roots.isNotEmpty) {
        firstId = roots.first.dept.deptId;
        // 默认选中第一个有子节点的子部门，更贴近「选部门看人」场景。
        if (roots.first.children.isNotEmpty) {
          firstId = roots.first.children.first.dept.deptId;
        }
      }
      setState(() {
        _roots = roots;
        _selectedDeptId = firstId;
        _bootLoading = false;
      });
      if (firstId != null) {
        await _loadEmployees(firstId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bootLoading = false;
        _bootError = e.toString();
      });
    }
  }

  List<_DeptNode> _buildTree(List<HrmDept> depts) {
    final nodes = <String, _DeptNode>{};
    for (final d in depts) {
      final id = d.deptId?.trim();
      if (id == null || id.isEmpty) continue;
      nodes[id] = _DeptNode(d);
    }
    final roots = <_DeptNode>[];
    for (final node in nodes.values) {
      final parentId = node.dept.parentId?.trim();
      if (parentId == null ||
          parentId.isEmpty ||
          parentId == '0' ||
          !nodes.containsKey(parentId)) {
        roots.add(node);
      } else {
        nodes[parentId]!.children.add(node);
      }
    }
    void sortRec(_DeptNode n) {
      n.children.sort(
        (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
      );
      for (final c in n.children) {
        sortRec(c);
      }
    }

    roots.sort(
      (a, b) => (a.dept.orderNum ?? 0).compareTo(b.dept.orderNum ?? 0),
    );
    for (final r in roots) {
      sortRec(r);
    }
    return roots;
  }

  /// 选中部门及其下级部门 id（与组织架构部门筛选一致）。
  Set<String> _deptSubtreeIds(String deptId) {
    _DeptNode? find(List<_DeptNode> nodes) {
      for (final n in nodes) {
        if (n.dept.deptId?.trim() == deptId) return n;
        final hit = find(n.children);
        if (hit != null) return hit;
      }
      return null;
    }

    final node = find(_roots);
    if (node == null) return {deptId};
    final out = <String>{};
    void walk(_DeptNode n) {
      final id = n.dept.deptId?.trim();
      if (id != null && id.isNotEmpty) out.add(id);
      for (final c in n.children) {
        walk(c);
      }
    }

    walk(node);
    return out;
  }

  HrmEmployee _toEmployee({
    required int userId,
    required HrmEmployeeProfile? profile,
    required HrmPosition? position,
  }) {
    final deptId = position?.sysDeptId?.trim();
    final postId = position?.postId?.trim();
    final deptName = (position?.deptName?.trim().isNotEmpty ?? false)
        ? position!.deptName!.trim()
        : (deptId != null ? (_deptNameById[deptId] ?? '') : '');
    final postName = (position?.postName?.trim().isNotEmpty ?? false)
        ? position!.postName!.trim()
        : (postId != null ? (_postNameById[postId] ?? '') : '');
    final name = profile?.name?.trim();
    return HrmEmployee()
      ..userId = userId
      ..no = profile?.no
      ..name = (name != null && name.isNotEmpty) ? name : '用户$userId'
      ..englishName = profile?.englishName
      ..aliasName = profile?.aliasName
      ..gender = profile?.gender
      ..empStatus = profile?.empStatus ?? 'ACTIVE'
      ..mobile = profile?.mobile
      ..corpEmail = profile?.corpEmail
      ..imAccount = profile?.imAccount
      ..titleList = [
        HrmEmployeeTitle()
          ..positionId = position?.id
          ..sysDeptId = deptId
          ..deptName = deptName.isEmpty ? null : deptName
          ..postId = postId
          ..postName = postName.isEmpty ? null : postName
          ..isPrimary = 1,
      ];
  }

  /// 按组织架构同源数据筛人：在任 ∩ 席位.部门（含下级）。
  /// 页面交互仍与原先一致：点左侧部门 → 右侧列表刷新。
  Future<void> _loadEmployees(String deptId) async {
    setState(() {
      _empLoading = true;
      _empError = null;
      _employees = const [];
    });
    try {
      var deptIds = _deptSubtreeIds(deptId);
      var list = _employeesOfDepts(deptIds);
      // 子树无在任时，再试「仅当前部门」（避免树节点匹配偏差导致空列表）。
      if (list.isEmpty) {
        list = _employeesOfDepts({deptId.trim()});
      }
      // 席位未拉到时无法按部门过滤，退化为展示全部在任（与组织架构同源数据）。
      if (list.isEmpty && _assigns.isNotEmpty && _positionById.isEmpty) {
        list = _employeesOfDepts(null);
      }
      list.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      if (!mounted) return;
      setState(() {
        _employees = list;
        _empLoading = false;
        for (final e in list) {
          final uid = e.userId;
          if (uid != null && _selectedUserIds.contains(uid)) {
            _selectedMap[uid] = e;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _empLoading = false;
        _empError = e.toString();
      });
    }
  }

  /// [deptIds] 为 null 时不过滤部门（展示全部在任）。
  List<HrmEmployee> _employeesOfDepts(Set<String>? deptIds) {
    final seen = <int>{};
    final list = <HrmEmployee>[];
    for (final a in _assigns) {
      final posId = a.positionId?.trim();
      final uid = a.employeeUserId;
      if (posId == null || posId.isEmpty || uid == null) continue;
      final pos = _positionById[posId];
      if (deptIds != null) {
        final posDept = pos?.sysDeptId?.trim();
        if (posDept == null || posDept.isEmpty || !deptIds.contains(posDept)) {
          continue;
        }
      }
      if (!seen.add(uid)) continue;
      final profile = _profileByUserId[uid];
      // 档案尚未同步时仍展示在任（至少有 userId）。
      list.add(
        _toEmployee(
          userId: uid,
          profile: profile,
          position: pos,
        ),
      );
    }
    return list;
  }

  void _selectDept(_DeptNode node) {
    final id = node.dept.deptId?.trim();
    if (id == null || id.isEmpty) return;
    if (id == _selectedDeptId) return;
    setState(() => _selectedDeptId = id);
    _loadEmployees(id);
  }

  List<_DeptNode> _filteredRoots() {
    final q = _deptFilterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _roots;

    _DeptNode? filterNode(_DeptNode node) {
      final name = node.dept.deptName?.toLowerCase() ?? '';
      final kids = <_DeptNode>[];
      for (final c in node.children) {
        final f = filterNode(c);
        if (f != null) kids.add(f);
      }
      if (name.contains(q) || kids.isNotEmpty) {
        final copy = _DeptNode(node.dept)..expanded = true;
        copy.children.addAll(kids);
        return copy;
      }
      return null;
    }

    final out = <_DeptNode>[];
    for (final r in _roots) {
      final f = filterNode(r);
      if (f != null) out.add(f);
    }
    return out;
  }

  List<HrmEmployee> get _visibleEmployees {
    final q = _nameFilterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _employees;
    return [
      for (final e in _employees)
        if ((e.name?.toLowerCase().contains(q) ?? false) ||
            (e.englishName?.toLowerCase().contains(q) ?? false))
          e,
    ];
  }

  void _toggleUser(HrmEmployee e, bool selected) {
    final uid = e.userId;
    if (uid == null) return;
    setState(() {
      if (selected) {
        _selectedUserIds.add(uid);
        _selectedMap[uid] = e;
      } else {
        _selectedUserIds.remove(uid);
        _selectedMap.remove(uid);
      }
    });
  }

  void _toggleAllVisible(bool selected) {
    setState(() {
      for (final e in _visibleEmployees) {
        final uid = e.userId;
        if (uid == null) continue;
        if (selected) {
          _selectedUserIds.add(uid);
          _selectedMap[uid] = e;
        } else {
          _selectedUserIds.remove(uid);
          _selectedMap.remove(uid);
        }
      }
    });
  }

  void _confirm() {
    final list = <HrmEmployee>[];
    for (final id in _selectedUserIds) {
      final e = _selectedMap[id];
      if (e != null) list.add(e);
    }
    // 已选但当前列表未加载到的 id：无法带回完整对象，跳过。
    widget.onConfirm(list);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogH = (screen.height * 0.82).clamp(480.0, 720.0);
    final dialogW = (screen.width * 0.72).clamp(720.0, 960.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogW,
            maxHeight: dialogH,
            minWidth: 720,
            minHeight: 480,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Text(
                        '选择销售人员',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTitle,
                        ),
                      ),
                      const Spacer(),
                      AppInkWell(
                        onPressed: widget.onClose,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close, size: 18, color: _kMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Expanded(
                  child: _bootLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        )
                      : _bootError != null
                      ? Center(
                          child: Text(
                            _bootError!,
                            style: const TextStyle(color: Color(0xFFCF1322)),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 240,
                              child: _buildDeptPane(),
                            ),
                            const VerticalDivider(width: 1, color: _kBorder),
                            Expanded(child: _buildEmployeePane()),
                          ],
                        ),
                ),
                const Divider(height: 1, color: _kBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton.outline(
                        onPressed: widget.onClose,
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 10),
                      AppButton.primary(
                        onPressed: _confirm,
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeptPane() {
    final roots = _filteredRoots();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            controller: _deptFilterCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: '筛选部门',
              hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _kBorder),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            children: [
              for (final root in roots) ..._buildDeptTiles(root, 0),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDeptTiles(_DeptNode node, int depth) {
    final id = node.dept.deptId;
    final selected = id != null && id == _selectedDeptId;
    final hasChildren = node.children.isNotEmpty;
    final out = <Widget>[
      AppInkWell(
        onPressed: () => _selectDept(node),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: EdgeInsets.fromLTRB(8.0 + depth * 12, 6, 6, 6),
          decoration: BoxDecoration(
            color: selected ? _kSelectedBg : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (hasChildren)
                AppInkWell(
                  onPressed: () => setState(() => node.expanded = !node.expanded),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      node.expanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 16,
                      color: _kMuted,
                    ),
                  ),
                )
              else
                const SizedBox(width: 20),
              Expanded(
                child: Text(
                  node.dept.deptName ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? _kPrimary : _kTitle,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    if (hasChildren && node.expanded) {
      for (final c in node.children) {
        out.addAll(_buildDeptTiles(c, depth + 1));
      }
    }
    return out;
  }

  Widget _buildEmployeePane() {
    final rows = _visibleEmployees;
    final visibleIds = [
      for (final e in rows)
        if (e.userId != null) e.userId!,
    ];
    final selectedVisible =
        visibleIds.where(_selectedUserIds.contains).length;
    final allChecked =
        visibleIds.isNotEmpty && selectedVisible == visibleIds.length;
    final partial =
        selectedVisible > 0 && selectedVisible < visibleIds.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameFilterCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: '输入姓名搜索',
              hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _kBorder),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _empLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _empError != null
                ? Center(
                    child: Text(
                      _empError!,
                      style: const TextStyle(color: Color(0xFFCF1322)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EmpHeader(
                        allChecked: allChecked,
                        partial: partial,
                        onToggleAll: visibleIds.isEmpty
                            ? null
                            : () => _toggleAllVisible(!allChecked),
                      ),
                      const Divider(height: 1, color: _kBorder),
                      Expanded(
                        child: rows.isEmpty
                            ? const Center(
                                child: Text(
                                  '暂无人员',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kMuted,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: rows.length,
                                itemBuilder: (context, index) {
                                  final e = rows[index];
                                  final uid = e.userId;
                                  final checked = uid != null &&
                                      _selectedUserIds.contains(uid);
                                  return _EmpRow(
                                    employee: e,
                                    checked: checked,
                                    onChanged: (v) =>
                                        _toggleUser(e, v ?? false),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmpHeader extends StatelessWidget {
  const _EmpHeader({
    required this.allChecked,
    required this.partial,
    required this.onToggleAll,
  });

  final bool allChecked;
  final bool partial;
  final VoidCallback? onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: allChecked
                  ? true
                  : partial
                  ? null
                  : false,
              tristate: true,
              onChanged: onToggleAll == null
                  ? null
                  : (_) => onToggleAll!(),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              '姓名',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              '部门/职位',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(
            width: 64,
            child: Text(
              '状态',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmpRow extends StatelessWidget {
  const _EmpRow({
    required this.employee,
    required this.checked,
    required this.onChanged,
  });

  final HrmEmployee employee;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(value: checked, onChanged: onChanged),
          ),
          Expanded(
            flex: 2,
            child: Text(
              employee.name ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              employee.englishName ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              hrmEmployeeDeptPost(employee),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              hrmEmployeeStatusLabel(employee.empStatus),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

String hrmEmployeeDeptPost(HrmEmployee e) {
  HrmEmployeeTitle? primary;
  for (final t in e.titleList) {
    if (t.isPrimary == 1) {
      primary = t;
      break;
    }
  }
  primary ??= e.titleList.isEmpty ? null : e.titleList.first;
  final dept = primary?.deptName?.trim() ?? '';
  final post = primary?.postName?.trim() ?? '';
  if (dept.isEmpty && post.isEmpty) return '-';
  if (dept.isEmpty) return post;
  if (post.isEmpty) return dept;
  return '$dept / $post';
}

String hrmEmployeeStatusLabel(String? status) {
  final s = status?.trim().toUpperCase() ?? '';
  return switch (s) {
    'ACTIVE' => '在职',
    'INACTIVE' || 'LEAVE' => '离职',
    _ => s.isEmpty ? '-' : s,
  };
}

String hrmEmployeeGenderLabel(String? gender) {
  final g = gender?.trim() ?? '';
  return switch (g) {
    '0' => '男',
    '1' => '女',
    '男' || '女' => g,
    _ => '-',
  };
}
