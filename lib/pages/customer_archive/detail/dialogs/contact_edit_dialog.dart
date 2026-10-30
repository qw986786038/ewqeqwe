import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:pinyin/pinyin.dart';

import '../../../../models/ad_code.dart';
import '../../../../models/dict_data.dart';
import '../../../../services/ad_code_api.dart';
import '../../../../services/customer_api.dart';
import '../../../../services/dict_api.dart';
import '../../dialogs/contact_vcf_import_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kTitle = Color(0xFF1D2129);
const _kBorder = Color(0xFFE5E6EB);
const _kSectionBar = Color(0xFF1677FF);
const _kEmptyBg = Color(0xFFF5F6F8);

const _kGenderOptions = [
  AppOption(value: '1', label: '男'),
  AppOption(value: '2', label: '女'),
];

/// 联系人详情「编辑」→ 编辑该联系人弹窗。
Future<bool> showContactEditDialog(
  BuildContext context, {
  required Map<String, dynamic> contact,
  bool isNew = false,
  int? contactOrdinal,
}) async {
  final hostContext = context;
  final result = await AppDialog.show<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _ContactEditDialog(
        contact: contact,
        isNew: isNew,
        contactOrdinal: contactOrdinal,
        onClose: (saved) => AppOverlay.close<bool>(dialogContext, saved),
        hostContext: hostContext,
      ),
    ),
  ).future;
  return result == true;
}

class _RelatedPersonDraft {
  _RelatedPersonDraft(this.id);
  final int id;
}

class _ContactEditDialog extends StatefulWidget {
  const _ContactEditDialog({
    required this.contact,
    required this.onClose,
    required this.hostContext,
    this.isNew = false,
    this.contactOrdinal,
  });

  final Map<String, dynamic> contact;
  final bool isNew;
  final int? contactOrdinal;
  final void Function(bool saved) onClose;
  final BuildContext hostContext;

  @override
  State<_ContactEditDialog> createState() => _ContactEditDialogState();
}

class _ContactEditDialogState extends State<_ContactEditDialog> {
  final _form = AppFormController();
  final _api = CustomerApi();
  final _dictApi = DictApi();
  final _adCodeApi = AdCodeApi();

  final _initials = <String, Object?>{};
  var _bootLoading = true;
  var _saving = false;
  var _nextId = 1;
  var _formEpoch = 0;

  List<AppOption<String>> _marketScopeOptions = const [];
  List<AppOption<String>> _tenureOptions = const [];
  List<AppOption<String>> _provinceOptions = const [];
  List<AppOption<String>> _cityOptions = const [];
  List<AppOption<String>> _enterpriseOptions = const [];
  List<AppOption<String>> _brandOptions = const [];

  final _superiors = <_RelatedPersonDraft>[];
  final _subordinates = <_RelatedPersonDraft>[];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  String? _asTrimmed(dynamic v) {
    final t = v?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }

  void _putInit(String key, dynamic value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    if (value is List && value.isEmpty) return;
    _initials[key] = value;
  }

