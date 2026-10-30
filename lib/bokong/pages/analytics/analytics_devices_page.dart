part of 'analytics_page.dart';

// ---------------------------------------------------------------------------
// 设备管理范围页面
// ---------------------------------------------------------------------------

/// 数据分析 · 设备管理范围。
class AnalyticsDevicesPage extends StatelessWidget {
  const AnalyticsDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DevicesBody();
  }
}

class _DevicesBody extends StatelessWidget {
  const _DevicesBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.lx.find<AnalyticsDevicesController>();

    return Scaffold(
      body: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Obx(() {
              final metrics = controller.metrics;
              final activeModule = controller.activeModule;
              final districtRanks = controller.districtRanks;
              final publicationRateRanks = controller.publicationRateRanks;
              final propertyCompanyDeviceRanks =
                  controller.propertyCompanyDeviceRanks;
              final districtRankPage = controller.districtRankPage.value;
              final publicationRateRankPage =
                  controller.publicationRateRankPage.value;
              final propertyCompanyDeviceRankPage =
                  controller.propertyCompanyDeviceRankPage.value;
              final districtRankOffset =
                  (districtRankPage - 1) * AnalyticsController.rankVisibleRows;
              final publicationRateRankOffset =
                  (publicationRateRankPage - 1) *
                  AnalyticsController.rankVisibleRows;
              final propertyCompanyDeviceRankOffset =
                  (propertyCompanyDeviceRankPage - 1) *
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
                            selected: metric.key == activeModule,
                            plainIcon: true,
                            onPressed: metric.key == null
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
                      gradientColors: const [
                        Color(0x80E1FFDB),
                        Color(0x00E1FFDB),
                      ],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.districtTitle,
                        items: controller.districtRanksAll,
                        labelHeader: '城市区域',
                        valueHeader: '设备数量',
                      ),
                      actions: _districtRankTopSelect(controller),
                      child: Column(
                        spacing: 8,
                        children: [
                          _rankTable(
                            context: context,
                            items: districtRanks,
                            labelHeader: '城市区域',
                            valueHeader: '设备数量',
                            rankOffset: districtRankOffset,
                          ),
                          _analyticsPagination(
                            page: districtRankPage,
                            totalPages: controller.districtTotalPages,
                            onPageChanged: controller.setDistrictRankPage,
                          ),
                        ],
                      ),
                    ).expanded(),
                    _AnalyticsRankCard(
                      title: controller.publicationRateTitle,
                      accent: const Color(0xFF8B5CF6),
                      gradientColors: const [
                        Color(0x80CEFAFE),
                        Color(0x00CEFAFE),
                      ],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.publicationRateTitle,
                        items: controller.publicationRateRanksAll,
                        labelHeader: '点位',
                        valueHeader: '上刊率',
                      ),
                      actions: Obx(
                        () => _lowerRankTopSelect(
                          value: controller.publicationRateRankLimit.value,
                          onChanged: controller.setPublicationRateRankLimit,
                        ),
                      ),
                      child: Column(
                        spacing: 8,
                        children: [
                          _rankTable(
                            context: context,
                            items: publicationRateRanks,
                            labelHeader: '点位',
                            valueHeader: '上刊率',
                            rankOffset: publicationRateRankOffset,
                          ),
                          _analyticsPagination(
                            page: publicationRateRankPage,
                            totalPages: controller.publicationRateTotalPages,
                            onPageChanged:
                                controller.setPublicationRateRankPage,
                          ),
                        ],
                      ),
                    ).expanded(),
                    _AnalyticsRankCard(
                      title: controller.propertyCompanyDeviceTitle,
                      accent: const Color(0xFF2563EB),
                      gradientColors: const [
                        Color(0x80FEDECE),
                        Color(0x00FEDECE),
                      ],
                      isExpanded: isExpanded,
                      onToggleExpand: toggle,
                      onViewAll: () => showAnalyticsRankAllDialog(
                        context: context,
                        title: controller.propertyCompanyDeviceTitle,
                        items: controller.propertyCompanyDeviceRanksAll,
                        labelHeader: '物业公司',
                        valueHeader: '设备数量',
                      ),
                      actions: Obx(
                        () => _lowerRankTopSelect(
                          value:
                              controller.propertyCompanyDeviceRankLimit.value,
                          onChanged:
                              controller.setPropertyCompanyDeviceRankLimit,
                        ),
                      ),
                      child: Column(
                        spacing: 8,
                        children: [
                          _rankTable(
                            context: context,
                            items: propertyCompanyDeviceRanks,
                            labelHeader: '物业公司',
                            valueHeader: '设备数量',
                            rankOffset: propertyCompanyDeviceRankOffset,
                          ),
                          _analyticsPagination(
                            page: propertyCompanyDeviceRankPage,
                            totalPages:
                                controller.propertyCompanyDeviceTotalPages,
                            onPageChanged:
                                controller.setPropertyCompanyDeviceRankPage,
                          ),
                        ],
                      ),
                    ).expanded(),
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
            child: _AnalyticsBottomCharts(controller: controller),
          ),
        ],
      ).scroll(),
    );
  }
}

