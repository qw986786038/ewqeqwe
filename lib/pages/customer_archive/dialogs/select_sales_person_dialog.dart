import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../models/hrm_dept.dart';
import '../../../models/hrm_employee.dart';
import '../../../services/hrm_api.dart';

const _kPrimary = Color(0xFF0958D9);
const _kTitle = Color(0xFF141414);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFD0D5DD);
const _kSelectedBg = Color(0xFFE8F3FF);

/// 打开「选择销售人员」弹窗；确定后返回选中员工列表。
///
/// 人员数据与 HRM 企业通讯录同源：部门树 + `employee-directory`。
Future<List<HrmEmployee>?> showSelectSalesPersonDialog(
  BuildContext context, {
  Set<int> alreadySelectedUserIds = const {},
}) {
  return showHyperDialog<List<HrmEmployee>>(
    context: context,
    barrierDismissible: false,
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
            onClose: () => Navigator.of(dialogContext).pop(),
            onConfirm: (list) => Navigator.of(dialogContext).pop(list),
          ),
        ),
      );
    },
  );
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
      final depts = await _api.fetchDepts();
      if (!mounted) return;
      final roots = _buildTree(depts);
      String? firstId;
      if (roots.isNotEmpty) {
        firstId = roots.first.dept.deptId;
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

  /// 与 HRM 企业通讯录一致：`employee-directory` + 含下级部门。
  Future<void> _loadEmployees(String deptId) async {
    setState(() {
      _empLoading = true;
      _empError = null;
      _employees = const [];
    });
    try {
      final list = await _api.fetchEmployees(
        sysDeptId: deptId,
        includeChildren: true,
      );
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

    final contentH = dialogH - 100;

    return HyperDialog(
      title: const Text('选择销售人员'),
      scrollable: false,
      style: HyperDialogStyle(maxWidth: dialogW),
      onClose: widget.onClose,
      content: SizedBox(
        height: contentH,
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
      actions: [
        HyperButton.outlined(
          onPressed: widget.onClose,
          label: const Text('取消'),
        ),
        HyperButton.filled(
          onPressed: _confirm,
          label: const Text('确定'),
        ),
      ],
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
