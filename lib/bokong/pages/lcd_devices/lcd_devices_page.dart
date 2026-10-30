import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad show ButtonStyleOverride, ComponentTheme, TabsTheme;
import 'package:yidivination/bokong/entity/lcd/ad_office_list_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/add/lcd_devices_add_dialog.dart';
import 'package:yidivination/bokong/pages/lcd_devices/device_detail/device_detail_page.dart';
import 'package:yidivination/bokong/pages/lcd_devices/dialogs/lcd_devices_control_dialogs.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/ad_file_info_sidebar.dart';
import 'package:yidivination/bokong/widget/amap/amap_widget.dart';
import 'package:yidivination/bokong/widget/fair_share_row.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/load_more_listener.dart';
import 'package:yidivination/bokong/widget/office_card_icon.dart';
import 'package:yidivination/bokong/widget/page_breadcrumb.dart';
import 'package:yidivination/bokong/widget/lcd_device_info_sidebar.dart';
import 'package:yidivination/bokong/widget/lcd_device_status_icon.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

/// 在线状态文案/圆点色（与 [AppBadge.success] 语义一致）。
const _kOnlineColor = Color(0xFF16A34A);
const _kToolbarIconColor = Color(0xFFC9CDD4);
const _kToolbarHeight = 32.0;

/// 设备列表地址类列（城市 / 行政区域 / 详细地址 / 楼栋 / 媒体位置）文字色。
const _kSecondaryCellStyle = TextStyle(
  fontSize: 14,
  color: Color(0xFF4E5969),
);

void _openDeviceDetail(BuildContext context, LcdDevicesController controller, LcdDeviceEntity device) {
  showLcdDeviceDetailDialog(context, device: device, accentColor: controller.colorOf(device), propertyName: controller.propertyNameOf(device));
}

/// 选中 1 台用单项调节弹窗；选中多于 1 台 / 多项楼栋用批量控制。
void _openDeviceControl(BuildContext context, LcdDevicesController controller, {required VoidCallback single}) {
  final selectedCount = controller.isOfficeGridLevel ? controller.selectedOfficeFolderIds.length : controller.selectedDeviceIds.length;
  if (selectedCount > 1) {
    showLcdDevicesBatchControlDialog(context, controller);
    return;
  }
  single();
}

