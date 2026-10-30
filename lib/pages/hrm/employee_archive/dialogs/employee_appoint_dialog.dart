import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../../models/hrm_dept.dart';
import '../../../../models/hrm_employee.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../../../../models/hrm_position.dart';
import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../../../../services/hrm_api.dart';

const _kStartTypeOptions = <AppOption<String>>[
  AppOption(value: 'HIRE', label: '入职'),
  AppOption(value: 'REGULARIZATION', label: '转正'),
  AppOption(value: 'PROMOTION', label: '晋级'),
];

/// 人事档案 · 任职弹窗。打开时拉通讯录 / 席位 / 职级；提交走 appoint。
Future<bool> showEmployeeAppointDialog(
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
    builder: (dialogContext) => _EmployeeAppointDialog(
      employeeUserId: userId,
      fallbackName: fallbackName,
      onClose: (ok) => AppOverlay.close<bool>(dialogContext, ok),
    ),
  ).future.then((v) => v == true);
}

class _EmployeeAppointDialog extends StatefulWidget {
  const _EmployeeAppointDialog({
    required this.employeeUserId,
    required this.fallbackName,
    required this.onClose,
  });

  final int employeeUserId;
  final String fallbackName;
  final void Function(bool ok) onClose;

  @override
  State<_EmployeeAppointDialog> createState() => _EmployeeAppointDialogState();
}

class _EmployeeAppointDialogState extends State<_EmployeeAppointDialog> {
  final _api = HrmApi();
  final _form = AppFormController();

  var _loading = true;
  var _saving = false;
  String? _loadError;
  String _employeeName = '';

  List<HrmPosition> _positions = const [];
  List<HrmPost> _posts = const [];
  List<HrmPostSeqLevel> _levels = const [];
  final Map<String, String> _deptNameById = {};

  @override
  void initState() {
    super.initState();
    _employeeName = widget.fallbackName;
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
        _api.fetchEmployees(includeChildren: true),
        _api.fetchPositions(),
        _api.fetchPostSeqLevels(),
        _api.fetchPosts(),
        _api.fetchDepts(),
      ]);
      final directory = results[0] as List<HrmEmployee>;
      final positions = results[1] as List<HrmPosition>;
      final levels = results[2] as List<HrmPostSeqLevel>;
      final posts = results[3] as List<HrmPost>;
      final depts = results[4] as List<HrmDept>;

      HrmEmployee? matched;
      for (final e in directory) {
        if (e.userId == widget.employeeUserId) {
          matched = e;
          break;
        }
      }
      final name = matched?.name?.trim();

      if (!mounted) return;
      setState(() {
        _positions = positions;
        _levels = levels;
        _posts = posts;
        _deptNameById
          ..clear()
          ..addEntries([
            for (final d in depts)
              if (d.deptId?.trim().isNotEmpty == true &&
                  d.deptName?.trim().isNotEmpty == true)
                MapEntry(d.deptId!.trim(), d.deptName!.trim()),
          ]);
        if (name != null && name.isNotEmpty) _employeeName = name;
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

  List<AppOption<String>> get _positionOptions {
    final postById = <String, String>{
      for (final p in _posts)
        if (p.id?.trim().isNotEmpty == true &&
            p.name?.trim().isNotEmpty == true)
          p.id!.trim(): p.name!.trim(),
    };
    return [
      for (final p in _positions)
        if (p.id?.trim().isNotEmpty == true)
          AppOption(
            value: p.id!.trim(),
            label: _positionLabel(p, postById),
          ),
    ];
  }

  String _positionLabel(HrmPosition p, Map<String, String> postById) {
    final deptId = p.sysDeptId?.trim();
    final postId = p.postId?.trim();
    final dept = (p.deptName?.trim().isNotEmpty == true)
        ? p.deptName!.trim()
        : (deptId == null ? '' : (_deptNameById[deptId] ?? ''));
    final post = (p.postName?.trim().isNotEmpty == true)
        ? p.postName!.trim()
        : (postId == null ? '' : (postById[postId] ?? ''));
    final type = switch (p.type?.trim().toUpperCase()) {
      'REGULAR' => '正式',
      'RESERVE' => '储备',
      'OUTSOURCE' => '外包',
      _ => p.type?.trim() ?? '',
    };
    final parts = [
      if (dept.isNotEmpty) dept,
      if (post.isNotEmpty) post,
      if (type.isNotEmpty) type,
    ];
    if (parts.isNotEmpty) return parts.join(' / ');
    return p.id?.trim() ?? '-';
  }

  List<AppOption<String>> get _levelOptions => [
        for (final l in _levels)
          if (l.id?.trim().isNotEmpty == true &&
              l.code?.trim().isNotEmpty == true)
            AppOption(value: l.id!.trim(), label: l.code!.trim()),
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
      final positionId = (values['positionId'] as String?)?.trim() ?? '';
      final levelId = (values['postSeqLevelId'] as String?)?.trim() ?? '';
      final startType = (values['startType'] as String?)?.trim() ?? '';
      final start = values['startDate'];
      if (positionId.isEmpty ||
          levelId.isEmpty ||
          startType.isEmpty ||
          start is! DateTime) {
        return;
      }
      final positionIdInt = int.tryParse(positionId);
      final levelIdInt = int.tryParse(levelId);
      if (positionIdInt == null || levelIdInt == null) {
        AppToast.show(context: context, title: '席位或职级无效');
        return;
      }

      setState(() => _saving = true);
      try {
        await _api.appointEmployee(
          employeeUserId: widget.employeeUserId,
          positionId: positionIdInt,
          postSeqLevelId: levelIdInt,
          startType: startType,
          startDate: _fmtDate(start),
          isPrimary: 1,
        );
        if (!mounted) return;
        AppToast.show(context: context, title: '任职成功');
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
    return AppForm(
      controller: _form,
      child: AppFormDialog(
        title: const Text('任职'),
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 480),
        content: _loading
            ? const SizedBox(
                height: 180,
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
                    height: 180,
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
                          initialValue: _employeeName,
                        ),
                        AppSelectFormField<String>(
                          name: 'positionId',
                          label: '席位',
                          required: true,
                          hintText: '请选择席位',
                          options: _positionOptions,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '请选择席位' : null,
                        ),
                        AppSelectFormField<String>(
                          name: 'postSeqLevelId',
                          label: '职级',
                          required: true,
                          hintText: '请选择职级',
                          options: _levelOptions,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '请选择职级' : null,
                        ),
                        AppSelectFormField<String>(
                          name: 'startType',
                          label: '开始类型',
                          required: true,
                          hintText: '请选择开始类型',
                          options: _kStartTypeOptions,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '请选择开始类型' : null,
                        ),
                        AppDateTimePickerFormField(
                          name: 'startDate',
                          label: '开始时间',
                          required: true,
                          validator: (v) => v == null ? '请选择开始时间' : null,
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
            onPressed: (_saving || _loading || _loadError != null)
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
