part of 'analytics_page.dart';

// ---------------------------------------------------------------------------
// 客户订单范围页面
// ---------------------------------------------------------------------------

/// 数据分析 · 客户订单范围。
class AnalyticsOrdersPage extends StatelessWidget {
  const AnalyticsOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OrdersBody();
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.lx.find<AnalyticsOrdersController>();

    return Scaffold(
      body: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Obx(() {
              // ⚠️ 订单指标接口已变更、暂未接入：接口无数据时先用占位数据把卡片撑起来。
              final metrics = _orderMetricsDisplayOrder(
                controller.metrics.isEmpty
                    ? _kOrderMetricsPlaceholder
                    : controller.metrics,
              );
              final activeModule = controller.activeModule;
              final districtRanks = controller.districtRanks;
              final customerOrderRanks = controller.customerOrderRanks;
              final industryOrderRanks = controller.industryOrderRanks;
              final propertyOrderRanks = controller.propertyOrderRanks;
              final districtRankPage = controller.districtRankPage.value;
              final customerOrderRankPage =
                  controller.customerOrderRankPage.value;
              final industryOrderRankPage =
                  controller.industryOrderRankPage.value;
              final propertyOrderRankPage =
                  controller.propertyOrderRankPage.value;
              final districtRankOffset =
                  (districtRankPage - 1) * AnalyticsController.rankVisibleRows;
              final customerOrderRankOffset =
                  (customerOrderRankPage - 1) *
                  AnalyticsController.rankVisibleRows;
              final industryOrderRankOffset =
                  (industryOrderRankPage - 1) *
                  AnalyticsController.rankVisibleRows;
              final propertyOrderRankOffset =
                  (propertyOrderRankPage - 1) *
                  AnalyticsController.rankVisibleRows;
              return Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (metrics.isEmpty)
                    const SizedBox(
                      height: 120,
                      child: Center(child: AppEmptyState()),
                    )
                  else
                    Row(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final metric in metrics)
                          _analyticsMetricCard(
                            metric: metric,
                            selected:
                                metric.key == activeModule &&
                                metric.key != 'total_customers',
                            plainIcon: true,
                            onPressed:
                                metric.key == null ||
                                    metric.key == 'total_customers'
                                ? null
                                : () => controller.selectModule(metric.key),
                          ).expanded(),
                      ],
                    ),
                _SyncedRankExpandRow(
                  builder: (isExpanded, toggle) => [
                    _AnalyticsRankCard(
                      title: controller.districtTitle,
                      accent: const Color(0xFFF59E0B),
                      titleIcon: AppLucideIcons.mapPin,
                      bannerColors: const [Color(0xFF5B86F8), Color(0xFF3F5FEA)],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.districtTitle,
                        items: controller.districtRanksAll,
                        labelHeader: '城市区域',
                        valueHeader: '订单数量',
                      ),
                      actions: _districtRankTopSelect(controller),
                      child: Column(
                        spacing: 8,
                        children: [
                          _rankTable(
                            context: context,
                            items: districtRanks,
                            labelHeader: '城市区域',
                            valueHeader: '订单数量',
                            rankOffset: districtRankOffset,
                            striped: true,
                          ),
                          _analyticsPagination(
                            page: districtRankPage,
                            totalPages: controller.districtTotalPages,
                            onPageChanged: controller.setDistrictRankPage,
                          ),
                        ],
                      ),
                    ).expanded(flex: 67),
                    _AnalyticsRankCard(
                      title: controller.customerOrderTitle,
                      accent: const Color(0xFF6366F1),
                      titleIcon: AppLucideIcons.users,
                      bannerColors: const [Color(0xFF20C4A4), Color(0xFF0F9C84)],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.customerOrderTitle,
                        items: controller.customerOrderRanksAll,
                        labelHeader: '客户名称',
                        valueHeader: '订单数量',
                        showBar: false,
                      ),
                      actions: Obx(
                        () => _lowerRankTopSelect(
                          value: controller.customerOrderRankLimit.value,
                          onChanged: controller.setCustomerOrderRankLimit,
                        ),
                      ),
                      child: Column(
                        spacing: 8,
                        children: [
                          _orderRankTable(
                            context: context,
                            items: customerOrderRanks,
                            labelHeader: '客户名称',
                            rankOffset: customerOrderRankOffset,
                          ),
                          _analyticsPagination(
                            page: customerOrderRankPage,
                            totalPages: controller.customerOrderTotalPages,
                            onPageChanged: controller.setCustomerOrderRankPage,
                          ),
                        ],
                      ),
                    ).expanded(flex: 44),
                    _AnalyticsRankCard(
                      title: controller.industryOrderTitle,
                      accent: const Color(0xFF8B5CF6),
                      titleIcon: AppLucideIcons.tags,
                      bannerColors: const [Color(0xFFFCC43D), Color(0xFFF7A21B)],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.industryOrderTitle,
                        items: controller.industryOrderRanksAll,
                        labelHeader: '行业名称',
                        valueHeader: '订单数量',
                        showBar: false,
                      ),
                      actions: Obx(
                        () => _lowerRankTopSelect(
                          value: controller.industryOrderRankLimit.value,
                          onChanged: controller.setIndustryOrderRankLimit,
                        ),
                      ),
                      child: Column(
                        spacing: 8,
                        children: [
                          _orderRankTable(
                            context: context,
                            items: industryOrderRanks,
                            labelHeader: '行业名称',
                            rankOffset: industryOrderRankOffset,
                          ),
                          _analyticsPagination(
                            page: industryOrderRankPage,
                            totalPages: controller.industryOrderTotalPages,
                            onPageChanged: controller.setIndustryOrderRankPage,
                          ),
                        ],
                      ),
                    ).expanded(flex: 44),
                    _AnalyticsRankCard(
                      title: controller.propertyOrderTitle,
                      accent: const Color(0xFF2563EB),
                      titleIcon: AppLucideIcons.building2,
                      bannerColors: const [Color(0xFFB066F8), Color(0xFF8E45EA)],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.propertyOrderTitle,
                        items: controller.propertyOrderRanksAll,
                        labelHeader: '物业名称',
                        valueHeader: '订单数量',
                        showBar: false,
                      ),
                      actions: Obx(
                        () => _lowerRankTopSelect(
                          value: controller.propertyOrderRankLimit.value,
                          onChanged: controller.setPropertyOrderRankLimit,
                        ),
                      ),
                      child: Column(
                        spacing: 8,
                        children: [
                          _orderRankTable(
                            context: context,
                            items: propertyOrderRanks,
                            labelHeader: '物业名称',
                            rankOffset: propertyOrderRankOffset,
                          ),
                          _analyticsPagination(
                            page: propertyOrderRankPage,
                            totalPages: controller.propertyOrderTotalPages,
                            onPageChanged: controller.setPropertyOrderRankPage,
                          ),
                        ],
                      ),
                    ).expanded(flex: 44),
                  ],
                ),
              ],
              );
            }),
          ),
          AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 326,
              child: Row(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OrderTrendCard(
                    controller: controller,
                  ).expanded(flex: 17),
                  _OrderStatusCard(
                    controller: controller,
                  ).expanded(flex: 10),
                ],
              ),
            ),
          ),
        ],
      ).scroll(),
    );
  }
}

