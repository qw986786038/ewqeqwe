import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_add_dialog.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_material_rule_panel.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/customer_avatar_icon.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/schedule_material_card.dart';

import '../device_detail_controller.dart';
import '../device_detail_insets.dart';
import '../device_detail_publish_rate_label.dart';
import '../device_detail_status_badge.dart';
import '../device_detail_title_icon.dart';
import '../dialogs/device_schedule_materials_dialog.dart';

/// 播放排期 Tab：对齐原「排期管理」接口与素材表格。
class DeviceScheduleTab extends StatelessWidget {
  const DeviceScheduleTab({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  Widget _statusBadge(LcdDeviceStatus status) =>
      deviceDetailStatusBadge(status);

  List<AppDataGridColumn<LcdProgramMaterialEntity>> _columns(
    BuildContext context,
  ) {
    return [
      AppDataGridColumn(
        id: 'order',
        title: '次序',
        value: (row) => controller.materials.indexOf(row) + 1,
        type: AppDataGridColumnType.number,
        width: 72,
        minWidth: 56,
        sortable: false,
        filterable: false,
      ),
      AppDataGridColumn(
        id: 'industry',
        title: '行业分类',
        value: (row) => row.customer_industry ?? '-',
        width: 120,
        cellBuilder: (context, row, value) => customerIndustryTag(
          label: row.customer_industry ?? '-',
          colorHex: row.color,
          filled: true,
          size: _listBadgeSize,
        ).center(),
      ),
      AppDataGridColumn(
        id: 'status',
        title: '状态',
        value: (row) => row.is_delete,
        width: 120,
        cellBuilder: (context, row, value) => Align(
          alignment: Alignment.center,
          child: row.is_delete == 1
              ? AppBadge.destructive(
                  appearance: AppBadgeStyle.soft,
                  shape: AppBadgeShape.square,
                  size: _listBadgeSize,
                  child: const Text('已下刊'),
                )
              : AppBadge.success(
                  shape: AppBadgeShape.square,
                  size: _listBadgeSize,
                  child: const Text('已上刊'),
                ),
        ),
      ),
      AppDataGridColumn(
        id: 'orderName',
        title: '订单名称',
        value: (row) => row.media_title ?? row.order_no ?? '-',
        widthMode: AppDataGridColumnWidthMode.fill,
        alignment: Alignment.centerLeft,
        titleAlignment: Alignment.centerLeft,
      ),
      AppDataGridColumn(
        id: 'adDuration',
        title: '广告时长',
        value: (row) => _durationLabel(row),
        width: 100,
      ),
      AppDataGridColumn(
        id: 'orderDailyFreq',
        title: '订单日播频次',
        value: (row) => _freqLabel(row.order_frequency),
        width: 130,
      ),
      AppDataGridColumn(
        id: 'playedToday',
        title: '今日已播放次数',
        value: (row) => _freqLabel(row.now_play_frequency),
        width: 130,
      ),
      AppDataGridColumn(
        id: 'setDailyFreq',
        title: '设定日播频次',
        value: (row) => _freqLabel(row.now_frequency),
        width: 130,
      ),
      AppDataGridColumn(
        id: 'volumeMet',
        title: '播量满足',
        value: (row) => row.satisfy,
        width: 96,
        cellBuilder: (context, row, value) => row.satisfy == true
            ? AppBadge.success(
                appearance: AppBadgeStyle.soft,
                shape: AppBadgeShape.square,
                size: _listBadgeSize,
                child: const Text('满足'),
              ).center()
            : AppBadge.destructive(
                appearance: AppBadgeStyle.soft,
                shape: AppBadgeShape.square,
                size: _listBadgeSize,
                child: const Text('不足'),
              ).center(),
      ),
      AppDataGridColumn(
        id: 'material',
        title: '广告物料',
        value: (row) => 1,
        width: 88,
      ),
      AppDataGridColumn(
        id: 'execStatus',
        title: '执行状态',
        value: (row) => row.order_detail_status,
        width: 100,
        cellBuilder: (context, row, value) =>
            _execStatusBadge(row.order_detail_status).center(),
      ),
      AppDataGridColumn(
        id: 'actions',
        title: '操作',
        value: (row) => row.id,
        width: 120,
        sortable: false,
        filterable: false,
        cellBuilder: (context, row, value) {
          final offShelf = row.is_delete == 1;
          // 1=播放中，2=暂停，3=已结束
          final paused = row.program_status == 2;
          final ended = row.program_status == 3;
          final colors = ShadcnTheme.of(context).colorScheme;
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              AppIconButton(
                icon: Icon(
                  paused ? AppLucideIcons.play : AppLucideIcons.pause,
                  size: 14,
                  color: ended
                      ? colors.mutedForeground
                      : (paused ? colors.primary : const Color(0xFFF59E0B)),
                ),
                tooltip: ended ? '已结束' : (paused ? '启动' : '暂停'),
                size: AppButtonSize.small,
                backgroundColor: const Color(0xFFFFFFFF),
                onPressed: ended
                    ? null
                    : () => controller.toggleMaterialPlay(row),
              ),
              AppIconButton(
                icon: Icon(
                  offShelf ? AppLucideIcons.upload : AppLucideIcons.download,
                  size: 14,
                  color: offShelf ? colors.primary : colors.destructive,
                ),
                tooltip: offShelf ? '上刊' : '下刊',
                size: AppButtonSize.small,
                backgroundColor: const Color(0xFFFFFFFF),
                onPressed: () => controller.toggleMaterialShelf(row),
              ),
            ],
          ).center();
        },
      ),
    ];
  }

