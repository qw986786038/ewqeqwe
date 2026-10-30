import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../post_manage_controller.dart';

/// 打开「新增岗位」弹窗；成功后刷新列表。
Future<void> showPostManageAddDialog(BuildContext context) {
  return _showPostManageFormDialog(context, editing: null);
}

/// 打开「修改岗位」弹窗；成功后刷新列表。
Future<void> showPostManageEditDialog(BuildContext context, HrmPost post) {
  return _showPostManageFormDialog(context, editing: post);
}

Future<void> _showPostManageFormDialog(
  BuildContext context, {
  required HrmPost? editing,
}) {
  final hostContext = context;
  final c = context.lx.find<PostManageController>();
  final isEdit = editing != null;
  final editId = editing?.id?.trim();
  if (isEdit && (editId == null || editId.isEmpty)) {
    AppToast.show(context: context, title: '岗位 id 无效');
    return Future.value();
  }

  final initialSeqId = editing == null
      ? null
      : (c.seqIdOfLevel(editing.postSeqLevelIdMin) ??
          c.seqIdOfLevel(editing.postSeqLevelIdMax));

  return AppDialog.show<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PostManageFormDialog(
      title: isEdit ? '修改岗位' : '新增岗位',
      seqs: List<HrmPostSeq>.from(c.seqs),
      levels: List<HrmPostSeqLevel>.from(c.levels),
      initialName: editing?.name?.trim() ?? '',
      initialSeqId: initialSeqId,
      initialLevelMinId: editing?.postSeqLevelIdMin?.trim(),
      initialLevelMaxId: editing?.postSeqLevelIdMax?.trim(),
      initialOrderNum: editing?.orderNum ?? c.nextOrderNum,
      seqLabelOf: c.seqOptionLabel,
      onClose: () => AppOverlay.close<void>(dialogContext),
      onSubmit: (payload) async {
        if (isEdit) {
          await c.updatePost(
            id: editId!,
            name: payload.name,
            postSeqLevelIdMin: payload.levelMinId,
            postSeqLevelIdMax: payload.levelMaxId,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '修改岗位成功');
          }
        } else {
          await c.createPost(
            name: payload.name,
            postSeqLevelIdMin: payload.levelMinId,
            postSeqLevelIdMax: payload.levelMaxId,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '新增岗位成功');
          }
        }
      },
    ),
  ).future;
}

class _PostFormPayload {
  const _PostFormPayload({
    required this.name,
    required this.levelMinId,
    required this.levelMaxId,
    required this.orderNum,
  });

  final String name;
  final String levelMinId;
  final String levelMaxId;
  final int orderNum;
}

class _PostManageFormDialog extends StatefulWidget {
  const _PostManageFormDialog({
    required this.title,
    required this.seqs,
    required this.levels,
    required this.initialName,
    required this.initialSeqId,
    required this.initialLevelMinId,
    required this.initialLevelMaxId,
    required this.initialOrderNum,
    required this.seqLabelOf,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final List<HrmPostSeq> seqs;
  final List<HrmPostSeqLevel> levels;
  final String initialName;
  final String? initialSeqId;
  final String? initialLevelMinId;
  final String? initialLevelMaxId;
  final int initialOrderNum;
  final String Function(HrmPostSeq seq) seqLabelOf;
  final VoidCallback onClose;
  final Future<void> Function(_PostFormPayload payload) onSubmit;

  @override
  State<_PostManageFormDialog> createState() => _PostManageFormDialogState();
}

class _PostManageFormDialogState extends State<_PostManageFormDialog> {
  final _form = AppFormController();
  late String? _seqId = widget.initialSeqId;
  int _levelEpoch = 0;
  var _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  List<AppOption<String>> get _seqOptions => [
        for (final s in widget.seqs)
          if (s.id != null && s.id!.trim().isNotEmpty)
            AppOption(value: s.id!.trim(), label: widget.seqLabelOf(s)),
      ];

  List<AppOption<String>> get _levelOptions {
    final seqId = _seqId;
    if (seqId == null || seqId.isEmpty) return const [];
    return [
      for (final l in widget.levels)
        if (l.postSeqId == seqId &&
            l.id != null &&
            l.id!.trim().isNotEmpty &&
            l.code?.trim().isNotEmpty == true)
          AppOption(value: l.id!.trim(), label: l.code!.trim()),
    ];
  }

  Future<void> _submit() async {
    if (_saving) return;
    await _form.submit((values) async {
      final name = (values['name'] as String?)?.trim() ?? '';
      final seqId = (values['postSeqId'] as String?)?.trim() ?? '';
      final minId = (values['postSeqLevelIdMin'] as String?)?.trim() ?? '';
      final maxId = (values['postSeqLevelIdMax'] as String?)?.trim() ?? '';
      final orderRaw = values['orderNum'];
      final orderNum = orderRaw is int
          ? orderRaw
          : int.tryParse(orderRaw?.toString() ?? '') ?? widget.initialOrderNum;

      if (name.isEmpty ||
          seqId.isEmpty ||
          minId.isEmpty ||
          maxId.isEmpty) {
        return;
      }

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _PostFormPayload(
            name: name,
            levelMinId: minId,
            levelMaxId: maxId,
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
    final levelOpts = _levelOptions;
    final minId = widget.initialLevelMinId;
    final maxId = widget.initialLevelMaxId;
    final minInitial = (minId != null &&
            levelOpts.any((o) => o.value == minId))
        ? minId
        : null;
    final maxInitial = (maxId != null &&
            levelOpts.any((o) => o.value == maxId))
        ? maxId
        : null;

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
                name: 'name',
                label: '岗位名称',
                required: true,
                hintText: '请输入岗位名称',
                initialValue: widget.initialName.isEmpty
                    ? null
                    : widget.initialName,
                validator: AppValidators.required(message: '请输入岗位名称'),
              ),
              AppSelectFormField<String>(
                name: 'postSeqId',
                label: '岗位序列',
                required: true,
                hintText: '请选择岗位序列',
                options: _seqOptions,
                initialValue: widget.initialSeqId,
                onChanged: (v) {
                  setState(() {
                    _seqId = v;
                    _levelEpoch++;
                  });
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? '请选择岗位序列' : null,
              ),
              KeyedSubtree(
                key: ValueKey('min-$_levelEpoch-$_seqId'),
                child: AppSelectFormField<String>(
                  name: 'postSeqLevelIdMin',
                  label: '职级下限',
                  required: true,
                  hintText: _seqId == null ? '请先选择岗位序列' : '请选择职级下限',
                  options: levelOpts,
                  enabled: _seqId != null,
                  initialValue: _levelEpoch == 0 ? minInitial : null,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '请选择职级下限' : null,
                ),
              ),
              KeyedSubtree(
                key: ValueKey('max-$_levelEpoch-$_seqId'),
                child: AppSelectFormField<String>(
                  name: 'postSeqLevelIdMax',
                  label: '职级上限',
                  required: true,
                  hintText: _seqId == null ? '请先选择岗位序列' : '请选择职级上限',
                  options: levelOpts,
                  enabled: _seqId != null,
                  initialValue: _levelEpoch == 0 ? maxInitial : null,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '请选择职级上限' : null,
                ),
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
