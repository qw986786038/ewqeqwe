import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../employee_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF86909C);
const _kBorder = Color(0xFFE5E6EB);
const _kDivider = Color(0xFFF2F3F5);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF86909C);
const _kHeaderBg = Color(0xFFFAFBFC);
const _kOrangeBg = Color(0xFFFFF7E6);
const _kOrangeFg = Color(0xFFD46B08);
const _kBlueBg = Color(0xFFE8F3FF);
const _kGreen = Color(0xFF00B42A);
const _kGreenBg = Color(0xFFE8FFEA);
const _kPageShadow = Color(0x0A000000);

/// 任职组织：按设计稿重排留白与配色；无接口字段写死演示。
class EmployeeAssignTab extends StatelessWidget {
  const EmployeeAssignTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return Obx(() {
      final assign =
          c.primaryAssign ?? (c.assigns.isEmpty ? null : c.assigns.first);
      final dept1 = _nz(
        assign == null ? null : c.assignDeptName(assign),
        '客户事业部',
      );
      final post = _nz(
        assign == null ? null : c.assignPostName(assign),
        '客户总监',
      );
      final levelRaw = assign == null ? null : c.assignLevelName(assign);
      final level = (levelRaw == null || levelRaw.isEmpty)
          ? 'P7（管理序列 M2）'
          : (levelRaw.contains('管理') || levelRaw.contains('（')
              ? levelRaw
              : '$levelRaw（管理序列 M2）');
      final start = _nz(assign?.startDate, '2023-04-01');
      final report = _nz(
        assign == null ? null : c.assignReportName(assign),
        '林哲 事业部总经理',
      );
      final selfName = _nz(c.profile.value?.name, '陈思远');

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '当前任职',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kTitle,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _Field(label: '一级部门', value: dept1),
                                  _Field(label: '职务', value: post),
                                  const _Field(
                                    label: '职务性质',
                                    value: '管理岗 · 全职',
                                  ),
                                  _Field(
                                    label: '直属上级',
                                    value: '$report（虚线）',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            Expanded(
                              child: Column(
                                children: [
                                  const _Field(label: '二级部门', value: '大客户部'),
                                  _Field(label: '职级', value: level),
                                  _Field(label: '生效日期', value: start),
                                  const _Field(
                                    label: '矩阵上级',
                                    value: '周哲 品牌总监（虚线）',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 16),
                          child: Divider(height: 1, color: _kDivider),
                        ),
                        const Text(
                          '行政汇报链',
                          style: TextStyle(fontSize: 12, color: _kLabel),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 8,
                          children: [
                            _ChainText('周哲 CEO'),
                            const _ChainArrow(),
                            _ChainText('林哲 事业部总经理'),
                            const _ChainArrow(),
                            _ChainText(
                              '$selfName $post',
                              highlight: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppInkWell(
                          onPressed: () {
                            AppToast.show(
                              context: context,
                              title: '请从侧栏进入组织架构',
                            );
                          },
                          child: const Text(
                            '在组织树中查看完整路径',
                            style: TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(flex: 3, child: _ScopeCard()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _HistoryCard(),
        ],
      );
    });
  }

  static String _nz(String? value, String fallback) {
    final s = value?.trim();
    if (s == null || s.isEmpty || s == '—') return fallback;
    return s;
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: _kPageShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _kLabel,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kTitle,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainText extends StatelessWidget {
  const _ChainText(this.text, {this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
        color: highlight ? _kPrimary : _kTitle,
      ),
    );
  }
}

class _ChainArrow extends StatelessWidget {
  const _ChainArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.arrow_forward_ios, size: 10, color: _kMuted),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard();

  @override
  Widget build(BuildContext context) {
    return const _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '管辖范围',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          SizedBox(height: 18),
          _ScopeRow(label: '直属下属', value: '4 人'),
          _ScopeRow(label: '间接下属', value: '8 人'),
          _ScopeRow(label: '负责客户数', value: '11 个'),
          _ScopeRow(label: '负责业绩目标', value: '4,300 万/年'),
          _ScopeRow(label: '编制满意度', value: '75%'),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 6,
              backgroundColor: Color(0xFFF2F3F5),
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _kLabel),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '任职历史',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 980),
                child: Column(
                  children: [
                    Container(
                      color: _kHeaderBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      child: const Row(
                        children: [
                          _HCell('生效日期', 100),
                          _HCell('部门', 150),
                          _HCell('职务', 100),
                          _HCell('职级', 56),
                          _HCell('汇报对象', 72),
                          _HCell('变动类型', 72),
                          _HCell('备注', 180),
                          _HCell('薪资变动', 140),
                        ],
                      ),
                    ),
                    for (var i = 0; i < _history.length; i++)
                      _HistoryRow(
                        row: _history[i],
                        zebra: i.isOdd,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryData {
  const _HistoryData({
    required this.date,
    required this.dept,
    required this.post,
    required this.level,
    required this.report,
    required this.type,
    required this.remark,
    required this.salary,
    required this.typeFg,
    required this.typeBg,
  });

  final String date;
  final String dept;
  final String post;
  final String level;
  final String report;
  final String type;
  final String remark;
  final String salary;
  final Color typeFg;
  final Color typeBg;
}

const _history = <_HistoryData>[
  _HistoryData(
    date: '2025-04-01',
    dept: '客户事业部 / 大客户部',
    post: '客户总监',
    level: 'P7',
    report: '林哲',
    type: '调薪',
    remark: '年度调薪，来源人：罗野',
    salary: '28,000 → 31,400',
    typeFg: _kOrangeFg,
    typeBg: _kOrangeBg,
  ),
  _HistoryData(
    date: '2023-04-01',
    dept: '客户事业部 / 大客户部',
    post: '客户总监',
    level: 'P7',
    report: '林哲',
    type: '晋升',
    remark: '通过 2023 春季晋升',
    salary: '24,000 → 28,000',
    typeFg: _kPrimary,
    typeBg: _kBlueBg,
  ),
  _HistoryData(
    date: '2021-07-01',
    dept: '客户事业部 / 大客户部',
    post: '高级客户经理',
    level: 'P6',
    report: '林哲',
    type: '调岗',
    remark: '由客户二部调至大客户部',
    salary: '无变动',
    typeFg: _kOrangeFg,
    typeBg: _kOrangeBg,
  ),
  _HistoryData(
    date: '2019-06-11',
    dept: '客户事业部 / 客户二部',
    post: '高级客户经理',
    level: 'P6',
    report: '周哲',
    type: '转正',
    remark: '试用期考核 A',
    salary: '80% → 100%',
    typeFg: _kGreen,
    typeBg: _kGreenBg,
  ),
  _HistoryData(
    date: '2019-03-11',
    dept: '客户事业部 / 客户二部',
    post: '客户主管',
    level: 'P5',
    report: '周哲',
    type: '入职',
    remark: '内部推荐',
    salary: '18,000',
    typeFg: _kPrimary,
    typeBg: _kBlueBg,
  ),
];

class _HCell extends StatelessWidget {
  const _HCell(this.text, this.width);

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _kLabel,
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row, required this.zebra});

  final _HistoryData row;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: zebra ? const Color(0xFFFAFBFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          _DCell(row.date, 100),
          _DCell(row.dept, 150),
          _DCell(row.post, 100),
          _DCell(row.level, 56),
          _DCell(row.report, 72),
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: row.typeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  row.type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: row.typeFg,
                  ),
                ),
              ),
            ),
          ),
          _DCell(row.remark, 180, muted: true),
          _DCell(row.salary, 140),
        ],
      ),
    );
  }
}

class _DCell extends StatelessWidget {
  const _DCell(this.text, this.width, {this.muted = false});

  final String text;
  final double width;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: muted ? _kMuted : _kTitle,
        ),
      ),
    );
  }
}
