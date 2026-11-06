import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../models/oac_brand.dart';
import '../../models/oac_brand_detail.dart';
import 'brand_detail_controller.dart';
import 'dialogs/add_order_dialog.dart';
import 'dialogs/agency_overview_dialog.dart';
import 'dialogs/order_contacts_dialog.dart';
import 'dialogs/order_sales_dialog.dart';

part 'order_detail_page.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF5F7FA);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE8E8E8);
const _kTitle = Color(0xFF262626);
const _kGold = Color(0xFFD48806);
const _kBanner = Color(0xFF0B3A6E);

class BrandDetailPage extends StatelessWidget {
  const BrandDetailPage({
    super.key,
    required this.brandId,
  });

  final String brandId;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<BrandDetailController>(
          () => BrandDetailController(brandId: brandId),
        );
      },
      // Scope 须包在 _Body 外：弹窗用 State.context，否则找不到 shadcn Theme。
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  BrandDetailController get _c => context.lx.find<BrandDetailController>();

  Future<void> _onAddOrder() async {
    final ok = await showAddOrderDialog(
      context,
      initialBrandId: _c.brandId,
    );
    if (ok && mounted) await _c.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: Obx(() {
        if (c.loading.value && c.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final err = c.errorMessage.value;
        if (err != null && c.detail.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                AppButton.primary(
                  onPressed: c.load,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        final detail = c.detail.value;
        if (detail == null) {
          return const Center(child: Text('暂无数据'));
        }
        final brand = detail.brand;
        // 订阅字典，头部标签中文刷新。
        c.dictVersion.value;
        return Column(
          children: [
            _HeaderBar(
              controller: c,
              brand: brand,
              onBack: () => Navigator.pop(context),
              onAddOrder: _onAddOrder,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                    _MetricRows(controller: c, detail: detail),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _BrandProfileCard(detail: detail)),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: _RelationGraphCard(graph: detail.relationGraph),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ChartCard(
                            title: '订单金额趋势（万元）',
                            child: _TrendChart(items: detail.monthlyTrend),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChartCard(
                            title: '合同类型占比',
                            child: _ContractDonut(counts: c.contractTypeCounts),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChartCard(
                            title: '关系分布',
                            child: _RelationBars(counts: c.relationLabelCounts),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _OrdersCard(controller: c),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _ContactsCard(contacts: detail.contacts),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: _SalesCard(people: c.salesPeople),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DynamicsCard(brand: brand),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MapCard(hq: detail.hqLocation),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NotesCard(remark: brand?.remark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.controller,
    required this.brand,
    required this.onBack,
    required this.onAddOrder,
  });

  final BrandDetailController controller;
  final OacBrand? brand;
  final VoidCallback onBack;
  final VoidCallback onAddOrder;

  Future<void> _onAddContact(BuildContext context) async {
    // 复用订单联系人新增表单（无订单上下文时仅写档案）。
    final stubOrder = OrderItem();
    final saved = await showOrderContactsDialog(
      context,
      controller: controller,
      order: stubOrder,
    );
    if (!saved || !context.mounted) return;
    await controller.load();
    if (!context.mounted) return;
    showHyperToast(context, content: const Text('联系人已添加'));
  }

  String _fmtDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final s = raw.trim();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    final name = brand?.name?.trim().isNotEmpty == true ? brand!.name! : '品牌详情';
    final letter = name.characters.first;
    final weight = brand?.weight ?? 0;
    final iconUrl = brand?.iconUrl?.trim();
    final displayTags = controller.headerDisplayTags(brand);
    final clientTag = controller.clientTagLabel(brand?.clientTag);
    final code = brand?.brandCode?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2F5C), _kBanner, Color(0xFF145A9E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HyperPressable(
                onTap: onBack,
                builder: (context, states, child) => child!,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '返回列表',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '|',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                ),
              ),
              Flexible(
                child: Text(
                  '订单管理 · 品牌 / $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '品牌健康度 · 良好',
                  style: TextStyle(
                    color: Color(0xFFE6F4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAAD14).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFAAD14)),
                ),
                child: const Text(
                  'TOP 5 客户',
                  style: TextStyle(
                    color: Color(0xFFFFD666),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: iconUrl != null && iconUrl.isNotEmpty
                    ? Image.network(
                        iconUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _HeaderAvatar(letter: letter),
                      )
                    : _HeaderAvatar(letter: letter),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < weight
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: const Color(0xFFFAAD14),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '权重 ${weight.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFFB8D4F0),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final t in displayTags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF722ED1)
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFD3ADF7),
                              ),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: Color(0xFFEFDBFF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (code != null && code.isNotEmpty)
                          Text(
                            '品牌编号 $code',
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                        if (clientTag != '-' &&
                            RegExp(r'[\u4e00-\u9fff]').hasMatch(clientTag))
                          Text(
                            '· $clientTag',
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (brand?.spokesperson?.trim().isNotEmpty == true)
                          '最新代言人：${brand!.spokesperson}',
                        if (brand?.ownerNames?.trim().isNotEmpty == true)
                          '负责人：${brand!.ownerNames}',
                        '建档日期 ${_fmtDay(brand?.createTime)}',
                        '最近更新 ${_fmtDay(brand?.updateTime)}',
                      ].join('  ·  '),
                      style: const TextStyle(
                        color: Color(0xFF9EB9D4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AppButton.outline(
                    onPressed: () {},
                    child: const Text(
                      '编辑',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  AppButton.outline(
                    onPressed: () => _onAddContact(context),
                    child: const Text(
                      '添加联系人',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  AppButton.primary(
                    onPressed: onAddOrder,
                    leading: const Icon(Icons.add, size: 16),
                    child: const Text('添加订单'),
                  ),
                  AppButton.outline(
                    onPressed: () {},
                    child: const Text(
                      '导出',
                      style: TextStyle(color: Colors.white),
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

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      color: const Color(0xFF52C41A),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Metrics ──────────────────────────────────────────────────────────────────

class _MetricRows extends StatelessWidget {
  const _MetricRows({required this.controller, required this.detail});

  final BrandDetailController controller;
  final OacBrandDetail detail;

  (int media, int agency) _enterpriseSplit() {
    var media = 0;
    var agency = 0;
    for (final e in detail.enterprises) {
      final t = (e.type ?? '').toLowerCase();
      if (t.contains('代理') || t.contains('agency') || t.contains('4a')) {
        agency++;
      } else {
        media++;
      }
    }
    return (media, agency);
  }

  String _agencySubtitle() {
    final names = [
      for (final a in detail.agencies)
        if (a.name?.trim().isNotEmpty == true) a.name!.trim(),
    ];
    if (names.isEmpty) return '-';
    if (names.length == 1) return names.first;
    return '${names.first}等 ${names.length} 家';
  }

  String _latestOrderTimeText(OacBrand? b) {
    final raw = b?.latestOrderTime?.trim();
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 19 ? raw.substring(0, 19) : raw;
  }

  Future<void> _onAddSales(BuildContext context) async {
    final order = detail.orders.isNotEmpty ? detail.orders.first : OrderItem();
    final saved = await showOrderSalesDialog(
      context,
      controller: controller,
      order: order,
    );
    if (!saved || !context.mounted) return;
    await controller.load();
    if (!context.mounted) return;
    showHyperToast(context, content: const Text('销售员已更新'));
  }

  @override
  Widget build(BuildContext context) {
    final b = detail.brand;
    final latestOrder = detail.orders.isNotEmpty ? detail.orders.first : null;
    final (mediaCnt, agencyCnt) = _enterpriseSplit();
    final subBrandText = detail.subBrands.isEmpty
        ? '-'
        : detail.subBrands.take(4).join('、');
    final sales = b?.ownerNameList ??
        _splitPeople(b?.ownerNames);
    final contactCount = b?.contactCount ?? detail.contacts.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '订单金额（累计）',
                value: _fmtWan(b?.orderAmount),
                valueColor: _kGold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '订单数量',
                value: '${b?.orderCount ?? detail.orders.length}',
                subtitle: '查看订单明细',
                subtitleColor: _kPrimary,
                onTap: () => openBrandOrderDetailPage(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '关联子品牌',
                value: '${detail.subBrands.length}',
                subtitle: subBrandText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '关联企业',
                value: '${b?.enterpriseCount ?? detail.enterprises.length}',
                subtitle: '媒体主 $mediaCnt · 代理方 $agencyCnt',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '关联4A',
                value: '${b?.agencyCount ?? detail.agencies.length}',
                subtitle: _agencySubtitle(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '联系人数量',
                value: '$contactCount 人',
                valueStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
                subtitle:
                    '覆盖 ${detail.enterprises.length} 家企业 / ${detail.agencies.length} 家4A',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '最新订单时间',
                value: _latestOrderTimeText(b),
                valueStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
                subtitle: latestOrder == null
                    ? null
                    : '${latestOrder.name ?? '-'} · ${_fmtWan(latestOrder.amount)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '合作媒体形式',
                valueWidget: detail.mediaFormats.isEmpty
                    ? const Text(
                        '暂无媒体形式数据',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kMuted,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final m in detail.mediaFormats)
                            AppBadge.primary(
                              shape: AppBadgeShape.square,
                              child: Text(
                                '${m.name ?? '-'} ${m.percent ?? 0}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '销售员',
                valueWidget: Row(
                  children: [
                    if (sales.isNotEmpty)
                      _Avatar(name: sales.first, size: 28)
                    else
                      const _Avatar(name: '?', size: 28),
                    const SizedBox(width: 8),
                    _orderAddChip(
                      label: '+',
                      onTap: () => _onAddSales(context),
                    ),
                  ],
                ),
                subtitle: sales.isEmpty
                    ? '暂无销售员'
                    : '主销售：${sales.first}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    this.value,
    this.valueWidget,
    this.subtitle,
    this.subtitleColor,
    this.valueColor,
    this.valueStyle,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? subtitle;
  final Color? subtitleColor;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: valueWidget ??
                  Text(
                    value ?? '-',
                    style: valueStyle ??
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? _kTitle,
                          height: 1.1,
                        ),
                  ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? _kMuted,
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return card;
    return HyperPressable(
      onTap: onTap,
      builder: (context, states, child) => child!,
      child: card,
    );
  }
}

// ── Profile / Graph ──────────────────────────────────────────────────────────

class _BrandProfileCard extends StatelessWidget {
  const _BrandProfileCard({required this.detail});

  final OacBrandDetail detail;

  @override
  Widget build(BuildContext context) {
    final b = detail.brand;
    final tags = [
      ...?b?.tagList,
      if (b?.clientTag != null) b!.clientTag!,
    ].where((e) => e.trim().isNotEmpty).toSet().toList();

    return _SectionCard(
      title: '品牌画像',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow(label: '所属行业', value: b?.industry ?? '-'),
          _ProfileRow(label: '品牌归属', value: b?.clientTag ?? '-'),
          _ProfileRow(
            label: '标签',
            valueWidget: tags.isEmpty
                ? const Text('-')
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final t in tags)
                        AppBadge.secondary(
                          appearance: AppBadgeStyle.soft,
                          shape: AppBadgeShape.square,
                          child: Text(t, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
          ),
          _ProfileRow(
            label: '代言人',
            value: b?.spokesperson ?? '-',
            icon: Icons.person_outline,
          ),
          _ProfileRow(label: '主市场', value: b?.city ?? '-'),
          _ProfileRow(
            label: '投放偏好',
            value: detail.mediaFormats.isEmpty
                ? '-'
                : detail.mediaFormats.map((e) => e.name).join('、'),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                '子品牌',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              AppButton.ghost(
                onPressed: () {},
                leading: const Icon(Icons.add, size: 14),
                child: const Text('添加'),
              ),
            ],
          ),
          if (detail.subBrands.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('暂无子品牌', style: TextStyle(color: _kMuted, fontSize: 13)),
            )
          else
            Wrap(
              spacing: 8,
              children: [
                for (final s in detail.subBrands)
                  AppBadge.outline(
                    child: Text(s),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          if (icon != null) ...[
            Icon(icon, size: 14, color: _kMuted),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '-',
                  style: const TextStyle(fontSize: 13, color: _kTitle),
                ),
          ),
        ],
      ),
    );
  }
}

class _RelationGraphCard extends StatelessWidget {
  const _RelationGraphCard({required this.graph});

  final RelationGraph? graph;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '品牌关系网络图谱',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: _kPrimary, label: '品牌'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFF13C2C2), label: '企业'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFFFA8C16), label: '4A'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFFEB2F96), label: '联系人'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFF52C41A), label: '销售'),
        ],
      ),
      child: SizedBox(
        height: 280,
        child: graph == null || graph!.nodes.isEmpty
            ? const Center(child: Text('暂无关系数据', style: TextStyle(color: _kMuted)))
            : CustomPaint(
                painter: _RelationGraphPainter(graph!),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _kMuted)),
      ],
    );
  }
}

class _RelationGraphPainter extends CustomPainter {
  _RelationGraphPainter(this.graph);

  final RelationGraph graph;

  Color _color(String? category) {
    return switch (category) {
      'brand' => _kPrimary,
      'enterprise' => const Color(0xFF13C2C2),
      'agency' => const Color(0xFFFA8C16),
      'contact' => const Color(0xFFEB2F96),
      'salesperson' => const Color(0xFF52C41A),
      _ => _kMuted,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nodes = graph.nodes;
    RelationNode? brand;
    for (final n in nodes) {
      if (n.category == 'brand') {
        brand = n;
        break;
      }
    }
    brand ??= nodes.isEmpty ? null : nodes.first;
    final others = nodes.where((n) => n.id != brand?.id).toList();
    final positions = <String, Offset>{};
    if (brand?.id != null) positions[brand!.id!] = center;

    final radius = math.min(size.width, size.height) * 0.34;
    for (var i = 0; i < others.length; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / math.max(others.length, 1));
      final id = others[i].id;
      if (id == null) continue;
      positions[id] = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFFD0D7DE)
      ..strokeWidth = 1;
    for (final link in graph.links) {
      final a = positions[link.source];
      final b = positions[link.target];
      if (a == null || b == null) continue;
      canvas.drawLine(a, b, linePaint);
    }

    for (final node in nodes) {
      final id = node.id;
      if (id == null) continue;
      final pos = positions[id];
      if (pos == null) continue;
      final isBrand = node.category == 'brand';
      final r = isBrand ? 28.0 : 22.0;
      final paint = Paint()..color = _color(node.category);
      canvas.drawCircle(pos, r, paint);
      final tp = TextPainter(
        text: TextSpan(
          text: _shortName(node.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: isBrand ? 12 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: r * 2 - 4);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  String _shortName(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    return n.length <= 4 ? n : n.substring(0, 4);
  }

  @override
  bool shouldRepaint(covariant _RelationGraphPainter oldDelegate) =>
      oldDelegate.graph != graph;
}

// ── Charts ───────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: SizedBox(height: 220, child: child),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.items});

  final List<MonthAmountItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无趋势数据', style: TextStyle(color: _kMuted)));
    }
    return AppLineChart(
      showLegend: false,
      height: 220,
      series: [
        AppLineSeries(
          name: '订单金额',
          points: [
            for (var i = 0; i < items.length; i++)
              AppLinePoint(
                x: i.toDouble(),
                y: num.tryParse(items[i].amount ?? '')?.toDouble() ?? 0,
                label: items[i].month ?? '$i',
              ),
          ],
        ),
      ],
      yAxis: AppChartAxis(formatter: (v) => v.toStringAsFixed(0)),
    );
  }
}

class _ContractDonut extends StatelessWidget {
  const _ContractDonut({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(child: Text('暂无合同数据', style: TextStyle(color: _kMuted)));
    }
    return AppPieChart.donut(
      height: 220,
      showValues: true,
      sections: [
        for (final e in counts.entries)
          AppPieSection(label: e.key, value: e.value.toDouble()),
      ],
    );
  }
}

class _RelationBars extends StatelessWidget {
  const _RelationBars({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(child: Text('暂无关系数据', style: TextStyle(color: _kMuted)));
    }
    final entries = counts.entries.toList();
    return AppBarChart.horizontal(
      height: 220,
      showLegend: false,
      showValues: true,
      groups: [
        for (final e in entries)
          AppBarGroup(
            label: e.key,
            values: [AppBarValue(value: e.value.toDouble())],
          ),
      ],
    );
  }
}

// ── Orders ───────────────────────────────────────────────────────────────────

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.controller});

  final BrandDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = controller.filteredOrders;
      final total = controller.detail.value?.orders.length ?? 0;
      final brand = controller.detail.value?.brand;
      // 读字典版本，标签映射变更时刷新表格。
      controller.dictVersion.value;
      var shownAmount = 0.0;
      for (final o in orders) {
        shownAmount += num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrdersHeader(
              controller: controller,
              shown: orders.length,
              total: total,
              amountText: _fmtWan('$shownAmount'),
              onViewAll: () => openBrandOrderDetailPage(context),
            ),
            const SizedBox(height: 12),
            _OrdersGrid(
              controller: controller,
              orders: orders,
              brand: brand,
              height: math.min(80.0 + math.max(orders.length, 1) * 56, 320),
            ),
          ],
        ),
      );
    });
  }
}

/// 标题行：左「订单明细 + 近期汇总」，右「筛选 + 全部 N 笔」。
class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.controller,
    required this.shown,
    required this.total,
    required this.amountText,
    required this.onViewAll,
  });

  final BrandDetailController controller;
  final int shown;
  final int total;
  final String amountText;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.receipt_long,
            size: 14,
            color: Color(0xFF52C41A),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '订单明细',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '近期 $shown 笔 · 金额合计 $amountText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _kMuted),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 200,
          child: TextField(
            controller: controller.orderKeywordCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: '筛选订单号 / 标签',
              hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
              prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        HyperPressable(
          onTap: onViewAll,
          builder: (context, states, child) => child!,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '全部 $total 笔',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF52C41A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF52C41A),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersGrid extends StatelessWidget {
  const _OrdersGrid({
    required this.controller,
    required this.orders,
    required this.brand,
    required this.height,
    this.withTime = false,
    this.indexOffset = 0,
  });

  final BrandDetailController controller;
  final List<OrderItem> orders;
  final OacBrand? brand;
  final double height;
  final bool withTime;
  final int indexOffset;

  List<String> get _brandTags {
    // 仅用 tagList（如 listed_company）；不带 clientTag（international）。
    final raw = <String>[...?brand?.tagList];
    final seen = <String>{};
    final out = <String>[];
    for (final t in raw) {
      final key = t.trim();
      if (key.isEmpty) continue;
      final label = controller.tagLabel(key);
      // 与订单管理一致：不展示纯英文标签。
      if (label == '-' || !_isDisplayableTag(label) || !seen.add(label)) {
        continue;
      }
      out.add(label);
    }
    return out;
  }

  String get _salesFallback {
    final list = brand?.ownerNameList;
    if (list != null && list.isNotEmpty) return list.first;
    return brand?.ownerNames?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('暂无订单', style: TextStyle(color: _kMuted)),
        ),
      );
    }
    final brandTags = _brandTags;
    final brandName = brand?.name?.trim().isNotEmpty == true
        ? brand!.name!.trim()
        : '-';
    String rowBrandName(OrderItem row) {
      final own = row.brandName?.trim();
      if (own != null && own.isNotEmpty) return own;
      return brandName;
    }
    final weight = brand?.weight;
    final iconUrl = brand?.iconUrl?.trim();
    final letter = brandName.characters.first;

    return SizedBox(
      width: double.infinity,
      child: AppDataGrid<OrderItem>.local(
        height: height,
        rows: orders,
        rowKey: (row) => row.id ?? row.orderNo ?? row.name ?? '',
        sortable: false,
        showInternalDividers: false,
        headerBackgroundColor: const Color(0xFFFAFAFA),
        columns: [
          AppDataGridColumn(
            id: 'index',
            title: '序号',
            width: 52,
            value: (row) => '${indexOffset + orders.indexOf(row) + 1}',
          ),
          AppDataGridColumn(
            id: 'weight',
            title: '权重',
            width: 110,
            value: (row) => '${weight ?? 0}',
            cellBuilder: (context, row, _) {
              final score = (weight ?? 0).clamp(0, 5);
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < score
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: i < score
                            ? const Color(0xFFFAAD14)
                            : const Color(0xFFD9D9D9),
                      ),
                  ],
                ),
              );
            },
          ),
          AppDataGridColumn(
            id: 'icon',
            title: '图标',
            width: 56,
            value: (row) => iconUrl ?? brandName,
            cellBuilder: (context, row, _) {
              if (iconUrl != null && iconUrl.isNotEmpty) {
                return Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      iconUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _Avatar(name: brandName, size: 28),
                    ),
                  ),
                );
              }
              return Center(child: _Avatar(name: letter, size: 28));
            },
          ),
          AppDataGridColumn(
            id: 'brandName',
            title: '品牌名称',
            width: 120,
            minWidth: 88,
            widthMode: AppDataGridColumnWidthMode.fill,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: rowBrandName,
            cellBuilder: (context, row, _) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                rowBrandName(row),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          AppDataGridColumn(
            id: 'tags',
            title: '标签',
            width: 168,
            minWidth: 120,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 1.2,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => brandTags.join(','),
            cellBuilder: (context, row, _) {
              if (brandTags.isEmpty) return const Text('-');
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in brandTags)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AppBadge.custom(
                          color: const Color(0xFF722ED1),
                          appearance: AppBadgeStyle.soft,
                          shape: AppBadgeShape.square,
                          child: Text(t, style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          AppDataGridColumn(
            id: 'enterprise',
            title: '关联企业',
            width: 160,
            minWidth: 120,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 1.3,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => row.enterprise ?? '-',
            cellBuilder: (context, row, _) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                row.enterprise?.trim().isNotEmpty == true
                    ? row.enterprise!.trim()
                    : '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          AppDataGridColumn(
            id: 'relation',
            title: '关联关系',
            width: 100,
            value: (row) => controller.relationLabel(row.relation),
          ),
          AppDataGridColumn(
            id: 'agency',
            title: '关联4A',
            width: 180,
            minWidth: 140,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 1.4,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => row.agencyName ?? row.agencyId ?? '',
            cellBuilder: (context, row, _) => _OrderAgencyLink(order: row),
          ),
          AppDataGridColumn(
            id: 'contract',
            title: '合同类型',
            width: 100,
            value: (row) => controller.contractTypeLabel(row.contractType),
            cellBuilder: (context, row, _) {
              final label = controller.contractTypeLabel(row.contractType);
              if (label == '-') return const Text('-');
              return Center(
                child: AppBadge.custom(
                  color: const Color(0xFF1677FF),
                  appearance: AppBadgeStyle.soft,
                  shape: AppBadgeShape.square,
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
          AppDataGridColumn(
            id: 'amount',
            title: '订单金额',
            width: 100,
            value: (row) => _fmtWan(row.amount),
            cellBuilder: (context, row, _) => Text(
              _fmtWan(row.amount),
              style: const TextStyle(
                color: _kGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppDataGridColumn(
            id: 'time',
            title: '订单时间',
            width: 110,
            value: (row) => _fmtOrderTime(row.orderTime, withTime: withTime),
          ),
          AppDataGridColumn(
            id: 'contact',
            title: '联系人',
            width: 180,
            minWidth: 140,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 1.4,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => row.contact ?? '-',
            cellBuilder: (context, row, _) => _OrderContactsCell(
              controller: controller,
              order: row,
            ),
          ),
          AppDataGridColumn(
            id: 'sales',
            title: '销售员',
            width: 120,
            minWidth: 96,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 0.9,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) {
              final s = row.salesPerson?.trim();
              if (s != null && s.isNotEmpty) return s;
              final fb = _salesFallback;
              return fb.isEmpty ? '-' : fb;
            },
            cellBuilder: (context, row, _) => _OrderSalesCell(
              controller: controller,
              order: row,
              fallback: _salesFallback,
            ),
          ),
          AppDataGridColumn(
            id: 'remark',
            title: '备注',
            width: 120,
            minWidth: 96,
            widthMode: AppDataGridColumnWidthMode.fill,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => row.remark?.trim().isNotEmpty == true
                ? row.remark!.trim()
                : '-',
          ),
          AppDataGridColumn(
            id: 'actions',
            title: '操作',
            width: 64,
            widthMode: AppDataGridColumnWidthMode.fixed,
            pin: AppDataGridColumnPin.end,
            value: (_) => '',
            cellBuilder: (context, row, _) => Center(
              child: HyperPressable(
                onTap: () {
                  showHyperToast(
                    context,
                    content: const Text('订单编辑暂未开放'),
                  );
                },
                builder: (context, states, child) => child!,
                child: const Text(
                  '编辑',
                  softWrap: false,
                  maxLines: 1,
                  style: TextStyle(
                    color: Color(0xFF52C41A),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 蓝色「+ / +N」添加按钮（联系人、销售员共用）。
Widget _orderAddChip({required String label, required VoidCallback onTap}) {
  return HyperPressable(
    onTap: onTap,
    builder: (context, states, child) => child!,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFECF5FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF409EFF),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

List<String> _splitPeople(String? raw) => (raw ?? '')
    .split(RegExp(r'[,，;；、/|]+'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// 联系人：`[+N] 名1 · 名2 [+]`——溢出在前，末尾固定添加。
class _OrderContactsCell extends StatelessWidget {
  const _OrderContactsCell({
    required this.controller,
    required this.order,
  });

  final BrandDetailController controller;
  final OrderItem order;

  Future<void> _openAdd(BuildContext context) async {
    final saved = await showOrderContactsDialog(
      context,
      controller: controller,
      order: order,
    );
    if (!saved || !context.mounted) return;
    showHyperToast(context, content: const Text('联系人已更新'));
  }

  @override
  Widget build(BuildContext context) {
    final parts = _splitPeople(order.contact);
    final visible = parts.take(2).toList();
    final more = parts.length - visible.length;
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (more > 0) ...[
              _orderAddChip(label: '+$more', onTap: () => _openAdd(context)),
              const SizedBox(width: 6),
            ],
            if (visible.isNotEmpty) ...[
              Text(
                visible.join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF52C41A),
                ),
              ),
              const SizedBox(width: 6),
            ],
            _orderAddChip(label: '+', onTap: () => _openAdd(context)),
          ],
        ),
      ),
    );
  }
}

/// 销售员：`[+N] 名1 · 名2 [+]`——溢出在前，末尾固定添加。
class _OrderSalesCell extends StatelessWidget {
  const _OrderSalesCell({
    required this.controller,
    required this.order,
    required this.fallback,
  });

  final BrandDetailController controller;
  final OrderItem order;
  final String fallback;

  Future<void> _openAdd(BuildContext context) async {
    final saved = await showOrderSalesDialog(
      context,
      controller: controller,
      order: order,
    );
    if (!saved || !context.mounted) return;
    showHyperToast(context, content: const Text('销售员已更新'));
  }

  @override
  Widget build(BuildContext context) {
    var parts = _splitPeople(order.salesPerson);
    if (parts.isEmpty) parts = _splitPeople(fallback);
    final visible = parts.take(2).toList();
    final more = parts.length - visible.length;
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (more > 0) ...[
              _orderAddChip(label: '+$more', onTap: () => _openAdd(context)),
              const SizedBox(width: 6),
            ],
            if (visible.isNotEmpty) ...[
              Text(
                visible.join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
            ],
            _orderAddChip(label: '+', onTap: () => _openAdd(context)),
          ],
        ),
      ),
    );
  }
}

/// 订单行「关联4A」：蓝色可点，打开主体概览（`GET /desktop/oac/customer/{id}`）。
class _OrderAgencyLink extends StatelessWidget {
  const _OrderAgencyLink({required this.order});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    final id = order.agencyId?.trim() ?? '';
    final name = order.agencyName?.trim() ?? '';
    final label = name.isNotEmpty ? name : id;
    if (label.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('-', style: TextStyle(fontSize: 12)),
      );
    }
    if (id.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: HyperPressable(
        onTap: () => showAgencyOverviewDialog(
          context,
          customerId: id,
        ),
        builder: (context, states, child) => child!,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
            style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF52C41A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Contacts / Sales ─────────────────────────────────────────────────────────

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.contacts});

  final List<ContactItem> contacts;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '联系人 共 ${contacts.length} 人',
      trailing: AppButton.ghost(
        onPressed: () {},
        leading: const Icon(Icons.add, size: 14),
        child: const Text('添加联系人'),
      ),
      child: contacts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('暂无联系人', style: TextStyle(color: _kMuted)),
              ),
            )
          : Column(
              children: [
                for (final c in contacts)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFBFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      children: [
                        _Avatar(name: c.name ?? '?', size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: c.name ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _kTitle,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: [
                                        if (c.orgName?.trim().isNotEmpty == true)
                                          ' · ${c.orgName}',
                                        if (c.title?.trim().isNotEmpty == true)
                                          ' · ${c.title}',
                                      ].join(),
                                      style: const TextStyle(
                                        color: _kMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (c.phone?.trim().isNotEmpty == true) ...[
                                    const Icon(Icons.phone_outlined,
                                        size: 14, color: _kMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.phone!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (c.email?.trim().isNotEmpty == true) ...[
                                    const Icon(Icons.mail_outline,
                                        size: 14, color: _kMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.email!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.people});

  final List<SalesPersonView> people;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '销售员',
      trailing: AppButton.ghost(
        onPressed: () {},
        leading: const Icon(Icons.add, size: 14),
        child: const Text('添加'),
      ),
      child: people.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('暂无销售员', style: TextStyle(color: _kMuted)),
              ),
            )
          : Column(
              children: [
                for (final p in people)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        _Avatar(name: p.name, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppBadge.custom(
                                    color: p.role.contains('负责')
                                        ? _kPrimary
                                        : const Color(0xFF52C41A),
                                    appearance: AppBadgeStyle.soft,
                                    shape: AppBadgeShape.square,
                                    child: Text(
                                      p.role.contains('负责') ? '主推销' : '协同销售',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${p.role} · 协同团队',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Dynamics / Map / Notes ───────────────────────────────────────────────────

class _DynamicsCard extends StatelessWidget {
  const _DynamicsCard({required this.brand});

  final OacBrand? brand;

  @override
  Widget build(BuildContext context) {
    final text = brand?.latestDynamic?.trim();
    final time = brand?.updateTime ?? brand?.createTime ?? '';
    return _SectionCard(
      title: '最新动态 · AI 简报',
      child: text == null || text.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('暂无动态', style: TextStyle(color: _kMuted)),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$time · 来源：系统动态',
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '动态：$text',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.hq});

  final HqLocation? hq;

  @override
  Widget build(BuildContext context) {
    final name = hq?.name ?? '总部';
    final address = hq?.address;
    return _SectionCard(
      title: '总部办公地图',
      child: Column(
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F3FF), Color(0xFFD6EAF8), Color(0xFFBFD8F0)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 64, color: Color(0xFF91B8E0)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.location_on, color: _kPrimary, size: 32),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  onPressed: () async {
                    final text = [
                      name,
                      if (address != null && address != '-') address,
                      if (hq?.lng != null && hq?.lat != null)
                        '${hq!.lng},${hq!.lat}',
                    ].join(' ');
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('地址已复制')),
                      );
                    }
                  },
                  child: const Text('复制地址'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.outline(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('地图导航待接入')),
                    );
                  },
                  child: const Text('导航到这'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.remark});

  final String? remark;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '备注与附件',
      trailing: AppButton.ghost(
        onPressed: () {},
        child: const Text('编辑'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFE58F)),
            ),
            child: Text(
              (remark == null || remark!.trim().isEmpty) ? '暂无备注' : remark!,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 18, color: _kMuted),
              SizedBox(width: 8),
              Text('暂无附件', style: TextStyle(color: _kMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton.link(
              onPressed: () {},
              child: const Text('+ 上传附件'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first;
    final colors = [
      const Color(0xFF722ED1),
      const Color(0xFFEB2F96),
      const Color(0xFF52C41A),
      const Color(0xFF1677FF),
      const Color(0xFFFA8C16),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// 品牌标签不展示纯英文（如 international）。
bool _isDisplayableTag(String tag) {
  final t = tag.trim();
  if (t.isEmpty) return false;
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(t);
}

String _fmtWan(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final n = num.tryParse(raw.trim());
  if (n == null) return raw.startsWith('¥') ? raw : '¥$raw';
  // 接口返回已是「万」；展示固定带万。
  if (n.abs() < 0.005) return '¥0万';
  final text =
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  return '¥$text万';
}

String _fmtDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final s = raw.trim();
  return s.length >= 10 ? s.substring(0, 10) : s;
}

DateTime? _parseOrderTime(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

String _fmtOrderTime(String? raw, {required bool withTime}) {
  final d = _parseOrderTime(raw);
  if (d == null) return _fmtDate(raw);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  if (!withTime) return '$y.$m.$day';
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}

void openBrandOrderDetailPage(BuildContext context) {
  final controller = context.lx.find<BrandDetailController>();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LxScope(
        bindings: (container) {
          container.putInstance<BrandDetailController>(
            controller,
            owned: false,
          );
        },
        child: AppShadcnScope(
          config: AppThemeConfig.standard(primary: _kPrimary),
          child: const BrandOrderDetailPage(),
        ),
      ),
    ),
  );
}
