import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF8C8C8C);
const _kHeaderBg = Color(0xFFF7F8FA);
const _kPurple = Color(0xFF635BFF);
const _kGreen = Color(0xFF52C41A);
const _kGreenBg = Color(0xFFF6FFED);
const _kBlueBg = Color(0xFFE6F4FF);
const _kOrangeBg = Color(0xFFFFF7E6);
const _kOrangeFg = Color(0xFFD46B08);
const _kRankPastBg = Color(0xFFF2F3F5);

/// 晋升与职级：布局与配色对齐设计稿（暂无接口，演示写死）。
class EmployeePromotionTab extends StatelessWidget {
  const EmployeePromotionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _RankHistoryCard()),
            const SizedBox(width: 12),
            const Expanded(child: _ReviewCard()),
          ],
        ),
        const SizedBox(height: 12),
        const _SalaryAdjustCard(),
      ],
    );
  }
}

class _RankHistoryCard extends StatelessWidget {
  const _RankHistoryCard();

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
          const Text(
            '职级历程',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: _RankChip(
                  code: 'P5',
                  sub: '2019-03',
                  style: _RankStyle.past,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _RankChip(
                  code: 'P6',
                  sub: '2019-06',
                  style: _RankStyle.past,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _RankChip(
                  code: 'P7',
                  sub: '2023-04 · 当前',
                  style: _RankStyle.current,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _RankChip(
                  code: 'P8',
                  sub: '待晋升',
                  style: _RankStyle.future,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: _kOrangeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '职级条件：连续 2 个季度绩效达到 A-，且完成资格评审后，当前已满足 1/2 个规则。',
              style: TextStyle(
                fontSize: 12,
                color: _kOrangeFg,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RankStyle { past, current, future }

class _RankChip extends StatelessWidget {
  const _RankChip({
    required this.code,
    required this.sub,
    required this.style,
  });

  final String code;
  final String sub;
  final _RankStyle style;

  @override
  Widget build(BuildContext context) {
    final isCurrent = style == _RankStyle.current;
    final isFuture = style == _RankStyle.future;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? _kPurple
            : isFuture
                ? Colors.white
                : _kRankPastBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? _kPurple
              : isFuture
                  ? const Color(0xFFC9CDD4)
                  : _kRankPastBg,
          width: isFuture ? 1.2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            code,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isCurrent ? Colors.white : _kTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? const Color(0xFFE8E6FF) : _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '晋升评审记录',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          SizedBox(height: 14),
          _ReviewItem(
            title: 'P6 → P7 晋升评审',
            date: '2023-03-20',
            badge: '通过',
            badgeFg: _kGreen,
            badgeBg: _kGreenBg,
            meta: '评委：周白 / 林哲 / 罗野',
            comment: '绩效均分 4.5/5，客户满意度 92%，团队管理能力达标。',
          ),
          SizedBox(height: 14),
          _ReviewItem(
            title: 'P5 → P6 转正定级',
            date: '2019-06-11',
            badge: '随转正完成',
            badgeFg: _kPrimary,
            badgeBg: _kBlueBg,
            meta: '评委：周哲',
            comment: '试用期绩效优秀，转正后职级 P6。',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({
    required this.title,
    required this.date,
    required this.badge,
    required this.badgeFg,
    required this.badgeBg,
    required this.meta,
    required this.comment,
    this.isLast = false,
  });

  final String title;
  final String date;
  final String badge;
  final Color badgeFg;
  final Color badgeBg;
  final String meta;
  final String comment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: _kPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  const Expanded(
                    child: VerticalDivider(
                      width: 2,
                      thickness: 2,
                      color: _kBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTitle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 12, color: _kLabel),
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kTitle,
                    height: 1.45,
                  ),
                ),
                if (!isLast) const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryAdjustCard extends StatelessWidget {
  const _SalaryAdjustCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  '调薪记录',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
                SizedBox(width: 8),
                _Tag(
                  text: '仅 HR 与本人可见',
                  bg: _kOrangeBg,
                  fg: _kOrangeFg,
                ),
              ],
            ),
          ),
          Container(
            color: _kHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                _HCell('生效日期', 110),
                _HCell('类型', 100),
                _HCell('调薪前', 100),
                _HCell('调薪后', 100),
                _HCell('幅度', 90),
                Expanded(child: _HCell('审批人', null)),
              ],
            ),
          ),
          for (final row in _salaryRows) _SalaryRow(row: row),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SalaryRowData {
  const _SalaryRowData({
    required this.date,
    required this.type,
    required this.before,
    required this.after,
    required this.rate,
    required this.approver,
  });

  final String date;
  final String type;
  final String before;
  final String after;
  final String rate;
  final String approver;
}

const _salaryRows = <_SalaryRowData>[
  _SalaryRowData(
    date: '2025-04-01',
    type: '年度调薪',
    before: '28,000',
    after: '31,400',
    rate: '+12%',
    approver: '罗野',
  ),
  _SalaryRowData(
    date: '2023-04-01',
    type: '晋升调薪',
    before: '22,000',
    after: '28,000',
    rate: '+27%',
    approver: '罗野',
  ),
  _SalaryRowData(
    date: '2021-07-01',
    type: '调岗调薪',
    before: '18,000',
    after: '22,000',
    rate: '+22.2%',
    approver: '罗野',
  ),
  _SalaryRowData(
    date: '2019-06-11',
    type: '转正调薪',
    before: '11,360',
    after: '18,000',
    rate: '+58.5%',
    approver: '罗野',
  ),
];

class _HCell extends StatelessWidget {
  const _HCell(this.text, this.width);

  final String text;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _kLabel,
      ),
    );
    if (width == null) return child;
    return SizedBox(width: width, child: child);
  }
}

class _SalaryRow extends StatelessWidget {
  const _SalaryRow({required this.row});

  final _SalaryRowData row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(row.date, style: const TextStyle(fontSize: 13, color: _kTitle)),
          ),
          SizedBox(
            width: 100,
            child: Text(row.type, style: const TextStyle(fontSize: 13, color: _kTitle)),
          ),
          SizedBox(
            width: 100,
            child: Text(row.before, style: const TextStyle(fontSize: 13, color: _kTitle)),
          ),
          SizedBox(
            width: 100,
            child: Text(row.after, style: const TextStyle(fontSize: 13, color: _kTitle)),
          ),
          SizedBox(
            width: 90,
            child: Text(
              row.rate,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kGreen,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.approver,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
        ],
      ),
    );
  }
}
