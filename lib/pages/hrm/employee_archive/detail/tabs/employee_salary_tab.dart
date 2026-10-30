import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF8C8C8C);
const _kHeaderBg = Color(0xFFF7F8FA);
const _kDanger = Color(0xFFFF4D4F);
const _kOrange = Color(0xFFFA8C16);
const _kOrangeBg = Color(0xFFFFF7E6);
const _kOrangeFg = Color(0xFFD46B08);
const _kBlueBg = Color(0xFFE6F4FF);
const _kChipGrayBg = Color(0xFFF2F3F5);

/// 薪资与档案：布局与配色对齐设计稿（暂无接口，演示写死）。
class EmployeeSalaryTab extends StatelessWidget {
  const EmployeeSalaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
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
                  const Text(
                    '本月薪酬与结算明细',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _Tag(
                    text: 'HR / 财务 / 本人可见',
                    bg: _kChipGrayBg,
                    fg: _kMuted,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '周期 2025-10 · 发薪日 2025-10-15',
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                  const Spacer(),
                  AppButton.outline(
                    onPressed: () {
                      AppToast.show(context: context, title: '导出工资条待接入');
                    },
                    child: const Text('导出工资条'),
                  ),
                  const SizedBox(width: 8),
                  AppButton.primary(
                    onPressed: () {
                      AppToast.show(context: context, title: '同步薪酬档案待接入');
                    },
                    child: const Text('同步薪酬档案'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                    child: _SummaryStat(label: '月基本工资', value: '¥ 31,400'),
                  ),
                  Expanded(
                    child: _SummaryStat(label: '绩效工资', value: '¥ 4,800'),
                  ),
                  Expanded(
                    child: _SummaryStat(label: '项目奖金 / 提成', value: '¥ 9,200'),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: '实发合计',
                      value: '¥ 28,360',
                      valueColor: _kPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                      '薪资项明细',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kTitle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '共 12 项',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                    SizedBox(width: 8),
                    _Tag(
                      text: '本期明细',
                      bg: _kBlueBg,
                      fg: _kPrimary,
                    ),
                  ],
                ),
              ),
              Container(
                color: _kHeaderBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '薪资项',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kLabel,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '类别',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kLabel,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '金额',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final row in _items) _ItemRow(row: row),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                '薪酬调整时间线',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              SizedBox(height: 16),
              _TimelineItem(
                color: _kOrange,
                title: '年度调薪',
                date: '2025-04-01',
                badge: '+12%',
                badgeFg: _kOrangeFg,
                badgeBg: _kOrangeBg,
                desc: '月基本工资 28,000 → 31,400，审批人：罗叶',
              ),
              _TimelineItem(
                color: _kPrimary,
                title: '晋升（P6 → P7）',
                date: '2023-04-01',
                badge: '晋升',
                badgeFg: _kPrimary,
                badgeBg: _kBlueBg,
                desc: '晋升后月基本工资 24,000 → 28,000，跨档定薪',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    this.valueColor = _kTitle,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kLabel)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ItemData {
  const _ItemData({
    required this.name,
    required this.category,
    required this.amount,
    this.amountColor = _kTitle,
    this.bold = false,
  });

  final String name;
  final String category;
  final String amount;
  final Color amountColor;
  final bool bold;
}

const _items = <_ItemData>[
  _ItemData(name: '基本工资', category: '固定项', amount: '¥ 31,400'),
  _ItemData(name: '绩效工资', category: '浮动项', amount: '¥ 4,800'),
  _ItemData(name: '项目奖金 / 提成', category: '浮动项', amount: '¥ 9,200'),
  _ItemData(name: '津贴补贴', category: '固定项', amount: '¥ 1,200'),
  _ItemData(
    name: '社保个人部分',
    category: '代扣项',
    amount: '- ¥ 3,185',
    amountColor: _kDanger,
  ),
  _ItemData(
    name: '公积金个人部分',
    category: '代扣项',
    amount: '- ¥ 1,820',
    amountColor: _kDanger,
  ),
  _ItemData(
    name: '个人所得税',
    category: '代扣项',
    amount: '- ¥ 5,240',
    amountColor: _kDanger,
  ),
  _ItemData(
    name: '实发合计',
    category: '应发 - 代扣',
    amount: '¥ 28,360',
    amountColor: _kPrimary,
    bold: true,
  ),
];

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.row});

  final _ItemData row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: row.bold ? FontWeight.w600 : FontWeight.w400,
                color: _kTitle,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.category,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: row.bold ? FontWeight.w700 : FontWeight.w500,
                color: row.amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.color,
    required this.title,
    required this.date,
    required this.badge,
    required this.badgeFg,
    required this.badgeBg,
    required this.desc,
    this.isLast = false,
  });

  final Color color;
  final String title;
  final String date;
  final String badge;
  final Color badgeFg;
  final Color badgeBg;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
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
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
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
                      Text(
                        date,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
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
                            color: badgeFg,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kLabel,
                      height: 1.45,
                    ),
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