/// 「客户订单」范围顶部指标卡**占位数据**（新接口接入后删除）。
///
/// key 与排行 moudle 对齐，保证可点击同步下方排行。
const List<AnalyticsMetric> _kOrderMetricsPlaceholder = [
  AnalyticsMetric(
    key: 'total_orders',
    title: '订单总数量',
    value: '1,286',
    unit: '个',
    percent: '0.00%',
    percentUp: true,
    diffLabel: '较昨日',
    diffDisplay: '32',
    showDiffTrend: true,
    diffUp: false,
    icon: AppLucideIcons.monitor,
    iconAsset: 'assets/images/analytics/order_card_total.svg',
    accent: Color(0xFF08B780),
    fill: Color(0xFFD1FAE5),
  ),
  AnalyticsMetric(
    key: 'order_98inch',
    title: '98寸订单数量',
    value: '892',
    unit: '个',
    percent: '69.40%',
    percentUp: true,
    diffLabel: '占比',
    diffDisplay: '69.4%',
    showDiffTrend: false,
    diffUp: true,
    icon: AppLucideIcons.tv,
    iconAsset: 'assets/images/analytics/device_card_98inch.svg',
    accent: Color(0xFF0891B2),
    fill: Color(0xFFCFFAFE),
  ),
  AnalyticsMetric(
    key: 'order_86inch',
    title: '86寸订单数量',
    value: '394',
    unit: '个',
    percent: '30.60%',
    percentUp: true,
    diffLabel: '占比',
    diffDisplay: '30.6%',
    showDiffTrend: false,
    diffUp: true,
    icon: AppLucideIcons.monitor,
    iconAsset: 'assets/images/analytics/device_card_86inch.svg',
    accent: Color(0xFF6366F1),
    fill: Color(0xFFE0E7FF),
  ),
  AnalyticsMetric(
    key: 'completed_orders',
    title: '完播订单',
    value: '81',
    unit: '个',
    percent: '6.30%',
    percentUp: false,
    diffLabel: '占比',
    diffDisplay: '6.3%',
    showDiffTrend: false,
    diffUp: false,
    icon: AppLucideIcons.clipboardList,
    iconAsset: 'assets/images/analytics/order_card_completed.svg',
    accent: Color(0xFFE11D48),
    fill: Color(0xFFFFE4E6),
  ),
  AnalyticsMetric(
    key: 'total_customers',
    title: '客户总数',
    value: '1,205',
    unit: '个',
    percent: '93.70%',
    percentUp: true,
    diffLabel: '占比',
    diffDisplay: '93.7%',
    showDiffTrend: false,
    diffUp: true,
    icon: AppLucideIcons.users,
    iconAsset: 'assets/images/analytics/order_card_customers.png',
    accent: Color(0xFFC026D3),
    fill: Color(0xFFFAE8FF),
  ),
];

