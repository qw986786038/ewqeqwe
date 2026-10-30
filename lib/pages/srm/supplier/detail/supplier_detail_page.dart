import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../../models/srm_supplier.dart';
import '../edit/supplier_edit_page.dart';
import 'supplier_detail_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF4E5969);
const _kGold = Color(0xFFFAAD14);
const _kDanger = Color(0xFFFF4D4F);
const _kTagBg = Color(0xFFE6F4FF);
const _kCardPad = Color(0xFFF7F8FA);

/// 供应商详情（主表 + 子表）。从列表「查看」进入。
class SupplierDetailPage extends StatelessWidget {
  const SupplierDetailPage({super.key, required this.supplierId});

  final String supplierId;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<SupplierDetailController>(
          () => SupplierDetailController(supplierId: supplierId),
        );
      },
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  SupplierDetailController _c(BuildContext context) =>
      context.lx.find<SupplierDetailController>();

  Future<void> _openEdit(BuildContext context) async {
    final c = _c(context);
    final id = c.supplierId.trim();
    if (id.isEmpty) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SupplierEditPage(supplierId: id),
      ),
    );
    if (ok == true && context.mounted) {
      await c.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Obx(() {
        if (c.loading.value && c.detail.value == null) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final err = c.errorMessage.value;
        if (err != null && c.detail.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: _kDanger)),
                const SizedBox(height: 12),
                AppButton.outline(onPressed: c.load, child: const Text('重试')),
              ],
            ),
          );
        }
        final d = c.detail.value!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  const Text(
                    '当前位置 / 供应商管理 / 供应商列表 / 供应商详情',
                    style: TextStyle(fontSize: 13, color: _kLabel),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '供应商详情',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '点击某一卡片「编辑」后仅该卡片可改，其他卡片不可编辑',
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                  const SizedBox(height: 14),
                  _OverviewCard(
                    detail: d,
                    onEdit: () => _openEdit(context),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BasicInfoCard(
                          detail: d,
                          onEdit: () => _openEdit(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TaxInfoCard(
                          detail: d,
                          onEditBank: () => _openEdit(context),
                          onEditInvoice: () => _openEdit(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ContractCard(
                          detail: d,
                          onEdit: () => _openEdit(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CapabilityCard(
                          detail: d,
                          onEdit: () => _openEdit(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PurchaseOrderCard(
                    onRemove: () => AppToast.show(
                      context: context,
                      title: '移除待接入',
                    ),
                    onAdd: () => AppToast.show(
                      context: context,
                      title: '添加待接入',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '点击卡片「编辑」后仅该卡片可改，其他卡片锁定',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ),
                  AppButton.primary(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('返回'),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── 卡片壳 ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.onEdit,
    this.headerTrailing,
  });

  final String title;
  final Widget child;
  final VoidCallback? onEdit;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              ?headerTrailing,
              if (onEdit != null)
                AppButton.link(
                  onPressed: onEdit,
                  child: const Text('编辑'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.label, this.value, {this.child});

  final String label;
  final String value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: _kTitle),
                ),
          ),
        ],
      ),
    );
  }
}

class _KVGrid extends StatelessWidget {
  const _KVGrid({required this.items, this.columns = 2});

  final List<(String, String, Widget?)> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16.0;
        final colW = columns <= 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 0,
          children: [
            for (final (label, value, child) in items)
              SizedBox(
                width: colW,
                child: _KV(label, value, child: child),
              ),
          ],
        );
      },
    );
  }
}

String _dash(String? v) {
  final s = v?.trim();
  if (s == null || s.isEmpty) return '—';
  return s;
}

String _licenseRange(SrmSupplier d) {
  final a = d.licenseValidStart?.trim() ?? '';
  final b = d.licenseValidEnd?.trim() ?? '';
  if (a.isEmpty && b.isEmpty) return '—';
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a ~ $b';
}

String _capital(num? v) {
  if (v == null) return '—';
  return v.toStringAsFixed(4);
}