  String? _initStr(String key) {
    final v = _initials[key];
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  List<String>? _initList(String key) {
    final v = _initials[key];
    if (v is List) {
      return [
        for (final e in v)
          if (e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
    }
    final s = _asTrimmed(v);
    if (s == null) return null;
    return s
        .split(RegExp(r'[,，；;、]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _optionValueByLabel(
    List<AppOption<String>> options,
    String? labelOrValue,
  ) {
    final raw = labelOrValue?.trim() ?? '';
    if (raw.isEmpty) return null;
    for (final o in options) {
      if (o.value == raw || o.label == raw) return o.value;
    }
    return raw;
  }

  List<String> _optionValuesByLabels(
    List<AppOption<String>> options,
    dynamic raw,
  ) {
    final parts = <String>[];
    if (raw is List) {
      for (final e in raw) {
        final t = e.toString().trim();
        if (t.isNotEmpty) parts.add(t);
      }
    } else {
      final s = _asTrimmed(raw);
      if (s != null) {
        parts.addAll(
          s
              .split(RegExp(r'[,，；;、]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );
      }
    }
    return [
      for (final p in parts) _optionValueByLabel(options, p) ?? p,
    ];
  }

  Future<void> _bootstrap() async {
    setState(() => _bootLoading = true);
    try {
      final results = await Future.wait([
        _dictApi.fetchMany(const [
          OacDictTypes.marketScope,
          OacDictTypes.tenure,
        ]),
        _adCodeApi.fetchChildren(),
      ]);
      final maps = results[0] as Map<String, List<DictDataItem>>;
      final provinces = results[1] as List<AdCodeItem>;

      List<AppOption<String>> opts(String type) {
        final list = maps[type] ?? const <DictDataItem>[];
        return [
          for (final d in list)
            if ((d.dictValue ?? d.dictLabel ?? '').trim().isNotEmpty)
              AppOption(
                value: (d.dictValue ?? d.dictLabel)!.trim(),
                label: (d.dictLabel ?? d.dictValue)!.trim(),
              ),
        ];
      }

      _marketScopeOptions = opts(OacDictTypes.marketScope);
      _tenureOptions = opts(OacDictTypes.tenure);
      _provinceOptions = [
        for (final p in provinces)
          if (p.code != null && (p.chName ?? '').trim().isNotEmpty)
            AppOption(
              value: '${p.code}',
              label: p.chName!.trim(),
            ),
      ];

      _hydrateFromContact();
      await _resolveCityFromContact();
    } catch (e) {
      if (widget.hostContext.mounted) {
        AppToast.show(context: widget.hostContext, title: '$e');
      }
    } finally {
      if (mounted) setState(() => _bootLoading = false);
    }
  }

  void _hydrateFromContact() {
    final c = widget.contact;
    final careers = c['careers'];
    Map<String, dynamic>? career;
    if (careers is List && careers.isNotEmpty && careers.first is Map) {
      career = Map<String, dynamic>.from(careers.first as Map);
    }

    final enterpriseOpts = <AppOption<String>>[];
    final brandOpts = <AppOption<String>>{};
    final seenEnt = <String>{};
    void addEnterprise(String? id, String? full) {
      final label = full?.trim() ?? '';
      final value = (id?.trim().isNotEmpty == true ? id!.trim() : label);
      if (label.isEmpty || value.isEmpty || !seenEnt.add(value)) return;
      enterpriseOpts.add(AppOption(value: value, label: label));
    }

    if (careers is List) {
      for (final e in careers) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        addEnterprise(
          _asTrimmed(m['enterpriseId']),
          _asTrimmed(m['enterpriseFullName']) ?? _asTrimmed(m['name']),
        );
        for (final key in const ['relatedBrands', 'responsibleBrands']) {
          final raw = _asTrimmed(m[key]);
          if (raw == null) continue;
          for (final part in raw.split(RegExp(r'[,，；;、]+'))) {
            final t = part.trim();
            if (t.isNotEmpty) brandOpts.add(AppOption(value: t, label: t));
          }
        }
      }
    }
    final enterprises = c['enterprises'];
    if (enterprises is List) {
      for (final e in enterprises) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        addEnterprise(
          _asTrimmed(m['id']),
          _asTrimmed(m['fullName']) ?? _asTrimmed(m['name']),
        );
      }
    }
    _enterpriseOptions = enterpriseOpts;
    _brandOptions = brandOpts.toList();

    _putInit('nameZh', c['name']);
    _putInit('nameEn', c['nameEn']);
    final genderLabel = _asTrimmed(c['genderLabel']);
    final genderRaw = _asTrimmed(c['gender']);
    if (genderLabel == '男' || genderRaw == '1') {
      _putInit('gender', '1');
    } else if (genderLabel == '女' || genderRaw == '2') {
      _putInit('gender', '2');
    } else {
      _putInit('gender', genderRaw);
    }
    _putInit('age', c['ageDesc']);
    final relatedEnt = _asTrimmed(c['relatedEnterprise']) ??
        _asTrimmed(c['orgName']);
    String? enterpriseInit = _asTrimmed(career?['enterpriseId']) ??
        _asTrimmed(career?['enterpriseFullName']) ??
        relatedEnt;
    if (enterpriseInit != null) {
      enterpriseInit =
          _optionValueByLabel(_enterpriseOptions, enterpriseInit) ??
              enterpriseInit;
    }
    _putInit('enterprise', enterpriseInit);
    _putInit('address', c['address'] ?? career?['address']);
    _putInit('title', career?['deptTitle'] ?? c['deptTitle']);
    _putInit('role', career?['jobDesc'] ?? c['jobDesc']);
    _putInit(
      'scope',
      _optionValuesByLabels(
        _marketScopeOptions,
        career?['marketScope'] ?? c['marketScope'],
      ),
    );
    _putInit(
      'brands',
      _optionValuesByLabels(
        _brandOptions,
        career?['responsibleBrands'] ?? c['responsibleBrands'],
      ),
    );
    _putInit(
      'tenure',
      _optionValueByLabel(_tenureOptions, c['tenure']?.toString()),
    );
    _putInit('mobile', c['phones']);
    _putInit('phone', c['tel'] ?? c['phone']);
    _putInit('email', c['emails']);
    _putInit('remark', c['remark']);
  }

  Future<void> _resolveCityFromContact() async {
    final cityText = _asTrimmed(widget.contact['city']) ??
        _asTrimmed(
          (widget.contact['careers'] is List &&
                  (widget.contact['careers'] as List).isNotEmpty &&
                  (widget.contact['careers'] as List).first is Map)
              ? ((widget.contact['careers'] as List).first
                  as Map)['city']
              : null,
        );
    if (cityText == null) return;

    String? matchedProvinceCode;
    String? matchedProvinceLabel;
    for (final o in _provinceOptions) {
      if (cityText.startsWith(o.label) || cityText.contains(o.label)) {
        matchedProvinceCode = o.value;
        matchedProvinceLabel = o.label;
        break;
      }
    }
    if (matchedProvinceCode == null) return;
    _putInit('province', matchedProvinceCode);

    final parentCode = int.tryParse(matchedProvinceCode);
    if (parentCode == null) return;
    try {
      final cities =
          await _adCodeApi.fetchChildren(parentCode: parentCode);
      _cityOptions = [
        for (final c in cities)
          if (c.code != null && (c.chName ?? '').trim().isNotEmpty)
            AppOption(
              value: '${c.code}',
              label: c.chName!.trim(),
            ),
      ];
      final rest = matchedProvinceLabel == null
          ? cityText
          : cityText.replaceFirst(matchedProvinceLabel, '').trim();
      for (final o in _cityOptions) {
        if (rest == o.label ||
            rest.contains(o.label) ||
            cityText.contains(o.label)) {
          _putInit('city', o.value);
          break;
        }
      }
    } catch (_) {}
  }

  Future<void> _onProvinceChanged(String? code) async {
    _cityOptions = const [];
    _initials.remove('city');
    _formEpoch++;
    setState(() {});
    final raw = code?.trim() ?? '';
    final parentCode = int.tryParse(raw);
    if (parentCode == null) return;
    try {
      final cities = await _adCodeApi.fetchChildren(parentCode: parentCode);
      if (!mounted) return;
      setState(() {
        _cityOptions = [
          for (final item in cities)
            if (item.code != null && (item.chName ?? '').trim().isNotEmpty)
              AppOption(
                value: '${item.code}',
                label: item.chName!.trim(),
              ),
        ];
        _formEpoch++;
      });
    } catch (e) {
      if (widget.hostContext.mounted) {
        AppToast.show(context: widget.hostContext, title: '$e');
      }
    }
  }

  Future<void> _importVcf() async {
    final list = await showContactVcfImportDialog(context);
    if (list == null || list.isEmpty || !mounted) return;
    // 编辑单联系人：仅取文件中首位。
    final parsed = list.first;
    void put(String key, String? v) {
      final t = v?.trim();
      if (t == null || t.isEmpty) return;
      _initials[key] = t;
    }

    final nameZh = parsed.nameZh?.trim();
    var nameEn = parsed.nameEn?.trim();
    if ((nameEn == null || nameEn.isEmpty) &&
        nameZh != null &&
        nameZh.isNotEmpty) {
      final py = _chineseToEnglishName(nameZh);
      if (py.isNotEmpty) nameEn = py;
    }
    put('nameZh', nameZh);
    put('nameEn', nameEn);
    put('gender', parsed.gender);
    put('mobile', parsed.mobile);
    put('phone', parsed.phone);
    put('email', parsed.email);
    put('address', parsed.address);
    put('title', parsed.title);
    put('role', parsed.role);
    put('remark', parsed.remark);
    if (parsed.org != null && parsed.org!.trim().isNotEmpty) {
      final org = parsed.org!.trim();
      if (!_enterpriseOptions.any((o) => o.value == org || o.label == org)) {
        _enterpriseOptions = [
          ..._enterpriseOptions,
          AppOption(value: org, label: org),
        ];
      }
      _putInit('enterprise', org);
    }
    setState(() => _formEpoch++);
    if (list.length > 1 && mounted) {
      AppToast.show(
        context: context,
        title: '已填充首位联系人（文件共 ${list.length} 位，编辑页仅支持一位）',
      );
    }
  }

  String _chineseToEnglishName(String zh) {
    final raw = PinyinHelper.getPinyinE(
      zh.trim(),
      separator: ' ',
      format: PinyinFormat.WITHOUT_TONE,
    ).trim();
    if (raw.isEmpty) return '';
    return raw
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
          final lower = w.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String? _labelOf(List<AppOption<String>> options, dynamic value) {
    final v = value?.toString().trim() ?? '';
    if (v.isEmpty) return null;
    for (final o in options) {
      if (o.value == v) return o.label;
    }
    return v;
  }

  /// 档案接口常用英文逗号拼接（市场范围 / 负责品牌）。
  String? _joinCsv(List<AppOption<String>> options, dynamic value) {
    final list = <String>[];
    if (value is List) {
      for (final e in value) {
        final l = _labelOf(options, e);
        if (l != null) list.add(l);
      }
    } else {
      final l = _labelOf(options, value);
      if (l != null) list.add(l);
    }
    return list.isEmpty ? null : list.join(',');
  }

  Map<String, dynamic> _buildRelated(
    Map<String, Object?> values,
    String prefix, {
    Map<String, dynamic>? existing,
  }) {
    final city = [
      _labelOf(_provinceOptions, values['${prefix}_province']) ?? '',
      _labelOf(_cityOptions, values['${prefix}_city']) ?? '',
    ].where((e) => e.isNotEmpty).join();
    return {
      if (existing != null) ...existing,
      'name': _asTrimmed(values['${prefix}_nameZh']),
      'nameEn': _asTrimmed(values['${prefix}_nameEn']),
      'gender': _asTrimmed(values['${prefix}_gender']),
      'ageDesc': _asTrimmed(values['${prefix}_age']),
      'phones': _asTrimmed(values['${prefix}_mobile']),
      'tel': _asTrimmed(values['${prefix}_phone']),
      'emails': _asTrimmed(values['${prefix}_email']),
      'address': _asTrimmed(values['${prefix}_address']),
      'deptTitle': _asTrimmed(values['${prefix}_title']),
      'jobDesc': _asTrimmed(values['${prefix}_role']),
      'remark': _asTrimmed(values['${prefix}_remark']),
      'city': city.isEmpty ? null : city,
      'marketScope':
          _joinCsv(_marketScopeOptions, values['${prefix}_scope']),
      'responsibleBrands':
          _joinCsv(_brandOptions, values['${prefix}_brands']),
      // 在职时间提交字典值（如 LT_3Y）。
      'tenure': _asTrimmed(values['${prefix}_tenure']),
      'superiors': existing?['superiors'] ?? const [],
      'subordinates': existing?['subordinates'] ?? const [],
      'enterpriseId': existing?['enterpriseId'],
    };
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ok = await _form.submit((values) async {
        final c = widget.contact;
        final contactId = c['id']?.toString().trim() ?? '';
        final customerId = c['customerId']?.toString().trim() ?? '';
        if (!widget.isNew && contactId.isEmpty) {
          throw CustomerApiException('缺少联系人 ID');
        }
        if (customerId.isEmpty) {
          throw CustomerApiException('缺少客户档案 ID');
        }

        final provinceLabel = _labelOf(_provinceOptions, values['province']);
        final cityLabel = _labelOf(_cityOptions, values['city']);
        final cityCombined = [
          if (provinceLabel != null && provinceLabel.isNotEmpty) provinceLabel,
          if (cityLabel != null && cityLabel.isNotEmpty) cityLabel,
        ].join();

        final enterpriseVal = _asTrimmed(values['enterprise']);
        String? enterpriseFull;
        String? enterpriseId;
        for (final o in _enterpriseOptions) {
          if (o.value == enterpriseVal) {
            enterpriseFull = o.label;
            enterpriseId = o.value;
            break;
          }
        }
        enterpriseFull ??= enterpriseVal;
        enterpriseId ??= enterpriseVal;

        // 更新走整包客户档案 PUT /desktop/oac/customer。
        final customer = await _api.fetchCustomerDetail(customerId);
        final list = customer['contacts'];
        final contacts = <Map<String, dynamic>>[
          if (list is List)
            for (final e in list)
              if (e is Map) Map<String, dynamic>.from(e),
        ];

        Map<String, dynamic>? existing;
        if (!widget.isNew) {
          for (final e in contacts) {
            if (e['id']?.toString().trim() == contactId) {
              existing = e;
              break;
            }
          }
          existing ??= <String, dynamic>{'id': contactId};
        } else {
          existing = <String, dynamic>{};
        }

        final patched = <String, dynamic>{
          ...existing,
          if (!widget.isNew) 'id': contactId,
          'name': _asTrimmed(values['nameZh']),
          'nameEn': _asTrimmed(values['nameEn']),
          'gender': _asTrimmed(values['gender']),
          'ageDesc': _asTrimmed(values['age']),
          'relatedEnterprise': enterpriseFull,
          'orgName': enterpriseFull,
          'enterpriseId': existing['enterpriseId'] ?? enterpriseId,
          'city': cityCombined.isEmpty ? null : cityCombined,
          'address': _asTrimmed(values['address']),
          'deptTitle': _asTrimmed(values['title']),
          'title': _asTrimmed(values['title']),
          'jobDesc': _asTrimmed(values['role']),
          'marketScope': _joinCsv(_marketScopeOptions, values['scope']),
          'responsibleBrands': _joinCsv(_brandOptions, values['brands']),
          'phones': _asTrimmed(values['mobile']),
          'phone': _asTrimmed(values['mobile']),
          'tel': _asTrimmed(values['phone']),
          'emails': _asTrimmed(values['email']),
          'email': _asTrimmed(values['email']),
          'tenure': _asTrimmed(values['tenure']),
          'remark': _asTrimmed(values['remark']),
          'superiors': [
            for (final s in _superiors)
              _buildRelated(values, 'sup_${s.id}'),
          ],
          'subordinates': [
            for (final s in _subordinates)
              _buildRelated(values, 'sub_${s.id}'),
          ],
        };

        if (widget.isNew) {
          customer['contacts'] = [...contacts, patched];
        } else {
          customer['contacts'] = [
            for (final e in contacts)
              if (e['id']?.toString().trim() == contactId) patched else e,
            if (!contacts.any((e) => e['id']?.toString().trim() == contactId))
              patched,
          ];
        }
        customer['id'] = customerId;
        await _api.updateCustomer(customer);
      });
      if (!ok || !mounted) return;
      widget.onClose(true);
      if (widget.hostContext.mounted) {
        AppToast.show(context: widget.hostContext, title: '保存成功');
      }
    } catch (e) {
      if (widget.hostContext.mounted) {
        AppToast.show(context: widget.hostContext, title: '$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewH = MediaQuery.sizeOf(context).height;
    final viewW = MediaQuery.sizeOf(context).width;
    final dialogMaxH = viewH * 0.9;
    final contentH = (dialogMaxH - 110).clamp(240.0, 640.0);
    // 与 quick_create 一致：最小 720，保证三列/省市区半列不低于 AppSelect 默认 minWidth:160。
    final dialogW = viewW > 1000 ? 860.0 : (viewW * 0.92).clamp(720.0, 860.0);
    final ordinal = widget.contactOrdinal ?? 1;
    return AppForm(
      controller: _form,
      child: AppFormDialog(
        title: Text(widget.isNew ? '联系人信息' : '编辑客户档案'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        constraints: BoxConstraints(
          minWidth: dialogW,
          maxWidth: dialogW,
          maxHeight: dialogMaxH,
        ),
        trailing: AppInkWell(
          onPressed: () => widget.onClose(false),
          child: const Icon(Icons.close, size: 18, color: _kMuted),
        ),
        actions: [
          AppButton.primary(
            onPressed: (_saving || _bootLoading) ? null : _submit,
            loadingLabel: '保存中',
            child: const Text('确定'),
          ),
          AppButton.outline(
            onPressed: _saving ? null : () => widget.onClose(false),
            child: const Text('取消'),
          ),
        ],
        // AppFormDialog 内容区偶发横向无界；钉死宽度，避免 Row+Expanded /
        // AppSelect 默认 minWidth:160 在窄列里右侧溢出。
        content: SizedBox(
          height: contentH,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentW =
                  constraints.maxWidth.isFinite && constraints.maxWidth > 0
                      ? constraints.maxWidth
                      : dialogW - 36;
              if (_bootLoading) {
                return SizedBox(
                  width: contentW,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return SingleChildScrollView(
                child: SizedBox(
                  width: contentW,
                  child: KeyedSubtree(
                    key: ValueKey('contact-edit-$_formEpoch'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.isNew) ...[
                          Row(
                            children: [
                              Text(
                                '联系人 $ordinal',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTitle,
                                ),
                              ),
                              const Spacer(),
                              AppInkWell(
                                onPressed: () => widget.onClose(false),
                                child: const Text(
                                  '删除联系人',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFFF4D4F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              AppInkWell(
                                onPressed: _importVcf,
                                child: const Text(
                                  '上传 VCF',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _kPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _sectionHeader(title: '基本信息'),
                        ] else ...[
                          const Row(
                            children: [
                              SizedBox(
                                width: 3,
                                height: 14,
                                child: ColoredBox(color: _kSectionBar),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '该联系人',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _sectionHeader(
                            title: '基本信息',
                            trailing: AppInkWell(
                              onPressed: _importVcf,
                              child: const Text(
                                '上传 VCF',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        ..._basicFields(prefix: '', requiredName: true),
                        const SizedBox(height: 18),
                        _sectionHeader(
                          title: '上级信息',
                          trailing: AppInkWell(
                            onPressed: () {
                              setState(() {
                                _superiors.add(
                                  _RelatedPersonDraft(_nextId++),
                                );
                              });
                            },
                            child: const Text(
                              '+ 添加',
                              style: TextStyle(
                                fontSize: 13,
                                color: _kPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_superiors.isEmpty)
                          _emptyHint('可添加多条，字段同基本信息')
                        else
                          for (var i = 0; i < _superiors.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _relatedBlock(
                              title: '上级 ${i + 1}',
                              prefix: 'sup_${_superiors[i].id}',
                              onDelete: () {
                                setState(() => _superiors.removeAt(i));
                              },
                            ),
                          ],
                        const SizedBox(height: 18),
                        _sectionHeader(
                          title: '下级信息',
                          trailing: AppInkWell(
                            onPressed: () {
                              setState(() {
                                _subordinates.add(
                                  _RelatedPersonDraft(_nextId++),
                                );
                              });
                            },
                            child: const Text(
                              '+ 添加',
                              style: TextStyle(
                                fontSize: 13,
                                color: _kPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_subordinates.isEmpty)
                          _emptyHint('可添加多条，字段同基本信息')
                        else
                          for (var i = 0; i < _subordinates.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _relatedBlock(
                              title: '下级 ${i + 1}',
                              prefix: 'sub_${_subordinates[i].id}',
                              onDelete: () {
                                setState(() => _subordinates.removeAt(i));
                              },
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({required String title, Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: _kEmptyBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: _kMuted),
      ),
    );
  }

  Widget _relatedBlock({
    required String title,
    required String prefix,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                child: const Text(
                  '删除',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFF4D4F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._basicFields(prefix: '${prefix}_', requiredName: false),
        ],
      ),
    );
  }

  List<Widget> _basicFields({
    required String prefix,
    required bool requiredName,
  }) {
    // 与 quick_create 联系人表单同构：两列/三列均分，避免半列再嵌套把
    // AppSelect（默认 minWidth:160）挤到 ~117px 从而右侧溢出约 43px。
    Widget row(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        );

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextFormField(
              name: '${prefix}nameZh',
              label: '姓名',
              required: requiredName,
              density: AppDensity.compact,
              hintText: '中文姓名',
              initialValue: _initStr('${prefix}nameZh'),
              validator: requiredName
                  ? AppValidators.required(message: '请输入姓名')
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextFormField(
              name: '${prefix}nameEn',
              label: 'Name',
              density: AppDensity.compact,
              hintText: 'English name',
              initialValue: _initStr('${prefix}nameEn'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppSelectFormField<String>(
              name: '${prefix}gender',
              label: '性别',
              hintText: '请选择',
              options: _kGenderOptions,
              clearable: true,
              minWidth: 0,
              initialValue: _initStr('${prefix}gender'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      row(
        AppTextFormField(
          name: '${prefix}age',
          label: '年龄段',
          density: AppDensity.compact,
          hintText: '如：约为35岁左右，即1990年左右',
          initialValue: _initStr('${prefix}age'),
        ),
        AppSelectFormField<String>(
          name: '${prefix}enterprise',
          label: '关联企业',
          hintText: '经营主体',
          options: _enterpriseOptions,
          clearable: true,
          minWidth: 0,
          initialValue: _initStr('${prefix}enterprise'),
        ),
      ),
      const SizedBox(height: 8),
      row(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSelectFormField<String>(
                name: '${prefix}province',
                label: '所在城市',
                hintText: '省',
                options: _provinceOptions,
                clearable: true,
                minWidth: 0,
                initialValue: _initStr('${prefix}province'),
                onChanged: prefix.isEmpty ? _onProvinceChanged : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppSelectFormField<String>(
                name: '${prefix}city',
                label: ' ',
                hintText: '市',
                options: _cityOptions,
                clearable: true,
                minWidth: 0,
                initialValue: _initStr('${prefix}city'),
              ),
            ),
          ],
        ),
        AppTextFormField(
          name: '${prefix}address',
          label: '详细地址',
          density: AppDensity.compact,
          hintText: '街道门牌等',
          initialValue: _initStr('${prefix}address'),
        ),
      ),
      const SizedBox(height: 8),
      row(
        AppTextFormField(
          name: '${prefix}title',
          label: '部门/职位',
          density: AppDensity.compact,
          hintText: '部门 / 职位',
          initialValue: _initStr('${prefix}title'),
        ),
        AppTextFormField(
          name: '${prefix}role',
          label: '职能描述',
          density: AppDensity.compact,
          hintText: '职责说明',
          initialValue: _initStr('${prefix}role'),
        ),
      ),
      const SizedBox(height: 8),
      row(
        AppMultiSelectFormField<String>(
          name: '${prefix}scope',
          label: '负责市场范围',
          options: _marketScopeOptions,
          initialValue: _initList('${prefix}scope'),
        ),
        AppMultiSelectFormField<String>(
          name: '${prefix}brands',
          label: '负责品牌',
          options: _brandOptions,
          initialValue: _initList('${prefix}brands'),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppSelectFormField<String>(
              name: '${prefix}tenure',
              label: '在职时间',
              hintText: '请选择',
              options: _tenureOptions,
              clearable: true,
              minWidth: 0,
              initialValue: _initStr('${prefix}tenure'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextFormField(
              name: '${prefix}mobile',
              label: '手机号',
              density: AppDensity.compact,
              hintText: '多项用逗号分隔',
              initialValue: _initStr('${prefix}mobile'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextFormField(
              name: '${prefix}phone',
              label: '电话',
              density: AppDensity.compact,
              hintText: '区号+号码',
              initialValue: _initStr('${prefix}phone'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      row(
        AppTextFormField(
          name: '${prefix}email',
          label: '邮箱',
          density: AppDensity.compact,
          hintText: '多项用逗号分隔',
          initialValue: _initStr('${prefix}email'),
        ),
        AppTextFormField(
          name: '${prefix}remark',
          label: '备注',
          density: AppDensity.compact,
          hintText: '选填',
          initialValue: _initStr('${prefix}remark'),
        ),
      ),
    ];
  }
}
