import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../seat_controller.dart';

/// 打开「新增编制」弹窗；成功后刷新列表。
Future<void> showSeatAddDialog(BuildContext context) {
  return _showSeatFormDialog(context, editing: null);
}

/// 打开「修改编制」弹窗；成功后刷新列表。
Future<void> showSeatEditDialog(BuildContext context, HrmPosition seat) {
  return _showSeatFormDialog(context, editing: seat);
}

Future<void> _showSeatFormDialog(
  BuildContext context, {
  required HrmPosition? editing,
}) {
  final hostContext = context;
  final c = context.lx.find<SeatController>();
  final isEdit = editing != null;
  final editId = editing?.id?.trim();
  if (isEdit && (editId == null || editId.isEmpty)) {
    AppToast.show(context: context, title: '编制 id 无效');
    return Future.value();
  }

  return showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _SeatFormDialog(
      title: isEdit ? '修改编制' : '新增编制',
      depts: List<HrmDept>.from(c.depts),
      posts: List<HrmPost>.from(c.posts),
      positions: List<HrmPosition>.from(c.allPositions),
      excludePositionId: editId,
      initialDeptId: editing?.sysDeptId?.trim(),
      initialPostId: editing?.postId?.trim(),
      initialType: editing?.type?.trim().toUpperCase() ?? 'REGULAR',
      initialReportId: editing?.reportPositionId?.trim(),
      initialDottedId: editing?.dottedPositionId?.trim(),
      positionLabelOf: c.positionOptionLabel,
      onClose: () => Navigator.of(dialogContext).pop(),
      onSubmit: (payload) async {
        if (isEdit) {
          await c.updateSeat(
            id: editId!,
            sysDeptId: payload.sysDeptId,
            postId: payload.postId,
            type: payload.type,
            reportPositionId: payload.reportPositionId,
            dottedPositionId: payload.dottedPositionId,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '修改编制成功');
          }
        } else {
          await c.createSeat(
            sysDeptId: payload.sysDeptId,
            postId: payload.postId,
            type: payload.type,
            reportPositionId: payload.reportPositionId,
            dottedPositionId: payload.dottedPositionId,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '新增编制成功');
          }
        }
      },
    ),
  );
}

class _SeatFormPayload {
  const _SeatFormPayload({
    required this.sysDeptId,
    required this.postId,
    required this.type,
    this.reportPositionId,
    this.dottedPositionId,
  });

  final String sysDeptId;
  final String postId;
  final String type;
  final String? reportPositionId;
  final String? dottedPositionId;
}

const _kTypeOptions = <AppOption<String>>[
  AppOption(value: 'REGULAR', label: '正式'),
  AppOption(value: 'RESERVE', label: '储备'),
  AppOption(value: 'OUTSOURCE', label: '外包'),
];