/// 「完播订单」「客户总数」固定配色：(accent, fill)。
const _kOrderMetricTones = <String, (Color, Color)>{
  'completed_orders': (Color(0xFFF97316), Color(0xFFFFEDD5)),
  'total_customers': (Color(0xFFF59E0B), Color(0xFFFEF3C7)),
};

AnalyticsMetric _withOrderMetricTone(AnalyticsMetric m) {
  final tone = _kOrderMetricTones[m.key];
  if (tone == null) return m;
  return AnalyticsMetric(
    key: m.key,
    title: m.title,
    value: m.value,
    unit: m.unit,
    percent: m.percent,
    percentUp: m.percentUp,
    diffLabel: m.diffLabel,
    diffDisplay: m.diffDisplay,
    showDiffTrend: m.showDiffTrend,
    diffUp: m.diffUp,
    icon: m.icon,
    iconAsset: m.iconAsset,
    accent: tone.$1,
    fill: tone.$2,
  );
}

/// 展示顺序：「完播订单」在「客户总数」左侧。
List<AnalyticsMetric> _orderMetricsDisplayOrder(List<AnalyticsMetric> metrics) {
  final list = metrics.map(_withOrderMetricTone).toList();
  final customersIdx = list.indexWhere((m) => m.key == 'total_customers');
  final completedIdx = list.indexWhere((m) => m.key == 'completed_orders');
  if (customersIdx < 0 || completedIdx < 0) return list;
  if (completedIdx < customersIdx) return list;
  final tmp = list[customersIdx];
  list[customersIdx] = list[completedIdx];
  list[completedIdx] = tmp;
  return list;
}

// ---------------------------------------------------------------------------
// 客户订单底部：经营趋势（左）+ 订单状态（右）
//
// ⚠️ 订单状态与趋势占位数据；新接口接入后替换。
// ---------------------------------------------------------------------------

/// 经营趋势：订单数 / 客户数 / 播放次数可切换；接口无数据时用占位曲线。
class _OrderTrendCard extends StatelessWidget {
  const _OrderTrendCard({required this.controller});

  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final title = controller.customerOrderTrendTitle;
      final series = controller.customerOrderTrendSeries;
      final maxY = controller.customerOrderTrendMaxY;
      final interval = controller.customerOrderTrendYInterval;
      final useThousands = controller.customerOrderTrendYUsesThousands;
      final tabIndex = (controller.orderTrendType.value - 1).clamp(0, 2);
      final preset = controller.orderTrendPreset.value;

