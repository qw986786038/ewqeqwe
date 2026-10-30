import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show DateTimeRange;
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/ad_data_analysis_api.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_comprehensive_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_comprehensive_order_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_district_rank_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_play_trends_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_property_rank_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_rank_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_trends_order_entity.dart';
import 'package:yidivination/bokong/entity/analytics/ad_data_analysis_up_rate_rank_entity.dart';
import 'package:yidivination/bokong/widget/message.dart';

/// 数据分析页：设备 / 订单范围与接口指标。
class AnalyticsController extends LxController {
  AnalyticsController({this.initialScope = 0});

  /// 初始范围：0 设备管理 / 1 客户订单（拆成两个独立页面后由页面注入）。
  final int initialScope;

  final scopeIndex = 0.obs;
  final selectedDate = DateTime.now().obs;
  final selectedModule = Rxn<String>();
  final orderStatus = 99.obs;
  final loading = false.obs;
  final analysis = Rxn<AdDataAnalysisEntity>();
  final districtRank = Rxn<AdDataAnalysisDistrictRankEntity>();
  final propertyRank = Rxn<AdDataAnalysisPropertyRankEntity>();
  final upRateRank = Rxn<AdDataAnalysisUpRateRankEntity>();
  final playTrends = Rxn<AdDataAnalysisPlayTrendsEntity>();
  final comprehensive = Rxn<AdDataAnalysisComprehensiveEntity>();
  final customerOrderRank = Rxn<AdDataAnalysisDistrictRankEntity>();
  final categoryOrderRank = Rxn<AdDataAnalysisDistrictRankEntity>();
  final officeOrderRank = Rxn<AdDataAnalysisDistrictRankEntity>();
  final comprehensiveOrder = Rxn<AdDataAnalysisComprehensiveOrderEntity>();
  final orderTrends = Rxn<AdDataAnalysisTrendsOrderEntity>();
  final analysisRank = Rxn<AdDataAnalysisRankEntity>();
  final rankLoading = false.obs;

  /// 播放趋势区间：`7d` / `15d` / `30d` / `60d` / `90d`
  final playTrendPreset = '7d'.obs;

  /// 经营趋势指标：1 订单数 / 2 客户数 / 3 播放次数
  final orderTrendType = 1.obs;

  /// 经营趋势区间：`7d` / `15d` / `30d` / `60d` / `90d`
  final orderTrendPreset = '7d'.obs;

  final timePreset = AnalyticsTimePreset.all.obs;
  final rankDateRange = Rxn<DateTimeRange>();

  /// 行政区排行 TOP（最多展示条数，非每页条数）
  final districtRankLimit = 10.obs;

  /// 媒体位置排行 TOP
  final mediaLocationRankLimit = 10.obs;

  /// 行政区排行页码
  final districtRankPage = 1.obs;

  /// 媒体位置排行页码
  final mediaLocationRankPage = 1.obs;

  /// 下半排行 TOP / 页码（各榜独立；收起仍联动）
  final publicationRateRankLimit = 10.obs;
  final publicationRateRankPage = 1.obs;
  final propertyCompanyDeviceRankLimit = 10.obs;
  final propertyCompanyDeviceRankPage = 1.obs;
  final customerOrderRankLimit = 10.obs;
  final customerOrderRankPage = 1.obs;
  final industryOrderRankLimit = 10.obs;
  final industryOrderRankPage = 1.obs;
  final propertyOrderRankLimit = 10.obs;
  final propertyOrderRankPage = 1.obs;

  /// 是否允许音量：null 全部不传，0 否，1 是
  final isVolume = Rxn<int>();
  final cityIds = Rxn<int>();
  final districtIds = Rxn<int>();

  /// 排行图固定可视行数（卡片高度不随条数跳动）
  static const rankVisibleRows = 10;

  static const regionOptions = [
    AppOption(value: 'all', label: '全部区域'),
    AppOption(value: 'lixia', label: '历下区'),
    AppOption(value: 'shizhong', label: '市中区'),
    AppOption(value: 'tianqiao', label: '天桥区'),
  ];

  static const mediaLocationOptions = [
    AppOption(value: 'all', label: '全部位置'),
    AppOption(value: 'f1', label: '地上一层'),
    AppOption(value: 'b1', label: '地下一层'),
    AppOption(value: 'lobby', label: '大堂'),
  ];

  static const audioOptions = [
    AppOption(value: -1, label: '全部'),
    AppOption(value: 1, label: '可播放声音'),
    AppOption(value: 0, label: '不可播放声音'),
  ];

  static const statusOptions = [
    AppOption(value: 99, label: '全部状态'),
    AppOption(value: 1, label: '执行中'),
    AppOption(value: 2, label: '已暂停'),
    AppOption(value: 3, label: '已完播'),
  ];

  static const topOptions = [
    AppOption(value: 10, label: 'TOP10'),
    AppOption(value: 20, label: 'TOP20'),
    AppOption(value: 50, label: 'TOP50'),
    AppOption(value: 100, label: 'TOP100'),
  ];

  static const playTrendPresetOptions = [
    AppOption(value: '7d', label: '近7天'),
    AppOption(value: '15d', label: '近15天'),
    AppOption(value: '30d', label: '近30天'),
    AppOption(value: '60d', label: '近60天'),
    AppOption(value: '90d', label: '近90天'),
  ];

  static const orderTrendPresetOptions = [
    AppOption(value: '7d', label: '近7天'),
    AppOption(value: '15d', label: '近15天'),
    AppOption(value: '30d', label: '近30天'),
    AppOption(value: '60d', label: '近60天'),
    AppOption(value: '90d', label: '近90天'),
  ];

  static const orderTrendTypeLabels = ['订单数', '客户数', '播放次数'];

  static const _orderTrendLineColor = Color(0xFF2563EB);

  static const _playTrendSeriesColors = <String, Color>{
    'device_98inch_plays': Color(0xFF3B82F6),
    'device_86inch_plays': Color(0xFF22C55E),
    'device_76inch_plays': Color(0xFFF59E0B),
  };

  static const _situationAccent = <({Color color, Color tile})>[
    (color: Color(0xFF6366F1), tile: Color(0xFFEDF0FF)),
    (color: Color(0xFFF97316), tile: Color(0xFFFFEFE3)),
    (color: Color(0xFF22C55E), tile: Color(0xFFE9F8EE)),
    (color: Color(0xFF3B82F6), tile: Color(0xFFE8F1FF)),
  ];

  static const _efficiencyAccent = <({Color color, Color tile})>[
    (color: Color(0xFF6366F1), tile: Color(0xFFEDF0FF)),
    (color: Color(0xFF3B82F6), tile: Color(0xFFE8F1FF)),
    (color: Color(0xFFF59E0B), tile: Color(0xFFFFF5E5)),
    (color: Color(0xFF22C55E), tile: Color(0xFFE9F8EE)),
  ];

