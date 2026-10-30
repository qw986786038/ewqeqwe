import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show DateTimeRange;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lemon_x/lemon_x.dart';
// ignore: unused_import
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad show ComponentTheme, TabsTheme;
import 'package:yidivination/bokong/entity/order/order_customer_entity.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/ad_customer_order_info_sidebar.dart';
import 'package:yidivination/bokong/widget/ad_file_info_sidebar.dart';
import 'package:yidivination/bokong/widget/customer_avatar_icon.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/load_more_listener.dart';
import 'package:yidivination/bokong/widget/page_breadcrumb.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';
import 'package:yidivination/bokong/theme/theme.dart';

import 'add/orders_create_dialog.dart';
import 'order_detail/order_detail_page.dart';
import 'orders_controller.dart';

/// 执行中 / 在线语义绿（对齐 [AppBadge.success] / [kOrderPlayRunningColor]）。
const _kOnlineColor = kOrderPlayRunningColor;

/// 已完播语义蓝。
const _kEndedColor = kOrderPlayEndedColor;
const _kToolbarIconColor = Color(0xFFC9CDD4);
const _kToolbarHeight = 32.0;

/// 客户订单页（列表单文件：筛选 + 网格 / 列表）。
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<OrdersController>(OrdersController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final controller = context.lx.find<OrdersController>();
    final colors = ShadcnTheme.of(context).colorScheme;

    return Scaffold(
      body: Obx(() {
        final showFilters = controller.filtersVisible.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Obx(() {
                final status = controller.statusTabFilter.value;
                final index = switch (status) {
                  'running' => 1,
                  'ended' => 2,
                  'pending' => 3,
                  _ => 0,
                };
                final selectedTone = switch (index) {
                  1 => _kOnlineColor,
                  2 => _kEndedColor,
                  3 => colors.destructive,
                  _ => colors.foreground,
                };
                return Row(
                  spacing: 16,
                  children: [
                    AppTabs(
                      index: index,
                      selectedColor: Colors.white,
                      selectedTextColor: selectedTone,
                      onChanged: (i) => controller.selectStatusTab(switch (i) {
                        1 => 'running',
                        2 => 'ended',
                        3 => 'pending',
                        _ => null,
                      }),
                      children: [
                        AppTabItem(
                          child: Text(
                            '全部 ${controller.totalCount}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        AppTabItem(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Image.asset(
                                'assets/images/order_tab_running.png',
                                width: 14,
                                height: 14,
                                filterQuality: FilterQuality.medium,
                              ),
                              Text(
                                '执行中 ${controller.runningCount}',
                                style: const TextStyle(
                                  color: _kOnlineColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppTabItem(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Image.asset(
                                'assets/images/order_tab_ended.png',
                                width: 14,
                                height: 14,
                                filterQuality: FilterQuality.medium,
                              ),
                              Text(
                                '已完播 ${controller.endedCount}',
                                style: const TextStyle(
                                  color: _kEndedColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppTabItem(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Image.asset(
                                'assets/images/order_tab_pending.png',
                                width: 14,
                                height: 14,
                                filterQuality: FilterQuality.medium,
                              ),
                              Text(
                                '已暂停 ${controller.pendingCount}',
                                style: TextStyle(
                                  color: colors.destructive,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SearchFieldBackground(
                      child: AppTextFormField(
                        hintText: '搜索关键字',
                        width: 280,
                        controller: controller.keywordController,
                        onSubmitted: (_) => controller.search(),
                        trailing: SearchIconButton(
                          onPressed: controller.search,
                        ),
                      ),
                    ),
                    Obx(() {
                      final visible = controller.filtersVisible.value;
                      void toggle() =>
                          controller.filtersVisible.value = !visible;
                      return !visible
                          ? AppButton.selected(
                              color: const Color(0xFF00A0EC),
                              onPressed: toggle,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 6,
                                children: [
                                  Icon(AppLucideIcons.listFilter, size: 16),
                                  Text('筛选'),
                                ],
                              ),
                            )
                          : AppButton.outline(
                              leading: const Icon(
                                AppLucideIcons.listFilter,
                                size: 16,
                              ),
                              onPressed: toggle,
                              child: const Text('筛选'),
                            );
                    }),
                    AppButton.primary(
                      color: const Color(0xFF00A0EC),
                      leading: const Icon(AppLucideIcons.plus, size: 16),
                      onPressed: () async {
                        final ok = await showOrdersCreateDialog(context);
                        if (ok) controller.loadCustomers(toPage: 1);
                      },
                      child: const Text('新建'),
                    ),
                  ],
                );
              }),
            if (showFilters) ...[
                    const AppDivider.horizontal(),
              Obx(() {
                final dateStart = controller.selectedDateStart.value;
                final dateEnd = controller.selectedDateEnd.value;
                final industry = controller.selectedIndustry.toList();
                final statusType = controller.selectedStatusType.value;
                final range = (dateStart != null && dateEnd != null)
                    ? DateTimeRange(dateStart, dateEnd)
                    : null;
                return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: [
                        AppDatePicker.range(
                          rangeValue: range,
                          hintText: '日期范围',
                          onRangeChanged: (value) => controller.setFilters(
                            dateStart: value?.start,
                            dateEnd: value?.end,
                            industry: industry,
                            statusType: statusType,
                          ),
                        ).width(220),
                    AppCascadeSelect<int>(
                      options: controller.industryOptions.toList(),
                      value: industry,
                      hintText: '所属行业',
                      clearable: true,
                      changeOnSelect: true,
                      columnWidth: 150,
                          onChanged: (value) => controller.setFilters(
                            dateStart: dateStart,
                            dateEnd: dateEnd,
                            industry: value,
                            statusType: statusType,
                          ),
                        ).width(240),
                        AppSelect<String>(
                          value: statusType,
                          hintText: '订单状态类型',
                          clearable: true,
                          minWidth: 180,
                          options: OrdersController.statusOptions,
                          onChanged: (value) => controller.setFilters(
                            dateStart: dateStart,
                            dateEnd: dateEnd,
                            industry: industry,
                            statusType: value,
                          ),
                        ).width(180),
                        AppButton.outline(
                          onPressed: controller.resetFilters,
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                );
              }),
            ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(8),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: AppControlMetricsScope(
                      metrics: AppControlMetricsScope.resolve(context).copyWith(height: _kToolbarHeight, buttonHeight: _kToolbarHeight),
                      child: Row(
                spacing: 8,
                children: [
                  Obx(() {
                    final customer = controller.gridCustomer;
                    // 卡片 / 列表二级追加客户。
                    final inCustomer = customer != null;
                    final name = customer?.customer_name?.trim();
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: PageBreadcrumb(
                        padding: EdgeInsets.zero,
                        children: [
                          if (inCustomer)
                            AppInkWell(
                              hoverOpacity: 0,
                              pressedOpacity: 0,
                              onPressed: controller.exitCustomerGrid,
                              child: const Text(
                                '订单管理',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          else
                            const Text(
                              '订单管理',
                              style: TextStyle(fontSize: 18),
                            ),
                          if (inCustomer)
                            Text(
                              name != null && name.isNotEmpty ? name : '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                        ],
                      ),
                    );
                  }),
                  const Spacer(),
                  Obx(() {
                    final mode = controller.viewMode.value;
                    // 侧边栏开关仅网格视图有意义（一级客户 / 二级订单）。
                    if (mode != OrderViewMode.grid) {
                      return const SizedBox.shrink();
                    }
                    final visible = controller.customerSidebarVisible.value;
                    final theme = ShadcnTheme.of(context);
                    const size = _kToolbarHeight;
                    final selectedRadius = BorderRadius.circular(
                      theme.radiusMd,
                    );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        AppTooltip(
                          tooltip: (_) => Text(visible ? '隐藏侧边栏' : '显示侧边栏'),
                          child: AppInkWell(
                            hoverOpacity: 0,
                            pressedOpacity: 0,
                            borderRadius: selectedRadius,
                            onPressed: () =>
                                controller.customerSidebarVisible.value =
                                    !visible,
                            child: SvgPicture.asset(
                              visible
                                  ? 'assets/images/lcd/sidebar_toggle_on.svg'
                                  : 'assets/images/sidebar_toggle_off.svg',
                              width: size,
                              height: size,
                            ),
                          ),
                        ),
                        AppDivider.vertical(height: 25),
                      ],
                    );
                  }),
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
                            OrdersToolbarSort.name,
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
                            OrdersToolbarSort.time,
                          ),
                        ),
                      ],
                    );
                  }),
                  // 卡片 / 列表切换暂时隐藏，固定列表模式。
                  // Obx(() {
                  //   final index =
                  //       controller.viewMode.value == OrderViewMode.list ? 1 : 0;
                  //   // 待上游：AppTabs 暴露 containerPadding 后去掉 ComponentTheme。
                  //   return shad.ComponentTheme(
                  //     data: const shad.TabsTheme(
                  //       containerPadding: EdgeInsets.all(2),
                  //     ),
                  //     child: AppTabs(
                  //       index: index,
                  //       iconOnly: true,
                  //       padding: const EdgeInsets.all(4),
                  //       selectedColor: Colors.white,
                  //       selectedTextColor: ShadcnTheme.of(
                  //         context,
                  //       ).colorScheme.primary,
                  //       unselectedForegroundColor: _kToolbarIconColor,
                  //       onChanged: (i) => controller.setViewMode(
                  //         i == 1 ? OrderViewMode.list : OrderViewMode.grid,
                  //       ),
                  //       children: const [
                  //         AppTabItem(
                  //           child: _ViewModeIcon('assets/images/lcd/view_mode_card.svg'),
                  //         ),
                  //         AppTabItem(
                  //           child: _ViewModeIcon('assets/images/lcd/view_mode_list.svg'),
                  //         ),
                  //       ],
                  //     ),
                  //   );
                  // }),
                    ],
                    ),
                    ),
                  ),
                  const AppDivider.horizontal(indent: 12, endIndent: 12),
                  Expanded(
              child: Obx(() {
                final mode = controller.viewMode.value;
                final panel = switch (mode) {
                  OrderViewMode.grid => _GridPanel(controller: controller),
                  OrderViewMode.list => _ListPanel(controller: controller),
                };
                // 列表：无侧边栏。网格一级：客户信息。网格二级：订单信息。
                final showSidebar =
                    mode == OrderViewMode.grid &&
                    controller.customerSidebarVisible.value;
                final atOrderLevel = controller.isGridAtOrderLevel;

                return Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    panel.expanded(),
                    if (showSidebar && !atOrderLevel)
                      _CustomerSidebar(controller: controller),
                    if (showSidebar && atOrderLevel)
                      _OrderSidebar(controller: controller),
                  ],
                );
              }),
            ),
                ],
              ),
            ).expanded(),
          ],
        );
      }),
    );
  }
}

