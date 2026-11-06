import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:pinyin/pinyin.dart';

import '../../../config/api_config.dart';
import '../../../models/ad_code.dart';
import '../../../models/customer_archive.dart';
import '../../../models/dict_data.dart';
import '../../../models/hrm_employee.dart';
import '../../../services/ad_code_api.dart';
import '../../../services/auth_session.dart';
import '../../../services/customer_api.dart';
import '../../../services/dict_api.dart';
import '../../../services/file_center_api.dart';
import 'contact_image_ocr_dialog.dart';
import 'ocr_text_confirm_dialog.dart';
import 'contact_vcf_import_dialog.dart';
import 'contact_vcf_parser.dart';
import 'select_sales_person_dialog.dart';

const _kPrimary = Color(0xFF0958D9);
const _kTitle = Color(0xFF141414);
const _kSectionTitle = Color(0xFF0F172A);
const _kLabel = Color(0xFF334155);
const _kMuted = Color(0xFF64748B);
const _kCardBorder = Color(0xFFD0D5DD);
const _kCardBg = Color(0xFFF4F5F7);
const _kEmptyBg = Color(0xFFEEF0F3);
const _kDanger = Color(0xFFCF1322);

const _kStatusOptions = [
  AppOption(value: '0', label: '正常'),
  AppOption(value: '1', label: '停用'),
];

const _kGenderOptions = [
  AppOption(value: '1', label: '男'),
  AppOption(value: '2', label: '女'),
  AppOption(value: '0', label: '未知'),
];

/// 渠道广告公司 · 企业类型 / 所属类型（对照新建表）。
const _kChannelTypeOptions = [
  AppOption(value: '户外媒体运营', label: '户外媒体运营'),
  AppOption(value: '整合发布', label: '整合发布'),
  AppOption(value: '创意设计', label: '创意设计'),
  AppOption(value: '创意发布', label: '创意发布'),
  AppOption(value: '品牌营销', label: '品牌营销'),
  AppOption(value: '线上推广', label: '线上推广'),
  AppOption(value: '活动策划与执行', label: '活动策划与执行'),
  AppOption(value: '物料工程', label: '物料工程'),
  AppOption(value: '咨询定位', label: '咨询定位'),
  AppOption(value: '品牌与市场公关', label: '品牌与市场公关'),
  AppOption(value: '数字内容服务', label: '数字内容服务'),
  AppOption(value: '4A公司VIP', label: '4A公司VIP'),
];

const _kOutdoorMediaType = '户外媒体运营';
const _k4aVipChannelType = '4A公司VIP';

/// 渠道 · 户外媒体运营子项「媒体资源标签」。
const _kMediaResourceOptions = [
  AppOption(value: '户外大牌', label: '户外大牌'),
  AppOption(value: '户外 LED 屏', label: '户外 LED 屏'),
  AppOption(value: '航空/机场', label: '航空/机场'),
  AppOption(value: '高铁/车站', label: '高铁/车站'),
  AppOption(value: '公交车身', label: '公交车身'),
  AppOption(value: '公交候车亭', label: '公交候车亭'),
  AppOption(value: '地铁类', label: '地铁类'),
  AppOption(value: '影院类', label: '影院类'),
  AppOption(value: '道闸', label: '道闸'),
  AppOption(value: '门禁', label: '门禁'),
  AppOption(value: '电梯框架', label: '电梯框架'),
  AppOption(value: '楼宇LCD屏', label: '楼宇LCD屏'),
  AppOption(value: '车库', label: '车库'),
  AppOption(value: '楼体灯光秀', label: '楼体灯光秀'),
];

/// 渠道广告公司 · 人员规模/人。
const _kStaffScaleOptions = [
  AppOption(value: '30以下', label: '30以下'),
  AppOption(value: '50以下', label: '50以下'),
  AppOption(value: '100以下', label: '100以下'),
  AppOption(value: '200以下', label: '200以下'),
  AppOption(value: '300以下', label: '300以下'),
  AppOption(value: '300以上', label: '300以上'),
];

/// 4A / VIP 服务类型 · 业务类型。
const _kBizTypeOptions = [
  AppOption(value: '媒介', label: '媒介'),
  AppOption(value: '创意', label: '创意'),
  AppOption(value: '全案', label: '全案'),
  AppOption(value: '咨询定位与公关', label: '咨询定位与公关'),
];

/// 接口 / 旧数据别名 → 字典键值（`mm_crm_self_media_matrix.dictValue`），便于回填。
const _kMediaTypeFromApi = <String, String>{
  'wechat_mp': 'wechat_mp',
  'wechat': 'wechat_mp',
  '微信公众号': 'wechat_mp',
  'wechat_channels': 'wechat_channels',
  'video': 'wechat_channels',
  'channels': 'wechat_channels',
  '视频号': 'wechat_channels',
  'douyin': 'douyin',
  '抖音': 'douyin',
  '抖音号': 'douyin',
  'xiaohongshu': 'xiaohongshu',
  '小红书': 'xiaohongshu',
};

const _kDictTypes = [
  OacDictTypes.customerType,
  OacDictTypes.marketScale,
  OacDictTypes.brandNature,
  OacDictTypes.revenueScale,
  OacDictTypes.marketingBudget,
  OacDictTypes.relationType,
  OacDictTypes.entityNature,
  OacDictTypes.marketScope,
  OacDictTypes.tenure,
  OacDictTypes.industry,
  OacDictTypes.selfMediaMatrix,
];

/// 打开「新建客户档案」弹窗（与主体概览同款 HyperDialog 小窗）。
/// [onCreated]：保存成功并关闭弹窗后回调（用于刷新外层列表）。
/// [customerId]：非空则为编辑，先拉详情回显。
Future<void> showCreateCustomerArchiveDialog(
  BuildContext context, {
  List<CustomerArchive> agencies = const [],
  String title = '新建客户档案',
  String? customerId,
  VoidCallback? onCreated,
}) {
  // 关闭后提示用宿主 context（弹窗内 SnackBar 会被遮罩挡住）。
  final hostContext = context;
  return showHyperDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final mq = MediaQuery.of(dialogContext);
      return AppShadcnScope(
        config: AppThemeConfig.standard(
          primary: _kPrimary,
          themeMode: AppThemeMode.light,
          controls: const AppControlMetrics(
            height: 34,
            buttonHeight: 32,
            horizontalPadding: 10,
            fontSize: 12,
            iconSize: 14,
            contentGap: 6,
          ),
        ),
        child: MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.noScaling),
          child: _CreateCustomerArchiveDialog(
            agencies: agencies,
            title: title,
            customerId: customerId,
            hostContext: hostContext,
            onClose: () => Navigator.of(dialogContext).pop(),
            onCreated: onCreated,
          ),
        ),
      );
    },
  );
}

/// 打开「编辑客户档案」弹窗（与新建同页，拉取详情回显）。
Future<void> showEditCustomerArchiveDialog(
  BuildContext context, {
  required String customerId,
  List<CustomerArchive> agencies = const [],
  VoidCallback? onSaved,
}) {
  return showCreateCustomerArchiveDialog(
    context,
    agencies: agencies,
    title: '编辑客户档案',
    customerId: customerId,
    onCreated: onSaved,
  );
}

/// 打开「快速新建 · 品牌企业」弹窗（订单页快捷入口）。
Future<void> showQuickCreateBrandDialog(
  BuildContext context, {
  List<CustomerArchive> agencies = const [],
  VoidCallback? onCreated,
}) {
  return showCreateCustomerArchiveDialog(
    context,
    agencies: agencies,
    title: '快速新建 · 品牌企业',
    onCreated: onCreated,
  );
}

class _CreateCustomerArchiveDialog extends StatefulWidget {
  const _CreateCustomerArchiveDialog({
    required this.agencies,
    required this.title,
    required this.onClose,
    required this.hostContext,
    this.customerId,
    this.onCreated,
  });

  final List<CustomerArchive> agencies;
  final String title;
  final String? customerId;
  final BuildContext hostContext;
  final VoidCallback onClose;
  final VoidCallback? onCreated;

  @override
  State<_CreateCustomerArchiveDialog> createState() =>
      _CreateCustomerArchiveDialogState();
}