  static const _donutPalette = <Color>[
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFFA855F7),
    Color(0xFF3B82F6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  static const _orderStatusColors = <String, Color>{
    'executing': Color(0xFF2563EB),
    'completed': Color(0xFF8B5CF6),
    'paused': Color(0xFFF59E0B),
  };

  static const _orderExpiringAccent = <({Color color, Color tile})>[
    (color: Color(0xFFEF4444), tile: Color(0xFFFDE7E7)),
    (color: Color(0xFF6366F1), tile: Color(0xFFE7E9FB)),
    (color: Color(0xFFF59E0B), tile: Color(0xFFFEF3DC)),
    (color: Color(0xFF16A34A), tile: Color(0xFFE6F5EE)),
  ];

  static const _metricAccents = <Color>[
    Color(0xFF08B780),
    Color(0xFF0891B2),
    Color(0xFF6366F1),
    Color(0xFFC026D3),
    Color(0xFFE11D48),
  ];

  /// 指标卡浅色（与 [_metricAccents] 一一对应）：选中态卡片底色 / 未选中态图标色。
  static const _metricFills = <Color>[
    Color(0xFFD1FAE5),
    Color(0xFFCFFAFE),
    Color(0xFFE0E7FF),
    Color(0xFFFAE8FF),
    Color(0xFFFFE4E6),
  ];

  int get analysisType => scopeIndex.value == 0 ? 1 : 2;

  String get dateParam {
    final d = selectedDate.value;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String? get rankStartDateParam {
    final range = rankDateRange.value;
    if (range == null) return null;
    return _formatYmd(range.start);
  }

  String? get rankEndDateParam {
    final range = rankDateRange.value;
    if (range == null) return null;
    return _formatYmd(range.end);
  }

  /// 当前选中的 KPI key。
  String? get activeModule {
    final selected = selectedModule.value?.trim();
    if (selected == null || selected.isEmpty) return null;
    return selected;
  }

  List<AdDataAnalysisOverviewEntity> get _overviewCards =>
      analysis.value?.kpiCards ??
      analysis.value?.overview ??
      const <AdDataAnalysisOverviewEntity>[];

  List<AnalyticsMetric> get metrics {
    final list = _overviewCards;
    return [
      for (var i = 0; i < list.length; i++) _metricFromOverview(list[i], i),
    ];
  }

  String get districtTitle {
    final title = districtRank.value?.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return scopeIndex.value == 0 ? '行政区设备数量排行' : '行政区设备订单数量排行';
  }

  String get mediaLocationTitle =>
      scopeIndex.value == 0 ? '媒体位置设备数量排行' : '媒体位置设备订单数量排行';

  List<AnalyticsRankItem> get districtRanks =>
      _pageSlice(districtRanksAll, districtRankPage.value);

  /// 当前 TOP 下的完整行政区排行（不切片分页）。
  List<AnalyticsRankItem> get districtRanksAll => _takeTop(
    _districtRanksFrom(districtRank.value, activeModule),
    districtRankLimit.value,
  );

  /// KPI key → 与上方指标卡相同的 accent 色。
  Map<String, Color> get _metricAccentMap {
    final cards = _overviewCards;
    final map = <String, Color>{};
    for (var i = 0; i < cards.length; i++) {
      final key = cards[i].key?.trim();
      if (key != null && key.isNotEmpty) {
        map[key] = _metricAccents[i % _metricAccents.length];
      }
    }
    return map;
  }

  Color _accentForModuleKey(String? moduleKey) {
    final key = moduleKey?.trim();
    if (key != null) {
      final accent = _metricAccentMap[key];
      if (accent != null) return accent;
    }
    return _metricAccents.first;
  }

  List<String> get _kpiKeysInOrder {
    final cards = _overviewCards;
    return [
      for (final item in cards)
        if (item.key?.trim().isNotEmpty == true) item.key!.trim(),
    ];
  }

  /// 媒体位置排行待新接口；暂空。
  List<AnalyticsRankItem> get mediaLocationRanks => const [];

  List<AppOption<int>> get districtTopOptions => topOptions;

  List<AppOption<int>> get mediaLocationTopOptions => topOptions;

  int get districtTotalPages => _localTotalPages(
    districtRank.value?.list?.length ?? 0,
    districtRankLimit.value,
  );

  int get mediaLocationTotalPages => 1;

  String get customerOrderTitle {
    final title = customerOrderRank.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '客户订单排行';
  }

  String get publicationRateTitle {
    final title = upRateRank.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '上刊率排行';
  }

  String get propertyCompanyDeviceTitle {
    final title = propertyRank.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '物业公司关联设备数量排行';
  }

  String get industryOrderTitle {
    final title = categoryOrderRank.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '所属行业订单排行';
  }

  String get propertyOrderTitle {
    final title = officeOrderRank.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '物业(写字楼)订单排行';
  }

  String get customerOrderTrendTitle {
    final title = orderTrends.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '经营趋势';
  }

  List<AnalyticsRankItem> get customerOrderRanks =>
      _pageSlice(customerOrderRanksAll, customerOrderRankPage.value);

  /// 当前 TOP 下的完整客户订单排行（不切片分页）。
  List<AnalyticsRankItem> get customerOrderRanksAll => _takeTop(
    _simpleProgressRanksFrom(customerOrderRank.value),
    customerOrderRankLimit.value,
  );

  List<AnalyticsRankItem> get publicationRateRanks =>
      _pageSlice(publicationRateRanksAll, publicationRateRankPage.value);

  /// 当前 TOP 下的完整上刊率排行（不切片分页）。
  List<AnalyticsRankItem> get publicationRateRanksAll => _takeTop(
    _publicationRateRanksFrom(upRateRank.value),
    publicationRateRankLimit.value,
  );

  List<AnalyticsRankItem> get propertyCompanyDeviceRanks => _pageSlice(
    propertyCompanyDeviceRanksAll,
    propertyCompanyDeviceRankPage.value,
  );

  /// 当前 TOP 下的完整物业公司设备排行（不切片分页）。
  List<AnalyticsRankItem> get propertyCompanyDeviceRanksAll => _takeTop(
    _propertyCompanyDeviceRanksFrom(propertyRank.value, activeModule),
    propertyCompanyDeviceRankLimit.value,
  );

  List<AnalyticsRankItem> get industryOrderRanks =>
      _pageSlice(industryOrderRanksAll, industryOrderRankPage.value);

  /// 当前 TOP 下的完整行业订单排行（不切片分页）。
  List<AnalyticsRankItem> get industryOrderRanksAll => _takeTop(
    _simpleProgressRanksFrom(categoryOrderRank.value),
    industryOrderRankLimit.value,
  );

  List<AnalyticsRankItem> get propertyOrderRanks =>
      _pageSlice(propertyOrderRanksAll, propertyOrderRankPage.value);

  /// 当前 TOP 下的完整物业订单排行（不切片分页）。
  List<AnalyticsRankItem> get propertyOrderRanksAll => _takeTop(
    _simpleProgressRanksFrom(officeOrderRank.value),
    propertyOrderRankLimit.value,
  );

  int get customerOrderTotalPages => _localTotalPages(
    customerOrderRank.value?.list?.length ?? 0,
    customerOrderRankLimit.value,
  );

  int get publicationRateTotalPages => _localTotalPages(
    upRateRank.value?.list?.length ?? 0,
    publicationRateRankLimit.value,
  );

  int get propertyCompanyDeviceTotalPages => _localTotalPages(
    propertyRank.value?.list?.length ?? 0,
    propertyCompanyDeviceRankLimit.value,
  );

  int get industryOrderTotalPages => _localTotalPages(
    categoryOrderRank.value?.list?.length ?? 0,
    industryOrderRankLimit.value,
  );

  int get propertyOrderTotalPages => _localTotalPages(
    officeOrderRank.value?.list?.length ?? 0,
    propertyOrderRankLimit.value,
  );

  /// TOP N 最多 ceil(N / 每页行数) 页；真实条数更少时用真实页数。
  static int _localTotalPages(int listLength, int top) {
    final capped = listLength <= 0
        ? 0
        : (top > 0 && listLength > top ? top : listLength);
    if (capped <= 0) return 1;
    return (capped + rankVisibleRows - 1) ~/ rankVisibleRows;
  }

  static List<T> _takeTop<T>(List<T> all, int top) {
    if (top <= 0 || all.length <= top) return all;
    return all.sublist(0, top);
  }

  /// 各榜独立本地翻页，避免接口共享 page 导致一榜带动全部。
  static List<T> _pageSlice<T>(List<T> all, int page) {
    if (all.isEmpty) return <T>[];
    final p = page < 1 ? 1 : page;
    final start = (p - 1) * rankVisibleRows;
    if (start >= all.length) return <T>[];
    final end = start + rankVisibleRows;
    return all.sublist(start, end > all.length ? all.length : end);
  }

  List<AppLineSeries> get customerOrderTrendSeries {
    final data = orderTrends.value;
    final categories = data?.categories ?? const <String>[];
    final series =
        data?.series ?? const <AdDataAnalysisTrendsOrderSeriesEntity>[];
    final typeIndex = (orderTrendType.value - 1).clamp(0, 2);
    final label = orderTrendTypeLabels[typeIndex];
    return [
      for (var i = 0; i < series.length; i++)
        AppLineSeries(
          name: label,
          color: _orderTrendLineColor,
          width: 2,
          points: _playTrendPoints(categories, series[i].data),
        ),
    ];
  }

  double get customerOrderTrendMaxY {
    var maxY = 0.0;
    for (final series in customerOrderTrendSeries) {
      for (final point in series.points) {
        final y = point.y ?? 0;
        if (y > maxY) maxY = y;
      }
    }
    if (maxY <= 0) return 10;
    final step = maxY <= 10 ? 1.0 : (maxY / 5).ceilToDouble();
    return (maxY / step).ceil() * step;
  }

  double get customerOrderTrendYInterval {
    final maxY = customerOrderTrendMaxY;
    if (maxY <= 10) return 2;
    return maxY / 5;
  }

  bool get customerOrderTrendYUsesThousands => customerOrderTrendMaxY >= 1000;

  String get playTrendTitle {
    final title = playTrends.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '播放趋势';
  }

  List<({String label, Color color})> get playTrendLegends {
    final series =
        playTrends.value?.series ??
        const <AdDataAnalysisPlayTrendsSeriesEntity>[];
    return [
      for (var i = 0; i < series.length; i++)
        (
          label: series[i].name?.trim().isNotEmpty == true
              ? series[i].name!.trim()
              : '-',
          color: _playTrendColorFor(series[i].key, i),
        ),
    ];
  }

  List<AppLineSeries> get playTrendSeries {
    final data = playTrends.value;
    final categories = data?.categories ?? const <String>[];
    final series =
        data?.series ?? const <AdDataAnalysisPlayTrendsSeriesEntity>[];
    return [
      for (var i = 0; i < series.length; i++)
        AppLineSeries(
          name: series[i].name?.trim().isNotEmpty == true
              ? series[i].name!.trim()
              : '-',
          color: _playTrendColorFor(series[i].key, i),
          width: 2,
          points: _playTrendPoints(categories, series[i].data),
        ),
    ];
  }

  double get playTrendMaxY {
    var maxY = 0.0;
    for (final series in playTrendSeries) {
      for (final point in series.points) {
        final y = point.y ?? 0;
        if (y > maxY) maxY = y;
      }
    }
    if (maxY <= 0) return 10;
    final step = maxY <= 10 ? 1.0 : (maxY / 5).ceilToDouble();
    return (maxY / step).ceil() * step;
  }

  double get playTrendYInterval {
    final maxY = playTrendMaxY;
    if (maxY <= 10) return 2;
    return maxY / 5;
  }

  bool get playTrendYUsesThousands => playTrendMaxY >= 1000;

  String get deviceSituationTitle {
    final title = _dashboardByType('list')?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '设备情况';
  }

  List<AnalyticsSituationItem> get deviceSituationItems {
    final items =
        _dashboardByType('list')?.items ??
        const <AdDataAnalysisComprehensiveItemEntity>[];
    return [
      for (var i = 0; i < items.length; i++)
        AnalyticsSituationItem(
          label: items[i].label?.trim().isNotEmpty == true
              ? items[i].label!.trim()
              : '-',
          value: _formatNum(items[i].value),
          unit: items[i].unit?.trim() ?? '',
          icon: _situationIconFor(items[i].icon),
          color: _situationAccent[i % _situationAccent.length].color,
          tile: _situationAccent[i % _situationAccent.length].tile,
        ),
    ];
  }

  String get deviceEfficiencyTitle {
    final title = _dashboardByType('cards')?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '设备使用效率';
  }

  List<AnalyticsEfficiencyItem> get deviceEfficiencyItems {
    final items =
        _dashboardByType('cards')?.items ??
        const <AdDataAnalysisComprehensiveItemEntity>[];
    return [
      for (var i = 0; i < items.length; i++)
        AnalyticsEfficiencyItem(
          label: items[i].label?.trim().isNotEmpty == true
              ? items[i].label!.trim()
              : '-',
          value: _formatNum(items[i].value),
          unit: items[i].unit?.trim() ?? '',
          color: _efficiencyAccent[i % _efficiencyAccent.length].color,
          tile: _efficiencyAccent[i % _efficiencyAccent.length].tile,
        ),
    ];
  }

  AnalyticsDonutChartData get mediaLocationDistribution =>
      _donutChartByTitle('媒体位置设备分布', fallbackTitle: '媒体位置设备分布');

  AnalyticsDonutChartData get playCountDistribution =>
      _donutChartByTitle('播放次数（设备占比）', fallbackTitle: '播放次数（设备占比）');

  String get orderStatusTitle {
    final title = comprehensiveOrder.value?.title?.trim();
    return (title != null && title.isNotEmpty) ? title : '订单状态';
  }

  List<AnalyticsOrderStatusItem> get orderStatusItems {
    final list =
        comprehensiveOrder.value?.statusDistribution ??
        const <AdDataAnalysisOrderStatusItemEntity>[];
    return [
      for (var i = 0; i < list.length; i++)
        AnalyticsOrderStatusItem(
          label: list[i].name?.trim().isNotEmpty == true
              ? list[i].name!.trim()
              : '-',
          value: (list[i].value ?? 0).toDouble(),
          percent: list[i].percentage?.trim().isNotEmpty == true
              ? list[i].percentage!.trim()
              : '0%',
          color:
              _orderStatusColors[list[i].key?.trim()] ??
              _donutPalette[i % _donutPalette.length],
        ),
    ];
  }

  List<AnalyticsOrderExpiringItem> get orderExpiringItems {
    final list =
        comprehensiveOrder.value?.expiringCards ??
        const <AdDataAnalysisOrderExpiringCardEntity>[];
    return [
      for (var i = 0; i < list.length; i++)
        AnalyticsOrderExpiringItem(
          label: list[i].label?.trim().isNotEmpty == true
              ? list[i].label!.trim()
              : '-',
          value: _formatNum(list[i].value),
          color: _orderExpiringAccent[i % _orderExpiringAccent.length].color,
          tile: _orderExpiringAccent[i % _orderExpiringAccent.length].tile,
        ),
    ];
  }

  AdDataAnalysisComprehensiveDashboardEntity? _dashboardByType(String type) {
    final list =
        comprehensive.value?.dashboard ??
        const <AdDataAnalysisComprehensiveDashboardEntity>[];
    for (final item in list) {
      if (item.type?.trim() == type) return item;
    }
    return null;
  }

  AnalyticsDonutChartData _donutChartByTitle(
    String title, {
    required String fallbackTitle,
  }) {
    final charts =
        comprehensive.value?.charts ??
        const <AdDataAnalysisComprehensiveChartEntity>[];
    AdDataAnalysisComprehensiveChartEntity? matched;
    for (final chart in charts) {
      if (chart.title?.trim() == title) {
        matched = chart;
        break;
      }
    }
    final legend =
        matched?.legend ?? const <AdDataAnalysisComprehensiveLegendEntity>[];
    return AnalyticsDonutChartData(
      title: matched?.title?.trim().isNotEmpty == true
          ? matched!.title!.trim()
          : fallbackTitle,
      totalLabel: matched?.totalLabel?.trim() ?? '',
      total: matched?.total?.toDouble() ?? 0,
      sections: [
        for (var i = 0; i < legend.length; i++)
          AnalyticsDonutSection(
            label: legend[i].label?.trim().isNotEmpty == true
                ? legend[i].label!.trim()
                : '-',
            value: (legend[i].value ?? 0).toDouble(),
            percent: legend[i].percent?.toDouble(),
            color: _donutPalette[i % _donutPalette.length],
          ),
      ],
    );
  }

  static Color _playTrendColorFor(String? key, int index) {
    final token = key?.trim() ?? '';
    final mapped = _playTrendSeriesColors[token];
    if (mapped != null) return mapped;
    return _metricAccents[index % _metricAccents.length];
  }

  static List<AppLinePoint> _playTrendPoints(
    List<String> categories,
    List<num>? values,
  ) {
    final data = values ?? const <num>[];
    final len = categories.length > data.length
        ? categories.length
        : data.length;
    if (len <= 0) return const [];
    return [
      for (var i = 0; i < len; i++)
        AppLinePoint(
          x: i.toDouble(),
          y: i < data.length ? data[i].toDouble() : 0,
          label: i < categories.length && categories[i].trim().isNotEmpty
              ? categories[i].trim()
              : '${i + 1}',
        ),
    ];
  }

  bool get isSelectedToday {
    final d = selectedDate.value;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get isSelectedYesterday {
    final d = selectedDate.value;
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }

  int get audioFilterValue => isVolume.value ?? -1;

  /// 筛选下拉是否均为「全部」（不含时间维度）。
  bool get isRankSelectFiltersAll =>
      isVolume.value == null &&
      orderStatus.value == 99 &&
      cityIds.value == null &&
      districtIds.value == null;

  /// 筛选条件行「全部」：清空区域 / 声音 / 订单状态，不改时间。
  void selectAllRankSelectFilters() {
    if (isRankSelectFiltersAll) return;
    isVolume.value = null;
    orderStatus.value = 99;
    cityIds.value = null;
    districtIds.value = null;
    _resetLowerRankPages();
    Future.microtask(_reloadByTimeDimension);
  }

  /// 筛选条件行「搜索」：按当前条件重新拉取。
  void searchRankFilters() {
    _resetLowerRankPages();
    Future.microtask(_reloadByTimeDimension);
  }

  @override
  void onInit() {
    super.onInit();
    scopeIndex.value = initialScope;
    // KPI → 默认选中第一张卡 → 再拉依赖 moudle 的排行。
    loadAnalysis();
    if (scopeIndex.value == 0) {
      loadPlayTrends();
      loadComprehensive();
    } else {
      loadOrderTrends();
      loadComprehensiveOrder();
    }
  }

  /// type=2 时：99 表示全部不传；其余原样作为 status。
  int? get _analysisStatusParam {
    if (analysisType != 2) return null;
    final status = orderStatus.value;
    if (status == 99) return null;
    return status;
  }

  /// 是否已选中可用于排行请求的 KPI 模块。
  bool get _hasSelectedModule {
    final key = activeModule;
    return key != null && key.isNotEmpty;
  }

  Future<void> loadAnalysis() async {
    loading.value = true;
    try {
      final resp = await AdDataAnalysisApi.dataAnalysis(
        type: analysisType,
        cityIds: cityIds.value?.toString(),
        districtIds: districtIds.value?.toString(),
        status: _analysisStatusParam,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      analysis.value = resp.data;
      _syncSelectedModule(resp.data);
      // 未选中卡片前不请求下方排行。
      if (!_hasSelectedModule) return;
      await _loadRanksForSelectedModule();
    } catch (e) {
      showError('$e');
    } finally {
      loading.value = false;
    }
  }

  /// 依赖当前选中 KPI（moudle）的排行请求。
  Future<void> _loadRanksForSelectedModule() async {
    if (!_hasSelectedModule) return;
    await loadDistrictRank();
    if (analysisType == 1) {
      await Future.wait([loadPropertyRank(), loadUpRateRank()]);
      _clampRankPage(
        propertyCompanyDeviceRankPage,
        propertyCompanyDeviceTotalPages,
      );
    } else {
      await Future.wait([
        loadCustomerOrderRank(),
        loadCategoryOrderRank(),
        loadOfficeOrderRank(),
      ]);
    }
    _clampRankPage(districtRankPage, districtTotalPages);
    _clampRankPage(mediaLocationRankPage, mediaLocationTotalPages);
  }

  Future<void> loadDistrictRank() async {
    if (!_hasSelectedModule) return;
    try {
      final resp = analysisType == 2
          ? await AdDataAnalysisApi.dataAnalysisDistrictOrder(
              type: analysisType,
              cityIds: cityIds.value?.toString(),
              districtIds: districtIds.value?.toString(),
              status: _analysisStatusParam,
              startDate: rankStartDateParam,
              endDate: rankEndDateParam,
              limit: districtRankLimit.value,
              moudle: activeModule,
            )
          : await AdDataAnalysisApi.dataAnalysisDistrictRank(
              type: analysisType,
              cityIds: cityIds.value?.toString(),
              districtIds: districtIds.value?.toString(),
              status: _analysisStatusParam,
              startDate: rankStartDateParam,
              endDate: rankEndDateParam,
              limit: districtRankLimit.value,
              moudle: activeModule,
            );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      districtRank.value = resp.data;
      _clampRankPage(districtRankPage, districtTotalPages);
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadCustomerOrderRank() async {
    if (!_hasSelectedModule) return;
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisCustomerOrder(
        type: analysisType,
        cityIds: cityIds.value?.toString(),
        districtIds: districtIds.value?.toString(),
        status: _analysisStatusParam,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
        limit: customerOrderRankLimit.value,
        moudle: activeModule,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      customerOrderRank.value = resp.data;
      _clampRankPage(customerOrderRankPage, customerOrderTotalPages);
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadCategoryOrderRank() async {
    if (!_hasSelectedModule) return;
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisCategoryOrder(
        type: analysisType,
        cityIds: cityIds.value?.toString(),
        districtIds: districtIds.value?.toString(),
        status: _analysisStatusParam,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
        limit: industryOrderRankLimit.value,
        moudle: activeModule,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      categoryOrderRank.value = resp.data;
      _clampRankPage(industryOrderRankPage, industryOrderTotalPages);
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadOfficeOrderRank() async {
    if (!_hasSelectedModule) return;
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisOfficeOrder(
        type: analysisType,
        cityIds: cityIds.value?.toString(),
        districtIds: districtIds.value?.toString(),
        status: _analysisStatusParam,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
        limit: propertyOrderRankLimit.value,
        moudle: activeModule,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      officeOrderRank.value = resp.data;
      _clampRankPage(propertyOrderRankPage, propertyOrderTotalPages);
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadComprehensiveOrder() async {
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisComprehensiveOrder();
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      comprehensiveOrder.value = resp.data;
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadPropertyRank() async {
    if (!_hasSelectedModule) return;
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisPropertyRank(
        type: analysisType,
        cityIds: cityIds.value?.toString(),
        districtIds: districtIds.value?.toString(),
        status: _analysisStatusParam,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
        limit: propertyCompanyDeviceRankLimit.value,
        moudle: activeModule,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      propertyRank.value = resp.data;
      _clampRankPage(
        propertyCompanyDeviceRankPage,
        propertyCompanyDeviceTotalPages,
      );
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadUpRateRank() async {
    if (!_hasSelectedModule) return;
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisUpRateDailyRank(
        type: analysisType,
        cityIds: cityIds.value?.toString(),
        districtIds: districtIds.value?.toString(),
        status: _analysisStatusParam,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
        limit: publicationRateRankLimit.value,
        moudle: activeModule,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      upRateRank.value = resp.data;
      _clampRankPage(publicationRateRankPage, publicationRateTotalPages);
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> loadPlayTrends() async {
    try {
      final range = _playTrendDateRange;
      final resp = await AdDataAnalysisApi.dataAnalysisPlayTrends(
        startDate: _formatYmd(range.start),
        endDate: _formatYmd(range.end),
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      playTrends.value = resp.data;
    } catch (e) {
      showError('$e');
    }
  }

  DateTimeRange get _playTrendDateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final days = switch (playTrendPreset.value) {
      '15d' => 15,
      '30d' => 30,
      '60d' => 60,
      '90d' => 90,
      _ => 7,
    };
    return DateTimeRange(end.subtract(Duration(days: days - 1)), end);
  }

  void setPlayTrendPreset(String? value) {
    final next = value?.trim();
    if (next == null || next.isEmpty) return;
    if (playTrendPreset.value == next) return;
    playTrendPreset.value = next;
    loadPlayTrends();
  }

  Future<void> loadOrderTrends() async {
    try {
      final range = _orderTrendDateRange;
      final resp = await AdDataAnalysisApi.dataAnalysisTrendsOrder(
        type: orderTrendType.value,
        startDate: _formatYmd(range.start),
        endDate: _formatYmd(range.end),
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      orderTrends.value = resp.data;
    } catch (e) {
      showError('$e');
    }
  }

  DateTimeRange get _orderTrendDateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final days = switch (orderTrendPreset.value) {
      '15d' => 15,
      '30d' => 30,
      '60d' => 60,
      '90d' => 90,
      _ => 7,
    };
    return DateTimeRange(end.subtract(Duration(days: days - 1)), end);
  }

  void setOrderTrendType(int type) {
    if (type < 1 || type > 3 || orderTrendType.value == type) return;
    orderTrendType.value = type;
    loadOrderTrends();
  }

  void setOrderTrendPreset(String? value) {
    final next = value?.trim();
    if (next == null || next.isEmpty) return;
    if (orderTrendPreset.value == next) return;
    orderTrendPreset.value = next;
    loadOrderTrends();
  }

  Future<void> loadComprehensive() async {
    try {
      final resp = await AdDataAnalysisApi.dataAnalysisComprehensive();
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      comprehensive.value = resp.data;
    } catch (e) {
      showError('$e');
    }
  }

  void _resetLowerRankPages() {
    publicationRateRankPage.value = 1;
    propertyCompanyDeviceRankPage.value = 1;
    customerOrderRankPage.value = 1;
    industryOrderRankPage.value = 1;
    propertyOrderRankPage.value = 1;
  }

  void _clampRankPage(RxInt page, int maxPages) {
    final max = maxPages < 1 ? 1 : maxPages;
    if (page.value < 1) {
      page.value = 1;
    } else if (page.value > max) {
      page.value = max;
    }
  }

  void _clampLowerRankPages() {
    _clampRankPage(publicationRateRankPage, publicationRateTotalPages);
    _clampRankPage(
      propertyCompanyDeviceRankPage,
      propertyCompanyDeviceTotalPages,
    );
    _clampRankPage(customerOrderRankPage, customerOrderTotalPages);
    _clampRankPage(industryOrderRankPage, industryOrderTotalPages);
    _clampRankPage(propertyOrderRankPage, propertyOrderTotalPages);
  }

  Future<void> loadAnalysisRank() async {
    analysisRank.value = null;
    rankLoading.value = true;
    try {
      final tops = [
        customerOrderRankLimit.value,
        industryOrderRankLimit.value,
        propertyOrderRankLimit.value,
      ];
      var fetchLimit = rankVisibleRows;
      for (final top in tops) {
        if (top > fetchLimit) fetchLimit = top;
      }
      final resp = await AdDataAnalysisApi.dataAnalysisRank(
        type: analysisType,
        startDate: rankStartDateParam,
        endDate: rankEndDateParam,
        // 一次拉齐各榜 TOP，本地翻页；不传 page / *_page。
        limit: fetchLimit,
        customerOrderTop: customerOrderRankLimit.value,
        industryOrderTop: industryOrderRankLimit.value,
        propertyOrderTop: propertyOrderRankLimit.value,
        cityIds: cityIds.value,
        districtIds: districtIds.value,
        isVolume: isVolume.value,
      );
      if (!resp.isSuccess()) {
        showError(resp.info());
        return;
      }
      analysisRank.value = resp.data;
      _clampLowerRankPages();
    } catch (e) {
      showError('$e');
    } finally {
      rankLoading.value = false;
    }
  }

  void selectScope(int index) {
    if (scopeIndex.value == index) return;
    scopeIndex.value = index;
    selectedModule.value = null;
    analysis.value = null;
    districtRank.value = null;
    propertyRank.value = null;
    upRateRank.value = null;
    playTrends.value = null;
    comprehensive.value = null;
    customerOrderRank.value = null;
    categoryOrderRank.value = null;
    officeOrderRank.value = null;
    comprehensiveOrder.value = null;
    orderTrends.value = null;
    analysisRank.value = null;
    districtRankPage.value = 1;
    mediaLocationRankPage.value = 1;
    _resetLowerRankPages();
    loadAnalysis();
    if (scopeIndex.value == 0) {
      loadPlayTrends();
      loadComprehensive();
    } else {
      loadOrderTrends();
      loadComprehensiveOrder();
    }
  }

  void selectToday() => setDate(DateTime.now());

  void selectYesterday() =>
      setDate(DateTime.now().subtract(const Duration(days: 1)));

  void setDate(DateTime? value) {
    if (value == null) return;
    final cur = selectedDate.value;
    if (cur.year == value.year &&
        cur.month == value.month &&
        cur.day == value.day) {
      return;
    }
    selectedDate.value = DateTime(value.year, value.month, value.day);
    districtRankPage.value = 1;
    mediaLocationRankPage.value = 1;
    loadAnalysis();
  }

  void selectModule(String? key) {
    final next = key?.trim();
    if (next == null || next.isEmpty) return;
    if (_isNonSelectableModule(next)) return;
    if (selectedModule.value == next) return;
    selectedModule.value = next;
    districtRankPage.value = 1;
    mediaLocationRankPage.value = 1;
    propertyCompanyDeviceRankPage.value = 1;
    publicationRateRankPage.value = 1;
    customerOrderRankPage.value = 1;
    industryOrderRankPage.value = 1;
    propertyOrderRankPage.value = 1;
    _loadRanksForSelectedModule();
  }

  void setOrderStatus(int? value) {
    if (value == null || orderStatus.value == value) return;
    orderStatus.value = value;
    districtRankPage.value = 1;
    mediaLocationRankPage.value = 1;
    loadAnalysis();
  }

  /// 调整行政区 TOP，回到第 1 页后请求接口。
  void setDistrictRankLimit(int? value) {
    if (value == null || districtRankLimit.value == value) return;
    districtRankLimit.value = value;
    districtRankPage.value = 1;
    loadDistrictRank();
  }

  /// 调整媒体位置 TOP，回到第 1 页后请求接口。
  void setMediaLocationRankLimit(int? value) {
    if (value == null || mediaLocationRankLimit.value == value) return;
    mediaLocationRankLimit.value = value;
    mediaLocationRankPage.value = 1;
    loadAnalysis();
  }

  /// 切换行政区排行页码（本地切片，不请求接口）。
  void setDistrictRankPage(int page) {
    final maxPage = districtTotalPages;
    if (page < 1 || page > maxPage || districtRankPage.value == page) return;
    districtRankPage.value = page;
  }

  /// 切换媒体位置排行页码（本地切片，不请求接口）。
  void setMediaLocationRankPage(int page) {
    final maxPage = mediaLocationTotalPages;
    if (page < 1 || page > maxPage || mediaLocationRankPage.value == page) {
      return;
    }
    mediaLocationRankPage.value = page;
  }

  void setPublicationRateRankLimit(int? value) {
    if (value == null || publicationRateRankLimit.value == value) return;
    publicationRateRankLimit.value = value;
    publicationRateRankPage.value = 1;
    loadUpRateRank();
  }

  void setPropertyCompanyDeviceRankLimit(int? value) {
    if (value == null || propertyCompanyDeviceRankLimit.value == value) return;
    propertyCompanyDeviceRankLimit.value = value;
    propertyCompanyDeviceRankPage.value = 1;
    loadPropertyRank();
  }

  void setCustomerOrderRankLimit(int? value) {
    if (value == null || customerOrderRankLimit.value == value) return;
    customerOrderRankLimit.value = value;
    customerOrderRankPage.value = 1;
    loadCustomerOrderRank();
  }

  void setIndustryOrderRankLimit(int? value) {
    if (value == null || industryOrderRankLimit.value == value) return;
    industryOrderRankLimit.value = value;
    industryOrderRankPage.value = 1;
    loadCategoryOrderRank();
  }

  void setPropertyOrderRankLimit(int? value) {
    if (value == null || propertyOrderRankLimit.value == value) return;
    propertyOrderRankLimit.value = value;
    propertyOrderRankPage.value = 1;
    loadOfficeOrderRank();
  }

  void setPublicationRateRankPage(int page) {
    final maxPage = publicationRateTotalPages;
    if (page < 1 || page > maxPage || publicationRateRankPage.value == page) {
      return;
    }
    publicationRateRankPage.value = page;
  }

  void setPropertyCompanyDeviceRankPage(int page) {
    final maxPage = propertyCompanyDeviceTotalPages;
    if (page < 1 ||
        page > maxPage ||
        propertyCompanyDeviceRankPage.value == page) {
      return;
    }
    propertyCompanyDeviceRankPage.value = page;
  }

  void setCustomerOrderRankPage(int page) {
    final maxPage = customerOrderTotalPages;
    if (page < 1 || page > maxPage || customerOrderRankPage.value == page) {
      return;
    }
    customerOrderRankPage.value = page;
  }

  void setIndustryOrderRankPage(int page) {
    final maxPage = industryOrderTotalPages;
    if (page < 1 || page > maxPage || industryOrderRankPage.value == page) {
      return;
    }
    industryOrderRankPage.value = page;
  }

  void setPropertyOrderRankPage(int page) {
    final maxPage = propertyOrderTotalPages;
    if (page < 1 || page > maxPage || propertyOrderRankPage.value == page) {
      return;
    }
    propertyOrderRankPage.value = page;
  }

  void selectTimePreset(AnalyticsTimePreset? value) {
    if (value == null || timePreset.value == value) return;
    timePreset.value = value;
    rankDateRange.value = _rangeForPreset(value);
    _resetLowerRankPages();
    Future.microtask(_reloadByTimeDimension);
  }

  void setRankDateRange(DateTimeRange? value) {
    rankDateRange.value = value;
    if (value != null && timePreset.value != AnalyticsTimePreset.all) {
      timePreset.value = AnalyticsTimePreset.all;
    }
    _resetLowerRankPages();
    Future.microtask(_reloadByTimeDimension);
  }

  void setIsVolume(int? value) {
    final next = (value == null || value < 0) ? null : value;
    if (isVolume.value == next) return;
    isVolume.value = next;
    _resetLowerRankPages();
    _reloadLowerOrderRanks();
  }

  void resetRankFilters() {
    timePreset.value = AnalyticsTimePreset.all;
    rankDateRange.value = null;
    isVolume.value = null;
    orderStatus.value = 99;
    cityIds.value = null;
    districtIds.value = null;
    publicationRateRankLimit.value = 10;
    propertyCompanyDeviceRankLimit.value = 10;
    customerOrderRankLimit.value = 10;
    industryOrderRankLimit.value = 10;
    propertyOrderRankLimit.value = 10;
    _resetLowerRankPages();
    Future.microtask(_reloadByTimeDimension);
  }

  /// 时间维度变更：KPI 完成后默认选中第一张卡，再拉排行。
  void _reloadByTimeDimension() {
    loadAnalysis();
  }

  void _reloadLowerOrderRanks() {
    if (!_hasSelectedModule) return;
    _loadRanksForSelectedModule();
  }

  /// 默认选中第一张可点 KPI；当前选中仍有效则保留。选中后再请求下方排行。
  void _syncSelectedModule(AdDataAnalysisEntity? data) {
    final cards =
        data?.kpiCards ??
        data?.overview ??
        const <AdDataAnalysisOverviewEntity>[];
    if (cards.isEmpty) {
      selectedModule.value = null;
      return;
    }
    final selectable = <String>[
      for (final item in cards)
        if (item.key?.trim().isNotEmpty == true &&
            !_isNonSelectableModule(item.key!.trim()))
          item.key!.trim(),
    ];
    if (selectable.isEmpty) {
      selectedModule.value = null;
      return;
    }
    final current = selectedModule.value?.trim();
    if (current != null && selectable.contains(current)) return;
    selectedModule.value = selectable.first;
  }

  /// 订单「客户总数」等不参与排行模块切换的指标。
  static bool _isNonSelectableModule(String key) => key == 'total_customers';

  AnalyticsMetric _metricFromOverview(
    AdDataAnalysisOverviewEntity item,
    int index,
  ) {
    final trend = item.trend;
    final ratioValue = item.ratio?.value?.trim();
    final useRatio = ratioValue != null && ratioValue.isNotEmpty;
    final direction = (trend?.type ?? trend?.direction ?? 'up').toLowerCase();
    final isUp = direction != 'down';
    final trendRaw = trend?.value ?? trend?.percent ?? trend?.diffValue;
    final trendText = trendRaw == null ? null : '$trendRaw'.trim();
    final trendLooksRatio =
        trendText != null &&
        (trendText.contains('%') || trendText.contains('％'));
    final trendDisplay = (trendText != null && trendText.isNotEmpty)
        ? (trendLooksRatio
              ? _formatRatio(trendText)
              : _formatTrendValue(trendRaw))
        : _formatTrendValue(null);
    final ratioLabel = item.ratio?.label?.trim();
    final compare = trend?.compare?.trim().isNotEmpty == true
        ? trend!.compare!.trim()
        : (trend?.diffLabel?.trim().isNotEmpty == true
              ? trend!.diffLabel!.trim()
              : '较昨日');
    final diffLabel = useRatio
        ? (ratioLabel != null && ratioLabel.isNotEmpty ? ratioLabel : '占比')
        : compare;
    final value = item.value ?? 0;
    final titleRaw = item.label?.trim().isNotEmpty == true
        ? item.label!.trim()
        : item.name?.trim();
    return AnalyticsMetric(
      key: item.key,
      title: titleRaw != null && titleRaw.isNotEmpty ? titleRaw : '-',
      value: _formatInt(value),
      unit: item.unit?.trim().isNotEmpty == true ? item.unit!.trim() : '',
      percent: useRatio ? _formatRatio(ratioValue) : trendDisplay,
      percentUp: isUp,
      diffLabel: diffLabel,
      diffDisplay: useRatio
          ? _formatRatio(ratioValue)
          : _formatTrendValue(trendRaw),
      showDiffTrend: !useRatio,
      diffUp: useRatio ? isUp : !_isTrendNegative(trendRaw),
      icon: _iconFor(item.icon, item.key),
      iconAsset: _metricIconAssetFor(
        item.icon,
        item.key,
        scopeIndex: scopeIndex.value,
        index: index,
      ),
      accent: _metricAccents[index % _metricAccents.length],
      fill: _metricFills[index % _metricFills.length],
    );
  }

  static String _formatTrendValue(dynamic value) {
    if (value == null) return '0';
    if (value is num) {
      if (value == value.roundToDouble()) return _formatInt(value.round());
      return value.toString();
    }
    final text = '$value'.trim();
    return text.isEmpty ? '0' : text;
  }

  static bool _isTrendNegative(dynamic value) {
    if (value == null) return false;
    if (value is num) return value < 0;
    final text = '$value'.trim();
    if (text.startsWith('-')) return true;
    final n = double.tryParse(text.replaceAll('%', ''));
    return n != null && n < 0;
  }

  static const _totalModuleKeys = {
    'total_devices',
    'total_orders',
    'total_customers',
  };

  static bool isTotalModule(String? key) {
    final token = key?.trim();
    return token != null &&
        token.isNotEmpty &&
        _totalModuleKeys.contains(token);
  }

  List<AnalyticsRankItem> _districtRanksFrom(
    AdDataAnalysisDistrictRankEntity? data,
    String? moduleKey,
  ) {
    final list = data?.list ?? const <AdDataAnalysisDistrictRankItemEntity>[];
    return [for (final item in list) _districtRankItem(item, moduleKey)];
  }

  AnalyticsRankItem _districtRankItem(
    AdDataAnalysisDistrictRankItemEntity item,
    String? moduleKey,
  ) {
    final bars =
        item.progressBars ?? const <AdDataAnalysisDistrictRankBarEntity>[];
    final key = moduleKey?.trim();
    if (isTotalModule(key)) {
      return _districtTotalRankItem(item, bars, key!);
    }

    AdDataAnalysisDistrictRankBarEntity? bar;
    if (key != null && key.isNotEmpty) {
      for (final candidate in bars) {
        if (candidate.key?.trim() == key) {
          bar = candidate;
          break;
        }
      }
    }
    bar ??= bars.isNotEmpty ? bars.first : null;
    final value = bar?.value ?? item.total ?? 0;
    return AnalyticsRankItem(
      label: item.name?.trim().isNotEmpty == true ? item.name!.trim() : '-',
      value: value.toDouble(),
      percentage: _parsePercentDouble(bar?.percentage),
      barColor: _accentForModuleKey(key),
    );
  }

  AnalyticsRankItem _districtTotalRankItem(
    AdDataAnalysisDistrictRankItemEntity item,
    List<AdDataAnalysisDistrictRankBarEntity> bars,
    String totalKey,
  ) {
    AdDataAnalysisDistrictRankBarEntity? totalBar;
    for (final candidate in bars) {
      if (candidate.key?.trim() == totalKey) {
        totalBar = candidate;
        break;
      }
    }
    totalBar ??= bars.isNotEmpty ? bars.first : null;

    final rowTotal = item.total ?? totalBar?.value ?? 0;
    final keyOrder = _kpiKeysInOrder;
    final segmentBars =
        <AdDataAnalysisDistrictRankBarEntity>[
          for (final bar in bars)
            if (!isTotalModule(bar.key)) bar,
        ]..sort((a, b) {
          final ai = keyOrder.indexOf(a.key?.trim() ?? '');
          final bi = keyOrder.indexOf(b.key?.trim() ?? '');
          final ar = ai < 0 ? keyOrder.length : ai;
          final br = bi < 0 ? keyOrder.length : bi;
          return ar.compareTo(br);
        });
    var segmentSum = 0;
    for (final bar in segmentBars) {
      segmentSum += bar.value ?? 0;
    }

    final accents = _metricAccentMap;
    final segments = <AnalyticsRankSegment>[
      for (final bar in segmentBars)
        if ((bar.value ?? 0) > 0 && segmentSum > 0)
          AnalyticsRankSegment(
            factor: (bar.value ?? 0) / segmentSum,
            color: accents[bar.key?.trim()] ?? _metricAccents.first,
            label: _metricBarLabel(bar.label, bar.key),
            value: (bar.value ?? 0).toDouble(),
          ),
    ];
    final previewBars = List<AdDataAnalysisDistrictRankBarEntity>.of(bars)
      ..sort((a, b) {
        final ai = keyOrder.indexOf(a.key?.trim() ?? '');
        final bi = keyOrder.indexOf(b.key?.trim() ?? '');
        final ar = ai < 0 ? keyOrder.length : ai;
        final br = bi < 0 ? keyOrder.length : bi;
        return ar.compareTo(br);
      });
    final previewSegments = <AnalyticsRankSegment>[
      for (final bar in previewBars)
        AnalyticsRankSegment(
          factor: 0,
          color: accents[bar.key?.trim()] ?? _metricAccents.first,
          label: _metricBarLabel(bar.label, bar.key),
          value: (bar.value ?? 0).toDouble(),
        ),
    ];

    return AnalyticsRankItem(
      label: item.name?.trim().isNotEmpty == true ? item.name!.trim() : '-',
      value: rowTotal.toDouble(),
      percentage: _parsePercentDouble(totalBar?.percentage),
      segments: segments.isEmpty ? null : segments,
      previewSegments: previewSegments.isEmpty ? null : previewSegments,
    );
  }

  String _metricBarLabel(String? label, String? key) {
    final text = label?.trim();
    if (text != null && text.isNotEmpty) return text;
    final token = key?.trim();
    if (token != null && token.isNotEmpty) {
      for (final card in _overviewCards) {
        if (card.key?.trim() != token) continue;
        final name = card.name?.trim();
        if (name != null && name.isNotEmpty) return name;
        final cardLabel = card.label?.trim();
        if (cardLabel != null && cardLabel.isNotEmpty) return cardLabel;
      }
      return token;
    }
    return '-';
  }

  static double? _parsePercentDouble(String? percent) {
    if (percent == null || percent.trim().isEmpty) return null;
    return double.tryParse(percent.replaceAll('%', '').trim());
  }

  List<AnalyticsRankItem> _simpleProgressRanksFrom(
    AdDataAnalysisDistrictRankEntity? data,
  ) {
    final list = data?.list ?? const <AdDataAnalysisDistrictRankItemEntity>[];
    return [for (final item in list) _simpleProgressRankItem(item)];
  }

  AnalyticsRankItem _simpleProgressRankItem(
    AdDataAnalysisDistrictRankItemEntity item,
  ) {
    final bars =
        item.progressBars ?? const <AdDataAnalysisDistrictRankBarEntity>[];
    final bar = bars.isNotEmpty ? bars.first : null;
    final value = (item.total ?? bar?.value ?? 0).toDouble();
    return AnalyticsRankItem(
      label: item.name?.trim().isNotEmpty == true ? item.name!.trim() : '-',
      value: value,
      percentage: _parsePercentDouble(bar?.percentage),
      barColor: _accentForModuleKey(activeModule),
    );
  }

  List<AnalyticsRankItem> _publicationRateRanksFrom(
    AdDataAnalysisUpRateRankEntity? data,
  ) {
    final list = data?.list ?? const <AdDataAnalysisUpRateRankItemEntity>[];
    return [for (final item in list) _upRateRankItem(item)];
  }

  AnalyticsRankItem _upRateRankItem(AdDataAnalysisUpRateRankItemEntity item) {
    final bars =
        item.progressBars ?? const <AdDataAnalysisUpRateRankBarEntity>[];
    AdDataAnalysisUpRateRankBarEntity? bar;
    for (final candidate in bars) {
      if (candidate.key?.trim() == 'publish_rate') {
        bar = candidate;
        break;
      }
    }
    bar ??= bars.isNotEmpty ? bars.first : null;
    final rate = (bar?.value ?? item.total ?? 0).toDouble();
    final percentText = bar?.percentage?.trim();
    return AnalyticsRankItem(
      label: item.name?.trim().isNotEmpty == true ? item.name!.trim() : '-',
      value: rate,
      suffix: '%',
      percentage: _parsePercentDouble(percentText) ?? rate,
      displayText: (percentText != null && percentText.isNotEmpty)
          ? percentText
          : null,
    );
  }

  List<AnalyticsRankItem> _propertyCompanyDeviceRanksFrom(
    AdDataAnalysisPropertyRankEntity? data,
    String? moduleKey,
  ) {
    final list = data?.list ?? const <AdDataAnalysisPropertyRankItemEntity>[];
    return [for (final item in list) _propertyRankItem(item, moduleKey)];
  }

  AnalyticsRankItem _propertyRankItem(
    AdDataAnalysisPropertyRankItemEntity item,
    String? moduleKey,
  ) {
    final bars =
        item.progressBars ?? const <AdDataAnalysisPropertyRankBarEntity>[];
    final key = moduleKey?.trim();
    if (isTotalModule(key)) {
      return _propertyTotalRankItem(item, bars, key!);
    }

    AdDataAnalysisPropertyRankBarEntity? bar;
    if (key != null && key.isNotEmpty) {
      for (final candidate in bars) {
        if (candidate.key?.trim() == key) {
          bar = candidate;
          break;
        }
      }
    }
    bar ??= bars.isNotEmpty ? bars.first : null;
    final value = bar?.value ?? item.total ?? 0;
    return AnalyticsRankItem(
      label: item.name?.trim().isNotEmpty == true ? item.name!.trim() : '-',
      value: value.toDouble(),
      percentage: _parsePercentDouble(bar?.percentage),
      barColor: _accentForModuleKey(key),
    );
  }

  AnalyticsRankItem _propertyTotalRankItem(
    AdDataAnalysisPropertyRankItemEntity item,
    List<AdDataAnalysisPropertyRankBarEntity> bars,
    String totalKey,
  ) {
    AdDataAnalysisPropertyRankBarEntity? totalBar;
    for (final candidate in bars) {
      if (candidate.key?.trim() == totalKey) {
        totalBar = candidate;
        break;
      }
    }
    totalBar ??= bars.isNotEmpty ? bars.first : null;

    final rowTotal = item.total ?? totalBar?.value ?? 0;
    final keyOrder = _kpiKeysInOrder;
    final segmentBars =
        <AdDataAnalysisPropertyRankBarEntity>[
          for (final bar in bars)
            if (!isTotalModule(bar.key)) bar,
        ]..sort((a, b) {
          final ai = keyOrder.indexOf(a.key?.trim() ?? '');
          final bi = keyOrder.indexOf(b.key?.trim() ?? '');
          final ar = ai < 0 ? keyOrder.length : ai;
          final br = bi < 0 ? keyOrder.length : bi;
          return ar.compareTo(br);
        });
    var segmentSum = 0;
    for (final bar in segmentBars) {
      segmentSum += bar.value ?? 0;
    }

    final accents = _metricAccentMap;
    final segments = <AnalyticsRankSegment>[
      for (final bar in segmentBars)
        if ((bar.value ?? 0) > 0 && segmentSum > 0)
          AnalyticsRankSegment(
            factor: (bar.value ?? 0) / segmentSum,
            color: accents[bar.key?.trim()] ?? _metricAccents.first,
            label: _metricBarLabel(bar.label, bar.key),
            value: (bar.value ?? 0).toDouble(),
          ),
    ];
    final previewBars = List<AdDataAnalysisPropertyRankBarEntity>.of(bars)
      ..sort((a, b) {
        final ai = keyOrder.indexOf(a.key?.trim() ?? '');
        final bi = keyOrder.indexOf(b.key?.trim() ?? '');
        final ar = ai < 0 ? keyOrder.length : ai;
        final br = bi < 0 ? keyOrder.length : bi;
        return ar.compareTo(br);
      });
    final previewSegments = <AnalyticsRankSegment>[
      for (final bar in previewBars)
        AnalyticsRankSegment(
          factor: 0,
          color: accents[bar.key?.trim()] ?? _metricAccents.first,
          label: _metricBarLabel(bar.label, bar.key),
          value: (bar.value ?? 0).toDouble(),
        ),
    ];

    return AnalyticsRankItem(
      label: item.name?.trim().isNotEmpty == true ? item.name!.trim() : '-',
      value: rowTotal.toDouble(),
      percentage: _parsePercentDouble(totalBar?.percentage),
      segments: segments.isEmpty ? null : segments,
      previewSegments: previewSegments.isEmpty ? null : previewSegments,
    );
  }

  static DateTimeRange? _rangeForPreset(AnalyticsTimePreset preset) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    return switch (preset) {
      AnalyticsTimePreset.all => null,
      AnalyticsTimePreset.today => DateTimeRange(end, end),
      AnalyticsTimePreset.day7 => DateTimeRange(
        end.subtract(const Duration(days: 6)),
        end,
      ),
      AnalyticsTimePreset.day30 => DateTimeRange(
        end.subtract(const Duration(days: 29)),
        end,
      ),
      AnalyticsTimePreset.day90 => DateTimeRange(
        end.subtract(const Duration(days: 89)),
        end,
      ),
      AnalyticsTimePreset.month6 => DateTimeRange(
        end.subtract(const Duration(days: 179)),
        end,
      ),
      AnalyticsTimePreset.year1 => DateTimeRange(
        end.subtract(const Duration(days: 364)),
        end,
      ),
    };
  }

  static String _formatYmd(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static String _formatInt(int value) {
    final raw = value.abs().toString();
    final buf = StringBuffer();
    if (value < 0) buf.write('-');
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      buf.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static String _formatNum(num? value) {
    if (value == null) return '0';
    if (value is int || value == value.roundToDouble()) {
      return _formatInt(value.round());
    }
    return value.toStringAsFixed(1);
  }

  static IconData _situationIconFor(String? icon) {
    return switch (icon?.trim()) {
      'building' => AppLucideIcons.building2,
      'area' => AppLucideIcons.mapPin,
      'up_rate_daily' => AppLucideIcons.chartLine,
      'kind' => AppLucideIcons.monitor,
      _ => AppLucideIcons.chartColumn,
    };
  }

  static String _formatRatio(String? ratio) {
    final raw = ratio?.trim();
    if (raw == null || raw.isEmpty) return '0.00%';
    return raw.contains('%') ? raw : '$raw%';
  }

  static IconData _iconFor(String? icon, String? key) {
    final token = (icon ?? key ?? '').trim();
    return switch (token) {
      'device' || 'total_devices' || 'total_orders' => AppLucideIcons.monitor,
      'screen_98' || 'device_98inch' || 'order_98inch' => AppLucideIcons.tv,
      'screen_86' ||
      'device_86inch' ||
      'order_86inch' => AppLucideIcons.monitor,
      'volume_on' || 'audio_enabled' => AppLucideIcons.volume2,
      'volume_off' || 'audio_disabled' => AppLucideIcons.volumeX,
      'clipboard' || 'order' => AppLucideIcons.clipboardList,
      _ => AppLucideIcons.chartColumn,
    };
  }

  /// 指标卡图标（按顺序固定；客户订单仅第 1 张用 order_total，其余与设备共用）。
  static const _deviceMetricIconAssets = <String>[
    'assets/images/analytics/device_card_total.svg',
    'assets/images/analytics/device_card_98inch.svg',
    'assets/images/analytics/device_card_86inch.svg',
    'assets/images/analytics/device_card_volume_on.svg',
    'assets/images/analytics/device_card_volume_off.svg',
  ];

  static const _orderMetricIconAssets = <String>[
    'assets/images/analytics/order_card_total.svg',
    'assets/images/analytics/device_card_98inch.svg',
    'assets/images/analytics/device_card_86inch.svg',
    'assets/images/analytics/order_card_customers.png',
    'assets/images/analytics/order_card_completed.svg',
  ];

  /// 优先按卡片序号取图（不依赖接口 key/icon 命名）；再按 key/icon 兜底。
  static String? _metricIconAssetFor(
    String? icon,
    String? key, {
    required int scopeIndex,
    required int index,
  }) {
    final byIndex = scopeIndex == 0
        ? (index >= 0 && index < _deviceMetricIconAssets.length
              ? _deviceMetricIconAssets[index]
              : null)
        : (index >= 0 && index < _orderMetricIconAssets.length
              ? _orderMetricIconAssets[index]
              : null);
    if (byIndex != null) return byIndex;

    final keyToken = key?.trim() ?? '';
    final iconToken = icon?.trim() ?? '';
    if (keyToken == 'total_devices') {
      return 'assets/images/analytics/device_total.png';
    }
    if (keyToken == 'total_orders') {
      return 'assets/images/analytics/order_total.png';
    }
    if (keyToken == 'total_customers') {
      return 'assets/images/analytics/order_customers.png';
    }
    if (keyToken == 'completed_orders') {
      return 'assets/images/analytics/order_completed.png';
    }
    return _metricIconAssetByToken(keyToken) ??
        _metricIconAssetByToken(iconToken);
  }

  static String? _metricIconAssetByToken(String token) {
    if (token.isEmpty) return null;
    return switch (token) {
      'device' => 'assets/images/analytics/device_total.png',
      'clipboard' || 'order' => 'assets/images/analytics/order_total.png',
      'screen_98' ||
      'device_98inch' ||
      'order_98inch' => 'assets/images/analytics/device_98inch.png',
      'screen_86' ||
      'device_86inch' ||
      'order_86inch' => 'assets/images/analytics/device_86inch.png',
      'volume_on' ||
      'audio_enabled' => 'assets/images/analytics/device_volume_on.png',
      'volume_off' ||
      'audio_disabled' => 'assets/images/analytics/device_volume_off.png',
      _ => null,
    };
  }
}

enum AnalyticsTimePreset { all, today, day7, day30, day90, month6, year1 }

@immutable
class AnalyticsMetric {
  const AnalyticsMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.percent,
    required this.percentUp,
    required this.diffLabel,
    required this.diffDisplay,
    required this.showDiffTrend,
    required this.diffUp,
    required this.icon,
    required this.accent,
    required this.fill,
    this.key,
    this.iconAsset,
  });

  final String? key;
  final String title;
  final String value;
  final String unit;
  final String percent;
  final bool percentUp;
  final String diffLabel;
  final String diffDisplay;
  final bool showDiffTrend;
  final bool diffUp;
  final IconData icon;
  final String? iconAsset;
  final Color accent;

  /// 浅色：选中态卡片底色 / 未选中态图标色（未选中卡片底色再向白色淡化）。
  final Color fill;
}

@immutable
class AnalyticsRankSegment {
  const AnalyticsRankSegment({
    required this.factor,
    required this.color,
    this.label = '',
    this.value = 0,
  });

  /// 段宽占已填充区域的比例（0~1）。
  final double factor;
  final Color color;

  /// 悬停预览标签。
  final String label;

  /// 悬停预览数值。
  final double value;
}

@immutable
class AnalyticsRankItem {
  const AnalyticsRankItem({
    required this.label,
    required this.value,
    this.suffix = '',
    this.percentage,
    this.displayText,
    this.segments,
    this.previewSegments,
    this.barColor,
  });

  final String label;
  final double value;
  final String suffix;

  /// 接口返回的占比（0~100，如 0.58、100）。
  final double? percentage;

  /// 右侧展示文案（如接口原样返回的 100.00%）。
  final String? displayText;

  /// 仅「全部」指标（total_devices / total_orders）时有值。
  final List<AnalyticsRankSegment>? segments;

  /// 悬停预览明细（含总量等全部分段）。
  final List<AnalyticsRankSegment>? previewSegments;

  /// 单段进度条颜色（与上方对应指标卡 accent 一致）。
  final Color? barColor;

  /// 进度条宽度因子（0~1）。
  double get barFactor {
    final p = percentage;
    if (p == null) {
      // Demo：后缀为 % 时，value 已是百分数。
      if (suffix.trim() == '%') return (value / 100).clamp(0.0, 1.0);
      return 0;
    }
    return (p / 100).clamp(0.0, 1.0);
  }

  String get displayValue {
    if (displayText != null && displayText!.isNotEmpty) return displayText!;
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text$suffix';
  }
}

@immutable
class AnalyticsSituationItem {
  const AnalyticsSituationItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.tile,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color tile;
}

@immutable
class AnalyticsEfficiencyItem {
  const AnalyticsEfficiencyItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.tile,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color tile;
}

@immutable
class AnalyticsDonutSection {
  const AnalyticsDonutSection({
    required this.label,
    required this.value,
    required this.color,
    this.percent,
  });

  final String label;
  final double value;
  final double? percent;
  final Color color;
}

@immutable
class AnalyticsDonutChartData {
  const AnalyticsDonutChartData({
    required this.title,
    required this.totalLabel,
    required this.total,
    required this.sections,
  });

  final String title;
  final String totalLabel;
  final double total;
  final List<AnalyticsDonutSection> sections;
}

@immutable
class AnalyticsOrderStatusItem {
  const AnalyticsOrderStatusItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final double value;
  final String percent;
  final Color color;
}

@immutable
class AnalyticsOrderExpiringItem {
  const AnalyticsOrderExpiringItem({
    required this.label,
    required this.value,
    required this.color,
    required this.tile,
  });

  final String label;
  final String value;
  final Color color;
  final Color tile;
}

/// 设备分析（接口 type=1）。
class AnalyticsDevicesController extends AnalyticsController {
  AnalyticsDevicesController() : super(initialScope: 0);
}

/// 订单分析（接口 type=2）。
class AnalyticsOrdersController extends AnalyticsController {
  AnalyticsOrdersController() : super(initialScope: 1);
}