// ignore: unused_element
class _ViewModeIcon extends StatelessWidget {
  const _ViewModeIcon(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SvgPicture.asset(asset, width: 20, height: 20, colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn));
  }
}

class _GridPanel extends StatelessWidget {
  const _GridPanel({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final customer = controller.gridCustomer;
      final customers = controller.customers.toList();
      final orders = controller.gridOrders.toList();
      // 必须在 Obx builder 内读取：LayoutBuilder 的 builder 在 layout 阶段才跑，订不到 Rx。
      final customersLoading = controller.loading.value;
      final ordersLoading = controller.ordersLoading.value;
      final loadingMore = customer == null ? customersLoading && customers.isNotEmpty : ordersLoading && orders.isNotEmpty;

      return Column(
        spacing: 12,
        children: [
          Expanded(
            child: LoadMoreListener(
              onLoadMore: controller.loadMore,
              child: LayoutBuilder(
              builder: (context, constraints) {
                if (customer == null) {
                  if (customersLoading && customers.isEmpty) {
                    return const Center(child: Text('加载中…'));
                  }
                  if (customers.isEmpty) {
                    return const Center(child: AppEmptyState());
                  }
                  return FixedSizeGrid(
                    itemWidth: OrdersController.customerItemWidth,
                    itemHeight: OrdersController.itemHeight,
                    spacing: OrdersController.itemSpacing,
                    padding: kGridShellPad,
                    itemCount: customers.length,
                    itemBuilder: (context, index) => _CustomerCard(
                      controller: controller,
                      customer: customers[index],
                    ),
                  );
                }
                if (ordersLoading && orders.isEmpty) {
                  return const Center(child: Text('加载中…'));
                }
                if (orders.isEmpty) {
                  return const Center(child: AppEmptyState());
                }
                final color = controller.colorOf(customer);
                final industryColor = controller.industryColorOf(customer);
                final customerName = customer.customer_name ?? '-';
                final industryLabel = customer.industry ?? '';
                return FixedSizeGrid(
                  itemWidth: OrdersController.customerItemWidth,
                  itemHeight: OrdersController.orderItemHeight,
                  spacing: OrdersController.itemSpacing,
                  padding: kGridShellPad,
                  itemCount: orders.length,
                  itemBuilder: (context, index) => _OrderCard(
                    controller: controller,
                    order: orders[index],
                    color: color,
                    industryColor: industryColor,
                    industryLabel: industryLabel,
                    customerName: customerName,
                    customerId: customer.customer_id,
                  ),
                );
              },
            ),
            ),
          ),
          if (loadingMore) const AppCircularProgressIndicator().center(),
        ],
      );
    });
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final customer = controller.gridCustomer;
      final customers = controller.customers.toList();
      final orders = controller.gridOrders.toList();
      final customersLoading = controller.loading.value;
      final ordersLoading = controller.ordersLoading.value;
      final loadingMore = customer == null ? customersLoading && customers.isNotEmpty : ordersLoading && orders.isNotEmpty;