  Future<void> _createProgram(BuildContext context) async {
    final schedule = controller.scheduleDevice.value;
    if (schedule?.id == null) {
      showWarn('该设备当日无排期，无法创建节目');
      return;
    }
    await showLcdProgramAddDialog(
      context: context,
      device: schedule!,
      onSubmit: controller.createProgram,
    );
  }

  void _confirmStart(BuildContext context) {
    final schedule = controller.scheduleDevice.value;
    if (schedule?.id == null) {
      showWarn('该设备当日无排期，无法保存并执行');
      return;
    }
    final label =
        schedule?.schedule_name ?? schedule?.terminal_point_name ?? '当前排期';
    showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: const Text('保存并执行'),
        content: Text('确定要保存并执行排期「$label」吗？'),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close<void>(dialogContext),
            child: const Text('取消'),
          ),
          AppButton.primary(
            onPressed: () async {
              await controller.startScheduleExecution();
              if (dialogContext.mounted) {
                await AppOverlay.close<void>(dialogContext);
              }
            },
            child: const Text('保存并执行'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = AppControlMetricsScope.resolve(context).buttonHeight;
    return Column(
      spacing: 16,
      children: [
        Obx(() {
          final device = controller.device;
          return AppCard(
            borderRadius: BorderRadius.circular(24),
            borderWidth: 0,
            padding: kDeviceDetailHeaderPadding,
            child: SizedBox(
              height: headerHeight,
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppText.h3(
                    device.displayName,
                    style: kDeviceDetailHeaderTitleStyle,
                  ),
                  if (device.building?.trim().isNotEmpty == true)
                    AppBadge.primary(
                      child: Text(device.building!.trim()),
                      shape: AppBadgeShape.square,
                      size: AppBadgeSize.normal.copyWith(height: 20),
                    ),
                  if (device.media_address?.trim().isNotEmpty == true)
                    AppText.subtitle(
                      device.media_address!.trim(),
                      style: kDeviceDetailHeaderTextStyle,
                    ),
                  const SizedBox(width: 8),
                  _statusBadge(device.displayStatus),
                  const SizedBox(width: 8),
                  deviceDetailPublishRateLabel(
                    context,
                    controller.schedulePublishRateText,
                  ),
                  const Spacer(),
                  AppButton.primary(
                    config: const AppButtonConfig(height: 28),
                    child: const Text('创建新节目'),
                    onPressed: () => _createProgram(context),
                  ),
                  AppButton.outline(
                    config: const AppButtonConfig(height: 28),
                    child: const Text('保存并执行'),
                    onPressed: () => _confirmStart(context),
                  ),
                  AppButton.outline(
                    config: const AppButtonConfig(height: 28),
                    child: const Text('智能排序'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }),
        Column(
          spacing: 16,
          children: [
            AppCard(
              borderRadius: BorderRadius.circular(24),
              borderWidth: 0,
              child: Obx(() {
                final materials = controller.materials.toList(growable: false);
                final selectedId = controller.selectedMaterial.value?.id;
                return AppDescriptions.custom(
                  title: const Text('节目排期及播放规则设定'),
                  titleIcon: deviceDetailTitleIcon(
                    context,
                    AppLucideIcons.calendarClock,
                  ),
                  actions: AppDatePicker(
                    value: controller.scheduleDate.value,
                    hintText: '选择日期',
                    onChanged: controller.setScheduleDate,
                  ).width(160),
                  child: Stack(
                    children: [
                      AppDataGrid<LcdProgramMaterialEntity>.local(
                        columns: _columns(context),
                        rows: materials,
                        rowKey: (row) => row.id ?? identityHashCode(row),
                        shrinkWrap: true,
                        sortable: false,
                        showBorder: false,
                        showInternalDividers: false,
                        headerBackgroundColor: kTableHeaderBackground,
                        headerTextStyle: kTableHeaderTextStyle,
                        stripeColor: kTableStripeBackground,
                        selectionMode: AppDataGridSelectionMode.single,
                        selectedKeys: <Object>{?selectedId},
                        onSelectionChanged: (rows) {
                          if (rows.isNotEmpty) {
                            controller.selectMaterial(rows.first);
                          }
                        },
                        reorderableRows: true,
                        onRowsReordered: controller.reorderMaterials,
                        empty: const Center(child: AppEmptyState()),
                      ),
                      if (controller.loadingMaterials.value ||
                          controller.loadingSchedule.value)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Color(0x66FFFFFF),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            Obx(() {
              final material = controller.selectedMaterial.value;
              if (material == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: AppEmptyState(),
                  ),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    borderWidth: 0,
                    child: AppDescriptions(
                      labelWidth: 72,
                      runSpacing: 0,
                      itemHeight: 32,
                      padding: _kDescBlockPadding,
                      layout: AppDescriptionLayout.horizontal,
                      title: const Text('客户及订单信息'),
                      titleIcon: deviceDetailTitleIcon(
                        context,
                        AppLucideIcons.userRound,
                      ),
                      items: [
                        const AppDescriptionItem(
                          label: Text('图标/Logo'),
                          labelAlignment: AlignmentGeometry.topStart,
                          itemHeight: null,
                          value: Align(
                            alignment: Alignment.centerLeft,
                            child: CustomerAvatarIcon(size: 56),
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('客户名称'),
                          value: Text(material.customer_name ?? '-'),
                        ),
                        AppDescriptionItem(
                          label: const Text('订单名称'),
                          value: Text(
                            material.media_title ?? material.order_no ?? '-',
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('所属行业'),
                          value: Text(material.customer_industry ?? '-'),
                        ),
                        AppDescriptionItem(
                          label: const Text('收费类型'),
                          value: Text(material.order_pay_label ?? '-'),
                        ),
                      ],
                    ),
                  ).expanded(),
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    borderWidth: 0,
                    child: AppDescriptions(
                      labelWidth: 72,
                      runSpacing: 0,
                      itemHeight: 32,
                      padding: _kDescCardPadding,
                      layout: AppDescriptionLayout.horizontal,
                      title: const Text('发布单信息'),
                      titleIcon: deviceDetailTitleIcon(
                        context,
                        AppLucideIcons.fileText,
                      ),
                      items: [
                        AppDescriptionItem(
                          label: const Text('上刊时间'),
                          value: Text(
                            _dateOnly(
                              material.start_time ??
                                  material.order_detail_send_time,
                            ),
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('下刊时间'),
                          value: Text(_dateOnly(material.end_time)),
                        ),
                        AppDescriptionItem(
                          label: const Text('订单天数'),
                          value: Text(
                            material.order_days == null
                                ? '-'
                                : '${material.order_days}天',
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('播放形式'),
                          value: Text(
                            _playRuleLabel(material.order_detail_play_rule),
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('播放时段'),
                          value: Text(
                            material.publish_slots ?? material.set_slots ?? '-',
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('广告时长'),
                          value: Text(_durationLabel(material)),
                        ),
                        AppDescriptionItem(
                          label: const Text('日播频次'),
                          value: Text(_freqLabel(material.order_frequency)),
                        ),
                      ],
                    ),
                  ).expanded(),
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    borderWidth: 0,
                    child: AppComponentTheme<AppDescriptionsTheme>(
                      data: const AppDescriptionsTheme(
                        itemHeight: 32,
                        padding: _kDescCardPadding,
                      ),
                      child: LcdProgramMaterialRulePanel(
                        material: material,
                        labelWidth: 72,
                        readOnly: true,
                      ),
                    ),
                  ).expanded(),
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    borderWidth: 0,
                    child: AppDescriptions.custom(
                      padding: _kDescBlockPadding,
                      title: const Text('广告物料'),
                      titleIcon: deviceDetailTitleIcon(
                        context,
                        AppLucideIcons.layers,
                      ),
                      actions: AppButton.outline(
                        onPressed: () => showDeviceScheduleMaterialsDialog(
                          context,
                          controller: controller,
                        ),
                        child: const Text('查看全部'),
                      ),
                      child: SizedBox(
                        width: ScheduleMaterialCard.width,
                        height: ScheduleMaterialCard.height,
                        child: ScheduleMaterialCard(
                          material: material,
                          borderWidth: 1,
                          onTap: () => showProgramMaterialPreviewDialog(
                            context: context,
                            material: material,
                          ),
                        ),
                      ),
                    ),
                  ).width(ScheduleMaterialCard.width + 16),
                ],
              );
            }),
          ],
        ).scroll(padding: kDeviceDetailPagePadding).expanded(),
      ],
    );
  }
}

String _durationLabel(LcdProgramMaterialEntity item) {
  final sec = item.duration ?? item.media_duration;
  if (sec == null) return '-';
  return "$sec'";
}

/// 标题图标底到内容视觉约 20（标题栏图标下余 4）：首行为 32 高文字行时，文字居中另有上留白。
const _kDescCardPadding = EdgeInsets.fromLTRB(20, 4, 20, 20);

/// 同上，首行为 Logo / 表格 / 卡片等无上留白的内容。
const _kDescBlockPadding = EdgeInsets.fromLTRB(20, 16, 20, 20);

/// 列表内标签总高 24（内容 20 + 上下内边距各 2）。
final _listBadgeSize = AppBadgeSize.normal.copyWith(height: 20);

Widget _execStatusBadge(int? status) {
  return switch (status) {
    0 => AppBadge.secondary(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _listBadgeSize,
      child: const Text('未执行'),
    ),
    1 => AppBadge.success(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _listBadgeSize,
      child: const Text('执行中'),
    ),
    2 => AppBadge.secondary(
      appearance: AppBadgeStyle.soft,
      shape: AppBadgeShape.square,
      size: _listBadgeSize,
      child: const Text('已完结'),
    ),
    _ => const Text('-'),
  };
}

String _freqLabel(int? value) {
  if (value == null) return '-';
  return '$value次';
}

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return '-';
  return value.split(' ').first;
}

String _playRuleLabel(int? playRule) {
  if (playRule == null) return '-';
  if (playRule == 1) return '循环播放';
  if (playRule == 2) return '定屏播放';
  return playRule.toString();
}
