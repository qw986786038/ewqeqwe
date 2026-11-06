import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_employee_profile.dart';
import '../../employee_archive/employee_archive_controller.dart';
import '../regularization_controller.dart';

const _kTitle = Color(0xFF1D2129);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFF53F3F);
const _kReadonly = Color(0xFFF7F8FA);

void showRegularizeDialog(BuildContext context, HrmEmployeeProfile row) {
  final ctrl = context.lx.find<RegularizationController>();
  showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => LxScope(
      bindings: (container) {
        container.putInstance<RegularizationController>(ctrl, owned: false);
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
        child: _RegularizeDialog(row: row),
      ),
    ),
  );
}

class _RegularizeDialog extends StatefulWidget {
  const _RegularizeDialog({required this.row});

  final HrmEmployeeProfile row;

  @override
  State<_RegularizeDialog> createState() => _RegularizeDialogState();
}

class _RegularizeDialogState extends State<_RegularizeDialog> {
  final _form = AppFormController();
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.row.name?.trim();
    final title = (name == null || name.isEmpty) ? '确认转正' : '确认转正 - $name';
    final hire = EmployeeArchiveController.dateText(widget.row.hireDate);
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: Text(title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 480),
        onClose: _saving ? null : () => Navigator.of(context).pop(),
        content: Column(
          children: [
            _ReadonlyField(label: '姓名', value: name ?? ''),
            _ReadonlyField(
              label: '入职日期',
              value: hire == '-' ? '' : hire,
            ),
            _Field(
              label: '转正日期',
              required: true,
              child: AppDatePickerFormField(
                name: 'regularizationDate',
                hintText: '请选择转正日期',
                initialValue: _parseDate(widget.row.regularizationDate),
                validator: (v) => v == null ? '请选择转正日期' : null,
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
            onPressed: _saving ? null : _submit,
            label: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final c = context.lx.find<RegularizationController>();
    await _form.submit((values) async {
      final date = values['regularizationDate'];
      if (date is! DateTime) return;
      setState(() => _saving = true);
      try {
        await c.regularize(widget.row, _fmt(date));
        if (!mounted) return;
        AppToast.show(context: context, title: '已确认转正');
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        AppToast.show(context: context, title: e.toString());
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Field(
      label: label,
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
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: _kTitle),
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 16),
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
