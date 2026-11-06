import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_employee_profile.dart';
import '../../../../services/hrm_api.dart';
import '../detail/employee_detail_controller.dart';
import '../employee_archive_controller.dart';

const _leaveTypeOptions = <AppOption<String>>[
  AppOption(value: 'VOLUNTARY', label: '主动离职'),
  AppOption(value: 'INVOLUNTARY', label: '被动离职'),
  AppOption(value: 'OTHER', label: '其他'),
];

/// 花名册 / 档案详情 · 办理离职。成功后刷新当前页数据。
Future<void> showEmployeeLeaveDialog(
  BuildContext context,
  HrmEmployeeProfile row,
) async {
  final id = row.id?.trim() ?? '';
  if (id.isEmpty) {
    AppToast.show(context: context, title: '缺少员工 ID');
    return;
  }
  final ok = await showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
      child: _LeaveDialog(
        employeeId: id,
        name: row.name?.trim() ?? '',
        onClose: (saved) => Navigator.of(dialogContext).pop(saved),
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  if (context.lx.contains<EmployeeDetailController>()) {
    await context.lx.find<EmployeeDetailController>().load();
  }
  if (!context.mounted) return;
  if (context.lx.contains<EmployeeArchiveController>()) {
    await context.lx.find<EmployeeArchiveController>().refreshAll();
  }
}

class _LeaveDialog extends StatefulWidget {
  const _LeaveDialog({
    required this.employeeId,
    required this.name,
    required this.onClose,
  });

  final String employeeId;
  final String name;
  final void Function(bool saved) onClose;

  @override
  State<_LeaveDialog> createState() => _LeaveDialogState();
}

class _LeaveDialogState extends State<_LeaveDialog> {
  final _api = HrmApi();
  final _form = AppFormController();
  late final TextEditingController _remarkCtrl;
  var _saving = false;
  var _remarkLen = 0;

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController();
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
        await _api.applyEmployeeLeave(
          id: widget.employeeId,
          leaveDate: _fmt(date),
          leaveType: type.trim(),
          leaveRemark: remark,
        );
        if (!mounted) return;
        AppToast.show(context: context, title: '已提交离职申请');
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
    final now = DateTime.now();
    final title = widget.name.isEmpty ? '办理离职' : '办理离职 - ${widget.name}';
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
                initialValue: DateTime(now.year, now.month, now.day),
                validator: (v) => v == null ? '请选择离职日期' : null,
              ),
              AppSelectFormField<String>(
                name: 'leaveType',
                label: '离职类型',
                required: true,
                hintText: '请选择离职类型',
                options: _leaveTypeOptions,
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
