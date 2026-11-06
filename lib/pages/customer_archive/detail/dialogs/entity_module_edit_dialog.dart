import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../services/customer_api.dart';
import '../customer_entity_detail_controller.dart';
import 'entity_tax_edit_dialog.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kTitle = Color(0xFF1D2129);

enum EntityEditModule { overview, basic, tax, contacts }

/// 各模块「编辑」：弹窗内仅展示该模块字段。
Future<void> showEntityModuleEditDialog(
  BuildContext context, {
  required CustomerEntityDetailController controller,
  required EntityEditModule module,
}) {
  if (module == EntityEditModule.tax) {
    return showEntityTaxEditDialog(context, controller: controller);
  }
  final title = switch (module) {
    EntityEditModule.overview => '编辑主体概览',
    EntityEditModule.basic => '编辑基本信息',
    EntityEditModule.tax => '编辑银税信息',
    EntityEditModule.contacts => '编辑联系人信息',
  };
  final hostContext = context;
  return showHyperDialog<void>(
    context: context,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _EntityModuleEditDialog(
        controller: controller,
        module: module,
        title: title,
        onClose: () => Navigator.of(dialogContext).pop(),
        hostContext: hostContext,
      ),
    ),
  );
}

class _EntityModuleEditDialog extends StatefulWidget {
  const _EntityModuleEditDialog({
    required this.controller,
    required this.module,
    required this.title,
    required this.onClose,
    required this.hostContext,
  });

  final CustomerEntityDetailController controller;
  final EntityEditModule module;
  final String title;
  final VoidCallback onClose;
  final BuildContext hostContext;

  @override
  State<_EntityModuleEditDialog> createState() =>
      _EntityModuleEditDialogState();
}

class _EntityModuleEditDialogState extends State<_EntityModuleEditDialog> {
  final _form = AppFormController();
  final _api = CustomerApi();
  var _saving = false;

  CustomerEntityDetailController get _c => widget.controller;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ok = await _form.submit((values) async {
        final raw = Map<String, dynamic>.from(_c.raw.value ?? {});
        final ent = Map<String, dynamic>.from(_c.enterprise.value ?? {});
        switch (widget.module) {
          case EntityEditModule.overview:
            _patchOverview(raw, ent, values);
          case EntityEditModule.basic:
            _patchBasic(ent, values);
          case EntityEditModule.tax:
            _patchTax(ent, values);
          case EntityEditModule.contacts:
            // 联系人结构复杂，本弹窗仅改备注类占位；行内编辑走完整档案。
            break;
        }
        _replaceEnterprise(raw, ent);
        raw['id'] = _c.customerId;
        await _api.updateCustomer(raw);
      });
      if (!ok || !mounted) return;
      widget.onClose();
      await _c.load();
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

