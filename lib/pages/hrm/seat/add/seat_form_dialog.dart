import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../seat_controller.dart';

/// 打开「新增席位」弹窗；成功后刷新列表。
Future<void> showSeatAddDialog(BuildContext context) {
  return _showSeatFormDialog(context, editing: null);
}

/// 打开「修改席位」弹窗；成功后刷新列表。
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
    AppToast.show(context: context, title: '席位 id 无效');
    return Future.value();
  }

  return AppDialog.show<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _SeatFormDialog(
      title: isEdit ? '修改席位' : '新增席位',
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
      onClose: () => AppOverlay.close<void>(dialogContext),
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
            AppToast.show(context: hostContext, title: '修改席位成功');
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
            AppToast.show(context: hostContext, title: '新增席位成功');
          }
        }
      },
    ),
  ).future;
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

  List<AppOption<String>> get _deptOptions => [
        for (final d in widget.depts)
          if (d.deptId != null &&
              d.deptId!.trim().isNotEmpty &&
              d.deptName?.trim().isNotEmpty == true)
            AppOption(
              value: d.deptId!.trim(),
              label: d.deptName!.trim(),
            ),
      ];

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
      child: AppFormDialog(
        title: Text(widget.title),
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 480),
        content: AppFieldScope.horizontal(
          labelWidth: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              AppSelectFormField<String>(
                name: 'sysDeptId',
                label: '所属部门',
                required: true,
                hintText: '请选择部门',
                options: _deptOptions,
                initialValue: widget.initialDeptId,
                validator: (v) =>
                    (v == null || v.isEmpty) ? '请选择部门' : null,
              ),
              AppSelectFormField<String>(
                name: 'postId',
                label: '所属岗位',
                required: true,
                hintText: '请选择岗位',
                options: _postOptions,
                initialValue: widget.initialPostId,
                validator: (v) =>
                    (v == null || v.isEmpty) ? '请选择岗位' : null,
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
                label: '行政汇报席位',
                hintText: '请选择行政汇报席位',
                options: reportOpts,
                initialValue: reportInitial,
                clearable: true,
              ),
              AppSelectFormField<String>(
                name: 'dottedPositionId',
                label: '虚线汇报席位',
                hintText: '请选择虚线汇报席位',
                options: reportOpts,
                initialValue: dottedInitial,
                clearable: true,
              ),
            ],
          ),
        ),
        actions: [
          AppButton.outline(
            onPressed: _saving ? null : widget.onClose,
            child: const Text('取消'),
          ),
          AppButton.primary(
            loading: _saving,
            loadingLabel: '提交中…',
            onPressed: _saving
                ? null
                : () async {
                    await _submit();
                  },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
