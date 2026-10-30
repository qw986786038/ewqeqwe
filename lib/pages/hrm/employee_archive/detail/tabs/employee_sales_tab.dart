import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF86909C);
const _kBorder = Color(0xFFE5E6EB);
const _kDivider = Color(0xFFF2F3F5);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF86909C);
const _kHeaderBg = Color(0xFFFAFBFC);
const _kOrange = Color(0xFFD46B08);
const _kOrangeBg = Color(0xFFFFF7E6);
const _kOrangeSoft = Color(0xFFFFFBE6);
const _kBlueBg = Color(0xFFE8F3FF);
const _kGreen = Color(0xFF00B42A);
const _kGreenBg = Color(0xFFE8FFEA);
const _kGrayBg = Color(0xFFF2F3F5);
const _kDanger = Color(0xFFF53F3F);
const _kPageShadow = Color(0x0A000000);

/// 销售/订单与客户：按设计稿排版；无接口写死演示。
class EmployeeSalesTab extends StatefulWidget {
  const EmployeeSalesTab({super.key});

  @override
  State<EmployeeSalesTab> createState() => _EmployeeSalesTabState();
}

class _EmployeeSalesTabState extends State<EmployeeSalesTab> {
  bool _hideAmount = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '订单总额',
                value: _hideAmount ? '******' : '42,800,000',
                valueColor: _kTitle,
                sub: '共 6 笔订单',
                subColor: _kMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: '已回款',
                value: _hideAmount ? '******' : '33,380,000',
                valueColor: _kGreen,
                sub: '回款比例 78%',
                subColor: _kGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: '待回款',
                value: _hideAmount ? '******' : '9,420,000',
                valueColor: _kOrange,
                sub: '含 1 笔逾期 37 天',
                subColor: _kOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    '销售订单',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kOrangeSoft,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFFE58F)),
                    ),
                    child: const Text(
                      '订单金额仅 HR / 财务 / 本人可见',
                      style: TextStyle(fontSize: 12, color: _kOrange),
                    ),
                  ),
                  const Spacer(),
                  AppInkWell(
                    onPressed: () =>
                        setState(() => _hideAmount = !_hideAmount),
                    child: Text(
                      _hideAmount ? '显示金额' : '隐藏金额',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1180),
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
                              _HCell('订单编号', 120),
                              _HCell('客户名称', 130),
                              _HCell('订单 / 项目类型', 120),
                              _HCell('签约日期', 100),
                              _HCell('订单金额（元）', 120),
                              _HCell('订单状态', 88),
                              _HCell('回款状态', 110),
                              _HCell('关联部门 / 项目角色', 150),
                              _HCell('备注', 200),
                            ],
                          ),
                        ),
                        for (var i = 0; i < _orders.length; i++)
                          _OrderRow(
                            row: _orders[i],
                            zebra: i.isOdd,
                            hideAmount: _hideAmount,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sub,
    required this.subColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String sub;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _kLabel),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: TextStyle(fontSize: 12, color: subColor, height: 1.2),
          ),
        ],
      ),
    );
  }
}

enum _OrderStatus { executing, done }

enum _PayStatus { partial, paid }

class _OrderData {
  const _OrderData({
    required this.no,
    required this.customer,
    required this.type,
    required this.signDate,
    required this.amount,
    required this.orderStatus,
    required this.payStatus,
    required this.payPercent,
    required this.role,
    required this.remark,
    this.remarkDanger = false,
  });

  final String no;
  final String customer;
  final String type;
  final String signDate;
  final String amount;
  final _OrderStatus orderStatus;
  final _PayStatus payStatus;
  final int payPercent;
  final String role;
  final String remark;
  final bool remarkDanger;
}