      final theme = AppTheme.of(context);
      return Column(
        spacing: 12,
        children: [
          Expanded(
            // 待上游：AppDataGrid 增加 rowHeight，避免为列表再套 AppShadcnScope。
            child: AppShadcnScope(
              config: theme.copyWith(
                dataGrid: AppDataGridMetrics(
                  rowHeight: customer == null ? 64 : 56,
                  columnHeight: theme.dataGrid.columnHeight,
                  filterHeight: theme.dataGrid.filterHeight,
                  footerHeight: theme.dataGrid.footerHeight,
                  horizontalPadding: theme.dataGrid.horizontalPadding,
                  fontSize: theme.dataGrid.fontSize,
                ),
              ),
              provideMaterialHost: false,
              syncMaterialTheme: false,
              child: LoadMoreListener(
                onLoadMore: controller.loadMore,
                child: LayoutBuilder(
                builder: (context, constraints) {
                  if (customer == null) {
                    if (customersLoading && customers.isEmpty) {
                      return const Center(child: Text('加载中…'));
                    }
                    // 待上游：AppDataGrid 的 cellBuilder 内容未继承 cellTextStyle，回收后去掉这层。
                    return DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 14),
                      child: AppDataGrid<OrderCustomerEntity>.local(
                      height: constraints.maxHeight,
                      rows: customers,
                      rowKey: (row) =>
                          '${row.customer_id ?? row.customer_no ?? ''}',
                      onRowDoubleTap: controller.enterCustomerGrid,
                      sortable: false,
                      showInternalDividers: false,
                      headerBackgroundColor: kTableHeaderBackground,
                      headerTextStyle: kTableHeaderTextStyle,
                      stripeColor: kTableStripeBackground,
                      empty: const Center(child: AppEmptyState()),
                      columns: [
                        AppDataGridColumn(
                          id: 'index',
                          title: '序号',
                          value: controller.customerSerialOf,
                          type: AppDataGridColumnType.number,
                          width: 100,
                          minWidth: 100,
                          sortable: false,
                          filterable: false,
                        ),
                        AppDataGridColumn(
                          id: 'customerName',
                          title: '用户名称',
                          value: (row) => row.customer_name ?? '',
                          minWidth: 200,
                          widthMode: AppDataGridColumnWidthMode.fill,
                          alignment: Alignment.centerLeft,
                          titleAlignment: Alignment.centerLeft,
                          cellBuilder: (context, row, value) => Row(
                            spacing: 12,
                            children: [
                              const CustomerAvatarIcon(size: 42),
                              Expanded(
                                child: Text(
                                  row.customer_name?.trim().isNotEmpty == true
                                      ? row.customer_name!.trim()
                                      : '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppDataGridColumn(
                          id: 'orderCount',
                          title: '订单数量',
                          value: OrdersController.customerFolderCount,
                          type: AppDataGridColumnType.number,
                          width: 160,
                          cellBuilder: (context, row, value) => Center(
                            child: Text(
                              '${OrdersController.customerFolderCount(row)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        AppDataGridColumn(
                          id: 'industry',
                          title: '所属行业',
                          value: (row) => row.industry ?? '',
                          width: 210,
                          alignment: Alignment.centerLeft,
                          titleAlignment: Alignment.centerLeft,
                          cellBuilder: (context, row, value) {
                            final industry = row.industry?.trim() ?? '';
                            final subIndustry = row.sub_industry?.trim() ?? '';
                            const tagSize = _CustomerCard._tagSize;
                            const tagText = TextStyle(fontSize: 12);
                            return Row(
                              spacing: 6,
                              children: [
                                if (industry.isNotEmpty)
                                  AppBadge.custom(
                                    color: _CustomerCard._primaryTagColor,
                                    appearance: AppBadgeStyle.solid,
                                    shape: AppBadgeShape.pill,
                                    size: tagSize,
                                    child: Text(industry, style: tagText),
                                  ),
                                if (subIndustry.isNotEmpty)
                                  Flexible(
                                    child: AppBadge.custom(
                                      color: _CustomerCard._secondaryTagColor,
                                      appearance: AppBadgeStyle.solid,
                                      shape: AppBadgeShape.pill,
                                      size: tagSize,
                                      child: Text(subIndustry, style: tagText),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        AppDataGridColumn(
                          id: 'orderTime',
                          title: '最后下单时间',
                          value: (row) => row.order_time ?? '-',
                          width: 200,
                          alignment: Alignment.centerLeft,
                          titleAlignment: Alignment.centerLeft,
                          cellBuilder: (context, row, value) => Text(row.order_time ?? '-', style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                      ),
                    );
                  }

                  if (ordersLoading && orders.isEmpty) {
                    return const Center(child: Text('加载中…'));
                  }
                  // 待上游：AppDataGrid 的 cellBuilder 内容未继承 cellTextStyle，回收后去掉这层。
                  return DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 14),
                    child: AppDataGrid<OrderEntity>.local(
                    height: constraints.maxHeight,
                    rows: orders,
                    rowKey: (row) => '${row.id ?? row.order_no ?? ''}',
                    onRowDoubleTap: (row) => showOrderDetailDialog(
                      context,
                      order: row,
                      accentColor: controller.colorOf(customer),
                      industryColor: controller.industryColorOf(customer),
                      industryLabel: customer.industry ?? '',
                      customerName: customer.customer_name ?? '-',
                      customerId: customer.customer_id,
                    ),
                    sortable: false,
                    showInternalDividers: false,
                    headerBackgroundColor: kTableHeaderBackground,
                    headerTextStyle: kTableHeaderTextStyle,
                    stripeColor: kTableStripeBackground,
                    empty: const Center(child: AppEmptyState()),
                    columns: [
                      AppDataGridColumn(
                        id: 'index',
                        title: '序号',
                        value: controller.orderSerialOf,
                        type: AppDataGridColumnType.number,
                        width: 100,
                        minWidth: 100,
                        sortable: false,
                        filterable: false,
                      ),
                      AppDataGridColumn(
                        id: 'customerName',
                        title: '客户名称',
                        value: (row) =>
                            row.customer_name ?? customer.customer_name ?? '-',
                        minWidth: 180,
                        widthMode: AppDataGridColumnWidthMode.fill,
                        sortable: false,
                        filterable: false,
                        cellBuilder: (context, row, value) => Center(
                          child: Text(
                            '$value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'orderName',
                        title: '订单名称',
                        value: (row) => row.order_name ?? '',
                        minWidth: 140,
                        widthMode: AppDataGridColumnWidthMode.fill,
                        cellBuilder: (context, row, value) => Center(
                          child: Text(
                            '$value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4E5969),
                            ),
                          ),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'status',
                        title: '状态显示',
                        value: orderPlayStatusLabel,
                        minWidth: 150,
                        widthMode: AppDataGridColumnWidthMode.fill,
                        cellBuilder: (context, row, value) {
                          final status = orderPlayStatusOf(row);
                          final statusColor = orderPlayStatusColor(
                            status,
                            paused: ShadcnTheme.of(
                              context,
                            ).colorScheme.destructive,
                          );
                          return Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                Icon(
                                  AppMaterialIcons.circle,
                                  size: 8,
                                  color: statusColor,
                                ),
                                Text(
                                  orderPlayStatusLabel(row),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: statusColor,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'progress',
                        title: '订单进度',
                        value: orderProgressOf,
                        type: AppDataGridColumnType.number,
                        minWidth: 200,
                        widthMode: AppDataGridColumnWidthMode.fill,
                        cellBuilder: (context, row, value) {
                          final colors = ShadcnTheme.of(context).colorScheme;
                          final progress = orderProgressOf(row);
                          final barColor = orderPlayStatusColor(
                            orderPlayStatusOf(row),
                            paused: colors.destructive,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              spacing: 8,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: SizedBox(
                                    width: 64,
                                    height: 6,
                                    child: AppProgress(
                                      progress: progress,
                                      color: barColor,
                                      backgroundColor: colors.muted,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: AppText.caption(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: kTextPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'exclusive',
                        title: '有无排他要求',
                        value: (row) => orderHasExclusive(row) ? '有' : '无',
                        minWidth: 200,
                        widthMode: AppDataGridColumnWidthMode.fill,
                        sortable: false,
                        filterable: false,
                        cellBuilder: (context, row, value) {
                          final has = orderHasExclusive(row);
                          final colors = ShadcnTheme.of(context).colorScheme;
                          return Center(
                            child: Text(
                              has ? '有' : '无',
                              style: TextStyle(
                                fontSize: 14,
                                color: has ? colors.primary : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    ),
                  );
                },
              ),
              ),
            ),
          ),
          if (loadingMore) const AppCircularProgressIndicator().center(),
        ],
      );
    });
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.controller, required this.customer});

  final OrdersController controller;
  final OrderCustomerEntity customer;

  static const _accent = Color(0xFF00A0E9);
  static const _primaryTagColor = Color(0xFFC9CDD4);
  static const _secondaryTagColor = Color(0xFFF4F4F5);
  static const _tagSize = AppBadgeSize(
    fontSize: 12,
    height: 18,
    padding: EdgeInsets.symmetric(horizontal: 8),
    iconSize: 8,
    contentGap: 4,
  );

  @override
  Widget build(BuildContext context) {
    final industry = customer.industry?.trim() ?? '';
    final subIndustry = customer.sub_industry?.trim() ?? '';
    final count = OrdersController.customerFolderCount(customer);
    final name = customer.customer_name?.trim().isNotEmpty == true
        ? customer.customer_name!.trim()
        : '-';

    return Obx(() {
      final selected =
          controller.selectedCustomerId.value == customer.customer_id;
      const stackColor = Color(0xFF0084C7);
      const idleStackColor = Color(0xFFE5E6EB);
      const radius = BorderRadius.all(Radius.circular(16));
      final backColor = selected ? stackColor : idleStackColor;
      return AppMotion.lift(
        cursor: SystemMouseCursors.click,
        child: AppInkWell(
          hoverOpacity: 0,
          pressedOpacity: 0,
          borderRadius: radius,
          onPressed: () =>
              controller.selectCustomerFolder(customer.customer_id),
          onDoubleTap: () => controller.enterCustomerGrid(customer),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 210,
                  height: 124,
                  child: AppCard(
                    filled: true,
                    fillColor: backColor,
                    borderColor: backColor,
                    borderRadius: radius,
                    duration: const Duration(milliseconds: 220),
                    shadow: false,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 118,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: radius,
                    border: Border.all(
                      color: selected ? stackColor : const Color(0xFFE5E6EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                AppText.label(
                                  name,
                                  maxLines: 1,
                                  scrollMode: AppTextScrollMode.hover,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppText.caption(
                                  '2026-09-24 18:00',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const AppDivider.horizontal(),
                              ],
                            ),
                          ),
                          AppCornerBadge.count(
                            count: count,
                            maxCount: 9999,
                            color: _accent,
                            foregroundColor: Colors.white,
                            size: 18,
                            position: AppCornerBadgePosition.bottomRight,
                            child: SidebarAvatarIcon(
                              avatarIcon: customer.avatar_icon,
                              size: 40,
                              iconSize: 16,
                              borderRadius: 16,
                              fallbackAsset: 'assets/images/folder_icon.png',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (industry.isNotEmpty || subIndustry.isNotEmpty)
                        Row(
                          spacing: 6,
                          children: [
                            if (industry.isNotEmpty)
                              AppBadge.custom(
                                color: _primaryTagColor,
                                appearance: AppBadgeStyle.solid,
                                shape: AppBadgeShape.pill,
                                size: _tagSize,
                                child: Text(industry),
                              ),
                            if (subIndustry.isNotEmpty)
                              AppBadge.custom(
                                color: _secondaryTagColor,
                                appearance: AppBadgeStyle.solid,
                                shape: AppBadgeShape.pill,
                                size: _tagSize,
                                child: Text(subIndustry),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.controller,
    required this.order,
    required this.color,
    required this.industryColor,
    required this.industryLabel,
    required this.customerName,
    this.customerId,
  });

  final OrdersController controller;
  final OrderEntity order;
  final Color color;
  final Color industryColor;
  final String industryLabel;
  final String customerName;
  final int? customerId;

  static const _exclusiveSize = AppBadgeSize(
    fontSize: 12,
    height: 18,
    padding: EdgeInsets.symmetric(horizontal: 8),
    iconSize: 8,
    contentGap: 4,
  );

  void _openDetail(BuildContext context) {
    showOrderDetailDialog(
      context,
      order: order,
      accentColor: color,
      industryColor: industryColor,
      industryLabel: industryLabel,
      customerName: customerName,
      customerId: customerId,
    );
  }

  static bool _hasExclusive(OrderEntity order) => orderHasExclusive(order);

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final status = orderPlayStatusOf(order);
    final progress = orderProgressOf(order).clamp(0.0, 1.0);
    final title = order.order_name?.trim().isNotEmpty == true
        ? order.order_name!.trim()
        : (customerName.trim().isNotEmpty
              ? customerName.trim()
              : (order.customer_name?.trim().isNotEmpty == true
                    ? order.customer_name!.trim()
                    : '-'));
    final percent = (progress * 100).round();
    final exclusive = _hasExclusive(order);
    final orderNo = order.order_no?.trim();
    final statusColor = orderPlayStatusColor(
      status,
      paused: colors.destructive,
    );
    final statusLabel = switch (status) {
      OrderPlayStatus.running => '执行中',
      OrderPlayStatus.ended => '已完播',
      OrderPlayStatus.pending => '已暂停',
    };

    return Obx(() {
      final selected =
          orderNo != null &&
          orderNo.isNotEmpty &&
          controller.selectedOrderNo.value == orderNo;
      const stackColor = Color(0xFF0084C7);
      const idleStackColor = Color(0xFFE5E6EB);
      const radius = BorderRadius.all(Radius.circular(16));
      final backColor = selected ? stackColor : idleStackColor;
      return AppMotion.lift(
        cursor: SystemMouseCursors.click,
        child: AppInkWell(
          hoverOpacity: 0,
          pressedOpacity: 0,
          borderRadius: radius,
          onPressed: () => controller.selectOrder(order),
          onDoubleTap: () => _openDetail(context),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 210,
                  height: 124,
                  child: AppCard(
                    filled: true,
                    fillColor: backColor,
                    borderColor: backColor,
                    borderRadius: radius,
                    duration: const Duration(milliseconds: 220),
                    shadow: false,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 118,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: radius,
                    border: Border.all(
                      color: selected ? stackColor : const Color(0xFFE5E6EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          SidebarAvatarIcon(
                            avatarIcon: order.avatar_icon,
                            size: 40,
                            iconSize: 16,
                            borderRadius: 16,
                            fallbackAsset: 'assets/images/folder_icon.png',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                AppText.label(
                                  title,
                                  maxLines: 1,
                                  scrollMode: AppTextScrollMode.hover,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    Image.asset(
                                      switch (status) {
                                        OrderPlayStatus.running =>
                                          'assets/images/order_tab_running.png',
                                        OrderPlayStatus.ended =>
                                          'assets/images/order_tab_ended.png',
                                        OrderPlayStatus.pending =>
                                          'assets/images/order_tab_pending.png',
                                      },
                                      width: 14,
                                      height: 14,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const AppDivider.horizontal(),
                      const Spacer(),
                      Row(
                        spacing: 8,
                        children: [
                          AppBadge.custom(
                            color: const Color(0xFFC9CDD4),
                            appearance: AppBadgeStyle.solid,
                            shape: AppBadgeShape.pill,
                            size: _exclusiveSize,
                            child: Text(exclusive ? '排它' : '暂无'),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 4,
                              child: AppProgress(
                                progress: progress,
                                color: statusColor,
                                backgroundColor: const Color(0xFFE8E8E8),
                              ),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// 客户列表右侧栏：宽 360，由顶栏「显示 / 隐藏」控制。
class _CustomerSidebar extends StatelessWidget {
  const _CustomerSidebar({required this.controller});

  final OrdersController controller;

  OrderCustomerEntity? get _selectedCustomer {
    final id = controller.selectedCustomerId.value;
    if (id == null) return null;
    for (final item in controller.customers) {
      if (item.customer_id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = controller.sidebarFileList.value;
      final basic = file?.device_basic_data;
      final customer = _selectedCustomer;
      final title = () {
        final info = file?.file_info?.trim();
        if (info != null && info.isNotEmpty) return info;
        final name = customer?.customer_name?.trim();
        if (name != null && name.isNotEmpty) return name;
        return '全部客户';
      }();
      final total = basic?.total_devices ?? 0;
      final size98 = basic?.count_98inch ?? total;
      final size86 = basic?.count_86inch ?? 0;
      final online = basic?.online_devices ?? 0;
      final offline = basic?.offline_devices ?? 0;
      final abnormal = basic?.abnormal_devices ?? 0;

      return AdFileInfoSidebar(
        showCard: false,
        kind: AdFileInfoSidebarKind.customer,
        file: file,
        loading: controller.sidebarFileListLoading.value,
        title: title,
        total: total,
        size98: size98,
        size86: size86,
        online: online,
        offline: offline,
        abnormal: abnormal,
        onAddTag: controller.addCustomerTag,
        onDeleteTag: controller.deleteCustomerTag,
        iconUpdateType: SidebarAvatarIconType.customer,
        iconUpdateId: controller.sidebarCustomerId,
        avatarIcon: customer?.avatar_icon ?? file?.avatar_icon,
        onIconUpdated: (icon) {
          final current = controller.sidebarFileList.value;
          if (current != null) {
            current.avatar_icon = icon;
            controller.sidebarFileList.value = null;
            controller.sidebarFileList.value = current;
          }
          final selected = _selectedCustomer;
          if (selected != null) {
            selected.avatar_icon = icon;
            controller.customers.refresh();
          }
        },
      );
    });
  }
}

/// 订单二级右侧栏：宽 360，由顶栏「显示 / 隐藏」控制。
class _OrderSidebar extends StatelessWidget {
  const _OrderSidebar({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = controller.sidebarOrderFile.value;
      final order = controller.selectedOrder;
      final customer = controller.gridCustomer;
      final fallbackTitle = () {
        final name = file?.file_info?.name?.trim();
        if (name != null && name.isNotEmpty) return name;
        final orderName = order?.order_name?.trim();
        if (orderName != null && orderName.isNotEmpty) return orderName;
        final customerName = customer?.customer_name?.trim();
        if (customerName != null && customerName.isNotEmpty)
          return customerName;
        return '-';
      }();

      return AdCustomerOrderInfoSidebar(
        file: file,
        loading: controller.sidebarOrderFileLoading.value,
        fallbackTitle: fallbackTitle,
        avatarIcon: order?.avatar_icon ?? file?.file_info?.avatar_icon,
        iconUpdateId: order?.id,
        onAddTag: controller.addOrderTag,
        onDeleteTag: controller.deleteOrderTag,
        onIconUpdated: (icon) {
          final current = controller.sidebarOrderFile.value;
          if (current?.file_info != null) {
            current!.file_info!.avatar_icon = icon;
            controller.sidebarOrderFile.value = null;
            controller.sidebarOrderFile.value = current;
          }
          final selected = controller.selectedOrder;
          if (selected != null) {
            selected.avatar_icon = icon;
            controller.gridOrders.refresh();
          }
        },
      );
    });
  }
}
