import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../models/hrm_employee_profile.dart';
import '../../../../services/hrm_api.dart';

const _leaveTypeOptions = <AppOption<String>>[
  AppOption(value: 'VOLUNTARY', label: '主动离职'),
  AppOption(value: 'INVOLUNTARY', label: '被动离职'),
  AppOption(value: 'OTHER', label: '其他'),
];

const _leaveTypes = {'VOLUNTARY', 'INVOLUNTARY', 'OTHER'};

/// 待离职 · 确认离职。
Future<bool> showLeaveConfirmDialog(
  BuildContext context,
  HrmEmployeeProfile row,
) async {
  final id = row.id?.trim() ?? '';
  if (id.isEmpty) {
    AppToast.show(context: context, title: '缺少员工 ID');
    return false;
  }
  final ok = await showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
      child: _ConfirmDialog(
        employeeId: id,
        name: row.name?.trim() ?? '',
        leaveDate: row.leaveDate,
        leaveType: row.leaveType,
        leaveRemark: row.leaveRemark,
        onClose: (saved) => Navigator.of(dialogContext).pop(saved),
      ),
    ),
  );
  return ok == true;
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.employeeId,
    required this.name,
    required this.leaveDate,
    required this.leaveType,
    required this.leaveRemark,
    required this.onClose,
  });

  final String employeeId;
  final String name;
  final String? leaveDate;
  final String? leaveType;
  final String? leaveRemark;
  final void Function(bool saved) onClose;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final _api = HrmApi();
  final _form = AppFormController();
  late final TextEditingController _remarkCtrl;
  var _saving = false;
  var _remarkLen = 0;

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController(text: widget.leaveRemark?.trim() ?? '');
    _remarkLen = _remarkCtrl.text.characters.length;
    _remarkCtrl.addListener(() {
      final len = _remarkCtrl.text.characters.length;
      if (len != _remarkLen) setState(() => _remarkLen = len);
    });
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    _form.dispose();
    super.dispose();
  }

  DateTime get _initialDate {
    final raw = widget.leaveDate?.trim() ?? '';
    final parsed = raw.length >= 10 ? DateTime.tryParse(raw.substring(0, 10)) : null;
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String? get _initialType {
    final type = widget.leaveType?.trim().toUpperCase();
    if (type == null || !_leaveTypes.contains(type)) return null;
    return type;
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final date = values['leaveDate'];
      final type = values['leaveType'];
      if (date is! DateTime || type is! String || type.trim().isEmpty) return;
      final remark = _remarkCtrl.text.trim();
      if (remark.length > 100) return;
      setState(() => _saving = true);
      try {
        await _api.confirmEmployeeLeave(
          id: widget.employeeId,
          leaveDate: _fmt(date),
          leaveType: type.trim(),
          leaveRemark: remark,
        );
        if (!mounted) return;
        AppToast.show(context: context, title: '已确认离职');
        widget.onClose(true);
      } catch (e) {
        if (mounted) AppToast.show(context: context, title: e.toString());
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.name.isEmpty ? '确认离职' : '确认离职 - ${widget.name}';
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: Text(title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 480),
        onClose: _saving ? null : () => widget.onClose(false),
        content: AppFieldScope.horizontal(
          labelWidth: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              AppDatePickerFormField(
                name: 'leaveDate',
                label: '离职日期',
                required: true,
                hintText: '请选择离职日期',
                initialValue: _initialDate,
                validator: (v) => v == null ? '请选择离职日期' : null,
              ),
              AppSelectFormField<String>(
                name: 'leaveType',
                label: '离职类型',
                required: true,
                hintText: '请选择离职类型',
                options: _leaveTypeOptions,
                initialValue: _initialType,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请选择离职类型' : null,
              ),
              AppTextAreaFormField(
                name: 'leaveRemark',
                label: '离职备注',
                hintText: '选填',
                controller: _remarkCtrl,
                minHeight: 88,
                description: '$_remarkLen / 100',
                validator: (v) {
                  final text = (v ?? _remarkCtrl.text).trim();
                  if (text.length > 100) return '离职备注不能超过 100 个字符';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          HyperButton.outlined(
            onPressed: _saving ? null : () => widget.onClose(false),
            label: const Text('取消'),
          ),
          HyperButton.filled(
            loading: _saving,
            onPressed: _saving ? null : _submit,
            label: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

String _fmt(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}
