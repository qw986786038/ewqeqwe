import 'package:flutter/widgets.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import '../device_detail_map.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

import '../device_detail_controller.dart';

/// 打开设备位置地图放大弹窗。
///
/// macOS 上同时存在详情小地图与放大地图两个 WKWebView 时，上层无法拖动；
/// 打开期间通过 [LcdDeviceDetailController.mapPreviewOpen] 卸载小地图。
Future<void> showDeviceMapPreviewDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
}) async {
  controller.mapPreviewOpen.value = true;
  // 等一帧让详情小地图先从树上卸掉，再挂放大地图（避免双 PlatformView 并存）。
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) {
    controller.mapPreviewOpen.value = false;
    return;
  }
  try {
    final screen = MediaQuery.sizeOf(context);
    final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
    await showAppWindowDialog<void>(
      context: context,
      resizable: true,
      initialSize: Size(960, initialHeight),
      builder: (dialogContext) =>
          DeviceMapPreviewDialog(controller: controller),
    ).future;
  } finally {
    controller.mapPreviewOpen.value = false;
  }
}

/// 设备位置预览：大图查看当前设备标记。
class DeviceMapPreviewDialog extends StatelessWidget {
  const DeviceMapPreviewDialog({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return AppFormDialog(
      title: Obx(() {
        final device = controller.device;
        return Text(
          device.displayName.trim().isEmpty ? '设备位置' : device.displayName,
        );
      }),
      constraints: const BoxConstraints(maxWidth: 960),
      content: SizedBox(
        width: 920,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Obx(() {
                  final device = controller.device;
                  if (!device.hasMapPoint) {
                    return const Center(child: AppEmptyState());
                  }
                  // 不用 ClipRRect：macOS PlatformView 上裁剪会挡住交互。
                  return DeviceDetailAmapWidget(
                    device: device,
                    showZoomControl: true,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
