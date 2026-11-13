import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../models/srm_purchase_order.dart';
import '../../../../services/srm_purchase_order_api.dart';
import '../../../../utils/china_regions.dart';
import 'select_counterpart_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
/// 横向表单统一标签列宽，保证每列输入框左缘对齐。
const _kPoLabelWidth = 88.0;

const _kContractTypeOptions = [
  AppOption(value: '设备采购', label: '设备采购'),
  AppOption(value: '媒介采购', label: '媒介采购'),
  AppOption(value: '物业租赁', label: '物业租赁'),
  AppOption(value: '维保运维', label: '维保运维'),
  AppOption(value: '灵活用工', label: '灵活用工'),
  AppOption(value: '技术服务', label: '技术服务'),
  AppOption(value: '物料制作', label: '物料制作'),
  AppOption(value: '工程施工', label: '工程施工'),
  AppOption(value: '其它', label: '其它'),
];

const _kSettlementOptions = [
  AppOption(value: '月结', label: '月结'),
  AppOption(value: '季结', label: '季结'),
  AppOption(value: '项目结算', label: '项目结算'),
  AppOption(value: '预付', label: '预付'),
  AppOption(value: '货到付款', label: '货到付款'),
];

const _kInvoiceTypeOptions = [
  AppOption(value: '专用发票', label: '专用发票'),
  AppOption(value: '普通发票', label: '普通发票'),
];

const _kTaxRateOptions = [
  AppOption(value: '3%', label: '3%'),
  AppOption(value: '6%', label: '6%'),
  AppOption(value: '9%', label: '9%'),
  AppOption(value: '11%', label: '11%'),
  AppOption(value: '13%', label: '13%'),
  AppOption(value: '其他', label: '其他'),
];

const _kTaxRatePresets = {'3%', '6%', '9%', '11%', '13%'};

enum _PoFormMode { create, view, edit }

/// 打开「创建采购订单」弹窗。成功后返回 `true`。
Future<bool> showPurchaseOrderCreateDialog(BuildContext context) {
  return _showPoFormDialog(context, mode: _PoFormMode.create);
}

/// 打开「采购订单详情」弹窗；可切到编辑。成功保存后返回 `true`。
Future<bool> showPurchaseOrderDetailDialog(
  BuildContext context, {
  required String orderId,
}) {
  return _showPoFormDialog(
    context,
    mode: _PoFormMode.view,
    orderId: orderId,
  );
}

Future<bool> _showPoFormDialog(
  BuildContext context, {
  required _PoFormMode mode,
  String? orderId,
}) {
  final hostContext = context;
  return showHyperDialog<bool>(
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
          child: _PurchaseOrderFormDialog(
            initialMode: mode,
            orderId: orderId,
            hostContext: hostContext,
            onClose: (ok) => Navigator.of(dialogContext).pop(ok),
          ),
        ),
      );
    },
  ).then((v) => v == true);
}

class _PurchaseOrderFormDialog extends StatefulWidget {
  const _PurchaseOrderFormDialog({
    required this.initialMode,
    required this.hostContext,
    required this.onClose,
    this.orderId,
  });

  final _PoFormMode initialMode;
  final String? orderId;
  final BuildContext hostContext;
  final void Function(bool ok) onClose;

  @override
  State<_PurchaseOrderFormDialog> createState() =>
      _PurchaseOrderFormDialogState();
}

class _PurchaseOrderFormDialogState extends State<_PurchaseOrderFormDialog> {
  final _api = SrmPurchaseOrderApi();
  final _form = AppFormController();
  final _staffFieldKey = GlobalKey<FormFieldState<String>>();

  late _PoFormMode _mode;
  var _bootLoading = false;
  var _saving = false;
  var _formEpoch = 0;
  SrmPurchaseOrder? _detail;
  List<AppCascadeOption<String>> _regions = const [];

  bool get _readOnly => _mode == _PoFormMode.view;
  bool get _isCreate => _mode == _PoFormMode.create;

