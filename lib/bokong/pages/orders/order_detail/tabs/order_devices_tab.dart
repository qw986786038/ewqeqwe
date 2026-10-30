import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/widget/customer_avatar_icon.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/lcd_device_grid_card.dart';
import 'package:yidivination/bokong/widget/lcd_device_status_icon.dart';
import 'package:yidivination/bokong/widget/order_release_material_card.dart';

import '../../../lcd_devices/lcd_devices_controller.dart';
import '../order_detail_controller.dart';
import '../order_detail_insets.dart';
import '../order_detail_summary_header.dart';

/// 投放设备 Tab。
///
/// - **卡片模式**：顶栏摘要 + 物料 chips/卡片 +「关联设备信息」设备卡片网格
/// - **列表模式**：隐藏顶栏摘要与物料卡片，仅 chips + 设备表格
class OrderDevicesTab extends StatelessWidget {
  const OrderDevicesTab({required this.controller, super.key});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isCard =
          controller.devicesViewMode.value == OrderDevicesViewMode.grid;
      return Column(
        spacing: 20,
        children: [
          if (isCard) OrderDetailSummaryHeader(controller: controller),
          if (isCard)
            Column(
              spacing: 20,
              children: [
                _MaterialsSection(controller: controller),
                _DevicesCardSection(controller: controller),
              ],
            ).scroll(padding: kOrderDetailPagePadding).expanded()
          else
            Padding(
              padding: kOrderDetailPagePadding,
              child: _DevicesListSection(controller: controller),
            ).expanded(),
        ],
      );
    });
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index =
          controller.devicesViewMode.value == OrderDevicesViewMode.list ? 1 : 0;
      return AppTabs(
        index: index,
        iconOnly: true,
        selectedColor: Colors.white,
        selectedTextColor: kIconButtonForeground,
        onChanged: (i) => controller.devicesViewMode.value = i == 1
            ? OrderDevicesViewMode.list
            : OrderDevicesViewMode.grid,
        children: const [
          AppTabItem(child: Icon(AppLucideIcons.layoutGrid, size: 16)),
          AppTabItem(child: Icon(AppLucideIcons.list, size: 16)),
        ],
      );
    });
  }
}

/// 发布单物料胶囊筛选，与 [OrderDetailController.selectedRelease] 联动。
class _ReleaseOrderTabs extends StatelessWidget {
  const _ReleaseOrderTabs({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.releaseRevision.value;
      final materials = controller.releaseItems;
      if (materials.isEmpty) return const SizedBox.shrink();

      final selectedKey = controller.selectedReleaseKey.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (var i = 0; i < materials.length; i++)
              _ReleaseMaterialCapsuleChip(
                label:
                    '物料${i + 1} (${controller.deviceCountOf(materials[i])}台)',
                selected: controller.releaseRowKey(materials[i]) == selectedKey,
                onTap: () => controller.selectRelease(materials[i]),
              ),
          ],
        ),
      );
    });
  }
}

class _ReleaseMaterialCapsuleChip extends StatelessWidget {
  const _ReleaseMaterialCapsuleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(999));
    return AppInkWell(
      onPressed: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.08)
              : colors.muted,
          borderRadius: radius,
          border: selected ? Border.all(color: colors.primary) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? colors.primary : const Color(0xFF4E5969),
          ),
        ),
      ),
    );
  }
}

/// 卡片模式：物料筛选 chips + 物料缩略卡片。
class _MaterialsSection extends StatelessWidget {
  const _MaterialsSection({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: BorderRadius.circular(24),
      borderWidth: 0,
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final _ = controller.releaseRevision.value;
        final materials = controller.releaseItems;
        final selected = controller.selectedRelease;

        return Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                const AppText.title('快速筛选物料'),
                if (materials.isNotEmpty)
                  Expanded(child: _ReleaseOrderTabs(controller: controller))
                else
                  const Spacer(),
                _ViewModeToggle(controller: controller),
              ],
            ),
            if (materials.isEmpty || selected == null)
              SizedBox(
                height: OrderReleaseMaterialCard.height,
                child: const Center(child: AppEmptyState()),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OrderReleaseMaterialCard(
                  key: ValueKey(controller.releaseRowKey(selected)),
                  item: selected,
                  selected: true,
                  onTap: () => controller.selectRelease(selected),
                  onDoubleTap: () => showAdMediaPreviewDialog(
                    context: context,
                    media: orderReleaseToAdMedia(selected),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

Widget _devicesBody(OrderDetailController controller) {
  final _ = controller.releaseRevision.value;
  final selectedKey = controller.selectedReleaseKey.value;
  final devices = controller.selectedMaterialDevices;
  if (selectedKey == null) {
    return const SizedBox(height: 240, child: Center(child: AppEmptyState()));
  }
  if (devices.isEmpty) {
    return const SizedBox(height: 240, child: Center(child: AppEmptyState()));
  }
  return switch (controller.devicesViewMode.value) {
    OrderDevicesViewMode.grid => _DevicesGridBody(devices: devices),
    OrderDevicesViewMode.list => _DevicesList(devices: devices),
  };
}

/// 卡片模式：关联设备信息 + 设备卡片网格。
class _DevicesCardSection extends StatelessWidget {
  const _DevicesCardSection({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: BorderRadius.circular(24),
      borderWidth: 0,
      padding: const EdgeInsets.all(20),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText.title('关联设备信息'),
          Obx(() => _devicesBody(controller)),
        ],
      ),
    );
  }
}

/// 列表模式：chips + 视图切换 + 设备表格（无顶栏摘要、无物料卡片）。
class _DevicesListSection extends StatelessWidget {
  const _DevicesListSection({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return SizedBox.expand(
      child: AppCard(
        borderRadius: BorderRadius.circular(24),
        borderWidth: 0,
        padding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                Icon(AppLucideIcons.images, size: 18, color: colors.primary),
                const AppText.title('快速筛选物料'),
                Expanded(child: _ReleaseOrderTabs(controller: controller)),
                _ViewModeToggle(controller: controller),
              ],
            ),
            Obx(() => _devicesBody(controller)).expanded(),
          ],
        ),
      ),
    );
  }
}