// ── 供应商概览 ───────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.detail, required this.onEdit});

  final SrmSupplier detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = detail.shortName?.trim().isNotEmpty == true
        ? detail.shortName!.trim()
        : (detail.fullName?.trim() ?? '');
    final letter = name.isEmpty
        ? '?'
        : String.fromCharCodes(name.runes.take(1));
    final logo = detail.logoFile?.trim() ?? '';
    final contacts = detail.contactList;
    final staffs = detail.staffList;
    final category = _dash(
      detail.supplyCategoryText ?? detail.categoryExportText,
    );

    return _SectionCard(
      title: '供应商概览',
      onEdit: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: logo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          logo,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KVGrid(
                  columns: 3,
                  items: [
                    ('供应商简称', _dash(detail.shortName), null),
                    (
                      '权重星级',
                      '',
                      _Stars(weight: detail.weight ?? 0),
                    ),
                    ('创建时间', _dash(detail.createTime), null),
                    ('供应商全称', _dash(detail.fullName), null),
                    (
                      '所在城市',
                      _dash(
                        detail.city ?? detail.regionName,
                      ),
                      null,
                    ),
                    ('详细地址', _dash(detail.businessAddress), null),
                    ('供应商类型', _dash(detail.supplierType), null),
                    ('供应品类', category, null),
                    (
                      '联系人',
                      '',
                      _PersonTags(
                        labels: contacts.isEmpty
                            ? [
                                if ((detail.contactInfoText ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  detail.contactInfoText!.trim(),
                              ]
                            : [
                                for (final c in contacts)
                                  if ((c.name ?? '').trim().isNotEmpty)
                                    c.name!.trim(),
                              ],
                        tipBuilder: (i) {
                          if (i < 0 || i >= contacts.length) return null;
                          final c = contacts[i];
                          final parts = <String>[
                            if ((c.mobile ?? '').trim().isNotEmpty)
                              c.mobile!.trim(),
                            if ((c.email ?? '').trim().isNotEmpty)
                              c.email!.trim(),
                            if ((c.deptPost ?? '').trim().isNotEmpty)
                              c.deptPost!.trim(),
                          ];
                          return parts.isEmpty ? null : parts.join(' · ');
                        },
                      ),
                    ),
                    (
                      '我方对接人',
                      '',
                      _PersonTags(
                        labels: staffs.isEmpty
                            ? [
                                if ((detail.staffInfoText ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  detail.staffInfoText!.trim(),
                              ]
                            : [
                                for (final s in staffs)
                                  if ((s.name ?? '').trim().isNotEmpty)
                                    [
                                      if ((s.deptPost ?? '').trim().isNotEmpty)
                                        s.deptPost!.trim(),
                                      s.name!.trim(),
                                    ].join(' - '),
                              ],
                      ),
                    ),
                    ('官网', _dash(detail.website), null),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '提示：鼠标悬停在人员姓名上可查看联系方式',
            style: TextStyle(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.weight});

  final int weight;

  @override
  Widget build(BuildContext context) {
    final n = weight.clamp(0, 5);
    if (n <= 0) {
      return const Text('—', style: TextStyle(fontSize: 13, color: _kTitle));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          const Icon(Icons.star, size: 16, color: _kGold),
      ],
    );
  }
}

class _PersonTags extends StatelessWidget {
  const _PersonTags({required this.labels, this.tipBuilder});

  final List<String> labels;
  final String? Function(int index)? tipBuilder;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 13, color: _kTitle));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < labels.length; i++)
          Tooltip(
            message: tipBuilder?.call(i) ?? labels[i],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kTagBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                labels[i],
                style: const TextStyle(fontSize: 12, color: _kPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 基本信息 ─────────────────────────────────────────────────────────────────

class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({required this.detail, required this.onEdit});

  final SrmSupplier detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '基本信息',
      onEdit: onEdit,
      child: Column(
        children: [
          _KV('统一社会信用代码', _dash(detail.creditCode)),
          _KV('法定代表人', _dash(detail.legalPerson)),
          _KV('注册资金（万元）', _capital(detail.registeredCapital)),
          _KV('成立日期', _dash(detail.establishDate)),
          _KV('营业执照有效期', _licenseRange(detail)),
          _KV('企业性质', _dash(detail.enterpriseNature)),
          _KV('注册地址', _dash(detail.registeredAddress)),
          _KV('经营范围', _dash(detail.businessScope)),
          _KV('经营异常记录', _dash(detail.abnormalRecord)),
          _KV('行政处罚记录', _dash(detail.penaltyHistory)),
          _KV('备注', _dash(detail.remark)),
        ],
      ),
    );
  }
}

// ── 银税信息 ─────────────────────────────────────────────────────────────────

class _TaxInfoCard extends StatelessWidget {
  const _TaxInfoCard({
    required this.detail,
    required this.onEditBank,
    required this.onEditInvoice,
  });

  final SrmSupplier detail;
  final VoidCallback onEditBank;
  final VoidCallback onEditInvoice;

  @override
  Widget build(BuildContext context) {
    final banks = detail.bankList;
    final invoices = detail.invoiceList;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '银税信息',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '银行账户信息',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppButton.link(onPressed: onEditBank, child: const Text('编辑')),
            ],
          ),
          const SizedBox(height: 8),
          if (banks.isEmpty)
            const _KV('开户银行', '—')
          else
            for (final b in banks) ...[
              _KV('开户银行', _dash(b.bankName)),
              _KV('银行账号', _dash(b.bankAccount)),
            ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                '开票信息',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTitle,
                ),
              ),
              const Spacer(),
              AppButton.link(onPressed: onEditInvoice, child: const Text('编辑')),
            ],
          ),
          const SizedBox(height: 8),
          if (invoices.isEmpty) ...[
            const _KV('名称', '—'),
            const _KV('税号', '—'),
            const _KV('注册地址', '—'),
            const _KV('注册电话', '—'),
            const _KV('开户银行', '—'),
            const _KV('开户银行账号', '—'),
          ] else
            for (final inv in invoices) ...[
              _KV('名称', _dash(inv.invoiceName)),
              _KV('税号', _dash(inv.taxNo)),
              _KV('注册地址', _dash(inv.registerAddress)),
              _KV('注册电话', _dash(inv.registerPhone)),
              _KV('开户银行', _dash(inv.bankName)),
              _KV('开户银行账号', _dash(inv.bankAccount)),
            ],
        ],
      ),
    );
  }
}

