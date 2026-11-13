import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/dict_data.dart';
import '../../../../models/hrm_employee_profile.dart';
import '../employee_archive_controller.dart';
import 'dialogs/employee_section_dialogs.dart';
import 'employee_edit_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF86909C);

/// 已有员工的编辑页：分区只读，点「编辑」再改。
class EmployeeEditOverview extends StatelessWidget {
  const EmployeeEditOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return ColoredBox(
      color: const Color(0xFFF5F6F8),
      child: Obx(() {
        c.loadToken.value;
        c.dicts.length;
        c.hukouProvinceName.value;
        c.hukouCityName.value;
        c.hukouDistrictName.value;
        c.contacts.length;
        c.educations.length;
        c.workExperiences.length;
        c.contracts.length;
        c.files.length;
        c.selectedSkillTagIds.length;
        c.skillGroups.length;
        c.nations.length;
        c.officeLocations.length;
        final p = c.profile.value ?? HrmEmployeeProfile();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _WorkInfoCard(profile: p),
            _PersonalCard(
              profile: p,
              provinceName: c.hukouProvinceName.value,
              cityName: c.hukouCityName.value,
              districtName: c.hukouDistrictName.value,
            ),
            const _ContactCard(),
            const _ContractCard(),
            const _EducationCard(),
            const _WorkExpCard(),
            const _SkillCard(),
            const _MaterialCard(),
          ],
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.child,
    this.hint,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
              Icon(icon, size: 16, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppInkWell(
                onPressed: onEdit,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: _kPrimary),
                      SizedBox(width: 4),
                      Text(
                        '编辑',
                        style: TextStyle(fontSize: 13, color: _kPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WorkInfoCard extends StatelessWidget {
  const _WorkInfoCard({required this.profile});

  final HrmEmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final p = profile;
    final prefs = <String>[
      if (p.showMobile == 1) '公开手机号',
      if (p.showEmail == 1) '公开企业邮箱',
      if (p.showIm == 1) '公开 IM 账号',
      if (p.showOffice == 1) '公开办公地点',
      if (p.keepInDirectory == 1) '离职后保留在通讯录',
    ];
    return _SectionCard(
      icon: Icons.work_outline,
      title: '工作信息',
      onEdit: () => showWorkInfoDialog(context, c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KvGrid(
            columns: 5,
            items: [
              ('工号', _text(p.no)),
              ('员工类型', _typeLabel(p.empType)),
              ('员工状态', _statusLabel(p.empStatus)),
              ('转正状态', _conversionLabel(p.conversionStatus)),
              ('入职时间', _text(p.hireDate)),
              ('企业邮箱', _text(p.corpEmail)),
              ('办公电话', _text(p.officePhone)),
              ('办公地点', _officeLabel(c, p.officeLocation)),
              ('工位', _text(p.workstation)),
              ('出差态度', _tripLabel(p.businessTrip)),
              ('出差城市', _text(p.businessTripCity)),
              ('IM 账号', _text(p.imAccount)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '通讯录展示偏好',
            style: TextStyle(fontSize: 12, color: _kLabel),
          ),
          const SizedBox(height: 6),
          Text(
            prefs.isEmpty ? '--' : prefs.join('、'),
            style: const TextStyle(fontSize: 13, color: _kTitle),
          ),
        ],
      ),
    );
  }
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({
    required this.profile,
    required this.provinceName,
    required this.cityName,
    required this.districtName,
  });

  final HrmEmployeeProfile profile;
  final String provinceName;
  final String cityName;
  final String districtName;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final p = profile;
    return _SectionCard(
      icon: Icons.person_outline,
      title: '个人信息',
      onEdit: () => showPersonalInfoDialog(context, c),
      child: _KvGrid(
        columns: 5,
        items: [
          ('姓名', _text(p.name)),
          ('手机号', _text(p.mobile)),
          ('个人邮箱', _text(p.personalEmail)),
          ('拼音', _text(p.pinYin)),
          ('英文名', _text(p.englishName)),
          ('性别', _genderLabel(p.gender)),
          ('出生日期', _text(p.birthDate)),
          ('民族', _text(p.nation)),
          ('政治面貌', _text(p.politicalStatus)),
          ('婚姻状况', _maritalLabel(p.maritalStatus)),
          ('首次参加工作日期', _text(p.firstWorkDate)),
          ('社保账号', _text(p.socialSecurityAccount)),
          ('公积金账号', _text(p.housingFundAccount)),
          ('证件号码', _text(p.idCardNo)),
          ('现居住地', _text(p.residence)),
          (
            '户籍省',
            c.hukouText(name: provinceName, code: p.province),
          ),
          (
            '户籍市',
            c.hukouText(name: cityName, code: p.city),
          ),
          (
            '户籍区',
            c.hukouText(name: districtName, code: p.district),
          ),
          ('户籍详细地址', _text(p.householdAddress)),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return _SectionCard(
      icon: Icons.phone_outlined,
      title: '紧急联系人',
      hint: '最多可添加 3 位，第一位默认为主要联系人。',
      onEdit: () => showContactsDialog(context, c),
      child: c.contacts.isEmpty
          ? const _EmptyLine('暂无紧急联系人')
          : Column(
              children: [
                for (var i = 0; i < c.contacts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _RecordTitle(
                    icon: Icons.person_outline,
                    title: i == 0 ? '联系人 ${i + 1}（主要）' : '联系人 ${i + 1}',
                  ),
                  const SizedBox(height: 12),
                  _KvGrid(
                    columns: 5,
                    items: [
                      ('姓名', _text(c.contacts[i].name)),
                      (
                        '与本人关系',
                        c.dictLabel(
                          HrmDictTypes.contactRelation,
                          c.contacts[i].relation,
                        ),
                      ),
                      ('联系电话', _text(c.contacts[i].phone)),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return _SectionCard(
      icon: Icons.description_outlined,
      title: '合同与协议',
      hint: '员工合同信息，仅 HR / 本人可见；可添加多条。',
      onEdit: () => showContractsDialog(context, c),
      child: c.contracts.isEmpty
          ? const _EmptyLine('暂无合同')
          : Column(
              children: [
                for (var i = 0; i < c.contracts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _RecordTitle(
                    icon: Icons.description_outlined,
                    title: '合同 ${i + 1}',
                  ),
                  const SizedBox(height: 12),
                  _KvGrid(
                    columns: 5,
                    items: [
                      ('类型', _contractType(c.contracts[i].type)),
                      ('编号', _text(c.contracts[i].contractNo)),
                      ('签约主体', _text(c.contracts[i].signParty)),
                      ('生效日期', _day(c.contracts[i].effectiveDate)),
                      ('到期日期', _day(c.contracts[i].expireDate)),
                      ('签署日期', _day(c.contracts[i].signDate)),
                      ('附件', _text(c.contracts[i].attachmentName)),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return _SectionCard(
      icon: Icons.school_outlined,
      title: '教育背景',
      hint: '可填写多条教育经历',
      onEdit: () => showEducationsDialog(context, c),
      child: c.educations.isEmpty
          ? const _EmptyLine('暂无教育经历')
          : Column(
              children: [
                for (var i = 0; i < c.educations.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _RecordTitle(
                    icon: Icons.school_outlined,
                    title: '教育经历 ${i + 1}',
                  ),
                  const SizedBox(height: 12),
                  _KvGrid(
                    columns: 5,
                    items: [
                      ('开始日期', _day(c.educations[i].startDate)),
                      ('结束日期', _day(c.educations[i].endDate)),
                      ('毕业院校', _text(c.educations[i].school)),
                      ('专业', _text(c.educations[i].major)),
                      (
                        '学历',
                        c.dictLabel(
                          HrmDictTypes.education,
                          c.educations[i].degree,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _WorkExpCard extends StatelessWidget {
  const _WorkExpCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return _SectionCard(
      icon: Icons.business_center_outlined,
      title: '工作经历',
      hint: '入职前工作履历，可填写多条',
      onEdit: () => showWorkExperiencesDialog(context, c),
      child: c.workExperiences.isEmpty
          ? const _EmptyLine('暂无工作经历')
          : Column(
              children: [
                for (var i = 0; i < c.workExperiences.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _RecordTitle(
                    icon: Icons.business_center_outlined,
                    title: '工作经历 ${i + 1}',
                  ),
                  const SizedBox(height: 12),
                  _KvGrid(
                    columns: 5,
                    items: [
                      ('入职日期', _day(c.workExperiences[i].startDate)),
                      ('离职日期', _day(c.workExperiences[i].endDate)),
                      ('公司', _text(c.workExperiences[i].company)),
                      ('职位', _text(c.workExperiences[i].position)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '主要职责与成果',
                    style: TextStyle(fontSize: 12, color: _kLabel),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _text(c.workExperiences[i].duties),
                    style: const TextStyle(fontSize: 13, color: _kTitle, height: 1.5),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final names = <String>[];
    for (final group in c.skillGroups) {
      for (final tag in group.tags ?? const []) {
        final id = int.tryParse(tag.id ?? '') ?? 0;
        final name = tag.name?.trim() ?? '';
        if (id > 0 && name.isNotEmpty && c.selectedSkillTagIds.contains(id)) {
          names.add(name);
        }
      }
    }
    return _SectionCard(
      icon: Icons.local_offer_outlined,
      title: '广告传媒行业能力标签',
      hint: '用于项目排兵布阵与人才盘点',
      onEdit: () => showSkillsDialog(context, c),
      child: names.isEmpty
          ? const _EmptyLine('暂未选择能力标签')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in names)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF91CAFF)),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 12, color: _kPrimary),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return _SectionCard(
      icon: Icons.folder_outlined,
      title: '资料附件',
      hint: '身份证、学历等材料。',
      onEdit: () => showMaterialsDialog(context, c),
      child: c.files.isEmpty
          ? const _EmptyLine('暂无附件')
          : Column(
              children: [
                for (final item in c.files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 16,
                          color: _kMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fileTypeLabel(item.type),
                          style: const TextStyle(fontSize: 13, color: _kTitle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fileName(item.url),
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                          ),
                        ),
                        Text(
                          _fileTime(item.createTime),
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

class _RecordTitle extends StatelessWidget {
  const _RecordTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _kPrimary),
        const SizedBox(width: 6),
        Text(
          title,
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

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13, color: _kMuted));
  }
}

class _KvGrid extends StatelessWidget {
  const _KvGrid({required this.items, this.columns = 5});

  final List<(String, String)> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 720 ? 2 : columns;
        final gap = 16.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(fontSize: 12, color: _kLabel),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: const TextStyle(fontSize: 13, color: _kTitle),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

String _text(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return '--';
  if (s.length >= 10 && DateTime.tryParse(s) != null && s.contains('-')) {
    return s.substring(0, 10);
  }
  return s;
}

String _day(DateTime? value) {
  if (value == null) return '--';
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '${value.year}-$m-$d';
}

String _genderLabel(String? code) {
  switch (code?.trim()) {
    case '0':
      return '男';
    case '1':
      return '女';
    case '2':
      return '未知';
    default:
      return _text(code);
  }
}

String _maritalLabel(String? code) {
  switch (code?.trim()) {
    case '0':
      return '未婚';
    case '1':
      return '已婚';
    case '3':
      return '离异';
    case '9':
      return '其他';
    default:
      return _text(code);
  }
}

String _conversionLabel(String? code) {
  switch (code?.trim().toUpperCase()) {
    case 'NOT_REQUIRED':
      return '无需转正';
    case 'PENDING':
      return '待转正';
    case 'CONVERTED':
      return '已转正';
    default:
      return _text(code);
  }
}

String _tripLabel(String? code) {
  switch (code?.trim()) {
    case '1':
      return '可以';
    case '3':
      return '偶尔';
    case '0':
      return '不可以';
    default:
      return _text(code);
  }
}

String _statusLabel(String? code) {
  const extra = {
    'PENDING': '待入职',
    'PROBATION': '试用',
    'LEFT': '离职',
    'UNPAID_LEAVE': '停薪留职',
  };
  final raw = code?.trim() ?? '';
  if (raw.isEmpty) return '--';
  for (final o in EmployeeArchiveController.statusOptions) {
    if (o.$1 == raw) return o.$2;
  }
  return extra[raw] ?? raw;
}

String _typeLabel(String? code) {
  final raw = code?.trim() ?? '';
  if (raw.isEmpty) return '--';
  if (raw == 'FULL_TIME' || raw == 'EMPLOYEE') return '正式';
  for (final o in EmployeeArchiveController.typeOptions) {
    if (o.$1 == raw) return o.$2;
  }
  return raw;
}

String _contractType(String code) {
  switch (code.trim().toUpperCase()) {
    case 'LABOR':
      return '劳动合同';
    case 'INTERN':
      return '实习协议';
    case 'OUTSOURCE':
      return '外包协议';
    case 'OTHER':
      return '其他';
    default:
      return _text(code);
  }
}

String _fileTypeLabel(String? type) {
  final raw = type?.trim();
  if (raw == null || raw.isEmpty) return '附件';
  return raw;
}

String _fileName(String? url) {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) return '--';
  final path = raw.split('?').first;
  final slash = path.lastIndexOf('/');
  final name = slash >= 0 ? path.substring(slash + 1) : path;
  if (name.isEmpty) return raw;
  try {
    return Uri.decodeComponent(name);
  } catch (_) {
    return name;
  }
}

String _fileTime(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '';
  final text = value.replaceFirst('T', ' ');
  return text.length > 16 ? text.substring(0, 16) : text;
}

String _officeLabel(EmployeeEditController c, String? id) {
  final raw = id?.trim() ?? '';
  if (raw.isEmpty) return '--';
  for (final o in c.officeLocations) {
    if (o.id?.trim() == raw && o.name?.trim().isNotEmpty == true) {
      return o.name!.trim();
    }
  }
  return raw;
}
