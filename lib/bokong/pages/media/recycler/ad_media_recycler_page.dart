import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/pages/media/recycler/ad_media_recycler_controller.dart';
import 'package:yidivination/bokong/widget/load_more_listener.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';

/// 素材库回收站。
class AdMediaRecyclerPage extends StatelessWidget {
  const AdMediaRecyclerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<AdMediaRecyclerController>(AdMediaRecyclerController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  static const double _thumbSize = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<AdMediaRecyclerController>();

    return Scaffold(
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Row(
                spacing: 16,
                children: [
                Obx(
                  () => AppTabs(
                    index: c.typeFilter.value.index,
                    selectedColor: Colors.white,
                    onChanged: (index) =>
                        c.setType(AdMediaRecyclerType.values[index]),
                    children: [
                      for (final type in AdMediaRecyclerType.values)
                        AppTabItem(
                          child: Text(
                            type.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                SearchFieldBackground(
                  child: AppTextFormField(
                    width: 360,
                    hintText: '搜索素材',
                    controller: c.searchController,
                    onSubmitted: (_) => c.search(),
                    trailing: SearchIconButton(onPressed: c.search),
                  ),
                ),
                const Spacer(),
                AppButton.outline(
                  onPressed: () => _confirmEmpty(context, c),
                  child: const Text('清空回收站'),
                ),
                Obx(() {
                  final hasSelection = c.selectedIds.isNotEmpty;
                  return AppButton.primary(
                    onPressed: hasSelection
                        ? () => _confirmRestoreSelected(context, c)
                        : null,
                    child: const Text('全部还原'),
                  );
                }),
              ],
            ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(20),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: Obx(() {
              final items = c.items.toList();
              final loading = c.loading.value;
              final selectedKeys = <Object>{for (final id in c.selectedIds) id};

              if (loading && items.isEmpty) {
                return const Center(
                  child: AppCircularProgressIndicator(),
                );
              }

              return Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LoadMoreListener(
                    onLoadMore: c.loadMore,
                    child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 待上游：AppDataGrid 增加 rowHeight，避免为单表再套 AppShadcnScope。
                      final theme = AppTheme.of(context);
                      return AppShadcnScope(
                        config: theme.copyWith(
                          dataGrid: AppDataGridMetrics(
                            rowHeight: 64,
                            columnHeight: theme.dataGrid.columnHeight,
                            filterHeight: theme.dataGrid.filterHeight,
                            footerHeight: theme.dataGrid.footerHeight,
                            horizontalPadding: theme.dataGrid.horizontalPadding,
                            fontSize: theme.dataGrid.fontSize,
                          ),
                        ),
                        provideMaterialHost: false,
                        syncMaterialTheme: false,
                        child: AppDataGrid<AdMediaEntity>.local(
                          height: constraints.maxHeight,
                          rows: items,
                          rowKey: (row) => row.id ?? identityHashCode(row),
                          selectionMode: AppDataGridSelectionMode.multiple,
                          selectedKeys: selectedKeys,
                          onSelectionChanged: c.setSelected,
                          onRowDoubleTap: (row) => showAdMediaPreviewDialog(
                            context: context,
                            media: row,
                          ),
                          sortable: false,
                          showBorder: false,
                          showInternalDividers: false,
                          striped: false,
                          selectedRowColor: const Color(0xFFF2F3F5),
                          headerBackgroundColor: kTableHeaderBackground,
                          headerTextStyle: kTableHeaderTextStyle,
                          empty: const Center(child: AppEmptyState()),
                          columns: [
                            AppDataGridColumn(
                              id: 'file',
                              title: '回收站文件',
                              value: (row) => _displayName(row),
                              widthMode: AppDataGridColumnWidthMode.fill,
                              alignment: Alignment.centerLeft,
                              titleAlignment: Alignment.centerLeft,
                              sortable: false,
                              filterable: false,
                              cellBuilder: (context, row, value) => Row(
                                spacing: 12,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: _thumbSize,
                                      height: _thumbSize,
                                      child: _Thumb(
                                        path: resolveAdMediaGridThumbPath(row),
                                        isWeb: adMediaIsWebType(row.media_type),
                                      ),
                                    ),
                                  ),
                                  AppText.label(
                                    _displayName(row),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ).expanded(),
                                ],
                              ),
                            ),
                            AppDataGridColumn(
                              id: 'actions',
                              title: '',
                              value: (row) => row.id ?? 0,
                              width: 120,
                              sortable: false,
                              filterable: false,
                              cellBuilder: (context, row, value) => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  AppIconButton(
                                    icon: Icon(
                                      AppLucideIcons.rotateCcw,
                                      size: 16,
                                      color: kIconButtonForeground,
                                    ),
                                    tooltip: '还原',
                                    onPressed: () =>
                                        _confirmRestoreOne(context, c, row),
                                  ),
                                  AppIconButton(
                                    icon: Icon(
                                      AppLucideIcons.trash2,
                                      size: 16,
                                      color: kIconButtonForeground,
                                    ),
                                    tooltip: '彻底删除',
                                    onPressed: () =>
                                        _confirmDeleteOne(context, c, row),
                                  ),
                                ],
                              ),
                            ),
                            AppDataGridColumn(
                              id: 'size',
                              title: '大小',
                              value: (row) {
                                final size = adMediaFileSizeLabel(
                                  row.file_size,
                                );
                                return size.isEmpty ? '-' : size;
                              },
                              width: 140,
                              sortable: false,
                              filterable: false,
                            ),
                            AppDataGridColumn(
                              id: 'deleteTime',
                              title: '删除时间',
                              value: (row) =>
                                  _formatDeleteTime(row.delete_time),
                              width: 200,
                              sortable: false,
                              filterable: false,
                            ),
                            AppDataGridColumn(
                              id: 'clearDate',
                              title: '清除日期',
                              value: (row) => '-',
                              width: 160,
                              sortable: false,
                              filterable: false,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ).expanded(),
                  if (loading) const AppCircularProgressIndicator().center(),
                ],
              );
            }),
            ).expanded(),
          ],
        ),
    );
  }