class _DevicesGridBody extends StatelessWidget {
  const _DevicesGridBody({required this.devices});

  final List<OrderDeviceEntry> devices;

  @override
  Widget build(BuildContext context) {
    return FixedSizeGrid(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemWidth: LcdDevicesController.itemMinWidth,
      itemHeight: LcdDevicesController.deviceItemHeight,
      spacing: LcdDevicesController.itemSpacing,
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final entry = devices[index];
        final device = entry.device;
        return LcdDeviceGridCard(
          device: device,
          displayName: device.displayName.isNotEmpty
              ? device.displayName
              : entry.propertyName,
          mediaAddress: entry.mediaLocation?.trim().isNotEmpty == true
              ? entry.mediaLocation!.trim()
              : (device.media_address?.trim() ?? ''),
        );
      },
    );
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.devices});

  final List<OrderDeviceEntry> devices;

  String _regionLabel(String region) {
    final separator = region.indexOf('·');
    if (separator >= 0 && separator < region.length - 1) {
      return region.substring(separator + 1);
    }
    return region;
  }

  List<AppDataGridColumn<OrderDeviceEntry>> get _columns => [
    AppDataGridColumn(
      id: 'index',
      title: '序号',
      value: (row) => devices.indexOf(row) + 1,
      type: AppDataGridColumnType.number,
      width: 72,
      minWidth: 56,
      sortable: false,
      filterable: false,
    ),
    AppDataGridColumn(
      id: 'icon',
      title: '图标',
      value: (row) => row.propertyName,
      width: 64,
      minWidth: 56,
      sortable: false,
      filterable: false,
      cellBuilder: (context, row, value) =>
          const Center(child: CustomerAvatarIcon(size: 32)),
    ),
    AppDataGridColumn(
      id: 'propertyName',
      title: '物业名称',
      value: (row) => row.propertyName,
      width: 160,
    ),
    AppDataGridColumn(
      id: 'region',
      title: '行政区域',
      value: (row) => _regionLabel(row.device.displayRegion),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'address',
      title: '详细地址',
      value: (row) => row.device.displayAddress,
      widthMode: AppDataGridColumnWidthMode.fill,
      alignment: Alignment.centerLeft,
      titleAlignment: Alignment.centerLeft,
    ),
    AppDataGridColumn(
      id: 'floor',
      title: '楼栋号',
      value: (row) => row.device.displayFloor,
      width: 100,
    ),
    AppDataGridColumn(
      id: 'mediaLocation',
      title: '媒体位置',
      value: (row) => row.mediaLocation ?? '',
      width: 120,
    ),
    AppDataGridColumn(
      id: 'status',
      title: '状态显示',
      value: (row) => row.device.displayStatusLabel,
      width: 100,
      cellBuilder: (context, row, value) {
        final status = row.device.displayStatus;
        return Align(
          alignment: Alignment.center,
          child: switch (status) {
            LcdDeviceStatus.online => AppBadge.success(
              appearance: AppBadgeStyle.plain,
              leading: const LcdDeviceStatusIcon.online(size: 12),
              child: const Text('在线'),
            ),
            LcdDeviceStatus.offline => AppBadge.secondary(
              appearance: AppBadgeStyle.plain,
              leading: const LcdDeviceStatusIcon.offline(size: 12),
              child: const Text('离线'),
            ),
            LcdDeviceStatus.abnormal => AppBadge.destructive(
              appearance: AppBadgeStyle.plain,
              leading: const LcdDeviceStatusIcon.abnormal(size: 12),
              child: const Text('异常'),
            ),
          },
        );
      },
    ),
    AppDataGridColumn(
      id: 'ordersToday',
      title: '订单数量(今日)',
      value: (row) => '${row.ordersToday}次',
      width: 140,
    ),
    AppDataGridColumn(
      id: 'publishRate',
      title: '上刊率(今日)',
      value: (row) => '${row.publishRate}%',
      width: 110,
      cellBuilder: (context, row, value) => Align(
        alignment: Alignment.center,
        child: AppText.label(
          '${row.publishRate}%',
          style: TextStyle(
            color: row.publishRate >= 90
                ? const Color(0xFF389E0D)
                : row.publishRate >= 80
                ? const Color(0xFFD48806)
                : const Color(0xFFCF1322),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AppDataGrid<OrderDeviceEntry>.local(
          columns: _columns,
          rows: devices,
          rowKey: (row) => row.device.uiKey,
          height: constraints.maxHeight,
          sortable: false,
          showInternalDividers: false,
          headerBackgroundColor: kTableHeaderBackground,
          headerTextStyle: kTableHeaderTextStyle,
          stripeColor: kTableStripeBackground,
          empty: const Center(child: const AppEmptyState()),
        );
      },
    );
  }
}
