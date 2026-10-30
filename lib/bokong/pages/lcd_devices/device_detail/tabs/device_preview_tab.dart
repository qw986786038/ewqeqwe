import 'package:flutter/widgets.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';

import '../device_detail_controller.dart';
import '../device_detail_insets.dart';
import '../device_detail_publish_rate_label.dart';
import '../device_detail_status_badge.dart';
import '../device_detail_title_icon.dart';

/// 节目单预览 Tab：对接 [LcdApi.programPreviewSheet]。
class DevicePreviewTab extends StatelessWidget {
  const DevicePreviewTab({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  Widget _statusBadge(LcdDeviceStatus status) =>
      deviceDetailStatusBadge(status);

  List<AppDataGridColumn<LcdProgramMaterialEntity>> _columns() => [
    AppDataGridColumn(
      id: 'order',
      title: '次序',
      value: (row) =>
          row.preview_seq ??
          row.play_sort ??
          controller.previewMaterials.indexOf(row) + 1,
      type: AppDataGridColumnType.number,
      width: 72,
      minWidth: 56,
      sortable: false,
      filterable: false,
    ),
    AppDataGridColumn(
      id: 'name',
      title: '节目名称',
      value: (row) => row.media_title ?? '-',
      widthMode: AppDataGridColumnWidthMode.fill,
      alignment: Alignment.centerLeft,
      titleAlignment: Alignment.centerLeft,
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
      id: 'adDuration',
      title: '广告时长',
      value: (row) => _durationLabel(row),
      width: 96,
    ),
    AppDataGridColumn(
      id: 'orderFreq',
      title: '订单频次',
      value: (row) => _freqLabel(row.order_frequency),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'exclusive',
      title: '有无排它',
      value: (row) => _hasExclusive(row) ? '有' : '无',
      width: 96,
      cellBuilder: (context, row, value) {
        final has = _hasExclusive(row);
        final colors = ShadcnTheme.of(context).colorScheme;
        return Text(
          has ? '有' : '无',
          style: has ? TextStyle(color: colors.primary) : null,
        ).center();
      },
    ),
    AppDataGridColumn(
      id: 'setFreq',
      title: '设定频次',
      value: (row) => _freqLabel(row.now_frequency),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'publishPeriod',
      title: '发布时段设定',
      value: (row) =>
          '${_dateLabel(row.start_time)}/${_dateLabel(row.end_time)}',
      width: 160,
    ),
    AppDataGridColumn(
      id: 'actualFreq',
      title: '实播频次',
      value: (row) => _freqLabel(row.now_play_frequency),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'volumeMet',
      title: '播量条件',
      value: (row) => row.satisfy == true ? '满足' : '不满足',
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
              child: const Text('不满足'),
            ).center(),
    ),
    AppDataGridColumn(
      id: 'overplayFreq',
      title: '超播频次',
      value: (row) => _freqLabel(row.play_total_out_frequency),
      width: 100,
    ),
    AppDataGridColumn(
      id: 'overplayRate',
      title: '超播率',
      value: (row) =>
          row.play_total_out_per == null ? '-' : '${row.play_total_out_per}%',
      width: 88,
    ),
    AppDataGridColumn(
      id: 'loopInterval',
      title: '循环间隔',
      value: (row) {
        final interval = row.actual_loop_interval ?? row.loop_rule;
        return interval == null ? '-' : '$interval秒';
      },
      width: 96,
    ),
    AppDataGridColumn(
      id: 'execStatus',
      title: '执行状态',
      value: (row) => row.order_detail_status,
      width: 100,
      cellBuilder: (context, row, value) =>
          _execStatusBadge(row.order_detail_status).center(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final headerHeight = AppControlMetricsScope.resolve(context).buttonHeight;
    return Padding(
      padding: kDeviceDetailPagePadding,
      child: Column(
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
                      child: const Text('导出'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            );
          }),
          Obx(() {
            final rows = controller.previewMaterials.toList(growable: false);
            final loading =
                controller.loadingPreview.value ||
                controller.loadingSchedule.value;

            if (!loading && rows.isEmpty) {
              return Column(
                spacing: 16,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      AppDatePicker(
                        value: controller.scheduleDate.value,
                        hintText: '选择日期',
                        onChanged: controller.setScheduleDate,
                      ).width(160),
                    ],
                  ),
                  const Center(child: AppEmptyState()).expanded(),
                ],
              ).expanded();
            }

            final reasons = rows
                .map((e) => e.preview_gap_advice?.trim() ?? '')
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
            return AppCard(
              borderRadius: BorderRadius.circular(24),
              borderWidth: 0,
              clipBehavior: Clip.antiAlias,
              child: AppScrollbarView(
                child: AppDescriptions.custom(
                  title: const Text('节目单预览'),
                  titleIcon: deviceDetailTitleIcon(
                    context,
                    AppLucideIcons.clapperboard,
                  ),
                  actions: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      if (reasons.isNotEmpty)
                        Builder(
                          builder: (anchorContext) => AppIconButton(
                            icon: const Icon(
                              AppLucideIcons.circleAlert,
                              size: 20,
                              color: Color(0xFFFAAD14),
                            ),
                            tooltip: '间隔建议',
                            onPressed: () => AppPopover.show<void>(
                              context: anchorContext,
                              alignment: Alignment.topRight,
                              anchorAlignment: Alignment.bottomRight,
                              builder: (context) => AppCard.elevated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 200,
                                    maxWidth: 360,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      for (final reason in reasons)
                                        Text(reason),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      AppDatePicker(
                        value: controller.scheduleDate.value,
                        hintText: '选择日期',
                        onChanged: controller.setScheduleDate,
                      ).width(160),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AppDataGrid<LcdProgramMaterialEntity>.local(
                        columns: _columns(),
                        rows: rows,
                        rowKey: (row) => row.preview_seq != null
                            ? '${row.id}-${row.preview_seq}'
                            : row.id ?? identityHashCode(row),
                        shrinkWrap: true,
                        sortable: false,
                        showBorder: false,
                        showInternalDividers: false,
                        headerBackgroundColor: kTableHeaderBackground,
                        headerTextStyle: kTableHeaderTextStyle,
                        stripeColor: kTableStripeBackground,
                        reorderableRows: true,
                        onRowsReordered: controller.reorderPreviewMaterials,
                        empty: const Center(child: AppEmptyState()),
                      ),
                      if (loading)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Color(0x66FFFFFF),
                            child: Center(
                              child: AppCircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ).expanded();
          }),
        ],
      ),
    );
  }
}

String _durationLabel(LcdProgramMaterialEntity row) {
  final sec = row.duration ?? row.media_duration;
  return sec == null ? '-' : '$sec秒';
}

String _freqLabel(int? value) => value == null ? '-' : '$value次';

String _dateLabel(String? value) {
  if (value == null || value.isEmpty) return '-';
  return value.split(' ').first.replaceAll('-', '.');
}

bool _hasExclusive(LcdProgramMaterialEntity row) {
  final industry = row.exclusive_industry?.trim();
  if (industry != null && industry.isNotEmpty) return true;
  final rule = row.exclusive_rule?.trim();
  return rule != null && rule.isNotEmpty && rule != '0';
}

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
