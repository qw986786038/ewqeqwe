import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../models/dict_data.dart';
import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../services/dict_api.dart';
import '../../../../services/hrm_api.dart';

const _kGreen = Color(0xFF22C55E);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFF53F3F);
const _kReadonly = Color(0xFFF7F8FA);

Future<bool> showEmployeeTransferPostDialog(
  BuildContext context, {
  required HrmEmployeeProfile profile,
  HrmEmployeeTitle? initial,
}) {
  return showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
      child: _TransferPostDialog(profile: profile, initial: initial),
    ),
  ).then((v) => v == true);
}

class _TransferPostDialog extends StatefulWidget {
  const _TransferPostDialog({required this.profile, this.initial});

  final HrmEmployeeProfile profile;
  final HrmEmployeeTitle? initial;

  @override
  State<_TransferPostDialog> createState() => _TransferPostDialogState();
}

class _TransferPostDialogState extends State<_TransferPostDialog> {
  final _api = HrmApi();
  final _dictApi = DictApi();
  final _form = AppFormController();

  var _loading = true;
  var _saving = false;
  String? _loadError;

  List<HrmDept> _depts = const [];
  List<AppTreeItemNode<String>> _deptNodes = const [];
  List<HrmPost> _posts = const [];
  List<HrmPosition> _positions = const [];
  Map<String, List<DictDataItem>> _dicts = const {};
  List<HrmPostSeqLevel> _levels = const [];

