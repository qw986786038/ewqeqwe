import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import '../lcd_devices_controller.dart';
import 'device_detail_controller.dart';
import 'device_detail_insets.dart';
import 'tabs/device_info_tab.dart';
import 'tabs/device_preview_tab.dart';
import 'tabs/device_publish_rate_tab.dart';
import 'tabs/device_schedule_tab.dart';

/// 设备详情 Tab 壳：弹窗尺寸 + Tab 栏 + 当前 Tab 内容。
class LcdDeviceDetailPage extends StatefulWidget {
  const LcdDeviceDetailPage({
    required this.device,
    required this.accentColor,
    required this.propertyName,
    this.initialTab = LcdDeviceDetailTab.info,
    this.listController,
    super.key,
  });

  final LcdDeviceEntity device;
  final Color accentColor;
  final String propertyName;
  final LcdDeviceDetailTab initialTab;
  final LcdDevicesController? listController;

  @override
  State<LcdDeviceDetailPage> createState() => _LcdDeviceDetailPageState();
}

class _LcdDeviceDetailPageState extends State<LcdDeviceDetailPage> {
  late final LcdDeviceDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LcdDeviceDetailController(
      device: widget.device,
      accentColor: widget.accentColor,
      propertyName: widget.propertyName,
      initialTab: widget.initialTab,
      listController: widget.listController,
    );
    unawaited(_controller.bootstrap());
  }

  @override
  void dispose() {
    unawaited(_controller.disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    final fills = AppDialogInteraction.maybeOf(context)?.fillsBounds ?? false;
    final theme = shad.Theme.of(context);
    final titleGap = theme.density.baseGap * theme.scaling;

    return AppFormDialog(
      title: Obx(() {
        final index = _controller.tab.value.index;
        return Align(
          alignment: Alignment.centerLeft,
          child: AppTabs(
            index: index,
            onChanged: _controller.selectTabIndex,
            selectedColor: const Color(0xFFFFFFFF),
            children: const [
              AppTabItem(child: Text('设备信息')),
              AppTabItem(child: Text('播放排期')),
              AppTabItem(child: Text('节目单预览')),
              AppTabItem(child: Text('上刊率分析')),
            ],
          ),
        );
      }),
      constraints: fills
          ? const BoxConstraints()
          : const BoxConstraints(maxWidth: 1500),
      padding: kDeviceDetailDialogPadding,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceOpacity: 1,
      // 待上游：AppFormDialog 补标题与内容间距参数后回收。
      content: Container(
        width: double.infinity,
        height: fills ? double.infinity : dialogHeight,
        padding: EdgeInsets.only(top: kDeviceDetailEdge - titleGap),
        child: Obx(() {
          return switch (_controller.tab.value) {
            LcdDeviceDetailTab.info => DeviceInfoTab(controller: _controller),
            LcdDeviceDetailTab.schedule => DeviceScheduleTab(
              controller: _controller,
            ),
            LcdDeviceDetailTab.preview => DevicePreviewTab(
              controller: _controller,
            ),
            LcdDeviceDetailTab.publishRate => DevicePublishRateTab(
              controller: _controller,
            ),
          };
        }),
      ),
      actions: const [],
    );
  }
}

/// 打开设备详情弹窗。
void showLcdDeviceDetailDialog(
  BuildContext context, {
  required LcdDeviceEntity device,
  required Color accentColor,
  required String propertyName,
  LcdDeviceDetailTab initialTab = LcdDeviceDetailTab.info,
}) {
  final lx = LxScope.maybeOf(context);
  final listController = lx != null && lx.contains<LcdDevicesController>()
      ? lx.find<LcdDevicesController>()
      : null;
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1500, initialHeight),
    builder: (dialogContext) => LcdDeviceDetailPage(
      device: device,
      accentColor: accentColor,
      propertyName: propertyName,
      initialTab: initialTab,
      listController: listController,
    ),
  );
}
