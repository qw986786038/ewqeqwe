import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad hide WidgetExtension;
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/pages/analytics/analytics_controller.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';

/// 数据分析页（设备 / 订单范围）。
///
/// 上游缺口（待回收）：
/// - 建议 `AppMetricCard`：左 56 图标 + 浅色底/描边 + 标题/数值/单位 + 较昨日趋势。
/// - 建议 `AppRankBadge` / `AppBadge.rank`：1–3 奖牌色 + 同色阴影 + 其余灰底序号。
/// - 建议 `AppCollapsibleRankCard`：accent 顶渐变 + 收起/展开；现本地 `_AnalyticsRankCard`。
/// - 建议 `AppTooltip.card` / 浅色明细气泡：现排行悬停用 OverlayPortal 白底卡。

// 数据分析：设备 / 订单两个子页面，同属一个 library（用 part 共享私有组件）。
part 'analytics_devices_page.dart';
part 'analytics_orders_page.dart';

/// 数据分析页：顶部 tab 在设备管理 / 客户订单两个子页间切换（页面内部切换，不新增路由）。
///
/// 设备 / 订单各用独立 Controller（[AnalyticsDevicesController] /
/// [AnalyticsOrdersController]），type=1 / type=2 分开请求，互不复用实例。
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<AnalyticsDevicesController>(
          AnalyticsDevicesController.new,
        );
        container.put<AnalyticsOrdersController>(
          AnalyticsOrdersController.new,
        );
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppTabs(
                            index: _tabIndex,
                            selectedColor: Colors.white,
                            onChanged: (index) {
                              if (_tabIndex == index) return;
                              setState(() => _tabIndex = index);
                            },
                            children: const [
                              AppTabItem(
                                child: Text(
                                  '设备管理',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              AppTabItem(
                                child: Text(
                                  '客户订单',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const AppDivider.horizontal(),
                      _AnalyticsRankFilterCard(
                        controller: _tabIndex == 0
                            ? context.lx.find<AnalyticsDevicesController>()
                            : context.lx.find<AnalyticsOrdersController>(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                (_tabIndex == 0
                        ? const AnalyticsDevicesPage()
                        : const AnalyticsOrdersPage())
                    .expanded(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 待上游回收：建议 `AppRankBadge(rank:)`；暂用本地方块徽章模拟。
Widget _rankBadge(int rank) {
  final (Color background, Color foreground) = switch (rank) {
    1 => (const Color(0xFFF5C518), const Color(0xFFFFFFFF)),
    2 => (const Color(0xFFB8C4D4), const Color(0xFF334155)),
    3 => (const Color(0xFFE8B48A), const Color(0xFF5C3D2E)),
    _ => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
  };

  return Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
      boxShadow: rank <= 3
          ? [
              BoxShadow(
                color: background.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    ),
    child: Text(
      '$rank',
      style: TextStyle(
        color: foreground,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    ),
  );
}

/// 全部弹窗内排行行高与行距。
const double _kRankRowGap = 16;
const double _kRankRowHeight = 20;

/// 排行卡内每行高度（设备 / 客户订单）。
const double _kOrderRankRowHeight = 50;

/// 排行表固定高度：表头 + 间距 + [AnalyticsController.rankVisibleRows] 行。
/// #4F6EF6，5% 透明度。
const Color _kAnalyticsTableHeaderBackground = Color(0x0D4F6EF6);

const double _kRankHeaderHeight = 44;
const double _kRankHeaderGap = 8;
const double _kRankChartHeight =
    _kRankHeaderHeight +
    _kRankHeaderGap +
    _kOrderRankRowHeight * AnalyticsController.rankVisibleRows;

/// 订单排行 AppTable 固定高度：表头 + [AnalyticsController.rankVisibleRows] 行。
const double _kOrderTableHeaderHeight = 36;
const double _kOrderTableRowHeight = 36;

/// 横幅排行卡表头高度。
const double _kBannerTableHeaderHeight = 40;
const double _kOrderTableHeight =
    _kBannerTableHeaderHeight +
    _kOrderRankRowHeight * AnalyticsController.rankVisibleRows;

String _formatRankValue(double value) {
  final raw = value.round().abs().toString();
  final buf = StringBuffer();
  if (value < 0) buf.write('-');
  for (var i = 0; i < raw.length; i++) {
    final fromEnd = raw.length - i;
    buf.write(raw[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

/// 排行进度条填充色。
const Color _kAnalyticsRankBarColor = Color(0xFF5B77FF);

const TextStyle _kAnalyticsTableTextStyle = TextStyle(fontSize: 14);

/// 序号列宽 40 居中，14 号「序号」左侧视觉约 8 + 6；右侧补到 14 与之对称。
const EdgeInsets _kRankRowPadding = EdgeInsets.fromLTRB(8, 0, 14, 0);

/// 横幅卡片内容区左右无内边距，表格行自带 16 保持文字位置。
const EdgeInsets _kBannerRankRowPadding = EdgeInsets.fromLTRB(24, 0, 30, 0);
const EdgeInsets _kBannerFirstCellPadding = EdgeInsets.fromLTRB(28, 0, 12, 0);
const EdgeInsets _kBannerLastCellPadding = EdgeInsets.fromLTRB(12, 0, 28, 0);

Widget _rankTableLabelText(String label, Color foreground) {
  return AppText.caption(
    label,
    scrollMode: AppTextScrollMode.hover,
    style: _kAnalyticsTableTextStyle.copyWith(color: foreground),
  );
}

/// 进度条宽度：接口占比 / 百分数值 / 当前页最大值归一化。
double _rankBarFactor(List<AnalyticsRankItem> items, AnalyticsRankItem item) {
  if (item.percentage != null || item.suffix.trim() == '%') {
    return item.barFactor;
  }
  var max = 0.0;
  for (final entry in items) {
    if (entry.value > max) max = entry.value;
  }
  if (max <= 0) return 0;
  return (item.value / max).clamp(0.0, 1.0);
}

Widget _rankBarFill({
  required shad.ColorScheme colors,
  required List<AnalyticsRankItem> items,
  required AnalyticsRankItem item,
  required double maxWidth,
}) {
  final fillWidth = maxWidth * _rankBarFactor(items, item);
  final segments = item.segments;
  if (segments != null && segments.isNotEmpty) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.muted),
        Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: SizedBox(
              width: fillWidth,
              height: 8,
              child: Row(
                children: [
                  for (final segment in segments)
                    if (segment.factor > 0)
                      SizedBox(
                        width: fillWidth * segment.factor,
                        height: 8,
                        child: ColoredBox(color: segment.color),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  return Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: colors.muted),
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: fillWidth,
          height: 8,
          child: ColoredBox(color: item.barColor ?? _kAnalyticsRankBarColor),
        ),
      ),
    ],
  );
}

/// 本地拼装排行条表：序号徽章 + 标签 + 进度条 + 数值。
Widget _rankTable({
  required BuildContext context,
  required List<AnalyticsRankItem> items,
  required String labelHeader,
  required String valueHeader,
  int rankOffset = 0,
  String Function(double value)? valueFormatter,

  /// true：偶数行（第 2、4…行）铺斑马底色，与 `AppTable.striped` 一致。
  bool striped = false,
}) {
  final colors = ShadcnTheme.of(context).colorScheme;
  final height = striped ? _kOrderTableHeight : _kRankChartHeight;
  final rowPadding = striped ? _kBannerRankRowPadding : _kRankRowPadding;
  if (items.isEmpty) {
    return SizedBox(
      height: height,
      child: const Center(child: AppEmptyState()),
    );
  }

  return SizedBox(
    height: height,
    child: Column(
      children: [
        Container(
          height: striped ? _kBannerTableHeaderHeight : _kRankHeaderHeight,
          padding: rowPadding,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _kAnalyticsTableHeaderBackground,
            borderRadius: striped
                ? null
                : const BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: AppText.caption(
                  '序号',
                  textAlign: TextAlign.center,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: AppText.caption(
                  labelHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: AppText.caption(
                  valueHeader,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!striped) const SizedBox(height: _kRankHeaderGap),
        Column(
          children: [
            for (var i = 0; i < AnalyticsController.rankVisibleRows; i++)
              SizedBox(
                height: _kOrderRankRowHeight,
                child: i >= items.length
                    ? const SizedBox.shrink()
                    : _RankItemHoverPreview(
                        segments: items[i].previewSegments,
                        valueFormatter: valueFormatter ?? _formatRankValue,
                        child: Container(
                          padding: rowPadding,
                          decoration: striped && i.isOdd
                              ? const BoxDecoration(
                                  color: kTableStripeBackground,
                                )
                              : null,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Center(
                                  child: _rankBadge(rankOffset + i + 1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: _rankTableLabelText(
                                  items[i].label,
                                  colors.foreground,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                  child: SizedBox(
                                    height: 8,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) =>
                                          _rankBarFill(
                                            colors: colors,
                                            items: items,
                                            item: items[i],
                                            maxWidth: constraints.maxWidth,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 56,
                                child: AppText.caption(
                                  valueFormatter?.call(items[i].value) ??
                                      items[i].displayValue,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _kAnalyticsTableTextStyle.copyWith(
                                    color: colors.foreground,
                                  ),
                                ),
                              ),
                            ],
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

/// 待上游：浅色明细悬停气泡；现用 OverlayPortal 实现白底预览卡。
class _RankItemHoverPreview extends StatefulWidget {
  const _RankItemHoverPreview({
    required this.child,
    required this.valueFormatter,
    this.segments,
  });

  final Widget child;
  final List<AnalyticsRankSegment>? segments;
  final String Function(double value) valueFormatter;

  @override
  State<_RankItemHoverPreview> createState() => _RankItemHoverPreviewState();
}

class _RankItemHoverPreviewState extends State<_RankItemHoverPreview> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    final segments = widget.segments;
    if (segments == null || segments.isEmpty) return widget.child;

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final colors = ShadcnTheme.of(context).colorScheme;
        return UnconstrainedBox(
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -8),
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.popover,
                  borderRadius: BorderRadius.circular(kControlRadius),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.foreground.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 132,
                      maxWidth: 168,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        for (final segment in segments)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: segment.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  segment.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.2,
                                    color: colors.foreground,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                widget.valueFormatter(segment.value),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                  color: colors.foreground,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => _portal.show(),
          onExit: (_) => _portal.hide(),
          child: widget.child,
        ),
      ),
    );
  }
}

Widget _districtRankTopSelect(AnalyticsController controller) {
  return Obx(
    () => AppSelect<int>(
      value: controller.districtRankLimit.value,
      options: controller.districtTopOptions,
      onChanged: controller.setDistrictRankLimit,
      minWidth: 110,
      hintText: 'TOP',
    ),
  );
}

Widget _lowerRankTopSelect({
  required int value,
  required ValueChanged<int?> onChanged,
}) {
  return AppSelect<int>(
    value: value,
    options: AnalyticsController.topOptions,
    onChanged: onChanged,
    minWidth: 110,
    hintText: 'TOP',
  );
}

/// 订单排行表：外层固定高度，只渲染真实数据行。
Widget _orderRankTable({
  required BuildContext context,
  required List<AnalyticsRankItem> items,
  required String labelHeader,
  int rankOffset = 0,
}) {
  final colors = ShadcnTheme.of(context).colorScheme;
  if (items.isEmpty) {
    return const SizedBox(
      height: _kOrderTableHeight,
      child: Center(child: AppEmptyState()),
    );
  }

  final visible = items.length > AnalyticsController.rankVisibleRows
      ? items.sublist(0, AnalyticsController.rankVisibleRows)
      : items;

  return SizedBox(
    height: _kOrderTableHeight,
    child: Align(
      alignment: Alignment.topCenter,
      child: AppTable(
        showOuterBorder: false,
        showInternalDividers: false,
        striped: true,
        stripeColor: kTableStripeBackground,
        headerHeight: _kBannerTableHeaderHeight,
        rowHeight: _kOrderRankRowHeight,
        headerBackgroundColor: _kAnalyticsTableHeaderBackground,
        borderRadius: BorderRadius.zero,
        columnWidths: const {
          0: FixedColumnWidth(80),
          1: FlexColumnWidth(),
          2: IntrinsicColumnWidth(),
        },
        rows: [
          AppTableHeader(
            cells: [
              AppTableCell(
                padding: _kBannerFirstCellPadding,
                child: AppText.caption(
                  '序号',
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              AppTableCell(
                child: AppText.caption(
                  labelHeader,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              AppTableCell(
                alignment: Alignment.centerRight,
                padding: _kBannerLastCellPadding,
                child: AppText.caption(
                  '订单数量',
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          for (var i = 0; i < visible.length; i++)
            AppTableRow(
              cells: [
                AppTableCell(
                  padding: _kBannerFirstCellPadding,
                  child: _rankBadge(rankOffset + i + 1),
                ),
                AppTableCell(
                  child: _rankTableLabelText(
                    visible[i].label,
                    colors.foreground,
                  ),
                ),
                AppTableCell(
                  alignment: Alignment.centerRight,
                  padding: _kBannerLastCellPadding,
                  child: AppText.caption(
                    visible[i].displayValue,
                    style: _kAnalyticsTableTextStyle.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

Widget _analyticsPagination({
  required int page,
  required int totalPages,
  required ValueChanged<int> onPageChanged,
}) {
  final pages = totalPages < 1 ? 1 : totalPages;
  return AppPagination(
    page: page.clamp(1, pages),
    totalPages: pages,
    onPageChanged: onPageChanged,
  ).center();
}

/// 同一行排行卡共用收起/展开状态。
class _SyncedRankExpandRow extends StatefulWidget {
  const _SyncedRankExpandRow({required this.builder});

  final List<Widget> Function(bool isExpanded, VoidCallback toggle) builder;

  @override
  State<_SyncedRankExpandRow> createState() => _SyncedRankExpandRowState();
}

class _SyncedRankExpandRowState extends State<_SyncedRankExpandRow> {
  bool _expanded = true;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: widget.builder(_expanded, _toggle),
    );
  }
}

/// 数据分析页卡片头部高度。
const double _kAnalyticsCardHeaderHeight = 52;

/// 排行卡顶部垂直渐变（上 → 下），与客户侧边栏排行卡一致。
const Color _kAnalyticsCardHeaderGradientStart = Color(0x4D6023FB);
const Color _kAnalyticsCardHeaderGradientEnd = Color(0xFFFFFFFF);
const double _kAnalyticsCardTopGradientHeight = 160;
Widget _analyticsCardGradientHeader({required Widget child}) {
  return Container(
    height: _kAnalyticsCardHeaderHeight,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: child,
  );
}

Widget _analyticsBorderCard({
  required BuildContext context,
  required Widget child,
  Widget? header,
  EdgeInsetsGeometry bodyPadding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  double borderWidth = 1,
  Color? borderColor,

  /// true：内容区占满卡片剩余高度（配合 Center 可垂直居中）。
  bool expandBody = false,

  /// 非空：卡片顶部铺 [_kAnalyticsCardTopGradientHeight] 高的垂直渐变。
  List<Color>? topGradientColors,
}) {
  final colors = ShadcnTheme.of(context).colorScheme;
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (header != null) header,
      if (expandBody)
        Expanded(
          child: Padding(padding: bodyPadding, child: child),
        )
      else
        Padding(padding: bodyPadding, child: child),
    ],
  );
  return AppCard(
    shadow: false,
    borderWidth: borderWidth,
    borderColor: borderColor ?? colors.border,
    borderRadius: BorderRadius.circular(24),
    padding: EdgeInsets.zero,
    fillColor: colors.card,
    clipBehavior: Clip.antiAlias,
    child: topGradientColors != null
        ? Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _kAnalyticsCardTopGradientHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: topGradientColors,
                    ),
                  ),
                ),
              ),
              content,
            ],
          )
        : content,
  );
}

/// 排行卡头部操作区：白底不透明 outline 控件（TOP / 收起）。
Widget _rankCardWhiteControl(Widget child) {
  return Builder(
    builder: (context) {
      final colors = ShadcnTheme.of(context).colorScheme;
      final radius = BorderRadius.circular(shad.Theme.of(context).radiusMd);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(color: Colors.white, child: child),
        ),
      );
    },
  );
}

/// 排行卡：头部垂直渐变 + 白底操作；内容区纯白（状态由同行 [_SyncedRankExpandRow] 同步）。
///
/// 待上游回收：建议 `AppCollapsibleRankCard(accent:, expanded:, onExpandedChanged:)`。
class _AnalyticsRankCard extends StatelessWidget {
  const _AnalyticsRankCard({
    required this.title,
    required this.accent,
    required this.child,
    required this.isExpanded,
    required this.onToggleExpand,
    this.actions,
    this.onViewAll,
    this.gradientColors = const [
      _kAnalyticsCardHeaderGradientStart,
      _kAnalyticsCardHeaderGradientEnd,
    ],
    this.bannerColors,
    this.titleIcon,
  });

  final String title;
  final Color accent;
  final Widget child;
  final Widget? actions;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onViewAll;

  /// 顶部垂直渐变色（上 → 下）。
  final List<Color> gradientColors;

  /// 非空：实色渐变横幅头部（居中白字标题 + 第二行操作），忽略 [gradientColors]。
  final List<Color>? bannerColors;

  /// 横幅标题前的图标（仅 [bannerColors] 非空时显示）。
  final IconData? titleIcon;

  @override
  Widget build(BuildContext context) {
    final banner = bannerColors;
    if (banner != null) {
      const titleLine = LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0xB3FFFFFF)],
      );
      return _analyticsBorderCard(
        context: context,
        bodyPadding: isExpanded
            ? const EdgeInsets.only(bottom: 12)
            : EdgeInsets.zero,
        child: isExpanded ? child : const SizedBox.shrink(),
        header: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: banner,
            ),
          ),
          child: Column(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Container(
                    width: 28,
                    height: 1,
                    decoration: const BoxDecoration(gradient: titleLine),
                  ),
                  if (titleIcon != null)
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Icon(titleIcon, size: 12, color: Colors.white),
                    ),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: titleLine.colors.reversed.toList(),
                      ),
                    ),
                  ),
                ],
              ).height(24),
              AppControlMetricsScope(
                metrics: AppControlMetricsScope.resolve(
                  context,
                ).copyWith(height: 30, buttonHeight: 30),
                child: Row(
                  spacing: 8,
                  children: [
                    if (onViewAll != null)
                      _rankCardWhiteControl(
                        AppButton.outline(
                          onPressed: onViewAll,
                          config: AppButtonConfig.plain,
                          child: const Text('全部'),
                        ),
                      ),
                    if (actions != null) _rankCardWhiteControl(actions!),
                    const Spacer(),
                    _rankCardWhiteControl(
                      AppButton.outline(
                        onPressed: onToggleExpand,
                        config: AppButtonConfig.plain,
                        child: Text(isExpanded ? '收起' : '展开'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _analyticsBorderCard(
      context: context,
      topGradientColors: gradientColors,
      // 标题栏 52、按钮 30 居中，按钮下余 11；顶部 9 使按钮到表头为 20。
      bodyPadding: isExpanded
          ? const EdgeInsets.fromLTRB(16, 9, 16, 12)
          : EdgeInsets.zero,
      child: isExpanded ? child : const SizedBox.shrink(),
      header: _analyticsCardGradientHeader(
        child: AppControlMetricsScope(
          metrics: AppControlMetricsScope.resolve(
            context,
          ).copyWith(height: 30, buttonHeight: 30),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: AppText.title(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onViewAll != null)
                _rankCardWhiteControl(
                  AppButton.outline(
                    onPressed: onViewAll,
                    config: AppButtonConfig.plain,
                    child: const Text('全部'),
                  ),
                ),
              if (actions != null) _rankCardWhiteControl(actions!),
              _rankCardWhiteControl(
                AppButton.outline(
                  onPressed: onToggleExpand,
                  config: AppButtonConfig.plain,
                  child: Text(isExpanded ? '收起' : '展开'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 待上游回收：建议 `AppMetricCard`（左图标 + 标题/数值/单位）。
Widget _analyticsMetricCard({
  required AnalyticsMetric metric,
  required bool selected,
  required VoidCallback? onPressed,

  /// 无底框大图标（78×78），卡片高 104 时上下内边距收为 13。
  bool plainIcon = false,
}) {
  final accent = metric.accent;
  final fill = selected
      ? metric.fill
      : Color.lerp(metric.fill, const Color(0xFFFFFFFF), 0.7)!;
  final iconBg = accent.withValues(alpha: 0.16);
  final borderColor = selected ? accent : const Color(0x00000000);
  final plainIconColor = selected ? accent : metric.fill;

  return SizedBox(
    height: 104,
    child: GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        shadow: false,
        filled: true,
        fillColor: fill,
        borderWidth: 1,
        borderColor: borderColor,
        borderRadius: BorderRadius.circular(24),
        padding: plainIcon
            ? const EdgeInsets.fromLTRB(24, 13, 16, 13)
            : const EdgeInsets.all(16),
        child: Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  AppText.caption(
                    metric.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 4,
                    children: [
                      Flexible(
                        child: AppText.h1(
                          metric.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 40,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (metric.unit.isNotEmpty)
                        AppText.caption(
                          metric.unit,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF000000),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (plainIcon && metric.iconAsset?.endsWith('.svg') == true)
              SvgPicture.asset(
                metric.iconAsset!,
                key: ValueKey('${metric.key}_${metric.iconAsset}'),
                width: 78,
                height: 78,
                colorFilter: ColorFilter.mode(plainIconColor, BlendMode.srcIn),
              )
            else if (plainIcon && metric.iconAsset != null)
              Image.asset(
                metric.iconAsset!,
                key: ValueKey('${metric.key}_${metric.iconAsset}'),
                width: 78,
                height: 78,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: false,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(metric.icon, size: 40, color: accent),
              )
            else
              AppAvatar.square(
                appearance: AppAvatarAppearance.soft,
                color: accent,
                backgroundColor: iconBg,
                icon: metric.iconAsset != null
                    ? Image.asset(
                        metric.iconAsset!,
                        key: ValueKey('${metric.key}_${metric.iconAsset}'),
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: false,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(metric.icon, size: 24, color: accent),
                      )
                    : Icon(metric.icon, size: 24, color: accent),
                size: 56,
                borderRadius: 16,
              ),
          ],
        ),
      ),
    ),
  );
}

/// 与上刊率分析趋势图一致的悬浮窗样式（白底 + 16 圆角 + floating 阴影）。
AppPointerTooltipStyle _analyticsTrendTooltipStyle(BuildContext context) {
  return AppPointerTooltipStyle(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppTheme.of(context).shadows.resolve(
        context,
        level: AppShadowLevel.floating,
        colorMode: AppShadowColorMode.custom,
        color: ShadcnTheme.of(context).colorScheme.foreground,
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ),
  );
}

/// 数据分析趋势悬停：与上刊率分析同款排版（日期加深、系列名减淡、色点 + 数值）。
class _AnalyticsTrendTooltip extends StatelessWidget {
  const _AnalyticsTrendTooltip({required this.data});

  final AppLineChartTooltipData data;

  static String _valueText(double? y) {
    if (y == null) return '-';
    return y % 1 == 0 ? '${y.toInt()}' : y.toStringAsFixed(1);
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
                _valueText(item.hit.point.y),
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

/// 排行筛选条件（设备 / 订单范围共用，放在顶部 Tab 卡内）：
/// 筛选条件: 全部 / 行政区域 / 媒体位置 / 设备状态类型（订单为订单状态）/ 搜索 / 重置
/// 时间维度: 全部 / 今天 / 近7天 / … / 日期范围。
class _AnalyticsRankFilterCard extends StatelessWidget {
  const _AnalyticsRankFilterCard({required this.controller});

  final AnalyticsController controller;

  static const _labelWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final audioFilter = controller.audioFilterValue;
      final rankDateRange = controller.rankDateRange.value;
      final timePreset = controller.timePreset.value;
      final isOrderScope = controller.scopeIndex.value == 1;
      final filtersAll = controller.isRankSelectFiltersAll;
      return Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              const SizedBox(width: _labelWidth, child: AppText.label('筛选条件:')),
              AppToggleGroup<bool>.single(
                value: filtersAll ? true : null,
                allowEmpty: true,
                mode: AppWidgetGroupMode.plain,
                onChanged: (v) {
                  if (v == true) controller.selectAllRankSelectFilters();
                },
                items: const [
                  AppToggleGroupItem(value: true, child: Text('全部')),
                ],
              ),
              const AppSelectFormField<String>(
                hintText: '行政区域',
                width: 140,
                options: AnalyticsController.regionOptions,
              ),
              const AppSelectFormField<String>(
                hintText: '媒体位置',
                width: 140,
                options: AnalyticsController.mediaLocationOptions,
              ),
              if (isOrderScope)
                AppSelect<int>(
                  hintText: '订单状态类型',
                  minWidth: 160,
                  value: controller.orderStatus.value,
                  options: AnalyticsController.statusOptions,
                  onChanged: controller.setOrderStatus,
                )
              else
                AppSelect<int>(
                  hintText: '设备状态类型',
                  minWidth: 160,
                  value: audioFilter,
                  options: AnalyticsController.audioOptions,
                  onChanged: controller.setIsVolume,
                ),
              AppButton.outline(
                onPressed: controller.searchRankFilters,
                child: const Text('搜索'),
              ),
              AppButton.outline(
                onPressed: controller.resetRankFilters,
                child: const Text('重置'),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              const SizedBox(width: _labelWidth, child: AppText.label('时间维度:')),
              AppToggleGroup<AnalyticsTimePreset>.single(
                value: timePreset,
                allowEmpty: false,
                mode: AppWidgetGroupMode.plain,
                onChanged: controller.selectTimePreset,
                items: const [
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.all,
                    child: Text('全部'),
                  ),
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.today,
                    child: Text('今天'),
                  ),
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.day7,
                    child: Text('近7天'),
                  ),
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.day30,
                    child: Text('近30天'),
                  ),
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.day90,
                    child: Text('近90天'),
                  ),
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.month6,
                    child: Text('近6个月'),
                  ),
                  AppToggleGroupItem(
                    value: AnalyticsTimePreset.year1,
                    child: Text('近1年'),
                  ),
                ],
              ),
              AppDatePicker.range(
                rangeValue: rankDateRange,
                hintText: '选择日期范围',
                onRangeChanged: controller.setRankDateRange,
              ).width(240),
            ],
          ),
        ],
      );
    });
  }
}

/// 打开当前排行完整列表弹窗（按当前 TOP，不切片分页）。
void showAnalyticsRankAllDialog({
  required BuildContext context,
  required String title,
  required List<AnalyticsRankItem> items,
  required String labelHeader,
  required String valueHeader,
  bool showBar = true,
  String Function(double value)? valueFormatter,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(720, initialHeight),
    builder: (dialogContext) => _AnalyticsRankAllDialog(
      title: title,
      items: items,
      labelHeader: labelHeader,
      valueHeader: valueHeader,
      showBar: showBar,
      valueFormatter: valueFormatter,
    ),
  );
}

class _AnalyticsRankAllDialog extends StatelessWidget {
  const _AnalyticsRankAllDialog({
    required this.title,
    required this.items,
    required this.labelHeader,
    required this.valueHeader,
    required this.showBar,
    this.valueFormatter,
  });

  final String title;
  final List<AnalyticsRankItem> items;
  final String labelHeader;
  final String valueHeader;
  final bool showBar;
  final String Function(double value)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return AppCard(
      shadow: false,
      filled: true,
      fillColor: colors.card,
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: AppText.h2(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const AppDialogCloseButton(),
              ],
            ),
          ),
          const AppDivider.horizontal(),
          Expanded(
            child: items.isEmpty
                ? const Center(child: AppEmptyState())
                : showBar
                ? _rankTableAll(
                    context: context,
                    items: items,
                    labelHeader: labelHeader,
                    valueHeader: valueHeader,
                    valueFormatter: valueFormatter,
                  )
                : _orderRankTableAll(
                    context: context,
                    items: items,
                    labelHeader: labelHeader,
                    valueHeader: valueHeader,
                  ),
          ),
        ],
      ),
    );
  }
}

/// 完整排行表（带进度条，可滚动，无分页）。
Widget _rankTableAll({
  required BuildContext context,
  required List<AnalyticsRankItem> items,
  required String labelHeader,
  required String valueHeader,
  String Function(double value)? valueFormatter,
}) {
  final colors = ShadcnTheme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          height: _kRankHeaderHeight,
          padding: _kRankRowPadding,
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            color: _kAnalyticsTableHeaderBackground,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: AppText.caption(
                  '序号',
                  textAlign: TextAlign.center,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: AppText.caption(
                  labelHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: AppText.caption(
                  valueHeader,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(height: _kRankRowGap),
          itemBuilder: (context, i) {
            final item = items[i];
            return SizedBox(
              height: _kRankRowHeight,
              child: _RankItemHoverPreview(
                segments: item.previewSegments,
                valueFormatter: valueFormatter ?? _formatRankValue,
                child: Padding(
                  padding: _kRankRowPadding,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(child: _rankBadge(i + 1)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 160,
                        child: _rankTableLabelText(
                          item.label,
                          colors.foreground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(999),
                          ),
                          child: SizedBox(
                            height: 8,
                            child: LayoutBuilder(
                              builder: (context, constraints) => _rankBarFill(
                                colors: colors,
                                items: items,
                                item: item,
                                maxWidth: constraints.maxWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: AppText.caption(
                          valueFormatter?.call(item.value) ?? item.displayValue,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _kAnalyticsTableTextStyle.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

/// 完整订单排行表（可滚动，无分页）。
Widget _orderRankTableAll({
  required BuildContext context,
  required List<AnalyticsRankItem> items,
  required String labelHeader,
  required String valueHeader,
}) {
  final colors = ShadcnTheme.of(context).colorScheme;
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: AppTable(
      showOuterBorder: false,
      showInternalDividers: false,
      headerHeight: _kOrderTableHeaderHeight,
      rowHeight: _kOrderTableRowHeight,
      headerBackgroundColor: _kAnalyticsTableHeaderBackground,
      columnWidths: const {
        0: FixedColumnWidth(64),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      rows: [
        AppTableHeader(
          cells: [
            AppTableCell(
              child: AppText.caption(
                '序号',
                style: _kAnalyticsTableTextStyle.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
            AppTableCell(
              child: AppText.caption(
                labelHeader,
                style: _kAnalyticsTableTextStyle.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
            AppTableCell(
              alignment: Alignment.centerRight,
              child: AppText.caption(
                valueHeader,
                style: _kAnalyticsTableTextStyle.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        for (var i = 0; i < items.length; i++)
          AppTableRow(
            cells: [
              AppTableCell(child: _rankBadge(i + 1)),
              AppTableCell(
                child: _rankTableLabelText(items[i].label, colors.foreground),
              ),
              AppTableCell(
                alignment: Alignment.centerRight,
                child: AppText.caption(
                  items[i].displayValue,
                  style: _kAnalyticsTableTextStyle.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