const _orders = <_OrderData>[
  _OrderData(
    no: 'SD-2025-1008',
    customer: '华信科技',
    type: '年度框架',
    signDate: '2025-01-18',
    amount: '8,600,000',
    orderStatus: _OrderStatus.executing,
    payStatus: _PayStatus.partial,
    payPercent: 65,
    role: '大客户部 · 主责',
    remark: '二期验收中',
  ),
  _OrderData(
    no: 'SD-2024-0881',
    customer: '远航集团',
    type: '数字化项目',
    signDate: '2024-09-02',
    amount: '12,400,000',
    orderStatus: _OrderStatus.executing,
    payStatus: _PayStatus.partial,
    payPercent: 70,
    role: '大客户部 · 主责',
    remark: '按里程碑回款',
  ),
  _OrderData(
    no: 'SD-2024-0612',
    customer: '星河传媒',
    type: '广告投放',
    signDate: '2024-05-20',
    amount: '3,200,000',
    orderStatus: _OrderStatus.done,
    payStatus: _PayStatus.paid,
    payPercent: 100,
    role: '大客户部 · 协作',
    remark: '已完结归档',
  ),
  _OrderData(
    no: 'SD-2023-1440',
    customer: '北辰实业',
    type: '咨询服务',
    signDate: '2023-11-08',
    amount: '6,800,000',
    orderStatus: _OrderStatus.executing,
    payStatus: _PayStatus.partial,
    payPercent: 15,
    role: '大客户部 · 主责',
    remark: '余款逾期 37 天，财务催收中',
    remarkDanger: true,
  ),
  _OrderData(
    no: 'SD-2022-0521',
    customer: '青云制造',
    type: '设备采购',
    signDate: '2022-06-15',
    amount: '4,600,000',
    orderStatus: _OrderStatus.done,
    payStatus: _PayStatus.paid,
    payPercent: 100,
    role: '客户二部 · 主责',
    remark: '无',
  ),
  _OrderData(
    no: 'SD-2021-0199',
    customer: '锦程物流',
    type: '年度框架',
    signDate: '2021-03-22',
    amount: '7,200,000',
    orderStatus: _OrderStatus.done,
    payStatus: _PayStatus.partial,
    payPercent: 60,
    role: '客户二部 · 协作',
    remark: '尾款协商中',
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

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.row,
    required this.zebra,
    required this.hideAmount,
  });

  final _OrderData row;
  final bool zebra;
  final bool hideAmount;

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
          _DCell(row.no, 120),
          _DCell(row.customer, 130),
          _DCell(row.type, 120),
          _DCell(row.signDate, 100),
          _DCell(hideAmount ? '******' : row.amount, 120, bold: !hideAmount),
          SizedBox(
            width: 88,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Pill(
                text: row.orderStatus == _OrderStatus.executing
                    ? '执行中'
                    : '已完结',
                fg: row.orderStatus == _OrderStatus.executing
                    ? _kPrimary
                    : _kMuted,
                bg: row.orderStatus == _OrderStatus.executing
                    ? _kBlueBg
                    : _kGrayBg,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Pill(
                text: row.payStatus == _PayStatus.paid
                    ? '已回款 100%'
                    : '回款中 ${row.payPercent}%',
                fg: row.payStatus == _PayStatus.paid ? _kGreen : _kOrange,
                bg: row.payStatus == _PayStatus.paid ? _kGreenBg : _kOrangeBg,
              ),
            ),
          ),
          _DCell(row.role, 150),
          _DCell(
            row.remark,
            200,
            muted: !row.remarkDanger,
            danger: row.remarkDanger,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fg, required this.bg});

  final String text;
  final Color fg;
  final Color bg;

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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _DCell extends StatelessWidget {
  const _DCell(
    this.text,
    this.width, {
    this.muted = false,
    this.bold = false,
    this.danger = false,
  });

  final String text;
  final double width;
  final bool muted;
  final bool bold;
  final bool danger;

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
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: danger
              ? _kDanger
              : muted
                  ? _kMuted
                  : _kTitle,
        ),
      ),
    );
  }
}