  Future<void> _confirmEmpty(
    BuildContext context,
    AdMediaRecyclerController c,
  ) async {
    final ok = await _confirm(
      context,
      title: '清空回收站',
      message: '确定要清空回收站吗？此操作不可撤销。',
      confirmLabel: '清空',
      destructive: true,
    );
    if (ok) await c.emptyRecycler();
  }

  Future<void> _confirmRestoreSelected(
    BuildContext context,
    AdMediaRecyclerController c,
  ) async {
    final count = c.selectedIds.length;
    if (count < 1) {
      showWarn('请先选择要还原的素材');
      return;
    }
    final ok = await _confirm(
      context,
      title: '全部还原',
      message: '确定要还原已选的 $count 个素材吗？',
      confirmLabel: '还原',
    );
    if (ok) await c.restoreSelected();
  }

  Future<void> _confirmRestoreOne(
    BuildContext context,
    AdMediaRecyclerController c,
    AdMediaEntity item,
  ) async {
    final name = _displayName(item);
    final ok = await _confirm(
      context,
      title: '还原素材',
      message: '确定要还原「$name」吗？',
      confirmLabel: '还原',
    );
    if (ok) await c.restoreOne(item);
  }

  Future<void> _confirmDeleteOne(
    BuildContext context,
    AdMediaRecyclerController c,
    AdMediaEntity item,
  ) async {
    final name = _displayName(item);
    final ok = await showAppDeleteConfirmDialog(
      context,
      title: '彻底删除',
      message: '确定要彻底删除「$name」吗？此操作不可撤销。',
    );
    if (ok) await c.deleteOne(item);
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    return showAppWindowDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDeleteConfirmAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close(dialogContext, false),
            child: const Text('取消'),
          ),
          if (destructive)
            AppButton.destructive(
              onPressed: () => AppOverlay.close(dialogContext, true),
              child: Text(confirmLabel),
            )
          else
            AppButton.primary(
              onPressed: () => AppOverlay.close(dialogContext, true),
              child: Text(confirmLabel),
            ),
        ],
      ),
    ).future.then((value) => value == true);
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, this.isWeb = false});

  final String? path;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xFF94A3B8);
    if (path == null || path!.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFE8EEF3),
        child: Center(
          child: Icon(
            isWeb ? AppLucideIcons.globe : AppLucideIcons.image,
            size: 18,
            color: hintColor,
          ),
        ),
      );
    }

    return ExtendedImage.network(
      path!,
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        if (state.extendedImageLoadState == LoadState.loading) {
          return const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: AppCircularProgressIndicator(),
            ),
          );
        }
        if (state.extendedImageLoadState == LoadState.failed) {
          return ColoredBox(
            color: const Color(0xFFE8EEF3),
            child: Center(
              child: Icon(AppLucideIcons.imageOff, size: 18, color: hintColor),
            ),
          );
        }
        return null;
      },
    );
  }
}

String _displayName(AdMediaEntity item) {
  final title = item.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  final path = item.file_path?.trim();
  if (path != null && path.isNotEmpty) {
    final parts = path.replaceAll('\\', '/').split('/');
    final name = parts.isNotEmpty ? parts.last : path;
    if (name.isNotEmpty) return name;
  }
  return item.media_no?.trim().isNotEmpty == true ? item.media_no!.trim() : '-';
}

String _formatDeleteTime(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '-';
  return value.replaceAll('-', '/');
}
