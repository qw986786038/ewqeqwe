import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/lcd/lcd_device_scene_pic_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_scene_pic_utils.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_terminal_mapper.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_constants.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/pages/lcd_devices/dialogs/lcd_devices_control_dialogs.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import '../device_detail_map.dart';
import '../device_detail_controller.dart';
import '../device_detail_insets.dart';
import '../device_detail_publish_rate_label.dart';
import '../device_detail_status_badge.dart';
import '../device_detail_title_icon.dart';
import '../dialogs/device_maintenance_records_dialog.dart';
import '../dialogs/device_map_preview_dialog.dart';
import '../dialogs/device_power_schedule_dialog.dart';
import '../dialogs/device_operation_logs_dialog.dart';
import '../dialogs/device_play_logs_dialog.dart';
import '../dialogs/device_record_add_dialog.dart';
import '../dialogs/device_site_photos_dialog.dart';

/// 描述项 value 字重。
const _kDescValueEmphasis = TextStyle(fontWeight: FontWeight.w500);

/// 标题图标底到首行文字视觉约 20：标题栏图标下余 4 + 顶部 4 + 行高 32 内文字居中的上留白。
const _kDescCardPadding = EdgeInsets.fromLTRB(20, 4, 20, 20);

AppInlineEditDisplayBuilder<String> _maintenanceInlineDisplay(
  String placeholder,
) {
  return (_, value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppText.muted(placeholder);
    }
    return Text(trimmed, style: _kDescValueEmphasis);
  };
}

Widget _maintenanceInlineText({
  required Rx<String> field,
  required String hint,
  required Future<void> Function(String) onSaved,
}) {
  return Obx(
    () => AppInlineEdit.text(
      value: field.value,
      hintText: hint,
      displayBuilder: _maintenanceInlineDisplay(hint),
      onSaved: onSaved,
    ),
  );
}

/// 待上游：`AppInlineEdit.text` 补 `maxLengthEnforcement` / `inputFormatters` 后回收。
Widget _limitedInlineText({
  required String value,
  required String hint,
  required int maxLength,
  required Future<void> Function(String) onSaved,
}) {
  return AppInlineEdit<String>(
    value: value,
    displayBuilder: (_, current) => Text(current),
    validator: (current) => lcdMaxLengthError(current, maxLength),
    submitOnEnter: true,
    onSaved: onSaved,
    editorBuilder: (context, details) => _LimitedInlineEditor(
      details: details,
      hintText: hint,
      maxLength: maxLength,
    ),
  );
}

/// 设备信息 Tab：本页自有头部 + 各分区描述。
class DeviceInfoTab extends StatelessWidget {
  const DeviceInfoTab({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  Widget _descriptionLink(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: AppInkWell(
        onPressed: onPressed,
        hoverOpacity: 0,
        pressedOpacity: 0,
        child: Text(
          label,
          style: TextStyle(fontSize: 14, color: colors.primary),
        ),
      ),
    );
  }

  Widget _descriptionActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    // ghost 按钮自带留白，左移使图标与上方文字对齐（small = 控件高 × 52/60）
    return Builder(
      builder: (context) {
        final inset = (AppControlMetricsScope.resolve(context).height * 52 / 60 - 16) / 2;
        return Transform.translate(
          offset: Offset(-inset, 0),
          child: AppIconButton(
            icon: Icon(icon, size: 16, color: color),
            tooltip: tooltip,
            size: AppButtonSize.small,
            variant: AppButtonVariant.ghost,
            onPressed: onPressed,
          ),
        );
      },
    );
  }

  void _runControl(
    void Function(LcdDevicesController list, List<String> nos) open,
  ) {
    final list = controller.listController;
    if (list == null) {
      showWarn('无法操作');
      return;
    }
    final nos = controller.takeControlDeviceNos();
    if (nos == null) return;
    open(list, nos);
  }

  Widget _statusBadge(LcdDeviceStatus status) =>
      deviceDetailStatusBadge(status);

