import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/device_detail/device_detail_title_icon.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/order_release_material_card.dart';

import '../order_detail_summary_header.dart';
import '../order_detail_controller.dart';
import '../order_detail_insets.dart';
import '../dialogs/order_materials_dialog.dart';
import '../dialogs/order_release_edit_dialog.dart';

/// 客户订单 Tab：顶栏摘要 + 发布单 / 排它 / 物料。
class OrderOrderTab extends StatelessWidget {
  const OrderOrderTab({required this.controller, super.key});

  final OrderDetailController controller;

  List<AppDataGridColumn<OrderItemEntity>> get _columns => [
    AppDataGridColumn(
      id: 'startAt',
      title: '上刊时间',
      value: (row) => _publishStart(row),
    ),
    AppDataGridColumn(
      id: 'endAt',
      title: '下刊时间',
      value: (row) => _publishEnd(row),
    ),
    AppDataGridColumn(
      id: 'days',
      title: '订单天数',
      value: (row) => row.order_days == null ? '-' : '${row.order_days}天',
    ),
    AppDataGridColumn(
      id: 'format',
      title: '播放形式',
      value: (row) => _playRuleLabel(row, controller.order),
      cellBuilder: (context, row, value) {
        final colors = ShadcnTheme.of(context).colorScheme;
        final label = value?.toString() ?? '-';
        if (label == '-') return Text(label).center();
        return AppBadge.custom(
          color: colors.primary,
          appearance: AppBadgeStyle.soft,
          size: _badgeSize,
          child: Text(label),
        ).center();
      },
    ),
    AppDataGridColumn(
      id: 'period',
      title: '播放时段',
      value: (row) => _playPeriodLabel(row, controller.order),
      width: 230,
      widthMode: AppDataGridColumnWidthMode.fixed,
    ),
    AppDataGridColumn(
      id: 'durationSec',
      title: '广告片时长',
      value: (row) => row.duration == null ? '-' : '${row.duration}秒',
    ),
    AppDataGridColumn(
      id: 'dailyFreq',
      title: '日播频次',
      value: (row) {
        final freq = row.order_frequency ?? controller.order.order_frequency;
        return freq == null ? '-' : '$freq次/日';
      },
      cellBuilder: (context, row, value) {
        final label = value?.toString() ?? '-';
        if (label == '-') return Text(label).center();
        return AppBadge.outline(size: _badgeSize, child: Text(label)).center();
      },
    ),
    AppDataGridColumn(
      id: 'playModel',
      title: '播放模式',
      value: (row) => row.play_model,
      cellBuilder: (context, row, value) => switch (row.play_model) {
        1 => AppBadge.custom(
          color: const Color(0xFF4F6BED),
          appearance: AppBadgeStyle.soft,
          size: _badgeSize,
          child: const Text('正常播放'),
        ),
        2 => AppBadge.custom(
          color: const Color(0xFFF97316),
          appearance: AppBadgeStyle.soft,
          size: _badgeSize,
          child: const Text('弹性播放'),
        ),
        _ => const Text('-'),
      }.center(),
    ),
    AppDataGridColumn(
      id: 'execStatus',
      title: '执行状态',
      value: (row) => row.status,
      width: 100,
      cellBuilder: (context, row, value) =>
          _execStatusBadge(row.status).center(),
    ),
    AppDataGridColumn(
      id: 'actions',
      title: '操作',
      value: (row) => controller.releaseRowKey(row),
      width: 120,
      sortable: false,
      filterable: false,
      cellBuilder: (context, row, value) {
        final offShelf = controller.isReleaseOffShelf(row);
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            AppIconButton(
              icon: Image.asset(
                offShelf
                    ? 'assets/images/order_shelf_on.png'
                    : 'assets/images/order_shelf_off.png',
                width: 18,
                height: 18,
                filterQuality: FilterQuality.medium,
              ),
              tooltip: offShelf ? '上刊' : '下刊',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outline,
              backgroundColor: Colors.white,
              onPressed: () => offShelf
                  ? controller.setReleaseOnShelf(row)
                  : controller.setReleaseOffShelf(row),
            ),
            AppIconButton(
              icon: Image.asset(
                'assets/images/order_release_edit.png',
                width: 18,
                height: 18,
                filterQuality: FilterQuality.medium,
              ),
              tooltip: '编辑',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outline,
              backgroundColor: Colors.white,
              onPressed: () => showOrderReleaseEditDialog(
                context,
                controller: controller,
                item: row,
              ),
            ),
            AppIconButton(
              icon: Image.asset(
                'assets/images/order_release_delete.png',
                width: 18,
                height: 18,
                filterQuality: FilterQuality.medium,
              ),
              tooltip: '删除',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outline,
              backgroundColor: Colors.white,
              onPressed: () => _confirmDeleteRelease(context, row),
            ),
          ],
        ).center();
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = ShadcnTheme.of(context).colorScheme;

    return Column(
      spacing: 20,
      children: [
        OrderDetailSummaryHeader(controller: c),
        Column(
          spacing: 20,
          children: [
            AppCard(
              borderRadius: BorderRadius.circular(24),
              borderWidth: 0,
              child: AppDescriptions.custom(
                title: const Text('发布单信息'),
                titleIcon: deviceDetailTitleIcon(
                  context,
                  AppLucideIcons.fileText,
                ),
                actions: AppButton.outline(
                  size: AppButtonSize.small,
                  config: const AppButtonConfig(height: 28),
                  leading: const Icon(AppLucideIcons.plus, size: 14),
                  onPressed: () => showOrderReleaseAddDialog(
                    context,
                    controller: controller,
                  ),
                  child: const Text('添加发布单'),
                ),
                child: Obx(() {
                  final selectedKey = c.selectedReleaseKey.value;
                  final _ = c.releaseRevision.value;
                  final releases = c.releaseItems;
                  return AppDataGrid<OrderItemEntity>.local(
                    columns: _columns,
                    rows: releases,
                    rowKey: c.releaseRowKey,
                    columnWidthMode: AppDataGridColumnWidthMode.fill,
                    shrinkWrap: true,
                    sortable: false,
                    showInternalDividers: false,
                    headerBackgroundColor: kTableHeaderBackground,
                    headerTextStyle: kTableHeaderTextStyle,
                    stripeColor: kTableStripeBackground,
                    selectionMode: AppDataGridSelectionMode.single,
                    selectedKeys: <Object>{?selectedKey},
                    autoSelectFirstRow:
                        selectedKey == null && releases.isNotEmpty,
                    onSelectionChanged: c.selectReleaseRows,
                    empty: const Center(child: AppEmptyState()),
                  );
                }),
              ),
            ),
            // 排它随发布单：行业来自 content_group；数值绑选中发布单字段。
            // 改动后防抖调用 edit_order_detail，并带回发布单其它字段。
            Obx(() {
              final _ = c.exclusiveRevision.value;
              final release = c.selectedRelease;
              final industries = c.industryItems.toList();
              final releaseKey = c.selectedReleaseKey.value;
              final loopOn = c.loopRuleOn.value;
              final industryOn = c.industryRuleOn.value;
              final exclusiveOn = c.exclusiveRuleOn.value;
              final industryIds = c.resolvedIndustryIds(release);
              final hasRelease = release != null;
              final industryOptions = <AppOption<int>>[
                for (final item in industries)
                  if (item.id != null)
                    AppOption<int>(
                      value: item.id!,
                      label: item.category_name ?? '-',
                    ),
              ];

              return AppCard(
                borderRadius: BorderRadius.circular(24),
                borderWidth: 0,
                child: AppDescriptions(
                  // 标题图标底到首行复选框约 20（标题栏图标下余 4）。
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  title: const Text('排它要求'),
                  titleIcon: deviceDetailTitleIcon(
                    context,
                    AppLucideIcons.tags,
                  ),
                  layout: AppDescriptionLayout.vertical,
                  columns: 3,
                  minColumnWidth: 220,
                  spacing: 24,
                  contentGap: 8,
                  items: [
                    AppDescriptionItem(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          AppCheckbox(
                            state: loopOn
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            onChanged: !hasRelease
                                ? null
                                : (state) => c.setLoopRuleOn(
                                    state == CheckboxState.checked,
                                  ),
                          ),
                          const Text('循环间隔'),
                        ],
                      ),
                      value: Row(
                        spacing: 8,
                        children: [
                          AppNumberInput(
                            key: ValueKey('loop-$releaseKey'),
                            value: c.resolvedLoopRule(release),
                            min: 0,
                            max: 1200,
                            enabled: hasRelease && loopOn,
                            onChanged: (value) => c.setReleaseLoopRule(value),
                          ),
                          AppText.caption(
                            '秒',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    AppDescriptionItem(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          AppCheckbox(
                            state: industryOn
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            onChanged: !hasRelease
                                ? null
                                : (state) => c.setIndustryRuleOn(
                                    state == CheckboxState.checked,
                                  ),
                          ),
                          const Text('相邻行业排它'),
                        ],
                      ),
                      value: SizedBox(
                        width: 220,
                        // key 只跟发布单走；勿把已选 id 写进 key，否则下拉未关时
                        // Obx/key 变化会拆掉锚点，触发 deactivated ancestor 断言。
                        child: AppMultiSelect<int>(
                          key: ValueKey(
                            'industry-$releaseKey-${industries.length}',
                          ),
                          maxVisibleOptions: 1,
                          options: industryOptions,
                          value: industryIds,
                          enabled: hasRelease && industryOn,
                          onChanged: (value) =>
                              c.setReleaseExclusiveIndustry(value?.toList()),
                        ),
                      ),
                    ),
                    AppDescriptionItem(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          AppCheckbox(
                            state: exclusiveOn
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            onChanged: !hasRelease
                                ? null
                                : (state) => c.setExclusiveRuleOn(
                                    state == CheckboxState.checked,
                                  ),
                          ),
                          const Text('前后排它'),
                        ],
                      ),
                      value: Row(
                        spacing: 8,
                        children: [
                          AppNumberInput(
                            key: ValueKey('exclusive-$releaseKey'),
                            value: c.resolvedExclusiveRule(release),
                            min: 0,
                            max: 120,
                            enabled: hasRelease && exclusiveOn,
                            onChanged: (value) =>
                                c.setReleaseExclusiveRule(value),
                          ),
                          AppText.caption(
                            '秒数 (1-120)',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            AppCard(
              borderRadius: BorderRadius.circular(24),
              borderWidth: 0,
              child: AppDescriptions.custom(
                title: const Text('广告物料'),
                titleIcon: deviceDetailTitleIcon(
                  context,
                  AppLucideIcons.images,
                ),
                actions: AppButton.outline(
                  config: const AppButtonConfig(height: 28),
                  onPressed: () =>
                      showOrderMaterialsDialog(context, controller: controller),
                  child: const Text('查看全部'),
                ),
                child: Obx(() {
                  final selectedKey = c.selectedReleaseKey.value;
                  final _ = c.releaseRevision.value;
                  final mediaItems = c.releaseItems;
                  final industryLabel = c.displayIndustryLabel;
                  final industryTag = industryLabel == '-'
                      ? null
                      : industryLabel;
                  if (mediaItems.isEmpty) {
                    return const SizedBox(
                      height: OrderReleaseMaterialCard.height,
                      child: Center(child: AppEmptyState()),
                    );
                  }
                  return SizedBox(
                    height: OrderReleaseMaterialCard.height,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 16,
                        children: [
                          for (final item in mediaItems)
                            OrderReleaseMaterialCard(
                              item: item,
                              industryLabel: industryTag,
                              selected: c.releaseRowKey(item) == selectedKey,
                              onTap: () => c.selectRelease(item),
                              onDoubleTap: () => showAdMediaPreviewDialog(
                                context: context,
                                media: orderReleaseToAdMedia(item),
                              ),
                              onEdit: () => showOrderReleaseEditDialog(
                                context,
                                controller: c,
                                item: item,
                              ),
                              onDelete: () =>
                                  _confirmDeleteRelease(context, item),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ).scroll(padding: kOrderDetailPagePadding).expanded(),
      ],
    );
  }

  void _confirmDeleteRelease(BuildContext context, OrderItemEntity item) {
    final title = orderReleaseMaterialTitle(item);
    showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => AppDeleteConfirmAlertDialog(
        title: const Text('删除发布单'),
        content: Text('确定要删除「$title」吗？此操作不可撤销。'),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close<void>(dialogContext),
            child: const Text('取消'),
          ),
          AppButton.destructive(
            onPressed: () async {
              await controller.deleteRelease(item);
              if (dialogContext.mounted) {
                AppOverlay.close<void>(dialogContext);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

String _displayDate(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '-';
  return trimmed.split(' ').first;
}

/// 标签总高 24（内容 20 + 上下内边距各 2）。
final _badgeSize = AppBadgeSize.normal.copyWith(height: 20);

Widget _execStatusBadge(int? status) {
  return switch (status) {
    0 => AppBadge.secondary(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _badgeSize,
      child: const Text('未执行'),
    ),
    1 => AppBadge.success(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _badgeSize,
      child: const Text('执行中'),
    ),
    2 => AppBadge.secondary(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _badgeSize,
      child: const Text('已完结'),
    ),
    3 => AppBadge.secondary(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _badgeSize,
      child: const Text('已下刊'),
    ),
    _ => const Text('-'),
  };
}

String _publishStart(OrderItemEntity item) =>
    _displayDate(item.send_time ?? item.cover_start_time ?? item.start_time);

String _publishEnd(OrderItemEntity item) =>
    _displayDate(item.send_end_time ?? item.cover_end_time ?? item.end_time);

String _playRuleLabel(OrderItemEntity item, OrderEntity order) {
  if (item.play_rule == 1) return '轮播';
  if (item.play_rule == 2) return '定屏播放';
  final fromOrder = order.play_rule_label?.trim();
  if (fromOrder != null && fromOrder.isNotEmpty) return fromOrder;
  return item.play_rule?.toString() ?? '-';
}

String _playPeriodLabel(OrderItemEntity item, OrderEntity order) {
  final period = item.play_period ?? order.play_period;
  if (period == null) return '-';
  final start = period.start_time?.trim();
  final end = period.end_time?.trim();
  if ((start == null || start.isEmpty) && (end == null || end.isEmpty)) {
    return '-';
  }
  return '${start ?? '-'} - ${end ?? '-'}';
}
