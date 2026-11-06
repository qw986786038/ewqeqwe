import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/dict_data.dart';
import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../employee_archive/employee_archive_controller.dart';
import '../onboarding_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kGreen = Color(0xFF22C55E);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFFF4D4F);

void showAddPendingDialog(BuildContext context) {
  _open(context, const _PersonDialog());
}

void showEditPendingDialog(
  BuildContext context,
  HrmEmployeeProfile row,
) {
  _open(context, _PersonDialog(row: row, editing: true));
}

void showConfirmHireDialog(
  BuildContext context,
  HrmEmployeeProfile row,
) {
  _open(context, _PersonDialog(row: row));
}

void _open(BuildContext context, Widget child) {
  final ctrl = context.lx.find<OnboardingController>();
  showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => LxScope(
      bindings: (container) {
        container.putInstance<OnboardingController>(ctrl, owned: false);
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: child,
      ),
    ),
  );
}

class _PersonDialog extends StatefulWidget {
  const _PersonDialog({this.row, this.editing = false});

  final HrmEmployeeProfile? row;
  final bool editing;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  final _form = AppFormController();
  String? _deptId;
  String? _postId;
  String? _positionId;
  String? _levelId;
  List<AppTreeItemNode<String>> _deptNodes = const [];
  var _deptTreeReady = false;
  String? _deptSig;
  var _saving = false;

  bool get _confirm => widget.row != null && !widget.editing;

  String get _title {
    if (widget.editing) return '编辑待入职人员';
    if (_confirm) return '确认入职';
    return '添加待入职人员';
  }

  String? _need(String? id, String label) {
    if (id == null || id.trim().isEmpty) return '请选择$label';
    return null;
  }

  List<AppOption<String>> _empTypeOptions(OnboardingController c) {
    final items = c.dicts[HrmDictTypes.empType] ?? const <DictDataItem>[];
    if (items.isEmpty) {
      return [
        for (final o in EmployeeArchiveController.typeOptions)
          AppOption(value: o.$1, label: o.$2),
      ];
    }
    return [
      for (final item in items)
        if (item.dictValue?.trim().isNotEmpty == true)
          AppOption(
            value: item.dictValue!.trim(),
            label: c.dictText(
              item.dictValue,
              current: EmployeeArchiveController.typeLabel(item.dictValue),
            ),
          ),
    ];
  }

  void _ensureDeptTree(List<HrmDept> depts) {
    final sig = depts.map((d) => d.deptId).join(',');
    if ((_deptTreeReady && _deptSig == sig) || depts.isEmpty) return;
    _deptSig = sig;
    _deptNodes = _deptTree(depts);
    final id = _deptId?.trim();
    if (id != null && id.isNotEmpty) {
      _deptNodes = _setSelected(_deptNodes, id);
    }
    _deptTreeReady = true;
  }