  String? _oldPositionId;
  String? _deptId;
  String? _postId;
  String? _seatId;
  String? _levelId;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initial?.positionId?.trim();
    if (initialId != null && initialId.isNotEmpty) {
      _oldPositionId = initialId;
    } else {
      final titles = _originTitles;
      if (titles.length == 1) _oldPositionId = titles.first.positionId?.trim();
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  List<HrmEmployeeTitle> get _originTitles => [
        for (final t in widget.profile.titleList)
          if (t.positionId?.trim().isNotEmpty == true) t,
      ];

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchDepts(),
        _api.fetchPosts(),
        _api.fetchPositions(used: 0),
        _api.fetchPostSeqLevels(),
        _dictApi.fetchMany(HrmDictTypes.all),
      ]);
      if (!mounted) return;
      setState(() {
        _depts = results[0] as List<HrmDept>;
        _posts = results[1] as List<HrmPost>;
        _positions = results[2] as List<HrmPosition>;
        _dicts = results[4] as Map<String, List<DictDataItem>>;
        _deptNodes = _deptTree(_seatDepts());
        _levels = results[3] as List<HrmPostSeqLevel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  List<HrmDept> _seatDepts() {
    final byId = <String, HrmDept>{
      for (final dept in _depts)
        if (dept.deptId?.trim().isNotEmpty == true) dept.deptId!.trim(): dept,
    };
    final keep = <String>{};
    for (final item in _positions) {
      if (item.postId?.trim().isNotEmpty != true) continue;
      var id = item.sysDeptId?.trim();
      while (id != null && id.isNotEmpty && id != '0' && keep.add(id)) {
        id = byId[id]?.parentId?.trim();
      }
    }
    return [
      for (final dept in _depts)
        if (keep.contains(dept.deptId?.trim())) dept,
    ];
  }

  List<HrmPost> get _postsOfDept {
    final dept = _deptId?.trim();
    if (dept == null || dept.isEmpty) return const [];
    final ids = <String>{
      for (final p in _positions)
        if (p.sysDeptId?.trim() == dept && p.postId?.trim().isNotEmpty == true)
          p.postId!.trim(),
    };
    return [
      for (final post in _posts)
        if (post.id?.trim().isNotEmpty == true &&
            ids.contains(post.id!.trim()) &&
            post.name?.trim().isNotEmpty == true)
          post,
    ];
  }

  List<HrmPosition> get _seatsOfPost {
    final dept = _deptId?.trim();
    final post = _postId?.trim();
    final oldId = _oldPositionId?.trim();
    if (dept == null || dept.isEmpty || post == null || post.isEmpty) {
      return const [];
    }
    return [
      for (final p in _positions)
        if (p.id?.trim().isNotEmpty == true &&
            p.id!.trim() != oldId &&
            p.sysDeptId?.trim() == dept &&
            p.postId?.trim() == post)
          p,
    ];
  }

  String _levelLabel(HrmPostSeqLevel level) {
    final code = level.code?.trim() ?? '';
    if (code.isNotEmpty) return code;
    return level.id?.trim() ?? '-';
  }

  String _originLabel(HrmEmployeeTitle title) {
    final dept = title.deptName?.trim() ?? '';
    final post = title.postName?.trim() ?? '';
    final level = title.postSeqLeveName?.trim() ?? '';
    final parts = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
      if (level.isNotEmpty) level,
    ];
    final text = parts.isEmpty ? (title.positionId?.trim() ?? '-') : parts.join(' / ');
    if (title.isPrimary == 1) return '$text · 主岗';
    return text;
  }

  String? _deptName(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return null;
    for (final d in _depts) {
      if (d.deptId?.trim() == key && d.deptName?.trim().isNotEmpty == true) {
        return d.deptName!.trim();
      }
    }
    return null;
  }

  String? _dictLabel(String? code) {
    final value = code?.trim();
    if (value == null || value.isEmpty) return null;
    for (final items in _dicts.values) {
      for (final item in items) {
        if (item.dictValue?.trim() == value) {
          final label = item.dictLabel?.trim();
          if (label != null && label.isNotEmpty) return label;
        }
      }
    }
    return null;
  }

  String _postName(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return '';
    for (final post in _posts) {
      if (post.id?.trim() == key) return post.name?.trim() ?? '';
    }
    return '';
  }

  String _seatLabel(HrmPosition item) {
    final dept = item.deptName?.trim().isNotEmpty == true
        ? item.deptName!.trim()
        : (_deptName(item.sysDeptId) ?? '');
    final post = item.postName?.trim().isNotEmpty == true
        ? item.postName!.trim()
        : _postName(item.postId);
    final current = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
    ].join(' / ');
    final shown = current.isEmpty ? (item.id?.trim() ?? '-') : current;
    final typeNow = switch (item.type?.trim().toUpperCase()) {
      'REGULAR' => '正式',
      'RESERVE' => '储备',
      'OUTSOURCE' => '外包',
      _ => item.type?.trim() ?? '',
    };
    final typeZh = _dictLabel(item.type) ?? typeNow;
    if (typeZh.isEmpty || typeZh == shown) return shown;
    return '$typeZh（$shown）';
  }

  String? _need(String? id, String label) {
    if (id == null || id.trim().isEmpty) return '请选择$label';
    return null;
  }

  Future<void> _submit() async {
    if (_saving || _loading) return;
    await _form.submit((_) async {
      final missing = _need(_oldPositionId, '原编制') ??
          _need(_deptId, '目标部门') ??
          _need(_postId, '目标职务') ??
          _need(_seatId, '目标编制') ??
          _need(_levelId, '目标职级');
      if (missing != null) {
        AppToast.show(context: context, title: missing);
        return;
      }
      setState(() => _saving = true);
      try {
        await _api.transferEmployeeAssign(
          oldPositionId: _oldPositionId!.trim(),
          newPositionId: _seatId!.trim(),
          newPostSeqLevelId: _levelId!.trim(),
        );
        if (!mounted) return;
        AppToast.show(context: context, title: '调岗成功');
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        AppToast.show(context: context, title: e.toString());
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.name?.trim() ?? '';
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: const Text('调岗'),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 520),
        onClose: _saving ? null : () => Navigator.of(context).pop(false),
        content: _loading
            ? const SizedBox(
                    height: 220,
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  )
            : _loadError != null
                ? SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: _kDanger),
                          ),
                          const SizedBox(height: 12),
                          HyperButton.outlined(
                            onPressed: _loadOptions,
                            label: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  )
            : Column(
                      children: [
                        _Field(
                          label: '员工',
                          child: Container(
                            height: 34,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _kReadonly,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: _kTitle),
                            ),
                          ),
                        ),
                        _Field(
                          label: '原编制',
                          required: true,
                          child: AppSelectFormField<String>(
                            name: 'oldPositionId',
                            hintText: '请选择原编制',
                            options: [
                              for (final t in _originTitles)
                                AppOption(
                                  value: t.positionId!.trim(),
                                  label: _originLabel(t),
                                ),
                            ],
                            initialValue: _oldPositionId,
                            validator: (_) => _need(_oldPositionId, '原编制'),
                            onChanged: (value) {
                              setState(() {
                                _oldPositionId = value;
                                if (_seatId?.trim() == value?.trim()) {
                                  _seatId = null;
                                  _levelId = null;
                                }
                              });
                            },
                          ),
                        ),
                        _Field(
                          label: '目标部门',
                          required: true,
                          child: FormField<String>(
                            initialValue: _deptId,
                            validator: (_) => _need(_deptId, '目标部门'),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            builder: (field) {
                              final selected = _deptName(_deptId);
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: open
                                                  ? _kGreen
                                                  : (field.hasError ? _kDanger : _kBorder),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selected ?? '请选择目标部门',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: selected == null ? _kMuted : _kTitle,
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
                                                  _seatId = null;
                                                  _levelId = null;
                                                  _deptNodes = _setSelected(_deptNodes, id);
                                                });
                                                actions.close();
                                              },
                                              child: Text(
                                                _deptName(id) ?? id,
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
                                        style: const TextStyle(fontSize: 12, color: _kDanger),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        _Field(
                          label: '目标职务',
                          required: true,
                          child: AppSelectFormField<String>(
                            key: ValueKey('post-$_deptId'),
                            name: 'sysPostId',
                            hintText: _deptId == null ? '请先选择部门' : '请选择目标职务',
                            enabled: _deptId != null,
                            options: [
                              for (final p in _postsOfDept)
                                AppOption(value: p.id!.trim(), label: p.name!.trim()),
                            ],
                            initialValue: _postId,
                            validator: (_) => _need(_postId, '目标职务'),
                            onChanged: (value) {
                              setState(() {
                                _postId = value;
                                _seatId = null;
                                _levelId = null;
                              });
                            },
                          ),
                        ),
                        _Field(
                          label: '目标编制',
                          required: true,
                          child: AppSelectFormField<String>(
                            key: ValueKey('seat-$_deptId-$_postId-$_oldPositionId'),
                            name: 'newPositionId',
                            hintText: _postId == null ? '请先选择职务' : '请选择目标编制',
                            enabled: _postId != null,
                            options: [
                              for (final p in _seatsOfPost)
                                AppOption(value: p.id!.trim(), label: _seatLabel(p)),
                            ],
                            initialValue: _seatId,
                            validator: (_) => _need(_seatId, '目标编制'),
                            onChanged: (value) {
                              setState(() {
                                _seatId = value;
                                _levelId = null;
                              });
                            },
                          ),
                        ),
                        _Field(
                          label: '目标职级',
                          required: true,
                          child: AppSelectFormField<String>(
                            key: ValueKey('level-$_seatId'),
                            name: 'newPostSeqLevelId',
                            hintText: _seatId == null ? '请先选择编制' : '请选择目标职级',
                            enabled: _seatId != null,
                            popupMinWidth: 480,
                            maxPopupHeight: 480,
                            optionConfig: AppOptionConfig<String>(
                              optionBuilder: (context, option, state) =>
                                  Text(option.label),
                            ),
                            options: [
                              for (final l in _levels)
                                if (l.id?.trim().isNotEmpty == true)
                                  AppOption(
                                    value: l.id!.trim(),
                                    label: _levelLabel(l),
                                  ),
                            ],
                            initialValue: _levelId,
                            validator: (_) => _need(_levelId, '目标职级'),
                            onChanged: (value) => _levelId = value,
                          ),
                        ),
                      ],
                    ),
        actions: [
          HyperButton.outlined(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            label: const Text('取消'),
          ),
          HyperButton.filled(
            loading: _saving,
            onPressed: (_saving || _loading || _loadError != null) ? null : _submit,
            label: const Text('确定'),
          ),
        ],
      ),
    );
  }
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
            width: 72,
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
