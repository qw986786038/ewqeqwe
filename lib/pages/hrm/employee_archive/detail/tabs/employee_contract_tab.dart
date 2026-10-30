import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../employee_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF8C8C8C);
const _kHeaderBg = Color(0xFFF7F8FA);
const _kWarnBg = Color(0xFFFFF7E6);
const _kWarnFg = Color(0xFFD46B08);
const _kWarnBorder = Color(0xFFFFD591);
const _kSuccess = Color(0xFF52C41A);
const _kSuccessBg = Color(0xFFF6FFED);
const _kChipOrangeBg = Color(0xFFFFF7E6);
const _kChipOrangeFg = Color(0xFFD46B08);
const _kChipGrayBg = Color(0xFFF2F3F5);

/// 合同信息：布局与配色对齐设计稿；无接口字段写死演示。
class EmployeeContractTab extends StatelessWidget {
  const EmployeeContractTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return Obx(() {
      final labor = () {
        for (final item in c.contracts) {
          final t = item.type?.trim() ?? '';
          if (t.contains('劳动') || t.toUpperCase() == 'LABOR') {
            return item;
          }
        }
        return c.contracts.isEmpty ? null : c.contracts.first;
      }();

      final no = _nz(labor?.contractNo, 'HT-2019-0323');
      final type = _nz(labor?.type, '固定期限');
      final sign = _nz(labor?.signDate, '2019-03-11');
      final start = _nz(labor?.effectiveDate, '2023-03-11');
      final end = _nz(labor?.expireDate, '2026-03-10');

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
                      '合同台账',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _Tag(
                      text: '仅 HR 与本人可见',
                      bg: _kChipOrangeBg,
                      fg: _kChipOrangeFg,
                    ),
                    const Spacer(),
                    AppButton.primary(
                      onPressed: () {
                        AppToast.show(context: context, title: '发起续签待接入');
                      },
                      child: const Text('发起续签'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LaborCard(
                        no: no,
                        type: type,
                        sign: sign,
                        period: '$start ~ $end',
                        end: end,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: _NdaCard()),
                  ],
                ),
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
                Row(
                  children: [
                    Text(
                      '合同薪酬条款',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kTitle,
                      ),
                    ),
                    SizedBox(width: 8),
                    _Tag(
                      text: 'HR · 财务可见',
                      bg: _kChipGrayBg,
                      fg: _kMuted,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SalaryStat(label: '月基本工资', value: '¥ 31,400'),
                    ),
                    Expanded(
                      child: _SalaryStat(label: '试用期工资比例', value: '80%'),
                    ),
                    Expanded(
                      child: _SalaryStat(label: '发薪日', value: '每月 15 日'),
                    ),
                    Expanded(
                      child: _SalaryStat(
                        label: '薪资保密范围',
                        value: 'A 级（仅 HR / 财务 / 本人）',
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
                  child: Text(
                    '续签与变更记录',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                ),
                const _ChangeHeader(),
                for (final row in _changeRows) _ChangeRow(row: row),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '到期提醒设置',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kTitle,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '有效设置：到期前 90 天 / 60 天 / 30 天，分别提醒 HR 与直属上级。',
                        style: TextStyle(fontSize: 13, color: _kLabel),
                      ),
                    ],
                  ),
                ),
                AppButton.outline(
                  onPressed: () {
                    AppToast.show(context: context, title: '修改提醒规则待接入');
                  },
                  child: const Text('修改提醒规则'),
                ),
              ],
            ),
          ),
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

class _LaborCard extends StatelessWidget {
  const _LaborCard({
    required this.no,
    required this.type,
    required this.sign,
    required this.period,
    required this.end,
  });

  final String no;
  final String type;
  final String sign;
  final String period;
  final String end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kWarnBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kWarnBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text(
                '劳动合同',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
              ),
              Spacer(),
              Text(
                '即将到期',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kWarnFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _gridField('合同编号', no),
                    _gridField('签订日期', sign),
                    _gridField('到期日', end),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _gridField('合同类型', type),
                    _gridField('合同期限', period),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '剩余天数',
                            style: TextStyle(fontSize: 12, color: _kLabel),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '148 天',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _kWarnFg,
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
          const Text(
            '到期前 90 天提醒 HR 与直属上级',
            style: TextStyle(fontSize: 12, color: _kWarnFg),
          ),
        ],
      ),
    );
  }

  static Widget _gridField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kLabel)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _NdaCard extends StatelessWidget {
  const _NdaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                '保密与竞业协议',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kSuccessBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '生效中',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _field('协议编号', 'NDA-2019-0323'),
                    _field('签订日期', '2019-03-11'),
                    _field('补偿比例', '月薪 30%'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _field('类型', '保密 + 竞业限制'),
                    _field('竞业期限', '离职后 12 个月'),
                    _field('生效状态', '生效中'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kLabel)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryStat extends StatelessWidget {
  const _SalaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kLabel)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kTitle,
          ),
        ),
      ],
    );
  }
}

class _ChangeRowData {
  const _ChangeRowData({
    required this.date,
    required this.type,
    required this.content,
    required this.operator,
    required this.file,
  });

  final String date;
  final String type;
  final String content;
  final String operator;
  final String file;
}

const _changeRows = <_ChangeRowData>[
  _ChangeRowData(
    date: '2023-03-11',
    type: '续签',
    content: '期限 2023-03-11 ~ 2026-03-10（3 年）',
    operator: '罗叶',
    file: 'HT-2023-0321.pdf',
  ),
  _ChangeRowData(
    date: '2020-03-10',
    type: '续签',
    content: '期限 2020-03-11 ~ 2023-03-10（3 年）',
    operator: '罗叶',
    file: 'HT-2020-0318.pdf',
  ),
  _ChangeRowData(
    date: '2019-06-11',
    type: '补充协议',
    content: '签署保密 / 竞业协议',
    operator: '罗叶',
    file: 'NDA-2019-0323.pdf',
  ),
  _ChangeRowData(
    date: '2019-03-11',
    type: '新签',
    content: '固定期限 3 年，试用期 3 个月',
    operator: '罗叶',
    file: 'HT-2019-0323.pdf',
  ),
];

class _ChangeHeader extends StatelessWidget {
  const _ChangeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          _HCell('操作日期', 110),
          _HCell('操作类型', 90),
          Expanded(child: _HCell('变更内容', null)),
          _HCell('操作人', 80),
          _HCell('附件', 160),
        ],
      ),
    );
  }
}

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

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.row});

  final _ChangeRowData row;

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
            width: 90,
            child: Text(row.type, style: const TextStyle(fontSize: 13, color: _kTitle)),
          ),
          Expanded(
            child: Text(
              row.content,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              row.operator,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          SizedBox(
            width: 160,
            child: AppInkWell(
              onPressed: () {
                AppToast.show(context: context, title: '附件下载待接入');
              },
              child: Text(
                row.file,
                style: const TextStyle(fontSize: 13, color: _kPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