// ---------------------------------------------------------------------------
// 底部图表区
//
// 播放趋势 / 设备情况 / 效率 / 环图均已接新接口。
// ---------------------------------------------------------------------------

typedef _BottomLegendEntry = ({
  String label,
  String value,
  String percent,
  Color color,
});

class _AnalyticsBottomCharts extends StatelessWidget {
  const _AnalyticsBottomCharts({required this.controller});

  final AnalyticsController controller;

  /// 环图占位尺寸：外径 = ring + hole = 144，盒 176 留边。
  static const double _donutBoxSize = 176;
  static const double _donutHoleRadius = 40;
  static const double _donutRingRadius = 32;

  /// 第一行（图表 + 两张清单卡）高度。
  static const double _row1Height = 280;

  /// 第二行（两张环图卡）高度。
  static const double _row2Height = 244;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final media = controller.mediaLocationDistribution;
      final play = controller.playCountDistribution;
      return Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _row1Height,
            child: Row(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _trendCard(context).expanded(),
                _situationCard(context).width(370),
                _efficiencyCard(context).width(370),
              ],
            ),
          ),
          SizedBox(
            height: _row2Height,
            child: Row(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _distributionCard(
                  context: context,
                  data: media,
                ).expanded(flex: 12),
                _distributionCard(
                  context: context,
                  data: play,
                ).expanded(flex: 10),
              ],
            ),
          ),
        ],
      );
    });
  }

  // -------------------------------------------------------------------------
  // 播放趋势
  // -------------------------------------------------------------------------

  Widget _trendCard(BuildContext context) {
    final title = controller.playTrendTitle;
    final legends = controller.playTrendLegends;
    final series = controller.playTrendSeries;
    final maxY = controller.playTrendMaxY;
    final interval = controller.playTrendYInterval;
    final useThousands = controller.playTrendYUsesThousands;
    final preset = controller.playTrendPreset.value;
    return _analyticsBorderCard(
      context: context,
      expandBody: true,
      header: Padding(
        // 32 高的下拉框比标题行高约 8，顶部少 4 保持标题距顶 20。
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          spacing: 12,
          children: [
            AppText.title(title, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            for (final item in legends) _legendDot(item.color, item.label),
            AppControlMetricsScope(
              metrics: AppControlMetricsScope.resolve(
                context,
              ).copyWith(height: 32),
              child: AppSelect<String>(
                value: preset,
                hintText: '近7天',
                minWidth: 96,
                options: AnalyticsController.playTrendPresetOptions,
                onChanged: controller.setPlayTrendPreset,
              ).width(96),
            ),
          ],
        ),
      ),
      bodyPadding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AppLineChart.area(
            height: constraints.maxHeight,
            showLegend: false,
            showTooltip: true,
            interactive: true,
            keyboardNavigation: false,
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
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Builder(
      builder: (context) {
        final colors = ShadcnTheme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            AppText.caption(
              label,
              style: TextStyle(color: colors.mutedForeground, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // 设备情况
  // -------------------------------------------------------------------------

  Widget _situationCard(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final title = controller.deviceSituationTitle;
    final rows = controller.deviceSituationItems;

    return _analyticsBorderCard(
      context: context,
      expandBody: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: AppText.title(title, style: const TextStyle(fontSize: 16)),
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows)
            Row(
              spacing: 10,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: row.tile,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(row.icon, size: 16, color: row.color),
                ),
                AppText.body(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ).expanded(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: row.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: row.unit,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 设备使用效率
  // -------------------------------------------------------------------------

  Widget _efficiencyCard(BuildContext context) {
    final title = controller.deviceEfficiencyTitle;
    final items = controller.deviceEfficiencyItems;

    return _analyticsBorderCard(
      context: context,
      expandBody: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: AppText.title(title, style: const TextStyle(fontSize: 16)),
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < items.length; i += 2)
            Row(
              spacing: 12,
              children: [
                _efficiencyCell(items[i]).expanded(),
                if (i + 1 < items.length)
                  _efficiencyCell(items[i + 1]).expanded()
                else
                  const Spacer(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _efficiencyCell(AnalyticsEfficiencyItem data) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: data.tile,
        borderRadius: BorderRadius.circular(14),
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
            style: const TextStyle(color: Color(0xFF1D2129), fontSize: 14),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: data.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2129),
                  ),
                ),
                TextSpan(
                  text: data.unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1D2129),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 环图 + 图例
  // -------------------------------------------------------------------------

  Widget _distributionCard({
    required BuildContext context,
    required AnalyticsDonutChartData data,
  }) {
    final hasPositive = data.sections.any((item) => item.value > 0);
    final sections = <AppPieSection>[
      if (!hasPositive)
        const AppPieSection(label: '-', value: 1, color: Color(0xFFE5E7EB))
      else
        for (final item in data.sections)
          AppPieSection(
            label: item.label,
            value: item.value,
            color: item.color,
          ),
    ];
    final entries = _legendEntries(data.sections);
    final half = entries.isEmpty ? 1 : (entries.length / 2).ceil();

    return _analyticsBorderCard(
      context: context,
      expandBody: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: AppText.title(data.title, style: const TextStyle(fontSize: 16)),
      ),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 16,
        children: [
          // 上游环形图半径是固定像素（默认外径 76 / 孔径 48，总直径 248），
          // 卡片内放不下会溢出裁切，这里按卡片尺寸收小。
          SizedBox.square(
            dimension: _donutBoxSize,
            child: AppPieChart.donut(
              height: _donutBoxSize,
              sections: sections,
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
          SingleChildScrollView(
            child: Row(
              spacing: 24,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < 2; column++)
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var i = column * half;
                          i < (column + 1) * half && i < entries.length;
                          i++
                        )
                          _legendItem(entries[i]),
                      ],
                    ),
                  ),
              ],
            ),
          ).expanded(),
        ],
      ),
    );
  }

  List<_BottomLegendEntry> _legendEntries(
    List<AnalyticsDonutSection> sections,
  ) {
    return [
      for (final item in sections)
        (
          label: item.label,
          value: _formatRankValue(item.value),
          percent: item.percent == null
              ? '0%'
              : '${item.percent!.toStringAsFixed(item.percent == item.percent!.roundToDouble() ? 0 : 1)}%',
          color: item.color,
        ),
    ];
  }

  Widget _legendItem(_BottomLegendEntry entry) {
    return Builder(
      builder: (context) {
        final colors = ShadcnTheme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: entry.color,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: AppText.caption(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.mutedForeground, fontSize: 12),
              ),
            ),
            AppText.caption(
              entry.value,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            AppText.caption(
              '(${entry.percent})',
              maxLines: 1,
              style: TextStyle(color: entry.color, fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}