  String get _title => switch (_mode) {
        _PoFormMode.create => '创建采购订单',
        _PoFormMode.view => '采购订单详情',
        _PoFormMode.edit => '编辑采购订单',
      };

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _bootstrap();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final needDetail = !_isCreate;
    setState(() => _bootLoading = true);
    try {
      final results = await Future.wait([
        ChinaRegions.load(),
        if (needDetail) _api.fetchDetail(widget.orderId!.trim()),
      ]);
      if (!mounted) return;
      _regions = results[0] as List<AppCascadeOption<String>>;
      if (needDetail) {
        _detail = results[1] as SrmPurchaseOrder;
      }
      _formEpoch++;
      setState(() => _bootLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _bootLoading = false);
      _toast(e.toString());
      if (needDetail) widget.onClose(false);
    }
  }

  void _toast(String title, {bool afterClose = false}) {
    final ctx = afterClose ? widget.hostContext : context;
    if (!ctx.mounted) return;
    AppToast.show(context: ctx, title: title);
  }

  DateTime? _parseDate(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final day = s.length >= 10 ? s.substring(0, 10) : s;
    return DateTime.tryParse(day);
  }

  String? _formatDate(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  List<String> _cityPath(String? city) {
    final raw = city?.trim() ?? '';
    if (raw.isEmpty) return const [];
    if (raw.contains('/')) {
      return [
        for (final p in raw.split('/'))
          if (p.trim().isNotEmpty) p.trim(),
      ];
    }
    return [raw];
  }

  String? _cityFromPath(Object? value) {
    if (value is! List || value.isEmpty) return null;
    final parts = <String>[];
    for (final e in value) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) parts.add(s);
    }
    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  num? _asAmount(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }

  String? _asTrimmed(Object? value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  String? _resolveTaxRate(Map<String, Object?> values) {
    final selected = _asTrimmed(values['taxRate']);
    if (selected == null) return null;
    if (selected != '其他') return selected;
    final custom = _asTrimmed(values['taxRateCustom']);
    if (custom == null) return '其他';
    final raw = custom.endsWith('%')
        ? custom.substring(0, custom.length - 1)
        : custom;
    final n = num.tryParse(raw);
    if (n == null || n < 0) {
      throw SrmPurchaseOrderApiException('请输入税率');
    }
    if (n > 100) return '100%';
    return '$raw%';
  }

  String? _resolveSettlement(Map<String, Object?> values) {
    return _asTrimmed(values['settlementMethod']);
  }

  Map<String, dynamic> _buildBody(Map<String, Object?> values) {
    final body = <String, dynamic>{};
    void put(String key, Object? value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      body[key] = value is String ? value.trim() : value;
    }

    put('orderName', _asTrimmed(values['orderName']));
    put('orderTag', _asTrimmed(values['orderTag']));
    put('brandName', _asTrimmed(values['brandName']));
    put('supplierFullName', _asTrimmed(values['supplierFullName']));
    put('contractType', _asTrimmed(values['contractType']));
    put('orderAmount', _asAmount(values['orderAmount']));
    put('orderTime', _formatDate(values['orderTime'] as DateTime?));
    put('settlementMethod', _resolveSettlement(values));
    put('invoiceType', _asTrimmed(values['invoiceType']));
    put('taxRate', _resolveTaxRate(values));
    put('city', _cityFromPath(values['city']));
    put('contactName', _asTrimmed(values['contactName']));
    put('staffName', _asTrimmed(values['staffName']));
    put('remark', _asTrimmed(values['remark']));

    final sid = _detail?.supplierId?.trim();
    if (sid != null && sid.isNotEmpty) {
      final id = int.tryParse(sid);
      if (id != null) body['supplierId'] = id;
    }
    return body;
  }

  Future<void> _submit() async {
    if (_saving || _readOnly) return;
    final ok = await _form.submit((values) async {
      setState(() => _saving = true);
      try {
        final body = _buildBody(values);
        final name = body['orderName']?.toString().trim() ?? '';
        final brand = body['brandName']?.toString().trim() ?? '';
        if (name.isEmpty || brand.isEmpty) {
          setState(() => _saving = false);
          return;
        }
        if (_mode == _PoFormMode.create) {
          await _api.create(body);
        } else {
          final id = _detail?.id?.trim() ?? widget.orderId?.trim();
          if (id == null || id.isEmpty) {
            throw SrmPurchaseOrderApiException('采购订单 ID 无效');
          }
          body['id'] = int.tryParse(id) ?? id;
          final orderNo = _detail?.orderNo?.trim();
          if (orderNo != null && orderNo.isNotEmpty) {
            body['orderNo'] = orderNo;
          }
          await _api.update(body);
        }
        if (!mounted) return;
        final successText =
            _mode == _PoFormMode.create ? '创建成功' : '更新成功';
        widget.onClose(true);
        _toast(successText, afterClose: true);
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          _toast(e.toString());
        }
      }
    });
    if (!ok && mounted) setState(() => _saving = false);
  }

  void _enterEdit() {
    if (_mode != _PoFormMode.view) return;
    setState(() {
      _mode = _PoFormMode.edit;
      _formEpoch++;
    });
  }

  Widget _twoCol({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 16) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: w, child: left),
            const SizedBox(width: 16),
            SizedBox(width: w, child: right),
          ],
        );
      },
    );
  }

  String _dash(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? '' : t;
  }

  String _amountText(SrmPurchaseOrder? d) {
    final v = d?.orderAmount;
    if (v == null) return '';
    return v.toStringAsFixed(2);
  }

  Widget _amountField({
    required bool enabled,
    String? initialText,
  }) {
    return AppTextFormField(
      name: 'orderAmount',
      label: '订单金额',
      hintText: enabled ? '单位：万元' : null,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      initialValue: initialText,
      trailing: const Text(
        '万元',
        style: TextStyle(fontSize: 13, color: _kMuted),
      ),
    );
  }

  Future<void> _pickStaff() async {
    if (_readOnly) return;
    final picked = await showSelectCounterpartDialog(context);
    if (picked == null || !mounted) return;
    final name = picked.name?.trim() ?? '';
    if (name.isEmpty) return;
    _staffFieldKey.currentState?.didChange(name);
  }

  Widget _staffField({
    required bool enabled,
    String? initialValue,
  }) {
    final field = AppTextFormField(
      key: _staffFieldKey,
      name: 'staffName',
      label: '我方对接人',
      hintText: '请选择',
      enabled: enabled,
      readOnly: true,
      initialValue: initialValue,
      trailing: enabled
          ? const Icon(Icons.keyboard_arrow_down, size: 18, color: _kMuted)
          : null,
    );
    if (!enabled) return field;
    return SizedBox(
      width: double.infinity,
      child: AppInkWell(
        onPressed: _pickStaff,
        child: AbsorbPointer(child: field),
      ),
    );
  }

  /// 详情只读：灰底输入框展示，布局对齐截图（左订单号…联系人 / 右订单名称…对接人）。
  Widget _buildViewBody(SrmPurchaseOrder d) {
    return AppFieldScope.horizontal(
      labelWidth: _kPoLabelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          _twoCol(
            left: AppTextFormField(
              name: 'orderNo',
              label: '订单号',
              enabled: false,
              initialValue: _dash(d.orderNo),
            ),
            right: AppTextFormField(
              name: 'orderName',
              label: '订单名称',
              required: true,
              enabled: false,
              initialValue: _dash(d.orderName),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'orderTag',
              label: '订单标签',
              enabled: false,
              initialValue: _dash(d.orderTag),
            ),
            right: AppTextFormField(
              name: 'brandName',
              label: '关联品牌',
              required: true,
              enabled: false,
              initialValue: _dash(d.brandName),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'supplierFullName',
              label: '供应商全称',
              enabled: false,
              initialValue: _dash(d.supplierFullName),
            ),
            right: AppTextFormField(
              name: 'contractType',
              label: '合同类型',
              enabled: false,
              initialValue: _dash(d.contractType),
            ),
          ),
          _twoCol(
            left: _amountField(
              enabled: false,
              initialText: _amountText(d),
            ),
            right: AppTextFormField(
              name: 'orderTime',
              label: '订单时间',
              enabled: false,
              initialValue: _dash(d.orderTime),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'settlementMethod',
              label: '结算方式',
              enabled: false,
              initialValue: _dash(d.settlementMethod),
            ),
            right: AppTextFormField(
              name: 'invoiceType',
              label: '发票类型',
              enabled: false,
              initialValue: _dash(d.invoiceType),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'taxRate',
              label: '税率',
              enabled: false,
              initialValue: _dash(d.taxRate),
            ),
            right: AppTextFormField(
              name: 'city',
              label: '城市',
              enabled: false,
              initialValue: _dash(d.city),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'contactName',
              label: '联系人',
              enabled: false,
              initialValue: _dash(d.contactName),
            ),
            right: AppTextFormField(
              name: 'staffName',
              label: '我方对接人',
              enabled: false,
              initialValue: _dash(d.staffName),
            ),
          ),
          AppTextAreaFormField(
            name: 'remark',
            label: '备注',
            enabled: false,
            minHeight: 88,
            initialValue: _dash(d.remark),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateBody() {
    return AppFieldScope.horizontal(
      labelWidth: _kPoLabelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          _twoCol(
            left: AppTextFormField(
              name: 'orderName',
              label: '订单名称',
              required: true,
              hintText: '请输入订单名称',
              validator: AppValidators.required(message: '请输入订单名称'),
            ),
            right: const AppTextFormField(
              name: 'orderTag',
              label: '订单标签',
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'brandName',
              label: '关联品牌',
              required: true,
              hintText: '请输入关联品牌',
              validator: AppValidators.required(message: '请输入关联品牌'),
            ),
            right: const AppTextFormField(
              name: 'supplierFullName',
              label: '供应商全称',
            ),
          ),
          _twoCol(
            left: const AppSelectFormField<String>(
              name: 'contractType',
              label: '合同类型',
              hintText: '请选择',
              clearable: true,
              // Select 默认 IntrinsicWidth，拉满与同列输入框左缘/宽度对齐
              minWidth: double.infinity,
              options: _kContractTypeOptions,
            ),
            right: _amountField(enabled: true),
          ),
          _twoCol(
            left: const _PoOrderTimeField(),
            right: const _PoSettlementField(),
          ),
          _twoCol(
            left: const AppSelectFormField<String>(
              name: 'invoiceType',
              label: '发票类型',
              hintText: '请选择',
              clearable: true,
              minWidth: double.infinity,
              options: _kInvoiceTypeOptions,
            ),
            right: const _PoTaxRateField(),
          ),
          _twoCol(
            left: AppRegionPickerFormField<String>(
              name: 'city',
              label: '城市',
              clearable: true,
              variant: AppRegionPickerVariant.provinceCity,
              options: _regions,
              width: double.infinity,
            ),
            right: const AppTextFormField(
              name: 'contactName',
              label: '联系人',
            ),
          ),
          _twoCol(
            left: _staffField(enabled: true),
            right: const SizedBox.shrink(),
          ),
          AppTextAreaFormField(
            name: 'remark',
            label: '备注',
            minHeight: 88,
          ),
        ],
      ),
    );
  }

  Widget _buildEditBody(SrmPurchaseOrder d) {
    return AppFieldScope.horizontal(
      labelWidth: _kPoLabelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          _twoCol(
            left: AppTextFormField(
              name: 'orderNo',
              label: '订单号',
              enabled: false,
              initialValue: d.orderNo,
            ),
            right: AppTextFormField(
              name: 'orderName',
              label: '订单名称',
              required: true,
              initialValue: d.orderName,
              validator: AppValidators.required(message: '请输入订单名称'),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'orderTag',
              label: '订单标签',
              initialValue: d.orderTag,
            ),
            right: AppTextFormField(
              name: 'brandName',
              label: '关联品牌',
              required: true,
              initialValue: d.brandName,
              validator: AppValidators.required(message: '请输入关联品牌'),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'supplierFullName',
              label: '供应商全称',
              initialValue: d.supplierFullName,
            ),
            right: AppSelectFormField<String>(
              name: 'contractType',
              label: '合同类型',
              hintText: '请选择',
              clearable: true,
              minWidth: double.infinity,
              options: _kContractTypeOptions,
              initialValue: d.contractType,
            ),
          ),
          _twoCol(
            left: _amountField(
              enabled: true,
              initialText: _amountText(d),
            ),
            right: _PoOrderTimeField(
              initialValue: _parseDate(d.orderTime),
            ),
          ),
          _twoCol(
            left: _PoSettlementField(initialValue: d.settlementMethod),
            right: AppSelectFormField<String>(
              name: 'invoiceType',
              label: '发票类型',
              hintText: '请选择',
              clearable: true,
              minWidth: double.infinity,
              options: _kInvoiceTypeOptions,
              initialValue: d.invoiceType,
            ),
          ),
          _twoCol(
            left: _PoTaxRateField(initialValue: d.taxRate),
            right: AppRegionPickerFormField<String>(
              name: 'city',
              label: '城市',
              clearable: true,
              variant: AppRegionPickerVariant.provinceCity,
              options: _regions,
              width: double.infinity,
              initialValue: _cityPath(d.city),
            ),
          ),
          _twoCol(
            left: AppTextFormField(
              name: 'contactName',
              label: '联系人',
              initialValue: d.contactName,
            ),
            right: _staffField(
              enabled: true,
              initialValue: d.staffName,
            ),
          ),
          AppTextAreaFormField(
            name: 'remark',
            label: '备注',
            minHeight: 88,
            initialValue: d.remark,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;

    return AppForm(
      key: ValueKey('po-form-$_formEpoch'),
      controller: _form,
      child: HyperDialog(
        title: Text(_title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 780),
        onClose: () => widget.onClose(false),
        content: _bootLoading
            ? const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : switch (_mode) {
                _PoFormMode.view when d != null => _buildViewBody(d),
                _PoFormMode.create => _buildCreateBody(),
                _PoFormMode.edit when d != null => _buildEditBody(d),
                _ => const SizedBox.shrink(),
              },
        actions: [
          if (_mode == _PoFormMode.view) ...[
            HyperButton.outlined(
              onPressed: () => widget.onClose(false),
              label: const Text('关闭'),
            ),
            HyperButton.filled(
              onPressed: _bootLoading ? null : _enterEdit,
              label: const Text('编辑'),
            ),
          ] else ...[
            HyperButton.outlined(
              onPressed: _saving ? null : () => widget.onClose(false),
              label: Text(_isCreate ? '取消' : '关闭'),
            ),
            HyperButton.filled(
              onPressed: _bootLoading || _saving
                  ? null
                  : () async {
                      await _submit();
                    },
              label: Text(_saving ? '保存中…' : '保存'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 手填税率超过 100 时，把输入收成 100。
class _CapTaxRateFormatter extends TextInputFormatter {
  const _CapTaxRateFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final n = num.tryParse(text);
    if (n == null || n <= 100) return newValue;
    return const TextEditingValue(
      text: '100',
      selection: TextSelection.collapsed(offset: 3),
    );
  }
}

/// 税率：选「其他」时可手填。
class _PoTaxRateField extends StatefulWidget {
  const _PoTaxRateField({this.initialValue});

  final String? initialValue;

  @override
  State<_PoTaxRateField> createState() => _PoTaxRateFieldState();
}

class _PoTaxRateFieldState extends State<_PoTaxRateField> {
  late String? _selected;
  late String? _custom;

  @override
  void initState() {
    super.initState();
    final rate = widget.initialValue?.trim();
    if (rate == null || rate.isEmpty) {
      _selected = null;
      _custom = null;
    } else if (_kTaxRatePresets.contains(rate) || rate == '其他') {
      _selected = rate;
      _custom = null;
    } else {
      _selected = '其他';
      _custom = rate.endsWith('%') ? rate.substring(0, rate.length - 1) : rate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        AppSelectFormField<String>(
          name: 'taxRate',
          label: '税率',
          hintText: '请选择',
          clearable: true,
          minWidth: double.infinity,
          options: _kTaxRateOptions,
          initialValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),
        if (_selected == '其他')
          AppTextFormField(
            name: 'taxRateCustom',
            // 空标签占位，与同列其它输入框左缘对齐
            label: '',
            hintText: '请输入税率',
            initialValue: _custom,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              const _CapTaxRateFormatter(),
            ],
            trailing: const Text(
              '%',
              style: TextStyle(fontSize: 13, color: _kMuted),
            ),
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return '请输入税率';
              final n = num.tryParse(text);
              if (n == null || n < 0) return '请输入税率';
              return null;
            },
          ),
      ],
    );
  }
}

class _PoSettlementField extends StatelessWidget {
  const _PoSettlementField({this.initialValue});

  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final raw = initialValue?.trim();
    final known = _kSettlementOptions.any((o) => o.value == raw);
    final options = [
      if (raw != null && raw.isNotEmpty && !known)
        AppOption(value: raw, label: raw),
      ..._kSettlementOptions,
    ];
    return AppSelectFormField<String>(
      name: 'settlementMethod',
      label: '结算方式',
      hintText: '请选择',
      clearable: true,
      minWidth: double.infinity,
      options: options,
      initialValue: (raw == null || raw.isEmpty) ? null : raw,
    );
  }
}

/// 订单时间：ObjectFormField 带 trailing 会 IntrinsicWidth 收缩，强制拉满与输入框左缘对齐。
class _PoOrderTimeField extends StatelessWidget {
  const _PoOrderTimeField({this.initialValue});

  final DateTime? initialValue;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: initialValue,
      builder: (state) => AppFormFieldBinding<DateTime>(
        name: 'orderTime',
        value: state.value,
        builder: (context, asyncError) => AppField(
          label: '订单时间',
          errorText: state.errorText ?? asyncError,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: AppDatePicker(
              value: state.value,
              hintText: '请选择日期',
              // popover 在 HyperDialog 内无法点「确定」，改 dialog
              mode: shad.PromptMode.dialog,
              onChanged: state.didChange,
            ),
          ),
        ),
      ),
    );
  }
}
