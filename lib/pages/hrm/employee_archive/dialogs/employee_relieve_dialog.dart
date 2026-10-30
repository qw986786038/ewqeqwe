import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee_assign.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../services/hrm_api.dart';

const _kEndTypeOptions = <AppOption<String>>[
  AppOption(value: 'TRANSFER_OUT', label: '调出'),
  AppOption(value: 'REGULARIZATION_OUT', label: '转正转出'),
  AppOption(value: 'PROMOTION_OUT', label: '晋升转出'),
  AppOption(value: 'CONCURRENT_END', label: '兼任结束'),
  AppOption(value: 'RESIGN', label: '离职'),
];

/// 人事档案 · 卸任弹窗。打开时拉在任记录；提交走 relieve。
Future<bool> showEmployeeRelieveDialog(
  BuildContext context, {
  required HrmEmployeeProfile employee,
}) {
  final userId = employee.userId;
  if (userId == null) {
    AppToast.show(context: context, title: '缺少用户 ID');
    return Future.value(false);
  }
  final fallbackName = () {
    final n = employee.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final no = employee.no?.trim();
    if (no != null && no.isNotEmpty) return no;
    return '用户 $userId';
  }();

  return AppDialog.show<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _EmployeeRelieveDialog(
      employeeUserId: userId,
      fallbackName: fallbackName,
      onClose: (ok) => AppOverlay.close<bool>(dialogContext, ok),
    ),
  ).future.then((v) => v == true);
}

class _EmployeeRelieveDialog extends StatefulWidget {
  const _EmployeeRelieveDialog({
    required this.employeeUserId,
    required this.fallbackName,
    required this.onClose,
  });

  final int employeeUserId;
  final String fallbackName;
  final void Function(bool ok) onClose;

  @override
  State<_EmployeeRelieveDialog> createState() => _EmployeeRelieveDialogState();
}

class _EmployeeRelieveDialogState extends State<_EmployeeRelieveDialog> {
  final _api = HrmApi();
  final _form = AppFormController();

  var _loading = true;
  var _saving = false;
  String? _loadError;