  String? _deptName(List<HrmDept> depts, String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return null;
    for (final d in depts) {
      if (d.deptId?.trim() == key) {
        final name = d.deptName?.trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final title = widget.row?.primaryTitle;
    _deptId = title?.sysDeptId;
    _postId = title?.postId;
    _positionId = title?.positionId;
    _levelId = title?.postSeqLevelId;
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OnboardingController>();
    final row = widget.row;
    final type = row?.empType == 'FULL_TIME' || row?.empType == 'EMPLOYEE'
        ? 'FORMAL'
        : row?.empType;
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: Text(_title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 640),
        onClose: _saving ? null : () => Navigator.of(context).pop(),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                        const _SectionLabel('基本信息'),
                        const SizedBox(height: 16),
                        _Field(
                          label: '姓名',
                          required: true,
                          child: AppTextFormField(
                            name: 'name',
                            hintText: '请输入姓名',
                            initialValue: row?.name,
                            validator: (v) => _limit(v, '姓名', 30, required: true),
                          ),
                        ),
                        _Field(
                          label: '手机号码',
                          required: true,
                          child: AppTextFormField(
                            name: 'mobile',
                            hintText: '请输入手机号码',
                            initialValue: row?.mobile,
                            validator: (v) => _limit(v, '手机号码', 20, required: true),
                          ),
                        ),
                        _Field(
                          label: '个人邮箱',
                          child: AppTextFormField(
                            name: 'personalEmail',
                            hintText: '选填',
                            initialValue: row?.personalEmail,
                            validator: (v) => _email(v),
                          ),
                        ),
                        _Field(
                          label: '预计入职日期',
                          required: true,
                          child: AppDatePickerFormField(
                            name: 'expectedHireDate',
                            hintText: '请选择预计入职日期',
                            // popover 挂在根 Overlay，找不到弹窗内的 AppShadcnScope。
                            mode: shad.PromptMode.dialog,
                            initialValue: _parseDate(row?.hireDate),
                            validator: (v) => v == null ? '请选择预计入职日期' : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _SectionLabel('工作信息'),
                        const SizedBox(height: 16),
                        Obx(() {
                          c.dicts.length;
                          return _Field(
                          label: '员工类型',
                          required: true,
                          child: AppSelectFormField<String>(
                            name: 'empType',
                            hintText: '请选择员工类型',
                            options: _empTypeOptions(c),
                            initialValue: (type == null || type.trim().isEmpty)
                                ? null
                                : type,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? '请选择员工类型' : null,
                          ),
                        );
                        }),
                        Obx(() {
                          c.positions.length;
                          c.dicts.length;
                          final depts = c.seatDepts();
                          _ensureDeptTree(depts);
                          final selected = _deptName(depts, _deptId);
                          return _Field(
                            label: '部门',
                            required: true,
                            child: FormField<String>(
                              initialValue: _deptId,
                              validator: (_) => _need(_deptId, '部门'),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              builder: (field) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AppAnchoredOverlay(
                                      placement: AppAnchoredOverlayPlacement.bottom,
                                      width: AppAnchoredOverlayWidth.matchAnchor,
                                      gap: 4,
                                      maxHeight: 280,
                                      anchorBuilder: (context, actions) {
                                        final open = actions.isOpen;
                                        return AppInkWell(
                                          onPressed: actions.toggle,
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            height: 34,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: open
                                                    ? _kGreen
                                                    : (field.hasError
                                                        ? _kDanger
                                                        : _kBorder),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selected ?? '请选择部门',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: selected == null
                                                          ? _kMuted
                                                          : _kTitle,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  open
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons.keyboard_arrow_down,
                                                  size: 18,
                                                  color: _kMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      overlayBuilder: (context, actions) {
                                        return SizedBox(
                                          height: 240,
                                          child: AppTree<String>(
                                            nodes: _deptNodes,
                                            expandIcon: true,
                                            allowMultiSelect: false,
                                            recursiveSelection: false,
                                            builder: (context, item) {
                                              final id = item.data;
                                              return AppTreeItem(
                                                selected: id == _deptId,
                                                onExpand: item.children.isEmpty
                                                    ? null
                                                    : (expanded) {
                                                        setState(() {
                                                          _deptNodes = _setExpanded(
                                                            _deptNodes,
                                                            id,
                                                            expanded,
                                                          );
                                                        });
                                                      },
                                                onPressed: () {
                                                  field.didChange(id);
                                                  setState(() {
                                                    _deptId = id;
                                                    _postId = null;
                                                    _positionId = null;
                                                    _levelId = null;
                                                    _deptNodes = _setSelected(
                                                      _deptNodes,
                                                      id,
                                                    );
                                                  });
                                                  actions.close();
                                                },
                                                child: Text(
                                                  _deptName(depts, id) ?? id,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: _kTitle,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                    if (field.errorText != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4, left: 2),
                                        child: Text(
                                          field.errorText!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _kDanger,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          );
                        }),
                        _Field(
                          label: '职务',
                          required: true,
                          child: AppSelectFormField<String>(
                            key: ValueKey('post-$_deptId'),
                            name: 'sysPostId',
                            hintText: _deptId == null ? '请先选择部门' : '请选择职务',
                            enabled: _deptId != null,
                            clearable: false,
                            validator: (_) => _need(_postId, '职务'),
                            options: [
                              for (final p in c.postsOfDept(_deptId))
                                if (p.id?.trim().isNotEmpty == true &&
                                    p.name?.trim().isNotEmpty == true)
                                  AppOption(value: p.id!.trim(), label: p.name!.trim()),
                            ],
                            initialValue: _postId,
                            onChanged: (value) {
                              setState(() {
                                _postId = value;
                                _positionId = null;
                                _levelId = null;
                              });
                            },
                          ),
                        ),
                        _Field(
                          label: '编制',
                          required: true,
                          child: AppSelectFormField<String>(
                            key: ValueKey('seat-$_deptId-$_postId'),
                            name: 'positionId',
                            hintText: _postId == null ? '请先选择职务' : '请选择编制',
                            enabled: _postId != null,
                            clearable: false,
                            validator: (_) => _need(_positionId, '编制'),
                            options: [
                              for (final p in c.positionsOf(
                                deptId: _deptId,
                                postId: _postId,
                              ))
                                AppOption(
                                  value: p.id!.trim(),
                                  label: c.positionLabel(p),
                                ),
                            ],
                            initialValue: _positionId,
                            onChanged: (value) {
                              setState(() {
                                _positionId = value;
                                _levelId = null;
                              });
                            },
                          ),
                        ),
                        _Field(
                          label: '职级',
                          required: true,
                          child: AppSelectFormField<String>(
                            key: ValueKey('level-$_positionId'),
                            name: 'postSeqLevelId',
                            hintText: _positionId == null ? '请先选择编制' : '请选择职级',
                            enabled: _positionId != null,
                            clearable: false,
                            validator: (_) => _need(_levelId, '职级'),
                            options: [
                              for (final l in c.levels)
                                if (l.id?.trim().isNotEmpty == true &&
                                    l.code?.trim().isNotEmpty == true)
                                  AppOption(value: l.id!.trim(), label: l.code!.trim()),
                            ],
                            initialValue: _levelId,
                            onChanged: (value) => _levelId = value,
                          ),
                        ),
          ],
        ),
        actions: [
          HyperButton.outlined(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            label: const Text('取消'),
          ),
          HyperButton.filled(
            loading: _saving,
            onPressed: _saving ? null : () => _submit(context, c),
            label: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, OnboardingController c) async {
    await _form.submit((values) async {
      final seat = _positionId?.trim();
      final level = _levelId?.trim();
      final seatEmpty = seat == null || seat.isEmpty;
      final levelEmpty = level == null || level.isEmpty;
      final missing = _need(_deptId, '部门') ??
          _need(_postId, '职务') ??
          _need(_positionId, '编制') ??
          _need(_levelId, '职级');
      if (missing != null) {
        AppToast.show(context: context, title: missing);
        return;
      }
      final date = values['expectedHireDate'];
      final value = OnboardingFormValue(
        name: _str(values['name']) ?? '',
        mobile: _str(values['mobile']) ?? '',
        personalEmail: _str(values['personalEmail']),
        expectedHireDate: date is DateTime ? _fmt(date) : '',
        empType: _str(values['empType']) ?? '',
        sysDeptId: _deptId,
        sysPostId: _postId,
        positionId: seatEmpty ? null : seat,
        postSeqLevelId: levelEmpty ? null : level,
      );
      setState(() => _saving = true);
      try {
        final String done;
        if (widget.editing) {
          await c.updatePending(widget.row!, value);
          done = '已保存';
        } else if (_confirm) {
          await c.confirmHire(widget.row!, value);
          done = '已确认入职';
        } else {
          await c.addPending(value);
          done = '已添加待入职人员';
        }
        if (!context.mounted) return;
        AppToast.show(context: context, title: done);
        Navigator.of(context).pop();
      } catch (e) {
        if (!context.mounted) return;
        AppToast.show(context: context, title: e.toString());
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: _kBorder),
          ),
          child: Text(text, style: const TextStyle(fontSize: 12, color: _kTitle)),
        ),
        const Expanded(child: Divider(color: _kBorder)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 108,
            child: Text.rich(
              TextSpan(
                children: [
                  if (required)
                    const TextSpan(
                      text: '* ',
                      style: TextStyle(color: _kDanger, fontSize: 13),
                    ),
                  TextSpan(text: label),
                ],
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

String? _limit(String? value, String label, int max, {bool required = false}) {
  final text = value?.trim() ?? '';
  if (required && text.isEmpty) return '请输入$label';
  if (text.length > max) return '$label不能超过 $max 个字符';
  return null;
}

String? _email(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.length > 100) return '个人邮箱不能超过 100 个字符';
  if (!text.contains('@') || text.startsWith('@') || text.endsWith('@')) {
    return '请输入有效邮箱';
  }
  return null;
}

String? _str(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _parseDate(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

String _fmt(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

class _DeptNode {
  _DeptNode(this.id, this.order);

  final String id;
  final int order;
  final List<_DeptNode> children = [];
}

List<AppTreeItemNode<String>> _deptTree(List<HrmDept> depts) {
  final nodes = <String, _DeptNode>{};
  for (final d in depts) {
    final id = d.deptId?.trim();
    final name = d.deptName?.trim();
    if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
    nodes[id] = _DeptNode(id, d.orderNum ?? 0);
  }
  final roots = <_DeptNode>[];
  for (final d in depts) {
    final id = d.deptId?.trim();
    final node = id == null ? null : nodes[id];
    if (node == null) continue;
    final parentId = d.parentId?.trim();
    final parent = (parentId == null || parentId.isEmpty || parentId == '0')
        ? null
        : nodes[parentId];
    if (parent == null) {
      roots.add(node);
    } else {
      parent.children.add(node);
    }
  }
  void sortRec(_DeptNode n) {
    n.children.sort((a, b) => a.order.compareTo(b.order));
    for (final c in n.children) {
      sortRec(c);
    }
  }

  roots.sort((a, b) => a.order.compareTo(b.order));
  for (final r in roots) {
    sortRec(r);
  }

  AppTreeItemNode<String> toItem(_DeptNode n, {required bool expanded}) {
    return AppTreeItemNode(
      data: n.id,
      expanded: expanded,
      children: [
        for (final c in n.children) toItem(c, expanded: false),
      ],
    );
  }

  return [for (final r in roots) toItem(r, expanded: true)];
}

List<AppTreeItemNode<String>> _setExpanded(
  List<AppTreeItemNode<String>> nodes,
  String id,
  bool expanded,
) {
  return [
    for (final n in nodes)
      AppTreeItemNode(
        data: n.data,
        expanded: n.data == id ? expanded : n.expanded,
        selected: n.selected,
        children: _setExpanded(
          n.children.whereType<AppTreeItemNode<String>>().toList(),
          id,
          expanded,
        ),
      ),
  ];
}

List<AppTreeItemNode<String>> _setSelected(
  List<AppTreeItemNode<String>> nodes,
  String id,
) {
  return [
    for (final n in nodes)
      AppTreeItemNode(
        data: n.data,
        expanded: n.expanded,
        selected: n.data == id,
        children: _setSelected(
          n.children.whereType<AppTreeItemNode<String>>().toList(),
          id,
        ),
      ),
  ];
}
