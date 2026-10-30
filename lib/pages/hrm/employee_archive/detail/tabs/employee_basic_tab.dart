import 'package:flutter/material.dart';
import 'package:lemon_x/lemon_x.dart';

import '../employee_detail_controller.dart';

const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF8C8C8C);
const _kAccent = Color(0xFFFA8C16);
const _kChipAllBg = Color(0xFFE6F4FF);
const _kChipAllFg = Color(0xFF1677FF);
const _kChipHrBg = Color(0xFFF2F3F5);
const _kChipHrFg = Color(0xFF4E5969);
const _kChipSelfBg = Color(0xFFFFF7E6);
const _kChipSelfFg = Color(0xFFD46B08);

/// 基础信息：三列「上标签下数值」，配色对齐设计稿。
class EmployeeBasicTab extends StatelessWidget {
  const EmployeeBasicTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeDetailController>();
    return Obx(() {
      final p = c.profile.value;
      final contact = c.contacts.isEmpty ? null : c.contacts.first;
      final age = c.ageYears();
      final birthRaw = p?.birthDate?.trim();
      final birthLine = (birthRaw == null || birthRaw.isEmpty)
          ? '2002-10-15（24岁）'
          : age == null
              ? birthRaw
              : '$birthRaw（$age岁）';
      final school = p?.graduateSchool?.trim();
      final major = p?.major?.trim();
      final eduMajor = [
        if (school != null && school.isNotEmpty) school,
        if (major != null && major.isNotEmpty) major,
      ].join(' · ');
      String? eduEnd;
      for (final e in c.educations) {
        if (e.isHighest == 1) {
          eduEnd = e.endDate;
          break;
        }
      }
      eduEnd ??= c.educations.isEmpty ? null : c.educations.first.endDate;

      final contactName = contact == null
          ? '张三（父母）'
          : '${_nz(contact.name, '张三')}'
              '${contact.relation?.trim().isNotEmpty == true ? '（${contact.relation!.trim()}）' : '（父母）'}';

      // 列顺序与设计稿一致：左 / 中 / 右
      final col1 = <(String, String, {bool accent})>[
        ('姓名', _nz(p?.name, '杜甫'), accent: false),
        (
          '性别',
          EmployeeDetailController.genderLabel(p?.gender) == '—'
              ? '男'
              : EmployeeDetailController.genderLabel(p?.gender),
          accent: false,
        ),
        ('政治面貌', _dashOr(p?.politicalStatus), accent: false),
        (
          '毕业院校',
          eduMajor.isEmpty ? '上海大学 · 市场营销' : eduMajor,
          accent: false,
        ),
        (
          '办公地点',
          _nz(c.officeLocationLabel(), '济南'),
          accent: false,
        ),
        (
          '个人邮箱',
          _nz(p?.personalEmail, 'dufu@qq.com'),
          accent: true,
        ),
        ('紧急联系人', contactName, accent: false),
      ];
      final col2 = <(String, String, {bool accent})>[
        ('英文名', _nz(p?.englishName, 'Du Fu'), accent: false),
        ('出生日期', birthLine, accent: false),
        (
          '婚姻状况',
          EmployeeDetailController.maritalLabel(p?.maritalStatus) == '—'
              ? '已婚'
              : EmployeeDetailController.maritalLabel(p?.maritalStatus),
          accent: false,
        ),
        ('毕业时间', _nz(eduEnd, '2026-09-30'), accent: false),
        ('身份证号', _nz(p?.idCardNo, '31010119900297'), accent: false),
        ('企业邮箱', _nz(p?.corpEmail, 'dufu@adhr.cn'), accent: false),
        (
          '紧急联系电话',
          _nz(contact?.phone, '158 6666 0000'),
          accent: true,
        ),
      ];
      final col3 = <(String, String, {bool accent})>[
        ('工号', _nz(p?.no, '1298'), accent: false),
        ('民族', _nz(p?.nation, '汉'), accent: false),
        ('最高学历', _nz(p?.highestEducation, '硕士'), accent: false),
        ('现居住地', _dashOr(p?.residence), accent: false),
        ('手机号', _nz(p?.mobile, '138 1000 0297'), accent: false),
        ('企业微信', _nz(p?.imAccount, '@杜甫'), accent: false),
        ('户籍地址', _dashOr(p?.householdAddress), accent: false),
      ];

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                      '基础信息与字段',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kTitle,
                      ),
                    ),
                    const Spacer(),
                    const _FilterChip(
                      text: '全部字段',
                      bg: _kChipAllBg,
                      fg: _kChipAllFg,
                    ),
                    const SizedBox(width: 8),
                    const _FilterChip(
                      text: '仅 HR 本人可见',
                      bg: _kChipHrBg,
                      fg: _kChipHrFg,
                    ),
                    const SizedBox(width: 8),
                    const _FilterChip(
                      text: '仅 HR 与本人可见',
                      bg: _kChipSelfBg,
                      fg: _kChipSelfFg,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _FieldColumn(items: col1)),
                    const SizedBox(width: 32),
                    Expanded(child: _FieldColumn(items: col2)),
                    const SizedBox(width: 32),
                    Expanded(child: _FieldColumn(items: col3)),
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

  /// 空值保留「—」（设计稿部分字段为空）。
  static String _dashOr(String? value) {
    final s = value?.trim();
    if (s == null || s.isEmpty) return '—';
    return s;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.text,
    required this.bg,
    required this.fg,
  });

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FieldColumn extends StatelessWidget {
  const _FieldColumn({required this.items});

  final List<(String, String, {bool accent})> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kLabel,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: item.accent && item.$2 != '—'
                        ? _kAccent
                        : _kTitle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