class _SeatFormDialog extends StatefulWidget {
  const _SeatFormDialog({
    required this.title,
    required this.depts,
    required this.posts,
    required this.positions,
    required this.excludePositionId,
    required this.initialDeptId,
    required this.initialPostId,
    required this.initialType,
    required this.initialReportId,
    required this.initialDottedId,
    required this.positionLabelOf,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final List<HrmDept> depts;
  final List<HrmPost> posts;
  final List<HrmPosition> positions;
  final String? excludePositionId;
  final String? initialDeptId;
  final String? initialPostId;
  final String initialType;
  final String? initialReportId;
  final String? initialDottedId;
  final String Function(HrmPosition position) positionLabelOf;
  final VoidCallback onClose;
  final Future<void> Function(_SeatFormPayload payload) onSubmit;

  @override
  State<_SeatFormDialog> createState() => _SeatFormDialogState();
}

class _SeatFormDialogState extends State<_SeatFormDialog> {
  final _form = AppFormController();
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  List<AppCascadeOption<String>> get _deptTree {
    final byId = <String, HrmDept>{};
    for (final dept in widget.depts) {
      final id = dept.deptId?.trim();
      final name = dept.deptName?.trim();
      if (id == null || id.isEmpty || name == null || name.isEmpty) continue;
      byId[id] = dept;
    }
    final childrenOf = <String, List<HrmDept>>{};
    final roots = <HrmDept>[];
    for (final dept in byId.values) {
      final parentId = dept.parentId?.trim();
      if (parentId == null ||
          parentId.isEmpty ||
          parentId == '0' ||
          !byId.containsKey(parentId)) {
        roots.add(dept);
      } else {
        childrenOf.putIfAbsent(parentId, () => <HrmDept>[]).add(dept);
      }
    }
    int byOrder(HrmDept a, HrmDept b) =>
        (a.orderNum ?? 0).compareTo(b.orderNum ?? 0);
    roots.sort(byOrder);
    for (final children in childrenOf.values) {
      children.sort(byOrder);
    }

    AppCascadeOption<String> toOption(HrmDept dept) {
      final id = dept.deptId!.trim();
      return AppCascadeOption(
        value: id,
        label: dept.deptName!.trim(),
        children: [
          for (final child in childrenOf[id] ?? const <HrmDept>[])
            toOption(child),
        ],
      );
    }

    return [for (final root in roots) toOption(root)];
  }

  /// 从根到 [id] 的路径，供级联回显。
  List<String> _deptPath(String? id) {
    final target = id?.trim();
    if (target == null || target.isEmpty) return const [];
    final byId = <String, HrmDept>{
      for (final dept in widget.depts)
        if (dept.deptId?.trim().isNotEmpty == true) dept.deptId!.trim(): dept,
    };
    if (!byId.containsKey(target)) return const [];
    final path = <String>[];
    var current = target;
    final seen = <String>{};
    while (byId.containsKey(current) && seen.add(current)) {
      path.add(current);
      final parentId = byId[current]!.parentId?.trim();
      if (parentId == null ||
          parentId.isEmpty ||
          parentId == '0' ||
          !byId.containsKey(parentId)) {
        break;
      }
      current = parentId;
    }
    return path.reversed.toList();
  }

  List<AppOption<String>> get _postOptions => [
        for (final p in widget.posts)
          if (p.id != null &&
              p.id!.trim().isNotEmpty &&
              p.name?.trim().isNotEmpty == true)
            AppOption(value: p.id!.trim(), label: p.name!.trim()),
      ];

  List<AppOption<String>> get _positionOptions {
    final exclude = widget.excludePositionId;
    return [
      for (final p in widget.positions)
        if (p.id != null &&
            p.id!.trim().isNotEmpty &&
            p.id!.trim() != exclude)
          AppOption(
            value: p.id!.trim(),
            label: widget.positionLabelOf(p),
          ),
    ];
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final deptId = (values['sysDeptId'] as String?)?.trim() ?? '';
      final postId = (values['postId'] as String?)?.trim() ?? '';
      final type = (values['type'] as String?)?.trim().toUpperCase() ?? '';
      final report = (values['reportPositionId'] as String?)?.trim();
      final dotted = (values['dottedPositionId'] as String?)?.trim();
      if (deptId.isEmpty || postId.isEmpty || type.isEmpty) return;

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _SeatFormPayload(
            sysDeptId: deptId,
            postId: postId,
            type: type,
            reportPositionId:
                report == null || report.isEmpty ? null : report,
            dottedPositionId:
                dotted == null || dotted.isEmpty ? null : dotted,
          ),
        );
        if (mounted) widget.onClose();
      } catch (e) {
        if (mounted) {
          AppToast.show(context: context, title: e.toString());
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final typeInitial = _kTypeOptions.any((o) => o.value == widget.initialType)
        ? widget.initialType
        : 'REGULAR';
    final reportOpts = _positionOptions;
    final reportInitial =
        widget.initialReportId != null &&
                reportOpts.any((o) => o.value == widget.initialReportId)
            ? widget.initialReportId
            : null;
    final dottedInitial =
        widget.initialDottedId != null &&
                reportOpts.any((o) => o.value == widget.initialDottedId)
            ? widget.initialDottedId
            : null;

    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: Text(widget.title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 480),
        onClose: _saving ? null : widget.onClose,
        content: AppFieldScope.horizontal(
          labelWidth: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              FormField<String>(
                initialValue: widget.initialDeptId,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请选择部门' : null,
                builder: (state) => AppFormFieldBinding<String>(
                  name: 'sysDeptId',
                  value: state.value,
                  builder: (context, asyncError) => AppField(
                    label: '所属部门',
                    required: true,
                    errorText: state.errorText ?? asyncError,
                    child: AppCascadeSelect<String>(
                      options: _deptTree,
                      value: _deptPath(state.value),
                      hintText: '请选择部门',
                      changeOnSelect: true,
                      onChanged: (path) {
                        state.didChange(
                          path.isEmpty ? null : path.last,
                        );
                      },
                    ),
                  ),
                ),
              ),
              AppSelectFormField<String>(
                name: 'postId',
                label: '所属职务',
                required: true,
                hintText: '请选择职务',
                options: _postOptions,
                initialValue: widget.initialPostId,
                validator: (v) =>
                    (v == null || v.isEmpty) ? '请选择职务' : null,
              ),
              AppRadioGroupFormField<String>(
                name: 'type',
                label: '编制类型',
                required: true,
                valueDirection: Axis.horizontal,
                spacing: 24,
                initialValue: typeInitial,
                options: _kTypeOptions,
                validator: (v) => (v != 'REGULAR' &&
                        v != 'RESERVE' &&
                        v != 'OUTSOURCE')
                    ? '请选择编制类型'
                    : null,
              ),
              AppSelectFormField<String>(
                name: 'reportPositionId',
                label: '行政汇报编制',
                hintText: '请选择行政汇报编制',
                options: reportOpts,
                initialValue: reportInitial,
                clearable: true,
              ),
              AppSelectFormField<String>(
                name: 'dottedPositionId',
                label: '虚线汇报编制',
                hintText: '请选择虚线汇报编制',
                options: reportOpts,
                initialValue: dottedInitial,
                clearable: true,
              ),
            ],
          ),
        ),
        actions: [
          HyperButton.outlined(
            onPressed: _saving ? null : widget.onClose,
            label: const Text('取消'),
          ),
          HyperButton.filled(
            loading: _saving,
            onPressed: _saving
                ? null
                : () async {
                    await _submit();
                  },
            label: Text(_saving ? '提交中…' : '确定'),
          ),
        ],
      ),
    );
  }
}
