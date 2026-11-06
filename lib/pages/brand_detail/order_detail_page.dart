part of 'brand_detail_page.dart';

/// 品牌详情「全部 N 笔」→ 订单明细详情。数据来自已加载的
/// `GET /desktop/oac/brand/{id}/detail`。
class BrandOrderDetailPage extends StatefulWidget {
  const BrandOrderDetailPage({super.key});

  @override
  State<BrandOrderDetailPage> createState() => _BrandOrderDetailPageState();
}

class _BrandOrderDetailPageState extends State<BrandOrderDetailPage> {
  BrandDetailController get _c => context.lx.find<BrandDetailController>();

  final _keywordCtrl = TextEditingController();
  final _jumpCtrl = TextEditingController();

  String? _contract;
  String? _relation;
  String? _tag;
  String? _sales;
  DateTime? _start;
  DateTime? _end;

  String _keyword = '';
  String? _appliedContract;
  String? _appliedRelation;
  String? _appliedTag;
  String? _appliedSales;
  DateTime? _appliedStart;
  DateTime? _appliedEnd;

  var _page = 1;
  var _pageSize = 10;

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _jumpCtrl.dispose();
    super.dispose();
  }

  Future<void> _addOrder() async {
    final ok = await showAddOrderDialog(
      context,
      initialBrandId: _c.brandId,
    );
    if (!ok || !mounted) return;
    await _c.load();
  }

  void _search() {
    setState(() {
      _keyword = _keywordCtrl.text.trim();
      _appliedContract = _contract;
      _appliedRelation = _relation;
      _appliedTag = _tag;
      _appliedSales = _sales;
      _appliedStart = _start;
      _appliedEnd = _end;
      _page = 1;
    });
  }

  void _reset() {
    setState(() {
      _keywordCtrl.clear();
      _keyword = '';
      _contract = null;
      _relation = null;
      _tag = null;
      _sales = null;
      _start = null;
      _end = null;
      _appliedContract = null;
      _appliedRelation = null;
      _appliedTag = null;
      _appliedSales = null;
      _appliedStart = null;
      _appliedEnd = null;
      _page = 1;
    });
  }

  List<OrderItem> _filtered(List<OrderItem> orders) {
    final kw = _keyword.toLowerCase();
    return [
      for (final o in orders)
        if (_match(o, kw)) o,
    ];
  }

  bool _match(OrderItem o, String kw) {
    if (kw.isNotEmpty) {
      final hay = [
        o.name,
        o.orderNo,
        o.tag,
        o.enterprise,
        o.brandName,
        o.agencyName,
        o.contact,
        o.salesPerson,
        o.remark,
        _c.contractTypeLabel(o.contractType),
        _c.relationLabel(o.relation),
      ].whereType<String>().join(' ').toLowerCase();
      if (!hay.contains(kw)) return false;
    }
    if (_appliedContract != null &&
        _c.contractTypeLabel(o.contractType) != _appliedContract) {
      return false;
    }
    if (_appliedRelation != null &&
        _c.relationLabel(o.relation) != _appliedRelation) {
      return false;
    }
    if (_appliedTag != null) {
      final tags = _c.headerDisplayTags(_c.detail.value?.brand);
      final own = _c.tagLabel(o.tag);
      if (!tags.contains(_appliedTag) && own != _appliedTag) return false;
    }
    if (_appliedSales != null) {
      var people = _splitPeople(o.salesPerson);
      if (people.isEmpty) {
        people = _c.detail.value?.brand?.ownerNameList ??
            _splitPeople(_c.detail.value?.brand?.ownerNames);
      }
      if (!people.contains(_appliedSales)) return false;
    }
    final time = _parseOrderTime(o.orderTime);
    if (_appliedStart != null || _appliedEnd != null) {
      if (time == null) return false;
      final day = DateTime(time.year, time.month, time.day);
      if (_appliedStart != null) {
        final start = DateTime(
          _appliedStart!.year,
          _appliedStart!.month,
          _appliedStart!.day,
        );
        if (day.isBefore(start)) return false;
      }
      if (_appliedEnd != null) {
        final end = DateTime(
          _appliedEnd!.year,
          _appliedEnd!.month,
          _appliedEnd!.day,
        );
        if (day.isAfter(end)) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Obx(() {
        c.dictVersion.value;
        final detail = c.detail.value;
        final brand = detail?.brand;
        final orders = _filtered(detail?.orders ?? const []);
        final pages = math.max(1, (orders.length / _pageSize).ceil());
        final page = _page.clamp(1, pages);
        final start = (page - 1) * _pageSize;
        final slice = orders.skip(start).take(_pageSize).toList();
        var amount = 0.0;
        for (final o in orders) {
          amount += num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
        }
        final name = brand?.name?.trim().isNotEmpty == true
            ? brand!.name!.trim()
            : '品牌';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  HyperPressable(
                    onTap: () => Navigator.of(context).pop(),
                    builder: (context, states, child) => child!,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: Color(0xFF52C41A),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '返回列表',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF52C41A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/', style: TextStyle(color: _kMuted)),
                  ),
                  Expanded(
                    child: Text(
                      '洞察视角 · 品牌 / 品牌一级列表 / $name · 订单明细',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _kMuted),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _OrderDetailHero(
                    controller: c,
                    brand: brand,
                    onBack: () => Navigator.of(context).pop(),
                    onAdd: _addOrder,
                  ),
                  const SizedBox(height: 12),
                  _OrderDetailKpis(controller: c, orders: orders),
                  const SizedBox(height: 12),
                  _OrderDetailFilters(
                    controller: c,
                    orders: detail?.orders ?? const [],
                    keywordCtrl: _keywordCtrl,
                    contract: _contract,
                    relation: _relation,
                    tag: _tag,
                    sales: _sales,
                    start: _start,
                    end: _end,
                    onContract: (v) => setState(() => _contract = v),
                    onRelation: (v) => setState(() => _relation = v),
                    onTag: (v) => setState(() => _tag = v),
                    onSales: (v) => setState(() => _sales = v),
                    onStart: (v) => setState(() => _start = v),
                    onEnd: (v) => setState(() => _end = v),
                    onSearch: _search,
                    onReset: _reset,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                            const Text(
                              '订单明细',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kTitle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '共 ${orders.length} 条 · 金额合计 ${_fmtWan('$amount')}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kMuted,
                              ),
                            ),
                            const Spacer(),
                            AppButton.outline(
                              onPressed: () {
                                showHyperToast(
                                  context,
                                  content: const Text('导出暂未开放'),
                                );
                              },
                              leading: const Icon(Icons.upload_outlined, size: 14),
                              child: const Text('导出'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _OrdersGrid(
                          controller: c,
                          orders: slice,
                          brand: brand,
                          height: math.max(160, 56.0 + slice.length * 52),
                          withTime: true,
                          indexOffset: start,
                        ),
                        const SizedBox(height: 12),
                        _OrderPager(
                          total: orders.length,
                          page: page,
                          pages: pages,
                          pageSize: _pageSize,
                          jumpCtrl: _jumpCtrl,
                          onPage: (p) => setState(() => _page = p),
                          onPageSize: (n) => setState(() {
                            _pageSize = n;
                            _page = 1;
                          }),
                        ),
                      ],
                    ),
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

class _OrderDetailHero extends StatelessWidget {
  const _OrderDetailHero({
    required this.controller,
    required this.brand,
    required this.onBack,
    required this.onAdd,
  });

  final BrandDetailController controller;
  final OacBrand? brand;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final name = brand?.name?.trim().isNotEmpty == true
        ? brand!.name!.trim()
        : '品牌';
    final iconUrl = brand?.iconUrl?.trim();
    final code = brand?.brandCode?.trim();
    final industry = controller.industryLabel(brand?.industry);
    final tags = [
      for (final t in brand?.tagList ?? const <String>[])
        if (_isDisplayableTag(controller.tagLabel(t))) controller.tagLabel(t),
    ];
    final subtitle = [
      '二级订单列表',
      if (industry != '-') industry,
      if (code != null && code.isNotEmpty) '品牌编号 $code',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          HyperPressable(
            onTap: onBack,
            builder: (context, states, child) => child!,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: _kTitle),
                SizedBox(width: 4),
                Text('返回列表', style: TextStyle(fontSize: 13, color: _kTitle)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: iconUrl != null && iconUrl.isNotEmpty
                ? Image.network(
                    iconUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Avatar(name: name, size: 40),
                  )
                : _Avatar(name: name, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTitle,
                      ),
                    ),
                    for (final t in tags)
                      AppBadge.custom(
                        color: const Color(0xFF722ED1),
                        appearance: AppBadgeStyle.soft,
                        shape: AppBadgeShape.square,
                        child: Text(t, style: const TextStyle(fontSize: 11)),
                      ),
                    HyperPressable(
                      onTap: onBack,
                      builder: (context, states, child) => child!,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '查看品牌详情',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF52C41A),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF52C41A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          AppButton.outline(
            onPressed: () {
              showHyperToast(context, content: const Text('导出暂未开放'));
            },
            leading: const Icon(Icons.upload_outlined, size: 14),
            child: const Text('导出'),
          ),
          const SizedBox(width: 8),
          HyperPressable(
            onTap: onAdd,
            builder: (context, states, child) => child!,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF52C41A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '添加订单',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailKpis extends StatelessWidget {
  const _OrderDetailKpis({
    required this.controller,
    required this.orders,
  });

  final BrandDetailController controller;
  final List<OrderItem> orders;

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail.value;
    final brand = detail?.brand;
    var amount = 0.0;
    DateTime? latest;
    final contractCounts = <String, int>{};
    for (final o in orders) {
      amount += num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
      final time = _parseOrderTime(o.orderTime);
      if (time != null && (latest == null || time.isAfter(latest))) {
        latest = time;
      }
      final label = controller.contractTypeLabel(o.contractType);
      if (label != '-') {
        contractCounts[label] = (contractCounts[label] ?? 0) + 1;
      }
    }
    String topContract = '-';
    var topCount = 0;
    for (final e in contractCounts.entries) {
      if (e.value > topCount) {
        topContract = e.key;
        topCount = e.value;
      }
    }
    final agency = brand?.agencyCount ?? detail?.agencies.length ?? 0;
    final enterprise = brand?.enterpriseCount ?? detail?.enterprises.length ?? 0;
    final latestText = latest == null
        ? (brand?.latestOrderTime?.trim().isNotEmpty == true
            ? _fmtOrderTime(brand!.latestOrderTime, withTime: true)
            : '-')
        : _fmtOrderTime(latest.toIso8601String(), withTime: true);
    return Row(
      children: [
        Expanded(
          child: _kpi(
            label: '订单数量',
            value: '${orders.length} 笔',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpi(
            label: '订单金额',
            value: _fmtWan('$amount'),
            valueColor: const Color(0xFFFA8C16),
            background: const Color(0xFFFFF7E6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpi(
            label: '关联 4A / 企业',
            value: '$agency / $enterprise',
            subtitle: topCount == 0 ? null : '$topContract $topCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpi(
            label: '合同类型分布',
            value: topContract,
            subtitle: topCount == 0 ? null : '$topCount 笔',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpi(
            label: '最新订单时间',
            value: latestText,
            valueColor: const Color(0xFF52C41A),
            background: const Color(0xFFF6FFED),
            valueSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _kpi({
    required String label,
    required String value,
    String? subtitle,
    Color valueColor = _kTitle,
    Color background = Colors.white,
    double valueSize = 22,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderDetailFilters extends StatelessWidget {
  const _OrderDetailFilters({
    required this.controller,
    required this.orders,
    required this.keywordCtrl,
    required this.contract,
    required this.relation,
    required this.tag,
    required this.sales,
    required this.start,
    required this.end,
    required this.onContract,
    required this.onRelation,
    required this.onTag,
    required this.onSales,
    required this.onStart,
    required this.onEnd,
    required this.onSearch,
    required this.onReset,
  });

  final BrandDetailController controller;
  final List<OrderItem> orders;
  final TextEditingController keywordCtrl;
  final String? contract;
  final String? relation;
  final String? tag;
  final String? sales;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onRelation;
  final ValueChanged<String?> onTag;
  final ValueChanged<String?> onSales;
  final ValueChanged<DateTime?> onStart;
  final ValueChanged<DateTime?> onEnd;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  List<AppOption<String>> _opts(Iterable<String> values) {
    final seen = <String>{};
    final out = <AppOption<String>>[];
    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty || v == '-' || !seen.add(v)) continue;
      out.add(AppOption(value: v, label: v));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final contracts = _opts(
      orders.map((o) => controller.contractTypeLabel(o.contractType)),
    );
    final relations = _opts(
      orders.map((o) => controller.relationLabel(o.relation)),
    );
    final tags = _opts([
      ...?controller.detail.value?.brand?.tagList?.map(controller.tagLabel),
      ...orders.map((o) => controller.tagLabel(o.tag)),
    ]);
    final salesOptions = _opts([
      for (final o in orders) ..._splitPeople(o.salesPerson),
      ...?controller.detail.value?.brand?.ownerNameList,
    ]);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          _filter(
            '订单号 / 关键词',
            SizedBox(
              width: 180,
              child: TextField(
                controller: keywordCtrl,
                style: const TextStyle(fontSize: 12),
                decoration: _fieldDeco('订单号 / 企业 / 标签'),
                onSubmitted: (_) => onSearch(),
              ),
            ),
          ),
          _filter(
            '合同类型',
            SizedBox(
              width: 140,
              child: AppSelect<String>(
                value: contract,
                hintText: '全部类型',
                clearable: true,
                minWidth: 140,
                options: contracts,
                onChanged: onContract,
              ),
            ),
          ),
          _filter(
            '关联关系',
            SizedBox(
              width: 140,
              child: AppSelect<String>(
                value: relation,
                hintText: '全部关系',
                clearable: true,
                minWidth: 140,
                options: relations,
                onChanged: onRelation,
              ),
            ),
          ),
          _filter(
            '标签',
            SizedBox(
              width: 140,
              child: AppSelect<String>(
                value: tag,
                hintText: '全部标签',
                clearable: true,
                minWidth: 140,
                options: tags,
                onChanged: onTag,
              ),
            ),
          ),
          _filter(
            '销售员',
            SizedBox(
              width: 140,
              child: AppSelect<String>(
                value: sales,
                hintText: '全部销售员',
                clearable: true,
                minWidth: 140,
                options: salesOptions,
                onChanged: onSales,
              ),
            ),
          ),
          _filter(
            '订单时间范围',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: AppDatePicker(
                    value: start,
                    hintText: '开始',
                    onChanged: onStart,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('-', style: TextStyle(color: _kMuted)),
                ),
                SizedBox(
                  width: 140,
                  child: AppDatePicker(
                    value: end,
                    hintText: '结束',
                    onChanged: onEnd,
                  ),
                ),
              ],
            ),
          ),
          HyperPressable(
            onTap: onSearch,
            builder: (context, states, child) => child!,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF52C41A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '查询',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          AppButton.outline(
            onPressed: onReset,
            leading: const Icon(Icons.refresh, size: 14),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  Widget _filter(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _kBorder),
      ),
    );
  }
}

class _OrderPager extends StatelessWidget {
  const _OrderPager({
    required this.total,
    required this.page,
    required this.pages,
    required this.pageSize,
    required this.jumpCtrl,
    required this.onPage,
    required this.onPageSize,
  });

  final int total;
  final int page;
  final int pages;
  final int pageSize;
  final TextEditingController jumpCtrl;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  @override
  Widget build(BuildContext context) {
    final window = <int>[];
    final from = math.max(1, page - 2);
    final to = math.min(pages, from + 4);
    for (var i = from; i <= to; i++) {
      window.add(i);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '共 $total 条',
          style: const TextStyle(fontSize: 12, color: _kMuted),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: AppSelect<int>(
            value: pageSize,
            minWidth: 96,
            options: const [
              AppOption(value: 10, label: '10条/页'),
              AppOption(value: 20, label: '20条/页'),
              AppOption(value: 50, label: '50条/页'),
            ],
            onChanged: (v) {
              if (v != null) onPageSize(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        _pageBtn(
          icon: Icons.chevron_left,
          enabled: page > 1,
          onTap: () => onPage(page - 1),
        ),
        for (final p in window)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: HyperPressable(
              onTap: () => onPage(p),
              builder: (context, states, child) => child!,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p == page ? const Color(0xFF52C41A) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: p == page
                        ? const Color(0xFF52C41A)
                        : _kBorder,
                  ),
                ),
                child: Text(
                  '$p',
                  style: TextStyle(
                    fontSize: 12,
                    color: p == page ? Colors.white : _kTitle,
                  ),
                ),
              ),
            ),
          ),
        _pageBtn(
          icon: Icons.chevron_right,
          enabled: page < pages,
          onTap: () => onPage(page + 1),
        ),
        const SizedBox(width: 8),
        const Text('前往', style: TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(width: 4),
        SizedBox(
          width: 48,
          child: TextField(
            controller: jumpCtrl,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _kBorder),
              ),
            ),
            onSubmitted: (v) {
              final n = int.tryParse(v.trim());
              if (n == null) return;
              onPage(n.clamp(1, pages));
            },
          ),
        ),
        const SizedBox(width: 4),
        const Text('页', style: TextStyle(fontSize: 12, color: _kMuted)),
      ],
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return HyperPressable(
      onTap: enabled ? onTap : null,
      builder: (context, states, child) => child!,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 16, color: enabled ? _kTitle : _kMuted),
      ),
    );
  }
}