  void _patchOverview(
    Map<String, dynamic> raw,
    Map<String, dynamic> ent,
    Map<String, dynamic> values,
  ) {
    void putRaw(String key, dynamic v) {
      final s = v?.toString().trim();
      if (s != null) raw[key] = s.isEmpty ? null : s;
    }

    void putEnt(String key, dynamic v) {
      final s = v?.toString().trim();
      if (s != null) ent[key] = s.isEmpty ? null : s;
    }

    putRaw('name', values['name']);
    putRaw('website', values['website']);
    putRaw('industry', values['industry']);
    putRaw('staffScale', values['staffScale']);
    final weight = values['weight']?.toString().trim();
    if (weight != null && weight.isNotEmpty) {
      raw['weight'] = int.tryParse(weight) ?? raw['weight'];
    }
    final sub = values['subBrands']?.toString().trim();
    if (sub != null) {
      raw['subBrands'] = sub.isEmpty
          ? <String>[]
          : sub
              .split(RegExp(r'[;；,，]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    }
    putEnt('fullName', values['fullName']);
    putEnt('shortName', values['shortName']);
    putEnt('relationType', values['relationType']);
    putEnt('entityNature', values['entityNature']);
    putEnt('city', values['city']);
    putEnt('address', values['address']);
  }

  void _patchBasic(Map<String, dynamic> ent, Map<String, dynamic> values) {
    void put(String key, dynamic v) {
      final s = v?.toString().trim();
      if (s != null) ent[key] = s.isEmpty ? null : s;
    }

    put('creditCode', values['creditCode']);
    put('legalPerson', values['legalPerson']);
    put('registeredCapital', values['registeredCapital']);
    put('establishDate', values['establishDate']);
    put('licenseValidPeriod', values['licenseValidPeriod']);
    put('entityNature', values['entityNature']);
    put('regAddress', values['regAddress']);
    put('businessScope', values['businessScope']);
    put('abnormalRecord', values['abnormalRecord']);
    put('penaltyHistory', values['penaltyHistory']);
    put('remark', values['remark']);
  }

  void _patchTax(Map<String, dynamic> ent, Map<String, dynamic> values) {
    void put(String key, dynamic v) {
      final s = v?.toString().trim();
      if (s != null) ent[key] = s.isEmpty ? null : s;
    }

    put('bankName', values['bankName']);
    put('bankAccount', values['bankAccount']);
    put('invoiceName', values['invoiceName']);
    put('taxNo', values['taxNo']);
    put('invoiceRegAddress', values['invoiceRegAddress']);
    put('invoiceRegPhone', values['invoiceRegPhone']);
    put('invoiceBank', values['invoiceBank']);
    put('invoiceBankAccount', values['invoiceBankAccount']);

    final entry = <String, dynamic>{
      'bankName': ent['bankName'],
      'bankAccount': ent['bankAccount'],
      'invoiceName': ent['invoiceName'],
      'taxNo': ent['taxNo'],
      'invoiceRegAddress': ent['invoiceRegAddress'],
      'invoiceRegPhone': ent['invoiceRegPhone'],
      'invoiceBank': ent['invoiceBank'],
      'invoiceBankAccount': ent['invoiceBankAccount'],
    };
    final list = ent['taxList'];
    if (list is List && list.isNotEmpty) {
      final next = [
        for (var i = 0; i < list.length; i++)
          if (i == 0) entry else list[i],
      ];
      ent['taxList'] = next;
    } else {
      ent['taxList'] = [entry];
    }
  }

  void _replaceEnterprise(
    Map<String, dynamic> raw,
    Map<String, dynamic> ent,
  ) {
    final id = ent['id']?.toString();
    final name = ent['fullName']?.toString();
    final list = raw['enterprises'];
    if (list is! List) {
      raw['enterprises'] = [ent];
      return;
    }
    raw['enterprises'] = [
      for (final e in list)
        if (e is Map &&
            ((id != null && e['id']?.toString() == id) ||
                (name != null && e['fullName']?.toString() == name)))
          ent
        else
          e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 为标题/按钮/内边距预留高度，避免 AppFormDialog 外层 Column 底部溢出。
    final viewH = MediaQuery.sizeOf(context).height;
    final contentH = (viewH * 0.9 - 220).clamp(200.0, 520.0);
    return AppForm(
      controller: _form,
      child: HyperDialog(
        title: Text(widget.title),
        scrollable: true,
        style: const HyperDialogStyle(maxWidth: 560),
        onClose: widget.onClose,
        actions: [
          HyperButton.outlined(
            onPressed: _saving ? null : widget.onClose,
            label: const Text('取消'),
          ),
          HyperButton.filled(
            onPressed: _saving ? null : _submit,
            label: Text(_saving ? '保存中…' : '保存'),
          ),
        ],
        content: SizedBox(
          height: contentH,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: AppFieldScope.horizontal(
              labelWidth: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: _fields(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _fields() {
    switch (widget.module) {
      case EntityEditModule.overview:
        return [
          AppTextFormField(
            name: 'name',
            label: '品牌简称',
            initialValue: _c.brandName == '-' ? '' : _c.brandName,
          ),
          AppTextFormField(
            name: 'weight',
            label: '权重',
            initialValue: '${_c.weight}',
          ),
          AppTextFormField(
            name: 'subBrands',
            label: '关联品牌',
            initialValue:
                _c.subBrandsText == '-' ? '' : _c.subBrandsText,
          ),
          AppTextFormField(
            name: 'relationType',
            label: '关联关系',
            initialValue: _c.entityRelationLabel == '-'
                ? ''
                : _c.entityRelationLabel,
          ),
          AppTextFormField(
            name: 'fullName',
            label: '企业全称',
            initialValue:
                _c.entityFullName == '-' ? '' : _c.entityFullName,
          ),
          AppTextFormField(
            name: 'shortName',
            label: '企业简称',
            initialValue:
                _c.entityShortName == '-' ? '' : _c.entityShortName,
          ),
          AppTextFormField(
            name: 'industry',
            label: '所属行业',
            initialValue:
                _c.industryLabel == '-' ? '' : _c.industryLabel,
          ),
          AppTextFormField(
            name: 'entityNature',
            label: '企业性质',
            initialValue: _c.entityNatureLabel == '-'
                ? ''
                : _c.entityNatureLabel,
          ),
          AppTextFormField(
            name: 'staffScale',
            label: '人员规模/人',
            initialValue: _c.staffScale == '-' ? '' : _c.staffScale,
          ),
          AppTextFormField(
            name: 'city',
            label: '所在城市',
            initialValue: _c.cityText == '-' ? '' : _c.cityText,
          ),
          AppTextFormField(
            name: 'address',
            label: '详细地址',
            initialValue: _c.address == '-' ? '' : _c.address,
          ),
          AppTextFormField(
            name: 'website',
            label: '官网',
            initialValue: _c.website == '-' ? '' : _c.website,
          ),
        ];
      case EntityEditModule.basic:
        return [
          AppTextFormField(
            name: 'creditCode',
            label: '统一社会信用代码',
            initialValue: _c.creditCode == '-' ? '' : _c.creditCode,
          ),
          AppTextFormField(
            name: 'legalPerson',
            label: '法定代表人',
            initialValue: _c.legalPerson == '-' ? '' : _c.legalPerson,
          ),
          AppTextFormField(
            name: 'registeredCapital',
            label: '注册资金',
            initialValue: _c.regCapital == '-' ? '' : _c.regCapital,
          ),
          AppTextFormField(
            name: 'establishDate',
            label: '成立日期',
            initialValue:
                _c.establishDate == '-' ? '' : _c.establishDate,
          ),
          AppTextFormField(
            name: 'licenseValidPeriod',
            label: '营业执照有效期',
            initialValue:
                _c.licenseExpire == '-' ? '' : _c.licenseExpire,
          ),
          AppTextFormField(
            name: 'entityNature',
            label: '企业性质',
            initialValue: _c.entityNatureLabel == '-'
                ? ''
                : _c.entityNatureLabel,
          ),
          AppTextFormField(
            name: 'regAddress',
            label: '注册地址',
            initialValue: _c.regAddress == '-' ? '' : _c.regAddress,
          ),
          AppTextAreaFormField(
            name: 'businessScope',
            label: '经营范围',
            initialValue:
                _c.businessScope == '-' ? '' : _c.businessScope,
          ),
          AppTextFormField(
            name: 'abnormalRecord',
            label: '经营异常记录',
            initialValue:
                _c.abnormalRecord == '-' ? '' : _c.abnormalRecord,
          ),
          AppTextFormField(
            name: 'penaltyHistory',
            label: '行政处罚历史',
            initialValue:
                _c.penaltyHistory == '-' ? '' : _c.penaltyHistory,
          ),
          AppTextFormField(
            name: 'remark',
            label: '备注',
            initialValue: _c.remark == '-' ? '' : _c.remark,
          ),
        ];
      case EntityEditModule.tax:
        return [
          const Text(
            '银行账户信息 1',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          AppTextFormField(
            name: 'bankName',
            label: '开户行',
            initialValue: _c.bankName == '-' ? '' : _c.bankName,
          ),
          AppTextFormField(
            name: 'bankAccount',
            label: '银行账号',
            initialValue: _c.bankAccount == '-' ? '' : _c.bankAccount,
          ),
          const Text(
            '开票信息 1',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          AppTextFormField(
            name: 'invoiceName',
            label: '名称',
            initialValue: _c.invoiceName == '-' ? '' : _c.invoiceName,
          ),
          AppTextFormField(
            name: 'taxNo',
            label: '税号',
            initialValue: _c.taxNo == '-' ? '' : _c.taxNo,
          ),
          AppTextFormField(
            name: 'invoiceRegAddress',
            label: '注册地址',
            initialValue:
                _c.invoiceAddress == '-' ? '' : _c.invoiceAddress,
          ),
          AppTextFormField(
            name: 'invoiceRegPhone',
            label: '注册电话',
            initialValue: _c.invoicePhone == '-' ? '' : _c.invoicePhone,
          ),
          AppTextFormField(
            name: 'invoiceBank',
            label: '开户银行',
            initialValue: _c.invoiceBank == '-' ? '' : _c.invoiceBank,
          ),
          AppTextFormField(
            name: 'invoiceBankAccount',
            label: '开户银行账号',
            initialValue:
                _c.invoiceAccount == '-' ? '' : _c.invoiceAccount,
          ),
        ];
      case EntityEditModule.contacts:
        return [
          const Text(
            '联系人请在列表中点击「编辑」修改单条；此处保存将刷新详情。',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
        ];
    }
  }
}
