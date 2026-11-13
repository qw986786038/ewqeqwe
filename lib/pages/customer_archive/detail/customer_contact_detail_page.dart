import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../services/customer_api.dart';
import 'dialogs/contact_edit_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);

/// 联系人详情：`GET /desktop/oac/contact/{id}`。
///
/// [embedded] 为 true 时用于详情页内弹窗，不包 Scaffold / AppBar。
class CustomerContactDetailPage extends StatefulWidget {
  const CustomerContactDetailPage({
    super.key,
    required this.contactId,
    this.embedded = false,
  });

  final String contactId;
  final bool embedded;

  @override
  State<CustomerContactDetailPage> createState() =>
      _CustomerContactDetailPageState();
}

class _CustomerContactDetailPageState extends State<CustomerContactDetailPage> {
  final _api = CustomerApi();
  var _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchContactDetail(widget.contactId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    final data = _data;
    if (data == null) return;
    final saved = await showContactEditDialog(context, contact: data);
    if (saved && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final name = data == null ? '…' : _dash(_str(data['name']));

    // State.context 在 AppShadcnScope 之上；弹窗须用 Scope 内 context，
    // 否则 DialogRoute 捕获不到 shad.Theme → No Theme found in context。
    return AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: Builder(
        builder: (context) {
          final body = _buildBody(context, data);
          if (widget.embedded) {
            return ColoredBox(color: _kPageBg, child: body);
          }
          return Scaffold(
            backgroundColor: _kPageBg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: _kTitle,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: const Border(bottom: BorderSide(color: _kBorder)),
              leadingWidth: 108,
              leading: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 18, color: _kPrimary),
                label: const Text(
                  '返回列表',
                  style: TextStyle(fontSize: 13, color: _kPrimary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              titleSpacing: 0,
              title: Text(
                '客户档案管理 / $name',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4E5969),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic>? data) {
    if (_loading && data == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFFFF4D4F))),
            const SizedBox(height: 12),
            AppButton.primary(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (data == null) {
      return const Center(child: Text('暂无数据', style: TextStyle(color: _kMuted)));
    }

    final name = _dash(_str(data['name']));
    final letter = name == '-'
        ? '?'
        : String.fromCharCodes(name.runes.take(1));
    final gender = _dash(
      _str(data['genderLabel']).isNotEmpty
          ? _str(data['genderLabel'])
          : _gender(_str(data['gender'])),
    );
    final careers = _careerRows(data['careers']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    '基本信息',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const Spacer(),
                  AppButton.primary(
                    onPressed: () => _openEdit(context),
                    leading: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    child: const Text('编辑'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF52C41A),
                          borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(height: 6),
                      const Text(
                        'LOGO/图标',
                        style: TextStyle(fontSize: 11, color: _kMuted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Table(
                      border: TableBorder.all(color: _kBorder, width: 1),
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.2),
                      },
                      children: [
                        TableRow(
                          children: [
                            _TableInfoCell(label: '姓名', value: name),
                            _TableInfoCell(
                              label: 'Name',
                              value: _dash(_str(data['nameEn'])),
                            ),
                            _TableInfoCell(label: '性别', value: gender),
                            _TableInfoCell(
                              label: '年龄段',
                              value: _dash(_str(data['ageDesc'])),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            _TableInfoCell(
                              label: '手机号',
                              value: _dash(_str(data['phones'])),
                            ),
                            _TableInfoCell(
                              label: '邮箱',
                              value: _dash(_str(data['emails'])),
                            ),
                            _TableInfoCell(
                              label: '所在城市',
                              value: _dash(_str(data['city'])),
                            ),
                            _TableInfoCell(
                              label: '详细地址',
                              value: _dash(_str(data['address'])),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '职业信息',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const SizedBox(height: 10),
              if (careers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('暂无职业信息', style: TextStyle(color: _kMuted)),
                )
              else
                _CareerTable(
                  rows: careers,
                  onEdit: () => _openEdit(context),
                ),
              const SizedBox(height: 8),
              const Text(
                '档案时间：创建时间-至今/离职时间；离职时间=新创建在其它企业下的时间',
                style: TextStyle(fontSize: 11, color: _kMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _careerRows(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];
    String cell(dynamic v) {
      final t = _dash(_str(v));
      if (t.length <= 120) return t;
      return '${t.substring(0, 120)}…';
    }

    final out = <Map<String, String>>[];
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      out.add({
        'no': '${i + 1}',
        'short': cell(m['enterpriseShortName']),
        'full': cell(m['enterpriseFullName']),
        'brand': cell(m['relatedBrands']),
        'relation': cell(m['relationType']),
        'city': cell(m['city']),
        'address': cell(m['address']),
        'title': cell(m['deptTitle']),
        'job': cell(m['jobDesc']),
        'scope': cell(m['marketScope']),
        'brands': cell(m['responsibleBrands']),
        'sup': cell(m['superiorNames']),
        'sub': cell(m['subordinateNames']),
        'archive': cell(m['archivePeriod']),
        'owner': cell(m['ownerNames']),
      });
    }
    return out;
  }
}

class _TableInfoCell extends StatelessWidget {
  const _TableInfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.length > 200 ? '${value.substring(0, 200)}…' : value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 4),
          Text(
            display,
            style: const TextStyle(fontSize: 13, color: _kTitle),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

/// 职业信息表：横向滚动 + 单元格边框。
class _CareerTable extends StatefulWidget {
  const _CareerTable({required this.rows, required this.onEdit});

  final List<Map<String, String>> rows;
  final VoidCallback onEdit;

  static const _cols = <(String id, String title, double width)>[
    ('no', '序号', 56),
    ('short', '企业简称', 100),
    ('full', '企业全称', 180),
    ('brand', '关联品牌', 140),
    ('relation', '关联关系', 100),
    ('city', '所在城市', 100),
    ('address', '详细地址', 140),
    ('title', '部门/职位', 120),
    ('job', '职能描述', 120),
    ('scope', '负责市场范围', 120),
    ('brands', '负责品牌', 120),
    ('sup', '上级联系人', 100),
    ('sub', '下级联系人', 100),
    ('archive', '档案时间', 160),
    ('owner', '负责人', 140),
    ('actions', '操作', 72),
  ];

  @override
  State<_CareerTable> createState() => _CareerTableState();
}

class _CareerTableState extends State<_CareerTable> {
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_hScroll.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent || !_hScroll.hasClients) return;
      final dx = resolved.scrollDelta.dx != 0
          ? resolved.scrollDelta.dx
          : resolved.scrollDelta.dy;
      if (dx == 0) return;
      final next = (_hScroll.offset + dx).clamp(
        0.0,
        _hScroll.position.maxScrollExtent,
      );
      if (next != _hScroll.offset) {
        _hScroll.jumpTo(next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalW = _CareerTable._cols.fold<double>(0, (s, c) => s + c.$3);
    const headerH = 40.0;
    const rowH = 48.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return SizedBox(
          width: viewportW,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: Listener(
              onPointerSignal: _onPointerSignal,
              child: Scrollbar(
                controller: _hScroll,
                thumbVisibility: true,
                interactive: true,
                notificationPredicate: (n) =>
                    n.depth == 0 && n.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _hScroll,
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalW,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: headerH,
                          width: totalW,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0;
                                  i < _CareerTable._cols.length;
                                  i++)
                                _cellBox(
                                  width: _CareerTable._cols[i].$3,
                                  header: true,
                                  firstCol: i == 0,
                                  last: i == _CareerTable._cols.length - 1,
                                  child: Text(
                                    _CareerTable._cols[i].$2,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kTitle,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        for (final row in widget.rows)
                          SizedBox(
                            height: rowH,
                            width: totalW,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0;
                                    i < _CareerTable._cols.length;
                                    i++)
                                  _cellBox(
                                    width: _CareerTable._cols[i].$3,
                                    header: false,
                                    firstCol: i == 0,
                                    last: i == _CareerTable._cols.length - 1,
                                    child: _CareerTable._cols[i].$1 == 'actions'
                                        ? AppInkWell(
                                            onPressed: widget.onEdit,
                                            child: const Text(
                                              '编辑',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _kPrimary,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            row[_CareerTable._cols[i].$1] ??
                                                '-',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _kTitle,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                              ],
                            ),
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
    );
  }

  Widget _cellBox({
    required double width,
    required bool header,
    required bool firstCol,
    required bool last,
    required Widget child,
  }) {
    // 高度由外层固定行高 + Row.stretch 提供；勿用 height: infinity（会与有限 maxHeight 冲突导致未布局）。
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: header ? const Color(0xFFFAFAFA) : Colors.white,
          border: Border(
            top: header
                ? const BorderSide(color: _kBorder)
                : BorderSide.none,
            left: firstCol
                ? const BorderSide(color: _kBorder)
                : BorderSide.none,
            right: const BorderSide(color: _kBorder),
            bottom: const BorderSide(color: _kBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(child: child),
        ),
      ),
    );
  }
}

String _str(dynamic v) => v?.toString().trim() ?? '';

String _dash(String s) {
  final t = s.trim();
  return t.isEmpty ? '-' : t;
}

String _gender(String s) => switch (s) {
      '1' => '男',
      '2' => '女',
      '男' || '女' => s,
      _ => s.isEmpty ? '-' : s,
    };
