import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_post_seq_level.dart';
import '../post_seq_controller.dart';

const _kSalaryMax = 99999999;

/// 打开「新增职级」弹窗；成功后刷新右侧职级列表。
Future<void> showPostSeqLevelAddDialog(BuildContext context) {
  return _showPostSeqLevelFormDialog(context, editing: null);
}

/// 打开「修改职级」弹窗；成功后刷新右侧职级列表。
Future<void> showPostSeqLevelEditDialog(
  BuildContext context,
  HrmPostSeqLevel level,
) {
  return _showPostSeqLevelFormDialog(context, editing: level);
}

Future<void> _showPostSeqLevelFormDialog(
  BuildContext context, {
  required HrmPostSeqLevel? editing,
}) {
  final hostContext = context;
  final c = context.lx.find<PostSeqController>();
  final seqId = c.selectedSeqId.value?.trim();
  if (seqId == null || seqId.isEmpty) {
    AppToast.show(context: context, title: '请先选择岗位序列');
    return Future.value();
  }

  final isEdit = editing != null;
  final editId = editing?.id?.trim();
  if (isEdit && (editId == null || editId.isEmpty)) {
    AppToast.show(context: context, title: '职级 id 无效');
    return Future.value();
  }

  int salaryOf(num? v) {
    if (v == null) return 1;
    final n = v.round();
    if (n < 1) return 1;
    if (n > _kSalaryMax) return _kSalaryMax;
    return n;
  }

  return AppDialog.show<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PostSeqLevelFormDialog(
      title: isEdit ? '修改职级' : '新增职级',
      initialCode: editing?.code?.trim() ?? '',
      initialSalaryMin: salaryOf(editing?.salaryMin),
      initialSalaryMax: salaryOf(editing?.salaryMax),
      initialOrderNum: editing?.orderNum ?? c.nextLevelOrderNum,
      onClose: () => AppOverlay.close<void>(dialogContext),
      onSubmit: (payload) async {
        if (isEdit) {
          await c.updateLevel(
            id: editId!,
            code: payload.code,
            salaryMin: payload.salaryMin,
            salaryMax: payload.salaryMax,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '修改职级成功');
          }
        } else {
          await c.createLevel(
            code: payload.code,
            salaryMin: payload.salaryMin,
            salaryMax: payload.salaryMax,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '新增职级成功');
          }
        }
      },
    ),
  ).future;
}

class _PostSeqLevelFormPayload {
  const _PostSeqLevelFormPayload({
    required this.code,
    required this.salaryMin,
    required this.salaryMax,
    required this.orderNum,
  });

  final String code;
  final num salaryMin;
  final num salaryMax;
  final int orderNum;
}

class _PostSeqLevelFormDialog extends StatefulWidget {
  const _PostSeqLevelFormDialog({
    required this.title,
    required this.initialCode,
    required this.initialSalaryMin,
    required this.initialSalaryMax,
    required this.initialOrderNum,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final String initialCode;
  final int initialSalaryMin;
  final int initialSalaryMax;
  final int initialOrderNum;
  final VoidCallback onClose;
  final Future<void> Function(_PostSeqLevelFormPayload payload) onSubmit;

  @override
  State<_PostSeqLevelFormDialog> createState() => _PostSeqLevelFormDialogState();
}

class _PostSeqLevelFormDialogState extends State<_PostSeqLevelFormDialog> {
  final _form = AppFormController();
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  int _asInt(Object? raw, int fallback) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final code = (values['code'] as String?)?.trim() ?? '';
      final salaryMin = _asInt(values['salaryMin'], widget.initialSalaryMin);
      final salaryMax = _asInt(values['salaryMax'], widget.initialSalaryMax);
      final orderNum = _asInt(values['orderNum'], widget.initialOrderNum);

      if (code.isEmpty) return;
      if (salaryMin <= 0 || salaryMax <= 0) return;
      if (salaryMax < salaryMin) {
        AppToast.show(context: context, title: '薪资上限不能低于下限');
        return;
      }

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _PostSeqLevelFormPayload(
            code: code,
            salaryMin: salaryMin,
            salaryMax: salaryMax,
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
                label: '编码',
                required: true,
                hintText: '请输入编码',
                maxLength: 30,
                initialValue:
                    widget.initialCode.isEmpty ? null : widget.initialCode,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return '请输入编码';
                  if (s.length > 30) return '编码不超过 30 字';
                  return null;
                },
              ),
              AppNumberInputFormField(
                name: 'salaryMin',
                label: '薪资下限',
                required: true,
                min: 1,
                max: _kSalaryMax,
                inputWidth: 160,
                initialValue: widget.initialSalaryMin,
                validator: (v) {
                  if (v == null || v <= 0) return '请输入薪资下限';
                  if (v > _kSalaryMax) return '薪资下限过大';
                  return null;
                },
              ),
              AppNumberInputFormField(
                name: 'salaryMax',
                label: '薪资上限',
                required: true,
                min: 1,
                max: _kSalaryMax,
                inputWidth: 160,
                initialValue: widget.initialSalaryMax,
                validator: (v) {
                  if (v == null || v <= 0) return '请输入薪资上限';
                  if (v > _kSalaryMax) return '薪资上限过大';
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
