import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_office_location.dart';
import '../workplace_controller.dart';

/// 打开「新增办公地」弹窗；成功后刷新列表。
Future<void> showWorkplaceAddDialog(BuildContext context) {
  return _showWorkplaceFormDialog(context, editing: null);
}

/// 打开「修改办公地」弹窗；成功后刷新列表。
Future<void> showWorkplaceEditDialog(
  BuildContext context,
  HrmOfficeLocation location,
) {
  return _showWorkplaceFormDialog(context, editing: location);
}

Future<void> _showWorkplaceFormDialog(
  BuildContext context, {
  required HrmOfficeLocation? editing,
}) {
  final hostContext = context;
  final c = context.lx.find<WorkplaceController>();
  final isEdit = editing != null;
  final editId = editing?.id?.trim();
  if (isEdit && (editId == null || editId.isEmpty)) {
    AppToast.show(context: context, title: '办公地 id 无效');
    return Future.value();
  }

  return showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _WorkplaceFormDialog(
      title: isEdit ? '修改办公地' : '新增办公地',
      initialName: editing?.name?.trim() ?? '',
      initialAddress: editing?.address?.trim() ?? '',
      initialOrderNum: editing?.orderNum ?? (isEdit ? 0 : c.nextOrderNum),
      onClose: () => Navigator.of(dialogContext).pop(),
      onSubmit: (payload) async {
        if (isEdit) {
          await c.updateLocation(
            id: editId!,
            name: payload.name,
            address: payload.address,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '修改办公地成功');
          }
        } else {
          await c.createLocation(
            name: payload.name,
            address: payload.address,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '新增办公地成功');
          }
        }
      },
    ),
  );
}

class _WorkplaceFormPayload {
  const _WorkplaceFormPayload({
    required this.name,
    required this.address,
    required this.orderNum,
  });

  final String name;
  final String address;
  final int orderNum;
}

class _WorkplaceFormDialog extends StatefulWidget {
  const _WorkplaceFormDialog({
    required this.title,
    required this.initialName,
    required this.initialAddress,
    required this.initialOrderNum,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final String initialName;
  final String initialAddress;
  final int initialOrderNum;
  final VoidCallback onClose;
  final Future<void> Function(_WorkplaceFormPayload payload) onSubmit;

  @override
  State<_WorkplaceFormDialog> createState() => _WorkplaceFormDialogState();
}

class _WorkplaceFormDialogState extends State<_WorkplaceFormDialog> {
  final _form = AppFormController();
  late final TextEditingController _addressCtrl;
  var _saving = false;
  var _addressLen = 0;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.initialAddress);
    _addressLen = widget.initialAddress.length;
    _addressCtrl.addListener(() {
      final len = _addressCtrl.text.length;
      if (len != _addressLen) {
        setState(() => _addressLen = len);
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final name = (values['name'] as String?)?.trim() ?? '';
      final address = _addressCtrl.text.trim();
      final orderRaw = values['orderNum'];
      final orderNum = orderRaw is int
          ? orderRaw
          : int.tryParse('$orderRaw') ?? 0;
      if (name.isEmpty || address.isEmpty) return;

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _WorkplaceFormPayload(
            name: name,
            address: address,
            orderNum: orderNum,
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
              AppTextFormField(
                name: 'name',
                label: '办公地址名称',
                required: true,
                hintText: '请输入办公地地址名称',
                maxLength: 30,
                initialValue:
                    widget.initialName.isEmpty ? null : widget.initialName,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '请输入办公地址名称';
                  if (s.length > 30) return '不能超过 30 字';
                  return null;
                },
              ),
              AppTextAreaFormField(
                name: 'address',
                label: '详细地址',
                required: true,
                hintText: '请输入详细地址',
                controller: _addressCtrl,
                minHeight: 88,
                description: '$_addressLen / 100',
                validator: (v) {
                  final s = (v ?? _addressCtrl.text).trim();
                  if (s.isEmpty) return '请输入详细地址';
                  if (s.length > 100) return '不能超过 100 字';
                  return null;
                },
              ),
              AppNumberInputFormField(
                name: 'orderNum',
                label: '显示排序',
                required: true,
                min: 0,
                max: 99999,
                initialValue: widget.initialOrderNum,
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