  List<HrmEmployeeAssign> _assigns = const [];
  final Map<String, String> _deptNameById = {};
  final Map<String, HrmPosition> _positionById = {};
  final Map<String, String> _postNameById = {};
  final Map<String, String> _levelCodeById = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchOnDutyAssigns(),
        _api.fetchPositions(),
        _api.fetchPostSeqLevels(),
        _api.fetchPosts(),
        _api.fetchDepts(),
      ]);
      final onDuty = results[0] as List<HrmEmployeeAssign>;
      final positions = results[1] as List<HrmPosition>;
      final levels = results[2] as List<HrmPostSeqLevel>;
      final posts = results[3] as List<HrmPost>;
      final depts = results[4] as List<HrmDept>;

      final mine = [
        for (final a in onDuty)
          if (a.employeeUserId == widget.employeeUserId &&
              a.id?.trim().isNotEmpty == true)
            a,
      ];

      if (!mounted) return;
      setState(() {
        _assigns = mine;
        _deptNameById
          ..clear()
          ..addEntries([
            for (final d in depts)
              if (d.deptId?.trim().isNotEmpty == true &&
                  d.deptName?.trim().isNotEmpty == true)
                MapEntry(d.deptId!.trim(), d.deptName!.trim()),
          ]);
        _positionById
          ..clear()
          ..addEntries([
            for (final p in positions)
              if (p.id?.trim().isNotEmpty == true)
                MapEntry(p.id!.trim(), p),
          ]);
        _postNameById
          ..clear()
          ..addEntries([
            for (final p in posts)
              if (p.id?.trim().isNotEmpty == true &&
                  p.name?.trim().isNotEmpty == true)
                MapEntry(p.id!.trim(), p.name!.trim()),
          ]);
        _levelCodeById
          ..clear()
          ..addEntries([
            for (final l in levels)
              if (l.id?.trim().isNotEmpty == true &&
                  l.code?.trim().isNotEmpty == true)
                MapEntry(l.id!.trim(), l.code!.trim()),
          ]);
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

  String _assignLabel(HrmEmployeeAssign a) {
    final pos = _positionById[a.positionId?.trim() ?? ''];
    final deptId = pos?.sysDeptId?.trim();
    final postId = pos?.postId?.trim();
    final dept = (pos?.deptName?.trim().isNotEmpty == true)
        ? pos!.deptName!.trim()
        : (deptId == null ? '' : (_deptNameById[deptId] ?? ''));
    final post = (pos?.postName?.trim().isNotEmpty == true)
        ? pos!.postName!.trim()
        : (postId == null ? '' : (_postNameById[postId] ?? ''));
    final level = _levelCodeById[a.postSeqLevelId?.trim() ?? ''] ?? '';
    final parts = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
      if (level.isNotEmpty) level,
    ];
    if (parts.isNotEmpty) return parts.join(' / ');
    return a.id?.trim() ?? '-';
  }

  List<AppOption<String>> get _assignOptions => [
        for (final a in _assigns)
          AppOption(
            value: a.id!.trim(),
            label: _assignLabel(a),
          ),
      ];

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _submit() async {
    if (_saving || _loading) return;
    await _form.submit((values) async {
      final assignId = (values['assignId'] as String?)?.trim() ?? '';
      final endType = (values['endType'] as String?)?.trim() ?? '';
      final end = values['endDate'];
      if (assignId.isEmpty || endType.isEmpty || end is! DateTime) return;

      final idInt = int.tryParse(assignId);
      if (idInt == null) {
        AppToast.show(context: context, title: '在任记录无效');
        return;
      }

      setState(() => _saving = true);
      try {
        await _api.relieveEmployeeAssign(
          id: idInt,
          endDate: _fmtDate(end),
          endType: endType,
        );
        if (!mounted) return;
        AppToast.show(context: context, title: '卸任成功');
        widget.onClose(true);
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
    final assignOpts = _assignOptions;
    final initialAssign = assignOpts.length == 1 ? assignOpts.first.value : null;

    return AppForm(
      controller: _form,
      child: AppFormDialog(
        title: const Text('卸任'),
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 480),
        content: _loading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            : _loadError != null
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF4D4F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppButton.outline(
                            onPressed: _loadOptions,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  )
                : AppFieldScope.horizontal(
                    labelWidth: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        AppTextFormField(
                          name: 'employeeName',
                          label: '员工',
                          readOnly: true,
                          enabled: false,
                          initialValue: widget.fallbackName,
                        ),
                        if (assignOpts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 96),
                            child: Text(
                              '该员工暂无在任记录',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF86909C),
                              ),
                            ),
                          )
                        else
                          AppSelectFormField<String>(
                            name: 'assignId',
                            label: '在任记录',
                            required: true,
                            hintText: '请选择在任记录',
                            options: assignOpts,
                            initialValue: initialAssign,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? '请选择在任记录' : null,
                          ),
                        AppSelectFormField<String>(
                          name: 'endType',
                          label: '结束类型',
                          required: true,
                          hintText: '请选择结束类型',
                          options: _kEndTypeOptions,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '请选择结束类型' : null,
                        ),
                        AppDateTimePickerFormField(
                          name: 'endDate',
                          label: '卸任时间',
                          required: true,
                          validator: (v) => v == null ? '请选择卸任时间' : null,
                        ),
                      ],
                    ),
                  ),
        actions: [
          AppButton.outline(
            onPressed: _saving ? null : () => widget.onClose(false),
            child: const Text('取消'),
          ),
          AppButton.primary(
            loading: _saving,
            loadingLabel: '提交中…',
            onPressed: (_saving ||
                    _loading ||
                    _loadError != null ||
                    _assigns.isEmpty)
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