class _CreateCustomerArchiveDialogState
    extends State<_CreateCustomerArchiveDialog> {
  final _form = AppFormController();
  final _dictApi = DictApi();
  final _adCodeApi = AdCodeApi();
  final _customerApi = CustomerApi();
  final _fileCenterApi = FileCenterApi();

  var _nextId = 1;
  var _bootLoading = true;
  late final List<_EntityDraft> _entities;
  late final List<_ContactDraft> _contacts;
  late final List<_MediaDraft> _medias;
  late final List<_SalesDraft> _sales;
  late final List<_VipDraft> _vips;
  List<CustomerArchive> _agencies = const [];
  List<AppOption<String>> _agencyOptions = const [
    AppOption(value: '', label: '无'),
  ];
  List<CustomerArchive> _channelCustomers = const [];
  List<AppOption<String>> _channelCustomerOptions = const [];
  /// 关联子品牌下拉：其它品牌企业档案。
  List<AppOption<String>> _brandCustomerOptions = const [];

  /// 当前客户类型编码：brand / channel / agency / gov / dsp。
  String? _selectedCustomerType;
  /// 渠道「企业类型」已选值（驱动媒体资源 / 关联 4A 显隐）。
  List<String> _selectedChannelTypes = const [];

  /// 本档案品牌简称 + 已选子品牌，供联系人「负责品牌」下拉。
  String _brandNameDraft = '';
  List<String> _subBrandsDraft = const [];
  final _brandChoicesRevision = ValueNotifier<int>(0);

  /// 品牌库联想：品牌简称 → 品牌库 id（最近一次搜索结果）。
  final Map<String, String> _brandNameToId = {};
  /// 品牌信息区重建（选中品牌库回填后吃新 initialValue）。
  var _brandInfoEpoch = 0;
  /// 避免同 id 重复拉详情回填。
  String? _lastAppliedBrandLibraryId;
  var _brandLibraryFilling = false;

  Map<String, List<DictDataItem>> _dictItems = const {};
  List<AppOption<String>> _customerTypeOptions = const [];
  List<AppOption<String>> _marketScaleOptions = const [];
  List<AppOption<String>> _brandNatureOptions = const [];
  List<AppOption<String>> _revenueOptions = const [];
  List<AppOption<String>> _marketingBudgetOptions = const [];
  List<AppOption<String>> _relationOptions = const [];
  List<AppOption<String>> _entityNatureOptions = const [];
  List<AppOption<String>> _marketScopeOptions = const [];
  List<AppOption<String>> _tenureOptions = const [];
  List<AppOption<String>> _industryOptions = const [];
  /// 自媒体矩阵平台（字典 `mm_crm_self_media_matrix`，value=dictValue）。
  List<AppOption<String>> _mediaPlatformOptions = const [];
  List<AppOption<String>> _provinceOptions = const [];

  /// 城市选项按经营主体 / 联系人 draft id 存储。
  final Map<int, List<AppOption<String>>> _cityOptionsByDraftId = {};
  /// 省变更时递增，用于重建市下拉并清空已选值。
  final Map<int, int> _cityEpochByDraftId = {};
  /// VCF 回填后递增，用于重建联系人字段以吃到新的 initialValue。
  final Map<int, int> _personEpochByDraftId = {};
  /// 银税 OCR / 经营异常查询回填后递增，用于重建对应字段以吃到新的 initialValue。
  final Map<int, int> _entityEpochByDraftId = {};
  final Map<int, int> _abnormalEpochByDraftId = {};
  final Set<int> _bankOcrLoadingIds = {};
  final Set<int> _licenseOcrLoadingIds = {};
  final Set<int> _abnormalQueryLoadingIds = {};

  /// 局部刷新：避免「添加」时整页 setState 重建全部表单字段。
  final _entitiesRevision = ValueNotifier<int>(0);
  final _cityRevision = ValueNotifier<int>(0);

  /// 姓名 → Name：英文名聚焦且为空时，用中文姓名拼音自动填充。
  final Map<int, String> _namePrefixByPersonId = {};
  final Map<int, GlobalKey<FormFieldState<String>>> _nameEnKeys = {};
  final Map<int, FocusNode> _nameEnFocusNodes = {};

  String? _customerTypeInitial;
  String? _marketScaleInitial;
  String? _relationInitial;
  String? _entityNatureInitial;
  String? _statusInitial = '0';

  /// 编辑态：详情 id、可选 weight，以及各表单字段 initialValue。
  String? _editId;
  Object? _editWeight;
  final Map<String, Object?> _initials = {};

  bool get _isEdit =>
      (widget.customerId?.trim().isNotEmpty ?? false) || _editId != null;

  @override
  void initState() {
    super.initState();
    _entities = [
      _EntityDraft(_nextId++)..taxEntries.add(_TaxEntryDraft(_nextId++)),
    ];
    _contacts = [_ContactDraft(_nextId++)];
    _medias = [];
    _sales = [];
    _vips = [];
    _bootstrap();
  }

  String get _customerTypeCode {
    final raw = (_selectedCustomerType ?? _customerTypeInitial ?? '').trim();
    if (raw.isEmpty) return 'brand';
    final lower = raw.toLowerCase();
    const codes = {'brand', 'channel', 'agency', 'gov', 'dsp'};
    if (codes.contains(lower)) return lower;
    for (final o in _customerTypeOptions) {
      if (o.value == raw || o.label == raw) {
        final v = o.value.trim().toLowerCase();
        if (codes.contains(v)) return v;
      }
    }
    if (raw.contains('渠道')) return 'channel';
    if (raw.contains('4A') || raw.contains('4a')) return 'agency';
    if (raw.contains('政务')) return 'gov';
    if (raw.toUpperCase().contains('DSP') || raw.contains('API')) {
      return 'dsp';
    }
    if (raw.contains('品牌')) return 'brand';
    return lower;
  }

  bool get _isBrandType => _customerTypeCode == 'brand';
  bool get _isChannelType => _customerTypeCode == 'channel';
  bool get _isAgencyType => _customerTypeCode == 'agency';
  bool get _isGovType => _customerTypeCode == 'gov';

  bool get _showBrandShortName => _isBrandType || _isGovType;
  bool get _showSubBrands => _isBrandType;
  bool get _showBrandNature => _isBrandType;
  bool get _showMarketingBudget => _isBrandType;
  bool get _showSpokesperson => _isBrandType;
  bool get _showServiceAgency => _isBrandType;
  bool get _showRevenueScale =>
      _isBrandType || _isChannelType || _isAgencyType;
  bool get _showStaffScale => _isChannelType;
  bool get _showChannelTypes => _isChannelType;
  bool get _showEntityMarketScope => _isBrandType;
  bool get _showEntityBizTypes => _isAgencyType;
  bool get _showEntityLicense => !_isGovType;
  bool get _showVipSection => _isAgencyType;

  void _onCustomerTypeChanged(String? value) {
    final next = value?.trim();
    if (next == _selectedCustomerType) return;
    setState(() {
      _selectedCustomerType = next;
      if (!_isChannelType) {
        _selectedChannelTypes = const [];
      }
      if (!_isAgencyType) {
        _vips.clear();
      }
    });
  }

  void _onChannelTypesChanged(List<String>? value) {
    setState(() {
      _selectedChannelTypes = [
        for (final v in value ?? const <String>[])
          if (v.trim().isNotEmpty) v.trim(),
      ];
    });
  }

  String? _initStr(String name) {
    final v = _initials[name];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  List<String> _initList(String name) {
    final v = _initials[name];
    if (v == null) return const [];
    return _asStringList(v);
  }

  void _putInit(String name, Object? value) {
    if (value == null) return;
    if (value is String && value.trim().isEmpty) return;
    if (value is Iterable && value.isEmpty) return;
    _initials[name] = value;
  }

  @override
  void dispose() {
    for (final node in _nameEnFocusNodes.values) {
      node.dispose();
    }
    _nameEnFocusNodes.clear();
    _nameEnKeys.clear();
    _namePrefixByPersonId.clear();
    _entitiesRevision.dispose();
    _cityRevision.dispose();
    _brandChoicesRevision.dispose();
    _form.dispose();
    super.dispose();
  }

  void _syncBrandChoices({String? name, List<String>? subBrands}) {
    if (name != null) _brandNameDraft = name.trim();
    if (subBrands != null) {
      _subBrandsDraft = [
        for (final s in subBrands)
          if (s.trim().isNotEmpty) s.trim(),
      ];
    }
    _brandChoicesRevision.value++;
  }

  /// 品牌简称联想：`GET …/brandLibrary/nameOptions`。
  Future<List<AppOption<String>>> _searchBrandLibraryOptions(
    String query,
  ) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final list = await _customerApi.fetchBrandLibraryNameOptions(q);
      final options = <AppOption<String>>[];
      final seen = <String>{};
      for (final m in list) {
        final name = _asTrimmed(m['brandName']);
        if (name == null || !seen.add(name)) continue;
        options.add(AppOption(value: name, label: name));
        final id = m['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) _brandNameToId[name] = id;
      }
      if (!seen.contains(q)) {
        options.insert(0, AppOption(value: q, label: q));
      }
      return options;
    } catch (_) {
      return [AppOption(value: q, label: q)];
    }
  }

  Future<void> _onBrandNamePicked(String? name) async {
    final n = name?.trim() ?? '';
    _syncBrandChoices(name: n);
    if (n.isEmpty || _brandLibraryFilling) return;
    final id = _brandNameToId[n];
    if (id == null || id.isEmpty) return;
    if (_lastAppliedBrandLibraryId == id) return;
    await _applyBrandLibraryDetail(id);
  }

  /// 选中品牌库项后：`GET …/brandLibrary/nameOptions/{id}` 回填品牌信息 / 主体 / 自媒体。
  Future<void> _applyBrandLibraryDetail(String id) async {
    if (_brandLibraryFilling) return;
    setState(() => _brandLibraryFilling = true);
    try {
      final data = await _customerApi.fetchBrandLibraryNameOptionDetail(id);
      if (!mounted) return;
      _lastAppliedBrandLibraryId = id;

      for (final k in const [
        'name',
        'subBrands',
        'industry',
        'brandNature',
        'revenueScale',
        'spokesperson',
        'website',
        'serviceAgencyId',
      ]) {
        _initials.remove(k);
      }

      final brandName = _asTrimmed(data['brandName']);
      if (brandName != null) {
        _putInit('name', brandName);
        _brandNameToId[brandName] = id;
      }

      final relatedNames = <String>[];
      final related = data['relatedBrands'];
      if (related is List) {
        for (final e in related) {
          if (e is! Map) continue;
          final n = _asTrimmed(e['name']);
          if (n != null) relatedNames.add(n);
        }
      }
      if (relatedNames.isNotEmpty) {
        _initials['subBrands'] = relatedNames;
      }
      _syncBrandChoices(
        name: brandName ?? _brandNameDraft,
        subBrands: relatedNames,
      );

      _putInit(
        'industry',
        _valuesFromLabelOrValue(_industryOptions, data['industry']),
      );
      _putInit(
        'brandNature',
        _libraryDictLabel(
          OacDictTypes.brandNature,
          data['brandNatureName'] ?? data['brandNature'],
        ),
      );
      _putInit(
        'revenueScale',
        _libraryDictLabel(
          OacDictTypes.revenueScale,
          data['revenueScaleName'] ?? data['revenueScale'],
        ),
      );
      _putInit(
        'spokesperson',
        _spokespersonFromLibrary(data['spokespersons']),
      );
      _putInit('website', _websitesFromLibrary(data['websites']));
      _applyLibraryServiceAgency(data);

      // 经营主体：用品牌库 enterprises 覆盖当前草稿（不带 serverId）。
      for (final e in _entities) {
        _cityOptionsByDraftId.remove(e.id);
        _cityEpochByDraftId.remove(e.id);
        _entityEpochByDraftId.remove(e.id);
        _abnormalEpochByDraftId.remove(e.id);
      }
      _entities.clear();
      final pendingCities = <_PendingCity>[];
      final ents = data['enterprises'];
      if (ents is List) {
        for (final raw in ents) {
          if (raw is! Map) continue;
          final e = Map<String, dynamic>.from(raw);
          final draft = _newEntityDraft();
          _entities.add(draft);
          final p = 'ent_${draft.id}';
          final fullName = _asTrimmed(e['name']);
          _putInit('${p}_name', fullName);
          _putInit(
            '${p}_shortName',
            e['shortName'] ??
                e['aliasName'] ??
                e['enterpriseShort'] ??
                (_entities.length == 1 ? brandName : null),
          );
          _putInit(
            '${p}_relation',
            _libraryDictLabel(
              OacDictTypes.relationType,
              e['relationTypeName'] ?? e['relationName'] ?? e['relationType'],
            ),
          );
          _putInit(
            '${p}_nature',
            _libraryDictLabel(
              OacDictTypes.entityNature,
              e['entityNatureName'] ?? e['natureName'] ?? e['entityNature'],
            ),
          );
          _putInit('${p}_legalPerson', e['legalPerson']);
          _putInit('${p}_creditCode', e['creditCode']);
          final addressParts = [
            _asTrimmed(e['address1']) ?? '',
            _asTrimmed(e['address2']) ?? '',
          ].where((s) => s.isNotEmpty).join('');
          final detailAddress =
              _asTrimmed(e['address']) ??
              (addressParts.isEmpty ? null : addressParts);
          if (detailAddress != null) {
            _putInit('${p}_address', detailAddress);
          }
          // 注册地址：优先显式字段，否则回退 address1+address2（品牌库常见结构）。
          final regAddress =
              _asTrimmed(e['regAddress']) ??
              _asTrimmed(e['registeredAddress']) ??
              _asTrimmed(e['businessAddress']) ??
              (addressParts.isEmpty ? null : addressParts);
          if (regAddress != null) {
            _putInit('${p}_regAddress', regAddress);
          }
          _putInit('${p}_regPhone', e['phone1'] ?? e['phone2'] ?? e['phone3']);
          final provCode = _valueFromLabelOrValue(
            _provinceOptions,
            e['province'],
          );
          _putInit('${p}_province', provCode);
          pendingCities.add(
            _PendingCity(
              draftId: draft.id,
              fieldName: '${p}_city',
              provinceCode: provCode,
              cityLabel: _asTrimmed(e['city']),
            ),
          );
        }
      }
      if (_entities.isEmpty) {
        _entities.add(_newEntityDraft());
      }
      _bumpEntities();

      // 自媒体矩阵。
      _medias.clear();
      final medias = data['medias'];
      if (medias is List) {
        for (final raw in medias) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final draft = _MediaDraft(_nextId++);
          _medias.add(draft);
          _putInit(
            'media_${draft.id}_platform',
            _mediaPlatformFromApi(_asTrimmed(m['mediaType'])),
          );
          _putInit('media_${draft.id}_account', m['accountName']);
          _putInit('media_${draft.id}_link', m['accountUrl']);
          await _hydrateMediaQr(draft, m);
        }
      }

      await _loadPendingCities(pendingCities);

      if (!mounted) return;
      setState(() => _brandInfoEpoch++);
      _toast('已从品牌库回填');
    } catch (e) {
      if (mounted) _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _brandLibraryFilling = false);
    }
  }

  String? _spokespersonFromLibrary(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    final first = raw.first;
    if (first is Map) {
      final display =
          _asTrimmed(first['spokespersonDisplay']) ?? _asTrimmed(first['name']);
      final extra = _asInt(first['spokespersonExtraCount']);
      if (display != null && extra != null && extra > 0) {
        return '$display +$extra';
      }
      if (display != null) return display;
    }
    final parts = <String>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final n =
          _asTrimmed(e['spokespersonDisplay']) ?? _asTrimmed(e['name']);
      if (n != null) parts.add(n);
    }
    return parts.isEmpty ? null : parts.join('、');
  }

  String? _websitesFromLibrary(dynamic raw) {
    final list = _asStringList(raw);
    return list.isEmpty ? null : list.join(', ');
  }

  /// 关联子品牌下拉选项（已有品牌 + 回填值兜底）。
  List<AppOption<String>> _subBrandSelectOptions() {
    final seen = <String>{};
    final out = <AppOption<String>>[];
    void add(String? raw) {
      final n = raw?.trim() ?? '';
      if (n.isEmpty || !seen.add(n)) return;
      out.add(AppOption(value: n, label: n));
    }

    for (final o in _brandCustomerOptions) {
      add(o.value);
    }
    for (final s in _initList('subBrands')) {
      add(s);
    }
    for (final s in _subBrandsDraft) {
      add(s);
    }
    return out;
  }

  /// 联系人负责品牌选项：本档案品牌简称 + 已关联子品牌。
  List<AppOption<String>> _responsibleBrandOptions() {
    final seen = <String>{};
    final out = <AppOption<String>>[];
    void add(String? raw) {
      final n = raw?.trim() ?? '';
      if (n.isEmpty || !seen.add(n)) return;
      out.add(AppOption(value: n, label: n));
    }

    add(_brandNameDraft);
    for (final s in _subBrandsDraft) {
      add(s);
    }
    for (final s in _initList('subBrands')) {
      add(s);
    }
    return out;
  }

  _EntityDraft _newEntityDraft() {
    return _EntityDraft(_nextId++)
      ..taxEntries.add(_TaxEntryDraft(_nextId++));
  }

  FocusNode _nameEnFocusOf(int personId) {
    return _nameEnFocusNodes.putIfAbsent(personId, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) return;
        final prefix = _namePrefixByPersonId[personId];
        if (prefix == null) return;
        _tryAutofillNameEn(personId, prefix);
      });
      return node;
    });
  }

  void _releasePersonNameEn(int personId) {
    _nameEnFocusNodes.remove(personId)?.dispose();
    _nameEnKeys.remove(personId);
    _namePrefixByPersonId.remove(personId);
  }

  void _tryAutofillNameEn(
    int personId,
    String namePrefix, {
    String? nameZh,
    bool force = false,
  }) {
    final enState = _nameEnKeys[personId]?.currentState;
    if (enState == null) return;
    final current = (enState.value ?? '').trim();
    if (!force && current.isNotEmpty) return;

    final zh =
        (nameZh ?? _form.value<String>('${namePrefix}_nameZh') ?? '').trim();
    final en = zh.isEmpty ? '' : _chineseToEnglishName(zh);
    if (!force && en.isEmpty) return;
    enState.didChange(en);
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

  List<AppOption<String>> _enterpriseOptions() {
    return [
      for (var i = 0; i < _entities.length; i++)
        AppOption(
          value: 'ent-${_entities[i].id}',
          label: '经营主体 ${i + 1}',
        ),
    ];
  }

  void _bumpEntities() => _entitiesRevision.value++;

  void _bumpCity() => _cityRevision.value++;

  Future<void> _bootstrap() async {
    setState(() => _bootLoading = true);
    try {
      final editId = widget.customerId?.trim();
      final results = await Future.wait([
        _dictApi.fetchMany(_kDictTypes),
        _adCodeApi.fetchChildren(),
        _customerApi.fetchList(
          OacCustomerQuery(
            customerType: 'agency',
            pageNum: 1,
            pageSize: 200,
          ),
        ),
        _customerApi.fetchList(
          OacCustomerQuery(
            customerType: 'channel',
            pageNum: 1,
            pageSize: 200,
          ),
        ),
        _customerApi.fetchList(
          OacCustomerQuery(
            customerType: 'brand',
            pageNum: 1,
            pageSize: 500,
          ),
        ),
        if (editId != null && editId.isNotEmpty)
          _customerApi.fetchCustomerDetail(editId),
      ]);
      if (!mounted) return;

      final dicts = results[0] as Map<String, List<DictDataItem>>;
      _dictItems = dicts;
      final provinces = results[1] as List<AdCodeItem>;
      final agencyPage = results[2] as OacCustomerListPage;
      final channelPage = results[3] as OacCustomerListPage;
      final brandPage = results[4] as OacCustomerListPage;
      final detail = results.length > 5
          ? results[5] as Map<String, dynamic>
          : null;

      List<AppOption<String>> opts(String type, {bool valueIsCode = false}) =>
          _dictToOptions(dicts[type] ?? const [], valueIsCode: valueIsCode);

      String? initial(
        String type, {
        required bool preferFirst,
        bool valueIsCode = false,
      }) {
        final items = dicts[type] ?? const <DictDataItem>[];
        final def = _dictDefaultValue(items, valueIsCode: valueIsCode);
        if (def != null) return def;
        if (!preferFirst) return null;
        final o = _dictToOptions(items, valueIsCode: valueIsCode);
        return o.isEmpty ? null : o.first.value;
      }

      // 客户类型接口存 dictValue 编码（brand/agency…）；其余字典存 dictLabel。
      _customerTypeOptions =
          opts(OacDictTypes.customerType, valueIsCode: true);
      _marketScaleOptions = opts(OacDictTypes.marketScale);
      _brandNatureOptions = opts(OacDictTypes.brandNature);
      _revenueOptions = opts(OacDictTypes.revenueScale);
      _marketingBudgetOptions = opts(OacDictTypes.marketingBudget);
      _relationOptions = opts(OacDictTypes.relationType);
      _entityNatureOptions = opts(OacDictTypes.entityNature);
      _marketScopeOptions = opts(OacDictTypes.marketScope);
      _tenureOptions = opts(OacDictTypes.tenure);
      _industryOptions = opts(OacDictTypes.industry);
      _mediaPlatformOptions =
          opts(OacDictTypes.selfMediaMatrix, valueIsCode: true);
      _provinceOptions = _adCodeToOptions(provinces);
      _agencies =
          agencyPage.rows.isNotEmpty ? agencyPage.rows : widget.agencies;
      _agencyOptions = [
        const AppOption(value: '', label: '无'),
        for (final a in _agencies)
          if (a.id != null && (a.brandName?.trim().isNotEmpty ?? false))
            AppOption(value: a.id!, label: a.brandName!.trim()),
      ];
      _channelCustomers = channelPage.rows;
      _channelCustomerOptions = [
        for (final a in _channelCustomers)
          if (a.id != null && (a.brandName?.trim().isNotEmpty ?? false))
            AppOption(value: a.id!, label: a.brandName!.trim()),
      ];
      final excludeBrandId = editId;
      _brandCustomerOptions = [
        for (final a in brandPage.rows)
          if (a.id != null &&
              (a.brandName?.trim().isNotEmpty ?? false) &&
              (excludeBrandId == null ||
                  excludeBrandId.isEmpty ||
                  a.id != excludeBrandId))
            AppOption(
              value: a.brandName!.trim(),
              label: a.brandName!.trim(),
            ),
      ];

      _customerTypeInitial = initial(
        OacDictTypes.customerType,
        preferFirst: true,
        valueIsCode: true,
      );
      // 快速新建品牌入口默认品牌企业。
      if (widget.title.contains('品牌企业')) {
        for (final o in _customerTypeOptions) {
          if (o.value.toLowerCase() == 'brand' || o.label.contains('品牌')) {
            _customerTypeInitial = o.value;
            break;
          }
        }
      }
      _selectedCustomerType = _customerTypeInitial;
      _marketScaleInitial =
          initial(OacDictTypes.marketScale, preferFirst: true);
      _relationInitial =
          initial(OacDictTypes.relationType, preferFirst: true);
      _entityNatureInitial =
          initial(OacDictTypes.entityNature, preferFirst: true);
      _statusInitial = '0';

      if (detail != null) {
        await _hydrateFromDetail(detail);
        await _prefetchEntityLicenseImages();
      } else {
        _syncBrandChoices(
          name: _initStr('name') ?? '',
          subBrands: _initList('subBrands'),
        );
      }

      if (!mounted) return;
      setState(() => _bootLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // 接口失败时回退入口传入的列表（如订单页已预加载）。
        _agencies = widget.agencies;
        _agencyOptions = [
          const AppOption(value: '', label: '无'),
          for (final a in _agencies)
            if (a.id != null && (a.brandName?.trim().isNotEmpty ?? false))
              AppOption(value: a.id!, label: a.brandName!.trim()),
        ];
        _bootLoading = false;
      });
      if (_isEdit || (widget.customerId?.trim().isNotEmpty ?? false)) {
        _toast(e.toString(), error: true);
      }
    }
  }

  /// 弹窗仍打开时用弹窗 ToastLayer；关闭后用宿主 context。
  void _toast(String title, {bool error = false, bool afterClose = false}) {
    final ctx = afterClose ? widget.hostContext : context;
    if (!ctx.mounted) return;
    AppToast.show(
      context: ctx,
      title: title,
      location: error
          ? AppToastLocation.topCenter
          : AppToastLocation.bottomRight,
    );
  }

  /// 选项 value/展示均取 [DictDataItem.dictLabel]（接口存标签文案）。
  /// [valueIsCode] 为 true 时 value 改用 [DictDataItem.dictValue]（如客户类型编码）。
  List<AppOption<String>> _dictToOptions(
    List<DictDataItem> items, {
    bool valueIsCode = false,
  }) {
    final out = <AppOption<String>>[];
    for (final e in items) {
      final label = e.dictLabel?.trim();
      final code = e.dictValue?.trim();
      if (label == null || label.isEmpty) continue;
      if (valueIsCode) {
        if (code == null || code.isEmpty) continue;
        out.add(AppOption(value: code, label: label));
      } else {
        out.add(AppOption(value: label, label: label));
      }
    }
    return out;
  }

  String? _dictDefaultValue(
    List<DictDataItem> items, {
    bool valueIsCode = false,
  }) {
    for (final e in items) {
      if (e.isDefault?.toUpperCase() != 'Y') continue;
      final label = e.dictLabel?.trim();
      final code = e.dictValue?.trim();
      if (label == null || label.isEmpty) continue;
      if (valueIsCode) {
        if (code == null || code.isEmpty) continue;
        return code;
      }
      return label;
    }
    return null;
  }

  List<AppOption<String>> _adCodeToOptions(List<AdCodeItem> items) {
    final out = <AppOption<String>>[];
    for (final e in items) {
      final code = e.code;
      final name = e.chName?.trim();
      if (code == null || name == null || name.isEmpty) continue;
      out.add(AppOption(value: code.toString(), label: name));
    }
    return out;
  }

  Future<void> _onProvinceChanged(int draftId, String? provinceCode) async {
    _cityOptionsByDraftId[draftId] = const [];
    _cityEpochByDraftId[draftId] = (_cityEpochByDraftId[draftId] ?? 0) + 1;
    _bumpCity();

    final raw = provinceCode?.trim();
    if (raw == null || raw.isEmpty) return;
    final code = int.tryParse(raw);
    if (code == null) return;

    try {
      final cities = await _adCodeApi.fetchChildren(parentCode: code);
      if (!mounted) return;
      _cityOptionsByDraftId[draftId] = _adCodeToOptions(cities);
      _bumpCity();
    } catch (_) {
      if (!mounted) return;
      _cityOptionsByDraftId[draftId] = const [];
      _bumpCity();
    }
  }

  Future<void> _submit() async {
    try {
      final ok = await _form.submit((values) async {
        final body = _buildCreateBody(values);
        if (_editId != null) {
          body['id'] = _editId;
          final code = _asTrimmed(values['customerCode']) ??
              _initStr('customerCode');
          if (code != null) body['customerCode'] = code;
          await _customerApi.updateCustomer(body);
        } else {
          await _customerApi.createCustomer(body);
        }
      });
      if (!ok || !mounted) return;
      final onCreated = widget.onCreated;
      final successText = _editId != null ? '更新成功' : '创建成功';
      widget.onClose();
      onCreated?.call();
      _toast(successText, afterClose: true);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _hydrateFromDetail(Map<String, dynamic> data) async {
    _initials.clear();
    _entities.clear();
    _contacts.clear();
    _medias.clear();
    _sales.clear();
    _vips.clear();
    _cityOptionsByDraftId.clear();
    _cityEpochByDraftId.clear();
    _selectedChannelTypes = const [];

    _editId = _asTrimmed(data['id']) ?? widget.customerId?.trim();
    _editWeight = data['weight'];

    _putInit('customerCode', data['customerCode'] ?? data['archiveCode']);
    _putInit('customerType', data['customerType']);
    _putInit('marketScale', data['marketScale']);
    _putInit('status', data['status']);
    _putInit('name', data['name']);
    _putInit('subBrands', _asStringList(data['subBrands']));
    _syncBrandChoices(
      name: _asTrimmed(data['name']) ?? '',
      subBrands: _asStringList(data['subBrands']),
    );
    _putInit(
      'industry',
      _valuesFromLabelOrValue(_industryOptions, data['industry']),
    );
    _putInit(
      'brandNature',
      _valueFromLabelOrValue(_brandNatureOptions, data['brandNature']),
    );
    _putInit(
      'revenueScale',
      _valueFromLabelOrValue(_revenueOptions, data['revenueScale']),
    );
    _putInit(
      'marketingBudget',
      _valueFromLabelOrValue(
        _marketingBudgetOptions,
        data['marketingBudget'],
      ),
    );
    _putInit(
      'staffScale',
      _valueFromLabelOrValue(_kStaffScaleOptions, data['staffScale']),
    );
    _putInit('spokesperson', data['spokesperson']);
    _putInit('website', data['website']);

    final channelTypes = _valuesFromLabelOrValue(
      _kChannelTypeOptions,
      data['channelTypes'] ?? data['belongTypes'],
    );
    _putInit('channelTypes', channelTypes);
    _selectedChannelTypes = channelTypes;
    _putInit(
      'mediaResources',
      _valuesFromLabelOrValue(
        _kMediaResourceOptions,
        data['mediaResources'],
      ),
    );
    _putInit(
      'vipAgencyIds',
      [
        for (final id in _asStringList(data['relatedAgencyIds'])) id,
      ],
    );

    final relatedIds = data['relatedAgencyIds'];
    if (relatedIds is List && relatedIds.isNotEmpty) {
      _putInit('serviceAgencyId', relatedIds.first.toString());
    } else {
      _putInit('serviceAgencyId', data['serviceAgencyId']);
    }

    _customerTypeInitial =
        _initStr('customerType') ?? _customerTypeInitial;
    _selectedCustomerType = _customerTypeInitial;
    _marketScaleInitial = _initStr('marketScale') ?? _marketScaleInitial;
    _statusInitial = _initStr('status') ?? '0';

    final pendingCities = <_PendingCity>[];
    final entNameToKey = <String, String>{};

    final ents = data['enterprises'];
    if (ents is List && ents.isNotEmpty) {
      for (final raw in ents) {
        if (raw is! Map) continue;
        final e = Map<String, dynamic>.from(raw);
        final draft = _EntityDraft(_nextId++, serverId: e['id']);
        _entities.add(draft);
        final p = 'ent_${draft.id}';
        final fullName = _asTrimmed(e['fullName']);
        _putInit('${p}_name', fullName);
        _putInit(
          '${p}_shortName',
          e['shortName'] ?? e['aliasName'] ?? e['enterpriseShort'],
        );
        if (fullName != null) entNameToKey[fullName] = 'ent-${draft.id}';
        final relationVal = _valueFromLabelOrValue(
          _relationOptions,
          e['relationType'],
        );
        _putInit(
          '${p}_bizTypes',
          _valuesFromLabelOrValue(
            _kBizTypeOptions,
            e['businessTypes'] ?? e['bizTypes'] ?? e['businessType'],
          ),
        );
        _putInit('${p}_relation', relationVal);
        if (_entities.length == 1 && relationVal != null) {
          _relationInitial = relationVal;
        }
        final natureVal = _valueFromLabelOrValue(
          _entityNatureOptions,
          e['entityNature'],
        );
        _putInit('${p}_nature', natureVal);
        if (_entities.length == 1 && natureVal != null) {
          _entityNatureInitial = natureVal;
        }
        _putInit(
          '${p}_scope',
          _valuesFromLabelOrValue(_marketScopeOptions, e['marketScope']),
        );
        final provCode = _valueFromLabelOrValue(
          _provinceOptions,
          e['province'],
        );
        _putInit('${p}_province', provCode);
        _putInit('${p}_address', e['address']);
        _putInit('${p}_legalPerson', e['legalPerson']);
        _putInit('${p}_regAddress', e['regAddress']);
        _putInit('${p}_regPhone', e['regPhone']);
        _putInit('${p}_creditCode', e['creditCode'] ?? e['unifiedSocialCreditCode']);
        _putInit(
          '${p}_regCapital',
          e['regCapital'] ?? e['registeredCapital'],
        );
        _putInit(
          '${p}_establishDate',
          e['establishDate'] ?? e['establishedDate'] ?? e['foundDate'],
        );
        _putInit('${p}_licenseExpire', _licenseExpireFromEnterprise(e));
        _putInit('${p}_businessScope', e['businessScope'] ?? e['bizScope']);
        _putInit(
          '${p}_abnormalRecord',
          e['abnormalRecord'] ?? e['businessAbnormal'],
        );
        _putInit(
          '${p}_penaltyHistory',
          e['penaltyHistory'] ?? e['adminPenalty'],
        );
        _putInit('${p}_remark', e['remark'] ?? e['remarks']);
        _hydrateEntityLicense(draft, e);
        _hydrateEntityTax(draft, e);
        pendingCities.add(
          _PendingCity(
            draftId: draft.id,
            fieldName: '${p}_city',
            provinceCode: provCode,
            cityLabel: _asTrimmed(e['city']),
          ),
        );
      }
    }
    if (_entities.isEmpty) {
      _entities.add(_newEntityDraft());
    }

    final medias = data['mediaList'];
    if (medias is List) {
      for (final raw in medias) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final draft = _MediaDraft(_nextId++, serverId: m['id']);
        _medias.add(draft);
        _putInit(
          'media_${draft.id}_platform',
          _mediaPlatformFromApi(_asTrimmed(m['mediaType'])),
        );
        _putInit('media_${draft.id}_account', m['accountName']);
        _putInit('media_${draft.id}_link', m['accountUrl']);
      }
    }

    final contacts = data['contacts'];
    if (contacts is List && contacts.isNotEmpty) {
      for (final raw in contacts) {
        if (raw is! Map) continue;
        final c = Map<String, dynamic>.from(raw);
        final draft = _ContactDraft(_nextId++, serverId: c['id']);
        _contacts.add(draft);
        _hydratePerson(
          c,
          'ct_${draft.id}',
          draft.id,
          entNameToKey,
          pendingCities,
        );
        final supers = c['superiors'];
        if (supers is List) {
          for (final sRaw in supers) {
            if (sRaw is! Map) continue;
            final s = Map<String, dynamic>.from(sRaw);
            final person = _PersonDraft(_nextId++, serverId: s['id']);
            draft.superiors.add(person);
            _hydratePerson(
              s,
              'ct_${draft.id}_sup_${person.id}',
              person.id,
              entNameToKey,
              pendingCities,
            );
          }
        }
        final subs = c['subordinates'];
        if (subs is List) {
          for (final sRaw in subs) {
            if (sRaw is! Map) continue;
            final s = Map<String, dynamic>.from(sRaw);
            final person = _PersonDraft(_nextId++, serverId: s['id']);
            draft.subordinates.add(person);
            _hydratePerson(
              s,
              'ct_${draft.id}_sub_${person.id}',
              person.id,
              entNameToKey,
              pendingCities,
            );
          }
        }
      }
    }
    if (_contacts.isEmpty) {
      _contacts.add(_ContactDraft(_nextId++));
    }

    final sales = data['salesList'];
    if (sales is List) {
      for (final raw in sales) {
        if (raw is! Map) continue;
        final s = Map<String, dynamic>.from(raw);
        final uid = _asInt(s['userId']) ?? _nextId;
        _sales.add(
          _SalesDraft(
            id: _nextId++,
            userId: uid,
            serverId: s['id'],
            nameZh: _asTrimmed(s['name']) ?? '-',
            nameEn: _asTrimmed(s['nameEn']) ?? '-',
            gender: _genderLabel(s['gender']),
            deptPost: _asTrimmed(s['deptTitle']) ?? '-',
            createTime: _asTrimmed(s['assignTime']) ?? '-',
          ),
        );
      }
    }

    final vipRaw = data['vipList'];
    if (vipRaw is List) {
      for (final raw in vipRaw) {
        if (raw is! Map) continue;
        final v = Map<String, dynamic>.from(raw);
        final draft = _VipDraft(_nextId++, serverId: v['id']);
        _vips.add(draft);
        final p = 'vip_${draft.id}';
        final relatedId = _asTrimmed(
          v['relatedCustomerId'] ?? v['channelCustomerId'] ?? v['customerId'],
        );
        _putInit('${p}_relatedId', relatedId);
        _putInit('${p}_fullName', v['fullName'] ?? v['companyName']);
        _putInit(
          '${p}_bizTypes',
          _valuesFromLabelOrValue(
            _kBizTypeOptions,
            v['businessTypes'] ?? v['bizTypes'] ?? v['businessType'],
          ),
        );
        final brands = v['serviceBrands'] ?? v['brands'];
        if (brands is List) {
          for (final bRaw in brands) {
            if (bRaw is! Map) continue;
            final b = Map<String, dynamic>.from(bRaw);
            final bd = _VipBrandDraft(_nextId++, serverId: b['id']);
            draft.brands.add(bd);
            final bp = 'vip_${draft.id}_brand_${bd.id}';
            _putInit('${bp}_name', b['brandName'] ?? b['name']);
            _putInit(
              '${bp}_serviceTypes',
              _valuesFromLabelOrValue(
                _kBizTypeOptions,
                b['serviceTypes'] ?? b['serviceType'],
              ),
            );
          }
        }
        if (draft.brands.isEmpty) {
          draft.brands.add(_VipBrandDraft(_nextId++));
        }
      }
    }

    await _loadPendingCities(pendingCities);
  }

  /// 与详情页一致：优先 licenseValidPeriod / validPeriod，其次起止日期拼接。
  String? _licenseExpireFromEnterprise(Map<String, dynamic> e) {
    final period = _asTrimmed(e['licenseValidPeriod']) ??
        _asTrimmed(e['validPeriod']) ??
        _asTrimmed(e['licenseExpire']) ??
        _asTrimmed(e['businessLicenseExpire']);
    if (period != null) return period;
    final start = _asTrimmed(e['validFromDate']) ??
        _asTrimmed(e['licenseStart']) ??
        _asTrimmed(e['businessLicenseStart']);
    final end = _asTrimmed(e['validToDate']) ??
        _asTrimmed(e['licenseEnd']) ??
        _asTrimmed(e['businessLicenseEnd']);
    if (start == null && end == null) return null;
    if (start == null) return end;
    if (end == null) return start;
    return '$start 至 $end';
  }

  void _hydrateEntityLicense(_EntityDraft draft, Map<String, dynamic> e) {
    draft.licenseOssId = _asTrimmed(e['licenseOssId'] ?? e['ossId']);
    draft.licenseUrl = _licenseDisplayUrl(e);
    // 仅有数字 ossId、无直链时，尝试下载接口预览。
    if ((draft.licenseUrl == null || draft.licenseUrl!.isEmpty) &&
        draft.licenseOssId != null &&
        RegExp(r'^\d+$').hasMatch(draft.licenseOssId!)) {
      draft.licenseUrl =
          '${ApiConfig.baseUrl}/desktop/resource/oss/download/${draft.licenseOssId}';
    }
  }

  Future<void> _prefetchEntityLicenseImages() async {
    await Future.wait([
      for (final e in _entities) _prefetchOneLicenseImage(e),
    ]);
  }

  Future<void> _prefetchOneLicenseImage(_EntityDraft draft) async {
    if (draft.licenseBytes != null && draft.licenseBytes!.isNotEmpty) return;
    final url = draft.licenseUrl?.trim() ?? '';
    if (url.isEmpty) return;
    try {
      final response = await http
          .get(Uri.parse(url), headers: AuthSession.headers())
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      if (response.bodyBytes.isEmpty) return;
      draft.licenseBytes = response.bodyBytes;
    } catch (_) {
      // 预览失败不阻断编辑；仍可保留 networkUrl 由 Image.network 尝试。
    }
  }

  /// 从主体详情解析可预览的营业执照图片地址。
  /// 接口约定：`licenseOssURL` 为营业执照图片。
  String? _licenseDisplayUrl(Map<String, dynamic> e) {
    for (final key in const [
      'licenseOssURL',
      'licenseOssUrl',
      'licenseUrl',
      'licenseFile',
      'licenseFileUrl',
      'attachmentUrl',
      'fileUrl',
      'url',
      'ossUrl',
    ]) {
      final resolved = _resolveMediaUrl(_asTrimmed(e[key]));
      if (resolved != null) return resolved;
    }
    final attachments = e['attachments'];
    if (attachments is List) {
      for (final item in attachments) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          for (final key in const [
            'url',
            'fileUrl',
            'ossUrl',
            'path',
            'filePath',
            'licenseUrl',
          ]) {
            final resolved = _resolveMediaUrl(_asTrimmed(m[key]));
            if (resolved != null) return resolved;
          }
        } else {
          final resolved = _resolveMediaUrl(_asTrimmed(item));
          if (resolved != null) return resolved;
        }
      }
    }
    // licenseOssId 有时直接是可访问路径 / 完整 URL。
    return _resolveMediaUrl(_asTrimmed(e['licenseOssId'] ?? e['ossId']));
  }

  /// 品牌库自媒体二维码：URL / data URL / 文件中心 fileId。
  Future<void> _hydrateMediaQr(
    _MediaDraft draft,
    Map<String, dynamic> media,
  ) async {
    var raw = _firstMediaQrRaw(media);
    if (raw is List && raw.isNotEmpty) raw = raw.first;
    if (raw == null) return;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final url = _mediaQrUrlFromMap(map);
      if (url != null) {
        draft.qrUrl = url;
        return;
      }
      final id = _asTrimmed(map['fileId'] ?? map['ossId'] ?? map['id']);
      if (id != null) draft.qrUrl = await _urlFromFileId(id);
      return;
    }
    final text = _asTrimmed(raw);
    if (text == null) return;
    if (text.startsWith('data:image')) {
      draft.qrBytes = _bytesFromDataUrl(text);
      return;
    }
    final resolved = _resolveMediaUrl(text);
    if (resolved != null) {
      draft.qrUrl = resolved;
      return;
    }
    draft.qrUrl = await _urlFromFileId(text);
  }

  dynamic _firstMediaQrRaw(Map<String, dynamic> media) {
    const preferred = [
      'qrCodeUrl',
      'qrUrl',
      'qrCode',
      'qrcode',
      'qrImage',
      'qrImageUrl',
      'qrOssUrl',
      'qrOssURL',
      'qrFileUrl',
      'qrOssId',
      'qrFileId',
      'qrCodeOssId',
      'accountQr',
      'accountQrUrl',
      'wechatQr',
      'qr',
    ];
    for (final key in preferred) {
      final value = media[key];
      if (_qrRawUsable(value)) return value;
    }
    for (final entry in media.entries) {
      final key = entry.key.toLowerCase();
      if (key == 'accounturl' || key == 'accountname' || key == 'mediatype') {
        continue;
      }
      if (!key.contains('qr') &&
          !key.contains('image') &&
          !key.contains('img') &&
          !key.contains('oss') &&
          !key.contains('pic')) {
        continue;
      }
      if (_qrRawUsable(entry.value)) return entry.value;
    }
    return null;
  }

  bool _qrRawUsable(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map || value is List) return value.isNotEmpty;
    return true;
  }

  String? _mediaQrUrlFromMap(Map<String, dynamic> map) {
    for (final key in const [
      'displayUrl',
      'previewUrl',
      'url',
      'qrUrl',
      'qrCodeUrl',
      'ossUrl',
      'fileUrl',
      'path',
      'objectUrl',
      'thumbnailUrl',
      'relativeUrl',
    ]) {
      final resolved = _resolveMediaUrl(_asTrimmed(map[key]));
      if (resolved != null) return resolved;
    }
    return null;
  }

  Uint8List? _bytesFromDataUrl(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    if (comma < 0 || comma >= dataUrl.length - 1) return null;
    try {
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _urlFromFileId(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    try {
      final info = await _fileCenterApi.fetchInfo(trimmed);
      final url = _resolveMediaUrl(info.displayUrl) ??
          _resolveMediaUrl(info.previewUrl) ??
          _resolveMediaUrl(info.url) ??
          _resolveMediaUrl(info.objectUrl) ??
          _resolveMediaUrl(info.thumbnailUrl) ??
          _resolveMediaUrl(info.relativeUrl) ??
          _resolveMediaUrl(info.objectRelativeUrl);
      if (url != null) return url;
    } catch (_) {}
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return '${ApiConfig.baseUrl}/desktop/resource/oss/download/$trimmed';
    }
    return null;
  }

  String? _resolveMediaUrl(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('data:')) return s;
    // 相对路径：拼到 API 同源根（去掉 /media-market-service 后通常也可访问静态资源）。
    if (s.startsWith('/')) {
      final base = Uri.parse(ApiConfig.baseUrl);
      final origin = base.hasPort
          ? '${base.scheme}://${base.host}:${base.port}'
          : '${base.scheme}://${base.host}';
      return '$origin$s';
    }
    // 形如 profile/xxx.jpg 的 OSS 相对路径。
    if (s.contains('/') || s.contains('.')) {
      final base = Uri.parse(ApiConfig.baseUrl);
      final origin = base.hasPort
          ? '${base.scheme}://${base.host}:${base.port}'
          : '${base.scheme}://${base.host}';
      return '$origin/$s';
    }
    return null;
  }

  void _hydrateEntityTax(_EntityDraft draft, Map<String, dynamic> e) {
    final p = 'ent_${draft.id}';
    draft.taxEntries.clear();
    final taxList = e['taxList'];
    if (taxList is List && taxList.isNotEmpty) {
      for (final raw in taxList) {
        if (raw is! Map) continue;
        final t = Map<String, dynamic>.from(raw);
        final td = _TaxEntryDraft(_nextId++, serverId: t['id']);
        draft.taxEntries.add(td);
        final tp = '${p}_tax_${td.id}';
        _putInit('${tp}_bankName', t['bankName'] ?? t['bankOfDeposit']);
        _putInit('${tp}_bankAccount', t['bankAccount'] ?? t['bankAccountNo']);
        _putInit('${tp}_invoiceName', t['invoiceName']);
        _putInit('${tp}_taxNo', t['taxNo']);
        _putInit(
          '${tp}_invoiceAddress',
          t['invoiceRegAddress'] ?? t['invoiceAddress'],
        );
        _putInit(
          '${tp}_invoicePhone',
          t['invoiceRegPhone'] ?? t['invoicePhone'],
        );
        _putInit('${tp}_invoiceBank', t['invoiceBank']);
        _putInit(
          '${tp}_invoiceAccount',
          t['invoiceBankAccount'] ?? t['invoiceAccount'],
        );
      }
    }
    if (draft.taxEntries.isEmpty) {
      final td = _TaxEntryDraft(_nextId++);
      draft.taxEntries.add(td);
      final tp = '${p}_tax_${td.id}';
      _putInit('${tp}_bankName', e['bankName'] ?? e['bankOfDeposit']);
      _putInit('${tp}_bankAccount', e['bankAccount'] ?? e['bankAccountNo']);
      _putInit('${tp}_invoiceName', e['invoiceName']);
      _putInit('${tp}_taxNo', e['taxNo']);
      _putInit(
        '${tp}_invoiceAddress',
        e['invoiceRegAddress'] ?? e['invoiceAddress'],
      );
      _putInit(
        '${tp}_invoicePhone',
        e['invoiceRegPhone'] ?? e['invoicePhone'],
      );
      _putInit('${tp}_invoiceBank', e['invoiceBank']);
      _putInit(
        '${tp}_invoiceAccount',
        e['invoiceBankAccount'] ?? e['invoiceAccount'],
      );
    }
  }

  void _hydratePerson(
    Map<String, dynamic> p,
    String prefix,
    int personId,
    Map<String, String> entNameToKey,
    List<_PendingCity> pendingCities,
  ) {
    _putInit('${prefix}_nameZh', p['name']);
    _putInit('${prefix}_nameEn', p['nameEn']);
    _putInit('${prefix}_gender', _genderToApi(p['gender']));
    _putInit('${prefix}_age', p['ageDesc']);
    final related = _asTrimmed(p['relatedEnterprise']);
    if (related != null) {
      _putInit(
        '${prefix}_enterprise',
        entNameToKey[related] ?? related,
      );
    }
    _putInit('${prefix}_address', p['address']);
    _putInit('${prefix}_title', p['deptTitle']);
    _putInit('${prefix}_role', p['jobDesc']);
    _putInit(
      '${prefix}_scope',
      _valuesFromLabelOrValue(_marketScopeOptions, p['marketScope']),
    );
    _putInit('${prefix}_brands', _asStringList(p['responsibleBrands']));
    _putInit('${prefix}_tenure', _valueFromLabelOrValue(_tenureOptions, p['tenure']));
    _putInit('${prefix}_mobile', p['phones']);
    _putInit('${prefix}_phone', p['tel']);
    _putInit('${prefix}_email', p['emails']);
    _putInit('${prefix}_remark', p['remark']);

    final split = _splitCombinedCity(_asTrimmed(p['city']));
    final provCode = _valueFromLabelOrValue(_provinceOptions, split.$1);
    _putInit('${prefix}_province', provCode);
    pendingCities.add(
      _PendingCity(
        draftId: personId,
        fieldName: '${prefix}_city',
        provinceCode: provCode,
        cityLabel: split.$2,
      ),
    );
  }

  Future<void> _loadPendingCities(List<_PendingCity> pending) async {
    await Future.wait([
      for (final item in pending) _loadOnePendingCity(item),
    ]);
  }

  Future<void> _loadOnePendingCity(_PendingCity item) async {
    final raw = item.provinceCode?.trim();
    if (raw == null || raw.isEmpty) return;
    final code = int.tryParse(raw);
    if (code == null) return;
    try {
      final cities = await _adCodeApi.fetchChildren(parentCode: code);
      if (!mounted) return;
      final opts = _adCodeToOptions(cities);
      _cityOptionsByDraftId[item.draftId] = opts;
      final cityCode = _valueFromLabelOrValue(opts, item.cityLabel);
      _putInit(item.fieldName, cityCode);
    } catch (_) {
      if (!mounted) return;
      _cityOptionsByDraftId[item.draftId] = const [];
    }
  }

  (String?, String?) _splitCombinedCity(String? combined) {
    final s = combined?.trim() ?? '';
    if (s.isEmpty) return (null, null);
    final labels = [
      for (final o in _provinceOptions) o.label,
    ]..sort((a, b) => b.length.compareTo(a.length));
    for (final p in labels) {
      if (p.isNotEmpty && s.startsWith(p)) {
        final rest = s.substring(p.length).trim();
        return (p, rest.isEmpty ? null : rest);
      }
    }
    return (null, s);
  }

  Map<String, dynamic> _buildCreateBody(Map<String, Object?> values) {
    // 以提交瞬间的表单值为准，避免类型切换后 state 未同步。
    _selectedCustomerType =
        _asTrimmed(values['customerType']) ?? _selectedCustomerType;
    final channelTypes = _asStringList(values['channelTypes']);
    _selectedChannelTypes = channelTypes;

    final agencyId = _asTrimmed(values['serviceAgencyId']);
    final vipAgencyIds = [
      for (final id in _asStringList(values['vipAgencyIds']))
        if (id.trim().isNotEmpty) int.tryParse(id) ?? id,
    ];
    final relatedAgencyIds = <dynamic>[
      if (_isBrandType && agencyId != null && agencyId.isNotEmpty)
        int.tryParse(agencyId) ?? agencyId,
      if (_isChannelType) ...vipAgencyIds,
    ];
    final salesList = <Map<String, dynamic>>[
      for (final s in _sales)
        {
          if (s.serverId != null) 'id': s.serverId,
          'userId': s.userId,
          'name': s.nameZh,
          'nameEn': s.nameEn == '-' ? '' : s.nameEn,
          'gender': _genderToApi(s.gender),
          'deptTitle': s.deptPost,
          'assignTime': s.createTime,
        },
    ];
    final ownerNames = [
      for (final s in _sales)
        if (s.nameZh.trim().isNotEmpty && s.nameZh != '-') s.nameZh.trim(),
    ].join(',');

    return {
      'customerType': _asTrimmed(values['customerType']),
      'marketScale': _asTrimmed(values['marketScale']),
      'name': _asTrimmed(values['name']),
      'industry': _joinOptionLabels(_industryOptions, values['industry']),
      'brandNature': _isBrandType ? _asTrimmed(values['brandNature']) : null,
      'revenueScale':
          _showRevenueScale ? _asTrimmed(values['revenueScale']) : null,
      'marketingBudget':
          _showMarketingBudget ? _asTrimmed(values['marketingBudget']) : null,
      'staffScale': _showStaffScale ? _asTrimmed(values['staffScale']) : null,
      'spokesperson':
          _showSpokesperson ? _asTrimmed(values['spokesperson']) : null,
      'website': _asTrimmed(values['website']),
      if (_editWeight != null) 'weight': _editWeight,
      'ownerNames': ownerNames.isEmpty ? null : ownerNames,
      'status': _asTrimmed(values['status']) ?? '0',
      'subBrands': _showSubBrands ? _asStringList(values['subBrands']) : null,
      'mediaList': _buildMediaList(values),
      'enterprises': _buildEnterprises(values),
      'contacts': [
        for (final c in _contacts) _buildContact(values, c),
      ],
      'salesList': salesList,
      'vipList': _showVipSection ? _buildVipList(values) : <dynamic>[],
      'serviceBrands': <dynamic>[],
      'channelTypes': _showChannelTypes ? channelTypes : <dynamic>[],
      'mediaResources': _showChannelTypes &&
              channelTypes.contains(_kOutdoorMediaType)
          ? _asStringList(values['mediaResources'])
          : <dynamic>[],
      'relatedAgencyIds': relatedAgencyIds,
    };
  }

  List<Map<String, dynamic>> _buildVipList(Map<String, Object?> values) {
    final out = <Map<String, dynamic>>[];
    for (final v in _vips) {
      final p = 'vip_${v.id}';
      final relatedId = _asTrimmed(values['${p}_relatedId']);
      final fullName = _asTrimmed(values['${p}_fullName']) ??
          _optionLabel(_channelCustomerOptions, relatedId);
      final brands = <Map<String, dynamic>>[
        for (final b in v.brands)
          {
            if (b.serverId != null) 'id': b.serverId,
            'brandName': _asTrimmed(values['vip_${v.id}_brand_${b.id}_name']),
            'serviceTypes': _asStringList(
              values['vip_${v.id}_brand_${b.id}_serviceTypes'],
            ),
          },
      ].where((e) {
        final name = e['brandName']?.toString().trim() ?? '';
        final types = e['serviceTypes'];
        return name.isNotEmpty || (types is List && types.isNotEmpty);
      }).toList();
      if (fullName == null && relatedId == null && brands.isEmpty) continue;
      out.add({
        if (v.serverId != null) 'id': v.serverId,
        'relatedCustomerId': relatedId,
        'fullName': fullName,
        'businessTypes': _asStringList(values['${p}_bizTypes']),
        'serviceBrands': brands,
      });
    }
    return out;
  }

  List<Map<String, dynamic>> _buildMediaList(Map<String, Object?> values) {
    final out = <Map<String, dynamic>>[];
    for (final m in _medias) {
      final platform = _asTrimmed(values['media_${m.id}_platform']);
      final account = _asTrimmed(values['media_${m.id}_account']);
      final link = _asTrimmed(values['media_${m.id}_link']);
      if (platform == null && account == null && link == null) continue;
      out.add({
        if (m.serverId != null) 'id': m.serverId,
        // 平台下拉 value 已是字典键值（如 wechat_mp）。
        'mediaType': platform,
        'accountName': account,
        'accountUrl': link,
      });
    }
    return out;
  }

  List<Map<String, dynamic>> _buildEnterprises(Map<String, Object?> values) {
    return [
      for (final e in _entities)
        {
          if (e.serverId != null) 'id': e.serverId,
          'fullName': _asTrimmed(values['ent_${e.id}_name']),
          'shortName': _asTrimmed(values['ent_${e.id}_shortName']),
          'relationType': _optionLabel(
            _relationOptions,
            _asTrimmed(values['ent_${e.id}_relation']),
          ),
          'entityNature': _asTrimmed(values['ent_${e.id}_nature']),
          'province': _optionLabel(
            _provinceOptions,
            _asTrimmed(values['ent_${e.id}_province']),
          ),
          'city': _optionLabel(
            _cityOptionsByDraftId[e.id] ?? const [],
            _asTrimmed(values['ent_${e.id}_city']),
          ),
          'address': _asTrimmed(values['ent_${e.id}_address']),
          if (_showEntityLicense) ...{
            'legalPerson': _asTrimmed(values['ent_${e.id}_legalPerson']),
            'regAddress': _asTrimmed(values['ent_${e.id}_regAddress']),
            'regPhone': _asTrimmed(values['ent_${e.id}_regPhone']),
            'creditCode': _asTrimmed(values['ent_${e.id}_creditCode']),
            'regCapital': _asTrimmed(values['ent_${e.id}_regCapital']),
            'establishDate': _asTrimmed(values['ent_${e.id}_establishDate']),
            'licenseExpire': _asTrimmed(values['ent_${e.id}_licenseExpire']),
            'licenseValidPeriod':
                _asTrimmed(values['ent_${e.id}_licenseExpire']),
            'businessScope': _asTrimmed(values['ent_${e.id}_businessScope']),
            'abnormalRecord':
                _asTrimmed(values['ent_${e.id}_abnormalRecord']),
            'penaltyHistory':
                _asTrimmed(values['ent_${e.id}_penaltyHistory']),
            if (e.licenseOssId != null && e.licenseOssId!.isNotEmpty)
              'licenseOssId': e.licenseOssId,
            if (e.licenseUrl != null && e.licenseUrl!.isNotEmpty) ...{
              'licenseOssURL': e.licenseUrl,
              'licenseUrl': e.licenseUrl,
            },
            ..._enterpriseTaxPayload(e, values),
          },
          'marketScope': _showEntityMarketScope
              ? _joinOptionLabels(
                  _marketScopeOptions,
                  values['ent_${e.id}_scope'],
                )
              : null,
          'businessTypes': _showEntityBizTypes
              ? _asStringList(values['ent_${e.id}_bizTypes'])
              : null,
          'remark': _asTrimmed(values['ent_${e.id}_remark']),
        },
    ];
  }

  Map<String, dynamic> _enterpriseTaxPayload(
    _EntityDraft e,
    Map<String, Object?> values,
  ) {
    final list = <Map<String, dynamic>>[];
    for (final t in e.taxEntries) {
      final tp = 'ent_${e.id}_tax_${t.id}';
      final row = <String, dynamic>{
        if (t.serverId != null) 'id': t.serverId,
        'bankName': _asTrimmed(values['${tp}_bankName']),
        'bankAccount': _asTrimmed(values['${tp}_bankAccount']),
        'invoiceName': _asTrimmed(values['${tp}_invoiceName']),
        'taxNo': _asTrimmed(values['${tp}_taxNo']),
        'invoiceRegAddress': _asTrimmed(values['${tp}_invoiceAddress']),
        'invoiceRegPhone': _asTrimmed(values['${tp}_invoicePhone']),
        'invoiceBank': _asTrimmed(values['${tp}_invoiceBank']),
        'invoiceBankAccount': _asTrimmed(values['${tp}_invoiceAccount']),
        // 兼容旧字段名
        'invoiceAddress': _asTrimmed(values['${tp}_invoiceAddress']),
        'invoicePhone': _asTrimmed(values['${tp}_invoicePhone']),
        'invoiceAccount': _asTrimmed(values['${tp}_invoiceAccount']),
      };
      final hasAny = row.entries.any(
        (kv) =>
            kv.key != 'id' &&
            kv.value is String &&
            (kv.value as String).trim().isNotEmpty,
      );
      if (hasAny || t.serverId != null) list.add(row);
    }
    final first = list.isEmpty ? null : list.first;
    return {
      'taxList': list,
      'bankName': first?['bankName'],
      'bankAccount': first?['bankAccount'],
      'invoiceName': first?['invoiceName'],
      'taxNo': first?['taxNo'],
      'invoiceAddress': first?['invoiceAddress'],
      'invoicePhone': first?['invoicePhone'],
      'invoiceBank': first?['invoiceBank'],
      'invoiceAccount': first?['invoiceAccount'],
      'invoiceRegAddress': first?['invoiceRegAddress'],
      'invoiceRegPhone': first?['invoiceRegPhone'],
      'invoiceBankAccount': first?['invoiceBankAccount'],
    };
  }

  Map<String, dynamic> _buildContact(
    Map<String, Object?> values,
    _ContactDraft contact,
  ) {
    final person = _buildPerson(
      values,
      'ct_${contact.id}',
      contact.id,
      serverId: contact.serverId,
    );
    person['superiors'] = [
      for (final s in contact.superiors)
        _buildPerson(
          values,
          'ct_${contact.id}_sup_${s.id}',
          s.id,
          serverId: s.serverId,
        ),
    ];
    person['subordinates'] = [
      for (final s in contact.subordinates)
        _buildPerson(
          values,
          'ct_${contact.id}_sub_${s.id}',
          s.id,
          serverId: s.serverId,
        ),
    ];
    return person;
  }

  Map<String, dynamic> _buildPerson(
    Map<String, Object?> values,
    String prefix,
    int personId, {
    Object? serverId,
  }) {
    final provinceCode = _asTrimmed(values['${prefix}_province']);
    final cityCode = _asTrimmed(values['${prefix}_city']);
    final provinceLabel =
        _optionLabel(_provinceOptions, provinceCode) ?? '';
    final cityLabel = _optionLabel(
          _cityOptionsByDraftId[personId] ?? const [],
          cityCode,
        ) ??
        '';
    final cityCombined = '$provinceLabel$cityLabel'.trim();
    final entKey = _asTrimmed(values['${prefix}_enterprise']);
    return {
      if (serverId != null) 'id': serverId,
      'name': _asTrimmed(values['${prefix}_nameZh']),
      'nameEn': _asTrimmed(values['${prefix}_nameEn']),
      'gender': _genderToApi(values['${prefix}_gender']),
      'ageDesc': _asTrimmed(values['${prefix}_age']),
      'relatedEnterprise': _enterpriseFullName(values, entKey),
      'city': cityCombined.isEmpty ? null : cityCombined,
      'address': _asTrimmed(values['${prefix}_address']),
      'deptTitle': _asTrimmed(values['${prefix}_title']),
      'jobDesc': _asTrimmed(values['${prefix}_role']),
      'marketScope': _joinOptionLabels(
        _marketScopeOptions,
        values['${prefix}_scope'],
      ),
      'responsibleBrands': _joinPlain(values['${prefix}_brands']),
      'phones': _asTrimmed(values['${prefix}_mobile']),
      'tel': _asTrimmed(values['${prefix}_phone']),
      'emails': _asTrimmed(values['${prefix}_email']),
      'tenure': _asTrimmed(values['${prefix}_tenure']),
      'remark': _asTrimmed(values['${prefix}_remark']),
    };
  }

  String? _enterpriseFullName(Map<String, Object?> values, String? entKey) {
    final key = entKey?.trim();
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('ent-')) {
      final id = key.substring(4);
      return _asTrimmed(values['ent_${id}_name']) ?? key;
    }
    return key;
  }

  String? _genderToApi(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    return switch (s) {
      '男' => '1',
      '女' => '2',
      '未知' => '0',
      '0' || '1' || '2' => s,
      _ => s.isEmpty ? null : s,
    };
  }

  String _genderLabel(dynamic raw) {
    final api = _genderToApi(raw);
    return switch (api) {
      '1' => '男',
      '2' => '女',
      '0' => '未知',
      _ => (raw?.toString().trim().isNotEmpty ?? false)
          ? raw.toString().trim()
          : '-',
    };
  }

  String? _mediaPlatformFromApi(String? type) {
    if (type == null || type.isEmpty) return null;
    final normalized = _kMediaTypeFromApi[type] ?? type;
    return _valueFromLabelOrValue(_mediaPlatformOptions, normalized) ??
        normalized;
  }

  /// 品牌库回填：字典编码转成中文标签（表单选项 value 即 dictLabel）。
  String? _libraryDictLabel(String dictType, dynamic raw) {
    final text = _libraryText(raw);
    if (text == null) return null;
    for (final item in _dictItems[dictType] ?? const <DictDataItem>[]) {
      final label = item.dictLabel?.trim();
      final code = item.dictValue?.trim();
      if (label == null || label.isEmpty) continue;
      if (text == label || text == code) return label;
    }
    return text;
  }

  /// 服务 4A：下拉展示中文名称。能对上已有客户则用其 id，否则用中文名补一条选项。
  void _applyLibraryServiceAgency(Map<String, dynamic> data) {
    var raw = data['serviceAgency'] ??
        data['serviceAgencyName'] ??
        data['agencyName'];
    if (raw is List) {
      raw = raw.isEmpty ? null : raw.first;
    }
    String? id = _asTrimmed(data['serviceAgencyId']);
    String? name;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      id ??= _asTrimmed(map['id'] ?? map['customerId'] ?? map['agencyId']);
      name = _libraryText(
        map['name'] ??
            map['brandName'] ??
            map['agencyName'] ??
            map['label'] ??
            map['nameZh'] ??
            map['fullName'],
      );
    } else {
      name = _libraryText(data['serviceAgencyName'] ?? data['agencyName']);
      final plain = _libraryText(raw);
      id ??= plain;
      name ??= plain;
    }
    final resolved = _resolveAgencyOption(id: id, name: name);
    if (resolved != null) _putInit('serviceAgencyId', resolved);
  }

  String? _resolveAgencyOption({String? id, String? name}) {
    for (final option in _agencyOptions) {
      if (id != null && id.isNotEmpty && option.value == id) return option.value;
      if (name != null &&
          name.isNotEmpty &&
          (option.label == name || option.value == name)) {
        return option.value;
      }
    }
    final display = _preferChinese([name, id]);
    if (display == null) return null;
    if (!_agencyOptions.any(
      (option) => option.value == display || option.label == display,
    )) {
      _agencyOptions = [
        ..._agencyOptions,
        AppOption(value: display, label: display),
      ];
    }
    for (final option in _agencyOptions) {
      if (option.label == display || option.value == display) return option.value;
    }
    return display;
  }

  String? _libraryText(dynamic raw) {
    if (raw is Map) {
      return _preferChinese([
        _asTrimmed(raw['dictLabel']),
        _asTrimmed(raw['label']),
        _asTrimmed(raw['name']),
        _asTrimmed(raw['nameZh']),
        _asTrimmed(raw['dictValue']),
        _asTrimmed(raw['value']),
        _asTrimmed(raw['code']),
      ]);
    }
    return _asTrimmed(raw);
  }

  String? _preferChinese(List<String?> parts) {
    String? fallback;
    for (final part in parts) {
      final text = part?.trim() ?? '';
      if (text.isEmpty) continue;
      fallback ??= text;
      if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) return text;
    }
    return fallback;
  }

  String? _valueFromLabelOrValue(
    List<AppOption<String>> options,
    dynamic raw,
  ) {
    final s = _asTrimmed(raw);
    if (s == null) return null;
    for (final o in options) {
      if (o.value == s || o.label == s) return o.value;
    }
    return s;
  }

  List<String> _valuesFromLabelOrValue(
    List<AppOption<String>> options,
    dynamic raw,
  ) {
    return [
      for (final part in _asStringList(raw))
        _valueFromLabelOrValue(options, part) ?? part,
    ];
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String? _asTrimmed(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  List<String> _asStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is Iterable) {
      return [
        for (final e in raw)
          if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    return [
      for (final p in s.split(','))
        if (p.trim().isNotEmpty) p.trim(),
    ];
  }

  String? _joinPlain(dynamic raw) {
    final list = _asStringList(raw);
    if (list.isEmpty) return null;
    return list.join(',');
  }

  String? _optionLabel(List<AppOption<String>> options, String? value) {
    if (value == null || value.isEmpty) return null;
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return value;
  }

  String? _joinOptionLabels(List<AppOption<String>> options, dynamic raw) {
    final list = _asStringList(raw);
    if (list.isEmpty) return null;
    return [
      for (final v in list) _optionLabel(options, v) ?? v,
    ].join(',');
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 12,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: _kSectionTitle,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        ?action,
      ],
    );
  }

  Widget _addLink(String label, VoidCallback onPressed) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: _kPrimary),
            const SizedBox(width: 1),
            Text(
              label,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Widget left, [Widget? right]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right ?? const SizedBox.shrink()),
      ],
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _kEmptyBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kCardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.3),
      ),
    );
  }

  Widget _card({
    required String title,
    required VoidCallback onDelete,
    required String deleteLabel,
    required List<Widget> children,
    Widget? trailingAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppInkWell(
                onPressed: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    deleteLabel,
                    style: const TextStyle(
                      color: _kDanger,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 8),
                trailingAction,
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _ocrTextLink(VoidCallback onPressed) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          '上传图片识别文本',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _sectionActions(List<Widget> actions) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i],
        ],
      ],
    );
  }

  Widget _textLink(String label, VoidCallback onPressed) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _subHeading(String text, {Widget? action}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: _kTitle,
          ),
        ),
        const Spacer(),
        ?action,
      ],
    );
  }

  Widget _contactBasicInfoActions(
    int contactIndex,
    void Function(VoidCallback) setContactState,
  ) {
    return _textLink(
      '上传 VCF',
      () => _importVcfForContact(contactIndex, setContactState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppForm(
      controller: _form,
      child: HyperDialog(
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 860),
        onClose: widget.onClose,
        title: Text(widget.title),
        content: DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 12, color: _kLabel, height: 1.35),
          child: _bootLoading
              ? const SizedBox(
                  height: 180,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('基础信息'),
                        const SizedBox(height: 8),
                        _row(
                          AppSelectFormField<String>(
                            name: 'customerType',
                            label: '客户类型',
                            required: true,
                            options: _customerTypeOptions,
                            initialValue: _customerTypeInitial,
                            onChanged: _onCustomerTypeChanged,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _row(
                          AppSelectFormField<String>(
                            name: 'marketScale',
                            label: '市场量级',
                            options: _marketScaleOptions,
                            initialValue: _marketScaleInitial,
                          ),
                          AppRadioGroupFormField<String>(
                            name: 'status',
                            label: '状态',
                            options: _kStatusOptions,
                            initialValue: _statusInitial ?? '0',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sectionTitle(
                          '品牌信息',
                          action: _ocrTextLink(_ocrFillBrand),
                        ),
                        const SizedBox(height: 8),
                        KeyedSubtree(
                          key: ValueKey(
                            'brand-info-$_customerTypeCode-$_brandInfoEpoch',
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildBrandInfoFields(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // 各动态分区用 StatefulBuilder 局部刷新，避免整页卡顿。
                        StatefulBuilder(
                          builder: (context, setMediaState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionTitle(
                                  '自媒体矩阵',
                                  action: _sectionActions([
                                    _ocrTextLink(
                                      () => _ocrFillMedia(setMediaState),
                                    ),
                                    _addLink('添加', () {
                                      setMediaState(
                                        () => _medias.add(
                                          _MediaDraft(_nextId++),
                                        ),
                                      );
                                    }),
                                  ]),
                                ),
                                if (_medias.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _emptyHint(
                                      '暂无自媒体账号，点击右上角添加',
                                    ),
                                  )
                                else
                                  for (var i = 0; i < _medias.length; i++)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        8,
                                        10,
                                        8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _kCardBorder,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 148,
                                            child: AppSelectFormField<String>(
                                              name:
                                                  'media_${_medias[i].id}_platform',
                                              options: _mediaPlatformOptions,
                                              initialValue: _initStr(
                                                    'media_${_medias[i].id}_platform',
                                                  ) ??
                                                  (_mediaPlatformOptions
                                                          .isEmpty
                                                      ? null
                                                      : _mediaPlatformOptions
                                                          .first
                                                          .value),
                                              hintText: '请选择',
                                              minWidth: 0,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: AppTextFormField(
                                              name:
                                                  'media_${_medias[i].id}_account',
                                              density: AppDensity.compact,
                                              hintText: '账号名',
                                              initialValue: _initStr(
                                                'media_${_medias[i].id}_account',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: AppTextFormField(
                                              name:
                                                  'media_${_medias[i].id}_link',
                                              density: AppDensity.compact,
                                              hintText: '链接',
                                              initialValue: _initStr(
                                                'media_${_medias[i].id}_link',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _MediaQrPicker(
                                            bytes: _medias[i].qrBytes,
                                            networkUrl: _medias[i].qrUrl,
                                            onPicked: (bytes) =>
                                                setMediaState(() {
                                              _medias[i].qrBytes = bytes;
                                              _medias[i].qrUrl = null;
                                            }),
                                            onCleared: () => setMediaState(() {
                                              _medias[i].qrBytes = null;
                                              _medias[i].qrUrl = null;
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          AppInkWell(
                                            onPressed: () => setMediaState(
                                              () => _medias.removeAt(i),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 6,
                                              ),
                                              child: Text(
                                                '删除',
                                                style: TextStyle(
                                                  color: _kDanger,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        StatefulBuilder(
                          builder: (context, setEntityState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionTitle(
                                  '经营主体信息',
                                  action: _sectionActions([
                                    _ocrTextLink(
                                      () => _ocrFillEntity(setEntityState),
                                    ),
                                    _addLink('添加', () {
                                      setEntityState(() {
                                        _entities.add(_newEntityDraft());
                                        _bumpEntities();
                                      });
                                    }),
                                  ]),
                                ),
                                for (var i = 0; i < _entities.length; i++)
                                  _card(
                                    title: '经营主体 ${i + 1}',
                                    deleteLabel: '删除主体',
                                    onDelete: () {
                                      if (_entities.length <= 1) return;
                                      final id = _entities[i].id;
                                      setEntityState(() {
                                        _entities.removeAt(i);
                                        _cityOptionsByDraftId.remove(id);
                                        _cityEpochByDraftId.remove(id);
                                        _entityEpochByDraftId.remove(id);
                                        _abnormalEpochByDraftId.remove(id);
                                        _bankOcrLoadingIds.remove(id);
                                        _licenseOcrLoadingIds.remove(id);
                                        _abnormalQueryLoadingIds.remove(id);
                                        _bumpEntities();
                                      });
                                    },
                                    children: _buildEntityFields(
                                      i,
                                      setEntityState,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        if (_showVipSection) ...[
                          const SizedBox(height: 14),
                          StatefulBuilder(
                            builder: (context, setVipState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _sectionTitle(
                                    'VIP 公司信息',
                                    action: _addLink('添加', () {
                                      setVipState(() {
                                        _vips.add(
                                          _VipDraft(_nextId++)
                                            ..brands.add(
                                              _VipBrandDraft(_nextId++),
                                            ),
                                        );
                                      });
                                    }),
                                  ),
                                  if (_vips.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _emptyHint(
                                        '可创建多个；选渠道广告公司或手工填写',
                                      ),
                                    )
                                  else
                                    for (var i = 0; i < _vips.length; i++)
                                      _card(
                                        title: 'VIP 公司 ${i + 1}',
                                        deleteLabel: '删除',
                                        onDelete: () => setVipState(
                                          () => _vips.removeAt(i),
                                        ),
                                        children: _buildVipFields(
                                          i,
                                          setVipState,
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        StatefulBuilder(
                          builder: (context, setContactState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionTitle(
                                  '联系人信息',
                                  action: _sectionActions([
                                    _ocrTextLink(
                                      () => _ocrFillContact(setContactState),
                                    ),
                                    _addLink('添加', () {
                                      setContactState(
                                        () => _contacts.add(
                                          _ContactDraft(_nextId++),
                                        ),
                                      );
                                    }),
                                  ]),
                                ),
                                for (var i = 0; i < _contacts.length; i++)
                                  _card(
                                    title: '联系人 ${i + 1}',
                                    deleteLabel: '删除联系人',
                                    onDelete: () {
                                      if (_contacts.length <= 1) return;
                                      final contact = _contacts[i];
                                      setContactState(() {
                                        void clearPerson(int personId) {
                                          _cityOptionsByDraftId.remove(personId);
                                          _cityEpochByDraftId.remove(personId);
                                          _personEpochByDraftId.remove(personId);
                                          _releasePersonNameEn(personId);
                                        }

                                        clearPerson(contact.id);
                                        for (final p in contact.superiors) {
                                          clearPerson(p.id);
                                        }
                                        for (final p in contact.subordinates) {
                                          clearPerson(p.id);
                                        }
                                        _contacts.removeAt(i);
                                      });
                                    },
                                    children: _buildContactFields(
                                      i,
                                      setContactState,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        StatefulBuilder(
                          builder: (context, setSalesState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionTitle(
                                  '销售人员信息',
                                  action: _addLink('添加', () async {
                                    final picked =
                                        await showSelectSalesPersonDialog(
                                      context,
                                      alreadySelectedUserIds: {
                                        for (final s in _sales) s.userId,
                                      },
                                    );
                                    if (picked == null || picked.isEmpty) {
                                      return;
                                    }
                                    setSalesState(() {
                                      final exist = {
                                        for (final s in _sales) s.userId,
                                      };
                                      for (final e in picked) {
                                        final uid = e.userId;
                                        if (uid == null || exist.contains(uid)) {
                                          continue;
                                        }
                                        exist.add(uid);
                                        _sales.add(
                                          _SalesDraft.fromEmployee(
                                            e,
                                            _nextId++,
                                          ),
                                        );
                                      }
                                    });
                                  }),
                                ),
                                if (_sales.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _emptyHint(
                                      '从组织架构选择销售人员，可添加多个',
                                    ),
                                  )
                                else
                                  for (var i = 0; i < _sales.length; i++)
                                    _buildSalesCard(i, setSalesState),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
        ),
        actions: [
          HyperButton.filled(
            onPressed: _bootLoading ? null : _submit,
            label: const Text('确定'),
          ),
          HyperButton.outlined(
            onPressed: widget.onClose,
            label: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 品牌简称：可输入联想品牌库；企业简称仍用手输。
  Widget _brandNameField({required String label, required String hint}) {
    final initial = _initStr('name');
    if (_showBrandShortName) {
      return AppComboboxFormField<String>.async(
        name: 'name',
        label: label,
        required: true,
        hintText: hint,
        clearable: true,
        debounce: const Duration(milliseconds: 300),
        cacheDuration: Duration.zero,
        initialValue: initial,
        initialOption: initial == null
            ? null
            : AppOption(value: initial, label: initial),
        searchOptions: _searchBrandLibraryOptions,
        validator: AppValidators.required(message: '请输入$label'),
        onChanged: _onBrandNamePicked,
      );
    }
    return AppTextFormField(
      name: 'name',
      label: label,
      required: true,
      density: AppDensity.compact,
      hintText: hint,
      initialValue: initial,
      validator: AppValidators.required(message: '请输入$label'),
      onChanged: (v) => _syncBrandChoices(name: v),
    );
  }

  List<Widget> _buildBrandInfoFields() {
    final nameLabel = _showBrandShortName ? '品牌简称' : '企业简称';
    final nameHint = _showBrandShortName
        ? (_brandLibraryFilling ? '正在回填品牌库…' : '输入搜索品牌库，或直接选用新名称')
        : '档案展示用简称';
    final out = <Widget>[
      if (_showSubBrands)
        _row(
          _brandNameField(label: nameLabel, hint: nameHint),
          AppMultiSelectFormField<String>(
            name: 'subBrands',
            label: '关联子品牌',
            description: '从已有品牌中多选',
            options: _subBrandSelectOptions(),
            initialValue: _initList('subBrands'),
            onChanged: (v) => _syncBrandChoices(subBrands: v),
          ),
        )
      else
        _brandNameField(label: nameLabel, hint: nameHint),
      const SizedBox(height: 6),
      if (_showBrandNature)
        _row(
          AppMultiSelectFormField<String>(
            name: 'industry',
            label: '所属行业',
            description: '多选',
            options: _industryOptions,
            initialValue: _initList('industry'),
          ),
          AppSelectFormField<String>(
            name: 'brandNature',
            label: '品牌性质',
            hintText: '请选择',
            options: _brandNatureOptions,
            clearable: true,
            initialValue: _initStr('brandNature'),
          ),
        )
      else if (_showChannelTypes)
        _row(
          AppMultiSelectFormField<String>(
            name: 'industry',
            label: '所属行业',
            description: '多选',
            options: _industryOptions,
            initialValue: _initList('industry'),
          ),
          AppMultiSelectFormField<String>(
            name: 'channelTypes',
            label: '所属类型',
            description: '企业类型，多选',
            options: _kChannelTypeOptions,
            initialValue: _initList('channelTypes').isNotEmpty
                ? _initList('channelTypes')
                : _selectedChannelTypes,
            onChanged: _onChannelTypesChanged,
          ),
        )
      else
        AppMultiSelectFormField<String>(
          name: 'industry',
          label: '所属行业',
          description: '多选',
          options: _industryOptions,
          initialValue: _initList('industry'),
        ),
    ];

    if (_showChannelTypes &&
        _selectedChannelTypes.contains(_kOutdoorMediaType)) {
      out.addAll([
        const SizedBox(height: 6),
        AppMultiSelectFormField<String>(
          name: 'mediaResources',
          label: '媒体资源标签',
          description: '户外媒体运营子项',
          options: _kMediaResourceOptions,
          initialValue: _initList('mediaResources'),
        ),
      ]);
    }
    if (_showChannelTypes &&
        _selectedChannelTypes.contains(_k4aVipChannelType)) {
      out.addAll([
        const SizedBox(height: 6),
        AppMultiSelectFormField<String>(
          name: 'vipAgencyIds',
          label: '关联 4A 公司',
          description: '4A公司VIP 子项',
          options: [
            for (final o in _agencyOptions)
              if (o.value.trim().isNotEmpty) o,
          ],
          initialValue: _initList('vipAgencyIds'),
        ),
      ]);
    }

    if (_showRevenueScale || _showStaffScale || _showMarketingBudget) {
      out.add(const SizedBox(height: 6));
      if (_showStaffScale) {
        out.add(
          _row(
            AppSelectFormField<String>(
              name: 'revenueScale',
              label: '营收规模/年',
              hintText: '请选择',
              options: _revenueOptions,
              clearable: true,
              initialValue: _initStr('revenueScale'),
            ),
            AppSelectFormField<String>(
              name: 'staffScale',
              label: '人员规模/人',
              hintText: '请选择',
              options: _kStaffScaleOptions,
              clearable: true,
              initialValue: _initStr('staffScale'),
            ),
          ),
        );
      } else if (_showMarketingBudget) {
        out.add(
          _row(
            AppSelectFormField<String>(
              name: 'revenueScale',
              label: '营收规模/年',
              hintText: '请选择',
              options: _revenueOptions,
              clearable: true,
              initialValue: _initStr('revenueScale'),
            ),
            AppSelectFormField<String>(
              name: 'marketingBudget',
              label: '营销费规模/年',
              hintText: '请选择',
              options: _marketingBudgetOptions,
              clearable: true,
              initialValue: _initStr('marketingBudget'),
            ),
          ),
        );
      } else {
        out.add(
          AppSelectFormField<String>(
            name: 'revenueScale',
            label: '营收规模/年',
            hintText: '请选择',
            options: _revenueOptions,
            clearable: true,
            initialValue: _initStr('revenueScale'),
          ),
        );
      }
    }

    if (_showSpokesperson || _showServiceAgency) {
      out.addAll([
        const SizedBox(height: 6),
        _row(
          AppTextFormField(
            name: 'spokesperson',
            label: '代言人信息',
            density: AppDensity.compact,
            hintText: '可自动填充或手动填写',
            initialValue: _initStr('spokesperson'),
          ),
          AppSelectFormField<String>(
            name: 'serviceAgencyId',
            label: '服务 4A 公司',
            hintText: '无 / 选择词库',
            clearable: true,
            options: _agencyOptions,
            initialValue: _initStr('serviceAgencyId'),
          ),
        ),
      ]);
    }

    out.addAll([
      const SizedBox(height: 6),
      AppTextFormField(
        name: 'website',
        label: '网址',
        density: AppDensity.compact,
        hintText: 'https://www.example.com',
        initialValue: _initStr('website'),
      ),
    ]);
    return out;
  }

  List<Widget> _buildVipFields(
    int i,
    void Function(VoidCallback) setVipState,
  ) {
    final vip = _vips[i];
    final id = vip.id;
    return [
      _row(
        AppSelectFormField<String>(
          name: 'vip_${id}_relatedId',
          label: '企业全称（选）',
          hintText: '从渠道广告公司选择',
          options: _channelCustomerOptions,
          clearable: true,
          initialValue: _initStr('vip_${id}_relatedId'),
        ),
        AppTextFormField(
          name: 'vip_${id}_fullName',
          label: '企业全称（填）',
          density: AppDensity.compact,
          hintText: '或手工新增填写',
          initialValue: _initStr('vip_${id}_fullName'),
        ),
      ),
      const SizedBox(height: 8),
      AppMultiSelectFormField<String>(
        name: 'vip_${id}_bizTypes',
        label: '业务类型',
        options: _kBizTypeOptions,
        initialValue: _initList('vip_${id}_bizTypes'),
      ),
      const SizedBox(height: 10),
      _sectionTitle(
        '服务品牌',
        action: _addLink('添加品牌', () {
          setVipState(() => vip.brands.add(_VipBrandDraft(_nextId++)));
        }),
      ),
      for (var j = 0; j < vip.brands.length; j++) ...[
        const SizedBox(height: 8),
        _row(
          AppTextFormField(
            name: 'vip_${id}_brand_${vip.brands[j].id}_name',
            label: '品牌名称',
            density: AppDensity.compact,
            initialValue: _initStr(
              'vip_${id}_brand_${vip.brands[j].id}_name',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AppMultiSelectFormField<String>(
                  name: 'vip_${id}_brand_${vip.brands[j].id}_serviceTypes',
                  label: '服务类型',
                  options: _kBizTypeOptions,
                  initialValue: _initList(
                    'vip_${id}_brand_${vip.brands[j].id}_serviceTypes',
                  ),
                ),
              ),
              if (vip.brands.length > 1) ...[
                const SizedBox(width: 8),
                AppInkWell(
                  onPressed: () => setVipState(() => vip.brands.removeAt(j)),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      '删除',
                      style: TextStyle(color: _kDanger, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildTaxEntryFields({
    required int entityIndex,
    required int taxIndex,
    required void Function(VoidCallback) setEntityState,
  }) {
    final entity = _entities[entityIndex];
    final entityId = entity.id;
    final tax = entity.taxEntries[taxIndex];
    final tp = 'ent_${entityId}_tax_${tax.id}';
    final n = taxIndex + 1;
    return [
      Row(
        children: [
          Text(
            '银行账户信息 $n',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kSectionTitle,
            ),
          ),
          const Spacer(),
          if (taxIndex == 0)
            if (_bankOcrLoadingIds.contains(entityId))
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              _textLink(
                '上传开户许可证或基本存款账户信息',
                () => _ocrBankAccountLicense(entityId, setEntityState),
              ),
          if (entity.taxEntries.length > 1) ...[
            const SizedBox(width: 8),
            AppInkWell(
              onPressed: () => setEntityState(() {
                entity.taxEntries.removeAt(taxIndex);
              }),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  '删除',
                  style: TextStyle(color: _kDanger, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_bankName',
        label: '开户行',
        density: AppDensity.compact,
        hintText: '请选择开户行（省 / 市 / 支行）',
        initialValue: _initStr('${tp}_bankName'),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_bankAccount',
        label: '银行账号',
        density: AppDensity.compact,
        hintText: '请输入',
        initialValue: _initStr('${tp}_bankAccount'),
      ),
      const SizedBox(height: 12),
      Text(
        '开票信息 $n',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kSectionTitle,
        ),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_invoiceName',
        label: '名称',
        density: AppDensity.compact,
        hintText: 'OCR 识别或手填',
        initialValue: _initStr('${tp}_invoiceName'),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_taxNo',
        label: '税号',
        density: AppDensity.compact,
        hintText: 'OCR 识别或手填',
        initialValue: _initStr('${tp}_taxNo'),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_invoiceAddress',
        label: '注册地址',
        density: AppDensity.compact,
        hintText: 'OCR 识别或手填',
        initialValue: _initStr('${tp}_invoiceAddress'),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_invoicePhone',
        label: '注册电话',
        density: AppDensity.compact,
        hintText: '请输入',
        initialValue: _initStr('${tp}_invoicePhone'),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_invoiceBank',
        label: '开户银行',
        density: AppDensity.compact,
        hintText: '请选择开户行（省 / 市 / 支行）',
        initialValue: _initStr('${tp}_invoiceBank'),
      ),
      const SizedBox(height: 8),
      AppTextFormField(
        name: '${tp}_invoiceAccount',
        label: '开户银行账号',
        density: AppDensity.compact,
        hintText: '请输入',
        initialValue: _initStr('${tp}_invoiceAccount'),
      ),
    ];
  }

  List<Widget> _buildEntityFields(
    int i,
    void Function(VoidCallback) setEntityState,
  ) {
    final id = _entities[i].id;
    final ocrEpoch = _entityEpochByDraftId[id] ?? 0;
    return [
      // OCR 回填会改 initials；需 Key 重建才能吃到新 initialValue。
      KeyedSubtree(
        key: ValueKey('ent-ocr-basic-$id-$ocrEpoch'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextFormField(
              name: 'ent_${id}_name',
              label: '主体全称',
              required: true,
              density: AppDensity.compact,
              hintText: '请输入经营主体全称',
              initialValue: _initStr('ent_${id}_name'),
              validator: AppValidators.required(message: '请输入主体全称'),
            ),
            const SizedBox(height: 8),
            AppTextFormField(
              name: 'ent_${id}_shortName',
              label: '企业简称',
              density: AppDensity.compact,
              hintText: '经营主体的企业/品牌简称',
              initialValue: _initStr('ent_${id}_shortName'),
            ),
            const SizedBox(height: 8),
            _row(
              AppSelectFormField<String>(
                name: 'ent_${id}_relation',
                label: '关联关系',
                hintText: '请选择',
                options: _relationOptions,
                initialValue:
                    _initStr('ent_${id}_relation') ?? _relationInitial,
                clearable: true,
              ),
              AppSelectFormField<String>(
                name: 'ent_${id}_nature',
                label: '主体性质',
                hintText: '请选择',
                options: _entityNatureOptions,
                initialValue:
                    _initStr('ent_${id}_nature') ?? _entityNatureInitial,
                clearable: true,
              ),
            ),
            const SizedBox(height: 8),
            if (_showEntityMarketScope) ...[
              AppMultiSelectFormField<String>(
                name: 'ent_${id}_scope',
                label: '市场范围',
                options: _marketScopeOptions,
                initialValue: _initList('ent_${id}_scope'),
              ),
              const SizedBox(height: 8),
            ] else if (_showEntityBizTypes) ...[
              AppMultiSelectFormField<String>(
                name: 'ent_${id}_bizTypes',
                label: '业务类型',
                options: _kBizTypeOptions,
                initialValue: _initList('ent_${id}_bizTypes'),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppSelectFormField<String>(
                    name: 'ent_${id}_province',
                    label: '所在城市',
                    hintText: '省',
                    options: _provinceOptions,
                    clearable: true,
                    initialValue: _initStr('ent_${id}_province'),
                    onChanged: (v) => _onProvinceChanged(id, v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _cityRevision,
                    builder: (context, _, _) {
                      return KeyedSubtree(
                        key: ValueKey(
                          'ent-city-$id-${_cityEpochByDraftId[id] ?? 0}',
                        ),
                        child: AppSelectFormField<String>(
                          name: 'ent_${id}_city',
                          label: ' ',
                          hintText: '市',
                          options: _cityOptionsByDraftId[id] ?? const [],
                          clearable: true,
                          initialValue: _initStr('ent_${id}_city'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AppTextFormField(
              name: 'ent_${id}_address',
              label: '详细地址',
              density: AppDensity.compact,
              hintText: '详细地址',
              initialValue: _initStr('ent_${id}_address'),
            ),
          ],
        ),
      ),
      if (_showEntityLicense) ...[
      const SizedBox(height: 10),
      _subHeading('营业执照信息'),
      const SizedBox(height: 4),
      const Text(
        '可上传电子营业执照；上传后自动识别填充法人/注册地址等',
        style: TextStyle(fontSize: 11, color: _kMuted, height: 1.35),
      ),
      const SizedBox(height: 8),
      const Text(
        '附件',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _kLabel,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 6),
      // 不用 Flexible/Expanded：AppFormDialog 内容区可能横向无界，
      // flex 子项会被撑到近十万像素导致 RenderFlex overflow。
      Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                _LicenseAttachmentPicker(
                  bytes: _entities[i].licenseBytes,
                  networkUrl: _entities[i].licenseUrl,
                  enabled: !_licenseOcrLoadingIds.contains(id),
                  onPicked: (bytes, fileName) => _onLicensePicked(
                    id,
                    bytes,
                    fileName,
                    setEntityState,
                  ),
                  onCleared: () => setEntityState(() {
                    _entities[i].licenseBytes = null;
                    _entities[i].licenseUrl = null;
                    _entities[i].licenseOssId = null;
                  }),
                ),
                if (_licenseOcrLoadingIds.contains(id))
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 280,
              child: Text(
                _licenseOcrLoadingIds.contains(id)
                    ? '正在上传并识别营业执照…'
                    : '请上传大小不超过 10MB、格式为 png/jpg/jpeg 的文件',
                style: const TextStyle(
                  fontSize: 11,
                  color: _kMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      KeyedSubtree(
        key: ValueKey(
          'ent-license-fields-$id-${_entityEpochByDraftId[id] ?? 0}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextFormField(
                    name: 'ent_${id}_legalPerson',
                    label: '法人',
                    density: AppDensity.compact,
                    hintText: '法人',
                    initialValue: _initStr('ent_${id}_legalPerson'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppTextFormField(
                    name: 'ent_${id}_regAddress',
                    label: '注册地址',
                    density: AppDensity.compact,
                    hintText: '注册地址',
                    initialValue: _initStr('ent_${id}_regAddress'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppTextFormField(
                    name: 'ent_${id}_regPhone',
                    label: '注册电话',
                    density: AppDensity.compact,
                    hintText: '注册电话',
                    initialValue: _initStr('ent_${id}_regPhone'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextFormField(
                    name: 'ent_${id}_creditCode',
                    label: '统一社会信用代码',
                    density: AppDensity.compact,
                    hintText: 'OCR 识别或手填',
                    initialValue: _initStr('ent_${id}_creditCode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    name: 'ent_${id}_regCapital',
                    label: '注册资金',
                    density: AppDensity.compact,
                    hintText: 'OCR 识别或手填',
                    initialValue: _initStr('ent_${id}_regCapital'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    name: 'ent_${id}_establishDate',
                    label: '成立日期',
                    density: AppDensity.compact,
                    hintText: 'OCR 识别或手填',
                    initialValue: _initStr('ent_${id}_establishDate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextFormField(
              name: 'ent_${id}_licenseExpire',
              label: '营业执照有效期',
              density: AppDensity.compact,
              hintText: 'OCR 识别或手填，如 2016-03-15 至 长期',
              initialValue: _initStr('ent_${id}_licenseExpire'),
            ),
            const SizedBox(height: 8),
            AppTextAreaFormField(
              name: 'ent_${id}_businessScope',
              label: '经营范围',
              hintText: 'OCR 识别或手填',
              minHeight: 88,
              maxHeight: 160,
              initialValue: _initStr('ent_${id}_businessScope'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(
                'ent-abnormal-$id-${_abnormalEpochByDraftId[id] ?? 0}',
              ),
              child: AppTextAreaFormField(
                name: 'ent_${id}_abnormalRecord',
                label: '经营异常记录',
                hintText: '优先按统一社会信用代码查询，也可手填',
                minHeight: 72,
                maxHeight: 120,
                initialValue: _initStr('ent_${id}_abnormalRecord'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 26, left: 8),
            child: _abnormalQueryLoadingIds.contains(id)
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _textLink(
                    '查询',
                    () => _queryAbnormalRecord(id, setEntityState),
                  ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      KeyedSubtree(
        key: ValueKey(
          'ent-penalty-$id-${_abnormalEpochByDraftId[id] ?? 0}',
        ),
        child: AppTextAreaFormField(
          name: 'ent_${id}_penaltyHistory',
          label: '行政处罚历史',
          hintText: '请输入',
          minHeight: 72,
          maxHeight: 120,
          initialValue: _initStr('ent_${id}_penaltyHistory'),
        ),
      ),
      const SizedBox(height: 8),
      AppTextAreaFormField(
        name: 'ent_${id}_remark',
        label: '备注',
        hintText: '请输入',
        minHeight: 72,
        maxHeight: 120,
        initialValue: _initStr('ent_${id}_remark'),
      ),
      const SizedBox(height: 12),
      _sectionTitle(
        '银税信息',
        action: _sectionActions([
          _ocrTextLink(() => _ocrFillTax(i, setEntityState)),
          _addLink('添加', () {
            setEntityState(() {
              _entities[i].taxEntries.add(_TaxEntryDraft(_nextId++));
            });
          }),
        ]),
      ),
      const SizedBox(height: 8),
      KeyedSubtree(
        key: ValueKey('ent-tax-$id-${_entityEpochByDraftId[id] ?? 0}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var ti = 0; ti < _entities[i].taxEntries.length; ti++) ...[
              if (ti > 0) const SizedBox(height: 12),
              ..._buildTaxEntryFields(
                entityIndex: i,
                taxIndex: ti,
                setEntityState: setEntityState,
              ),
            ],
          ],
        ),
      ),
      ] else ...[
        const SizedBox(height: 8),
        AppTextAreaFormField(
          name: 'ent_${id}_remark',
          label: '备注',
          hintText: '请输入',
          minHeight: 72,
          maxHeight: 120,
          initialValue: _initStr('ent_${id}_remark'),
        ),
      ],
    ];
  }

  /// 选图后：filecenter 预签名直传 → 登记 → 详情 → OCR 自动回填。
  Future<void> _onLicensePicked(
    int entityId,
    Uint8List bytes,
    String fileName,
    void Function(VoidCallback) setEntityState,
  ) async {
    if (_licenseOcrLoadingIds.contains(entityId)) return;
    _EntityDraft? entity;
    for (final e in _entities) {
      if (e.id == entityId) {
        entity = e;
        break;
      }
    }
    if (entity == null) return;

    setEntityState(() {
      _licenseOcrLoadingIds.add(entityId);
      entity!.licenseBytes = bytes;
      entity.licenseUrl = null;
      entity.licenseOssId = null;
    });

    try {
      final upload = await _fileCenterApi.uploadBytes(
        bytes: bytes,
        fileName: fileName.trim().isEmpty ? 'business_license.jpg' : fileName,
      );
      if (!mounted) return;
      entity.licenseOssId = upload.fileId;
      entity.licenseUrl =
          upload.displayUrl?.trim().isNotEmpty == true
              ? upload.displayUrl
              : upload.publicUrl;

      final result = await _customerApi.ocrBusinessLicenseByUrl(
        imageUrl: upload.publicUrl,
      );
      if (!mounted) return;
      setEntityState(() => _licenseOcrLoadingIds.remove(entityId));
      final confirmed = await showOcrTextConfirmDialog(
        context,
        title: '确认营业执照信息',
        rawText: [
          result.companyName,
          result.creditCode,
          result.legalPerson,
          result.businessAddress,
          result.registeredCapital,
          result.registrationDate ?? result.issueDate,
          result.licenseExpireText,
          result.businessScope,
        ].where((e) => (e ?? '').trim().isNotEmpty).join('\n'),
        fields: [
          OcrConfirmField(key: 'name', label: '企业名称', value: result.companyName),
          OcrConfirmField(key: 'shortName', label: '企业简称', value: result.companyName),
          OcrConfirmField(key: 'legalPerson', label: '法定代表人', value: result.legalPerson),
          OcrConfirmField(key: 'creditCode', label: '统一社会信用代码', value: result.creditCode),
          OcrConfirmField(
            key: 'nature',
            label: '企业类型',
            value: result.companyType ?? result.companyForm,
          ),
          OcrConfirmField(
            key: 'regCapital',
            label: '注册资本',
            value: result.registeredCapital,
          ),
          OcrConfirmField(
            key: 'establishDate',
            label: '成立日期',
            value: result.registrationDate ?? result.issueDate,
          ),
          OcrConfirmField(
            key: 'licenseExpire',
            label: '营业期限',
            value: result.licenseExpireText,
          ),
          OcrConfirmField(
            key: 'regAddress',
            label: '注册地址',
            maxLines: 2,
            value: result.businessAddress,
          ),
          OcrConfirmField(
            key: 'address',
            label: '经营地址',
            maxLines: 2,
            value: result.businessAddress,
          ),
          OcrConfirmField(
            key: 'businessScope',
            label: '经营范围',
            maxLines: 3,
            value: result.businessScope,
          ),
        ],
      );
      if (!mounted || confirmed == null) return;
      _snapshotEntityLicenseFormToInitials(entityId);
      final p = 'ent_$entityId';
      void put(String key, {bool overwrite = true}) {
        final v = _confirmed(confirmed, key);
        if (v == null) return;
        if (!overwrite) {
          final cur = (_form.value<String>('${p}_$key') ??
                  _initStr('${p}_$key') ??
                  '')
              .trim();
          if (cur.isNotEmpty) return;
        }
        _putInit('${p}_$key', v);
      }

      put('name');
      put('shortName', overwrite: false);
      put('legalPerson');
      put('regAddress');
      put('address', overwrite: false);
      put('creditCode');
      put('regCapital');
      put('establishDate');
      put('licenseExpire');
      put('businessScope');
      final nature = _optionValue(_entityNatureOptions, confirmed['nature']);
      if (nature != null) {
        final cur = (_form.value<String>('${p}_nature') ??
                _initStr('${p}_nature') ??
                '')
            .trim();
        if (cur.isEmpty) _putInit('${p}_nature', nature);
      }
      setEntityState(() {
        _entityEpochByDraftId[entityId] =
            (_entityEpochByDraftId[entityId] ?? 0) + 1;
      });
      _toast('已根据识别结果回填营业执照信息');
    } catch (e) {
      if (!mounted) return;
      setEntityState(() {
        _licenseOcrLoadingIds.remove(entityId);
        // 上传/识别失败时保留本地预览，便于重试；不提交无 fileId 的附件。
        entity?.licenseOssId = null;
        entity?.licenseUrl = null;
      });
      _toast(e.toString(), error: true);
    }
  }

  void _snapshotEntityLicenseFormToInitials(int entityId) {
    const keys = [
      'name',
      'shortName',
      'nature',
      'address',
      'legalPerson',
      'regAddress',
      'regPhone',
      'creditCode',
      'regCapital',
      'establishDate',
      'licenseExpire',
      'businessScope',
    ];
    for (final key in keys) {
      final name = 'ent_${entityId}_$key';
      final v = _form.value<Object?>(name);
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      _initials[name] = v;
    }
  }

  Future<void> _queryAbnormalRecord(
    int entityId,
    void Function(VoidCallback) setEntityState,
  ) async {
    if (_abnormalQueryLoadingIds.contains(entityId)) return;
    final creditCode =
        (_form.value<String>('ent_${entityId}_creditCode') ??
                _initStr('ent_${entityId}_creditCode') ??
                '')
            .trim();
    if (creditCode.isEmpty) {
      _toast('请先填写统一社会信用代码', error: true);
      return;
    }
    setEntityState(() => _abnormalQueryLoadingIds.add(entityId));
    try {
      final result = await _customerApi.fetchEntRiskQuery(
        creditCode: creditCode,
      );
      if (!mounted) return;
      final abnormal = result.abnormalRecord?.trim();
      final penalty = result.penaltyHistory?.trim();
      if ((abnormal == null || abnormal.isEmpty) &&
          (penalty == null || penalty.isEmpty)) {
        setEntityState(() => _abnormalQueryLoadingIds.remove(entityId));
        _toast('未查询到经营异常记录');
        return;
      }
      final curAbnormal =
          (_form.value<String>('ent_${entityId}_abnormalRecord') ?? '').trim();
      if (curAbnormal.isNotEmpty) {
        _initials['ent_${entityId}_abnormalRecord'] = curAbnormal;
      }
      final curPenalty =
          (_form.value<String>('ent_${entityId}_penaltyHistory') ?? '').trim();
      if (curPenalty.isNotEmpty) {
        _initials['ent_${entityId}_penaltyHistory'] = curPenalty;
      }
      if (abnormal != null && abnormal.isNotEmpty) {
        _putInit('ent_${entityId}_abnormalRecord', abnormal);
      }
      if (penalty != null && penalty.isNotEmpty) {
        _putInit('ent_${entityId}_penaltyHistory', penalty);
      }
      setEntityState(() {
        _abnormalQueryLoadingIds.remove(entityId);
        _abnormalEpochByDraftId[entityId] =
            (_abnormalEpochByDraftId[entityId] ?? 0) + 1;
      });
      final tip = result.message?.trim();
      _toast((tip != null && tip.isNotEmpty) ? tip : '查询成功');
    } catch (e) {
      if (!mounted) return;
      setEntityState(() => _abnormalQueryLoadingIds.remove(entityId));
      _toast(e.toString(), error: true);
    }
  }

  Future<void> _ocrBankAccountLicense(
    int entityId,
    void Function(VoidCallback) setEntityState,
  ) async {
    if (_bankOcrLoadingIds.contains(entityId)) return;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      _toast('无法读取图片内容', error: true);
      return;
    }
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      _toast('图片需不超过 10MB', error: true);
      return;
    }
    setEntityState(() => _bankOcrLoadingIds.add(entityId));
    try {
      final result = await _customerApi.ocrBankAccountLicense(
        bytes: bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      setEntityState(() => _bankOcrLoadingIds.remove(entityId));
      final confirmed = await showOcrTextConfirmDialog(
        context,
        title: '确认开户信息',
        rawText: [
          result.customerName,
          result.depositaryBank,
          result.bankAccount,
        ].where((e) => (e ?? '').trim().isNotEmpty).join('\n'),
        fields: [
          OcrConfirmField(key: 'invoiceName', label: '名称', value: result.customerName),
          OcrConfirmField(key: 'bankName', label: '开户行', value: result.depositaryBank),
          OcrConfirmField(key: 'bankAccount', label: '银行账号', value: result.bankAccount),
        ],
      );
      if (!mounted || confirmed == null) return;
      _snapshotEntityTaxFormToInitials(entityId);
      final bank = _confirmed(confirmed, 'bankName');
      final account = _confirmed(confirmed, 'bankAccount');
      final name = _confirmed(confirmed, 'invoiceName');
      _EntityDraft? entity;
      for (final e in _entities) {
        if (e.id == entityId) {
          entity = e;
          break;
        }
      }
      final taxId = (entity != null && entity.taxEntries.isNotEmpty)
          ? entity.taxEntries.first.id
          : null;
      final tp = taxId == null ? null : 'ent_${entityId}_tax_$taxId';
      if (tp != null) {
        if (bank != null && bank.isNotEmpty) {
          _putInit('${tp}_bankName', bank);
          _putInit('${tp}_invoiceBank', bank);
        }
        if (account != null && account.isNotEmpty) {
          _putInit('${tp}_bankAccount', account);
          _putInit('${tp}_invoiceAccount', account);
        }
        if (name != null && name.isNotEmpty) {
          _putInit('${tp}_invoiceName', name);
        }
      }
      setEntityState(() {
        _bankOcrLoadingIds.remove(entityId);
        _entityEpochByDraftId[entityId] =
            (_entityEpochByDraftId[entityId] ?? 0) + 1;
      });
      _toast('已根据识别结果回填开户信息');
    } catch (e) {
      if (!mounted) return;
      setEntityState(() => _bankOcrLoadingIds.remove(entityId));
      _toast(e.toString(), error: true);
    }
  }

  void _snapshotEntityTaxFormToInitials(int entityId) {
    const keys = [
      'bankName',
      'bankAccount',
      'invoiceName',
      'taxNo',
      'invoiceAddress',
      'invoicePhone',
      'invoiceBank',
      'invoiceAccount',
    ];
    _EntityDraft? entity;
    for (final e in _entities) {
      if (e.id == entityId) {
        entity = e;
        break;
      }
    }
    final taxIds = [
      if (entity != null)
        for (final t in entity.taxEntries) t.id,
    ];
    for (final taxId in taxIds) {
      for (final key in keys) {
        final name = 'ent_${entityId}_tax_${taxId}_$key';
        final v = _form.value<Object?>(name);
        if (v == null) continue;
        if (v is String && v.trim().isEmpty) continue;
        _initials[name] = v;
      }
    }
  }

  Future<void> _ocrFillContact(
    void Function(VoidCallback) setContactState,
  ) async {
    final ocr = await _recognizeModuleImage('识别联系人信息');
    if (!mounted || ocr == null) return;
    final data = await showContactOcrPreviewDialog(
      context,
      initialContent: _ocrPlain(ocr),
      kvData: ocr.kvData,
    );
    if (!mounted || data == null || !data.hasAny) return;
    final index = _contactIndexForOcrFill(setContactState);
    if (!mounted || index < 0) return;
    await _applyOcrToContact(index, data, setContactState);
    if (!mounted) return;
    _toast('已根据识别结果回填联系人信息');
  }

  /// 优先填到还没写姓名和手机的联系人；都有内容时新增一条。
  int _contactIndexForOcrFill(void Function(VoidCallback) setContactState) {
    for (var i = 0; i < _contacts.length; i++) {
      final prefix = 'ct_${_contacts[i].id}';
      final name = (_form.value<String>('${prefix}_nameZh') ??
              _initStr('${prefix}_nameZh') ??
              '')
          .trim();
      final mobile = (_form.value<String>('${prefix}_mobile') ??
              _initStr('${prefix}_mobile') ??
              '')
          .trim();
      if (name.isEmpty && mobile.isEmpty) return i;
    }
    late final int newIndex;
    setContactState(() {
      _contacts.add(_ContactDraft(_nextId++));
      newIndex = _contacts.length - 1;
    });
    return newIndex;
  }

  Future<void> _applyOcrToContact(
    int contactIndex,
    ContactOcrFillData data,
    void Function(VoidCallback) setContactState,
  ) async {
    if (contactIndex < 0 || contactIndex >= _contacts.length) return;
    final contact = _contacts[contactIndex];
    final personId = contact.id;
    final prefix = 'ct_$personId';
    _snapshotPersonFormToInitials(prefix);

    final nameZh = data.nameZh?.trim();
    var nameEn = data.nameEn?.trim();
    if ((nameEn == null || nameEn.isEmpty) &&
        nameZh != null &&
        nameZh.isNotEmpty) {
      final py = _chineseToEnglishName(nameZh);
      if (py.isNotEmpty) nameEn = py;
    }
    _putInit('${prefix}_nameZh', nameZh);
    _putInit('${prefix}_nameEn', nameEn);
    _putInit('${prefix}_gender', data.gender);
    _putInit('${prefix}_age', data.ageDesc);
    _putInit('${prefix}_mobile', data.mobile);
    _putInit('${prefix}_phone', data.phone);
    _putInit('${prefix}_email', data.email);
    _putInit('${prefix}_address', data.address);
    _putInit('${prefix}_title', data.deptTitle);
    _putInit('${prefix}_role', data.jobDesc);
    _putInit('${prefix}_remark', data.remark);

    final org = data.relatedEnterprise?.trim();
    if (org != null && org.isNotEmpty) {
      final entKey = _matchEnterpriseKey(org);
      if (entKey != null) {
        _putInit('${prefix}_enterprise', entKey);
      } else if ((_initStr('${prefix}_remark') ?? '').isEmpty &&
          (data.remark == null || data.remark!.trim().isEmpty)) {
        _putInit('${prefix}_remark', '组织：$org');
      }
    }

    final pending = <_PendingCity>[];
    final cityText = data.city?.trim().isNotEmpty == true
        ? data.city!.trim()
        : data.address?.trim();
    if (cityText != null && cityText.isNotEmpty) {
      final split = _splitCombinedCity(cityText);
      final provCode = _valueFromLabelOrValue(_provinceOptions, split.$1);
      _putInit('${prefix}_province', provCode);
      pending.add(
        _PendingCity(
          draftId: personId,
          fieldName: '${prefix}_city',
          provinceCode: provCode,
          cityLabel: split.$2,
        ),
      );
    }

    await _loadPendingCities(pending);
    if (!mounted) return;
    setContactState(() {
      _personEpochByDraftId[personId] =
          (_personEpochByDraftId[personId] ?? 0) + 1;
      _cityEpochByDraftId[personId] =
          (_cityEpochByDraftId[personId] ?? 0) + 1;
      _nameEnKeys[personId] = GlobalKey<FormFieldState<String>>();
      _cityRevision.value++;
    });
  }

  Future<void> _importVcfForContact(
    int contactIndex,
    void Function(VoidCallback) setContactState,
  ) async {
    if (contactIndex < 0 || contactIndex >= _contacts.length) return;
    final parsed = await showContactVcfImportDialog(context);
    if (!mounted || parsed == null || parsed.isEmpty) return;

    // 首位填到当前卡片；其余依次新增联系人并填充。
    await _applyVcfToContact(contactIndex, parsed.first, setContactState);
    for (var i = 1; i < parsed.length; i++) {
      if (!mounted) return;
      late final int newIndex;
      setContactState(() {
        _contacts.add(_ContactDraft(_nextId++));
        newIndex = _contacts.length - 1;
      });
      await _applyVcfToContact(newIndex, parsed[i], setContactState);
    }
    if (!mounted) return;
    final tip = parsed.length > 1
        ? '已根据 VCF 填充 ${parsed.length} 位联系人'
        : '已根据 VCF 填充联系人';
    AppToast.show(context: context, title: tip);
  }

  Future<OacGeneralOcrResult?> _recognizeModuleImage(String title) {
    return recognizeImageText(context, dialogTitle: title);
  }

  String _ocrPlain(OacGeneralOcrResult ocr) {
    final content = ocr.content?.trim() ?? '';
    if (content.isNotEmpty) return content;
    return ocr.words.join('\n').trim();
  }

  String? _ocrKv(OacGeneralOcrResult ocr, List<String> keys) {
    final kv = ocr.kvData;
    if (kv == null || kv.isEmpty) return null;
    for (final entry in kv.entries) {
      final k = entry.key.toString().trim();
      for (final want in keys) {
        if (k == want || k.contains(want)) {
          final v = entry.value?.toString().trim() ?? '';
          if (v.isNotEmpty) return v;
        }
      }
    }
    return null;
  }

  String? _ocrPick(String text, RegExp re) {
    final m = re.firstMatch(text);
    final v = m?.group(1)?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String? _matchOptionInText(List<AppOption<String>> options, String text) {
    String? best;
    var bestLen = 0;
    for (final o in options) {
      final label = o.label.trim();
      if (label.length < 2) continue;
      if (text.contains(label) && label.length > bestLen) {
        best = o.value;
        bestLen = label.length;
      }
    }
    return best;
  }

  List<String> _matchOptionsInText(
    List<AppOption<String>> options,
    String text,
  ) {
    final hits = <String>[];
    for (final o in options) {
      final label = o.label.trim();
      if (label.length < 2) continue;
      if (text.contains(label)) hits.add(o.value);
    }
    return hits;
  }

  void _snapshotNamed(List<String> names) {
    for (final name in names) {
      final v = _form.value<Object?>(name);
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      if (v is List && v.isEmpty) continue;
      _initials[name] = v;
    }
  }

  String? _optionValue(List<AppOption<String>> options, String? raw) {
    final v = _valueFromLabelOrValue(options, raw);
    if (v == null) return null;
    for (final o in options) {
      if (o.value == v) return v;
    }
    return null;
  }

  String? _confirmed(Map<String, String> data, String key) {
    final v = data[key]?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  List<OcrConfirmField> _brandConfirmFields(
    String text, [
    OacGeneralOcrResult? ocr,
  ]) {
    String? kv(List<String> keys) => ocr == null ? null : _ocrKv(ocr, keys);
    final industries = _matchOptionsInText(_industryOptions, text)
        .map((v) => _optionLabel(_industryOptions, v) ?? v)
        .join('、');
    return [
      OcrConfirmField(
        key: 'name',
        label: '品牌简称',
        value: kv(const ['品牌简称', '品牌名称', '企业简称']) ??
            _ocrPick(text, RegExp(r'品牌(?:简称|名称)[:：\s]*([^\s，,；;]{1,40})')),
      ),
      OcrConfirmField(
        key: 'industry',
        label: '所属行业',
        value: industries.isEmpty ? null : industries,
      ),
      OcrConfirmField(
        key: 'brandNature',
        label: '品牌性质',
        value: _optionLabel(
          _brandNatureOptions,
          kv(const ['品牌性质']) ?? _matchOptionInText(_brandNatureOptions, text),
        ),
      ),
      OcrConfirmField(
        key: 'spokesperson',
        label: '代言人信息',
        value: kv(const ['代言人', '代言人信息']) ??
            _ocrPick(text, RegExp(r'代言人(?:信息)?[:：\s]*([^\s，,；;]{1,20})')),
      ),
      OcrConfirmField(
        key: 'website',
        label: '网址',
        value: kv(const ['网址', '官网']) ?? _ocrPick(text, RegExp(r'(https?://\S+)')),
      ),
      OcrConfirmField(
        key: 'revenueScale',
        label: '营收规模/年',
        value: _optionLabel(
          _revenueOptions,
          kv(const ['营收规模']) ?? _matchOptionInText(_revenueOptions, text),
        ),
      ),
      OcrConfirmField(
        key: 'staffScale',
        label: '人员规模',
        value: _optionLabel(
          _kStaffScaleOptions,
          _matchOptionInText(_kStaffScaleOptions, text),
        ),
      ),
    ];
  }

  Future<void> _ocrFillBrand() async {
    final ocr = await _recognizeModuleImage('识别品牌信息');
    if (!mounted || ocr == null) return;
    final text = _ocrPlain(ocr);
    final confirmed = await showOcrTextConfirmDialog(
      context,
      title: '确认品牌信息',
      rawText: text,
      fields: _brandConfirmFields(text, ocr),
      reparse: _brandConfirmFields,
    );
    if (!mounted || confirmed == null) return;
    _snapshotNamed(const [
      'name',
      'industry',
      'brandNature',
      'spokesperson',
      'website',
      'revenueScale',
      'staffScale',
      'marketingBudget',
    ]);
    var filled = 0;
    void put(String name, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      _putInit(name, value);
      filled++;
    }

    put('name', _confirmed(confirmed, 'name'));
    final industry = <String>[];
    for (final part in (_confirmed(confirmed, 'industry') ?? '').split(
      RegExp(r'[、,，;；]'),
    )) {
      final v = _optionValue(_industryOptions, part.trim());
      if (v != null && !industry.contains(v)) industry.add(v);
    }
    put('industry', industry);
    put('brandNature', _optionValue(_brandNatureOptions, confirmed['brandNature']));
    put('spokesperson', _confirmed(confirmed, 'spokesperson'));
    put('website', _confirmed(confirmed, 'website'));
    put('revenueScale', _optionValue(_revenueOptions, confirmed['revenueScale']));
    put('staffScale', _optionValue(_kStaffScaleOptions, confirmed['staffScale']));
    if (filled == 0) {
      _toast('未识别到可回填的品牌信息', error: true);
      return;
    }
    final name = _initStr('name');
    if (name != null) _syncBrandChoices(name: name);
    setState(() => _brandInfoEpoch++);
    _toast('已根据识别结果回填品牌信息');
  }

  List<({String? platform, String? account, String? link})> _parseMediaRows(
    String text, [
    OacGeneralOcrResult? ocr,
  ]) {
    final rows = <({String? platform, String? account, String? link})>[];
    final seen = <String>{};
    for (final opt in _mediaPlatformOptions) {
      final label = opt.label.trim();
      if (label.length < 2) continue;
      final idx = text.indexOf(label);
      if (idx < 0) continue;
      final rest = text.substring(idx + label.length);
      final account = _ocrPick(
        rest,
        RegExp(r'^[:：\s]*([^\s，,；;\n]{1,40})'),
      );
      final link = RegExp(r'https?://\S+').firstMatch(rest)?.group(0);
      final key = '$label|${account ?? ''}|${link ?? ''}';
      if (!seen.add(key)) continue;
      if ((account == null || account.isEmpty) &&
          (link == null || link.isEmpty)) {
        continue;
      }
      rows.add((platform: opt.value, account: account, link: link));
    }
    final kvAccount = ocr == null ? null : _ocrKv(ocr, const ['账号', '账号名']);
    final kvLink = ocr == null ? null : _ocrKv(ocr, const ['链接', '网址']);
    final kvPlatform = ocr == null ? null : _ocrKv(ocr, const ['平台']);
    if (rows.isEmpty &&
        ((kvAccount != null && kvAccount.isNotEmpty) ||
            (kvLink != null && kvLink.isNotEmpty))) {
      rows.add((
        platform: kvPlatform == null
            ? null
            : _valueFromLabelOrValue(_mediaPlatformOptions, kvPlatform),
        account: kvAccount,
        link: kvLink,
      ));
    }
    return rows;
  }

  List<OcrConfirmField> _mediaConfirmFields(
    String text, [
    OacGeneralOcrResult? ocr,
  ]) {
    final rows = _parseMediaRows(text, ocr);
    final shown = rows.isEmpty
        ? <({String? platform, String? account, String? link})>[
            (platform: null, account: null, link: null),
          ]
        : rows;
    final fields = <OcrConfirmField>[];
    for (var i = 0; i < shown.length; i++) {
      final n = shown.length == 1 ? '' : ' ${i + 1}';
      final row = shown[i];
      fields.add(
        OcrConfirmField(
          key: 'platform_$i',
          label: '平台$n',
          value: _optionLabel(_mediaPlatformOptions, row.platform),
        ),
      );
      fields.add(
        OcrConfirmField(key: 'account_$i', label: '账号名$n', value: row.account),
      );
      fields.add(
        OcrConfirmField(key: 'link_$i', label: '链接$n', value: row.link),
      );
    }
    return fields;
  }

  Future<void> _ocrFillMedia(void Function(VoidCallback) setMediaState) async {
    final ocr = await _recognizeModuleImage('识别自媒体矩阵');
    if (!mounted || ocr == null) return;
    final text = _ocrPlain(ocr);
    final confirmed = await showOcrTextConfirmDialog(
      context,
      title: '确认自媒体矩阵',
      rawText: text,
      fields: _mediaConfirmFields(text, ocr),
      reparse: _mediaConfirmFields,
    );
    if (!mounted || confirmed == null) return;
    final rows = <({String? platform, String? account, String? link})>[];
    for (var i = 0;; i++) {
      if (!confirmed.containsKey('platform_$i') &&
          !confirmed.containsKey('account_$i') &&
          !confirmed.containsKey('link_$i')) {
        break;
      }
      final account = _confirmed(confirmed, 'account_$i');
      final link = _confirmed(confirmed, 'link_$i');
      if ((account == null || account.isEmpty) &&
          (link == null || link.isEmpty)) {
        continue;
      }
      rows.add((
        platform: _optionValue(_mediaPlatformOptions, confirmed['platform_$i']),
        account: account,
        link: link,
      ));
    }
    if (rows.isEmpty) {
      _toast('未识别到可回填的自媒体信息', error: true);
      return;
    }
    setMediaState(() {
      final firstId = _medias.isEmpty ? null : _medias.first.id;
      final account = firstId == null
          ? ''
          : (_form.value<String>('media_${firstId}_account') ??
                  _initStr('media_${firstId}_account') ??
                  '')
              .trim();
      final link = firstId == null
          ? ''
          : (_form.value<String>('media_${firstId}_link') ??
                  _initStr('media_${firstId}_link') ??
                  '')
              .trim();
      final reusable = _medias.length == 1 && account.isEmpty && link.isEmpty;
      if (reusable) _medias.clear();
      for (final row in rows) {
        final draft = _MediaDraft(_nextId++);
        _medias.add(draft);
        _putInit('media_${draft.id}_platform', row.platform);
        _putInit('media_${draft.id}_account', row.account);
        _putInit('media_${draft.id}_link', row.link);
      }
    });
    _toast('已根据识别结果回填自媒体矩阵');
  }

  List<OcrConfirmField> _entityConfirmFields(
    String text, [
    OacGeneralOcrResult? ocr,
  ]) {
    String? kv(List<String> keys) => ocr == null ? null : _ocrKv(ocr, keys);
    return [
      OcrConfirmField(
        key: 'name',
        label: '企业名称',
        value: kv(const ['企业名称', '公司名称', '主体全称', '名称']) ??
            _ocrPick(text, RegExp(r'(?:企业名称|公司名称|主体全称)[:：\s]*([^\n]{2,80})')),
      ),
      OcrConfirmField(
        key: 'shortName',
        label: '企业简称',
        value: kv(const ['企业简称', '简称']) ??
            _ocrPick(text, RegExp(r'(?:企业简称|简称)[:：\s]*([^\s，,；;\n]{1,40})')),
      ),
      OcrConfirmField(
        key: 'legalPerson',
        label: '法定代表人',
        value: kv(const ['法定代表人', '法人']) ??
            _ocrPick(text, RegExp(r'(?:法定代表人|法人)[:：\s]*([^\s，,；;\n]{2,20})')),
      ),
      OcrConfirmField(
        key: 'creditCode',
        label: '统一社会信用代码',
        value: kv(const ['统一社会信用代码', '信用代码']) ??
            _ocrPick(text, RegExp(r'([0-9A-Z]{18})')),
      ),
      OcrConfirmField(
        key: 'nature',
        label: '企业类型',
        value: _optionLabel(
          _entityNatureOptions,
          _matchOptionInText(_entityNatureOptions, text),
        ),
      ),
      OcrConfirmField(
        key: 'regPhone',
        label: '注册电话',
        value: kv(const ['注册电话', '联系电话']) ??
            _ocrPick(text, RegExp(r'(?:注册电话|联系电话)[:：\s]*([0-9\-]{7,20})')),
      ),
      OcrConfirmField(
        key: 'regCapital',
        label: '注册资本',
        value: kv(const ['注册资本', '注册资金']) ??
            _ocrPick(text, RegExp(r'(?:注册资本|注册资金)[:：\s]*([^\n]{2,40})')),
      ),
      OcrConfirmField(
        key: 'establishDate',
        label: '成立日期',
        value: kv(const ['成立日期', '注册日期']) ??
            _ocrPick(text, RegExp(r'(?:成立日期|注册日期)[:：\s]*([0-9年月日./\-]{6,20})')),
      ),
      OcrConfirmField(
        key: 'regAddress',
        label: '注册地址',
        maxLines: 2,
        value: kv(const ['注册地址', '住所']) ??
            _ocrPick(text, RegExp(r'(?:注册地址|住所)[:：\s]*([^\n]{4,120})')),
      ),
      OcrConfirmField(
        key: 'address',
        label: '经营地址',
        maxLines: 2,
        value: kv(const ['详细地址', '经营地址']) ??
            _ocrPick(text, RegExp(r'(?:详细地址|经营地址)[:：\s]*([^\n]{4,120})')),
      ),
      OcrConfirmField(
        key: 'businessScope',
        label: '经营范围',
        maxLines: 3,
        value: kv(const ['经营范围']) ??
            _ocrPick(text, RegExp(r'经营范围[:：\s]*([^\n]{4,500})')),
      ),
    ];
  }

  Future<void> _ocrFillEntity(
    void Function(VoidCallback) setEntityState,
  ) async {
    if (_entities.isEmpty) return;
    final ocr = await _recognizeModuleImage('识别经营主体信息');
    if (!mounted || ocr == null) return;
    final id = _entities.first.id;
    final text = _ocrPlain(ocr);
    final confirmed = await showOcrTextConfirmDialog(
      context,
      title: '确认经营主体信息',
      rawText: text,
      fields: _entityConfirmFields(text, ocr),
      reparse: _entityConfirmFields,
    );
    if (!mounted || confirmed == null) return;
    _snapshotEntityLicenseFormToInitials(id);
    var filled = 0;
    void put(String key, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      _putInit('ent_${id}_$key', v);
      filled++;
    }

    for (final key in const [
      'name',
      'shortName',
      'legalPerson',
      'creditCode',
      'regPhone',
      'regCapital',
      'establishDate',
      'regAddress',
      'address',
      'businessScope',
    ]) {
      put(key, _confirmed(confirmed, key));
    }
    final nature = _optionValue(_entityNatureOptions, confirmed['nature']);
    if (nature != null) {
      _putInit('ent_${id}_nature', nature);
      filled++;
    }
    if (filled == 0) {
      _toast('未识别到可回填的经营主体信息', error: true);
      return;
    }
    setEntityState(() {
      _entityEpochByDraftId[id] = (_entityEpochByDraftId[id] ?? 0) + 1;
    });
    _toast('已根据识别结果回填经营主体信息');
  }

  List<OcrConfirmField> _taxConfirmFields(
    String text, [
    OacGeneralOcrResult? ocr,
  ]) {
    String? kv(List<String> keys) => ocr == null ? null : _ocrKv(ocr, keys);
    final account = kv(const ['银行账号', '账号']) ??
        _ocrPick(text, RegExp(r'(?:银行账号|账号)[:：\s]*([0-9 ]{8,40})'));
    return [
      OcrConfirmField(
        key: 'bankName',
        label: '开户行',
        value: kv(const ['开户行', '开户银行']) ??
            _ocrPick(text, RegExp(r'(?:开户银行|开户行)[:：\s]*([^\n]{2,80})')),
      ),
      OcrConfirmField(
        key: 'bankAccount',
        label: '银行账号',
        value: account?.replaceAll(' ', ''),
      ),
      OcrConfirmField(
        key: 'taxNo',
        label: '税号',
        value: kv(const ['税号', '纳税人识别号']) ??
            _ocrPick(text, RegExp(r'(?:税号|纳税人识别号)[:：\s]*([0-9A-Z]{15,20})')),
      ),
      OcrConfirmField(
        key: 'invoiceName',
        label: '开票名称',
        value: kv(const ['开票名称', '发票抬头']) ??
            _ocrPick(text, RegExp(r'(?:开票名称|发票抬头)[:：\s]*([^\n]{2,80})')),
      ),
      OcrConfirmField(
        key: 'invoiceAddress',
        label: '注册地址',
        maxLines: 2,
        value: kv(const ['注册地址']) ??
            _ocrPick(text, RegExp(r'注册地址[:：\s]*([^\n]{4,120})')),
      ),
      OcrConfirmField(
        key: 'invoicePhone',
        label: '注册电话',
        value: kv(const ['注册电话']) ??
            _ocrPick(text, RegExp(r'注册电话[:：\s]*([0-9\-]{7,20})')),
      ),
    ];
  }

  Future<void> _ocrFillTax(
    int entityIndex,
    void Function(VoidCallback) setEntityState,
  ) async {
    if (entityIndex < 0 || entityIndex >= _entities.length) return;
    final ocr = await _recognizeModuleImage('识别银税信息');
    if (!mounted || ocr == null) return;
    final entity = _entities[entityIndex];
    final text = _ocrPlain(ocr);
    final confirmed = await showOcrTextConfirmDialog(
      context,
      title: '确认银税信息',
      rawText: text,
      fields: _taxConfirmFields(text, ocr),
      reparse: _taxConfirmFields,
    );
    if (!mounted || confirmed == null) return;
    if (entity.taxEntries.isEmpty) {
      setEntityState(() {
        entity.taxEntries.add(_TaxEntryDraft(_nextId++));
      });
    }
    if (!mounted || entity.taxEntries.isEmpty) return;
    final tax = entity.taxEntries.first;
    final prefix = 'ent_${entity.id}_tax_${tax.id}';
    _snapshotEntityTaxFormToInitials(entity.id);
    var filled = 0;
    void put(String key, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      _putInit('${prefix}_$key', v);
      filled++;
    }

    final bank = _confirmed(confirmed, 'bankName');
    final account = _confirmed(confirmed, 'bankAccount')?.replaceAll(' ', '');
    put('bankName', bank);
    put('invoiceBank', bank);
    put('bankAccount', account);
    put('invoiceAccount', account);
    put('taxNo', _confirmed(confirmed, 'taxNo'));
    put('invoiceName', _confirmed(confirmed, 'invoiceName'));
    put('invoiceAddress', _confirmed(confirmed, 'invoiceAddress'));
    put('invoicePhone', _confirmed(confirmed, 'invoicePhone'));
    if (filled == 0) {
      _toast('未识别到可回填的银税信息', error: true);
      return;
    }
    setEntityState(() {
      _entityEpochByDraftId[entity.id] =
          (_entityEpochByDraftId[entity.id] ?? 0) + 1;
    });
    _toast('已根据识别结果回填银税信息');
  }

  Future<void> _applyVcfToContact(
    int contactIndex,
    ContactVcfData data,
    void Function(VoidCallback) setContactState,
  ) async {
    if (contactIndex < 0 || contactIndex >= _contacts.length) return;
    final contact = _contacts[contactIndex];
    final personId = contact.id;
    final prefix = 'ct_$personId';

    // 先把当前表单值写入 initials，避免重建时丢掉未改动的字段。
    _snapshotPersonFormToInitials(prefix);

    final nameZh = data.nameZh?.trim();
    var nameEn = data.nameEn?.trim();
    // VCF 无英文名时，用中文姓名转拼音自动填 Name。
    if ((nameEn == null || nameEn.isEmpty) &&
        nameZh != null &&
        nameZh.isNotEmpty) {
      final py = _chineseToEnglishName(nameZh);
      if (py.isNotEmpty) nameEn = py;
    }

    _putInit('${prefix}_nameZh', nameZh);
    _putInit('${prefix}_nameEn', nameEn);
    _putInit('${prefix}_gender', data.gender);
    _putInit('${prefix}_mobile', data.mobile);
    _putInit('${prefix}_phone', data.phone);
    _putInit('${prefix}_email', data.email);
    _putInit('${prefix}_address', data.address);
    _putInit('${prefix}_title', data.title);
    _putInit('${prefix}_role', data.role);
    _putInit('${prefix}_remark', data.remark);

    final org = data.org?.trim();
    if (org != null && org.isNotEmpty) {
      final entKey = _matchEnterpriseKey(org);
      if (entKey != null) {
        _putInit('${prefix}_enterprise', entKey);
      } else if ((_initStr('${prefix}_remark') ?? '').isEmpty &&
          (data.remark == null || data.remark!.trim().isEmpty)) {
        _putInit('${prefix}_remark', '组织：$org');
      }
    }

    final pending = <_PendingCity>[];
    final cityCombined = data.combinedCity;
    if (cityCombined != null && cityCombined.isNotEmpty) {
      final split = _splitCombinedCity(cityCombined);
      final provCode = _valueFromLabelOrValue(_provinceOptions, split.$1) ??
          _valueFromLabelOrValue(_provinceOptions, data.province);
      _putInit('${prefix}_province', provCode);
      pending.add(
        _PendingCity(
          draftId: personId,
          fieldName: '${prefix}_city',
          provinceCode: provCode,
          cityLabel: split.$2 ?? data.city,
        ),
      );
    }

    await _loadPendingCities(pending);
    if (!mounted) return;

    setContactState(() {
      _personEpochByDraftId[personId] =
          (_personEpochByDraftId[personId] ?? 0) + 1;
      _cityEpochByDraftId[personId] =
          (_cityEpochByDraftId[personId] ?? 0) + 1;
      // 字段重建后旧 GlobalKey 会失效，换新 key 供拼音自动填充使用。
      _nameEnKeys[personId] = GlobalKey<FormFieldState<String>>();
      _cityRevision.value++;
    });
  }

  void _snapshotPersonFormToInitials(String prefix) {
    const keys = [
      'nameZh',
      'nameEn',
      'gender',
      'age',
      'enterprise',
      'province',
      'city',
      'address',
      'title',
      'role',
      'tenure',
      'mobile',
      'phone',
      'email',
      'remark',
    ];
    for (final key in keys) {
      final name = '${prefix}_$key';
      final v = _form.value<Object?>(name);
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      _initials[name] = v;
    }
    final scope = _form.value<Object?>('${prefix}_scope');
    if (scope is List && scope.isNotEmpty) {
      _initials['${prefix}_scope'] = List<String>.from(
        scope.map((e) => e.toString()),
      );
    }
    final brands = _form.value<Object?>('${prefix}_brands');
    if (brands is List && brands.isNotEmpty) {
      _initials['${prefix}_brands'] = List<String>.from(
        brands.map((e) => e.toString()),
      );
    }
  }

  String? _matchEnterpriseKey(String orgName) {
    final target = orgName.trim();
    if (target.isEmpty) return null;
    for (var i = 0; i < _entities.length; i++) {
      final id = _entities[i].id;
      final fullName =
          (_form.value<String>('ent_${id}_name') ?? _initStr('ent_${id}_name') ?? '')
              .trim();
      if (fullName.isNotEmpty &&
          (fullName == target || fullName.contains(target) || target.contains(fullName))) {
        return 'ent-$id';
      }
    }
    return null;
  }

  List<Widget> _buildContactFields(
    int i,
    void Function(VoidCallback) setContactState,
  ) {
    final contact = _contacts[i];
    final id = contact.id;
    return [
      _subHeading(
        '基本信息',
        action: _contactBasicInfoActions(i, setContactState),
      ),
      const SizedBox(height: 8),
      ..._buildPersonFields(
        namePrefix: 'ct_$id',
        personId: id,
        nameRequired: true,
      ),
      const SizedBox(height: 10),
      _sectionTitle(
        '上级信息',
        action: _addLink('添加', () {
          setContactState(() {
            contact.superiors.add(_PersonDraft(_nextId++));
          });
        }),
      ),
      if (contact.superiors.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _emptyHint('可添加多条，字段同基本信息'),
        )
      else
        for (var j = 0; j < contact.superiors.length; j++)
          _card(
            title: '上级 ${j + 1}',
            deleteLabel: '删除',
            onDelete: () {
              final personId = contact.superiors[j].id;
              setContactState(() {
                contact.superiors.removeAt(j);
                _cityOptionsByDraftId.remove(personId);
                _cityEpochByDraftId.remove(personId);
                _personEpochByDraftId.remove(personId);
                _releasePersonNameEn(personId);
              });
            },
            children: _buildPersonFields(
              namePrefix: 'ct_${id}_sup_${contact.superiors[j].id}',
              personId: contact.superiors[j].id,
              nameRequired: false,
            ),
          ),
      const SizedBox(height: 10),
      _sectionTitle(
        '下级信息',
        action: _addLink('添加', () {
          setContactState(() {
            contact.subordinates.add(_PersonDraft(_nextId++));
          });
        }),
      ),
      if (contact.subordinates.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _emptyHint('可添加多条，字段同基本信息'),
        )
      else
        for (var j = 0; j < contact.subordinates.length; j++)
          _card(
            title: '下级 ${j + 1}',
            deleteLabel: '删除',
            onDelete: () {
              final personId = contact.subordinates[j].id;
              setContactState(() {
                contact.subordinates.removeAt(j);
                _cityOptionsByDraftId.remove(personId);
                _cityEpochByDraftId.remove(personId);
                _personEpochByDraftId.remove(personId);
                _releasePersonNameEn(personId);
              });
            },
            children: _buildPersonFields(
              namePrefix: 'ct_${id}_sub_${contact.subordinates[j].id}',
              personId: contact.subordinates[j].id,
              nameRequired: false,
            ),
          ),
    ];
  }

  Widget _buildSalesCard(
    int i,
    void Function(VoidCallback) setSalesState,
  ) {
    final s = _sales[i];
    Widget field(String label, String value, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kLabel, height: 1.2),
            ),
            const SizedBox(height: 4),
            Container(
              height: 34,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kCardBorder),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _kTitle),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field('姓名（中文）', s.nameZh),
              const SizedBox(width: 12),
              field('Name', s.nameEn),
              const SizedBox(width: 12),
              field('性别', s.gender),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: AppInkWell(
                  onPressed: () => setSalesState(() => _sales.removeAt(i)),
                  borderRadius: BorderRadius.circular(4),
                  child: const SizedBox(
                    width: 40,
                    height: 34,
                    child: Center(
                      child: Text(
                        '删除',
                        softWrap: false,
                        style: TextStyle(
                          color: _kDanger,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field('部门/职位', s.deptPost, flex: 2),
              const SizedBox(width: 12),
              field('创建时间', s.createTime),
            ],
          ),
        ],
      ),
    );
  }

  /// 联系人 / 上级 / 下级共用的基本信息字段（不含上下级区块）。
  List<Widget> _buildPersonFields({
    required String namePrefix,
    required int personId,
    required bool nameRequired,
  }) {
    _namePrefixByPersonId[personId] = namePrefix;
    final nameEnKey = _nameEnKeys.putIfAbsent(
      personId,
      GlobalKey<FormFieldState<String>>.new,
    );
    final nameEnFocus = _nameEnFocusOf(personId);
    final epoch = _personEpochByDraftId[personId] ?? 0;
    return [
      KeyedSubtree(
        key: ValueKey('person-fields-$personId-$epoch'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextFormField(
                    name: '${namePrefix}_nameZh',
                    label: '姓名',
                    required: nameRequired,
                    density: AppDensity.compact,
                    hintText: '中文姓名',
                    initialValue: _initStr('${namePrefix}_nameZh'),
                    validator: nameRequired
                        ? AppValidators.required(message: '请输入姓名')
                        : null,
                    onChanged: (v) => _tryAutofillNameEn(
                      personId,
                      namePrefix,
                      nameZh: v,
                      force: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    key: nameEnKey,
                    name: '${namePrefix}_nameEn',
                    label: 'Name',
                    density: AppDensity.compact,
                    hintText: 'English name',
                    focusNode: nameEnFocus,
                    initialValue: _initStr('${namePrefix}_nameEn'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSelectFormField<String>(
                    name: '${namePrefix}_gender',
                    label: '性别',
                    hintText: '请选择',
                    options: _kGenderOptions,
                    clearable: true,
                    initialValue: _initStr('${namePrefix}_gender'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(
              AppTextFormField(
                name: '${namePrefix}_age',
                label: '年龄段',
                density: AppDensity.compact,
                hintText: '如：约为35岁左右，即1990年左右',
                initialValue: _initStr('${namePrefix}_age'),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _entitiesRevision,
                builder: (context, _, _) {
                  return AppSelectFormField<String>(
                    name: '${namePrefix}_enterprise',
                    label: '关联企业',
                    hintText: '经营主体',
                    options: _enterpriseOptions(),
                    clearable: true,
                    initialValue: _initStr('${namePrefix}_enterprise'),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _row(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppSelectFormField<String>(
                      name: '${namePrefix}_province',
                      label: '所在城市',
                      hintText: '省',
                      options: _provinceOptions,
                      clearable: true,
                      initialValue: _initStr('${namePrefix}_province'),
                      onChanged: (v) => _onProvinceChanged(personId, v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _cityRevision,
                      builder: (context, _, _) {
                        return KeyedSubtree(
                          key: ValueKey(
                            'person-city-$personId-'
                            '${_cityEpochByDraftId[personId] ?? 0}',
                          ),
                          child: AppSelectFormField<String>(
                            name: '${namePrefix}_city',
                            label: ' ',
                            hintText: '市',
                            options:
                                _cityOptionsByDraftId[personId] ?? const [],
                            clearable: true,
                            initialValue: _initStr('${namePrefix}_city'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              AppTextFormField(
                name: '${namePrefix}_address',
                label: '详细地址',
                density: AppDensity.compact,
                hintText: '街道门牌等',
                initialValue: _initStr('${namePrefix}_address'),
              ),
            ),
            const SizedBox(height: 8),
            _row(
              AppTextFormField(
                name: '${namePrefix}_title',
                label: '部门/职位',
                density: AppDensity.compact,
                hintText: '部门 / 职位',
                initialValue: _initStr('${namePrefix}_title'),
              ),
              AppTextFormField(
                name: '${namePrefix}_role',
                label: '职能描述',
                density: AppDensity.compact,
                hintText: '职责说明',
                initialValue: _initStr('${namePrefix}_role'),
              ),
            ),
            const SizedBox(height: 8),
            _row(
              AppMultiSelectFormField<String>(
                name: '${namePrefix}_scope',
                label: '负责市场范围',
                options: _marketScopeOptions,
                initialValue: _initList('${namePrefix}_scope'),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _brandChoicesRevision,
                builder: (context, _, _) {
                  return AppMultiSelectFormField<String>(
                    name: '${namePrefix}_brands',
                    label: '负责品牌',
                    description: '从品牌/子品牌中选择',
                    options: _responsibleBrandOptions(),
                    initialValue: _initList('${namePrefix}_brands'),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppSelectFormField<String>(
                    name: '${namePrefix}_tenure',
                    label: '在职时间',
                    hintText: '请选择',
                    options: _tenureOptions,
                    clearable: true,
                    initialValue: _initStr('${namePrefix}_tenure'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    name: '${namePrefix}_mobile',
                    label: '手机号',
                    density: AppDensity.compact,
                    hintText: '多项用逗号分隔',
                    initialValue: _initStr('${namePrefix}_mobile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    name: '${namePrefix}_phone',
                    label: '电话',
                    density: AppDensity.compact,
                    hintText: '区号+号码',
                    initialValue: _initStr('${namePrefix}_phone'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(
              AppTextFormField(
                name: '${namePrefix}_email',
                label: '邮箱',
                density: AppDensity.compact,
                hintText: '多项用逗号分隔',
                initialValue: _initStr('${namePrefix}_email'),
              ),
              AppTextFormField(
                name: '${namePrefix}_remark',
                label: '备注',
                density: AppDensity.compact,
                hintText: '选填',
                initialValue: _initStr('${namePrefix}_remark'),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _PendingCity {
  _PendingCity({
    required this.draftId,
    required this.fieldName,
    required this.provinceCode,
    required this.cityLabel,
  });

  final int draftId;
  final String fieldName;
  final String? provinceCode;
  final String? cityLabel;
}

class _EntityDraft {
  _EntityDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
  Uint8List? licenseBytes;
  /// 编辑回显 / 预览：营业执照图片地址。
  String? licenseUrl;
  /// 业务入库：文件中心 fileId（兼容旧字段名 licenseOssId）。
  String? licenseOssId;
  final List<_TaxEntryDraft> taxEntries = [];
}

class _TaxEntryDraft {
  _TaxEntryDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
}

class _VipDraft {
  _VipDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
  final List<_VipBrandDraft> brands = [];
}

class _VipBrandDraft {
  _VipBrandDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
}

class _ContactDraft {
  _ContactDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
  final List<_PersonDraft> superiors = [];
  final List<_PersonDraft> subordinates = [];
}

class _PersonDraft {
  _PersonDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
}

class _MediaDraft {
  _MediaDraft(this.id, {this.serverId});
  final int id;
  final Object? serverId;
  Uint8List? qrBytes;
  /// 品牌库回填的二维码地址（本地未重新选图时用于预览）。
  String? qrUrl;
}

/// 营业执照附件：虚线方框 +，旁侧提示文案。
class _LicenseAttachmentPicker extends StatelessWidget {
  const _LicenseAttachmentPicker({
    required this.bytes,
    required this.onPicked,
    required this.onCleared,
    this.networkUrl,
    this.enabled = true,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final void Function(Uint8List bytes, String fileName) onPicked;
  final VoidCallback onCleared;
  final bool enabled;

  Future<void> _pick() async {
    if (!enabled) return;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    if (file == null) return;
    final data = await file.readAsBytes();
    if (data.isEmpty) return;
    if (data.lengthInBytes > 10 * 1024 * 1024) return;
    final name = file.name.trim().isEmpty ? 'business_license.jpg' : file.name;
    onPicked(data, name);
  }

  @override
  Widget build(BuildContext context) {
    final local = bytes != null && bytes!.isNotEmpty;
    final remote = (networkUrl?.trim().isNotEmpty ?? false);
    final hasImage = local || remote;
    return SizedBox(
      width: 64,
      height: 64,
      child: AppInkWell(
        onPressed: enabled ? _pick : null,
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: hasImage
              ? null
              : _DashedRectPainter(color: _kCardBorder, radius: 6),
          child: DecoratedBox(
            decoration: hasImage
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kCardBorder),
                  )
                : const BoxDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (local)
                          Image.memory(
                            bytes!,
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                            gaplessPlayback: true,
                          )
                        else
                          Image.network(
                            networkUrl!.trim(),
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                            headers: AuthSession.headers(),
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: _kEmptyBg,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 20,
                                color: _kMuted,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: AppInkWell(
                            onPressed: onCleared,
                            borderRadius: BorderRadius.circular(4),
                            child: const ColoredBox(
                              color: Color(0x99000000),
                              child: Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.add, size: 22, color: _kMuted),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 自媒体行内「二维码」上传：虚线方框 + 预览，对齐稿面。
class _MediaQrPicker extends StatelessWidget {
  const _MediaQrPicker({
    required this.bytes,
    required this.onPicked,
    required this.onCleared,
    this.networkUrl,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final ValueChanged<Uint8List> onPicked;
  final VoidCallback onCleared;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (file == null) return;
    final data = await file.readAsBytes();
    if (data.isEmpty) return;
    onPicked(data);
  }

  @override
  Widget build(BuildContext context) {
    final local = bytes != null && bytes!.isNotEmpty;
    final remote = networkUrl?.trim().isNotEmpty ?? false;
    final hasImage = local || remote;
    return SizedBox(
      width: 56,
      height: 56,
      child: AppInkWell(
        onPressed: _pick,
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: hasImage
              ? null
              : _DashedRectPainter(color: _kCardBorder, radius: 6),
          child: DecoratedBox(
            decoration: hasImage
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kCardBorder),
                  )
                : const BoxDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (local)
                          Image.memory(
                            bytes!,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            gaplessPlayback: true,
                          )
                        else
                          Image.network(
                            networkUrl!.trim(),
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            headers: AuthSession.headers(),
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: _kEmptyBg,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 18,
                                color: _kMuted,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: AppInkWell(
                            onPressed: onCleared,
                            borderRadius: BorderRadius.circular(4),
                            child: const ColoredBox(
                              color: Color(0x99000000),
                              child: Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 16, color: _kMuted),
                        SizedBox(height: 2),
                        Text(
                          '二维码',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(radius),
        ),
      );
    const dash = 3.0;
    const gap = 2.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _SalesDraft {
  _SalesDraft({
    required this.id,
    required this.userId,
    required this.nameZh,
    required this.nameEn,
    required this.gender,
    required this.deptPost,
    required this.createTime,
    this.serverId,
  });

  final int id;
  final int userId;
  final Object? serverId;
  final String nameZh;
  final String nameEn;
  final String gender;
  final String deptPost;
  final String createTime;

  factory _SalesDraft.fromEmployee(HrmEmployee e, int localId) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return _SalesDraft(
      id: localId,
      userId: e.userId ?? localId,
      nameZh: e.name?.trim() ?? '-',
      nameEn: e.englishName?.trim() ?? '-',
      gender: hrmEmployeeGenderLabel(e.gender),
      deptPost: hrmEmployeeDeptPost(e),
      createTime: '$y-$m-$d',
    );
  }
}