// ── 合同与结算 ───────────────────────────────────────────────────────────────

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.detail, required this.onEdit});

  final SrmSupplier detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '合同与结算',
      onEdit: onEdit,
      child: _KVGrid(
        columns: 2,
        items: [
          ('合作模式', _dash(detail.cooperationMode), null),
          ('结算方式', _dash(detail.settlementMethod), null),
          (
            '账期(天)',
            detail.paymentTermDays == null ? '—' : '${detail.paymentTermDays}',
            null,
          ),
          ('付款条件', _dash(detail.paymentCondition), null),
          ('返点政策', _dash(detail.rebatePolicy), null),
          ('合同模板', _dash(detail.contractTemplate), null),
        ],
      ),
    );
  }
}

// ── 能力与品类 ───────────────────────────────────────────────────────────────

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.detail, required this.onEdit});

  final SrmSupplier detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cats = detail.categoryList;
    return _SectionCard(
      title: '能力与品类',
      onEdit: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '供应品类明细',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 8),
          if (cats.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kCardPad,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: const Text(
                '暂无品类明细',
                style: TextStyle(fontSize: 13, color: _kMuted),
              ),
            )
          else
            for (var i = 0; i < cats.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                decoration: BoxDecoration(
                  color: _kCardPad,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    _KV('供应品类', _dash(cats[i].supplyCategory)),
                    _KV('类型', _dash(cats[i].itemType)),
                    _KV('描述', _dash(cats[i].itemDesc)),
                  ],
                ),
              ),
            ],
          const SizedBox(height: 12),
          _KV('服务区域', _dash(detail.serviceArea)),
          _KV('交付能力', _dash(detail.deliveryCapacity)),
          _KV('核心优势', _dash(detail.coreAdvantage)),
          _KV(
            '团队规模',
            detail.teamSize == null ? '—' : '${detail.teamSize}',
          ),
          _KV(
            '开票类型',
            _dash(detail.invoiceTypeText ?? detail.invoiceType),
          ),
          _KV(
            '开票税率',
            _dash(detail.taxRateText ?? detail.taxRate),
          ),
        ],
      ),
    );
  }
}

// ── 采购订单明细（接口未提供，先占位复刻布局）────────────────────────────────

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({required this.onRemove, required this.onAdd});

  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '采购订单明细',
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.link(
            onPressed: onRemove,
            child: const Text('移除', style: TextStyle(color: _kDanger)),
          ),
          AppButton.link(onPressed: onAdd, child: const Text('添加')),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kBorder),
            ),
            child: const Row(
              children: [
                SizedBox(width: 28),
                Expanded(flex: 3, child: Text('订单名称 / 订单号', style: _headStyle)),
                Expanded(flex: 2, child: Text('订单标签', style: _headStyle)),
                Expanded(flex: 2, child: Text('关联品牌', style: _headStyle)),
                Expanded(flex: 2, child: Text('合同类型', style: _headStyle)),
                Expanded(flex: 2, child: Text('订单金额(万元)', style: _headStyle)),
                Expanded(flex: 2, child: Text('订单时间', style: _headStyle)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text(
              '暂无采购订单',
              style: TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
        ],
      ),
    );
  }
}

const _headStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: _kLabel,
);
