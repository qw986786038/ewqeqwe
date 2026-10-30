import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/entity/lcd/ad_file_list_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_customer_order_file_entity.dart';
import 'package:yidivination/bokong/pages/orders/orders_controller.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/ad_file_info_sidebar.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/change_sidebar_icon_dialog.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/office_card_icon.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

/// 客户订单二级侧栏：主订单文件信息（ShowDoc 1585）。
class AdCustomerOrderInfoSidebar extends StatelessWidget {
  const AdCustomerOrderInfoSidebar({
    required this.file,
    required this.loading,
    required this.onAddTag,
    this.onDeleteTag,
    this.fallbackTitle,
    this.avatarIcon,
    this.iconUpdateId,
    this.onIconUpdated,
    this.width = 344,
    super.key,
  });

  final AdCustomerOrderFileEntity? file;
  final bool loading;
  final Future<bool> Function(String tag) onAddTag;
  final Future<bool> Function(String tag)? onDeleteTag;
  final String? fallbackTitle;
  final String? avatarIcon;

  /// ShowDoc 1514：type=4 主订单，传订单 id。
  final int? iconUpdateId;
  final ValueChanged<String>? onIconUpdated;
  final double width;

  @override
  Widget build(BuildContext context) {
    final info = file?.file_info;
    final resolvedAvatar = avatarIcon ?? info?.avatar_icon;
    final title = () {
      final name = info?.name?.trim();
      if (name != null && name.isNotEmpty) return name;
      final fallback = fallbackTitle?.trim();
      if (fallback != null && fallback.isNotEmpty) return fallback;
      return '-';
    }();
    final tags = parseAdFileListTags(file?.tag_list);
    final publishes = file?.publish_order_info ?? const [];

    Future<void> changeIcon() async {
      final id = iconUpdateId;
      if (id == null) {
        showWarn('请先选择订单');
        return;
      }
      final result = await showChangeSidebarIconDialog(
        context,
        iconType: SidebarAvatarIconType.order,
        updateId: id,
        currentAvatarIcon: resolvedAvatar,
      );
      if (result == null) return;
      onIconUpdated?.call(result.avatarIcon);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (loading && file == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AppCircularProgressIndicator(),
              ),
            ).expanded()
          else
            Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OrderSummaryCard(
                  title: title,
                  avatarIcon: resolvedAvatar,
                  orderDays: info?.order_days ?? 0,
                  chargeType: info?.charge_type?.trim().isNotEmpty == true
                      ? info!.charge_type!.trim()
                      : '-',
                  onChangeIcon: changeIcon,
                ),
                SidebarFileTagsCard(
                  tags: tags,
                  onAddTag: onAddTag,
                  onDeleteTag: onDeleteTag,
                ),
                _PublishOrdersSection(items: publishes),
              ],
            ).scroll().expanded(),
        ],
      ),
    ).width(width);
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.title,
    this.avatarIcon,
    required this.orderDays,
    required this.chargeType,
    this.onChangeIcon,
  });

  final String title;
  final String? avatarIcon;
  final int orderDays;
  final String chargeType;
  final VoidCallback? onChangeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final rows = [
      (label: '订单天数', value: '$orderDays'),
      (label: '收费类型', value: chargeType),
    ];
    final accent = sidebarHeaderAccent(avatarIcon, templateBackground: false);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2129),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              spacing: 12,
              children: [
                SidebarAvatarIcon(
                  avatarIcon: avatarIcon,
                  size: 40,
                  iconSize: 16,
                  fallbackAsset: 'assets/images/folder_icon.png',
                ),
                AppText.body(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ).expanded(),
                if (onChangeIcon != null)
                  AppButton.primary(
                    size: AppButtonSize.small,
                    config: const AppButtonConfig(height: 20),
                    color: const Color(0x1AFFFFFF),
                    onPressed: onChangeIcon,
                    child: Text(
                      '更改',
                      style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const AppDivider.horizontal(indent: 32, endIndent: 32),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  AppText.caption(
                    rows[i].label,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ).expanded(),
                  AppText.title(
                    rows[i].value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublishOrdersSection extends StatelessWidget {
  const _PublishOrdersSection({required this.items});

  final List<AdCustomerOrderPublishInfoEntity> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText.title('发布单信息'),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppEmptyState()),
            )
          else
            for (final item in items) _PublishOrderCard(item: item),
        ],
      ),
    );
  }
}

class _PublishOrderCard extends StatelessWidget {
  const _PublishOrderCard({required this.item});

  final AdCustomerOrderPublishInfoEntity item;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final playType = item.play_type?.trim().isNotEmpty == true
        ? item.play_type!.trim()
        : '-';
    final frequency = item.play_frequency?.trim().isNotEmpty == true
        ? item.play_frequency!.trim()
        : '-';
    final days = item.order_days == null ? '-' : '${item.order_days}天';
    final mode = item.play_mode?.trim().isNotEmpty == true
        ? item.play_mode!.trim()
        : '-';
    final dateRange = _publishDateRange(
      item.publish_date_start,
      item.publish_date_end,
    );
    final statusLabel = _orderStatusLabel(item.order_status);
    final progress = ((item.progress ?? 0).clamp(0, 100)) / 100.0;
    final statusColor = _orderStatusColor(
      item.order_status,
      paused: colors.destructive,
      muted: colors.mutedForeground,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              if (playType != '-')
                AppBadge.custom(
                  color: colors.primary,
                  appearance: AppBadgeStyle.soft,
                  child: Text(playType, style: const TextStyle(fontSize: 14)),
                ),
              AppText.body(
                frequency,
                style: TextStyle(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _PublishMeta(label: '订单天数', value: days).expanded(),
              _PublishMeta(label: '播放模式', value: mode).expanded(),
            ],
          ),
          _PublishMeta(label: '上刊日期', value: dateRange),
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.caption(
                '订单状态',
                style: TextStyle(color: colors.mutedForeground, fontSize: 14),
              ),
              Row(
                spacing: 8,
                children: [
                  AppText.body(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: statusColor,
                      ),
                    ),
                  ),
                  AppText.caption(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublishMeta extends StatelessWidget {
  const _PublishMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return Column(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.caption(
          label,
          style: TextStyle(color: colors.mutedForeground, fontSize: 14),
        ),
        AppText.body(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

String _publishDateRange(String? start, String? end) {
  final s = start?.trim();
  final e = end?.trim();
  if ((s == null || s.isEmpty) && (e == null || e.isEmpty)) return '-';
  return '${s ?? '-'} ~ ${e ?? '-'}';
}

String _orderStatusLabel(int? status) {
  return switch (status) {
    0 => '未执行',
    1 => '执行中',
    2 => '已完播',
    3 => '已暂停',
    _ => '-',
  };
}

/// 与订单卡一致：执行中绿 / 已完播蓝 / 已暂停红；未执行等用 muted。
Color _orderStatusColor(
  int? status, {
  required Color paused,
  required Color muted,
}) {
  return switch (status) {
    1 => kOrderPlayRunningColor,
    2 => kOrderPlayEndedColor,
    3 => paused,
    _ => muted,
  };
}
