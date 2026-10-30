import 'dart:math' as math;
import 'package:yidivination/bokong/widget/app_empty_state.dart';

import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart'
    show ComponentTheme, OutlineButtonTheme;
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/pages/lcd_devices/lcd_devices_controller.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/lcd_device_status_icon.dart';
import '../device_detail_controller.dart';
import '../device_detail_insets.dart';
import '../device_detail_publish_rate_label.dart';
import '../device_detail_status_badge.dart';
import '../device_detail_title_icon.dart';

/// 上刊率分析 Tab：单日查询 + 区间对比趋势。
class DevicePublishRateTab extends StatelessWidget {
  const DevicePublishRateTab({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  Widget _onlineBadge({required int? status, required String? text}) {
    final label = (text?.trim().isNotEmpty == true) ? text!.trim() : null;
    final online = status == 1 || label == '在线';
    if (online) {
      if (label == null || label == '在线') {
        return deviceDetailStatusBadge(LcdDeviceStatus.online);
      }
    } else if (label == null || label == '离线') {
      return deviceDetailStatusBadge(LcdDeviceStatus.offline);
    }
    const size = AppBadgeSize(
      fontSize: 14,
      height: 20,
      padding: EdgeInsets.zero,
      iconSize: 12,
      contentGap: 4,
    );
    if (online) {
      return AppBadge.success(
        size: size,
        appearance: AppBadgeStyle.plain,
        leading: const LcdDeviceStatusIcon.online(size: 12),
        child: Text(label!),
      );
    }
    return AppBadge.secondary(
      size: size,
      appearance: AppBadgeStyle.plain,
      leading: const LcdDeviceStatusIcon.offline(size: 12),
      child: Text(label!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final headerHeight = AppControlMetricsScope.resolve(context).buttonHeight;
    final c = controller;
    return Padding(
      padding: kDeviceDetailPagePadding,
      child: Column(
        spacing: 16,
        children: [
          AppCard(
            borderRadius: BorderRadius.circular(24),
            borderWidth: 0,
            padding: kDeviceDetailHeaderPadding,
            child: SizedBox(
              height: headerHeight,
              child: Obx(() {
                final device = c.device;
                final daily = c.publishRateDaily.value;
                final name = daily?.deviceName?.trim().isNotEmpty == true
                    ? daily!.deviceName!.trim()
                    : device.displayName;
                final building = daily?.building?.trim().isNotEmpty == true
                    ? daily!.building!.trim()
                    : (device.building?.trim() ?? '');
                final floor = daily?.floor?.trim().isNotEmpty == true
                    ? daily!.floor!.trim()
                    : (device.media_address?.trim() ?? '');
                final onlineStatus = daily?.onlineStatus;
                final onlineText =
                    daily?.onlineStatusText?.trim().isNotEmpty == true
                    ? daily!.onlineStatusText!.trim()
                    : device.displayStatusLabel;
                return Row(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.h3(name, style: kDeviceDetailHeaderTitleStyle),
                    if (building.isNotEmpty)
                      AppBadge.primary(
                        child: Text(building),
                        shape: AppBadgeShape.square,
                        size: AppBadgeSize.normal.copyWith(height: 20),
                      ),
                    if (floor.isNotEmpty)
                      AppText.subtitle(
                        floor,
                        style: kDeviceDetailHeaderTextStyle,
                      ),
                    const SizedBox(width: 8),
                    _onlineBadge(
                      status:
                          onlineStatus ??
                          (device.displayStatus == LcdDeviceStatus.online
                              ? 1
                              : 0),
                      text: onlineText,
                    ),
                    const SizedBox(width: 8),
                    deviceDetailPublishRateLabel(
                      context,
                      c.publishRateDailyPercentText,
                    ),
                  ],
                );
              }),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              SizedBox(
                width: 400,
                height: double.infinity,
                child: AppCard(
                  borderRadius: BorderRadius.circular(24),
                  borderWidth: 0,
                  padding: const EdgeInsets.all(20),
                  child: Obx(() {
                    final day = c.publishRateDay.value;
                    final loading = c.loadingPublishRateDaily.value;
                    final rate = c.publishRateDailyPercent;
                    final stats = c.publishRateDaily.value?.statistics;
                    final shouldCount = stats?.shouldPublishCount ?? 0;
                    final publishedCount = stats?.publishedCount ?? 0;
                    final unpublishedCount = stats?.unpublishedCount ?? 0;
                    final progress = (rate / 100).clamp(0.0, 1.0);
                    final rateText = rate % 1 == 0
                        ? '${rate.toInt()}%'
                        : '${rate.toStringAsFixed(1)}%';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            deviceDetailTitleIcon(
                              context,
                              AppLucideIcons.calendarSearch,
                            ),
                            const AppText.title('单日上刊率查询'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppFieldScope.horizontal(
                          labelWidth: 60,
                          child: AppControlHeight(
                            height: 32,
                            child: AppDatePickerFormField(
                              key: ValueKey(
                                'publish-rate-day-${day.millisecondsSinceEpoch}',
                              ),
                              label: '查看日期',
                              initialValue: day,
                              onChanged: c.setPublishRateDay,
                            ),
                          ),
                        ),
                        Expanded(
                          child: loading
                              ? const Center(child: Text('加载中…'))
                              : Column(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: _PublishRateRing(
                                          progress: progress,
                                          rateText: rateText,
                                          color: colors.primary,
                                          trackColor: colors.muted,
                                          labelColor: colors.mutedForeground,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Column(
                                          spacing: 6,
                                          children: [
                                            const Text(
                                              '应上刊',
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.2,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              spacing: 6,
                                              children: [
                                                Image.asset(
                                                  'assets/images/publish_rate_should.png',
                                                  width: 18,
                                                  height: 18,
                                                  filterQuality:
                                                      FilterQuality.medium,
                                                ),
                                                Text(
                                                  '$shouldCount次',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ).expanded(),
                                        Column(
                                          spacing: 6,
                                          children: [
                                            const Text(
                                              '已上刊',
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.2,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              spacing: 6,
                                              children: [
                                                Image.asset(
                                                  'assets/images/publish_rate_done.png',
                                                  width: 18,
                                                  height: 18,
                                                  filterQuality:
                                                      FilterQuality.medium,
                                                ),
                                                Text(
                                                  '$publishedCount次',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ).expanded(),
                                        Column(
                                          spacing: 6,
                                          children: [
                                            const Text(
                                              '未上刊',
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.2,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              spacing: 6,
                                              children: [
                                                Image.asset(
                                                  'assets/images/publish_rate_miss.png',
                                                  width: 18,
                                                  height: 18,
                                                  filterQuality:
                                                      FilterQuality.medium,
                                                ),
                                                Text(
                                                  '$unpublishedCount次',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ).expanded(),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              Obx(() {
                final preset = c.publishRateListPreset.value;
                final range = c.publishRateListRange.value;
                final loading = c.loadingPublishRateList.value;
                final series = c.publishRateTrendSeries;
                final labels = c.publishRateTrendLabels;
                final maxY = c.publishRateTrendMaxY;
                final yInterval = maxY <= 100 ? 25.0 : (maxY / 4);
                return Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText.title('此设备的平均上刊率和上刊率趋势'),
                    ComponentTheme<OutlineButtonTheme>(
                      data: OutlineButtonTheme(
                        decoration: (context, states, value) {
                          if (value is! BoxDecoration) return value;
                          if (states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.pressed) ||
                              states.contains(WidgetState.disabled)) {
                            return value;
                          }
                          return value.copyWith(color: const Color(0xFFFFFFFF));
                        },
                      ),
                      child: AppControlMetricsScope(
                        metrics: AppControlMetricsScope.resolve(
                          context,
                        ).copyWith(height: 32, buttonHeight: 32),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            AppToggleGroup<PublishRateListPreset>.single(
                              value: preset,
                              allowEmpty: false,
                              mode: AppWidgetGroupMode.plain,
                              onChanged: c.selectPublishRateListPreset,
                              items: const [
                                AppToggleGroupItem(
                                  value: PublishRateListPreset.all,
                                  child: Text('全部'),
                                ),
                                AppToggleGroupItem(
                                  value: PublishRateListPreset.year1,
                                  child: Text('近一年'),
                                ),
                                AppToggleGroupItem(
                                  value: PublishRateListPreset.month6,
                                  child: Text('近6个月'),
                                ),
                                AppToggleGroupItem(
                                  value: PublishRateListPreset.day90,
                                  child: Text('近90天'),
                                ),
                                AppToggleGroupItem(
                                  value: PublishRateListPreset.day30,
                                  child: Text('近30天'),
                                ),
                              ],
                            ),
                            AppDatePicker.range(
                              rangeValue: range,
                              onRangeChanged: c.setPublishRateListRange,
                            ).width(260),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      spacing: 16,
                      children: [
                        _AvgRateCard(
                          label: '此设备平均上刊率',
                          value: c.publishRateDeviceAvgText,
                          color: const Color(0xFF0091FF),
                          chartAsset:
                              'assets/images/publish_rate_chart_device.svg',
                        ).expanded(),
                        _AvgRateCard(
                          label: 'TOP1设备平均上刊率',
                          value: c.publishRateTop1AvgText,
                          color: const Color(0xFF14B8A6),
                          chartAsset:
                              'assets/images/publish_rate_chart_top1.svg',
                        ).expanded(),
                        _AvgRateCard(
                          label: '与TOP1设备的差值',
                          value: c.publishRateGapWithTop1Text,
                          color: const Color(0xFFF5A623),
                          chartAsset:
                              'assets/images/publish_rate_chart_gap.svg',
                        ).expanded(),
                      ],
                    ),
                    AppCard(
                      borderRadius: BorderRadius.circular(24),
                      borderWidth: 0,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppText.title('此设备的上刊率趋势图'),
                          Expanded(
                            child: loading
                                ? const Center(child: Text('加载中…'))
                                : series.isEmpty
                                ? const Center(child: const AppEmptyState())
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return AppLineChart.area(
                                        height: constraints.maxHeight,
                                        showLegend: true,
                                        maxRenderedPoints: 100,
                                        series: series,
                                        xAxis: AppChartAxis(
                                          formatter: (value) {
                                            if (labels.isEmpty) {
                                              return '';
                                            }
                                            return labels[value.round().clamp(
                                              0,
                                              labels.length - 1,
                                            )];
                                          },
                                        ),
                                        yAxis: AppChartAxis(
                                          min: 0,
                                          max: maxY,
                                          interval: yInterval,
                                          formatter: (value) =>
                                              '${value.toInt()}%',
                                        ),
                                        tooltipStyle: AppPointerTooltipStyle(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            12,
                                            14,
                                            12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFFFF),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: AppTheme.of(context)
                                                .shadows
                                                .resolve(
                                                  context,
                                                  level:
                                                      AppShadowLevel.floating,
                                                  colorMode:
                                                      AppShadowColorMode.custom,
                                                  color: ShadcnTheme.of(
                                                    context,
                                                  ).colorScheme.foreground,
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 2),
                                                ),
                                          ),
                                        ),
                                        tooltipWidgetBuilder: (context, data) {
                                          return _PublishRateTrendTooltip(
                                            data: data,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ).expanded(),
                  ],
                );
              }).expanded(),
            ],
          ).expanded(),
        ],
      ),
    );
  }
}

/// 上刊率趋势悬停：日期加深加大，附文减淡，系列色圆点与数值。
class _PublishRateTrendTooltip extends StatelessWidget {
  const _PublishRateTrendTooltip({required this.data});

  final AppLineChartTooltipData data;

  static String _rateText(double? y) {
    if (y == null) return '-';
    return y % 1 == 0 ? '${y.toInt()}%' : '${y.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(
          data.xLabel,
          style: const TextStyle(
            color: Color(0xFF1D2129),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        for (final item in data.items)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                item.hit.series.name,
                style: const TextStyle(
                  color: Color(0xFF4E5969),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              Text(
                _rateText(item.hit.point.y),
                style: TextStyle(
                  color: item.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 单日上刊率环形进度（中心显示百分比）。
class _PublishRateRing extends StatelessWidget {
  const _PublishRateRing({
    required this.progress,
    required this.rateText,
    required this.color,
    required this.trackColor,
    required this.labelColor,
  });

  final double progress;
  final String rateText;
  final Color color;
  final Color trackColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 214,
      child: CustomPaint(
        painter: _PublishRateRingPainter(
          progress: progress,
          color: color,
          trackColor: trackColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.h1(
              rateText,
              style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            AppText.caption(
              '上刊率',
              style: TextStyle(color: labelColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishRateRingPainter extends CustomPainter {
  const _PublishRateRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.1;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    final sweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    if (sweep <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PublishRateRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

/// 平均上刊率卡片：标题在上，数值与装饰柱同排贴底对齐。
class _AvgRateCard extends StatelessWidget {
  const _AvgRateCard({
    required this.label,
    required this.value,
    required this.color,
    required this.chartAsset,
  });

  final String label;
  final String value;
  final Color color;
  final String chartAsset;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return SizedBox(
      height: 94,
      child: AppCard(
        borderRadius: BorderRadius.circular(24),
        borderWidth: 0,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.caption(
                  label,
                  style: TextStyle(color: colors.mutedForeground),
                ),
                AppText.h1(
                  value,
                  style: TextStyle(color: color, fontSize: 28, height: 1),
                ),
              ],
            ).expanded(),
            // SVG 柱底在 y=40（画布 48），下移 6 与数字字形底边齐平。
            Transform.translate(
              offset: const Offset(0, 6),
              child: SvgPicture.asset(
                chartAsset,
                width: 86,
                height: 48,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
