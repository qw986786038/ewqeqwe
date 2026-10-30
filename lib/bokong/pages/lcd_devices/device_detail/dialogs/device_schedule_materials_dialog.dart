import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/pages/lcd/program/lcd_program_add_dialog.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/schedule_material_card.dart';

import '../device_detail_controller.dart';

/// 打开排期广告物料「查看全部」弹窗。
void showDeviceScheduleMaterialsDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(1080, initialHeight),
    builder: (dialogContext) =>
        DeviceScheduleMaterialsDialog(controller: controller),
  );
}

/// 广告物料弹窗：比例 Tab + 网格卡片（对齐素材库样式）。
class DeviceScheduleMaterialsDialog extends StatefulWidget {
  const DeviceScheduleMaterialsDialog({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  @override
  State<DeviceScheduleMaterialsDialog> createState() =>
      _DeviceScheduleMaterialsDialogState();
}

class _DeviceScheduleMaterialsDialogState
    extends State<DeviceScheduleMaterialsDialog> {
  static const double _gridGap = 16;
  static const int _maxColumns = 5;
  static const double _itemHeight = 270;
  static const double _cardBottomHeight = 64;

  static double get _thumbHeight => _itemHeight - _cardBottomHeight;

  var _thumbRatio = AdMediaThumbRatio.r4x3;

  LcdDeviceDetailController get _c => widget.controller;

  Future<void> _addProgram() async {
    final schedule = _c.scheduleDevice.value;
    if (schedule?.id == null) {
      showWarn('该设备当日无排期，无法创建节目');
      return;
    }
    await showLcdProgramAddDialog(
      context: context,
      device: schedule!,
      onSubmit: _c.createProgram,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return AppFormDialog(
      title: const Text('广告物料'),
      constraints: const BoxConstraints(maxWidth: 1080),
      content: SizedBox(
        width: 1040,
        height: maxHeight.clamp(420, 640),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                AppTabs(
                  index: _thumbRatio.index,
                  selectedColor: Colors.white,
                  onChanged: (index) => setState(
                    () => _thumbRatio = AdMediaThumbRatio.values[index],
                  ),
                  children: const [
                    AppTabItem(child: Text('1:1')),
                    AppTabItem(child: Text('4:3')),
                    AppTabItem(child: Text('16:9')),
                  ],
                ),
                const Spacer(),
                AppButton.primary(
                  color: const Color(0xFF00A0EC),
                  onPressed: _addProgram,
                  leading: const Icon(AppLucideIcons.plus, size: 16),
                  child: const Text('新增'),
                ),
              ],
            ),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final materials = _c.materials.toList(growable: false);
                  if (materials.isEmpty) {
                    return const Center(child: AppEmptyState());
                  }
                  return FixedSizeGrid(
                    itemWidth: _thumbHeight * _thumbRatio.layoutFactor,
                    itemHeight: _itemHeight,
                    spacing: _gridGap,
                    maxColumns: _maxColumns,
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      final material = materials[index];
                      return SizedBox.expand(
                        child: ScheduleMaterialCard(
                          material: material,
                          fillCell: true,
                          onTap: () => showProgramMaterialPreviewDialog(
                            context: context,
                            material: material,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(context),
          child: const Text('取消'),
        ),
        AppButton.primary(
          onPressed: () => AppOverlay.close(context),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
