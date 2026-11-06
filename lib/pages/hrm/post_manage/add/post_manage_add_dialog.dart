import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/hrm_post.dart';
import '../../../../models/hrm_post_seq_level.dart';
import '../post_manage_controller.dart';

/// 打开「新增职务」弹窗；成功后刷新列表。
Future<void> showPostManageAddDialog(BuildContext context) {
  return _showPostManageFormDialog(context, editing: null);
}

/// 打开「修改职务」弹窗；成功后刷新列表。
Future<void> showPostManageEditDialog(BuildContext context, HrmPost post) {
  return _showPostManageFormDialog(context, editing: post);
}

/// 确认后删除职务。
Future<void> confirmDeletePost(BuildContext context, HrmPost post) async {
  final id = post.id?.trim();
  if (id == null || id.isEmpty) {
    AppToast.show(context: context, title: '职务 id 无效');
    return;
  }
  final name = post.name?.trim().isNotEmpty == true
      ? post.name!.trim()
      : '未命名职务';
  final hostContext = context;
  final c = context.lx.find<PostManageController>();
  final ok = await showHyperDialog<bool>(
    context: context,
    builder: (dialogContext) => HyperDialog(
      title: const Text('确认删除'),
      content: Text('确定删除职务「$name」吗？'),
      actions: [
        HyperButton.outlined(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          label: const Text('取消'),
        ),
        HyperButton.filled(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          label: const Text('删除'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await c.deletePost(id);
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: '删除职务成功');
    }
  } catch (e) {
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: e.toString());
    }
  }
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
    AppToast.show(context: context, title: '职务 id 无效');
    return Future.value();
  }

  // 弹窗仅展示名称 / 排序；职级上下限沿用原值，新增时取序列中首末职级兜底。
  String? levelMin = editing?.postSeqLevelIdMin?.trim();
  String? levelMax = editing?.postSeqLevelIdMax?.trim();
  if ((levelMin == null || levelMin.isEmpty) ||
      (levelMax == null || levelMax.isEmpty)) {
    final fallback = _defaultLevelRange(c.levels);
    levelMin = (levelMin == null || levelMin.isEmpty) ? fallback.$1 : levelMin;
    levelMax = (levelMax == null || levelMax.isEmpty) ? fallback.$2 : levelMax;
  }

  return showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PostManageFormDialog(
      title: isEdit ? '修改职务' : '新增职务',
      initialName: editing?.name?.trim() ?? '',
      initialOrderNum: editing?.orderNum ?? c.nextOrderNum,
      levelMinId: levelMin ?? '',
      levelMaxId: levelMax ?? '',
      onClose: () => Navigator.of(dialogContext).pop(),
      onSubmit: (payload) async {
        if (isEdit) {
          await c.updatePost(
            id: editId!,
            name: payload.name,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '修改职务成功');
          }
        } else {
          if (payload.levelMinId.isEmpty || payload.levelMaxId.isEmpty) {
            throw StateError('请先在「序列」中配置职级后再维护职务');
          }
          await c.createPost(
            name: payload.name,
            postSeqLevelIdMin: payload.levelMinId,
            postSeqLevelIdMax: payload.levelMaxId,
            orderNum: payload.orderNum,
          );
          if (hostContext.mounted) {
            AppToast.show(context: hostContext, title: '新增职务成功');
          }
        }
      },
    ),
  );
}

/// 取第一个序列下按 orderNum 的首末职级，作新增职务默认上下限。
(String?, String?) _defaultLevelRange(List<HrmPostSeqLevel> levels) {
  if (levels.isEmpty) return (null, null);
  final bySeq = <String, List<HrmPostSeqLevel>>{};
  for (final l in levels) {
    final seqId = l.postSeqId?.trim();
    final id = l.id?.trim();
    if (seqId == null || seqId.isEmpty || id == null || id.isEmpty) continue;
    bySeq.putIfAbsent(seqId, () => <HrmPostSeqLevel>[]).add(l);
  }
  if (bySeq.isEmpty) return (null, null);
  final firstSeqLevels = bySeq.values.first
    ..sort((a, b) => (a.orderNum ?? 0).compareTo(b.orderNum ?? 0));
  final minId = firstSeqLevels.first.id?.trim();
  final maxId = firstSeqLevels.last.id?.trim();
  return (minId, maxId);
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
    required this.initialName,
    required this.initialOrderNum,
    required this.levelMinId,
    required this.levelMaxId,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final String initialName;
  final int initialOrderNum;
  final String levelMinId;
  final String levelMaxId;
  final VoidCallback onClose;
  final Future<void> Function(_PostFormPayload payload) onSubmit;

  @override
  State<_PostManageFormDialog> createState() => _PostManageFormDialogState();
}

class _PostManageFormDialogState extends State<_PostManageFormDialog> {
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
      final name = (values['name'] as String?)?.trim() ?? '';
      final orderRaw = values['orderNum'];
      final orderNum = orderRaw is int
          ? orderRaw
          : int.tryParse(orderRaw?.toString() ?? '') ?? widget.initialOrderNum;

      if (name.isEmpty) return;

      setState(() => _saving = true);
      try {
        await widget.onSubmit(
          _PostFormPayload(
            name: name,
            levelMinId: widget.levelMinId,
            levelMaxId: widget.levelMaxId,
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
          labelWidth: 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              AppTextFormField(
                name: 'name',
                label: '职务名称',
                required: true,
                maxLength: 10,
                hintText: '请输入职务名称',
                initialValue:
                    widget.initialName.isEmpty ? null : widget.initialName,
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return '请输入职务名称';
                  if (name.length > 10) return '职务名称不能超过10个字';
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
