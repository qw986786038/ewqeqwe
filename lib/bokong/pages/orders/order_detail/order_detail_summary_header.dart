import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/customer_avatar_icon.dart';
import '../orders_controller.dart';
import 'order_detail_controller.dart';
import 'order_detail_insets.dart';

/// 摘要信息四列统一行高，保证标签行、值行横向对齐。
const double _kLabelHeight = 20;
const double _kValueHeight = 24;

/// 订单详情各 Tab 共用顶栏摘要（数据来自列表传入的订单）。
class OrderDetailSummaryHeader extends StatelessWidget {
  const OrderDetailSummaryHeader({required this.controller, super.key});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final order = c.order;
    final progress = c.progress;
    final percent = (progress * 100).round();
    final colors = ShadcnTheme.of(context).colorScheme;
    final barColor = orderPlayStatusColor(c.status, paused: colors.destructive);
    final customerName = c.displayCustomerName;
    final payLabel = switch (order.order_pay) {
      0 => '免费',
      1 => '付费',
      _ =>
        (order.order_pay_label?.trim().isNotEmpty == true)
            ? order.order_pay_label!.trim()
            : '付费',
    };
    // 订单类型优先接口 source_type_label / customer_order。
    final typeLabel = () {
      for (final raw in [
        order.source_type_label,
        order.customer_order?.source_type_label,
      ]) {
        final label = raw?.trim();
        if (label != null && label.isNotEmpty) return label;
      }
      return 'SAAS';
    }();
    final badgeSize = AppBadgeSize.normal.copyWith(height: 20);
    final statusBadge = switch (c.status) {
      OrderPlayStatus.running => AppBadge.success(
        appearance: AppBadgeStyle.plain,
        size: badgeSize,
        leading: const Icon(AppMaterialIcons.circle, size: 8),
        child: const Text('执行中'),
      ),
      OrderPlayStatus.pending => AppBadge.destructive(
        appearance: AppBadgeStyle.plain,
        size: badgeSize,
        leading: const Icon(AppMaterialIcons.circle, size: 8),
        child: const Text('已暂停'),
      ),
      OrderPlayStatus.ended => AppBadge.custom(
        color: kOrderPlayEndedColor,
        appearance: AppBadgeStyle.plain,
        size: badgeSize,
        leading: const Icon(AppMaterialIcons.circle, size: 8),
        child: const Text('已完播'),
      ),
    };

    return AppCard(
      borderRadius: BorderRadius.circular(24),
      borderWidth: 0,
      padding: kOrderDetailHeaderPadding,
      child: Row(
        spacing: 12,
        children: [
          const CustomerAvatarIcon(
            size: 80,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              AppText.h4(customerName),
              const SizedBox(height: 4),
              AppText.caption('所属行业'),
              Text(
                c.displayIndustryLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ).expanded(),
          AppDescriptions(
            columns: 4,
            minColumnWidth: 100,
            maxColumnWidth: 300,
            density: AppDensity.compact,
            labelAlignment: Alignment.center,
            valueAlignment: Alignment.center,
            spacing: 20,
            contentGap: 6,
            items: [
              AppDescriptionItem(
                minWidth: 200,
                label: const SizedBox(
                  height: _kLabelHeight,
                  child: Center(child: Text('订单编号')),
                ),
                value: SizedBox(
                  height: _kValueHeight,
                  child: Center(child: Text(c.orderNo)),
                ),
              ),
              AppDescriptionItem(
                label: const SizedBox(
                  height: _kLabelHeight,
                  child: Center(child: Text('订单类型')),
                ),
                value: SizedBox(
                  height: _kValueHeight,
                  child: Center(
                    child: AppBadge.custom(
                      color: const Color(0xFF7C3AED),
                      appearance: AppBadgeStyle.soft,
                      shape: AppBadgeShape.square,
                      size: badgeSize,
                      child: Text(typeLabel),
                    ),
                  ),
                ),
              ),
              AppDescriptionItem(
                minWidth: 200,
                label: SizedBox(
                  height: _kLabelHeight,
                  child: Row(
                    children: [const Text('状态'), const Spacer(), statusBadge],
                  ),
                ),
                value: SizedBox(
                  height: _kValueHeight,
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 8,
                          child: AppProgress(
                            progress: progress,
                            color: barColor,
                            backgroundColor: colors.muted,
                          ),
                        ),
                      ),
                      AppText.caption(
                        '$percent%',
                        style: TextStyle(
                          color: barColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppDescriptionItem(
                label: const SizedBox(
                  height: _kLabelHeight,
                  child: Center(child: Text('付费类型')),
                ),
                value: SizedBox(
                  height: _kValueHeight,
                  child: Center(
                    child: AppBadge.custom(
                      color: const Color(0xFFF59E0B),
                      appearance: AppBadgeStyle.soft,
                      shape: AppBadgeShape.square,
                      size: badgeSize,
                      child: Text(payLabel),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