/// 设备管理页。
class LcdDevicesPage extends StatelessWidget {
  const LcdDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<LcdDevicesController>(LcdDevicesController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final controller = context.lx.find<LcdDevicesController>();
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
                  Row(
                    spacing: 16,
                    children: [
                      Obx(() {
                        final status = controller.statusFilter.value;
                        final index = status == 1
                            ? 1
                            : status == 2
                            ? 2
                            : 0;
                        return AppTabs(
                          index: index,
                          selectedColor: Colors.white,
                          // 按当前 Tab 保留在线绿 / 离线灰，避免白底把子树滤成黑字。
                          // 选中态染色（白 X 被抹掉）须上游去掉 ColorFiltered，勿换 PNG。
                          selectedTextColor: index == 1 ? _kOnlineColor : kIconButtonForeground,
                          onChanged: (i) => controller.selectStatusFilter(switch (i) {
                            1 => 1,
                            2 => 2,
                            _ => null,
                          }),
                          children: [
                            AppTabItem(child: Text('全部 ${controller.totalCount}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            AppTabItem(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  const LcdDeviceStatusIcon.online(size: 14),
                                  Text('在线 ${controller.onlineCount}', style: const TextStyle(color: _kOnlineColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            AppTabItem(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  const LcdDeviceStatusIcon.offline(size: 14),
                                  Text('离线 ${controller.offlineCount}', style: const TextStyle(color: kIconButtonForeground, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      SearchFieldBackground(
                        child: AppTextFormField(
                          hintText: '搜索关键字',
                          width: 280,
                          controller: controller.keywordController,
                          onSubmitted: (_) => controller.search(),
                          trailing: SearchIconButton(onPressed: controller.search),
                        ),
                      ),
                      Obx(() {
                        final visible = controller.filtersVisible.value;
                        void toggle() => controller.filtersVisible.value = !visible;
                        return !visible
                            ? AppButton.selected(
                                color: const Color(0xFF00A0EC),
                                onPressed: toggle,
                                child: const Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [Icon(AppLucideIcons.listFilter, size: 16), Text('筛选')]),
                              )
                            : AppButton.outline(leading: const Icon(AppLucideIcons.listFilter, size: 16), onPressed: toggle, child: const Text('筛选'));
                      }),
                      AppButton.primary(
                        color: const Color(0xFF00A0EC),
                        leading: const Icon(AppLucideIcons.plus, size: 16),
                        onPressed: () => showLcdDevicesAddDialog(context, listController: controller),
                        child: const Text('新建'),
                      ),
                    ],
                  ),
                  if (showFilters) ...[
                    const AppDivider.horizontal(),
                    Obx(() {
                      final cityId = controller.selectedCityId.value;
                      final districtId = controller.selectedDistrictId.value;
                      final officeId = controller.selectedOfficeId.value;
                      final mediaAddress = controller.selectedMediaAddress.value;
                      final mediaSize = controller.selectedMediaSize.value;
                      final sound = controller.selectedSound.value;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 8,
                          children: [
                            AppSelect<int>(
                              value: cityId,
                              hintText: '城市',
                              clearable: true,
                              minWidth: 180,
                              options: controller.cityOptions,
                              onChanged: (value) =>
                                  controller.setFilters(cityId: value, districtId: districtId, officeId: officeId, mediaAddress: mediaAddress, mediaSize: mediaSize, sound: sound),
                            ).width(180),
                            AppSelect<int>(
                              key: ValueKey(cityId),
                              value: districtId,
                              hintText: '行政区',
                              clearable: true,
                              minWidth: 180,
                              options: controller.districtOptionsFor(cityId),
                              onChanged: (value) =>
                                  controller.setFilters(cityId: cityId, districtId: value, officeId: officeId, mediaAddress: mediaAddress, mediaSize: mediaSize, sound: sound),
                            ).width(180),
                            AppCombobox<int>(
                              // 选中/清空会增减 TextField.features；上游缩减 features 时会 RangeError，
                              // 用 key 强制重建规避（待上游 TextField.didUpdateWidget 修复）。
                              key: ValueKey(
                                'lcd-office-'
                                '${officeId != null}-'
                                '${controller.officeOptions.length}',
                              ),
                              value: officeId,
                              hintText: '楼栋',
                              clearable: true,
                              minWidth: 180,
                              displayMode: AppComboboxDisplayMode.token,
                              options: controller.officeOptions,
                              onChanged: (value) =>
                                  controller.setFilters(cityId: cityId, districtId: districtId, officeId: value, mediaAddress: mediaAddress, mediaSize: mediaSize, sound: sound),
                            ).width(180),
                            AppCombobox<String>(
                              key: ValueKey(
                                'lcd-media-address-'
                                '${mediaAddress != null}-'
                                '${controller.mediaAddressOptions.length}',
                              ),
                              value: mediaAddress,
                              hintText: '媒体位置',
                              clearable: true,
                              minWidth: 180,
                              displayMode: AppComboboxDisplayMode.token,
                              options: controller.mediaAddressOptions,
                              onChanged: (value) =>
                                  controller.setFilters(cityId: cityId, districtId: districtId, officeId: officeId, mediaAddress: value, mediaSize: mediaSize, sound: sound),
                            ).width(180),
                            AppSelect<String>(
                              value: mediaSize,
                              hintText: '媒体尺寸',
                              clearable: true,
                              minWidth: 180,
                              options: controller.mediaSizeOptions,
                              onChanged: (value) =>
                                  controller.setFilters(cityId: cityId, districtId: districtId, officeId: officeId, mediaAddress: mediaAddress, mediaSize: value, sound: sound),
                            ).width(180),
                            AppSelect<String>(
                              value: sound,
                              hintText: '是否可播放声音',
                              clearable: true,
                              minWidth: 180,
                              options: LcdDevicesController.soundOptions,
                              onChanged: (value) =>
                                  controller.setFilters(cityId: cityId, districtId: districtId, officeId: officeId, mediaAddress: mediaAddress, mediaSize: mediaSize, sound: value),
                            ).width(180),
                            AppButton.outline(onPressed: controller.resetFilters, child: const Text('重置')),
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
                          final office = controller.gridOffice;
                          // 卡片 / 列表二级追加楼栋；地图不保留下钻态。
                          final inOffice = office != null && controller.viewMode.value != LcdDeviceViewMode.map;
                          final name = office?.name?.trim();
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: PageBreadcrumb(
                              padding: EdgeInsets.zero,
                              children: [
                                if (inOffice)
                                  AppInkWell(
                                    hoverOpacity: 0,
                                    pressedOpacity: 0,
                                    onPressed: controller.exitOfficeGrid,
                                    child: const Text('设备管理', style: TextStyle(fontSize: 18)),
                                  )
                                else
                                  const Text('设备管理', style: TextStyle(fontSize: 18)),
                                if (inOffice)
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
                          final officeLevel = controller.isOfficeGridLevel;
                          final showSelection = controller.isAtDeviceLevel || officeLevel;
                          if (!showSelection) return const SizedBox.shrink();
                          final selectedCount = officeLevel ? controller.selectedOfficeFolderIds.length : controller.selectedDeviceIds.length;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: '已选中 '),
                                    TextSpan(
                                      text: '$selectedCount',
                                      style: TextStyle(color: colors.primary),
                                    ),
                                    const TextSpan(text: ' 项'),
                                  ],
                                ),
                              ),
                              // 待上游：AppButton.outline 暴露 backgroundColor 后去掉 ButtonStyleOverride。
                              shad.ButtonStyleOverride(
                                decoration: (context, states, value) => value is BoxDecoration ? value.copyWith(color: const Color(0xFFEEEEF0)) : value,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    AppButton.outline(onPressed: officeLevel ? controller.selectAllOffices : controller.selectAllDevices, child: const Text('全选')),
                                    if (selectedCount > 0)
                                      AppButton.outline(onPressed: officeLevel ? controller.clearOfficeSelection : controller.clearDeviceSelection, child: const Text('取消选中')),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                        Obx(() {
                          final mode = controller.viewMode.value;
                          // 侧边栏只在卡片（网格）视图：楼栋层看楼栋信息，设备层看设备信息。
                          if (mode != LcdDeviceViewMode.grid) {
                            return const SizedBox.shrink();
                          }
                          final visible = controller.officeSidebarVisible.value;
                          final theme = ShadcnTheme.of(context);
                          const size = _kToolbarHeight;
                          final selectedRadius = BorderRadius.circular(theme.radiusMd);
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
                                  onPressed: () => controller.officeSidebarVisible.value = !visible,
                                  child: SvgPicture.asset(
                                    visible ? 'assets/images/lcd/sidebar_toggle_on.svg' : 'assets/images/sidebar_toggle_off.svg',
                                    width: size,
                                    height: size,
                                  ),
                                ),
                              ),
                              AppDivider.vertical(height: 25),
                            ],
                          );
                        }),
                        AppIconButton(
                          icon: Image.asset('assets/images/device_control/restart.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                          tooltip: '重启',
                          onPressed: () => _openDeviceControl(context, controller, single: () => showLcdDeviceRestartDialog(context, controller)),
                        ),
                        AppIconButton(
                          icon: Image.asset('assets/images/device_control/volume.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                          tooltip: '音量',
                          onPressed: () => _openDeviceControl(context, controller, single: () => showLcdDeviceVolumeDialog(context, controller)),
                        ),
                        AppIconButton(
                          icon: Image.asset('assets/images/device_control/brightness.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                          tooltip: '亮度',
                          onPressed: () => _openDeviceControl(context, controller, single: () => showLcdDeviceBrightnessDialog(context, controller)),
                        ),
                        AppIconButton(
                          icon: Image.asset('assets/images/device_control/power.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                          tooltip: '屏幕开关',
                          onPressed: () => _openDeviceControl(context, controller, single: () => showLcdDeviceScreenPowerDialog(context, controller)),
                        ),
                        AppIconButton(icon: Image.asset('assets/images/device_control/power_schedule.png', width: 20, height: 20, filterQuality: FilterQuality.medium), tooltip: '开关机时间', onPressed: () => showLcdDevicesPowerScheduleDialog(context, controller)),
                        AppDivider.vertical(height: 25),
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
                                  titleDir == 'asc' ? AppLucideIcons.arrowUpAZ : AppLucideIcons.arrowDownAZ,
                                  size: 20,
                                  color: titleDir != null ? colors.primary : _kToolbarIconColor,
                                ),
                                tooltip: switch (titleDir) {
                                  'desc' => '按名称降序',
                                  'asc' => '按名称升序',
                                  _ => '按名称排序',
                                },
                                onPressed: () => controller.toggleToolbarSort(LcdDevicesToolbarSort.name),
                              ),
                              AppIconButton(
                                icon: Icon(AppLucideIcons.clockArrowDown, size: 20, color: timeDir != null ? colors.primary : _kToolbarIconColor),
                                tooltip: switch (timeDir) {
                                  'desc' => '按时间降序',
                                  'asc' => '按时间升序',
                                  _ => '按时间排序',
                                },
                                onPressed: () => controller.toggleToolbarSort(LcdDevicesToolbarSort.time),
                              ),
                            ],
                          );
                        }),
                        AppDivider.vertical(height: 25),
                        Obx(() {
                          final mode = controller.viewMode.value;
                          final index = switch (mode) {
                            LcdDeviceViewMode.grid => 0,
                            LcdDeviceViewMode.list => 1,
                            LcdDeviceViewMode.map => 2,
                          };
                          // 待上游：AppTabs 暴露 containerPadding 后去掉 ComponentTheme。
                          return shad.ComponentTheme(
                            data: const shad.TabsTheme(containerPadding: EdgeInsets.all(2)),
                            child: AppTabs(
                              index: index,
                              iconOnly: true,
                              padding: const EdgeInsets.all(4),
                              selectedColor: Colors.white,
                              selectedTextColor: ShadcnTheme.of(context).colorScheme.primary,
                              unselectedForegroundColor: _kToolbarIconColor,
                              onChanged: (i) => controller.setViewMode(switch (i) {
                                1 => LcdDeviceViewMode.list,
                                2 => LcdDeviceViewMode.map,
                                _ => LcdDeviceViewMode.grid,
                              }),
                              children: const [
                                AppTabItem(child: _ViewModeIcon('assets/images/lcd/view_mode_card.svg')),
                                AppTabItem(child: _ViewModeIcon('assets/images/lcd/view_mode_list.svg')),
                                AppTabItem(child: _ViewModeIcon('assets/images/lcd/view_mode_map.svg')),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    ),
                  ),
                  const AppDivider.horizontal(indent: 12, endIndent: 12),
                  Expanded(
                    child: Obx(() {
                      // 始终订阅选中集合，避免多选时侧边栏依赖丢失。
                      final selectedIds = controller.selectedDeviceIds.toList();
                      final selectedOfficeIds = controller.selectedOfficeFolderIds.toList();
                      final mode = controller.viewMode.value;
                      final panel = switch (mode) {
                        LcdDeviceViewMode.grid => _GridPanel(controller: controller),
                        LcdDeviceViewMode.list => _ListPanel(controller: controller),
                        LcdDeviceViewMode.map => _MapPanel(controller: controller),
                      };
                      // 地图 / 列表：无侧边栏。网格楼栋层：楼栋信息。网格设备层：设备信息。
                      if (mode != LcdDeviceViewMode.grid) return panel;

                      final sidebarVisible = controller.officeSidebarVisible.value;
                      final atOfficeLevel = !controller.isAtDeviceLevel;
                      final showOfficeSidebar = atOfficeLevel && sidebarVisible;
                      final showDeviceSidebar = !atOfficeLevel && sidebarVisible;
                      // 仅单选展示该设备；未选 / 多选同为空态（侧边栏始终保留）。
                      final device = selectedIds.length == 1 ? controller.firstSelectedDevice : null;

                      return Row(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          panel.expanded(),
                          if (showOfficeSidebar) _OfficeSidebar(controller: controller, selectedCount: selectedOfficeIds.length),
                          if (showDeviceSidebar)
                            LcdDeviceInfoSidebar(
                              device: device,
                              playPreview: controller.playPreview.value,
                              playPreviewLoading: controller.playPreviewLoading.value,
                              onIconUpdated: (icon) {
                                device?.avatar_icon = icon;
                                controller.devices.refresh();
                              },
                            ),
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

class _ViewModeIcon extends StatelessWidget {
  const _ViewModeIcon(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SvgPicture.asset(asset, width: 20, height: 20, colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn));
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.controller});

  final LcdDevicesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final office = controller.gridOffice;
      final offices = controller.offices.toList();
      final devices = controller.devices.toList();
      final officesLoading = controller.officesLoading.value;
      final devicesLoading = controller.loading.value;
      final selectedOffices = {
        for (final id in controller.selectedOfficeFolderIds) '$id',
      };
      final selectedDevices = controller.selectedDeviceIds.toSet();
      final loadingMore = office == null ? officesLoading && offices.isNotEmpty : devicesLoading && devices.isNotEmpty;

      final theme = AppTheme.of(context);
      return Column(
        spacing: 12,
        children: [
          Expanded(
            // 待上游：AppDataGrid 增加 rowHeight，避免为列表再套 AppShadcnScope。
            child: AppShadcnScope(
              config: theme.copyWith(
                dataGrid: AppDataGridMetrics(
                  rowHeight: office == null ? 64 : 56,
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
                  if (office == null) {
                    if (officesLoading && offices.isEmpty) {
                      return const Center(child: Text('加载中…'));
                    }
                    // 待上游：AppDataGrid 的 cellBuilder 内容未继承 cellTextStyle，回收后去掉这层。
                    return DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 14),
                      child: AppDataGrid<AdOfficeListItemEntity>.local(
                      height: constraints.maxHeight,
                      rows: offices,
                      rowKey: (row) => '${row.office_id}',
                      selectionMode: AppDataGridSelectionMode.multiple,
                      selectedKeys: selectedOffices,
                      onSelectionChanged: controller.updateSelectedOffices,
                      onRowDoubleTap: controller.enterOfficeGrid,
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
                          value: controller.officeSerialOf,
                          type: AppDataGridColumnType.number,
                          width: 72,
                          minWidth: 56,
                          sortable: false,
                          filterable: false,
                        ),
                        AppDataGridColumn(
                          id: 'officeName',
                          title: '写字楼名称',
                          value: (row) => row.name ?? '',
                          minWidth: 200,
                          widthMode: AppDataGridColumnWidthMode.fill,
                          alignment: Alignment.centerLeft,
                          titleAlignment: Alignment.centerLeft,
                          cellBuilder: (context, row, value) => Row(
                            spacing: 12,
                            children: [
                              SidebarAvatarIcon(
                                avatarIcon: withDefaultAvatar(row.avatar_icon),
                                size: 40,
                                iconSize: 24,
                                borderRadius: 14,
                                fallbackAsset: 'assets/images/folder_icon.png',
                                useTemplateBackground: true,
                              ),
                              Expanded(
                                child: Text(
                                  row.name?.trim().isNotEmpty == true
                                      ? row.name!.trim()
                                      : '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppDataGridColumn(
                          id: 'deviceCount',
                          title: '设备数量',
                          value: (row) => row.deviceCount ?? 0,
                          type: AppDataGridColumnType.number,
                          width: 160,
                          cellBuilder: (context, row, value) => Center(
                            child: Text(
                              '${row.deviceCount ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        AppDataGridColumn(
                          id: 'region',
                          title: '行政区',
                          value: (row) => row.region ?? '',
                          width: 160,
                          cellBuilder: (context, row, value) => Center(
                            child: Text(
                              '$value',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF4E5969)),
                            ),
                          ),
                        ),
                        AppDataGridColumn(
                          id: 'regionAddressGap',
                          title: '',
                          value: (row) => '',
                          width: 30,
                          sortable: false,
                          filterable: false,
                        ),
                        AppDataGridColumn(
                          id: 'address',
                          title: '详细地址',
                          value: (row) => row.address ?? '',
                          width: 280,
                          alignment: Alignment.centerLeft,
                          titleAlignment: Alignment.centerLeft,
                          cellBuilder: (context, row, value) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$value',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF4E5969)),
                            ),
                          ),
                        ),
                      ],
                      ),
                    );
                  }

                  if (devicesLoading && devices.isEmpty) {
                    return const Center(child: Text('加载中…'));
                  }
                  return AppDataGrid<LcdDeviceEntity>.local(
                    height: constraints.maxHeight,
                    rows: devices,
                    rowKey: (row) => row.uiKey,
                    selectionMode: AppDataGridSelectionMode.multiple,
                    selectedKeys: selectedDevices,
                    onSelectionChanged: controller.updateSelectedDevices,
                    onRowDoubleTap: (row) =>
                        _openDeviceDetail(context, controller, row),
                    sortable: false,
                    showInternalDividers: false,
                    headerBackgroundColor: kTableHeaderBackground,
                    headerTextStyle: kTableHeaderTextStyle,
                    cellTextStyle: const TextStyle(fontSize: 14),
                    stripeColor: kTableStripeBackground,
                    empty: const Center(child: AppEmptyState()),
                    columns: [
                      AppDataGridColumn(
                        id: 'index',
                        title: '序号',
                        value: controller.serialOf,
                        type: AppDataGridColumnType.number,
                        width: 72,
                        minWidth: 56,
                        sortable: false,
                        filterable: false,
                      ),
                      AppDataGridColumn(
                        id: 'deviceName',
                        title: '设备名称',
                        value: (row) => row.displayName,
                        width: 180,
                      ),
                      AppDataGridColumn(
                        id: 'orderNum',
                        title: '订单数量(次)',
                        value: (row) => '${row.order_num ?? 0}',
                        width: 110,
                        cellBuilder: (context, row, value) => Center(
                          child: Text(
                            '$value',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'city',
                        title: '城市',
                        value: (row) => row.city ?? '',
                        width: 100,
                        cellBuilder: (context, row, value) => Center(
                          child: Text('$value', style: _kSecondaryCellStyle),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'region',
                        title: '行政区域',
                        value: (row) => row.district ?? '',
                        width: 120,
                        cellBuilder: (context, row, value) => Center(
                          child: Text('$value', style: _kSecondaryCellStyle),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'address',
                        title: '详细地址',
                        value: (row) => row.displayAddress,
                        widthMode: AppDataGridColumnWidthMode.fill,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        cellBuilder: (context, row, value) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _kSecondaryCellStyle,
                          ),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'building',
                        title: '楼栋',
                        value: (row) => row.building ?? '',
                        width: 88,
                        cellBuilder: (context, row, value) => Center(
                          child: Text('$value', style: _kSecondaryCellStyle),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'mediaLocation',
                        title: '媒体位置',
                        value: (row) => row.media_address ?? '',
                        width: 110,
                        cellBuilder: (context, row, value) => Center(
                          child: Text('$value', style: _kSecondaryCellStyle),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'deviceStatus',
                        title: '状态显示',
                        value: (row) => row.displayStatusLabel,
                        width: 100,
                        cellBuilder: (context, row, value) {
                          return Align(
                            alignment: Alignment.center,
                            child: switch (row.displayStatus) {
                              LcdDeviceStatus.online => AppBadge.success(
                                appearance: AppBadgeStyle.plain,
                                size: AppBadgeSize.normal.copyWith(fontSize: 14),
                                leading: const LcdDeviceStatusIcon.online(
                                  size: 12,
                                ),
                                child: const Text('在线'),
                              ),
                              LcdDeviceStatus.offline => AppBadge.secondary(
                                appearance: AppBadgeStyle.plain,
                                size: AppBadgeSize.normal.copyWith(fontSize: 14),
                                leading: const LcdDeviceStatusIcon.offline(
                                  size: 12,
                                ),
                                child: const Text('离线'),
                              ),
                              LcdDeviceStatus.abnormal => AppBadge.destructive(
                                appearance: AppBadgeStyle.plain,
                                size: AppBadgeSize.normal.copyWith(fontSize: 14),
                                leading: const LcdDeviceStatusIcon.abnormal(
                                  size: 12,
                                ),
                                child: const Text('异常'),
                              ),
                            },
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'publishRate',
                        title: '上刊率',
                        value: (row) => row.publish_rate?.rate ?? '-',
                        width: 88,
                        cellBuilder: (context, row, value) => Center(
                          child: Text(
                            '$value',
                            style: const TextStyle(
                              color: Color(0xFF34C759),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'sound',
                        title: '是否可播放声音',
                        value: (row) {
                          if (row.is_volume != null) {
                            return row.is_volume == 1 ? '1' : '0';
                          }
                          if (row.play_sound != null) {
                            return row.play_sound! ? '1' : '0';
                          }
                          return '';
                        },
                        width: 120,
                        cellBuilder: (context, row, value) {
                          final soundOn =
                              row.is_volume == 1 || row.play_sound == true;
                          final colors = ShadcnTheme.of(context).colorScheme;
                          return Center(
                            child: Icon(
                              soundOn
                                  ? AppLucideIcons.volume2
                                  : AppLucideIcons.volumeX,
                              size: 16,
                              color: soundOn
                                  ? colors.primary
                                  : colors.destructive,
                            ),
                          );
                        },
                      ),
                    ],
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

class _GridPanel extends StatelessWidget {
  const _GridPanel({required this.controller});

  final LcdDevicesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final office = controller.gridOffice;
      final offices = controller.offices.toList();
      final devices = controller.devices.toList();
      // 必须在 Obx builder 内读取：LayoutBuilder 的 builder 在 layout 阶段才跑，订不到 Rx。
      final officesLoading = controller.officesLoading.value;
      final devicesLoading = controller.loading.value;

      final loadingMore = office == null ? officesLoading && offices.isNotEmpty : devicesLoading && devices.isNotEmpty;

      return Column(
        spacing: 12,
        children: [
          Expanded(
            child: LoadMoreListener(
              onLoadMore: controller.loadMore,
              child: LayoutBuilder(
              builder: (context, constraints) {
                if (office == null) {
                  if (officesLoading && offices.isEmpty) {
                    return const Center(child: Text('加载中…'));
                  }
                  if (offices.isEmpty) {
                    return const Center(child: const AppEmptyState());
                  }
                  return FixedSizeGrid(
                    itemWidth: LcdDevicesController.officeItemWidth,
                    itemHeight: LcdDevicesController.itemHeight,
                    spacing: LcdDevicesController.itemSpacing,
                    padding: kGridShellPad,
                    itemCount: offices.length,
                    itemBuilder: (context, index) {
                      final item = offices[index];
                      return _OfficeCard(key: ValueKey(item.office_id ?? index), controller: controller, office: item, index: index);
                    },
                  );
                }

                if (devicesLoading && devices.isEmpty) {
                  return const Center(child: Text('加载中…'));
                }
                if (devices.isEmpty) {
                  return const Center(child: const AppEmptyState());
                }
                return FixedSizeGrid(
                  itemWidth: LcdDevicesController.officeItemWidth,
                  itemHeight: LcdDevicesController.itemHeight,
                  spacing: LcdDevicesController.itemSpacing,
                  padding: kGridShellPad,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return _DeviceCard(key: ValueKey(device.uiKey), controller: controller, device: device, index: index);
                  },
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

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({super.key, required this.controller, required this.office, required this.index});

  final LcdDevicesController controller;
  final AdOfficeListItemEntity office;
  final int index;

  @override
  Widget build(BuildContext context) {
    final name = office.name?.trim().isNotEmpty == true ? office.name!.trim() : '-';
    final region = office.region?.trim().isNotEmpty == true ? office.region!.trim() : '-';
    final address = office.address?.trim().isNotEmpty == true ? office.address!.trim() : '-';
    final building = office.building?.trim() ?? '';
    final mediaAddress = office.media_address?.trim() ?? '';
    final subtitle = [if (building.isNotEmpty) building, if (mediaAddress.isNotEmpty) mediaAddress].join(' · ');

    return Obx(() {
      final selected = controller.selectedOfficeFolderIds.contains(office.office_id);
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
          onPressed: () => controller.toggleOfficeFolder(office.office_id),
          onDoubleTap: () => controller.enterOfficeGrid(office),
          child: Stack(
            clipBehavior: Clip.none,
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF9F9F9), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFF9F9F9)],
                    ),
                    borderRadius: radius,
                    border: Border.all(
                      color: selected ? stackColor : const Color(0xFFE5E6EB),
                    ),
                    boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 10)],
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
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                AppText.caption(region, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                const AppDivider.horizontal(),
                              ],
                            ),
                          ),
                          OfficeCardIcon(avatarIcon: office.avatar_icon, count: office.deviceCount ?? 0),
                        ],
                      ),
                      const Spacer(),
                      AppText.caption(subtitle.isNotEmpty ? subtitle : address, maxLines: 1, scrollMode: AppTextScrollMode.hover, style: const TextStyle(fontSize: 12)),
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

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({super.key, required this.controller, required this.device, required this.index});

  final LcdDevicesController controller;
  final LcdDeviceEntity device;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _LcdDeviceCard(
        device: device,
        selected: controller.selectedDeviceIds.contains(device.uiKey),
        onTap: () => controller.toggleDeviceSelected(device.uiKey),
        onDoubleTap: () => _openDeviceDetail(context, controller, device),
      ),
    );
  }
}

/// 设备网格 / 地图详情共用卡片。
class _LcdDeviceCard extends StatelessWidget {
  const _LcdDeviceCard({required this.device, required this.selected, this.onTap, this.onDoubleTap});

  final LcdDeviceEntity device;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  static const _tagSize = AppBadgeSize(
    fontSize: 12,
    height: 18,
    padding: EdgeInsets.symmetric(horizontal: 8),
    iconSize: 8,
    contentGap: 4,
  );

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(16));
    final building = device.building?.trim() ?? '';
    final mediaAddress = device.media_address?.trim() ?? '';
    const stackColor = Color(0xFF0084C7);
    const idleStackColor = Color(0xFFE5E6EB);
    final backColor = selected ? stackColor : idleStackColor;

    final statusWidget = switch (device.displayStatus) {
      LcdDeviceStatus.online => const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          LcdDeviceStatusIcon.online(size: 14),
          Text('在线', style: TextStyle(fontSize: 12, color: _kOnlineColor, height: 1)),
        ],
      ),
      LcdDeviceStatus.offline => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const LcdDeviceStatusIcon.offline(size: 14),
          Text('离线', style: TextStyle(fontSize: 12, color: colors.mutedForeground, height: 1)),
        ],
      ),
      LcdDeviceStatus.abnormal => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const LcdDeviceStatusIcon.abnormal(size: 14),
          Text('异常', style: TextStyle(fontSize: 12, color: colors.destructive, height: 1)),
        ],
      ),
    };

    return AppMotion.lift(
      cursor: SystemMouseCursors.click,
      child: AppInkWell(
        onPressed: onTap,
        onDoubleTap: onDoubleTap,
        hoverOpacity: 0,
        pressedOpacity: 0,
        borderRadius: radius,
        child: Stack(
          clipBehavior: Clip.none,
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF9F9F9), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFF9F9F9)],
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: selected ? stackColor : const Color(0xFFE5E6EB),
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        SidebarAvatarIcon(
                          avatarIcon: withDefaultAvatar(device.avatar_icon),
                          size: 40,
                          iconSize: 24,
                          borderRadius: 16,
                          fallbackAsset: 'assets/images/device_icon.png',
                          useTemplateBackground: true,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [
                              AppText.label(
                                device.displayName,
                                maxLines: 1,
                                scrollMode: AppTextScrollMode.hover,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              statusWidget,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AppDivider.horizontal(),
                    const Spacer(),
                    if (building.isNotEmpty || mediaAddress.isNotEmpty)
                      FairShareRow(
                        spacing: 6,
                        children: [
                          if (building.isNotEmpty)
                            AppBadge.custom(
                              color: const Color(0xFF414853),
                              appearance: AppBadgeStyle.solid,
                              shape: AppBadgeShape.pill,
                              size: _tagSize,
                              child: Text(building),
                            ),
                          if (mediaAddress.isNotEmpty)
                            AppBadge.custom(
                              color: const Color(0xFFF4F4F5),
                              appearance: AppBadgeStyle.solid,
                              shape: AppBadgeShape.pill,
                              size: _tagSize,
                              child: Text(mediaAddress),
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
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.controller});

  final LcdDevicesController controller;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ShadcnTheme.of(context).radiusMd);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: ShadcnTheme.of(context).colorScheme.border),
      ),
      child: Obx(() {
        final selectedId = controller.selectedMapSiteId.value;
        final markers = <AmapMarker>[];
        for (final device in controller.devices) {
          if (!device.hasMapPoint) continue;
          final selected = device.uiKey == selectedId;
          markers.add(LcdDevicesController.mapMarkerOf(device, selected: selected));
        }
        // 不用 ClipRRect：macOS PlatformView 上叠裁剪/绘制层会挡住拖动与点击。
        return AmapWidget(
          embedded: true,
          suppressMarkerModal: true,
          requestNativeLocationPermission: false,
          markers: markers,
          onMarkerTap: (payload) {
            if (payload.id.isEmpty) {
              controller.clearMapSelection();
              return;
            }
            controller.selectMapSite(payload.id);
            if (payload.doubleTap) {
              final device = controller.selectedMapSite;
              if (device != null) {
                _openDeviceDetail(context, controller, device);
              }
            }
          },
        );
      }),
    );
  }
}

/// 楼栋列表右侧栏：宽 360，由顶栏「显示 / 隐藏」控制。
class _OfficeSidebar extends StatelessWidget {
  const _OfficeSidebar({required this.controller, required this.selectedCount});

  final LcdDevicesController controller;
  final int selectedCount;

  AdOfficeListItemEntity? get _selectedOffice {
    if (selectedCount != 1) return null;
    final id = controller.selectedOfficeFolderId.value;
    if (id == null) return null;
    for (final item in controller.offices) {
      if (item.office_id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 与设备层一致：仅单选绑定数据；未选 / 多选仍保留侧栏壳。
      final single = selectedCount == 1;
      final file = single ? controller.sidebarFileList.value : null;
      final basic = file?.device_basic_data;
      final office = _selectedOffice;
      final title = () {
        if (!single) return '-';
        final info = file?.file_info?.trim();
        if (info != null && info.isNotEmpty) return info;
        final name = office?.name?.trim();
        if (name != null && name.isNotEmpty) return name;
        return '-';
      }();
      final total = basic?.total_devices ?? 0;
      final size98 = basic?.count_98inch ?? 0;
      final size86 = basic?.count_86inch ?? 0;
      final online = basic?.online_devices ?? 0;
      final offline = basic?.offline_devices ?? 0;
      final abnormal = basic?.abnormal_devices ?? 0;

      return AdFileInfoSidebar(
        showCard: false,
        file: file,
        loading: single && controller.sidebarFileListLoading.value,
        title: title,
        total: total,
        size98: size98,
        size86: size86,
        online: online,
        offline: offline,
        abnormal: abnormal,
        onAddTag: controller.addOfficeTag,
        onDeleteTag: controller.deleteOfficeTag,
        iconUpdateType: SidebarAvatarIconType.office,
        iconUpdateId: single ? controller.sidebarOfficeId : null,
        avatarIcon: office?.avatar_icon ?? file?.avatar_icon,
        address: [office?.region, office?.address]
            .map((e) => e?.trim() ?? '')
            .where((e) => e.isNotEmpty)
            .join('\n'),
        onTitleUpdated: (name) {
          controller.sidebarFileList.value?.file_info = name;
          _selectedOffice?.name = name;
        },
        onIconUpdated: (icon) {
          final current = controller.sidebarFileList.value;
          if (current != null) {
            current.avatar_icon = icon;
            controller.sidebarFileList.value = null;
            controller.sidebarFileList.value = current;
          }
          final selected = _selectedOffice;
          if (selected != null) {
            selected.avatar_icon = icon;
            controller.offices.refresh();
          }
        },
      );
    });
  }
}
