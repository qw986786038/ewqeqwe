import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../services/customer_api.dart';
import '../customer_entity_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kTitle = Color(0xFF1D2129);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFFF4D4F);

/// 编辑银税信息：多组「银行账户 + 开票」列表，支持 +添加 / 删除。
Future<void> showEntityTaxEditDialog(
  BuildContext context, {
  required CustomerEntityDetailController controller,
  bool appendEmpty = false,
}) {
  final hostContext = context;
  return showHyperDialog<void>(
    context: context,
    builder: (dialogContext) => AppShadcnScope(
      config: AppThemeConfig.standard(primary: _kPrimary),
      child: _EntityTaxEditDialog(
        controller: controller,
        appendEmpty: appendEmpty,
        onClose: () => Navigator.of(dialogContext).pop(),
        hostContext: hostContext,
      ),
    ),
  );
}

class _TaxDraft {
  _TaxDraft({
    String bankName = '',
    String bankAccount = '',
    String invoiceName = '',
    String taxNo = '',
    String invoiceRegAddress = '',
    String invoiceRegPhone = '',
    String invoiceBank = '',
    String invoiceBankAccount = '',
  })  : bankName = TextEditingController(text: bankName),
        bankAccount = TextEditingController(text: bankAccount),
        invoiceName = TextEditingController(text: invoiceName),
        taxNo = TextEditingController(text: taxNo),
        invoiceRegAddress = TextEditingController(text: invoiceRegAddress),
        invoiceRegPhone = TextEditingController(text: invoiceRegPhone),
        invoiceBank = TextEditingController(text: invoiceBank),
        invoiceBankAccount = TextEditingController(text: invoiceBankAccount);

  factory _TaxDraft.fromMap(Map<String, dynamic> m) {
    String s(dynamic v) => v?.toString().trim() ?? '';
    return _TaxDraft(
      bankName: s(m['bankName']),
      bankAccount: s(m['bankAccount']),
      invoiceName: s(m['invoiceName']),
      taxNo: s(m['taxNo']),
      invoiceRegAddress: s(m['invoiceRegAddress'] ?? m['invoiceAddress']),
      invoiceRegPhone: s(m['invoiceRegPhone'] ?? m['invoicePhone']),
      invoiceBank: s(m['invoiceBank']),
      invoiceBankAccount:
          s(m['invoiceBankAccount'] ?? m['invoiceAccount']),
    );
  }

  final TextEditingController bankName;
  final TextEditingController bankAccount;
  final TextEditingController invoiceName;
  final TextEditingController taxNo;
  final TextEditingController invoiceRegAddress;
  final TextEditingController invoiceRegPhone;
  final TextEditingController invoiceBank;
  final TextEditingController invoiceBankAccount;

  Map<String, dynamic> toMap() {
    String? t(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    return {
      'bankName': t(bankName),
      'bankAccount': t(bankAccount),
      'invoiceName': t(invoiceName),
      'taxNo': t(taxNo),
      'invoiceRegAddress': t(invoiceRegAddress),
      'invoiceRegPhone': t(invoiceRegPhone),
      'invoiceBank': t(invoiceBank),
      'invoiceBankAccount': t(invoiceBankAccount),
    };
  }

  void dispose() {
    bankName.dispose();
    bankAccount.dispose();
    invoiceName.dispose();
    taxNo.dispose();
    invoiceRegAddress.dispose();
    invoiceRegPhone.dispose();
    invoiceBank.dispose();
    invoiceBankAccount.dispose();
  }
}

class _EntityTaxEditDialog extends StatefulWidget {
  const _EntityTaxEditDialog({
    required this.controller,
    required this.appendEmpty,
    required this.onClose,
    required this.hostContext,
  });

  final CustomerEntityDetailController controller;
  final bool appendEmpty;
  final VoidCallback onClose;
  final BuildContext hostContext;

  @override
  State<_EntityTaxEditDialog> createState() => _EntityTaxEditDialogState();
}

class _EntityTaxEditDialogState extends State<_EntityTaxEditDialog> {
  final _api = CustomerApi();
  final _scroll = ScrollController();
  final _entries = <_TaxDraft>[];
  var _saving = false;

  CustomerEntityDetailController get _c => widget.controller;

