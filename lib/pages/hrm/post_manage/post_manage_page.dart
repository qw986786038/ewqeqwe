import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_post.dart';
import 'add/post_manage_add_dialog.dart';
import 'post_manage_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);

/// HRM · 岗位管理。
class PostManagePage extends StatelessWidget {
  const PostManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<PostManageController>(PostManageController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<PostManageController>();
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
                    '岗位名称',
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
                        hintText: '请输入岗位名称',
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
                            onPressed: () => showPostManageAddDialog(context),
                            leading: const Icon(Icons.add, size: 16),
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
                        c.filteredPosts.length;
                        c.loading.value;
                        final err = c.errorMessage.value;
                        if (c.loading.value && c.posts.isEmpty) {
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
                        if (err != null && c.posts.isEmpty) {
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
                            return AppDataGrid<HrmPost>.local(
                              height: h > 0 ? h : 420,
                              rows: c.filteredPosts.toList(),
                              rowKey: (row) => row.id ?? row.name ?? '',
                              sortable: true,
                              showInternalDividers: true,
                              headerBackgroundColor: const Color(0xFFFAFAFA),
                              textStyle: const TextStyle(fontSize: 12),
                              cellTextStyle: const TextStyle(fontSize: 12),
                              empty: const Center(
                                child: Text(
                                  '暂无岗位',
                                  style: TextStyle(color: _kMuted),
                                ),
                              ),
                              columns: [
                                AppDataGridColumn(
                                  id: 'name',
                                  title: '岗位名称',
                                  width: 140,
                                  value: (row) =>
                                      row.name?.trim().isNotEmpty == true
                                          ? row.name!.trim()
                                          : '-',
                                ),
                                AppDataGridColumn(
                                  id: 'seq',
                                  title: '岗位序列',
                                  width: 220,
                                  value: (row) => c.seqDisplay(row),
                                ),
                                AppDataGridColumn(
                                  id: 'levelMin',
                                  title: '职级下限',
                                  width: 100,
                                  value: (row) => c.levelCodeMin(row),
                                ),
                                AppDataGridColumn(
                                  id: 'levelMax',
                                  title: '职级上限',
                                  width: 100,
                                  value: (row) => c.levelCodeMax(row),
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
                                              showPostManageEditDialog(
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
                                          onPressed: () {
                                            AppToast.show(
                                              context: context,
                                              title: '删除岗位待接入',
                                            );
                                          },
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
