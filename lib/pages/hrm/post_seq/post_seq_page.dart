import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_post_seq.dart';
import '../../../models/hrm_post_seq_level.dart';
import 'add/post_seq_form_dialog.dart';
import 'add/post_seq_level_form_dialog.dart';
import 'post_seq_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);

/// HRM · 岗位序列（左序列表 + 右职级表）。
class PostSeqPage extends StatelessWidget {
  const PostSeqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<PostSeqController>(PostSeqController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _kPageBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _SeqPanel()),
            SizedBox(width: 12),
            Expanded(child: _LevelPanel()),
          ],
        ),
      ),
    );
  }
}

class _SeqPanel extends StatelessWidget {
  const _SeqPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<PostSeqController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Text(
                  '岗位序列',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
                const Spacer(),
                AppButton.primary(
                  onPressed: () => showPostSeqAddDialog(context),
                  leading: const Icon(Icons.add, size: 16),
                  child: const Text('新增'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: Obx(() {
              c.seqs.length;
              c.selectedSeqId.value;
              final err = c.seqError.value;
              if (c.seqLoading.value && c.seqs.isEmpty) {
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }
              if (err != null && c.seqs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        err,
                        style: const TextStyle(fontSize: 13, color: _kMuted),
                      ),
                      const SizedBox(height: 12),
                      AppButton.outline(
                        onPressed: c.refreshSeqs,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }
              final selected = c.selectedSeqId.value;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  return AppDataGrid<HrmPostSeq>.local(
                    height: h > 0 ? h : 420,
                    rows: c.seqs.toList(),
                    rowKey: (row) => row.id ?? row.code ?? '',
                    sortable: true,
                    showInternalDividers: true,
                    headerBackgroundColor: const Color(0xFFFAFAFA),
                    textStyle: const TextStyle(fontSize: 12),
                    cellTextStyle: const TextStyle(fontSize: 12),
                    selectionMode: AppDataGridSelectionMode.single,
                    selectedKeys: <Object>{?selected},
                    onSelectionChanged: (keys) {
                      if (keys.isEmpty) return;
                      final id = keys.first.toString();
                      if (id.isNotEmpty) c.selectSeq(id);
                    },
                    empty: const Center(
                      child: Text(
                        '暂无岗位序列',
                        style: TextStyle(color: _kMuted),
                      ),
                    ),
                    columns: [
                      AppDataGridColumn(
                        id: 'code',
                        title: '编号',
                        width: 72,
                        value: (row) =>
                            row.code?.trim().isNotEmpty == true
                                ? row.code!.trim()
                                : '-',
                      ),
                      AppDataGridColumn(
                        id: 'name',
                        title: '名称',
                        width: 160,
                        value: (row) =>
                            row.name?.trim().isNotEmpty == true
                                ? row.name!.trim()
                                : '-',
                      ),
                      AppDataGridColumn(
                        id: 'channel',
                        title: '类型',
                        width: 88,
                        value: (row) {
                          final label =
                              PostSeqController.channelLabel(row.channel);
                          return label.isNotEmpty ? label : '-';
                        },
                      ),
                      AppDataGridColumn(
                        id: 'order',
                        title: '排序',
                        width: 64,
                        type: AppDataGridColumnType.number,
                        value: (row) => row.orderNum ?? 0,
                        cellBuilder: (context, row, _) => Text(
                          '${row.orderNum ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'actions',
                        title: '操作',
                        width: 88,
                        sortable: false,
                        resizable: false,
                        pin: AppDataGridColumnPin.end,
                        value: (_) => '',
                        cellBuilder: (context, row, _) => Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppInkWell(
                                onPressed: () =>
                                    showPostSeqEditDialog(context, row),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                              AppInkWell(
                                onPressed: () =>
                                    _confirmDeletePostSeq(context, row),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeletePostSeq(
  BuildContext context,
  HrmPostSeq seq,
) async {
  final id = seq.id?.trim();
  if (id == null || id.isEmpty) {
    AppToast.show(context: context, title: '岗位序列 id 无效');
    return;
  }
  final name = seq.name?.trim().isNotEmpty == true
      ? seq.name!.trim()
      : (seq.code?.trim().isNotEmpty == true ? seq.code!.trim() : id);
  final hostContext = context;
  final c = context.lx.find<PostSeqController>();
  final ok = await AppDialog.show<bool>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      title: const Text('确认删除'),
      content: Text('确定删除岗位序列「$name」吗？'),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(dialogContext, false),
          child: const Text('取消'),
        ),
        AppButton.destructive(
          onPressed: () => AppOverlay.close(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  ).future;
  if (ok != true) return;
  try {
    await c.deleteSeq(id);
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: '删除岗位序列成功');
    }
  } catch (e) {
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: e.toString());
    }
  }
}

class _LevelPanel extends StatelessWidget {
  const _LevelPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<PostSeqController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() {
                    c.selectedSeqId.value;
                    c.seqs.length;
                    final sub = c.selectedSeq?.name?.trim();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '岗位序列职级',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kTitle,
                          ),
                        ),
                        if (sub != null && sub.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
                AppButton.primary(
                  onPressed: () => showPostSeqLevelAddDialog(context),
                  leading: const Icon(Icons.add, size: 16),
                  child: const Text('新增'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: Obx(() {
              c.levels.length;
              c.selectedSeqId.value;
              final err = c.levelError.value;
              if (c.selectedSeqId.value == null) {
                return const Center(
                  child: Text(
                    '请选择左侧岗位序列',
                    style: TextStyle(color: _kMuted, fontSize: 13),
                  ),
                );
              }
              if (c.levelLoading.value && c.levels.isEmpty) {
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }
              if (err != null && c.levels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        err,
                        style: const TextStyle(fontSize: 13, color: _kMuted),
                      ),
                      const SizedBox(height: 12),
                      AppButton.outline(
                        onPressed: () {
                          final id = c.selectedSeqId.value;
                          if (id != null) c.loadLevels(id);
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  return AppDataGrid<HrmPostSeqLevel>.local(
                    height: h > 0 ? h : 420,
                    rows: c.levels.toList(),
                    rowKey: (row) => row.id ?? row.code ?? '',
                    sortable: true,
                    showInternalDividers: true,
                    headerBackgroundColor: const Color(0xFFFAFAFA),
                    textStyle: const TextStyle(fontSize: 12),
                    cellTextStyle: const TextStyle(fontSize: 12),
                    empty: const Center(
                      child: Text(
                        '暂无职级',
                        style: TextStyle(color: _kMuted),
                      ),
                    ),
                    columns: [
                      AppDataGridColumn(
                        id: 'code',
                        title: '编码',
                        width: 80,
                        value: (row) =>
                            row.code?.trim().isNotEmpty == true
                                ? row.code!.trim()
                                : '-',
                      ),
                      AppDataGridColumn(
                        id: 'salaryMin',
                        title: '薪资下限',
                        width: 120,
                        type: AppDataGridColumnType.number,
                        value: (row) => row.salaryMin ?? 0,
                        cellBuilder: (context, row, _) => Text(
                          PostSeqController.moneyText(row.salaryMin),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'salaryMax',
                        title: '薪资上限',
                        width: 120,
                        type: AppDataGridColumnType.number,
                        value: (row) => row.salaryMax ?? 0,
                        cellBuilder: (context, row, _) => Text(
                          PostSeqController.moneyText(row.salaryMax),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'order',
                        title: '排序',
                        width: 64,
                        type: AppDataGridColumnType.number,
                        value: (row) => row.orderNum ?? 0,
                        cellBuilder: (context, row, _) => Text(
                          '${row.orderNum ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'actions',
                        title: '操作',
                        width: 88,
                        sortable: false,
                        resizable: false,
                        pin: AppDataGridColumnPin.end,
                        value: (_) => '',
                        cellBuilder: (context, row, _) => Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppInkWell(
                                onPressed: () =>
                                    showPostSeqLevelEditDialog(context, row),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                              AppInkWell(
                                onPressed: () =>
                                    _confirmDeletePostSeqLevel(context, row),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeletePostSeqLevel(
  BuildContext context,
  HrmPostSeqLevel level,
) async {
  final id = level.id?.trim();
  if (id == null || id.isEmpty) {
    AppToast.show(context: context, title: '职级 id 无效');
    return;
  }
  final name = level.code?.trim().isNotEmpty == true
      ? level.code!.trim()
      : id;
  final hostContext = context;
  final c = context.lx.find<PostSeqController>();
  final ok = await AppDialog.show<bool>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      title: const Text('确认删除'),
      content: Text('确定删除职级「$name」吗？'),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(dialogContext, false),
          child: const Text('取消'),
        ),
        AppButton.destructive(
          onPressed: () => AppOverlay.close(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  ).future;
  if (ok != true) return;
  try {
    await c.deleteLevel(id);
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: '删除职级成功');
    }
  } catch (e) {
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: e.toString());
    }
  }
}
