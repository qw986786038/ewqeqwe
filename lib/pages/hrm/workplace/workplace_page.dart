import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_office_location.dart';
import 'add/workplace_form_dialog.dart';
import 'workplace_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);

/// HRM · 工作地点（办公地 CRUD）。
class WorkplacePage extends StatelessWidget {
  const WorkplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<WorkplaceController>(WorkplaceController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<WorkplaceController>();
    return ColoredBox(
      color: _kPageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  const Text(
                    '办公地址',
                    style: TextStyle(fontSize: 13, color: _kLabel),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: c.nameSearchCtrl,
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => c.search(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '请输入办公地址名称',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC9CDD4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: _kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: _kPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton.primary(
                    onPressed: c.search,
                    leading: const Icon(Icons.search, size: 16),
                    child: const Text('搜索'),
                  ),
                  const SizedBox(width: 8),
                  AppButton.outline(
                    onPressed: c.resetSearch,
                    leading: const Icon(Icons.refresh, size: 16),
                    child: const Text('重置'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Row(
                        children: [
                          AppButton.primary(
                            onPressed: () => showWorkplaceAddDialog(context),
                            leading: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            child: const Text('新增'),
                          ),
                          const Spacer(),
                          AppInkWell(
                            onPressed: c.search,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.search,
                                size: 18,
                                color: _kMuted,
                              ),
                            ),
                          ),
                          Obx(() {
                            final loading = c.loading.value;
                            return AppInkWell(
                              onPressed: loading ? null : c.refreshAll,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: loading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        size: 18,
                                        color: _kMuted,
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _kBorder),
                    Expanded(
                      child: Obx(() {
                        c.filtered.length;
                        c.loading.value;
                        final err = c.errorMessage.value;
                        if (c.loading.value && c.locations.isEmpty) {
                          return const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          );
                        }
                        if (err != null && c.locations.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  err,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppButton.outline(
                                  onPressed: c.refreshAll,
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final h = constraints.maxHeight;
                            return AppDataGrid<HrmOfficeLocation>.local(
                              height: h > 0 ? h : 420,
                              rows: c.filtered.toList(),
                              rowKey: (row) => row.id ?? row.name ?? '',
                              sortable: true,
                              showInternalDividers: true,
                              headerBackgroundColor: const Color(0xFFFAFAFA),
                              textStyle: const TextStyle(fontSize: 12),
                              cellTextStyle: const TextStyle(fontSize: 12),
                              empty: const Center(
                                child: Text(
                                  '暂无办公地',
                                  style: TextStyle(color: _kMuted),
                                ),
                              ),
                              columns: [
                                AppDataGridColumn(
                                  id: 'name',
                                  title: '办公地址名称',
                                  width: 160,
                                  value: (row) =>
                                      row.name?.trim().isNotEmpty == true
                                          ? row.name!.trim()
                                          : '-',
                                ),
                                AppDataGridColumn(
                                  id: 'address',
                                  title: '详细地址',
                                  width: 280,
                                  value: (row) =>
                                      row.address?.trim().isNotEmpty == true
                                          ? row.address!.trim()
                                          : '-',
                                ),
                                AppDataGridColumn(
                                  id: 'order',
                                  title: '排序',
                                  width: 80,
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
                                              showWorkplaceEditDialog(
                                            context,
                                            row,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                              _confirmDelete(context, row),
                                          borderRadius:
                                              BorderRadius.circular(4),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  HrmOfficeLocation location,
) async {
  final id = location.id?.trim();
  if (id == null || id.isEmpty) {
    AppToast.show(context: context, title: '办公地 id 无效');
    return;
  }
  final name = location.name?.trim().isNotEmpty == true
      ? location.name!.trim()
      : id;
  final hostContext = context;
  final c = context.lx.find<WorkplaceController>();
  final ok = await AppDialog.show<bool>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      title: const Text('确认删除'),
      content: Text('确定删除办公地「$name」吗？'),
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
    await c.deleteLocation(id);
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: '删除办公地成功');
    }
  } catch (e) {
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: e.toString());
    }
  }
}
