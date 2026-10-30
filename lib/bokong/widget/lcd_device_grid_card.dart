import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/widget/lcd_device_status_icon.dart';

/// 在线状态文案色（与设备管理页 [AppBadge.success] 语义一致）。
const kLcdDeviceOnlineColor = Color(0xFF16A34A);

/// 设备网格卡片（设备管理 / 订单关联设备等场景共用）。
class LcdDeviceGridCard extends StatelessWidget {
  const LcdDeviceGridCard({
    super.key,
    required this.device,
    this.displayName,
    this.mediaAddress,
    this.selected = false,
    this.onTap,
    this.onDoubleTap,
  });

  final LcdDeviceEntity device;
  final String? displayName;
  final String? mediaAddress;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  static const _unselectedBorder = Color(0xFFE5E6EB);

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    const accent = LcdDevicesController.folderColor;
    final radius = BorderRadius.circular(28);
    final building = device.building?.trim() ?? '';
    final resolvedMediaAddress =
        mediaAddress?.trim() ?? device.media_address?.trim() ?? '';
    final region = device.displayRegion;
    final address = device.displayAddress;
    final name = () {
      final override = displayName?.trim();
      if (override != null && override.isNotEmpty) return override;
      return device.displayName;
    }();

    final statusWidget = switch (device.displayStatus) {
      LcdDeviceStatus.online => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const LcdDeviceStatusIcon.online(size: 12),
          const Text(
            '在线',
            style: TextStyle(
              fontSize: 14,
              color: kLcdDeviceOnlineColor,
              height: 1,
            ),
          ),
        ],
      ),
      LcdDeviceStatus.offline => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const LcdDeviceStatusIcon.offline(size: 12),
          Text(
            '离线',
            style: TextStyle(
              fontSize: 14,
              color: colors.mutedForeground,
              height: 1,
            ),
          ),
        ],
      ),
      LcdDeviceStatus.abnormal => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const LcdDeviceStatusIcon.abnormal(size: 12),
          Text(
            '异常',
            style: TextStyle(
              fontSize: 14,
              color: colors.destructive,
              height: 1,
            ),
          ),
        ],
      ),
    };

    const bodyWhite = Color(0xFFFFFFFF);
    final bodyColor = selected
        ? Color.lerp(bodyWhite, accent, 0.03) ?? bodyWhite
        : bodyWhite;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: LcdDevicesController.deviceItemHeight,
        child: Stack(
          children: [
            AppInkWell(
              onPressed: onTap,
              onDoubleTap: onDoubleTap,
              borderRadius: radius,
              hoverOpacity: 0,
              pressedOpacity: 0,
              child: AppCard(
                filled: true,
                fillColor: bodyColor,
                borderColor: selected ? accent : _unselectedBorder,
                borderWidth: 1,
                borderRadius: radius,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        AppAvatar.square(
                          name: name,
                          initialsCount: 1,
                          backgroundColor: kAvatarBackground,
                          foregroundColor: colors.primary,
                          size: 40,
                          borderRadius: 16,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              AppText.label(
                                name,
                                maxLines: 1,
                                scrollMode: AppTextScrollMode.hover,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (region.isNotEmpty)
                                AppText.caption(
                                  region,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (address.isNotEmpty)
                      AppText.caption(
                        address,
                        maxLines: 1,
                        scrollMode: AppTextScrollMode.hover,
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      spacing: 6,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (building.isNotEmpty)
                          AppBadge.custom(
                            color: accent,
                            appearance: AppBadgeStyle.soft,
                            shape: AppBadgeShape.square,
                            size: const AppBadgeSize(
                              fontSize: 14,
                              height: 24,
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              iconSize: 8,
                              contentGap: 4,
                            ),
                            child: Text(building),
                          ),
                        Expanded(
                          child: resolvedMediaAddress.isEmpty
                              ? const SizedBox.shrink()
                              : AppText.caption(
                                  resolvedMediaAddress,
                                  maxLines: 1,
                                  scrollMode: AppTextScrollMode.hover,
                                  style: const TextStyle(fontSize: 14),
                                ),
                        ),
                        statusWidget,
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                  painter: const _LcdDeviceGridCardCornerCheckPainter(
                    color: kSelectedCornerBadgeColor,
                    innerRadius: 16,
                  ),
                  child: const SizedBox(
                    width: 30,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8, right: 10),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          AppLucideIcons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LcdDeviceGridCardCornerCheckPainter extends CustomPainter {
  const _LcdDeviceGridCardCornerCheckPainter({
    required this.color,
    this.innerRadius = 16,
  });

  final Color color;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      bottomLeft: Radius.circular(innerRadius.clamp(0, size.shortestSide)),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LcdDeviceGridCardCornerCheckPainter oldDelegate,
  ) {
    return oldDelegate.color != color || oldDelegate.innerRadius != innerRadius;
  }
}
