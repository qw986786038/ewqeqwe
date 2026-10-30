import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import 'employee_edit_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kSubTitle = Color(0xFF4E5969);
const _kDanger = Color(0xFFFF4D4F);

const _genderOptions = <AppOption<String>>[
  AppOption(value: '0', label: '男'),
  AppOption(value: '1', label: '女'),
  AppOption(value: '2', label: '未知'),
];

const _maritalOptions = <AppOption<String>>[
  AppOption(value: '0', label: '未婚'),
  AppOption(value: '1', label: '已婚'),
  AppOption(value: '3', label: '离异'),
  AppOption(value: '9', label: '其他'),
];

const _languageOptions = <AppOption<String>>[
  AppOption(value: 'zh', label: '中文'),
  AppOption(value: 'en', label: '英语'),
  AppOption(value: 'ja', label: '日语'),
  AppOption(value: 'ko', label: '韩语'),
];

const _tripOptions = <AppOption<String>>[
  AppOption(value: '1', label: '可以'),
  AppOption(value: '3', label: '偶尔可以'),
  AppOption(value: '0', label: '不方便'),
];

const _overtimeOptions = <AppOption<String>>[
  AppOption(value: '1', label: '可加班'),
  AppOption(value: '3', label: '视情况而定'),
  AppOption(value: '0', label: '不可加班'),
];

const _degreeOptions = <AppOption<String>>[
  AppOption(value: '大专', label: '大专'),
  AppOption(value: '本科', label: '本科'),
  AppOption(value: '硕士', label: '硕士'),
  AppOption(value: '博士', label: '博士'),
  AppOption(value: '其他', label: '其他'),
];

const _contractTypeOptions = <AppOption<String>>[
  AppOption(value: 'LABOR', label: '劳动合同'),
  AppOption(value: 'INTERN', label: '实习协议'),
  AppOption(value: 'OUTSOURCE', label: '外包协议'),
  AppOption(value: 'OTHER', label: '其他'),
];

