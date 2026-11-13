import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../../models/dict_data.dart';
import '../../../../../models/hrm_employee_profile.dart';
import '../../employee_archive_controller.dart';
import '../employee_edit_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);

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

const _conversionOptions = <AppOption<String>>[
  AppOption(value: 'NOT_REQUIRED', label: '无需转正'),
  AppOption(value: 'PENDING', label: '待转正'),
  AppOption(value: 'CONVERTED', label: '已转正'),
];

const _tripOptions = <AppOption<String>>[
  AppOption(value: '1', label: '可以'),
  AppOption(value: '3', label: '偶尔'),
  AppOption(value: '0', label: '不可以'),
];

const _degreeFallbackOptions = <AppOption<String>>[
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

const _relationFallbackOptions = <AppOption<String>>[
  AppOption(value: '父母', label: '父母'),
  AppOption(value: '配偶', label: '配偶'),
  AppOption(value: '子女', label: '子女'),
  AppOption(value: '兄弟姐妹', label: '兄弟姐妹'),
  AppOption(value: '朋友', label: '朋友'),
  AppOption(value: '其他', label: '其他'),
];

void showWorkInfoDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _WorkInfoDialog());
}

void showPersonalInfoDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _PersonalInfoDialog());
}

void showContactsDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _ContactsDialog());
}

void showContractsDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _ContractsDialog());
}

void showEducationsDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _EducationsDialog());
}

void showWorkExperiencesDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _WorkExpDialog());
}

void showSkillsDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _SkillsDialog());
}

void showMaterialsDialog(BuildContext context, EmployeeEditController c) {
  _open(context, c, const _MaterialsDialog());
}

void _open(BuildContext context, EmployeeEditController c, Widget child) {
  showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => LxScope(
      bindings: (container) {
        container.putInstance<EmployeeEditController>(c, owned: false);
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: const Color(0xFF1677FF)),
        child: child,
      ),
    ),
  );
}

class _WorkInfoDialog extends StatefulWidget {
  const _WorkInfoDialog();

  @override
  State<_WorkInfoDialog> createState() => _WorkInfoDialogState();
}

