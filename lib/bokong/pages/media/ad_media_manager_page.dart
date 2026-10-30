import 'package:extended_image/extended_image.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/order/ad_content_category_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/pages/media/add/ad_media_add_dialog.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/pages/media/dialogs/ad_media_delete_dialog.dart';
import 'package:yidivination/bokong/pages/media/dialogs/ad_media_rename_dialog.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/load_more_listener.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad show ComponentTheme, TabsTheme;

const _kToolbarIconColor = Color(0xFFC9CDD4);

/// 素材库管理页。
class AdMediaManagerPage extends StatelessWidget {
  const AdMediaManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<AdMediaController>(AdMediaController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final controller = context.lx.find<AdMediaController>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    Obx(
                      () => AppTabs(
                        index: controller.libraryTab.value.index,
                        selectedColor: Colors.white,
                        onChanged: (index) => controller.selectLibraryTab(
                          AdMediaLibraryTab.values[index],
                        ),
                        children: const [
                          AppTabItem(
                            child: Text(
                              '全部',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          AppTabItem(
                            child: Text(
                              '本地',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          AppTabItem(
                            child: Text(
                              '云盘',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          AppTabItem(
                            child: Text(
                              '云库',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SearchFieldBackground(
                      child: AppTextFormField(
                        width: 360,
                        hintText: '搜索素材',
                        controller: controller.searchController,
                        onSubmitted: (_) => controller.searchActiveScope(),
                        trailing: SearchIconButton(
                          onPressed: controller.searchActiveScope,
                        ),
                      ),
                    ),
                  ],
                ),
                const AppDivider.horizontal(),
                Obx(() {
                  final mediaType = controller.mediaType.value;
                  final customerId = controller.customerId.value;
                  final resolution = controller.resolution.value;
                  final fileFormat = controller.fileFormat.value;
                  return Row(
                    spacing: 8,
                    children: [
                      AppSelect<int?>(
                        value: mediaType,
                        hintText: '媒体类型',
                        clearable: true,
                        minWidth: 180,
                        options: controller.mediaTypeOptions.toList(),
                        onChanged: (value) => controller.setFilters(
                          customerId: customerId,
                          mediaType: value,
                          resolution: resolution,
                          fileFormat: fileFormat,
                        ),
                      ).width(180),
                      AppCombobox<int?>(
                        // 选中/清空会增减 TextField.features；上游缩减 features 时会 RangeError，
                        // 用 key 强制重建规避（待上游 TextField.didUpdateWidget 修复）。
                        key: ValueKey(
                          'media-customer-'
                          '${customerId != null}-'
                          '${controller.customerOptions.length}',
                        ),
                        value: customerId,
                        hintText: '选择客户',
                        clearable: true,
                        minWidth: 180,
                        displayMode: AppComboboxDisplayMode.token,
                        options: controller.customerOptions.toList(),
                        onChanged: (value) => controller.setFilters(
                          customerId: value,
                          mediaType: mediaType,
                          resolution: resolution,
                          fileFormat: fileFormat,
                        ),
                      ).width(180),
                      AppSelect<String?>(
                        value: resolution,
                        hintText: '分辨率',
                        clearable: true,
                        minWidth: 180,
                        options: controller.resolutionOptions.toList(),
                        onChanged: (value) => controller.setFilters(
                          customerId: customerId,
                          mediaType: mediaType,
                          resolution: value,
                          fileFormat: fileFormat,
                        ),
                      ).width(180),
                      AppSelect<String?>(
                        value: fileFormat,
                        hintText: '文件格式',
                        clearable: true,
                        minWidth: 180,
                        options: controller.fileFormatOptions.toList(),
                        onChanged: (value) => controller.setFilters(
                          customerId: customerId,
                          mediaType: mediaType,
                          resolution: resolution,
                          fileFormat: value,
                        ),
                      ).width(180),
                      AppButton.outline(
                        onPressed: controller.resetFilters,
                        child: const Text('重置'),
                      ),
                    ],
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
            child: Row(
              spacing: 16,
              children: [
                _FolderPanel(controller: controller).width(240),
                const AppDivider.vertical(padding: EdgeInsets.zero),
                _GridPanel(
                  controller: controller,
                  onDelete: (item) => showAdMediaDeleteDialog(
                    context,
                    controller: controller,
                    item: item,
                  ),
                  onRename: (item) => showAdMediaRenameDialog(
                    context,
                    controller: controller,
                    item: item,
                  ),
                ).expanded(),
              ],
            ),
          ).expanded(),
        ],
      ),
    );
  }
}

class _FolderPanel extends StatelessWidget {
  const _FolderPanel({required this.controller});

  final AdMediaController controller;

  Object _nodeId(AdContentCategoryEntity node) {
    final int? categoryId = node.category_id;
    if (categoryId != null && categoryId != 0) {
      return AdMediaController.categoryFolderId(categoryId);
    }
    return AdMediaController.allFolderId;
  }

  int _nodeCount(AdContentCategoryEntity node) => node.total ?? node.count ?? 0;

  AppAsyncTreeNode<AdContentCategoryEntity> _toTreeNode(
    AdContentCategoryEntity node,
  ) {
    final children = node.children ?? const <AdContentCategoryEntity>[];
    return AppAsyncTreeNode<AdContentCategoryEntity>(
      id: _nodeId(node),
      data: node,
      hasChildren: children.isNotEmpty,
      children: [for (final child in children) _toTreeNode(child)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final AdContentCategoryEntity? rootNode = controller.categoryRoot.value;
      final List<AppAsyncTreeNode<AdContentCategoryEntity>> nodes =
          rootNode == null ? const [] : [_toTreeNode(rootNode)];
      final Object selectedId =
          controller.selectedFolderId.value ?? AdMediaController.allFolderId;
      final loading = controller.categoryLoading.value;

      return Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText.title('文件夹列表'),
          if (loading && nodes.isEmpty)
            const Center(child: AppCircularProgressIndicator()).expanded()
          else if (nodes.isEmpty)
            const Center(child: AppEmptyState()).expanded()
          else
            AppAsyncTree<AdContentCategoryEntity>(
              nodes: nodes,
              itemSpacing: 8,
              selectionExtent: AppTreeSelectionExtent.parent,
              selectedId: selectedId,
              initialExpandedIds: {AdMediaController.allFolderId},
              padding: EdgeInsets.zero,
              onSelected: (node) {
                if (node.id == AdMediaController.allFolderId) {
                  controller.selectAllFolderForActiveScope();
                  return;
                }
                controller.selectFolderForActiveScope(node.data);
              },
              itemBuilder: (context, details) {
                return AppTreeItem(
                  expandable: details.node.expandable,
                  leading: Image.asset(
                    'assets/images/media_folder_icon.png',
                    width: 24,
                    height: 24,
                    filterQuality: FilterQuality.medium,
                  ),
                  trailing: Align(
                    child: Text('${_nodeCount(details.node.data)}'),
                  ),
                  onPressed: details.select,
                  onExpand: details.node.expandable
                      ? details.setExpanded
                      : null,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      details.node.data.name ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ).expanded(),
        ],
      );
    });
  }
}

class _GridPanel extends StatelessWidget {
  const _GridPanel({
    required this.controller,
    required this.onDelete,
    required this.onRename,
  });

  final AdMediaController controller;
  final ValueChanged<AdMediaEntity> onDelete;
  final ValueChanged<AdMediaEntity> onRename;

  static const double _gridGap = 16;

  /// 网格 item 总高度（含底部信息区）。
  static const double _itemHeight = 270;
  static const double _cardBottomHeight = 64;

  /// 缩略图区高度：总高减去底部信息，保证比例按此推算宽度。
  static double get _thumbHeight => _itemHeight - _cardBottomHeight;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.activeState;
      final items = List<AdMediaEntity>.of(state.items);
      final ratio = controller.thumbRatio.value;

      return Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPageShellInsetH),
              child: AppControlMetricsScope(
                metrics: AppControlMetricsScope.resolve(context).copyWith(height: 32, buttonHeight: 32),
                child: Row(
                spacing: 8,
                children: [
                  // 待上游：AppTabs 暴露 containerPadding 后去掉 ComponentTheme。
                  shad.ComponentTheme(
                    data: const shad.TabsTheme(containerPadding: EdgeInsets.all(2)),
                    child: AppTabs(
                      index: ratio.index,
                      // 容器 2×2 + 竖向 6.5×2 + 文字 ≈ 32，与右侧按钮等高。
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
                      selectedColor: Colors.white,
                      selectedTextColor: ShadcnTheme.of(context).colorScheme.primary,
                      onChanged: (index) => controller.thumbRatio.value =
                          AdMediaThumbRatio.values[index],
                      children: const [
                        AppTabItem(child: Text('1:1')),
                        AppTabItem(child: Text('4:3')),
                        AppTabItem(child: Text('16:9')),
                      ],
                    ),
                  ),
                  Obx(
                    () => AppButton.primary(
                      color: const Color(0xFF00A0EC),
                      onPressed: controller.uploading.value
                          ? null
                          : () => showAdMediaAddDialog(
                              context: context,
                              controller: controller,
                              scope: controller.activeScope,
                            ),
                      leading: Icon(
                        controller.uploading.value
                            ? AppLucideIcons.loaderCircle
                            : AppLucideIcons.plus,
                        size: 16,
                      ),
                      child: const Text('添加'),
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final titleDir = controller.titleSort.value;
                    final timeDir = controller.createTimeSort.value;
                    final colors = ShadcnTheme.of(context).colorScheme;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        AppIconButton(
                          icon: Icon(
                            titleDir == 'asc'
                                ? AppLucideIcons.arrowUpAZ
                                : AppLucideIcons.arrowDownAZ,
                            size: 20,
                            color: titleDir != null
                                ? colors.primary
                                : _kToolbarIconColor,
                          ),
                          tooltip: switch (titleDir) {
                            'desc' => '按名称降序',
                            'asc' => '按名称升序',
                            _ => '按名称排序',
                          },
                          onPressed: () => controller.toggleToolbarSort(
                            AdMediaToolbarSort.name,
                          ),
                        ),
                        AppIconButton(
                          icon: Icon(
                            AppLucideIcons.clockArrowDown,
                            size: 20,
                            color: timeDir != null
                                ? colors.primary
                                : _kToolbarIconColor,
                          ),
                          tooltip: switch (timeDir) {
                            'desc' => '按时间降序',
                            'asc' => '按时间升序',
                            _ => '按时间排序',
                          },
                          onPressed: () => controller.toggleToolbarSort(
                            AdMediaToolbarSort.time,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              ),
          ),
          Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.loading.value && items.isEmpty)
                const Center(child: AppCircularProgressIndicator()).expanded()
              else if (items.isEmpty)
                const Center(child: AppEmptyState()).expanded()
              else
                LoadMoreListener(
                  onLoadMore: controller.loadMoreActive,
                  child: FixedSizeGrid(
                    itemWidth: _thumbHeight * ratio.layoutFactor,
                    itemHeight: _itemHeight,
                    spacing: _gridGap,
                    padding: kGridShellPad,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _MediaCard(
                        item: item,
                        onDelete: () => onDelete(item),
                        onRename: () => onRename(item),
                      );
                    },
                  ),
                ).expanded(),
              if (state.loading.value && items.isNotEmpty)
                const AppCircularProgressIndicator().center(),
            ],
          ).expanded(),
        ],
      );
    });
  }
}

class _MediaCard extends StatelessWidget {
  static const Color metaColor = Color(0xFF6B7280);

  const _MediaCard({
    required this.item,
    required this.onDelete,
    required this.onRename,
  });

  final AdMediaEntity item;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final String resolution = adMediaResolution(item);
    final String? resolutionLabel = resolution == '-' ? null : resolution;
    final String? format = item.file_format?.trim().isNotEmpty == true
        ? item.file_format!.trim().toUpperCase()
        : null;
    final String duration = item.media_type == 2
        ? adMediaDurationClock(item.duration)
        : '';
    final String size = adMediaFileSizeLabel(item.file_size);
    final isWeb = adMediaIsWebType(item.media_type);
    final showPlay = adMediaShowPlayOverlay(item.media_type);

    return AppMotion.lift(
      cursor: SystemMouseCursors.click,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                AppInkWell(
                  onDoubleTap: () =>
                      showAdMediaPreviewDialog(context: context, media: item),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MediaThumb(
                        path: resolveAdMediaGridThumbPath(item),
                        isWeb: isWeb,
                      ),
                      if (resolutionLabel != null || format != null)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              spacing: 6,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (resolutionLabel != null)
                                  MediaThumbOverlayTextBadge(
                                    label: resolutionLabel,
                                  ),
                                if (format != null)
                                  MediaThumbOverlayTextBadge(label: format),
                              ],
                            ),
                          ),
                        ),
                      if (showPlay)
                        const Center(child: MediaThumbPlayOverlay()),
                      if (duration.isNotEmpty)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: MediaThumbOverlayTextBadge(label: duration),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: MediaThumbDeleteButton(onPressed: onDelete),
                  ),
                ),
              ],
            ).expanded(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                spacing: 6,
                children: [
                  Row(
                    children: [
                      AppText.label(
                        item.title ?? item.media_no ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).expanded(),
                      MediaEditIcon(onPressed: onRename, color: metaColor),
                    ],
                  ),
                  Row(
                    children: [
                      AppText.caption(
                        item.customer_name?.trim().isNotEmpty == true
                            ? item.customer_name!.trim()
                            : '-',
                        style: const TextStyle(color: metaColor),
                      ).expanded(),
                      if (size.isNotEmpty)
                        AppText.caption(
                          size,
                          style: const TextStyle(color: metaColor),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({required this.path, this.isWeb = false});

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
            size: 34,
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
              width: 20,
              height: 20,
              child: AppCircularProgressIndicator(),
            ),
          );
        }
        if (state.extendedImageLoadState == LoadState.failed) {
          return ColoredBox(
            color: const Color(0xFFE8EEF3),
            child: Center(
              child: Icon(AppLucideIcons.imageOff, size: 34, color: hintColor),
            ),
          );
        }
        return null;
      },
    );
  }
}