/// 人事档案 · 修改信息（长滚动编辑页）。
class EmployeeEditPage extends StatelessWidget {
  const EmployeeEditPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _Body(onBack: onBack);
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return ColoredBox(
      color: _kPageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                AppInkWell(
                  onPressed: onBack,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 18, color: _kSubTitle),
                        SizedBox(width: 4),
                        Text(
                          '返回列表',
                          style: TextStyle(fontSize: 13, color: _kSubTitle),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() {
                  final p = c.profile.value;
                  final String title;
                  if (c.isCreate) {
                    title = '新增员工';
                  } else if (p?.name?.trim().isNotEmpty == true) {
                    title = '修改信息 · ${p!.name!.trim()}';
                  } else {
                    title = '修改信息';
                  }
                  return Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.loading.value && !c.loaded.value) {
                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }
              if (c.errorMessage.value != null && !c.loaded.value) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.errorMessage.value!,
                        style: const TextStyle(fontSize: 13, color: _kMuted),
                      ),
                      const SizedBox(height: 12),
                      AppButton.outline(
                        onPressed: c.load,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }
              return _EditForm(onBack: onBack);
            }),
          ),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final p = c.profile.value;
    if (p == null) {
      return const Center(child: Text('暂无员工数据', style: TextStyle(color: _kMuted)));
    }
    final token = c.loadToken.value;
    return AppForm(
      key: ValueKey('employee_edit_form_$token'),
      controller: c.form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: AppFieldScope.horizontal(
                labelWidth: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    _SectionCard(
                      title: '基础身份信息',
                      children: [
                        const _SubSectionTitle('身份标识'),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'name',
                            label: '姓名',
                            required: true,
                            hintText: '请输入姓名',
                            initialValue: p.name,
                            validator: AppValidators.required(message: '不可为空'),
                          ),
                          right: AppTextFormField(
                            name: 'no',
                            label: '工号',
                            required: true,
                            hintText: '请输入工号',
                            initialValue: p.no,
                            validator: AppValidators.required(message: '不可为空'),
                          ),
                        ),
                        _TwoCol(
                          left: AppSelectFormField<String>(
                            name: 'gender',
                            label: '性别',
                            hintText: '请选择',
                            options: _genderOptions,
                            initialValue: p.gender,
                            clearable: true,
                          ),
                          right: AppDatePickerFormField(
                            name: 'birthDate',
                            label: '出生日期',
                            hintText: '请选择日期',
                            initialValue: _parseDate(p.birthDate),
                          ),
                        ),
                        const _SubSectionTitle('姓名别称'),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'pinYin',
                            label: '拼音',
                            hintText: '请输入拼音',
                            initialValue: p.pinYin,
                          ),
                          right: AppTextFormField(
                            name: 'englishName',
                            label: '英文名',
                            hintText: '请输入英文名',
                            initialValue: p.englishName,
                          ),
                        ),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'aliasName',
                            label: '花名',
                            hintText: '请输入花名',
                            initialValue: p.aliasName,
                          ),
                          right: AppSelectFormField<String>(
                            name: 'commonLanguage',
                            label: '常用语言',
                            hintText: '请选择',
                            options: _languageOptions,
                            initialValue: p.commonLanguage,
                            clearable: true,
                          ),
                        ),
                        const _SubSectionTitle('证件与人口属性'),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'idCardNo',
                            label: '身份证号',
                            hintText: '请输入身份证号',
                            initialValue: p.idCardNo,
                          ),
                          right: AppSelectFormField<String>(
                            name: 'nation',
                            label: '民族',
                            hintText: '请选择民族',
                            options: c.nationOptions(),
                            initialValue: p.nation,
                            clearable: true,
                          ),
                        ),
                        AppSelectFormField<String>(
                          name: 'maritalStatus',
                          label: '婚姻状况',
                          hintText: '请选择',
                          options: _maritalOptions,
                          initialValue: p.maritalStatus,
                          clearable: true,
                        ),
                        const _SubSectionTitle('联系方式'),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'mobile',
                            label: '手机',
                            required: true,
                            hintText: '请输入手机号',
                            initialValue: p.mobile,
                            validator: AppValidators.required(message: '不可为空'),
                          ),
                          right: AppTextFormField(
                            name: 'corpEmail',
                            label: '企业邮箱',
                            hintText: '请输入企业邮箱',
                            initialValue: p.corpEmail,
                          ),
                        ),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'personalEmail',
                            label: '个人邮箱',
                            hintText: '请输入个人邮箱',
                            initialValue: p.personalEmail,
                          ),
                          right: AppTextFormField(
                            name: 'imAccount',
                            label: 'IM',
                            hintText: '请输入 IM 账号',
                            initialValue: p.imAccount,
                          ),
                        ),
                        const _SubSectionTitle('办公信息'),
                        _TwoCol(
                          left: AppSelectFormField<String>(
                            name: 'officeLocation',
                            label: '办公地点',
                            hintText: '请选择',
                            options: c.officeLocationOptions(),
                            initialValue: p.officeLocation,
                            clearable: true,
                          ),
                          right: AppTextFormField(
                            name: 'workstation',
                            label: '工位',
                            hintText: '请输入工位',
                            initialValue: p.workstation,
                          ),
                        ),
                        _TwoCol(
                          left: AppTextFormField(
                            name: 'officePhone',
                            label: '办公电话',
                            hintText: '请输入办公电话',
                            initialValue: p.officePhone,
                          ),
                          right: AppTextFormField(
                            name: 'officeExt',
                            label: '分机',
                            hintText: '请输入分机号',
                            initialValue: p.officeExt,
                          ),
                        ),
                        const _SubSectionTitle('户籍地址'),
                        AppRegionPickerFormField<String>.async(
                          name: 'hukouRegion',
                          label: '省 / 市 / 区',
                          initialValue: c.hukouInitialPath(p),
                          loadOptions: c.loadRegionOptions,
                        ),
                        AppTextAreaFormField(
                          name: 'householdAddress',
                          label: '详细地址',
                          hintText: '请输入户籍详细地址',
                          initialValue: p.householdAddress,
                          minHeight: 64,
                        ),
                        const _SubSectionTitle('通讯录展示偏好'),
                        Wrap(
                          spacing: 20,
                          runSpacing: 4,
                          children: [
                            AppCheckboxFormField(
                              name: 'showMobile',
                              controlLabel: const Text('展示手机'),
                              initialValue:
                                  EmployeeEditController.checkboxFromInt(p.showMobile),
                            ),
                            AppCheckboxFormField(
                              name: 'showEmail',
                              controlLabel: const Text('展示邮箱'),
                              initialValue:
                                  EmployeeEditController.checkboxFromInt(p.showEmail),
                            ),
                            AppCheckboxFormField(
                              name: 'showIm',
                              controlLabel: const Text('展示 IM'),
                              initialValue:
                                  EmployeeEditController.checkboxFromInt(p.showIm),
                            ),
                            AppCheckboxFormField(
                              name: 'showOffice',
                              controlLabel: const Text('展示办公电话'),
                              initialValue:
                                  EmployeeEditController.checkboxFromInt(p.showOffice),
                            ),
                            AppCheckboxFormField(
                              name: 'keepInDirectory',
                              controlLabel: const Text('保留在通讯录'),
                              initialValue: EmployeeEditController.checkboxFromInt(
                                p.keepInDirectory,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _SectionCard(
                      title: '任职',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Text(
                                '一名员工仅能有一个主岗，可有多个兼职。',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            AppButton.primary(
                              onPressed: c.addAssign,
                              leading: const Icon(Icons.add, size: 16),
                              child: const Text('添加任职'),
                            ),
                          ],
                        ),
                        Obx(() {
                          final items = c.assigns.toList();
                          if (items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '暂无任职记录',
                                style: TextStyle(fontSize: 12, color: _kMuted),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              for (var i = 0; i < items.length; i++)
                                _AssignBlock(
                                  index: i + 1,
                                  item: items[i],
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                    _SectionCard(
                      title: '紧急联系人',
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            final full = c.contacts.length >= 3;
                            return AppButton.primary(
                              onPressed: full ? null : c.addContact,
                              leading: const Icon(Icons.add, size: 16),
                              child: Text(full ? '已达上限 3 位' : '添加联系人'),
                            );
                          }),
                        ),
                        Obx(() {
                          final items = c.contacts.toList();
                          if (items.isEmpty) {
                            return const Text(
                              '暂无紧急联系人',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              for (final item in items)
                                _ContactBlock(item: item),
                            ],
                          );
                        }),
                      ],
                    ),
                    _SectionCard(
                      title: '合同与协议',
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.primary(
                            onPressed: c.addContract,
                            leading: const Icon(Icons.add, size: 16),
                            child: const Text('添加合同'),
                          ),
                        ),
                        Obx(() {
                          final items = c.contracts.toList();
                          if (items.isEmpty) {
                            return const Text(
                              '暂无合同',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              for (final item in items)
                                _ContractBlock(item: item),
                            ],
                          );
                        }),
                      ],
                    ),
                    _SectionCard(
                      title: '教育背景',
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.primary(
                            onPressed: c.addEducation,
                            leading: const Icon(Icons.add, size: 16),
                            child: const Text('添加教育经历'),
                          ),
                        ),
                        Obx(() {
                          final items = c.educations.toList();
                          if (items.isEmpty) {
                            return const Text(
                              '暂无教育经历',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              for (final item in items)
                                _EducationBlock(item: item),
                            ],
                          );
                        }),
                      ],
                    ),
                    _SectionCard(
                      title: '工作经历',
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.primary(
                            onPressed: c.addWorkExperience,
                            leading: const Icon(Icons.add, size: 16),
                            child: const Text('添加工作经历'),
                          ),
                        ),
                        Obx(() {
                          final items = c.workExperiences.toList();
                          if (items.isEmpty) {
                            return const Text(
                              '暂无工作经历',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              for (final item in items) _WorkBlock(item: item),
                            ],
                          );
                        }),
                      ],
                    ),
                    _SectionCard(
                      title: '广告传媒行业能力标签',
                      children: [
                        Obx(() {
                          final groups = c.skillGroups.toList();
                          if (groups.isEmpty) {
                            return const Text(
                              '暂无能力标签分组',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 16,
                            children: [
                              for (final g in groups) ...[
                                if (g.name?.trim().isNotEmpty == true)
                                  Text(
                                    g.name!.trim(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _kSubTitle,
                                    ),
                                  ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in g.tags ?? const [])
                                      if (tag.id != null && tag.name != null)
                                        _SkillChip(
                                          tagId: int.tryParse(tag.id!) ?? 0,
                                          label: tag.name!,
                                        ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        }),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          name: 'dispatchCity',
                          label: '可外派城市',
                          hintText: '请输入可外派城市',
                          initialValue: p.dispatchCity,
                        ),
                        _TwoCol(
                          left: AppSelectFormField<String>(
                            name: 'businessTrip',
                            label: '可出差',
                            hintText: '请选择',
                            options: _tripOptions,
                            initialValue: p.businessTrip,
                            clearable: true,
                          ),
                          right: AppSelectFormField<String>(
                            name: 'overtime',
                            label: '加班偏好',
                            hintText: '请选择',
                            options: _overtimeOptions,
                            initialValue: p.overtime?.toString(),
                            clearable: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Obx(() {
                final saving = c.saving.value;
                return AppButton.primary(
                  loading: saving,
                  loadingLabel: '保存中…',
                  onPressed: saving
                      ? null
                      : () async {
                          await c.form.submit((values) async {
                            try {
                              await c.save(values);
                              if (!context.mounted) return;
                              AppToast.show(
                                context: context,
                                title: c.isCreate ? '新增成功' : '保存成功',
                              );
                              if (c.isCreate) onBack();
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.show(
                                  context: context,
                                  title: e.toString(),
                                );
                              }
                            }
                          });
                        },
                  child: Text(c.isCreate ? '提交' : '保存'),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
        spacing: 12,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SubSectionTitle extends StatelessWidget {
  const _SubSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _kSubTitle,
        ),
      ),
    );
  }
}

class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _ThreeCol extends StatelessWidget {
  const _ThreeCol({
    required this.left,
    required this.mid,
    required this.right,
  });

  final Widget left;
  final Widget mid;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: mid),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _AssignBlock extends StatelessWidget {
  const _AssignBlock({required this.index, required this.item});

  final int index;
  final EmployeeAssignDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final title = item.isPrimary ? '任职 $index（主岗）' : '任职 $index（兼职）';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: _kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2129),
                  ),
                ),
              ),
              AppButton.text(
                onPressed: () => c.removeAssign(item.localKey),
                child: const Text(
                  '删除',
                  style: TextStyle(color: _kDanger),
                ),
              ),
            ],
          ),
          _ThreeCol(
            left: AppSelectFormField<bool>(
              name: 'assign_primary_${item.localKey}',
              label: '主岗 / 兼职',
              required: true,
              hintText: '请选择',
              options: const [
                AppOption(value: true, label: '主岗'),
                AppOption(value: false, label: '兼职'),
              ],
              initialValue: item.isPrimary,
              onChanged: (v) {
                if (v == null) return;
                item.isPrimary = v;
                if (item.isPrimary) {
                  for (final a in c.assigns) {
                    if (a.localKey != item.localKey) a.isPrimary = false;
                  }
                }
                c.assigns.refresh();
              },
            ),
            mid: AppSelectFormField<String>(
              name: 'assign_dept_${item.localKey}',
              label: '所属部门',
              required: true,
              hintText: '请选择部门',
              options: c.deptOptions(),
              initialValue: item.deptId,
              onChanged: (v) {
                item.deptId = v;
                item.positionId = null;
                c.assigns.refresh();
              },
            ),
            right: AppSelectFormField<String>(
              name: 'assign_post_${item.localKey}',
              label: '当前岗位',
              required: true,
              hintText: '请选择岗位',
              options: c.postOptions(),
              initialValue: item.postId,
              onChanged: (v) => item.postId = v,
            ),
          ),
          _ThreeCol(
            left: AppSelectFormField<String>(
              name: 'assign_seq_${item.localKey}',
              label: '岗位序列',
              hintText: '请选择',
              options: c.postSeqOptions(),
              initialValue: item.postSeqId,
              onChanged: (v) {
                item.postSeqId = v;
                item.postSeqLevelId = null;
                c.assigns.refresh();
              },
            ),
            mid: KeyedSubtree(
              key: ValueKey(
                'assign-level-${item.localKey}-${item.postSeqId}-'
                '${item.postSeqLevelId}',
              ),
              child: AppSelectFormField<String>(
                name: 'assign_level_${item.localKey}',
                label: '职级',
                required: true,
                hintText: '请选择',
                options: c.postSeqLevelOptions(item.postSeqId),
                initialValue: item.postSeqLevelId,
                onChanged: (v) => item.postSeqLevelId = v,
              ),
            ),
            right: KeyedSubtree(
              key: ValueKey(
                'assign-seat-${item.localKey}-${item.deptId}-'
                '${item.positionId}',
              ),
              child: AppSelectFormField<String>(
                name: 'assign_position_${item.localKey}',
                label: '席位',
                required: true,
                hintText: '请选择席位',
                options: c.positionOptions(item.deptId),
                initialValue: item.positionId,
                onChanged: (v) {
                  c.applyPositionToAssign(item, v);
                  c.assigns.refresh();
                },
              ),
            ),
          ),
          KeyedSubtree(
            key: ValueKey(
              'assign-report-${item.localKey}-${item.positionId}-'
              '${item.reportTo}-${item.dottedReport}',
            ),
            child: _ThreeCol(
              left: AppTextFormField(
                name: 'assign_report_${item.localKey}',
                label: '汇报对象',
                readOnly: true,
                enabled: false,
                hintText: '由席位自动带出',
                initialValue: item.reportTo == '由席位自动带出'
                    ? null
                    : item.reportTo,
              ),
              mid: AppTextFormField(
                name: 'assign_dotted_${item.localKey}',
                label: '虚线汇报对象',
                readOnly: true,
                enabled: false,
                hintText: '由席位自动带出',
                initialValue: item.dottedReport == '由席位自动带出'
                    ? null
                    : item.dottedReport,
              ),
              right: AppDatePickerFormField(
                name: 'assign_start_${item.localKey}',
                label: '任职开始日期',
                required: true,
                hintText: '请选择日期',
                initialValue: item.startDate,
                onChanged: (v) => item.startDate = v,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.item});

  final EmployeeContactDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              onPressed: () => c.removeContact(item.localKey),
              child: const Text('删除', style: TextStyle(color: _kDanger)),
            ),
          ),
          AppTextFormField(
            name: 'contact_name_${item.localKey}',
            label: '姓名',
            required: true,
            hintText: '请输入姓名',
            initialValue: item.name,
            onChanged: (v) => item.name = v,
            validator: AppValidators.required(message: '不可为空'),
          ),
          _TwoCol(
            left: AppTextFormField(
              name: 'contact_relation_${item.localKey}',
              label: '关系',
              required: true,
              hintText: '请输入关系',
              initialValue: item.relation,
              onChanged: (v) => item.relation = v,
              validator: AppValidators.required(message: '不可为空'),
            ),
            right: AppTextFormField(
              name: 'contact_phone_${item.localKey}',
              label: '电话',
              required: true,
              hintText: '请输入电话',
              initialValue: item.phone,
              onChanged: (v) => item.phone = v,
              validator: AppValidators.required(message: '不可为空'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractBlock extends StatelessWidget {
  const _ContractBlock({required this.item});

  final EmployeeContractDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              onPressed: () => c.removeContract(item.localKey),
              child: const Text('删除', style: TextStyle(color: _kDanger)),
            ),
          ),
          _TwoCol(
            left: AppSelectFormField<String>(
              name: 'contract_type_${item.localKey}',
              label: '类型',
              required: true,
              hintText: '请选择',
              options: _contractTypeOptions,
              initialValue: item.type.isEmpty ? null : item.type,
              onChanged: (v) => item.type = v ?? '',
              validator: (v) =>
                  (v == null || v.isEmpty) ? '请选择合同类型' : null,
            ),
            right: AppTextFormField(
              name: 'contract_no_${item.localKey}',
              label: '编号',
              required: true,
              hintText: '请输入合同编号',
              initialValue: item.contractNo,
              onChanged: (v) => item.contractNo = v,
              validator: AppValidators.required(message: '不可为空'),
            ),
          ),
          AppTextFormField(
            name: 'contract_party_${item.localKey}',
            label: '签约主体',
            required: true,
            hintText: '请输入签约主体',
            initialValue: item.signParty,
            onChanged: (v) => item.signParty = v,
            validator: AppValidators.required(message: '不可为空'),
          ),
          _TwoCol(
            left: AppDatePickerFormField(
              name: 'contract_effective_${item.localKey}',
              label: '生效日期',
              hintText: '请选择日期',
              initialValue: item.effectiveDate,
              onChanged: (v) => item.effectiveDate = v,
            ),
            right: AppDatePickerFormField(
              name: 'contract_expire_${item.localKey}',
              label: '到期日期',
              hintText: '请选择日期',
              initialValue: item.expireDate,
              onChanged: (v) => item.expireDate = v,
            ),
          ),
          _TwoCol(
            left: AppDatePickerFormField(
              name: 'contract_sign_${item.localKey}',
              label: '签署日期',
              hintText: '请选择日期',
              initialValue: item.signDate,
              onChanged: (v) => item.signDate = v,
            ),
            right: Obx(() {
              final name = c.contracts
                      .firstWhere((e) => e.localKey == item.localKey)
                      .attachmentName
                      .trim()
                      .isEmpty
                  ? '未选择文件'
                  : c.contracts
                      .firstWhere((e) => e.localKey == item.localKey)
                      .attachmentName;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextFormField(
                      key: ValueKey('contract_file_${item.localKey}_$name'),
                      name: 'contract_file_${item.localKey}',
                      label: '附件',
                      readOnly: true,
                      enabled: false,
                      initialValue: name,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton.outline(
                    onPressed: () {
                      c.pickContractFile(
                        item.localKey,
                        '合同附件_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      );
                      AppToast.show(context: context, title: '附件选取待接入');
                    },
                    child: const Text('选取文件'),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EducationBlock extends StatelessWidget {
  const _EducationBlock({required this.item});

  final EmployeeEduDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            children: [
              if (item.isHighest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '最高学历',
                    style: TextStyle(fontSize: 12, color: _kPrimary),
                  ),
                ),
              const Spacer(),
              if (!item.isHighest)
                AppButton.text(
                  onPressed: () => c.markHighestEducation(item.localKey),
                  child: const Text('设为最高学历'),
                ),
              AppButton.text(
                onPressed: () => c.removeEducation(item.localKey),
                child: const Text('删除', style: TextStyle(color: _kDanger)),
              ),
            ],
          ),
          _TwoCol(
            left: AppDatePickerFormField(
              name: 'edu_start_${item.localKey}',
              label: '开始日期',
              hintText: '请选择日期',
              initialValue: item.startDate,
              onChanged: (v) => item.startDate = v,
            ),
            right: AppDatePickerFormField(
              name: 'edu_end_${item.localKey}',
              label: '结束日期',
              hintText: '请选择日期',
              initialValue: item.endDate,
              onChanged: (v) => item.endDate = v,
            ),
          ),
          AppTextFormField(
            name: 'edu_school_${item.localKey}',
            label: '院校',
            hintText: '请输入院校',
            initialValue: item.school,
            onChanged: (v) => item.school = v,
          ),
          _TwoCol(
            left: AppTextFormField(
              name: 'edu_major_${item.localKey}',
              label: '专业',
              hintText: '请输入专业',
              initialValue: item.major,
              onChanged: (v) => item.major = v,
            ),
            right: AppSelectFormField<String>(
              name: 'edu_degree_${item.localKey}',
              label: '学历',
              hintText: '请选择',
              options: _degreeOptions,
              initialValue: item.degree.isEmpty ? null : item.degree,
              onChanged: (v) => item.degree = v ?? '',
              clearable: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkBlock extends StatelessWidget {
  const _WorkBlock({required this.item});

  final EmployeeWorkDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              onPressed: () => c.removeWorkExperience(item.localKey),
              child: const Text('删除', style: TextStyle(color: _kDanger)),
            ),
          ),
          _TwoCol(
            left: AppDatePickerFormField(
              name: 'work_start_${item.localKey}',
              label: '入职日期',
              hintText: '请选择日期',
              initialValue: item.startDate,
              onChanged: (v) => item.startDate = v,
            ),
            right: AppDatePickerFormField(
              name: 'work_end_${item.localKey}',
              label: '离职日期',
              hintText: '请选择日期',
              initialValue: item.endDate,
              onChanged: (v) => item.endDate = v,
            ),
          ),
          _TwoCol(
            left: AppTextFormField(
              name: 'work_company_${item.localKey}',
              label: '公司',
              hintText: '请输入公司名称',
              initialValue: item.company,
              onChanged: (v) => item.company = v,
            ),
            right: AppTextFormField(
              name: 'work_position_${item.localKey}',
              label: '职位',
              hintText: '请输入职位',
              initialValue: item.position,
              onChanged: (v) => item.position = v,
            ),
          ),
          AppTextAreaFormField(
            name: 'work_duties_${item.localKey}',
            label: '主要职责',
            hintText: '请输入主要职责与成果',
            initialValue: item.duties,
            minHeight: 72,
            onChanged: (v) => item.duties = v,
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.tagId, required this.label});

  final int tagId;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return Obx(() {
      final selected = c.isSkillSelected(tagId);
      return AppInkWell(
        onPressed: tagId <= 0 ? null : () => c.toggleSkill(tagId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F4FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _kPrimary : _kBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? _kPrimary : _kSubTitle,
            ),
          ),
        ),
      );
    });
  }
}