class _WorkInfoDialogState extends State<_WorkInfoDialog> {
  final _form = AppFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final p = c.profile.value ?? HrmEmployeeProfile();
    return AppForm(
      controller: _form,
      child: _DialogChrome(
        title: '编辑工作信息',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () => _form.submit((values) => _save(context, c, values)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldGrid(
              children: [
                AppTextFormField(
                  name: 'no',
                  label: '工号',
                  required: true,
                  hintText: '请输入工号',
                  initialValue: p.no,
                  validator: _required,
                ),
                AppSelectFormField<String>(
                  name: 'empType',
                  label: '员工类型',
                  hintText: '请选择',
                  options: _typeOptions(p.empType),
                  initialValue: p.empType == 'FULL_TIME' || p.empType == 'EMPLOYEE'
                      ? 'FORMAL'
                      : _blank(p.empType),
                  clearable: true,
                ),
                AppSelectFormField<String>(
                  name: 'empStatus',
                  label: '员工状态',
                  hintText: '请选择',
                  options: _statusOptions(p.empStatus),
                  initialValue: _blank(p.empStatus),
                  enabled: false,
                ),
                AppSelectFormField<String>(
                  name: 'conversionStatus',
                  label: '转正状态',
                  hintText: '请选择',
                  options: _withCurrent(_conversionOptions, p.conversionStatus),
                  initialValue: _blank(p.conversionStatus),
                  enabled: false,
                ),
                AppDatePickerFormField(
                  name: 'hireDate',
                  label: '入职时间',
                  hintText: '请选择日期',
                  initialValue: _parseDate(p.hireDate),
                  enabled: false,
                ),
                AppTextFormField(
                  name: 'corpEmail',
                  label: '企业邮箱',
                  hintText: '请输入企业邮箱',
                  initialValue: p.corpEmail,
                ),
                AppTextFormField(
                  name: 'officePhone',
                  label: '办公电话',
                  hintText: '请输入办公电话',
                  initialValue: p.officePhone,
                ),
                AppSelectFormField<String>(
                  name: 'officeLocation',
                  label: '办公地点',
                  hintText: '请选择',
                  options: c.officeLocationOptions(),
                  initialValue: _blank(p.officeLocation),
                  clearable: true,
                ),
                AppTextFormField(
                  name: 'workstation',
                  label: '工位',
                  hintText: '请输入工位',
                  initialValue: p.workstation,
                ),
                AppSelectFormField<String>(
                  name: 'businessTrip',
                  label: '出差态度',
                  hintText: '请选择',
                  options: _withCurrent(_tripOptions, p.businessTrip),
                  initialValue: _blank(p.businessTrip),
                  clearable: true,
                ),
                AppTextFormField(
                  name: 'businessTripCity',
                  label: '出差城市',
                  hintText: '请输入出差城市',
                  initialValue: p.businessTripCity,
                ),
                AppTextFormField(
                  name: 'imAccount',
                  label: 'IM 账号',
                  hintText: '请输入 IM 账号',
                  initialValue: p.imAccount,
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '通讯录展示偏好',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 18,
                    runSpacing: 0,
                    children: [
                      AppCheckboxFormField(
                        name: 'showMobile',
                        controlLabel: const Text('公开手机号'),
                        initialValue: p.showMobile == 1,
                      ),
                      AppCheckboxFormField(
                        name: 'showEmail',
                        controlLabel: const Text('公开企业邮箱'),
                        initialValue: p.showEmail == 1,
                      ),
                      AppCheckboxFormField(
                        name: 'showIm',
                        controlLabel: const Text('公开 IM 账号'),
                        initialValue: p.showIm == 1,
                      ),
                      AppCheckboxFormField(
                        name: 'showOffice',
                        controlLabel: const Text('公开办公地点'),
                        initialValue: p.showOffice == 1,
                      ),
                      AppCheckboxFormField(
                        name: 'keepInDirectory',
                        controlLabel: const Text('离职后保留在通讯录'),
                        initialValue: p.keepInDirectory == 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    EmployeeEditController c,
    Map<String, dynamic> values,
  ) async {
    final next = Map<String, Object?>.from(c.collectValues());
    next['no'] = values['no'];
    next['empType'] = values['empType'];
    next['corpEmail'] = values['corpEmail'];
    next['officePhone'] = values['officePhone'];
    next['officeLocation'] = values['officeLocation'];
    next['workstation'] = values['workstation'];
    next['businessTrip'] = values['businessTrip'];
    next['businessTripCity'] = values['businessTripCity'];
    next['imAccount'] = values['imAccount'];
    next['showMobile'] = values['showMobile'] == true;
    next['showEmail'] = values['showEmail'] == true;
    next['showIm'] = values['showIm'] == true;
    next['showOffice'] = values['showOffice'] == true;
    next['keepInDirectory'] = values['keepInDirectory'] == true;
    await _commit(context, c, next);
  }
}

class _PersonalInfoDialog extends StatefulWidget {
  const _PersonalInfoDialog();

  @override
  State<_PersonalInfoDialog> createState() => _PersonalInfoDialogState();
}

class _PersonalInfoDialogState extends State<_PersonalInfoDialog> {
  final _form = AppFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final p = c.profile.value ?? HrmEmployeeProfile();
    return AppForm(
      controller: _form,
      child: _DialogChrome(
        title: '编辑个人信息',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () => _form.submit((values) => _save(context, c, values)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldGrid(
              children: [
                AppTextFormField(
                  name: 'name',
                  label: '姓名',
                  required: true,
                  hintText: '请输入姓名',
                  initialValue: p.name,
                  validator: _required,
                ),
                AppTextFormField(
                  name: 'mobile',
                  label: '手机号',
                  hintText: '请输入手机号',
                  initialValue: p.mobile,
                  readOnly: true,
                  enabled: false,
                ),
                AppTextFormField(
                  name: 'personalEmail',
                  label: '个人邮箱',
                  hintText: '请输入个人邮箱',
                  initialValue: p.personalEmail,
                ),
                AppTextFormField(
                  name: 'pinYin',
                  label: '拼音',
                  hintText: '请输入拼音',
                  initialValue: p.pinYin,
                ),
                AppTextFormField(
                  name: 'englishName',
                  label: '英文名',
                  hintText: '请输入英文名',
                  initialValue: p.englishName,
                ),
                AppSelectFormField<String>(
                  name: 'gender',
                  label: '性别',
                  hintText: '请选择',
                  options: _genderOptions,
                  initialValue: _blank(p.gender),
                  clearable: true,
                ),
                AppDatePickerFormField(
                  name: 'birthDate',
                  label: '出生日期',
                  hintText: '请选择日期',
                  initialValue: _parseDate(p.birthDate),
                ),
                AppSelectFormField<String>(
                  name: 'nation',
                  label: '民族',
                  hintText: '请选择',
                  options: c.nationOptions(),
                  initialValue: _blank(p.nation),
                  clearable: true,
                ),
                AppTextFormField(
                  name: 'politicalStatus',
                  label: '政治面貌',
                  hintText: '请输入政治面貌',
                  initialValue: p.politicalStatus,
                ),
                AppSelectFormField<String>(
                  name: 'maritalStatus',
                  label: '婚姻状况',
                  hintText: '请选择',
                  options: _withCurrent(_maritalOptions, p.maritalStatus),
                  initialValue: _blank(p.maritalStatus),
                  clearable: true,
                ),
                AppDatePickerFormField(
                  name: 'firstWorkDate',
                  label: '首次参加工作日期',
                  hintText: '请选择日期',
                  initialValue: _parseDate(p.firstWorkDate),
                ),
                AppTextFormField(
                  name: 'socialSecurityAccount',
                  label: '社保账号',
                  hintText: '请输入社保账号',
                  initialValue: p.socialSecurityAccount,
                ),
                AppTextFormField(
                  name: 'housingFundAccount',
                  label: '公积金账号',
                  hintText: '请输入公积金账号',
                  initialValue: p.housingFundAccount,
                ),
                AppTextFormField(
                  name: 'idCardNo',
                  label: '证件号码',
                  hintText: '请输入证件号码',
                  initialValue: p.idCardNo,
                ),
                AppTextFormField(
                  name: 'residence',
                  label: '现居住地',
                  hintText: '请输入现居住地',
                  initialValue: p.residence,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HukouFields(controller: c, initial: c.hukouInitialPath(p)),
            const SizedBox(height: 12),
            AppTextFormField(
              name: 'householdAddress',
              label: '户籍详细地址',
              hintText: '请输入户籍详细地址',
              initialValue: p.householdAddress,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    EmployeeEditController c,
    Map<String, dynamic> values,
  ) async {
    final next = Map<String, Object?>.from(c.collectValues());
    next['name'] = values['name'];
    next['personalEmail'] = values['personalEmail'];
    next['pinYin'] = values['pinYin'];
    next['englishName'] = values['englishName'];
    next['gender'] = values['gender'];
    next['birthDate'] = values['birthDate'];
    next['nation'] = values['nation'];
    next['politicalStatus'] = values['politicalStatus'];
    next['maritalStatus'] = values['maritalStatus'];
    next['firstWorkDate'] = values['firstWorkDate'];
    next['socialSecurityAccount'] = values['socialSecurityAccount'];
    next['housingFundAccount'] = values['housingFundAccount'];
    next['idCardNo'] = values['idCardNo'];
    next['residence'] = values['residence'];
    next['householdAddress'] = values['householdAddress'];
    next['hukouRegion'] = [
      for (final key in ['hukouProvince', 'hukouCity', 'hukouDistrict'])
        if (values[key]?.toString().trim().isNotEmpty == true)
          values[key].toString().trim(),
    ];
    await _commit(context, c, next);
  }
}

class _HukouFields extends StatefulWidget {
  const _HukouFields({required this.controller, required this.initial});

  final EmployeeEditController controller;
  final List<String> initial;

  @override
  State<_HukouFields> createState() => _HukouFieldsState();
}

class _HukouFieldsState extends State<_HukouFields> {
  var _ready = false;
  List<AppOption<String>> _provinces = const [];
  List<AppOption<String>> _cities = const [];
  List<AppOption<String>> _districts = const [];
  String? _province;
  String? _city;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _province = init.isNotEmpty ? init.first : null;
    _city = init.length > 1 ? init[1] : null;
    _load();
  }

  Future<void> _load() async {
    final provinces = await _options(AppRegionLevel.province, const []);
    List<AppOption<String>> cities = const [];
    List<AppOption<String>> districts = const [];
    final province = _province;
    if (province != null && province.isNotEmpty) {
      cities = await _options(AppRegionLevel.city, [province]);
    }
    final city = _city;
    if (province != null && city != null && city.isNotEmpty) {
      districts = await _options(AppRegionLevel.county, [province, city]);
    }
    if (!mounted) return;
    setState(() {
      _provinces = provinces;
      _cities = cities;
      _districts = districts;
      _ready = true;
    });
  }

  Future<List<AppOption<String>>> _options(
    AppRegionLevel level,
    List<String> path,
  ) async {
    final items = await widget.controller.loadRegionOptions(level, path);
    return [for (final e in items) AppOption(value: e.value, label: e.label)];
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final init = widget.initial;
    return _FieldGrid(
      columns: 3,
      children: [
        AppSelectFormField<String>(
          name: 'hukouProvince',
          label: '户籍省',
          hintText: '请选择省',
          options: _provinces,
          initialValue: init.isNotEmpty ? init.first : null,
          clearable: true,
          onChanged: (value) async {
            final cities = value == null || value.isEmpty
                ? const <AppOption<String>>[]
                : await _options(AppRegionLevel.city, [value]);
            if (!mounted) return;
            setState(() {
              _province = value;
              _city = null;
              _cities = cities;
              _districts = const [];
            });
          },
        ),
        AppSelectFormField<String>(
          key: ValueKey('city-$_province'),
          name: 'hukouCity',
          label: '户籍市',
          hintText: '请选择市',
          options: _cities,
          initialValue: _city,
          clearable: true,
          onChanged: (value) async {
            final province = _province;
            final districts = value == null ||
                    value.isEmpty ||
                    province == null ||
                    province.isEmpty
                ? const <AppOption<String>>[]
                : await _options(AppRegionLevel.county, [province, value]);
            if (!mounted) return;
            setState(() {
              _city = value;
              _districts = districts;
            });
          },
        ),
        AppSelectFormField<String>(
          key: ValueKey('district-$_province-$_city'),
          name: 'hukouDistrict',
          label: '户籍区',
          hintText: '请选择区',
          options: _districts,
          initialValue: init.length > 2 && _city == (init.length > 1 ? init[1] : null)
              ? init[2]
              : null,
          clearable: true,
        ),
      ],
    );
  }
}

class _ContactsDialog extends StatefulWidget {
  const _ContactsDialog();

  @override
  State<_ContactsDialog> createState() => _ContactsDialogState();
}

class _ContactsDialogState extends State<_ContactsDialog> {
  final _form = AppFormController();
  List<EmployeeContactDraft>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= [
      for (final e in context.lx.find<EmployeeEditController>().contacts)
        EmployeeContactDraft(localKey: e.localKey, id: e.id)
          ..name = e.name
          ..relation = e.relation
          ..phone = e.phone,
    ];
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final items = _items ?? const <EmployeeContactDraft>[];
    return AppForm(
      controller: _form,
      child: _DialogChrome(
        title: '编辑紧急联系人',
        hint: '最多可添加 3 位，第一位默认为主要联系人。',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () => _form.submit((values) => _save(context, c, values)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddButton(
              label: '添加联系人',
              enabled: items.length < 3,
              onPressed: () {
                setState(() {
                  _items!.add(EmployeeContactDraft(localKey: c.nextLocalKey()));
                });
              },
            ),
            for (var i = 0; i < items.length; i++) ...[
              const SizedBox(height: 14),
              _BlockTitle(
                title: i == 0 ? '联系人 ${i + 1}（主要）' : '联系人 ${i + 1}',
                onDelete: () => setState(() => _items!.removeAt(i)),
              ),
              const SizedBox(height: 10),
              _FieldGrid(
                columns: 3,
                children: [
                  AppTextFormField(
                    name: 'name_${items[i].localKey}',
                    label: '姓名',
                    required: true,
                    hintText: '请输入姓名',
                    initialValue: items[i].name,
                    validator: _required,
                  ),
                  AppSelectFormField<String>(
                    name: 'relation_${items[i].localKey}',
                    label: '与本人关系',
                    required: true,
                    hintText: '请选择',
                    options: _relationSelectOptions(c, items[i].relation),
                    initialValue: _blank(items[i].relation),
                    validator: _required,
                  ),
                  AppTextFormField(
                    name: 'phone_${items[i].localKey}',
                    label: '联系电话',
                    required: true,
                    hintText: '请输入联系电话',
                    initialValue: items[i].phone,
                    validator: _required,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    EmployeeEditController c,
    Map<String, dynamic> values,
  ) async {
    final next = <EmployeeContactDraft>[];
    for (final item in _items ?? const <EmployeeContactDraft>[]) {
      next.add(
        EmployeeContactDraft(localKey: item.localKey, id: item.id)
          ..name = _str(values['name_${item.localKey}'])
          ..relation = _str(values['relation_${item.localKey}'])
          ..phone = _str(values['phone_${item.localKey}']),
      );
    }
    await _commitList(
      context,
      c,
      apply: () {
        c.contacts
          ..clear()
          ..addAll(next);
        c.contacts.refresh();
      },
      restore: (backup) {
        c.contacts
          ..clear()
          ..addAll(backup);
        c.contacts.refresh();
      },
      backup: c.contacts.toList(),
    );
  }
}

class _ContractsDialog extends StatefulWidget {
  const _ContractsDialog();

  @override
  State<_ContractsDialog> createState() => _ContractsDialogState();
}

class _ContractsDialogState extends State<_ContractsDialog> {
  final _form = AppFormController();
  List<EmployeeContractDraft>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= [
      for (final e in context.lx.find<EmployeeEditController>().contracts)
        EmployeeContractDraft(localKey: e.localKey, id: e.id)
          ..type = e.type
          ..contractNo = e.contractNo
          ..signParty = e.signParty
          ..effectiveDate = e.effectiveDate
          ..expireDate = e.expireDate
          ..signDate = e.signDate
          ..attachmentName = e.attachmentName,
    ];
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final items = _items ?? const <EmployeeContractDraft>[];
    return AppForm(
      controller: _form,
      child: _DialogChrome(
        title: '编辑合同与协议',
        hint: '员工合同信息，仅 HR / 本人可见；可添加多条。',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () => _form.submit((values) => _save(context, c, values)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddButton(
              label: '添加合同',
              onPressed: () {
                setState(() {
                  _items!.add(EmployeeContractDraft(localKey: c.nextLocalKey()));
                });
              },
            ),
            for (var i = 0; i < items.length; i++) ...[
              const SizedBox(height: 14),
              _BlockTitle(
                title: '合同 ${i + 1}',
                onDelete: () => setState(() => _items!.removeAt(i)),
              ),
              const SizedBox(height: 10),
              _FieldGrid(
                columns: 3,
                children: [
                  AppSelectFormField<String>(
                    name: 'type_${items[i].localKey}',
                    label: '类型',
                    required: true,
                    hintText: '请选择',
                    options: _withCurrent(_contractTypeOptions, items[i].type),
                    initialValue: _blank(items[i].type),
                    validator: _required,
                  ),
                  AppTextFormField(
                    name: 'no_${items[i].localKey}',
                    label: '编号',
                    required: true,
                    hintText: '如 HT-2026-001',
                    initialValue: items[i].contractNo,
                    validator: _required,
                  ),
                  AppTextFormField(
                    name: 'party_${items[i].localKey}',
                    label: '签约主体',
                    required: true,
                    hintText: '请输入签约主体',
                    initialValue: items[i].signParty,
                    validator: _required,
                  ),
                  AppDatePickerFormField(
                    name: 'effective_${items[i].localKey}',
                    label: '生效日期',
                    hintText: '请选择日期',
                    initialValue: items[i].effectiveDate,
                  ),
                  AppDatePickerFormField(
                    name: 'expire_${items[i].localKey}',
                    label: '到期日期',
                    hintText: '请选择日期',
                    initialValue: items[i].expireDate,
                  ),
                  AppDatePickerFormField(
                    name: 'sign_${items[i].localKey}',
                    label: '签署日期',
                    hintText: '请选择日期',
                    initialValue: items[i].signDate,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _AddButton(
                  label: items[i].attachmentName.trim().isEmpty
                      ? '选取文件'
                      : items[i].attachmentName,
                  onPressed: () async {
                    final file = await FilePicker.pickFile(type: FileType.any);
                    final name = file?.name;
                    if (name == null || name.isEmpty || !mounted) return;
                    setState(() => _items![i].attachmentName = name);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    EmployeeEditController c,
    Map<String, dynamic> values,
  ) async {
    final next = <EmployeeContractDraft>[];
    for (final item in _items ?? const <EmployeeContractDraft>[]) {
      final key = item.localKey;
      next.add(
        EmployeeContractDraft(localKey: key, id: item.id)
          ..type = _str(values['type_$key'])
          ..contractNo = _str(values['no_$key'])
          ..signParty = _str(values['party_$key'])
          ..effectiveDate = values['effective_$key'] is DateTime
              ? values['effective_$key'] as DateTime
              : item.effectiveDate
          ..expireDate = values['expire_$key'] is DateTime
              ? values['expire_$key'] as DateTime
              : item.expireDate
          ..signDate = values['sign_$key'] is DateTime
              ? values['sign_$key'] as DateTime
              : item.signDate
          ..attachmentName = item.attachmentName,
      );
    }
    await _commitList(
      context,
      c,
      apply: () {
        c.contracts
          ..clear()
          ..addAll(next);
        c.contracts.refresh();
      },
      restore: (backup) {
        c.contracts
          ..clear()
          ..addAll(backup);
        c.contracts.refresh();
      },
      backup: c.contracts.toList(),
    );
  }
}

class _EducationsDialog extends StatefulWidget {
  const _EducationsDialog();

  @override
  State<_EducationsDialog> createState() => _EducationsDialogState();
}

class _EducationsDialogState extends State<_EducationsDialog> {
  final _form = AppFormController();
  List<EmployeeEduDraft>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= [
      for (final e in context.lx.find<EmployeeEditController>().educations)
        EmployeeEduDraft(localKey: e.localKey, id: e.id, isHighest: e.isHighest)
          ..startDate = e.startDate
          ..endDate = e.endDate
          ..school = e.school
          ..major = e.major
          ..degree = e.degree,
    ];
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final items = _items ?? const <EmployeeEduDraft>[];
    return AppForm(
      controller: _form,
      child: _DialogChrome(
        title: '编辑教育背景',
        hint: '可填写多条教育经历',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () => _form.submit((values) => _save(context, c, values)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddButton(
              label: '添加教育经历',
              onPressed: () {
                setState(() {
                  _items!.add(EmployeeEduDraft(localKey: c.nextLocalKey()));
                });
              },
            ),
            for (var i = 0; i < items.length; i++) ...[
              const SizedBox(height: 14),
              _BlockTitle(
                title: '教育经历 ${i + 1}',
                onDelete: () => setState(() => _items!.removeAt(i)),
              ),
              const SizedBox(height: 10),
              _FieldGrid(
                children: [
                  AppDatePickerFormField(
                    name: 'start_${items[i].localKey}',
                    label: '开始日期',
                    hintText: '请选择日期',
                    initialValue: items[i].startDate,
                  ),
                  AppDatePickerFormField(
                    name: 'end_${items[i].localKey}',
                    label: '结束日期',
                    hintText: '请选择日期',
                    initialValue: items[i].endDate,
                  ),
                  AppTextFormField(
                    name: 'school_${items[i].localKey}',
                    label: '毕业院校',
                    hintText: '请输入毕业院校',
                    initialValue: items[i].school,
                  ),
                  AppTextFormField(
                    name: 'major_${items[i].localKey}',
                    label: '专业',
                    hintText: '请输入专业',
                    initialValue: items[i].major,
                  ),
                  AppSelectFormField<String>(
                    name: 'degree_${items[i].localKey}',
                    label: '学历',
                    hintText: '请选择',
                    options: _degreeSelectOptions(c, items[i].degree),
                    initialValue: _blank(items[i].degree),
                    clearable: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    EmployeeEditController c,
    Map<String, dynamic> values,
  ) async {
    final next = <EmployeeEduDraft>[];
    for (final item in _items ?? const <EmployeeEduDraft>[]) {
      final key = item.localKey;
      next.add(
        EmployeeEduDraft(localKey: key, id: item.id, isHighest: item.isHighest)
          ..school = _str(values['school_$key'])
          ..major = _str(values['major_$key'])
          ..degree = _str(values['degree_$key'])
          ..startDate = values['start_$key'] is DateTime
              ? values['start_$key'] as DateTime
              : null
          ..endDate = values['end_$key'] is DateTime
              ? values['end_$key'] as DateTime
              : null,
      );
    }
    await _commitList(
      context,
      c,
      apply: () {
        c.educations
          ..clear()
          ..addAll(next);
        c.educations.refresh();
      },
      restore: (backup) {
        c.educations
          ..clear()
          ..addAll(backup);
        c.educations.refresh();
      },
      backup: c.educations.toList(),
    );
  }
}

class _WorkExpDialog extends StatefulWidget {
  const _WorkExpDialog();

  @override
  State<_WorkExpDialog> createState() => _WorkExpDialogState();
}

class _WorkExpDialogState extends State<_WorkExpDialog> {
  final _form = AppFormController();
  List<EmployeeWorkDraft>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??= [
      for (final e in context.lx.find<EmployeeEditController>().workExperiences)
        EmployeeWorkDraft(localKey: e.localKey, id: e.id)
          ..startDate = e.startDate
          ..endDate = e.endDate
          ..company = e.company
          ..position = e.position
          ..duties = e.duties,
    ];
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final items = _items ?? const <EmployeeWorkDraft>[];
    return AppForm(
      controller: _form,
      child: _DialogChrome(
        title: '编辑工作经历',
        hint: '入职前工作履历，可填写多条',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () => _form.submit((values) => _save(context, c, values)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddButton(
              label: '添加工作经历',
              onPressed: () {
                setState(() {
                  _items!.add(EmployeeWorkDraft(localKey: c.nextLocalKey()));
                });
              },
            ),
            for (var i = 0; i < items.length; i++) ...[
              const SizedBox(height: 14),
              _BlockTitle(
                title: '工作经历 ${i + 1}',
                onDelete: () => setState(() => _items!.removeAt(i)),
              ),
              const SizedBox(height: 10),
              _FieldGrid(
                children: [
                  AppDatePickerFormField(
                    name: 'start_${items[i].localKey}',
                    label: '入职日期',
                    hintText: '请选择日期',
                    initialValue: items[i].startDate,
                  ),
                  AppDatePickerFormField(
                    name: 'end_${items[i].localKey}',
                    label: '离职日期',
                    hintText: '请选择日期',
                    initialValue: items[i].endDate,
                  ),
                  AppTextFormField(
                    name: 'company_${items[i].localKey}',
                    label: '公司',
                    hintText: '请输入公司',
                    initialValue: items[i].company,
                  ),
                  AppTextFormField(
                    name: 'position_${items[i].localKey}',
                    label: '职位',
                    hintText: '请输入职位',
                    initialValue: items[i].position,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextAreaFormField(
                name: 'duties_${items[i].localKey}',
                label: '主要职责与成果',
                hintText: '请输入主要职责与成果',
                initialValue: items[i].duties,
                minHeight: 88,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    EmployeeEditController c,
    Map<String, dynamic> values,
  ) async {
    final next = <EmployeeWorkDraft>[];
    for (final item in _items ?? const <EmployeeWorkDraft>[]) {
      final key = item.localKey;
      next.add(
        EmployeeWorkDraft(localKey: key, id: item.id)
          ..company = _str(values['company_$key'])
          ..position = _str(values['position_$key'])
          ..duties = _str(values['duties_$key'])
          ..startDate = values['start_$key'] is DateTime
              ? values['start_$key'] as DateTime
              : null
          ..endDate = values['end_$key'] is DateTime
              ? values['end_$key'] as DateTime
              : null,
      );
    }
    await _commitList(
      context,
      c,
      apply: () {
        c.workExperiences
          ..clear()
          ..addAll(next);
        c.workExperiences.refresh();
      },
      restore: (backup) {
        c.workExperiences
          ..clear()
          ..addAll(backup);
        c.workExperiences.refresh();
      },
      backup: c.workExperiences.toList(),
    );
  }
}

class _SkillsDialog extends StatefulWidget {
  const _SkillsDialog();

  @override
  State<_SkillsDialog> createState() => _SkillsDialogState();
}

class _SkillsDialogState extends State<_SkillsDialog> {
  Set<int>? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= {
      ...context.lx.find<EmployeeEditController>().selectedSkillTagIds,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    final selected = _selected ?? const <int>{};
    return _DialogChrome(
      title: '编辑能力标签',
      hint: '用于项目排兵布阵与人才盘点',
      onCancel: () => Navigator.of(context).pop(),
      onSave: () => _save(context, c),
      body: c.skillGroups.isEmpty
          ? const Text('暂无能力标签', style: TextStyle(fontSize: 13, color: _kMuted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in c.skillGroups) ...[
                  Text(
                    group.name?.trim().isNotEmpty == true
                        ? group.name!.trim()
                        : '未命名分组',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in group.tags ?? const [])
                        if ((int.tryParse(tag.id ?? '') ?? 0) > 0 &&
                            tag.name?.trim().isNotEmpty == true)
                          _SkillChip(
                            label: tag.name!.trim(),
                            selected: selected.contains(int.parse(tag.id!)),
                            onTap: () {
                              final id = int.parse(tag.id!);
                              setState(() {
                                if (!_selected!.add(id)) _selected!.remove(id);
                              });
                            },
                          ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }

  Future<void> _save(BuildContext context, EmployeeEditController c) async {
    try {
      await c.saveSkills(_selected ?? const <int>{});
      if (!context.mounted) return;
      AppToast.show(context: context, title: '保存成功');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context: context, title: e.toString());
    }
  }
}

class _MaterialsDialog extends StatelessWidget {
  const _MaterialsDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeEditController>();
    return Obx(() {
      final items = c.files.toList();
      return _DialogChrome(
        title: '编辑资料附件',
        hint: '已入库附件。上传与删除接口尚未提供，这里只展示列表。',
        onCancel: () => Navigator.of(context).pop(),
        onSave: () async => Navigator.of(context).pop(),
        body: items.isEmpty
            ? const Text(
                '暂无附件',
                style: TextStyle(fontSize: 13, color: _kMuted),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
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
    });
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

class _DialogChrome extends StatelessWidget {
  const _DialogChrome({
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onSave,
    this.hint,
  });

  final String title;
  final String? hint;
  final Widget body;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return HyperDialog(
      title: Text(title),
      scrollable: true,
      style: const HyperDialogStyle(maxWidth: 980),
      onClose: onCancel,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                hint!,
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ),
          body,
        ],
      ),
      actions: [
        HyperButton.outlined(
          onPressed: onCancel,
          label: const Text('取消'),
        ),
        HyperButton.filled(
          onPressed: () async {
            await onSave();
          },
          label: const Text('保存'),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: AppInkWell(
          onPressed: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kPrimary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: _kPrimary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 13, color: _kPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.title, required this.onDelete});

  final String title;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        const Spacer(),
        AppInkWell(
          onPressed: onDelete,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '删除',
              style: TextStyle(fontSize: 12, color: Color(0xFFFF4D4F)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onTap,
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
            color: selected ? _kPrimary : _kTitle,
          ),
        ),
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children, this.columns = 4});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final cols = constraints.maxWidth < 720 ? 2 : columns;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

Future<void> _commit(
  BuildContext context,
  EmployeeEditController c,
  Map<String, Object?> values,
) async {
  try {
    await c.save(values);
    if (!context.mounted) return;
    AppToast.show(context: context, title: '保存成功');
    Navigator.of(context).pop();
  } catch (e) {
    if (!context.mounted) return;
    AppToast.show(context: context, title: e.toString());
  }
}

Future<void> _commitList<T>(
  BuildContext context,
  EmployeeEditController c, {
  required void Function() apply,
  required void Function(List<T> backup) restore,
  required List<T> backup,
}) async {
  apply();
  try {
    await c.save(c.collectValues());
    if (!context.mounted) return;
    AppToast.show(context: context, title: '保存成功');
    Navigator.of(context).pop();
  } catch (e) {
    restore(backup);
    if (!context.mounted) return;
    AppToast.show(context: context, title: e.toString());
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return '不可为空';
  return null;
}

String? _blank(String? value) {
  final s = value?.trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

String _str(Object? value) => value?.toString().trim() ?? '';

DateTime? _parseDate(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

List<AppOption<String>> _withCurrent(
  List<AppOption<String>> base,
  String? current,
) {
  final value = current?.trim();
  if (value == null || value.isEmpty) return base;
  if (base.any((e) => e.value == value)) return base;
  return [AppOption(value: value, label: value), ...base];
}

List<AppOption<String>> _relationSelectOptions(
  EmployeeEditController c,
  String? current,
) {
  final fromDict = c.dictOptions(
    HrmDictTypes.contactRelation,
    current: current,
  );
  if (fromDict.isNotEmpty) return fromDict;
  return _withCurrent(_relationFallbackOptions, current);
}

List<AppOption<String>> _degreeSelectOptions(
  EmployeeEditController c,
  String? current,
) {
  final fromDict = c.dictOptions(HrmDictTypes.education, current: current);
  if (fromDict.isNotEmpty) return fromDict;
  return _withCurrent(_degreeFallbackOptions, current);
}

List<AppOption<String>> _statusOptions(String? current) {
  return _withCurrent(
    [
      for (final o in EmployeeArchiveController.statusOptions)
        AppOption(value: o.$1, label: o.$2),
      const AppOption(value: 'PROBATION', label: '试用'),
      const AppOption(value: 'UNPAID_LEAVE', label: '停薪留职'),
    ],
    current,
  );
}

List<AppOption<String>> _typeOptions(String? current) {
  final mapped = current == 'FULL_TIME' || current == 'EMPLOYEE'
      ? 'FORMAL'
      : current;
  return _withCurrent(
    [
      for (final o in EmployeeArchiveController.typeOptions)
        AppOption(value: o.$1, label: o.$2),
    ],
    mapped,
  );
}
