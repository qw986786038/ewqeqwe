import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../../models/srm_purchase_order.dart';
import '../../../../services/srm_purchase_order_api.dart';
import '../../../../utils/china_regions.dart';
import 'select_counterpart_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBarrier = Color(0x99000000);

const _kContractTypeOptions = [
  AppOption(value: '设备采购', label: '设备采购'),
  AppOption(value: '媒介采购', label: '媒介采购'),
  AppOption(value: '物业租赁', label: '物业租赁'),
  AppOption(value: '维保运维', label: '维保运维'),
  AppOption(value: '技术服务', label: '技术服务'),
  AppOption(value: '其它', label: '其它'),
];

const _kSettlementOptions = [
  AppOption(value: '项目结算', label: '项目结算'),
  AppOption(value: '月结', label: '月结'),
  AppOption(value: '30天', label: '30天'),
  AppOption(value: '60天', label: '60天'),
  AppOption(value: '预付', label: '预付'),
];

const _kInvoiceTypeOptions = [
  AppOption(value: '专用发票', label: '专用发票'),
  AppOption(value: '普通发票', label: '普通发票'),
];

const _kTaxRateOptions = [
  AppOption(value: '1%', label: '1%'),
  AppOption(value: '3%', label: '3%'),
  AppOption(value: '6%', label: '6%'),
  AppOption(value: '9%', label: '9%'),
  AppOption(value: '13%', label: '13%'),
];

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
  return AppDialog.show<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: _kBarrier,
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
            onClose: (ok) => AppOverlay.close<bool>(dialogContext, ok),
          ),
        ),
      );
    },
  ).future.then((v) => v == true);
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
    put('settlementMethod', _asTrimmed(values['settlementMethod']));
    put('invoiceType', _asTrimmed(values['invoiceType']));
    put('taxRate', _asTrimmed(values['taxRate']));
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
      final body = _buildBody(values);
      final name = body['orderName']?.toString().trim() ?? '';
      final brand = body['brandName']?.toString().trim() ?? '';
      if (name.isEmpty || brand.isEmpty) return;

      setState(() => _saving = true);
      try {
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppTextFormField(
            name: 'orderAmount',
            label: '订单金额',
            hintText: enabled ? '单位：万元' : null,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            initialValue: initialText,
          ),
        ),
        const SizedBox(width: 8),
        const Text('万元', style: TextStyle(fontSize: 12, color: _kMuted)),
      ],
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
    return AppInkWell(
      onPressed: _pickStaff,
      child: AbsorbPointer(child: field),
    );
  }

  /// 详情只读：灰底输入框展示，布局对齐截图（左订单号…联系人 / 右订单名称…对接人）。
  Widget _buildViewBody(SrmPurchaseOrder d) {
    return AppFieldScope.horizontal(
      labelWidth: 88,
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
      labelWidth: 88,
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
              options: _kContractTypeOptions,
            ),
            right: _amountField(enabled: true),
          ),
          _twoCol(
            left: AppDatePickerFormField(
              name: 'orderTime',
              label: '订单时间',
              hintText: '请选择日期',
            ),
            right: const AppSelectFormField<String>(
              name: 'settlementMethod',
              label: '结算方式',
              hintText: '请选择',
              clearable: true,
              options: _kSettlementOptions,
            ),
          ),
          _twoCol(
            left: const AppSelectFormField<String>(
              name: 'invoiceType',
              label: '发票类型',
              hintText: '请选择',
              clearable: true,
              options: _kInvoiceTypeOptions,
            ),
            right: const AppSelectFormField<String>(
              name: 'taxRate',
              label: '税率',
              hintText: '请选择',
              clearable: true,
              options: _kTaxRateOptions,
            ),
          ),
          _twoCol(
            left: AppRegionPickerFormField<String>(
              name: 'city',
              label: '城市',
              clearable: true,
              variant: AppRegionPickerVariant.provinceCity,
              options: _regions,
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
      labelWidth: 88,
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
              options: _kContractTypeOptions,
              initialValue: d.contractType,
            ),
          ),
          _twoCol(
            left: _amountField(
              enabled: true,
              initialText: _amountText(d),
            ),
            right: AppDatePickerFormField(
              name: 'orderTime',
              label: '订单时间',
              hintText: '请选择日期',
              initialValue: _parseDate(d.orderTime),
            ),
          ),
          _twoCol(
            left: AppSelectFormField<String>(
              name: 'settlementMethod',
              label: '结算方式',
              hintText: '请选择',
              clearable: true,
              options: _kSettlementOptions,
              initialValue: d.settlementMethod,
            ),
            right: AppSelectFormField<String>(
              name: 'invoiceType',
              label: '发票类型',
              hintText: '请选择',
              clearable: true,
              options: _kInvoiceTypeOptions,
              initialValue: d.invoiceType,
            ),
          ),
          _twoCol(
            left: AppSelectFormField<String>(
              name: 'taxRate',
              label: '税率',
              hintText: '请选择',
              clearable: true,
              options: _kTaxRateOptions,
              initialValue: d.taxRate,
            ),
            right: AppRegionPickerFormField<String>(
              name: 'city',
              label: '城市',
              clearable: true,
              variant: AppRegionPickerVariant.provinceCity,
              options: _regions,
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
      child: AppFormDialog(
        title: Text(_title),
        constraints: const BoxConstraints(minWidth: 720, maxWidth: 780),
        content: _bootLoading
            ? const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : SingleChildScrollView(
                child: switch (_mode) {
                  _PoFormMode.view when d != null => _buildViewBody(d),
                  _PoFormMode.create => _buildCreateBody(),
                  _PoFormMode.edit when d != null => _buildEditBody(d),
                  _ => const SizedBox.shrink(),
                },
              ),
        actions: [
          if (_mode == _PoFormMode.view) ...[
            AppButton.outline(
              onPressed: () => widget.onClose(false),
              child: const Text('关闭'),
            ),
            AppButton.primary(
              onPressed: _bootLoading ? null : _enterEdit,
              child: const Text('编辑'),
            ),
          ] else ...[
            AppButton.outline(
              onPressed: _saving ? null : () => widget.onClose(false),
              child: Text(_isCreate ? '取消' : '关闭'),
            ),
            AppButton.primary(
              loading: _saving,
              loadingLabel: '保存中…',
              onPressed: _bootLoading || _saving
                  ? null
                  : () async {
                      await _submit();
                    },
              child: const Text('保存'),
            ),
          ],
        ],
      ),
    );
  }
}
