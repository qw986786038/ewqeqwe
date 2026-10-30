import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF8C8C8C);
const _kOrange = Color(0xFFFA8C16);
const _kOrangeBg = Color(0xFFFFF7E6);
const _kOrangeFg = Color(0xFFD46B08);
const _kBlueBg = Color(0xFFE6F4FF);
const _kGreen = Color(0xFF52C41A);
const _kGreenBg = Color(0xFFF6FFED);
const _kPurple = Color(0xFF722ED1);
const _kGold = Color(0xFFFAAD14);

/// 入职登记表：布局与配色对齐设计稿（暂无接口，演示写死）。
class EmployeeOnboardingTab extends StatelessWidget {
  const EmployeeOnboardingTab({super.key});

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
                    '入职信息与登记表',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '共 6 条登记节点',
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                  const Spacer(),
                  AppButton.outline(
                    onPressed: () {
                      AppToast.show(context: context, title: '导出登记表待接入');
                    },
                    child: const Text('导出登记表'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < _nodes.length; i++)
                _NodeItem(
                  node: _nodes[i],
                  isLast: i == _nodes.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NodeData {
  const _NodeData({
    required this.color,
    required this.title,
    required this.date,
    required this.badge,
    required this.badgeFg,
    required this.badgeBg,
    required this.desc,
  });

  final Color color;
  final String title;
  final String date;
  final String badge;
  final Color badgeFg;
  final Color badgeBg;
  final String desc;
}

const _nodes = <_NodeData>[
  _NodeData(
    color: _kPrimary,
    title: '代办入职手续',
    date: '2019-03-11',
    badge: '已完成',
    badgeFg: _kGreen,
    badgeBg: _kGreenBg,
    desc: '办理人：罗野 · HR。签订劳动合同，开通企业邮箱与门禁，发放入职装备（入职引导人：司念）。',
  ),
  _NodeData(
    color: _kPurple,
    title: '试用期开始',
    date: '2019-03-11',
    badge: '已结束',
    badgeFg: _kPrimary,
    badgeBg: _kBlueBg,
    desc: '试用期 2019-03-11 ~ 2019-06-10，考核人：周哲。',
  ),
  _NodeData(
    color: _kGreen,
    title: '转正',
    date: '2019-06-11',
    badge: '通过',
    badgeFg: _kGreen,
    badgeBg: _kGreenBg,
    desc: '试用期评估得分 92 分，结论：优秀，准予转正。',
  ),
  _NodeData(
    color: _kOrange,
    title: '部门内调动',
    date: '2021-07-01',
    badge: '客户二部 → 大客户部',
    badgeFg: _kOrangeFg,
    badgeBg: _kOrangeBg,
    desc: '调动原因：承接汽车行业大客户，原上级：刘波，现上级：林哲。',
  ),
  _NodeData(
    color: _kPrimary,
    title: '资料归档',
    date: '2023-03-20',
    badge: '档案已归档',
    badgeFg: _kPrimary,
    badgeBg: _kBlueBg,
    desc: '归档资料包含：简历、学历、身份证、劳动合同（汽车行业竞业限制协议已签）。',
  ),
  _NodeData(
    color: _kGold,
    title: '年度调薪',
    date: '2025-04-01',
    badge: '+12%',
    badgeFg: _kOrangeFg,
    badgeBg: _kOrangeBg,
    desc: '绩效评级 A，薪酬涨幅 12%，月基本工资 28K → 31.4K。',
  ),
];

class _NodeItem extends StatelessWidget {
  const _NodeItem({required this.node, required this.isLast});

  final _NodeData node;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: node.color, width: 2.5),
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
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        node.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTitle,
                        ),
                      ),
                      Text(
                        node.date,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: node.badgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          node.badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: node.badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    node.desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kLabel,
                      height: 1.5,
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