  bool _isBlank(_TaxDraft d) =>
      d.bankName.text.trim().isEmpty &&
      d.bankAccount.text.trim().isEmpty &&
      d.invoiceName.text.trim().isEmpty &&
      d.taxNo.text.trim().isEmpty &&
      d.invoiceRegAddress.text.trim().isEmpty &&
      d.invoiceRegPhone.text.trim().isEmpty &&
      d.invoiceBank.text.trim().isEmpty &&
      d.invoiceBankAccount.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    final existing = _c.taxEntries;
    if (existing.isEmpty) {
      _entries.add(_TaxDraft());
    } else {
      for (final e in existing) {
        _entries.add(_TaxDraft.fromMap(e));
      }
    }
    // 页面「添加」：在已有列表末尾追加一组空白（对齐网页：已有 1/2 + 空的 3）。
    if (widget.appendEmpty &&
        (_entries.isEmpty || !_isBlank(_entries.last))) {
      _entries.add(_TaxDraft());
    }
    if (widget.appendEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _add() {
    setState(() => _entries.add(_TaxDraft()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _remove(int index) {
    if (_entries.length <= 1) {
      setState(() {
        _entries[index].dispose();
        _entries[index] = _TaxDraft();
      });
      return;
    }
    setState(() {
      _entries.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final raw = Map<String, dynamic>.from(_c.raw.value ?? {});
      final ent = Map<String, dynamic>.from(_c.enterprise.value ?? {});
      final list = [for (final e in _entries) e.toMap()];
      ent['taxList'] = list;
      if (list.isNotEmpty) {
        final first = list.first;
        ent['bankName'] = first['bankName'];
        ent['bankAccount'] = first['bankAccount'];
        ent['invoiceName'] = first['invoiceName'];
        ent['taxNo'] = first['taxNo'];
        ent['invoiceRegAddress'] = first['invoiceRegAddress'];
        ent['invoiceRegPhone'] = first['invoiceRegPhone'];
        ent['invoiceBank'] = first['invoiceBank'];
        ent['invoiceBankAccount'] = first['invoiceBankAccount'];
      }
      _replaceEnterprise(raw, ent);
      raw['id'] = _c.customerId;
      await _api.updateCustomer(raw);
      if (!mounted) return;
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
    final viewH = MediaQuery.sizeOf(context).height;
    final contentH = (viewH * 0.9 - 220).clamp(240.0, 640.0);
    return HyperDialog(
      title: const Text('编辑银税信息'),
      scrollable: false,
      style: const HyperDialogStyle(maxWidth: 720),
      onClose: widget.onClose,
      actions: [
        HyperButton.filled(
          onPressed: _saving ? null : _submit,
          label: Text(_saving ? '保存中…' : '确定'),
        ),
        HyperButton.outlined(
          onPressed: _saving ? null : widget.onClose,
          label: const Text('取消'),
        ),
      ],
      content: SizedBox(
        height: contentH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  '银税信息',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
                const SizedBox(width: 12),
                AppInkWell(
                  onPressed: _add,
                  child: const Text(
                    '+ 添加',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.only(right: 4, bottom: 8),
                itemCount: _entries.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: _DashedDivider(),
                ),
                itemBuilder: (context, index) => _TaxEntryBlock(
                  index: index,
                  draft: _entries[index],
                  onDelete: () => _remove(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 3.0;
        final n = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              const ColoredBox(
                color: _kBorder,
                child: SizedBox(width: dash, height: 1),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TaxEntryBlock extends StatelessWidget {
  const _TaxEntryBlock({
    required this.index,
    required this.draft,
    required this.onDelete,
  });

  final int index;
  final _TaxDraft draft;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final n = index + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '银行账户信息 $n',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppInkWell(
                onPressed: onDelete,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    '删除',
                    style: TextStyle(fontSize: 12, color: _kDanger),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FieldRow(
            left: _CtrlField(
              label: '开户行',
              controller: draft.bankName,
              hintText: '请选择开户行（省/市/支行）',
            ),
            right: _CtrlField(
              label: '银行账号',
              controller: draft.bankAccount,
              hintText: '请输入',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '开票信息 $n',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 14),
          _FieldRow(
            left: _CtrlField(
              label: '名称',
              controller: draft.invoiceName,
              hintText: 'OCR 识别或手填',
            ),
            right: _CtrlField(
              label: '税号',
              controller: draft.taxNo,
              hintText: 'OCR 识别或手填',
            ),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            left: _CtrlField(
              label: '注册地址',
              controller: draft.invoiceRegAddress,
              hintText: 'OCR 识别或手填',
            ),
            right: _CtrlField(
              label: '注册电话',
              controller: draft.invoiceRegPhone,
              hintText: '请输入',
            ),
          ),
          const SizedBox(height: 12),
          _FieldRow(
            left: _CtrlField(
              label: '开户银行',
              controller: draft.invoiceBank,
              hintText: '请选择开户行（省/市/支行）',
            ),
            right: _CtrlField(
              label: '开户银行账号',
              controller: draft.invoiceBankAccount,
              hintText: '请输入',
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 24),
        Expanded(child: right),
      ],
    );
  }
}

class _CtrlField extends StatelessWidget {
  const _CtrlField({
    required this.label,
    required this.controller,
    required this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              controller: controller,
              value: controller.text,
              hintText: hintText,
              density: AppDensity.normal,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}