  Widget _sceneThumb(BuildContext context, LcdDeviceScenePicEntity photo) {
    final url = photo.url?.trim();
    final isVideo = isLcdDeviceScenePicVideo(photo);
    final canPreview = resolveLcdDeviceScenePicPreviewPath(photo) != null;

    return AppInkWell(
      onDoubleTap: canPreview
          ? () => showLcdDeviceScenePicPreview(context: context, item: photo)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(8),
                image: (url != null && url.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (url == null || url.isEmpty)
                  ? Icon(
                      isVideo ? AppLucideIcons.video : AppLucideIcons.image,
                      size: 24,
                      color: const Color(0xFF64748B),
                    ).center()
                  : null,
            ),
            if (isVideo && canPreview)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: const Color(0x38000000),
                  child: Icon(
                    AppLucideIcons.play,
                    size: 24,
                    color: const Color(0xFFFFFFFF),
                  ).center(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<AppDescriptionItem> _scenePhotoItems(
    BuildContext context,
    List<LcdDeviceScenePicEntity> pics,
  ) {
    final previewPics = pics.take(3).toList(growable: false);
    return [
      AppDescriptionItem(
        label: const Text('现场照片'),
        value: Row(
          children: [
            _descriptionLink(
              context,
              '查看全部 (${pics.length})',
              () => showDeviceSitePhotosDialog(context, controller: controller),
            ),
            const SizedBox(width: 8),
            _descriptionLink(
              context,
              '添加',
              () => controller.pickAndAddScenePic(),
            ),
          ],
        ),
      ),
      if (previewPics.isNotEmpty)
        AppDescriptionItem.custom(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              const slotCount = 3;
              final thumbWidth =
                  (constraints.maxWidth - spacing * (slotCount - 1)) /
                  slotCount;
              return Row(
                spacing: spacing,
                children: [
                  for (final photo in previewPics)
                    SizedBox(
                      width: thumbWidth,
                      child: _sceneThumb(context, photo),
                    ),
                ],
              );
            },
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = AppControlMetricsScope.resolve(context).buttonHeight;
    return Padding(
      padding: kDeviceDetailPagePadding,
      child: Column(
        spacing: 20,
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
                      controller.pointName.value.trim().isNotEmpty
                          ? controller.pointName.value.trim()
                          : device.displayName,
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
                    if (controller.schedulePublishRateText != '-') ...[
                      const SizedBox(width: 8),
                      deviceDetailPublishRateLabel(
                        context,
                        controller.schedulePublishRateText,
                      ),
                    ],
                    const Spacer(),
                    AppIconButton(
                      icon: Image.asset('assets/images/device_control/restart.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                      tooltip: '重启',
                      onPressed: () => _runControl(
                        (list, nos) => showLcdDeviceRestartDialog(
                          context,
                          list,
                          deviceNos: nos,
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: Image.asset('assets/images/device_control/volume.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                      tooltip: '音量',
                      onPressed: () => _runControl(
                        (list, nos) => showLcdDeviceVolumeDialog(
                          context,
                          list,
                          deviceNos: nos,
                          device: device,
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: Image.asset('assets/images/device_control/brightness.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                      tooltip: '亮度',
                      onPressed: () => _runControl(
                        (list, nos) => showLcdDeviceBrightnessDialog(
                          context,
                          list,
                          deviceNos: nos,
                          device: device,
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: Image.asset('assets/images/device_control/power.png', width: 20, height: 20, filterQuality: FilterQuality.medium),
                      tooltip: '屏幕开关',
                      onPressed: () => _runControl(
                        (list, nos) => showLcdDeviceScreenPowerDialog(
                          context,
                          list,
                          deviceNos: nos,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Column(
                spacing: 16,
                children: [
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    child: Obx(() {
                      final device = controller.device;
                      return AppDescriptions(
                        itemHeight: 32,
                        padding: _kDescCardPadding,
                        layout: AppDescriptionLayout.horizontal,
                        labelWidth: 100,
                        columns: 1,
                        valueStyle: _kDescValueEmphasis,
                        title: const Text('基本信息'),
                        titleIcon: deviceDetailTitleIcon(
                          context,
                          AppLucideIcons.fileText,
                        ),
                        items: [
                          AppDescriptionItem(
                            label: const Text('点位名称'),
                            value: _limitedInlineText(
                              value: controller.pointName.value,
                              hint: '请输入点位名称',
                              maxLength: kLcdPointNameMaxLength,
                              onSaved: controller.savePointName,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('城市'),
                            value: Text(lcdDeviceTextOrDash(device.city)),
                          ),
                          AppDescriptionItem(
                            label: const Text('行政区'),
                            value: AppInlineEdit.select<int>(
                              value: controller.districtId.value,
                              options: controller.districtOptions,
                              hintText: '请选择',
                              onSaved: controller.saveDistrict,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('楼栋'),
                            value: AppInlineEdit.text(
                              value: controller.building.value,
                              hintText: '请输入楼栋',
                              onSaved: controller.saveBuilding,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('详细地址'),
                            value: Text(
                              lcdDeviceTextOrDash(device.detailed_address),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('媒体位置'),
                            value: _limitedInlineText(
                              value: controller.mediaLocation.value,
                              hint: '请输入媒体位置',
                              maxLength: kLcdMediaAddressMaxLength,
                              onSaved: controller.saveMediaLocation,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('媒体尺寸'),
                            value: DefaultTextStyle.merge(
                              style: _kDescValueEmphasis,
                              child: AppInlineEdit.select<String>(
                                value: controller.mediaSize.value.isEmpty
                                    ? null
                                    : controller.mediaSize.value,
                                options:
                                    LcdDeviceDetailController.mediaSizeOptions,
                                hintText: '请选择',
                                onSaved: controller.saveMediaSize,
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('分辨率'),
                            value: AppInlineEdit.text(
                              value: controller.resolution.value,
                              hintText: '如 1920x1080',
                              onSaved: controller.saveResolution,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('开关机时间'),
                            labelAlignment: AlignmentDirectional.topStart,
                            value: AppInlineEdit.dialog(
                              value: controller.powerSchedule.value,
                              intrinsicHeight: true,
                              alignment: AlignmentDirectional.topStart,
                              displayBuilder: (_, value) {
                                final text = value.trim();
                                return Text(
                                  text.isEmpty ? '-' : text,
                                  style: _kDescValueEmphasis,
                                );
                              },
                              dialogBuilder: (context, value) =>
                                  showDevicePowerScheduleDialog(
                                    context,
                                    initial: value,
                                  ),
                              onSaved: controller.savePowerSchedule,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('开机时长'),
                            value: Text(
                              lcdDeviceTextWithUnit(
                                controller.bootHours.value,
                                '小时',
                              ),
                              style: _kDescValueEmphasis,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('是否允许音量'),
                            value: AppInlineEdit.switchValue(
                              value: controller.soundEnabled.value,
                              onSaved: (value) =>
                                  controller.soundEnabled.value = value,
                            ),
                          ),
                        ],
                      ).scroll();
                    }),
                  ).expanded(),
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      // 不用 ClipRRect：macOS PlatformView 上裁剪会挡住地图交互，圆角用上层白边遮罩。
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Obx(() {
                              final loading = controller.loading.value;
                              final device = controller.device;
                              final previewOpen =
                                  controller.mapPreviewOpen.value;
                              if (!device.hasMapPoint) {
                                return Center(
                                  child: AppText.muted(
                                    loading ? '加载中…' : '暂无设备位置',
                                  ),
                                );
                              }
                              // macOS：与放大弹窗同时存在两个 WKWebView 时上层无法拖动。
                              if (previewOpen) {
                                return const ColoredBox(
                                  color: Color(0xFFF8FAFC),
                                );
                              }
                              return DeviceDetailAmapWidget(device: device);
                            }),
                          ),
                          Positioned.fill(
                            left: -8,
                            top: -8,
                            right: -8,
                            bottom: -8,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 8,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Obx(() {
                              final device = controller.device;
                              if (!device.hasMapPoint) {
                                return const SizedBox.shrink();
                              }
                              return AppIconButton(
                                icon: const Icon(
                                  AppLucideIcons.maximize2,
                                  size: 16,
                                ),
                                tooltip: '放大查看',
                                size: AppButtonSize.small,
                                backgroundColor: const Color(0xFFFFFFFF),
                                onPressed: () => showDeviceMapPreviewDialog(
                                  context,
                                  controller: controller,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).expanded(),
              Column(
                spacing: 16,
                children: [
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    child: Obx(() {
                      final device = controller.device;
                      final pics = controller.scenePics;
                      return AppDescriptions(
                        itemHeight: 32,
                        padding: _kDescCardPadding,
                        layout: AppDescriptionLayout.horizontal,
                        labelWidth: 72,
                        columns: 1,
                        valueStyle: _kDescValueEmphasis,
                        title: const Text('设备信息'),
                        titleIcon: deviceDetailTitleIcon(
                          context,
                          AppLucideIcons.computer,
                        ),
                        items: [
                          AppDescriptionItem(
                            label: const Text('设备编号'),
                            value: Text(lcdDeviceTextOrDash(device.device_no)),
                          ),
                          AppDescriptionItem(
                            label: const Text('播控ID'),
                            value: Text(lcdDeviceTextOrDash(device.point_code)),
                          ),
                          AppDescriptionItem(
                            label: const Text('创建时间'),
                            value: Text(
                              lcdDeviceTextOrDash(device.created_time),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('操作系统'),
                            value: AppInlineEdit.select<String>(
                              value: controller.os.value.isEmpty
                                  ? null
                                  : controller.os.value,
                              options: controller.osSelectOptions,
                              hintText: '请选择',
                              onSaved: controller.saveOs,
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('连网方式'),
                            value: AppInlineEdit.select<String>(
                              value: controller.network.value.isEmpty
                                  ? null
                                  : controller.network.value,
                              options: controller.networkSelectOptions,
                              hintText: '请选择',
                              onSaved: controller.saveNetwork,
                            ),
                          ),
                          ..._scenePhotoItems(context, pics),
                        ],
                      ).scroll();
                    }),
                  ).expanded(),
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    child: Obx(() {
                      final device = controller.device;
                      return AppDescriptions(
                        itemHeight: 32,
                        padding: _kDescCardPadding,
                        labelWidth: 40,
                        columns: 2,
                        minColumnWidth: 100,
                        runSpacing: 0,
                        valueStyle: _kDescValueEmphasis,
                        valueHeight: AppControlMetricsScope.resolve(
                          context,
                        ).height,
                        layout: AppDescriptionLayout.horizontal,
                        title: const Text('监测数据'),
                        titleIcon: deviceDetailTitleIcon(
                          context,
                          AppLucideIcons.activity,
                        ),
                        items: [
                          AppDescriptionItem(
                            label: const Text('温度'),
                            value: Text(
                              lcdDeviceNumWithUnit(device.playlog_temp, '℃'),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('CO2'),
                            value: Text(
                              lcdDeviceNumWithUnit(device.playlog_co2, 'ppm'),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('烟雾'),
                            value: Text(
                              lcdDeviceNumOrDash(device.playlog_tovc),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('湿度'),
                            value: Text(
                              lcdDeviceNumWithUnit(device.playlog_humi, '%'),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('AQI'),
                            value: Text(lcdDeviceNumOrDash(device.playlog_aqi)),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ).expanded(),
              Column(
                spacing: 16,
                children: [
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    child: Obx(() {
                      final device = controller.device;
                      return AppDescriptions(
                        itemHeight: 32,
                        padding: _kDescCardPadding,
                        labelWidth: 60,
                        runSpacing: 0,
                        valueStyle: _kDescValueEmphasis,
                        valueHeight: AppControlMetricsScope.resolve(
                          context,
                        ).height,
                        layout: AppDescriptionLayout.horizontal,
                        title: const Text('运行数据'),
                        titleIcon: deviceDetailTitleIcon(
                          context,
                          AppLucideIcons.gauge,
                        ),
                        items: [
                          AppDescriptionItem(
                            label: const Text('运营天数'),
                            value: Text(
                              lcdDeviceTextWithUnit(
                                device.operational_period,
                                '天',
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('在线时长'),
                            value: Text(
                              lcdDeviceTextWithUnit(
                                device.total_history_time,
                                '小时',
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('电价标准'),
                            value: Text(
                              lcdDeviceNumWithUnit(device.power_price, '元/度'),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('总电量'),
                            value: Text(
                              lcdDeviceNumWithUnit(
                                device.energy_consumption ??
                                    device.playlog_energy,
                                '度',
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('总电费'),
                            value: Text(
                              lcdDeviceNumWithUnit(device.electricity_fee, '元'),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    child: Obx(() {
                      final device = controller.device;
                      final actionIconColor = ShadcnTheme.of(
                        context,
                      ).colorScheme.primary;
                      return AppDescriptions(
                        itemHeight: 32,
                        padding: _kDescCardPadding,
                        labelWidth: 60,
                        runSpacing: 0,
                        valueStyle: _kDescValueEmphasis,
                        valueHeight: AppControlMetricsScope.resolve(
                          context,
                        ).height,
                        layout: AppDescriptionLayout.horizontal,
                        title: const Text('告警数据'),
                        titleIcon: deviceDetailTitleIcon(
                          context,
                          AppLucideIcons.bell,
                        ),
                        items: [
                          AppDescriptionItem(
                            label: const Text('异常次数'),
                            value: Text(
                              lcdDeviceCountOrZero(
                                device.operation_status ?? device.device_status,
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('离线时间'),
                            value: Text(
                              lcdDeviceTextOrDash(device.last_online_time),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('异常告警'),
                            value: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                _descriptionActionIcon(
                                  icon: AppLucideIcons.eye,
                                  tooltip: '查看',
                                  color: actionIconColor,
                                  onPressed: () =>
                                      showDeviceMaintenanceRecordsDialog(
                                        context,
                                        controller: controller,
                                        type: 3,
                                      ),
                                ),
                                _descriptionActionIcon(
                                  icon: AppLucideIcons.plus,
                                  tooltip: '添加',
                                  color: const Color(0xFF22C55E),
                                  onPressed: () => showDeviceRecordAddDialog(
                                    context,
                                    controller: controller,
                                    type: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('播放日志'),
                            value: _descriptionActionIcon(
                              icon: AppLucideIcons.eye,
                              tooltip: '查看',
                              color: actionIconColor,
                              onPressed: () => showDevicePlayLogsDialog(
                                context,
                                controller: controller,
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('终端日志'),
                            value: _descriptionActionIcon(
                              icon: AppLucideIcons.eye,
                              tooltip: '查看',
                              color: actionIconColor,
                              onPressed: () => showDeviceOperationLogsDialog(
                                context,
                                controller: controller,
                              ),
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('维保记录'),
                            value: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                _descriptionActionIcon(
                                  icon: AppLucideIcons.eye,
                                  tooltip: '查看',
                                  color: actionIconColor,
                                  onPressed: () =>
                                      showDeviceMaintenanceRecordsDialog(
                                        context,
                                        controller: controller,
                                        type: 1,
                                      ),
                                ),
                                _descriptionActionIcon(
                                  icon: AppLucideIcons.plus,
                                  tooltip: '添加',
                                  color: const Color(0xFF22C55E),
                                  onPressed: () => showDeviceRecordAddDialog(
                                    context,
                                    controller: controller,
                                    type: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppDescriptionItem(
                            label: const Text('巡检记录'),
                            value: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                _descriptionActionIcon(
                                  icon: AppLucideIcons.eye,
                                  tooltip: '查看',
                                  color: actionIconColor,
                                  onPressed: () =>
                                      showDeviceMaintenanceRecordsDialog(
                                        context,
                                        controller: controller,
                                        type: 2,
                                      ),
                                ),
                                _descriptionActionIcon(
                                  icon: AppLucideIcons.plus,
                                  tooltip: '添加',
                                  color: const Color(0xFF22C55E),
                                  onPressed: () => showDeviceRecordAddDialog(
                                    context,
                                    controller: controller,
                                    type: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).scroll();
                    }),
                  ).expanded(),
                ],
              ).expanded(),
              Column(
                spacing: 16,
                children: [
                  AppCard(
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    child: AppDescriptions(
                      itemHeight: 32,
                      padding: _kDescCardPadding,
                      runSpacing: 0,
                      layout: AppDescriptionLayout.horizontal,
                      labelWidth: 72,
                      columns: 1,
                      valueStyle: _kDescValueEmphasis,
                      title: const Text('维保巡检'),
                      titleIcon: deviceDetailTitleIcon(
                        context,
                        AppLucideIcons.users,
                      ),
                      items: [
                        AppDescriptionItem(
                          label: const Text('物业公司'),
                          value: _maintenanceInlineText(
                            field: controller.propertyCompany,
                            hint: '请输入物业公司',
                            onSaved: controller.savePropertyCompany,
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('设备数量'),
                          value: Obx(
                            () => Text(
                              lcdDeviceNumOrDash(controller.device.quantity),
                              style: _kDescValueEmphasis,
                            ),
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('联系人'),
                          value: _maintenanceInlineText(
                            field: controller.propertyContact,
                            hint: '请输入联系人',
                            onSaved: controller.savePropertyContact,
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('联系电话'),
                          value: _maintenanceInlineText(
                            field: controller.propertyPhone,
                            hint: '请输入联系电话',
                            onSaved: controller.savePropertyPhone,
                          ),
                        ),
                        const AppDescriptionItem.divider(
                          divider: AppDivider.horizontal(height: 16),
                        ),
                        AppDescriptionItem(
                          label: const Text('维保公司'),
                          value: _maintenanceInlineText(
                            field: controller.maintenanceCompany,
                            hint: '请输入维保公司',
                            onSaved: controller.saveMaintenanceCompany,
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('联系人'),
                          value: _maintenanceInlineText(
                            field: controller.maintenanceContact,
                            hint: '请输入联系人',
                            onSaved: controller.saveMaintenanceContact,
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('联系电话'),
                          value: _maintenanceInlineText(
                            field: controller.maintenancePhone,
                            hint: '请输入联系电话',
                            onSaved: controller.saveMaintenancePhone,
                          ),
                        ),
                        const AppDescriptionItem.divider(
                          divider: AppDivider.horizontal(height: 16),
                        ),
                        AppDescriptionItem(
                          label: const Text('巡检部门'),
                          value: _maintenanceInlineText(
                            field: controller.inspectionDept,
                            hint: '请输入巡检部门',
                            onSaved: controller.saveInspectionDept,
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('负责人'),
                          value: _maintenanceInlineText(
                            field: controller.inspectionOwner,
                            hint: '请输入负责人',
                            onSaved: controller.saveInspectionOwner,
                          ),
                        ),
                        AppDescriptionItem(
                          label: const Text('联系电话'),
                          value: _maintenanceInlineText(
                            field: controller.inspectionPhone,
                            hint: '请输入联系电话',
                            onSaved: controller.saveInspectionPhone,
                          ),
                        ),
                      ],
                    ).scroll(),
                  ).expanded(),
                ],
              ).expanded(),
            ],
          ).expanded(),
        ],
      ),
    );
  }
}

/// 待上游：`AppInlineEdit.text` 支持 IME 安全字数限制后回收。
class _LimitedInlineEditor extends StatefulWidget {
  const _LimitedInlineEditor({
    required this.details,
    required this.hintText,
    required this.maxLength,
  });

  final AppInlineEditDetails<String> details;
  final String hintText;
  final int maxLength;

  @override
  State<_LimitedInlineEditor> createState() => _LimitedInlineEditorState();
}

class _LimitedInlineEditorState extends State<_LimitedInlineEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.details.value);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: _controller,
      focusNode: widget.details.focusNode,
      autofocus: true,
      hintText: widget.hintText,
      inputFormatters: lcdMaxLengthFormatters(widget.maxLength),
      density: AppDensity.compact,
      chrome: AppFieldChrome.bare,
      enabled: !widget.details.saving,
      onChanged: widget.details.onChanged,
      onSubmitted: (_) => widget.details.submit(),
    );
  }
}
