import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../models/oac_brand_detail.dart';
import '../../models/oac_person.dart';
import '../brand_detail/dialogs/add_order_dialog.dart';
import '../customer_archive/detail/dialogs/contact_edit_dialog.dart';
import '../customer_archive/dialogs/quick_create_brand_dialog.dart';
import '../office_map_dialog.dart';
import 'person_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF5F7FA);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE8E8E8);
const _kTitle = Color(0xFF262626);
const _kGold = Color(0xFFD48806);
const _kBanner = Color(0xFF0B3A6E);
const _kTrendUp = Color(0xFF52C41A);

class PersonDetailPage extends StatelessWidget {
  const PersonDetailPage({
    super.key,
    required this.contactId,
    this.personSeed,
  });

  final String contactId;
  final OacPerson? personSeed;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<PersonDetailController>(
          () => PersonDetailController(
            contactId: contactId,
            personSeed: personSeed,
          ),
        );
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  PersonDetailController _c(BuildContext context) =>
      context.lx.find<PersonDetailController>();

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Obx(() {
        c.personVersion.value;
        if (c.loading.value && c.contactRaw.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final err = c.errorMessage.value;
        if (err != null && c.contactRaw.value == null) {
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
        return Column(
          children: [
            _Header(controller: c),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _MetricRows(controller: c),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _PortraitCard(controller: c),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: _RelationGraphCard(
                          graph: c.buildRelationGraph(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ChartCard(
                          title: '参与订单金额趋势（万元）',
                          child: _TrendChart(items: c.monthlyTrend.toList()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChartCard(
                          title: '参与订单构成',
                          // 环形图例在饼图上方，固定 220 易底部溢出。
                          height: 260,
                          child: _ContractDonut(counts: c.contractTypeCounts),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChartCard(
                          title: '合作主体分布',
                          child: _RelationBars(counts: c.enterpriseOrderCounts),
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
                      Expanded(child: _CoworkersCard(controller: c)),
                      const SizedBox(width: 12),
                      Expanded(child: _DynamicsCard(controller: c)),
                      const SizedBox(width: 12),
                      Expanded(child: _MapCard(controller: c)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _SalesCard(controller: c),
                            const SizedBox(height: 12),
                            _NotesCard(remark: c.remark),
                          ],
                        ),
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

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final PersonDetailController controller;

  Future<void> _onAddColleague(
    BuildContext context,
    PersonDetailController c,
  ) async {
    final customerId = c.customerId?.trim();
    if (customerId == null || customerId.isEmpty) {
      showHyperToast(context, content: const Text('未找到所属客户档案，无法添加同事'));
      return;
    }
    await showEditCustomerArchiveDialog(
      context,
      customerId: customerId,
      contactsOnly: true,
      title: '添加同事',
      onSaved: () {
        c.load();
      },
    );
  }

  Future<void> _onEdit(
    BuildContext context,
    PersonDetailController c,
  ) async {
    final raw = c.contact;
    if (raw == null) {
      showHyperToast(context, content: const Text('联系人数据未加载'));
      return;
    }
    final customerId = c.customerId?.trim() ?? '';
    if (customerId.isEmpty) {
      showHyperToast(context, content: const Text('未找到所属客户档案，无法编辑'));
      return;
    }
    final contact = Map<String, dynamic>.from(raw);
    final id = contact['id']?.toString().trim() ?? '';
    if (id.isEmpty) contact['id'] = c.contactId;
    contact['customerId'] = customerId;
    final saved = await showContactEditDialog(context, contact: contact);
    if (saved && context.mounted) await c.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final name = c.displayName;
    final letter = name == '-'
        ? '?'
        : String.fromCharCodes(name.runes.take(1));
    final location = [
      if (c.city != '-') c.city,
      if (c.address != '-') c.address,
    ].join(' · ');

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
                onTap: () => Navigator.pop(context),
                builder: (context, states, child) => child!,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '返回人员列表',
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
                  '观察视角：人 > 人一级列表 > $name',
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
                  color: const Color(0xFF52C41A).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF95DE64)),
                ),
                child: Text(
                  '影响力评分 ${c.influenceScore}',
                  style: const TextStyle(
                    color: Color(0xFFD9F7BE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (c.keyDecisionMaker) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52C41A).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF95DE64)),
                  ),
                  child: const Text(
                    '关键决策人',
                    style: TextStyle(
                      color: Color(0xFFD9F7BE),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF52C41A),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
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
                        if (c.realNameVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '实名认证',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          c.personCode,
                          style: const TextStyle(
                            color: Color(0xFFB8D4F0),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (c.employer != '-')
                          _HeaderChip(c.employer, green: true),
                        if (c.title != '-') _HeaderChip(c.title),
                        if (c.enterpriseType != '-')
                          _HeaderChip(c.enterpriseType),
                        if (c.jobDesc != '-') _HeaderChip(c.jobDesc),
                      ],
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        location,
                        style: const TextStyle(
                          color: Color(0xFF9EB9D4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (c.phone != '-') '电话 ${c.phone}',
                        if (c.email != '-') '邮箱 ${c.email}',
                        if (c.ownerNames != '-') '负责销售：${c.ownerNames}',
                      ].join('  ·  '),
                      style: const TextStyle(
                        color: Color(0xFF9EB9D4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  AppButton.outline(
                    onPressed: () => _onEdit(context, c),
                    child: const Text(
                      '编辑',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  AppButton.primary(
                    onPressed: () async {
                      await showAddOrderDialog(context);
                    },
                    child: const Text('+ 添加订单'),
                  ),
                  AppButton.outline(
                    onPressed: () => _onAddColleague(context, c),
                    child:
                        const Text('添加同事', style: TextStyle(color: Colors.white)),
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip(this.text, {this.green = false});

  final String text;
  final bool green;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: green
            ? const Color(0xFF52C41A).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: green ? const Color(0xFFB7EB8F) : Colors.white24,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: green ? const Color(0xFFD9F7BE) : const Color(0xFFE6F4FF),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetricRows extends StatelessWidget {
  const _MetricRows({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final yoy = c.orderAmountYoyRate;
    final latest = c.latestOrder;
    final sales = c.ownerNames
        .split(RegExp(r'[,，;；、/|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != '-')
        .toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '累计订单金额',
                value: _fmtWan(c.orderAmount),
                valueColor: _kGold,
                subtitleWidget: yoy == null || yoy.isEmpty
                    ? null
                    : Text(
                        '同比 ${yoy.startsWith('-') ? '' : '+'}$yoy%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTrendUp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '参与订单数',
                value: '${c.orderCount}',
                subtitle: '查看订单明细',
                subtitleColor: _kPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '关联品牌',
                value: '${c.brandCount}',
                subtitle: c.brandNames.isEmpty
                    ? c.brandIndustrySummary
                    : c.brandNames.join('、'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '关联企业',
                value: '${c.enterpriseCount}',
                subtitle: c.employer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '同企业联系人',
                value: '${c.sameEnterpriseContactCount}',
                subtitle: c.employer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '最新订单时间',
                value: _fmtDateTime(c.latestOrderTime),
                valueStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
                subtitle: latest == null
                    ? null
                    : '${latest.name ?? '-'} · ${_fmtWan(latest.amount)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '偏好媒体形式',
                value: '暂无媒体形式数据',
                valueStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '沟通与跟进',
                valueWidget: Text(
                  '参与订单 ${c.orderCount} · 关联品牌 ${c.brandCount} · 关联4A ${c.agencyCount}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '销售员',
                valueWidget: Row(
                  children: [
                    _Avatar(name: sales.isNotEmpty ? sales.first : '?', size: 28),
                    const SizedBox(width: 8),
                    Text(
                      sales.isEmpty ? '暂无销售员' : '主跟进：${sales.first}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '关联4A',
                value: '${c.agencyCount}',
                subtitle: c.agencyNames.isEmpty
                    ? '-'
                    : c.agencyNames.take(2).join('、'),
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
    this.subtitleWidget,
    this.subtitleColor,
    this.valueColor,
    this.valueStyle,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Color? subtitleColor;
  final Color? valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? _kTitle,
                          height: 1.1,
                        ),
                  ),
            ),
          ),
          if (subtitleWidget != null)
            subtitleWidget!
          else if (subtitle != null)
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
  }
}

class _PortraitCard extends StatelessWidget {
  const _PortraitCard({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final tags = <String>[
      if (c.enterpriseType != '-') c.enterpriseType,
      '经营主体',
      ...c.brandNames,
    ];
    return _SectionCard(
      title: '联系人画像',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow(label: '就职企业', value: c.employer),
          _ProfileRow(label: '企业类型', value: c.enterpriseType),
          _ProfileRow(label: '职位', value: c.title),
          _ProfileRow(label: '职能描述', value: c.jobDesc),
          _ProfileRow(label: '负责区域', value: c.marketScope),
          _ProfileRow(label: '负责品牌', value: c.responsibleBrands),
          _ProfileRow(label: '档案时间', value: c.archivePeriod),
          const SizedBox(height: 8),
          Wrap(
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
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  final RelationGraph graph;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '关系网络图谱',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: _kPrimary, label: '人'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFF52C41A), label: '品牌'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFF595959), label: '企业'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFFFA8C16), label: '4A'),
          SizedBox(width: 10),
          _LegendDot(color: Color(0xFF13C2C2), label: '销售'),
        ],
      ),
      child: SizedBox(
        height: 280,
        child: graph.nodes.isEmpty
            ? const Center(
                child: Text('暂无关系数据', style: TextStyle(color: _kMuted)),
              )
            : CustomPaint(
                painter: _PersonGraphPainter(graph),
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
      mainAxisSize: MainAxisSize.min,
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

class _PersonGraphPainter extends CustomPainter {
  _PersonGraphPainter(this.graph);

  final RelationGraph graph;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = graph.nodes;
    if (nodes.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;
    final positions = <String, Offset>{};
    final others = [
      for (final n in nodes)
        if (n.id != 'person' && n.id != null) n,
    ];
    positions['person'] = center;
    for (var i = 0; i < others.length; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / others.length);
      positions[others[i].id!] = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    }
    final linePaint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 1.2;
    for (final link in graph.links) {
      final a = positions[link.source];
      final b = positions[link.target];
      if (a == null || b == null) continue;
      canvas.drawLine(a, b, linePaint);
    }
    for (final n in nodes) {
      final id = n.id;
      if (id == null) continue;
      final p = positions[id];
      if (p == null) continue;
      final color = switch (n.category) {
        'brand' => const Color(0xFF52C41A),
        'enterprise' => const Color(0xFF595959),
        'agency' => const Color(0xFFFA8C16),
        'salesperson' => const Color(0xFF13C2C2),
        _ => _kPrimary,
      };
      final r = id == 'person' ? 28.0 : 20.0;
      canvas.drawCircle(p, r, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(
          text: n.name ?? '',
          style: TextStyle(
            color: Colors.white,
            fontSize: id == 'person' ? 12 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: r * 2.2);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _PersonGraphPainter oldDelegate) =>
      oldDelegate.graph != graph;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.height = 220,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: SizedBox(height: height, child: child),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.items});

  final List<MonthAmountItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('暂无趋势数据', style: TextStyle(color: _kMuted)),
      );
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
      return const Center(
        child: Text('暂无合同数据', style: TextStyle(color: _kMuted)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return AppPieChart.donut(
          // 吃满卡片内高度；图例+饼图同处一列，勿再写死 220。
          height: h.isFinite && h > 0 ? h : 260,
          showValues: true,
          sections: [
            for (final e in counts.entries)
              AppPieSection(label: e.key, value: e.value.toDouble()),
          ],
        );
      },
    );
  }
}

class _RelationBars extends StatelessWidget {
  const _RelationBars({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(
        child: Text('暂无主体数据', style: TextStyle(color: _kMuted)),
      );
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

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final rows = c.orders.toList();
    return _SectionCard(
      title: '参与订单明细 · 共 ${rows.length} 条',
      child: rows.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('暂无订单', style: TextStyle(color: _kMuted)),
              ),
            )
          : AppDataGrid<OrderItem>.local(
              height: 280,
              rows: rows,
              rowKey: (row) => row.id ?? row.orderNo ?? '',
              showInternalDividers: true,
              headerBackgroundColor: const Color(0xFFFAFAFA),
              columns: [
                AppDataGridColumn(
                  id: 'no',
                  title: '序号',
                  width: 52,
                  value: (row) => rows.indexOf(row) + 1,
                  type: AppDataGridColumnType.number,
                ),
                AppDataGridColumn(
                  id: 'contact',
                  title: '联系人',
                  width: 120,
                  alignment: Alignment.centerLeft,
                  value: (_) => c.displayName,
                  cellBuilder: (context, row, _) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      if (c.title != '-')
                        Text(
                          c.title,
                          style:
                              const TextStyle(fontSize: 11, color: _kMuted),
                        ),
                    ],
                  ),
                ),
                AppDataGridColumn(
                  id: 'employer',
                  title: '就职企业(最新)',
                  width: 140,
                  value: (_) => c.employer,
                ),
                AppDataGridColumn(
                  id: 'brand',
                  title: '关联品牌',
                  width: 88,
                  value: (row) => row.brandName ?? '-',
                ),
                AppDataGridColumn(
                  id: 'enterprise',
                  title: '关联企业',
                  width: 160,
                  value: (row) => row.enterprise ?? '-',
                ),
                AppDataGridColumn(
                  id: 'amount',
                  title: '订单金额',
                  width: 100,
                  value: (row) => row.amount ?? '',
                  cellBuilder: (context, row, _) => Text(
                    _fmtWan(row.amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kGold,
                    ),
                  ),
                ),
                AppDataGridColumn(
                  id: 'time',
                  title: '订单时间',
                  width: 140,
                  value: (row) => row.orderTime ?? '',
                  cellBuilder: (context, row, _) => Text(
                    _fmtDateTime(row.orderTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                AppDataGridColumn(
                  id: 'same',
                  title: '同企业联系人',
                  width: 120,
                  value: (_) => c.sameEnterpriseContactNames.isEmpty
                      ? '-'
                      : c.sameEnterpriseContactNames.join('、'),
                ),
                AppDataGridColumn(
                  id: 'sales',
                  title: '销售员',
                  width: 88,
                  value: (row) => row.salesPerson ?? '-',
                ),
              ],
            ),
    );
  }
}

class _CoworkersCard extends StatelessWidget {
  const _CoworkersCard({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final names = controller.sameEnterpriseContactNames;
    return _SectionCard(
      title: '同企业联系人',
      child: names.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('暂无同事', style: TextStyle(color: _kMuted)),
            )
          : Column(
              children: [
                for (final name in names)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _Avatar(name: name, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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

class _DynamicsCard extends StatelessWidget {
  const _DynamicsCard({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final briefs = controller.aiBriefs;
    return _SectionCard(
      title: '最新动态 · AI 简报',
      child: briefs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('暂无动态', style: TextStyle(color: _kMuted)),
            )
          : Column(
              children: [
                for (final b in briefs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
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
                                '${b['time'] ?? '-'} · ${b['source'] ?? '系统动态'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${b['summary'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
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

class _MapCard extends StatefulWidget {
  const _MapCard({required this.controller});

  final PersonDetailController controller;

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  final _mapKey = GlobalKey<OfficeAmapViewState>();

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final address = c.address == '-' ? '' : c.address;
    final city = c.city == '-' ? '' : c.city;
    return _SectionCard(
      title: '办公地址地图',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: OfficeAmapView(
              key: _mapKey,
              address: address,
              city: city,
              showZoomControl: false,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (c.employer != '-') c.employer,
              if (c.displayName != '-') c.displayName,
              if (address.isNotEmpty) address,
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: _kTitle),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppButton.outline(
                onPressed: address.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: address));
                        if (!context.mounted) return;
                        showHyperToast(context, content: const Text('已复制地址'));
                      },
                child: const Text('复制地址'),
              ),
              const SizedBox(width: 8),
              AppButton.outline(
                onPressed: address.isEmpty
                    ? null
                    : () {
                        final s = _mapKey.currentState;
                        openAmapNavigation(
                          context,
                          address: address,
                          name: c.employer == '-' ? c.displayName : c.employer,
                          longitude: s?.lng,
                          latitude: s?.lat,
                        );
                      },
                child: const Text('导航'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.salesStats.entries.toList();
    final owners = controller.ownerNames
        .split(RegExp(r'[,，;；、/|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != '-')
        .toList();
    final people = stats.isNotEmpty
        ? stats
        : [
            for (final n in owners) MapEntry(n, (count: 0, amount: 0.0)),
          ];
    return _SectionCard(
      title: '负责销售员',
      child: people.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('暂无销售员', style: TextStyle(color: _kMuted)),
            )
          : Column(
              children: [
                for (var i = 0; i < people.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        _Avatar(name: people[i].key, size: 32),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    people[i].key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AppBadge.custom(
                                    color: i == 0
                                        ? _kPrimary
                                        : const Color(0xFF52C41A),
                                    appearance: AppBadgeStyle.soft,
                                    shape: AppBadgeShape.square,
                                    child: Text(
                                      i == 0 ? '主销售' : '协同销售',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '负责 ${people[i].value.count} 单 · ${_fmtWan(people[i].value.amount.toStringAsFixed(2))}',
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

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.remark});

  final String remark;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '备注与附件',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            remark == '-' ? '暂无备注' : remark,
            style: TextStyle(
              fontSize: 13,
              color: remark == '-' ? _kMuted : _kTitle,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('暂无附件', style: TextStyle(color: _kMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

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
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty
        ? '?'
        : String.fromCharCodes(name.runes.take(1));
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}

String _fmtWan(String? raw) {
  final n = num.tryParse(raw?.trim() ?? '');
  if (n == null) return '-';
  final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
  return '¥$s万';
}

String _fmtDateTime(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return '-';
  return s.length >= 16 ? s.substring(0, 16) : s;
}
