import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../employee_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF4E5969);
const _kWarnBg = Color(0xFFFFF7E6);
const _kWarnFg = Color(0xFFD46B08);
const _kWarnBorder = Color(0xFFFFD591);
const _kWarnBtn = Color(0xFFFA8C16);
const _kSuccess = Color(0xFF52C41A);
const _kSuccessBg = Color(0xFFF6FFED);
const _kDanger = Color(0xFFFF4D4F);
const _kPurpleBg = Color(0xFFF9F0FF);
const _kPurpleBorder = Color(0xFFD3ADF7);
const _kPurple = Color(0xFF722ED1);
const _kTimelineLine = Color(0xFFE5E6EB);

/// 概览：接口有则用接口，否则写死演示数据（对齐设计稿配色）。
class EmployeeOverviewTab extends StatelessWidget {
  const EmployeeOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return Obx(() {
      final p = c.profile.value;
      final assign = c.primaryAssign;
      final contact = c.contacts.isEmpty ? null : c.contacts.first;
      final contract = c.contracts.isEmpty ? null : c.contracts.first;
      final age = c.ageYears();
      final name = _nz(p?.name, '陈思远');
      final alias = _nz(
        p?.aliasName?.trim().isNotEmpty == true
            ? p!.aliasName
            : p?.englishName,
        'SiYuan',
      );
      final gender = EmployeeDetailController.genderLabel(p?.gender);
      final genderAge = [
        gender == '—' ? '男' : gender,
        if (age != null) '$age 岁' else '32 岁',
      ].join(' / ');
      final eduLine = [
        _nz(p?.highestEducation, '硕士'),
        _nz(p?.graduateSchool, '山东大学'),
        _nz(p?.major, '市场营销'),
      ].join(' · ');
      final dept = assign == null
          ? '客户事业部'
          : _nz(c.assignDeptName(assign), '客户事业部');
      final postLevel = assign == null
          ? '客户总监 / P7'
          : [
              c.assignPostName(assign),
              c.assignLevelName(assign),
            ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ')
                .ifEmpty('客户总监 / P7');
      final report = assign == null
          ? '林哲 · 事业部总经理'
          : _nz(c.assignReportName(assign), '林哲 · 事业部总经理');
      final contactName = contact == null
          ? '张三（父母）'
          : '${_nz(contact.name, '张三')}'
              '${contact.relation?.trim().isNotEmpty == true ? '（${contact.relation!.trim()}）' : '（父母）'}';
      final contactPhone = _nz(contact?.phone, '158 6666 0000');
      final contactCount = c.contacts.isEmpty ? 2 : c.contacts.length;
      final contractNo = _nz(contract?.contractNo, 'HT-2019-0311');
      final contractType = _nz(contract?.type, '固定期限 · 3 年');
      final contractEnd = _nz(contract?.expireDate, '2026-03-10');

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Panel(
                  title: '个人与家庭档案',
                  titleTrailing: AppInkWell(
                    onPressed: () {
                      AppToast.show(context: context, title: '请使用顶部「编辑档案」');
                    },
                    child: const Text(
                      '编辑信息',
                      style: TextStyle(fontSize: 12, color: _kPrimary),
                    ),
                  ),
                  child: Column(
                    children: [
                      _kv('姓名 / 花名', '$name / $alias'),
                      _kv('年龄 / 性别', genderAge),
                      _kv('最高学历', eduLine),
                      _kv('现居住地', _nz(p?.residence, '济南 · 历下区')),
                      _kv(
                        '婚姻状况',
                        EmployeeDetailController.maritalLabel(p?.maritalStatus) ==
                                '—'
                            ? '已婚'
                            : EmployeeDetailController.maritalLabel(
                                p?.maritalStatus,
                              ),
                      ),
                      _kv('政治面貌', _nz(p?.politicalStatus, '群众')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Panel(
                  title: '任职信息摘要',
                  child: Column(
                    children: [
                      _kv('部门', dept),
                      _kv('职务 / 职级', postLevel),
                      _kv('汇报对象', report),
                      _kv('直属下属', '4 人 · 团队 12 人'),
                      _kv(
                        '职务状态',
                        assign?.startDate?.trim().isNotEmpty == true
                            ? '在任 · 自 ${assign!.startDate!.trim()}'
                            : '在任 · 自 2021-04-01',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Panel(
                  title: '合同状态',
                  titleTrailing: const Text(
                    '仅 HR 与本人可见',
                    style: TextStyle(fontSize: 11, color: _kMuted),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: _kWarnBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kWarnBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '即将到期',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kWarnFg,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _kWarnBorder),
                              ),
                              child: const Text(
                                '提醒中',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _kWarnFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _kv('合同编号', contractNo, compact: true),
                        _kv('类型', contractType, compact: true),
                        _kv('到期日', contractEnd, compact: true),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 72,
                                child: Text(
                                  '剩余天数',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kLabel,
                                  ),
                                ),
                              ),
                              Text(
                                '145 天',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kDanger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton.primary(
                          color: _kWarnBtn,
                          onPressed: () {
                            AppToast.show(context: context, title: '续约待接入');
                          },
                          child: const Text('续约 / 续签'),
                        ),
                      ],
                    ),
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
                child: _Panel(
                  title: '薪酬摘要',
                  titleTrailing: const Text(
                    '结算期 2025-10 · HR / 财务 / 本人',
                    style: TextStyle(fontSize: 11, color: _kMuted),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '实发工资',
                        style: TextStyle(fontSize: 12, color: _kLabel),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '¥ 28,360',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: _MiniStat(label: '月基本工资', value: '¥31,400')),
                          Expanded(child: _MiniStat(label: '绩效 / 奖金', value: '¥4,800')),
                          Expanded(child: _MiniStat(label: '个税 / 社保', value: '¥5,240')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppInkWell(
                        onPressed: () {
                          AppToast.show(context: context, title: '薪酬明细待接入');
                        },
                        child: const Text(
                          '查看薪酬与结算明细 →',
                          style: TextStyle(fontSize: 12, color: _kPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Panel(
                  title: '紧急联系人',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kTitle,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contactPhone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _kWarnBtn,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '共 $contactCount 位紧急联系人',
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Panel(
                  title: '招聘 / 订单与客户',
                  child: Column(
                    children: [
                      EmployeeOverviewTab._kv('司龄业绩', '12 年'),
                      EmployeeOverviewTab._kv('累计订单金额', '¥ 4,280,000'),
                      EmployeeOverviewTab._kv('主要客户', '豪华车 · 安踏'),
                      EmployeeOverviewTab._kv('本年度线索', '36 条'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Panel(
            title: '绩效与编制摘要',
            titleTrailing: const Text(
              '仅 HR 与本人可见',
              style: TextStyle(fontSize: 11, color: _kMuted),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kSuccessBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB7EB8F)),
                  ),
                  child: const Text(
                    'A',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _kSuccess,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      _MiniStat(label: '2024 绩效', value: '达成 108%'),
                      _MiniStat(label: '近 6 月均绩', value: '92%'),
                      _MiniStat(label: '年度等级', value: 'A-'),
                      _MiniStat(label: '年终奖月数', value: '6.5 个月'),
                      _MiniStat(label: '晋升次数', value: '3 次'),
                      _MiniStat(label: '迟到次数', value: '1 次'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            titleIcon: const Icon(Icons.schedule, size: 16, color: _kPrimary),
            title: '职务任职时间线',
            titleTrailing: const Text(
              '入职 → 试用 → 转正 → 调岗 → 晋升 → 调薪',
              style: TextStyle(fontSize: 12, color: _kMuted),
            ),
            child: const Column(
              children: [
                _TimelineItem(
                  color: _kPrimary,
                  title: '入职',
                  date: '2019-03-11',
                  badge: '已完成',
                  badgeFg: _kSuccess,
                  badgeBg: _kSuccessBg,
                  desc: '进入客户事业部，任客户主管（P5），汇报对象林哲。',
                ),
                _TimelineItem(
                  color: _kPrimary,
                  title: '试用期开始',
                  date: '2019-03-11 ~ 2019-06-10',
                  badge: '3 个月',
                  badgeFg: _kPrimary,
                  badgeBg: Color(0xFFE6F4FF),
                  desc: '目标转正；导师为现业务线负责人。',
                ),
                _TimelineItem(
                  color: _kSuccess,
                  title: '转正',
                  date: '2019-06-11',
                  badge: '已完成',
                  badgeFg: _kSuccess,
                  badgeBg: _kSuccessBg,
                  desc: '考核达标，正式任客户主管（P5）。',
                ),
                _TimelineItem(
                  color: _kWarnBtn,
                  title: '调岗',
                  date: '2021-07-01',
                  badge: '职务调整',
                  badgeFg: _kWarnFg,
                  badgeBg: _kWarnBg,
                  desc: '由客户二组调至大客户部，负责豪华车线；汇报线调整为林哲。',
                ),
                _TimelineItem(
                  color: _kPrimary,
                  title: '晋升',
                  date: '2023-04-01',
                  badge: '升一档',
                  badgeFg: _kPrimary,
                  badgeBg: Color(0xFFE6F4FF),
                  desc: '晋升客户总监（P7），负责华东区域（沪苏浙皖鲁）。',
                ),
                _TimelineItem(
                  color: Color(0xFFFAAD14),
                  title: '调薪',
                  date: '2025-08-01',
                  badge: '+12%',
                  badgeFg: _kSuccess,
                  badgeBg: _kSuccessBg,
                  desc: '年度调整；月基本工资 28,000 → 31,400，团队规模扩大。',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            titleIcon: const Icon(Icons.account_tree_outlined, size: 16, color: _kPrimary),
            title: '组织关系图',
            titleTrailing: AppInkWell(
              onPressed: () {
                AppToast.show(context: context, title: '请从侧栏进入组织架构');
              },
              child: const Text(
                '在组织架构中查看',
                style: TextStyle(fontSize: 12, color: _kPrimary),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '展示汇报上级、直属下属、协作人与项目组',
                  style: TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 16),
                _OrgPersonCard(
                  name: report.split('·').first.trim().ifEmpty('林哲'),
                  role: '汇报上级 · 事业部总经理',
                  avatarColor: _kPrimary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_downward, size: 16, color: _kMuted),
                ),
                _OrgPersonCard(
                  name: '$name（本人）',
                  role: '$postLevel · $dept',
                  avatarColor: _kPurple,
                  highlight: true,
                ),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OrgGroup(
                        title: '直属下属',
                        items: [
                          ('马青云', '客户经理 · 华东'),
                          ('卢安', '华北销售经理'),
                          ('沈虹', '客户专员'),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _OrgGroup(
                        title: '协作人',
                        items: [
                          ('周白', '品牌总监'),
                          ('赵婉', '项目经理'),
                          ('孙亮', '财务经理'),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _OrgGroup(
                        title: '项目组',
                        items: [
                          ('豪华车年度方案', '项目成员'),
                          ('安踏双 11', '项目成员'),
                          ('星巴克新品上市', '项目成员'),
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
    });
  }

  static String _nz(String? value, String fallback) {
    final s = value?.trim();
    if (s == null || s.isEmpty || s == '—') return fallback;
    return s;
  }

  static Widget _kv(String k, String v, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 72 : 88,
            child: Text(k, style: const TextStyle(fontSize: 12, color: _kLabel)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontSize: 13, color: _kTitle)),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.titleTrailing,
    this.titleIcon,
  });

  final String title;
  final Widget child;
  final Widget? titleTrailing;
  final Widget? titleIcon;

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
              if (titleIcon != null) ...[
                titleIcon!,
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              if (titleTrailing != null) ...[
                const Spacer(),
                titleTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
      ],
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
                      color: _kTimelineLine,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
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

class _OrgPersonCard extends StatelessWidget {
  const _OrgPersonCard({
    required this.name,
    required this.role,
    required this.avatarColor,
    this.highlight = false,
  });

  final String name;
  final String role;
  final Color avatarColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final char = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: highlight ? _kPurpleBg : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? _kPurpleBorder : _kBorder,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: highlight ? _kPurple : _kTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgGroup extends StatelessWidget {
  const _OrgGroup({required this.title, required this.items});

  final String title;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 8),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9E8FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      e.$1.characters.first,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kTitle,
                          ),
                        ),
                        Text(
                          e.$2,
                          style: const TextStyle(fontSize: 11, color: _kMuted),
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
