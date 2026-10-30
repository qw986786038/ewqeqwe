import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_post_seq.dart';
import '../post_seq_controller.dart';

const _kChannelOptions = <AppOption<String>>[
  AppOption(value: 'M', label: '管理岗'),
  AppOption(value: 'T', label: '技术岗'),
];

/// 打开「新增岗位序列」弹窗；成功后刷新列表。
Future<void> showPostSeqAddDialog(BuildContext context) {
  return _showPostSeqFormDialog(context, editing: null);
}

/// 打开「修改岗位序列」弹窗；成功后刷新列表。
Future<void> showPostSeqEditDialog(BuildContext context, HrmPostSeq seq) {
  return _showPostSeqFormDialog(context, editing: seq);
}

Future<void> _showPostSeqFormDialog(
  BuildContext context, {
  required HrmPostSeq? editing,
}) {
  final hostContext = context;
  final c = context.lx.find<PostSeqController>();
  final isEdit = editing != null;
  final editId = editing?.id?.trim();
  if (isEdit && (editId == null || editId.isEmpty)) {
    AppToast.show(context: context, title: '岗位序列 id 无效');
    return Future.value();
  }

  final channel = editing?.channel?.trim().toUpperCase();
  final initialChannel =
      (channel == 'M' || channel == 'T') ? channel! : 'M';

  return AppDialog.show<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PostSeqFormDialog(
      title: isEdit ? '修改岗位序列' : '新增岗位序列',
      initialCode: editing?.code?.trim() ?? '',
      initialName: editing?.name?.trim() ?? '',
      initialChannel: initialChannel,
      initialOrderNum: editing?.orderNum ?? c.nextOrderNum,
      onClose: () => AppOverlay.close<void>(dialogContext),
      onSubmit: (payload) async {
        if (isEdit) {
          await c.updateSeq(
            id: editId!,
            code: payload.code,
            name: payload.name,
            channel: payload.channel,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '修改岗位序列成功');
          }
        } else {
          await c.createSeq(
            code: payload.code,
            name: payload.name,
            channel: payload.channel,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '新增岗位序列成功');
          }
        }
      },
    ),
  ).future;
}

class _PostSeqFormPayload {
  const _PostSeqFormPayload({
    required this.code,
    required this.name,
    required this.channel,
    required this.orderNum,
  });

  final String code;
  final String name;
  final String channel;
  final int orderNum;
}

class _PostSeqFormDialog extends StatefulWidget {
  const _PostSeqFormDialog({
    required this.title,
    required this.initialCode,
    required this.initialName,
    required this.initialChannel,
    required this.initialOrderNum,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final String initialCode;
  final String initialName;
  final String initialChannel;
  final int initialOrderNum;
  final VoidCallback onClose;
  final Future<void> Function(_PostSeqFormPayload payload) onSubmit;

  @override
  State<_PostSeqFormDialog> createState() => _PostSeqFormDialogState();
}

class _PostSeqFormDialogState extends State<_PostSeqFormDialog> {
  final _form = AppFormController();
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final code = (values['code'] as String?)?.trim() ?? '';
      final name = (values['name'] as String?)?.trim() ?? '';
      final channel = (values['channel'] as String?)?.trim().toUpperCase() ?? '';
      final orderRaw = values['orderNum'];
      final orderNum = orderRaw is int
          ? orderRaw
          : int.tryParse(orderRaw?.toString() ?? '') ?? widget.initialOrderNum;

      if (code.isEmpty || name.isEmpty || (channel != 'M' && channel != 'T')) {
        return;
      }

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _PostSeqFormPayload(
            code: code,
            name: name,
            channel: channel,
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
      child: AppFormDialog(
        title: Text(widget.title),
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 480),
        content: AppFieldScope.horizontal(
          labelWidth: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              AppTextFormField(
                name: 'code',
                label: '编号',
                required: true,
                hintText: '请输入编号',
                maxLength: 30,
                initialValue:
                    widget.initialCode.isEmpty ? null : widget.initialCode,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '请输入编号';
                  if (s.length > 30) return '编号不超过 30 字';
                  return null;
                },
              ),
              AppTextFormField(
                name: 'name',
                label: '名称',
                required: true,
                hintText: '请输入名称',
                maxLength: 30,
                initialValue:
                    widget.initialName.isEmpty ? null : widget.initialName,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '请输入名称';
                  if (s.length > 30) return '名称不超过 30 字';
                  return null;
                },
              ),
              AppRadioGroupFormField<String>(
                name: 'channel',
                label: '类型',
                required: true,
                valueDirection: Axis.horizontal,
                spacing: 24,
                initialValue: widget.initialChannel,
                options: _kChannelOptions,
                validator: (v) =>
                    (v != 'M' && v != 'T') ? '请选择类型' : null,
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
          AppButton.outline(
            onPressed: _saving ? null : widget.onClose,
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
