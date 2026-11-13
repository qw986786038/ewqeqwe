import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_ui/lemon_ui.dart';

import '../../../models/customer_archive.dart';
import '../../../models/oac_brand_detail.dart';
import '../../../services/brand_api.dart';
import '../../../services/customer_api.dart';
import '../../../services/order_api.dart';
import '../../customer_archive/dialogs/quick_create_brand_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kSectionTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF4E5969);
const _kHint = Color(0xFFC9CDD4);
const _kMuted = Color(0xFF86909C);

const _kContractTypeOptions = [
  AppOption(value: '广告发布', label: '广告发布'),
  AppOption(value: '框架协议', label: '框架协议'),
  AppOption(value: '项目制', label: '项目制'),
];

const _kRelationOptions = [
  AppOption(value: '经营主体', label: '经营主体'),
  AppOption(value: '关联4A', label: '关联4A'),
  AppOption(value: '媒体主', label: '媒体主'),
];

/// 打开「+添加订单」弹窗（与主体概览同款 HyperDialog 小窗）。
/// [initialBrandId] 可选：从详情页打开时预选该品牌。
/// [editingOrder] 非空时为「编辑订单」，保存走 `PUT /desktop/oac/order`。
/// 返回 `true` 表示创建/更新成功。
Future<bool> showAddOrderDialog(
  BuildContext context, {
  String? initialBrandId,
  OrderItem? editingOrder,
}) async {
  final result = await showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      // 弹窗内取消全局文字放大；控件高度略留余量，避免下拉选中后文字上下被裁切。
      final mq = MediaQuery.of(dialogContext);
      return AppShadcnScope(
        config: AppThemeConfig.standard(
          primary: _kPrimary,
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
          child: _AddOrderDialog(
            initialBrandId: initialBrandId,
            editingOrder: editingOrder,
            onClose: ([bool saved = false]) =>
                Navigator.of(dialogContext).pop(saved),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// 打开「编辑订单」弹窗。
Future<bool> showEditOrderDialog(
  BuildContext context, {
  required OrderItem order,
  String? initialBrandId,
}) =>
    showAddOrderDialog(
      context,
      initialBrandId: initialBrandId ?? order.brandId,
      editingOrder: order,
    );

class _AddOrderDialog extends StatefulWidget {
  const _AddOrderDialog({
    required this.onClose,
    this.initialBrandId,
    this.editingOrder,
  });

  final String? initialBrandId;
  final OrderItem? editingOrder;
  final void Function([bool saved]) onClose;

  @override
  State<_AddOrderDialog> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends State<_AddOrderDialog> {
  AppFormController _form = AppFormController();
  final _orderApi = OrderApi();
  final _customerApi = CustomerApi();
  final _brandApi = BrandApi();
  late final TextEditingController _durationCtrl;
  late final TextEditingController _remarkCtrl;

  var _bootLoading = true;
  var _detailLoading = false;
  String? _bootError;
  List<CustomerArchive> _brands = const [];
  List<CustomerArchive> _agencies = const [];
  OacBrandDetail? _detail;
  CustomerArchive? _selectedBrand;
  EnterpriseItem? _selectedEnterprise;
  String? _selectedAgencyId;
  /// 品牌切换时递增：重建签约主体下拉。
  var _brandEpoch = 0;
  /// 签约主体切换时递增：重建只读品牌信息与联系人。
  var _fillEpoch = 0;

  bool get _isEdit => widget.editingOrder != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingOrder;
    _durationCtrl = TextEditingController(
      text: editing?.durationDays != null && editing!.durationDays! > 0
          ? '${editing.durationDays} 天'
          : '',
    );
    _remarkCtrl = TextEditingController(text: editing?.remark?.trim() ?? '');
    _bootstrap();
  }

  @override
  void dispose() {
    _form.dispose();
    _durationCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  /// KeyedSubtree 换 key 时新字段会先 register、旧字段要到帧末才 dispose。
  /// 换新的 FormController，避免同名字段在同一 controller 上冲突。
  void _swapFormController() {
    final previous = _form;
    _form = AppFormController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
  }

  void _remountFillFields() {
    _swapFormController();
    _fillEpoch++;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootLoading = true;
      _bootError = null;
    });
    try {
      final results = await Future.wait([
        _customerApi.fetchList(
          OacCustomerQuery(
            customerType: 'brand',
            status: '0',
            pageNum: 1,
            pageSize: 500,
          ),
        ),
        _customerApi.fetchList(
          OacCustomerQuery(
            customerType: 'agency',
            status: '0',
            pageNum: 1,
            pageSize: 500,
          ),
        ),
      ]);
      if (!mounted) return;
      _brands = results[0].rows;
      _agencies = results[1].rows;

      // 优先用入口传入的品牌；否则默认选中列表第一项，并带出首个签约主体。
      final initial = _resolveInitialBrand() ?? _firstBrand();
      if (initial?.id != null) {
        await _onBrandSelected(initial!.id);
      }
      if (!mounted) return;
      setState(() => _bootLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bootLoading = false;
        _bootError = e.toString();
      });
    }
  }

  CustomerArchive? _resolveInitialBrand() {
    final candidates = [
      widget.editingOrder?.brandId?.trim(),
      widget.initialBrandId?.trim(),
    ];
    for (final initialId in candidates) {
      if (initialId == null || initialId.isEmpty) continue;
      for (final b in _brands) {
        if (b.id == initialId) return b;
      }
    }
    return null;
  }

  EnterpriseItem? _resolveEnterpriseForEdit(OacBrandDetail detail) {
    final editing = widget.editingOrder;
    if (editing == null) return _firstEnterprise(detail);
    final entId = editing.signEnterpriseId?.trim();
    if (entId != null && entId.isNotEmpty) {
      for (final e in detail.enterprises) {
        if (e.id?.trim() == entId) return e;
      }
    }
    final name = editing.enterprise?.trim();
    if (name != null && name.isNotEmpty) {
      for (final e in detail.enterprises) {
        if (e.name?.trim() == name) return e;
      }
    }
    return _firstEnterprise(detail);
  }

  DateTime? _parseDate(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ?? DateTime.tryParse(s);
  }

  shad.DateTimeRange? _editPeriod() {
    final start = _parseDate(widget.editingOrder?.periodStart);
    final end = _parseDate(widget.editingOrder?.periodEnd);
    if (start == null || end == null) return null;
    return shad.DateTimeRange(start, end);
  }

  List<String> _editContactNames() =>
      _splitNames(widget.editingOrder?.contact);

  List<String> _editSalesNames() =>
      _splitNames(widget.editingOrder?.salesPerson);

  String? _editRelationValue() {
    final editing = widget.editingOrder;
    if (editing == null) return null;
    final label = editing.relationLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final raw = editing.relation?.trim();
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'operating_entity' || 'operatingEntity' || 'operator' => '经营主体',
      'agency' => '关联4A',
      'media' => '媒体主',
      _ => raw,
    };
  }

  CustomerArchive? _firstBrand() {
    for (final b in _brands) {
      if (b.id != null && (b.brandName?.trim().isNotEmpty ?? false)) {
        return b;
      }
    }
    return null;
  }

  Future<void> _openQuickCreate() async {
    await showQuickCreateBrandDialog(context, agencies: _agencies);
    if (!mounted) return;
    // 创建成功后刷新品牌列表（接口接入后可按返回 id 预选）。
    try {
      final page = await _customerApi.fetchList(
        OacCustomerQuery(
          customerType: 'brand',
          status: '0',
          pageNum: 1,
          pageSize: 500,
        ),
      );
      if (!mounted) return;
      setState(() => _brands = page.rows);
    } catch (_) {}
  }

  Future<void> _onBrandSelected(String? brandId) async {
    final id = brandId?.trim();
    if (id == null || id.isEmpty) {
      setState(() {
        _selectedBrand = null;
        _selectedEnterprise = null;
        _detail = null;
        _brandEpoch++;
        _remountFillFields();
      });
      return;
    }
    CustomerArchive? row;
    for (final b in _brands) {
      if (b.id == id) {
        row = b;
        break;
      }
    }
    setState(() {
      _selectedBrand = row;
      _selectedEnterprise = null;
      _detailLoading = true;
    });
    try {
      final detail = await _brandApi.fetchDetail(id);
      if (!mounted) return;
      final firstEnt = _resolveEnterpriseForEdit(detail);
      final editingAgency = widget.editingOrder?.agencyId?.trim();
      setState(() {
        _detail = detail;
        _selectedEnterprise = firstEnt;
        _selectedAgencyId = (editingAgency != null && editingAgency.isNotEmpty)
            ? editingAgency
            : _resolveAgencyId(detail: detail, brand: row);
        _detailLoading = false;
        _brandEpoch++;
        _remountFillFields();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _selectedEnterprise = null;
        _detailLoading = false;
        _brandEpoch++;
        _remountFillFields();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('品牌详情加载失败：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onEnterpriseSelected(String? key) {
    final enterprise = _findEnterprise(key);
    setState(() {
      _selectedEnterprise = enterprise;
      _remountFillFields();
    });
  }

  EnterpriseItem? _firstEnterprise(OacBrandDetail detail) {
    for (final e in detail.enterprises) {
      if (e.name?.trim().isNotEmpty == true) return e;
    }
    return null;
  }

  String _brandOptionLabel(CustomerArchive b) {
    final name = b.brandName?.trim() ?? '';
    final type = _clientTypeLabel(b.customerType);
    if (type == null || type.isEmpty) return name;
    return '$name ($type)';
  }

  String? _clientTypeLabel(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    return switch (t) {
      'brand' => '品牌企业',
      'agency' => '4A公司',
      'channel' => '渠道广告公司',
      'gov' => '政务单位',
      'dsp' => 'DSP/API',
      _ => t,
    };
  }

  String _enterpriseKey(EnterpriseItem e) {
    final id = e.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    return e.name?.trim() ?? '';
  }

  void _onPeriodChanged(shad.DateTimeRange? range) {
    if (range == null) {
      _durationCtrl.text = '';
      return;
    }
    final days = range.end.difference(range.start).inDays + 1;
    _durationCtrl.text = days > 0 ? '$days 天' : '';
  }

  String _fmtDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  String _joinNames(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join(',');
    }
    return raw?.toString().trim() ?? '';
  }

  List<String> _splitNames(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[;；,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  EnterpriseItem? _findEnterprise(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final e in _detail?.enterprises ?? const <EnterpriseItem>[]) {
      if (e.id == key || e.name?.trim() == key) return e;
    }
    return null;
  }

  CustomerArchive? _findAgency(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final e in _agencies) {
      if (e.id == key || e.brandName?.trim() == key) return e;
    }
    return null;
  }

  (DateTime?, DateTime?) _periodBounds(dynamic period) {
    if (period is shad.DateTimeRange) {
      return (period.start, period.end);
    }
    if (period is DateTimeRange) {
      return (period.start, period.end);
    }
    return (null, null);
  }

  String? _resolveCity({
    OacBrandDetail? detail,
    EnterpriseItem? enterprise,
  }) {
    final entCity = enterprise?.city?.trim();
    if (entCity != null && entCity.isNotEmpty) return entCity;
    final brandCity = detail?.brand?.city?.trim();
    if (brandCity != null && brandCity.isNotEmpty) return brandCity;
    for (final e in detail?.enterprises ?? const <EnterpriseItem>[]) {
      final c = e.city?.trim();
      if (c != null && c.isNotEmpty) return c;
    }
    final listCity = _selectedBrand?.city?.trim();
    if (listCity == null || listCity.isEmpty) return null;
    return _splitNames(listCity).firstOrNull;
  }

  String? _resolveRelation(EnterpriseItem? enterprise) {
    final t = enterprise?.type?.trim();
    if (t != null && t.isNotEmpty) return t;
    final listRel = _selectedBrand?.relation?.trim();
    if (listRel == null || listRel.isEmpty) return null;
    return _splitNames(listRel).firstOrNull;
  }

  String? _resolveAgencyId({
    OacBrandDetail? detail,
    CustomerArchive? brand,
  }) {
    final serviceAgencyId = brand?.serviceAgencyId?.trim();
    if (serviceAgencyId != null && serviceAgencyId.isNotEmpty) {
      return serviceAgencyId;
    }
    for (final a in detail?.agencies ?? const <AgencyItem>[]) {
      final id = a.id?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  String? _agencyDisplayName(String? agencyId) {
    if (agencyId == null || agencyId.isEmpty) return null;
    for (final a in _agencies) {
      if (a.id == agencyId) {
        final n = a.brandName?.trim();
        if (n != null && n.isNotEmpty) return n;
      }
    }
    for (final a in _detail?.agencies ?? const <AgencyItem>[]) {
      if (a.id == agencyId) {
        final n = a.name?.trim();
        if (n != null && n.isNotEmpty) return n;
      }
    }
    return null;
  }

  List<String> _salesNames(OacBrandDetail detail) {
    final list = detail.brand?.ownerNameList;
    if (list != null && list.isNotEmpty) {
      return list.where((e) => e.trim().isNotEmpty).toList();
    }
    final fromBrand = _splitNames(detail.brand?.ownerNames);
    if (fromBrand.isNotEmpty) return fromBrand;
    return _splitNames(_selectedBrand?.salesperson);
  }

  Future<void> _save() async {
    if (_remarkCtrl.text.characters.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备注不能超过 500 字')),
      );
      return;
    }
    try {
      final ok = await _form.submit((values) async {
        final brandId = _asInt(values['brandId'] ?? _selectedBrand?.id);
        if (brandId == null) {
          throw OrderApiException('请选择品牌简称');
        }

        final enterpriseKey = values['enterprise']?.toString();
        final enterprise =
            _findEnterprise(enterpriseKey) ?? _selectedEnterprise;
        final enterpriseName = enterprise?.name?.trim().isNotEmpty == true
            ? enterprise!.name!.trim()
            : enterpriseKey?.trim();

        final agencyId = _asInt(
          _findAgency(values['agency']?.toString())?.id ??
              _resolveAgencyId(detail: _detail, brand: _selectedBrand),
        );

        final signDate = values['signDate'];
        final signDt = signDate is DateTime ? signDate : null;
        final (periodStart, periodEnd) = _periodBounds(values['period']);

        final amountRaw = values['amount']?.toString().trim() ?? '';
        final amount = num.tryParse(amountRaw);
        if (amount == null) {
          throw OrderApiException('订单金额格式不正确');
        }

        int? durationDays;
        if (periodStart != null && periodEnd != null) {
          durationDays = periodEnd.difference(periodStart).inDays + 1;
          if (durationDays < 1) durationDays = null;
        }

        final relation = _resolveRelation(enterprise) ??
            values['relation']?.toString();
        final clientType = _clientTypeLabel(_selectedBrand?.customerType) ??
            values['clientType']?.toString();
        final industry = _detail?.brand?.industry?.trim() ??
            _selectedBrand?.industry?.trim() ??
            values['industry']?.toString();
        final city = _resolveCity(
              detail: _detail,
              enterprise: enterprise,
            ) ??
            values['city']?.toString();

        final editingId = _asInt(widget.editingOrder?.id);
        final agencyFromForm = _isEdit
            ? _asInt(
                _findAgency(values['agency']?.toString())?.id ??
                    values['agency'] ??
                    _selectedAgencyId,
              )
            : agencyId;
        final relationFromForm = _isEdit
            ? (values['relation']?.toString().trim().isNotEmpty == true
                ? values['relation']?.toString().trim()
                : relation)
            : relation;

        final body = OacOrderCreateBody()
          ..id = editingId
          ..brandId = brandId
          ..agencyId = agencyFromForm
          ..agencyCustomerId = agencyFromForm
          ..signEnterpriseId = _asInt(enterprise?.id)
          ..enterpriseName = enterpriseName
          ..dealRelation = relationFromForm
          ..customerType = clientType
          ..industry = industry
          ..city = city
          ..orderName = widget.editingOrder?.orderNo?.trim()
          ..amount = amount
          ..signDate = signDt == null ? null : _fmtDateTime(signDt)
          ..orderTime = signDt == null ? null : _fmtDateTime(signDt)
          ..periodStart =
              periodStart == null ? null : _fmtDateTime(periodStart)
          ..periodEnd = periodEnd == null ? null : _fmtDateTime(periodEnd)
          ..durationDays = durationDays
          ..contactName = _joinNames(values['clientContacts'])
          ..ownerNames = _joinNames(values['ourContacts'])
          ..contractType = values['contractType']?.toString()
          ..remark = _remarkCtrl.text.trim().isEmpty
              ? null
              : _remarkCtrl.text.trim();

        if (_isEdit) {
          if (editingId == null) {
            throw OrderApiException('订单 id 无效，无法保存');
          }
          await _orderApi.updateOrder(body);
        } else {
          await _orderApi.createOrder(body);
        }
      });
      if (!ok || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '订单已更新' : '订单已保存')),
      );
      widget.onClose(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
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
            color: _kSectionTitle,
          ),
        ),
      ],
    );
  }

  Widget _quickCreateLink({VoidCallback? onPressed}) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 12, color: _kPrimary),
            SizedBox(width: 1),
            Text(
              '快速新建',
              style: TextStyle(
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

  /// 「快速新建」在标签行右侧；下拉控件单独占满整列宽度，避免选中文案被箭头挡住。
  Widget _selectWithQuickCreate({
    required String label,
    required Widget field,
    bool required = false,
    VoidCallback? onQuickCreate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kLabel,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(text: label),
                    if (required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Color(0xFFFF4D4F),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onQuickCreate != null)
              _quickCreateLink(onPressed: onQuickCreate),
          ],
        ),
        const SizedBox(height: 6),
        field,
      ],
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

  /// 不可编辑控件略降透明度，与可填项区分更明显。
  Widget _dimDisabled(Widget child) => Opacity(opacity: 0.62, child: child);

  /// 品牌信息只读字段（灰显不可编辑）。
  Widget _readonlyField({
    required String name,
    required String label,
    required String? value,
    bool required = false,
    String? hintText,
  }) {
    final text = value?.trim() ?? '';
    return _dimDisabled(
      AppTextFormField(
        name: name,
        label: label,
        required: required,
        initialValue: text,
        hintText: hintText,
        enabled: false,
        readOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandOptions = [
      for (final b in _brands)
        if (b.id != null && (b.brandName?.trim().isNotEmpty ?? false))
          AppOption(value: b.id!, label: _brandOptionLabel(b)),
    ];

    final detail = _detail;
    final enterprise = _selectedEnterprise;
    final editing = widget.editingOrder;
    final industry = detail?.brand?.industry?.trim() ??
        _selectedBrand?.industry?.trim() ??
        editing?.industry?.trim();
    final city = _resolveCity(detail: detail, enterprise: enterprise) ??
        editing?.city?.trim() ??
        '';
    final relation = _editRelationValue() ?? _resolveRelation(enterprise) ?? '';
    final clientType = _clientTypeLabel(
          _selectedBrand?.customerType ?? editing?.customerType,
        ) ??
        '';
    final agencyId = _selectedAgencyId ??
        _resolveAgencyId(detail: detail, brand: _selectedBrand);
    final agencyName = _agencyDisplayName(agencyId) ??
        editing?.agencyName?.trim() ??
        '';

    final enterprises = detail?.enterprises
            .where((e) => e.name?.trim().isNotEmpty == true)
            .map(
              (e) => AppOption(
                value: _enterpriseKey(e),
                label: e.name!.trim(),
              ),
            )
            .toList() ??
        const <AppOption<String>>[];
    final selectedEntKey =
        enterprise == null ? null : _enterpriseKey(enterprise);

    final agencyOptions = [
      for (final a in _agencies)
        if (a.id != null && (a.brandName?.trim().isNotEmpty ?? false))
          AppOption(value: a.id!, label: a.brandName!.trim()),
    ];

    final entId = enterprise?.id?.trim();
    final contactOptions = detail?.contacts
            .where((e) {
              final name = e.name?.trim();
              if (name == null || name.isEmpty) return false;
              if (entId == null || entId.isEmpty) return true;
              final cid = e.enterpriseId?.trim();
              if (cid == null || cid.isEmpty) return true;
              return cid == entId;
            })
            .map((e) => AppOption(value: e.name!.trim(), label: e.name!.trim()))
            .toList() ??
        const <AppOption<String>>[];
    final salesOptions = (detail == null ? const <String>[] : _salesNames(detail))
        .map((e) => AppOption(value: e, label: e))
        .toList();

    final editContacts = _editContactNames();
    final editSales = _editSalesNames();
    final initialContacts = _isEdit
        ? [
            for (final n in editContacts)
              if (contactOptions.any((o) => o.value == n) || n.isNotEmpty) n,
          ]
        : (contactOptions.isNotEmpty
            ? [contactOptions.first.value]
            : const <String>[]);
    final initialSales = _isEdit
        ? [
            for (final n in editSales)
              if (salesOptions.any((o) => o.value == n) || n.isNotEmpty) n,
          ]
        : (salesOptions.isNotEmpty
            ? [salesOptions.first.value]
            : const <String>[]);

    final editPeriod = _editPeriod();
    final editSignDate = _parseDate(editing?.orderTime) ?? DateTime.now();
    final editContract = editing?.contractType?.trim();
    final editAmount = editing?.amount?.trim() ?? '';
    final editOrderNo = editing?.orderNo?.trim() ?? '';

    final quickCreateEnabled = !_bootLoading && !_isEdit;

    return AppForm(
      key: ValueKey(_fillEpoch),
      controller: _form,
      child: HyperDialog(
        title: Text(_isEdit ? '编辑订单' : '+添加订单'),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 640),
        onClose: () => widget.onClose(),
        content: DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 12, color: _kLabel),
          child: _bootLoading
              ? const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _bootError != null
                  ? SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          _bootError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF4D4F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('品牌信息'),
                        const SizedBox(height: 8),
                        _row(
                          _selectWithQuickCreate(
                            label: '品牌简称',
                            required: true,
                            onQuickCreate:
                                quickCreateEnabled ? _openQuickCreate : null,
                            field: KeyedSubtree(
                              key: ValueKey(
                                'brand-$_brandEpoch-${_selectedBrand?.id}',
                              ),
                              child: AppSelectFormField<String>(
                                name: 'brandId',
                                hintText: '请选择品牌',
                                popupMinWidth: 180,
                                options: brandOptions,
                                initialValue: _selectedBrand?.id,
                                onChanged: _onBrandSelected,
                                validator: (v) =>
                                    v == null ? '请选择品牌简称' : null,
                              ),
                            ),
                          ),
                          _detailLoading
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 28),
                                  child: Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : _selectWithQuickCreate(
                                  label: '签约主体全称',
                                  required: true,
                                  onQuickCreate: quickCreateEnabled
                                      ? _openQuickCreate
                                      : null,
                                  field: KeyedSubtree(
                                    key: ValueKey('ent-$_brandEpoch'),
                                    child: AppSelectFormField<String>(
                                      name: 'enterprise',
                                      hintText: '请选择',
                                      popupMinWidth: 180,
                                      options: enterprises,
                                      initialValue: selectedEntKey,
                                      onChanged: _onEnterpriseSelected,
                                      validator: (v) =>
                                          v == null ? '请选择签约主体' : null,
                                    ),
                                  ),
                                ),
                        ),
                        KeyedSubtree(
                          key: ValueKey('fill-$_fillEpoch'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              _row(
                                _isEdit
                                    ? AppSelectFormField<String>(
                                        name: 'relation',
                                        label: '关联关系',
                                        required: true,
                                        hintText: '请选择',
                                        popupMinWidth: 160,
                                        options: [
                                          ..._kRelationOptions,
                                          if (relation.isNotEmpty &&
                                              !_kRelationOptions.any(
                                                (o) => o.value == relation,
                                              ))
                                            AppOption(
                                              value: relation,
                                              label: relation,
                                            ),
                                        ],
                                        initialValue: relation.isEmpty
                                            ? null
                                            : relation,
                                        validator: (v) =>
                                            v == null ? '请选择关联关系' : null,
                                      )
                                    : _readonlyField(
                                        name: 'relation',
                                        label: '关联关系',
                                        required: true,
                                        value: relation,
                                        hintText: '随签约主体自动填充',
                                      ),
                                _readonlyField(
                                  name: 'clientType',
                                  label: '客户类型',
                                  required: true,
                                  value: clientType,
                                  hintText: '随品牌自动填充',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _row(
                                _readonlyField(
                                  name: 'industry',
                                  label: '所属行业',
                                  required: true,
                                  value: industry,
                                  hintText: '随品牌自动填充',
                                ),
                                _readonlyField(
                                  name: 'city',
                                  label: '所在城市',
                                  required: true,
                                  value: city,
                                  hintText: '随签约主体自动填充',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _row(
                                _isEdit
                                    ? AppSelectFormField<String>(
                                        name: 'agency',
                                        label: '关联 4A',
                                        hintText: '请选择',
                                        popupMinWidth: 180,
                                        options: agencyOptions,
                                        initialValue: agencyId,
                                        onChanged: (v) => setState(
                                          () => _selectedAgencyId = v,
                                        ),
                                      )
                                    : _readonlyField(
                                        name: 'agency',
                                        label: '关联 4A',
                                        value: agencyName,
                                        hintText: '随品牌自动填充',
                                      ),
                              ),
                              const SizedBox(height: 12),
                              _sectionTitle('订单信息'),
                              const SizedBox(height: 8),
                              _row(
                                _dimDisabled(
                                  AppTextFormField(
                                    name: 'orderNo',
                                    label: '订单编号',
                                    initialValue: editOrderNo,
                                    hintText: _isEdit ? null : '保存后自动生成',
                                    enabled: false,
                                    readOnly: true,
                                  ),
                                ),
                                AppSelectFormField<String>(
                                  name: 'contractType',
                                  label: '合同类型',
                                  required: true,
                                  hintText: '请选择',
                                  popupMinWidth: 160,
                                  options: [
                                    ..._kContractTypeOptions,
                                    if (editContract != null &&
                                        editContract.isNotEmpty &&
                                        !_kContractTypeOptions.any(
                                          (o) => o.value == editContract,
                                        ))
                                      AppOption(
                                        value: editContract,
                                        label: editContract,
                                      ),
                                  ],
                                  initialValue: (editContract != null &&
                                          editContract.isNotEmpty)
                                      ? editContract
                                      : '广告发布',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _row(
                                AppTextFormField(
                                  name: 'amount',
                                  label: '订单金额',
                                  required: true,
                                  initialValue: editAmount,
                                  hintText: '单位：元，如 15000000',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  trailing: const Text(
                                    '元',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kMuted,
                                    ),
                                  ),
                                  validator: AppValidators.required(
                                    message: '请输入订单金额',
                                  ),
                                ),
                                AppDatePickerFormField(
                                  name: 'signDate',
                                  label: '订单签约时间',
                                  required: true,
                                  // popover 在弹窗内会因 IntrinsicWidth+Spacer 横向溢出，改 dialog
                                  mode: shad.PromptMode.dialog,
                                  initialValue: editSignDate,
                                  validator: (v) =>
                                      v == null ? '请选择签约时间' : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _row(
                                AppDateRangePickerFormField(
                                  name: 'period',
                                  label: '订单周期',
                                  required: true,
                                  hintText: '开始日期 - 结束日期',
                                  mode: shad.PromptMode.dialog,
                                  initialValue: editPeriod,
                                  onChanged: _onPeriodChanged,
                                  validator: (v) =>
                                      v == null ? '请选择订单周期' : null,
                                ),
                                _dimDisabled(
                                  AppTextFormField(
                                    name: 'duration',
                                    label: '订单时长',
                                    controller: _durationCtrl,
                                    hintText: '按周期自动计算',
                                    enabled: false,
                                    readOnly: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppTextAreaFormField(
                                name: 'remark',
                                label: '备注',
                                controller: _remarkCtrl,
                                hintText: '补充说明',
                                minHeight: 72,
                                onChanged: (_) => setState(() {}),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 2,
                                    right: 2,
                                  ),
                                  child: Text(
                                    '${_remarkCtrl.text.characters.length}/500',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _kHint,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _sectionTitle('关联人信息'),
                              const SizedBox(height: 8),
                              _row(
                                AppMultiSelectFormField<String>(
                                  name: 'clientContacts',
                                  label: _isEdit ? '客户联系人' : '客户方联系人',
                                  required: true,
                                  options: [
                                    ...contactOptions,
                                    for (final n in editContacts)
                                      if (n.isNotEmpty &&
                                          !contactOptions
                                              .any((o) => o.value == n))
                                        AppOption(value: n, label: n),
                                  ],
                                  initialValue: initialContacts,
                                  validator: (v) => v == null || v.isEmpty
                                      ? '请选择客户联系人'
                                      : null,
                                ),
                                AppMultiSelectFormField<String>(
                                  name: 'ourContacts',
                                  label: '我方联系人',
                                  required: true,
                                  options: [
                                    ...salesOptions,
                                    for (final n in editSales)
                                      if (n.isNotEmpty &&
                                          !salesOptions
                                              .any((o) => o.value == n))
                                        AppOption(value: n, label: n),
                                  ],
                                  initialValue: initialSales,
                                  validator: (v) => v == null || v.isEmpty
                                      ? '请选择我方联系人'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
        actions: [
          HyperButton.outlined(
            onPressed: () => widget.onClose(),
            label: const Text('取消'),
          ),
          HyperButton.filled(
            onPressed: (_bootLoading || _detailLoading) ? null : _save,
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