      return _analyticsBorderCard(
        context: context,
        header: Padding(
          // 32 高的下拉框比标题行高约 8，顶部少 4 保持标题距顶 20。
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              AppText.title(title, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              AppControlMetricsScope(
                metrics: AppControlMetricsScope.resolve(
                  context,
                ).copyWith(height: 32),
                child: AppSelect<String>(
                  value: preset,
                  hintText: '近7天',
                  minWidth: 110,
                  options: AnalyticsController.orderTrendPresetOptions,
                  onChanged: controller.setOrderTrendPreset,
                ).width(110),
              ),
            ],
          ),
        ),
        // 标题行被 32 高下拉框撑高，顶部少给 10；纵轴顶部刻度文字有一半在图表外，
        // 间距多给 12。两处视觉间距约 20。
        bodyPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        expandBody: true,
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppTabs(
                index: tabIndex,
                selectedColor: Colors.white,
                selectedTextColor: kIconButtonForeground,
                onChanged: (index) => controller.setOrderTrendType(index + 1),
                children: [
                  for (final tab in AnalyticsController.orderTrendTypeLabels)
                    AppTabItem(child: Text(tab)),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return AppLineChart.area(
                  height: constraints.maxHeight,
                  showLegend: false,
                  showTooltip: true,
                  interactive: true,
                  keyboardNavigation: false,
                  maxRenderedPoints: 100,
                  samplingStrategy: AppChartSamplingStrategy.none,
                  series: series,
                  tooltipStyle: _analyticsTrendTooltipStyle(context),
                  tooltipWidgetBuilder: (context, data) {
                    return _AnalyticsTrendTooltip(data: data);
                  },
                  yAxis: AppChartAxis(
                    min: 0,
                    max: maxY,
                    interval: interval,
                    formatter: (value) => useThousands
                        ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
                        : '${value.toInt()}',
                  ),
                );
              },
            ).expanded(),
          ],
        ),
      );
    });
  }
}

/// 订单状态：环图 + 图例 + 到期订单四宫格。
class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.controller});

  final AnalyticsController controller;

  static const double _donutBoxSize = 150;

  /// 外径 = 内径 + 环宽 ≈ 74 → 直径约 148（撑满 150 的框）。
  static const double _donutHoleRadius = 44;
  static const double _donutRingRadius = 30;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return Obx(() {
      final title = controller.orderStatusTitle;
      final status = controller.orderStatusItems;
      final expiring = controller.orderExpiringItems;
      final hasPositive = status.any((item) => item.value > 0);

      return _analyticsBorderCard(
        context: context,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: AppText.title(title, style: const TextStyle(fontSize: 16)),
        ),
        bodyPadding: const EdgeInsets.all(20),
        expandBody: true,
        child: Center(
          child: Row(
            spacing: 20,
            children: [
              SizedBox.square(
                dimension: _donutBoxSize,
                child: AppPieChart.donut(
                  height: _donutBoxSize,
                  sections: [
                    if (!hasPositive)
                      const AppPieSection(
                        label: '-',
                        value: 1,
                        color: Color(0xFFE5E7EB),
                      )
                    else
                      for (final item in status)
                        AppPieSection(
                          label: item.label,
                          value: item.value,
                          color: item.color,
                        ),
                  ],
                  showLegend: false,
                  showValues: false,
                  valueFormatter: (value) => _formatRankValue(value),
                  dataBuilder: (chartData) => chartData.copyWith(
                    centerSpaceRadius: _donutHoleRadius,
                    sections: [
                      for (final section in chartData.sections)
                        section.copyWith(radius: _donutRingRadius),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 14,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in status)
                    _statusLegend(item, colors.mutedForeground),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  for (var i = 0; i < expiring.length; i += 2)
                    Row(
                      spacing: 10,
                      children: [
                        _expiringCell(expiring[i]).expanded(),
                        if (i + 1 < expiring.length)
                          _expiringCell(expiring[i + 1]).expanded()
                        else
                          const Spacer(),
                      ],
                    ),
                ],
              ).expanded(),
            ],
          ),
        ),
      );
    });
  }

  Widget _statusLegend(AnalyticsOrderStatusItem item, Color mutedForeground) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        AppText.caption(
          item.label,
          style: TextStyle(color: mutedForeground, fontSize: 13),
        ),
        AppText.caption(
          _formatRankValue(item.value),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        AppText.caption(
          '(${item.percent})',
          style: TextStyle(color: item.color, fontSize: 12),
        ),
      ],
    );
  }

  Widget _expiringCell(AnalyticsOrderExpiringItem data) {
    const black = Color(0xFF1D2129);
    // 仅「今日到期」数字标红；其余文案与数字保持黑色。
    final numberColor = data.label.contains('今日到期')
        ? const Color(0xFFEF4444)
        : black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: data.tile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 6,
        children: [
          AppText.caption(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: black, fontSize: 14),
          ),
          AppText.title(
            data.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: numberColor,
            ),
          ),
        ],
      ),
    );
  }
}
