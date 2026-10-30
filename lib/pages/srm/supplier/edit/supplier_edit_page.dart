import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_x/lemon_x.dart';
import 'package:pinyin/pinyin.dart';

import '../../../customer_archive/dialogs/select_sales_person_dialog.dart';
import 'cnaps_bank_picker.dart';
import 'supplier_edit_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF4E5969);
const _kDanger = Color(0xFFFF4D4F);

String? _asStr(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString().trim());
}

DateTime? _asDate(Object? v) => v is DateTime ? v : null;

List<String>? _asStrList(Object? v) {
  if (v is! List) return null;
  return [
    for (final e in v)
      if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
  ];
}

shad.DateTimeRange? _asShadRange(Object? v) {
  if (v is shad.DateTimeRange) return v;
  if (v is DateTimeRange) return shad.DateTimeRange(v.start, v.end);
  return null;
}

/// 新建 / 编辑供应商（全页）。
class SupplierEditPage extends StatelessWidget {
  const SupplierEditPage({super.key, this.supplierId});

  /// 非空为编辑。
  final String? supplierId;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<SupplierEditController>(
          () => SupplierEditController(supplierId: supplierId),
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

  SupplierEditController _c(BuildContext context) =>
      context.lx.find<SupplierEditController>();

  Future<void> _onSave(
    BuildContext context, {
    required bool continueAdd,
  }) async {
    final c = _c(context);
    final ok = await c.save(context: context, continueAdd: continueAdd);
    if (ok && !continueAdd && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Obx(() {
        if (c.bootLoading.value) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final err = c.errorMessage.value;
        if (err != null && c.isEdit) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    err,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _kMuted),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton.outline(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          );
        }
        return Column(
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
                    onPressed: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Icon(
                        AppLucideIcons.arrowLeft,
                        size: 18,
                        color: _kLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.isEdit ? '编辑供应商' : '新建供应商',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kTitle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '带 * 为必填；保存后可在详情中继续维护子表与采购订单。',
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                  AppButton.outline(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('取消'),
                  ),
                  if (!c.isEdit) ...[
                    const SizedBox(width: 8),
                    AppButton.outline(
                      onPressed: () => _onSave(context, continueAdd: true),
                      child: const Text('保存并继续新增'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  AppButton.primary(
                    onPressed: () => _onSave(context, continueAdd: false),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final epoch = c.formEpoch.value;
                final regions = c.regionOptions.toList();
                final serviceOpts = [
                  for (final o in regions)
                    AppOption(value: o.value, label: o.label),
                ];
                return AppForm(
                  key: ValueKey('supplier_edit_form_$epoch'),
                  controller: c.form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      _SectionCard(
                        title: '经营主体信息',
                        headerTrailing: Obx(() {
                          final loading = c.ocrLoading.value;
                          return AppButton.primary(
                            onPressed: loading
                                ? null
                                : () => c.runOcr(context),
                            leading: loading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                            child: const Text('营业执照识别'),
                          );
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            _ThreeCol(
                              left: AppTextFormField(
                                name: 'shortName',
                                label: '简称',
                                required: true,
                                hintText: '请输入简称',
                                initialValue: _asStr(c.initialOf('shortName')),
                                validator: AppValidators.required(
                                  message: '不可为空',
                                ),
                              ),
                              mid: AppTextFormField(
                                name: 'fullName',
                                label: '全称',
                                required: true,
                                hintText: '请输入全称',
                                initialValue: _asStr(c.initialOf('fullName')),
                                validator: AppValidators.required(
                                  message: '不可为空',
                                ),
                              ),
                              right: AppMultiSelectFormField<String>(
                                name: 'supplierTypes',
                                label: '供应商类型',
                                required: true,
                                options:
                                    SupplierEditController.supplierTypeOptions,
                                initialValue:
                                    _asStrList(c.initialOf('supplierTypes')),
                                onChanged: c.syncCategoriesFromTypes,
                                validator: (v) =>
                                    v == null || v.isEmpty ? '请选择供应商类型' : null,
                              ),
                            ),
                            AppRegionPickerFormField<String>(
                              name: 'region',
                              label: '所在地区',
                              required: true,
                              options: regions,
                              initialValue:
                                  _asStrList(c.initialOf('region')) ?? const [],
                              validator: (v) =>
                                  v == null || v.isEmpty ? '请选择所在地区' : null,
                            ),
                            _ThreeCol(
                              left: AppTextFormField(
                                name: 'businessAddress',
                                label: '经营地址',
                                hintText: '请输入经营地址',
                                initialValue:
                                    _asStr(c.initialOf('businessAddress')),
                              ),
                              mid: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    '公司 logo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      AppButton.primary(
                                        onPressed: () => c.pickLogo(context),
                                        leading: const Icon(
                                          Icons.upload_outlined,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        child: const Text('上传 Logo'),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Obx(() {
                                          final label = c.logoLabel.value;
                                          return Text(
                                            label?.trim().isNotEmpty == true
                                                ? label!
                                                : '未上传',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: label == null
                                                  ? _kMuted
                                                  : _kTitle,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              right: AppTextFormField(
                                name: 'website',
                                label: '官网',
                                hintText: 'https://',
                                initialValue: _asStr(c.initialOf('website')),
                              ),
                            ),
                            _TwoCol(
                              left: AppTextAreaFormField(
                                name: 'abnormalRecord',
                                label: '经营异常记录',
                                hintText: '选填',
                                minHeight: 72,
                                initialValue:
                                    _asStr(c.initialOf('abnormalRecord')),
                              ),
                              right: AppTextAreaFormField(
                                name: 'penaltyHistory',
                                label: '行政处罚历史',
                                hintText: '选填',
                                minHeight: 72,
                                initialValue:
                                    _asStr(c.initialOf('penaltyHistory')),
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  '黑名单',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _kLabel,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Obx(() {
                                  final on = c.blacklist.value;
                                  return AppToggleGroup<bool>.single(
                                    value: on,
                                    onChanged: (v) {
                                      if (v != null) c.blacklist.value = v;
                                    },
                                    mode: AppWidgetGroupMode.plain,
                                    spacing: 8,
                                    items: const [
                                      AppToggleGroupItem(
                                        value: false,
                                        child: Text('否'),
                                      ),
                                      AppToggleGroupItem(
                                        value: true,
                                        child: Text('是'),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '营业执照信息',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            _ThreeCol(
                              left: AppTextFormField(
                                name: 'creditCode',
                                label: '信用代码',
                                hintText: '统一社会信用代码',
                                initialValue:
                                    _asStr(c.initialOf('creditCode')),
                              ),
                              mid: AppTextFormField(
                                name: 'legalPerson',
                                label: '法人',
                                hintText: '请输入法人',
                                initialValue:
                                    _asStr(c.initialOf('legalPerson')),
                              ),
                              right: AppNumberInputFormField(
                                name: 'registeredCapital',
                                label: '注册资金(万元)',
                                min: 0,
                                max: 99999999,
                                initialValue:
                                    _asInt(c.initialOf('registeredCapital')) ??
                                        0,
                              ),
                            ),
                            _ThreeCol(
                              left: AppDatePickerFormField(
                                name: 'establishDate',
                                label: '成立日期',
                                hintText: '请选择日期',
                                initialValue:
                                    _asDate(c.initialOf('establishDate')),
                              ),
                              mid: AppDateRangePickerFormField(
                                name: 'licenseValid',
                                label: '执照有效期',
                                hintText: '开始日期 - 结束日期',
                                initialValue:
                                    _asShadRange(c.initialOf('licenseValid')),
                              ),
                              right: AppSelectFormField<String>(
                                name: 'enterpriseNature',
                                label: '企业性质',
                                hintText: '请选择',
                                clearable: true,
                                options: SupplierEditController
                                    .enterpriseNatureOptions,
                                initialValue:
                                    _asStr(c.initialOf('enterpriseNature')),
                              ),
                            ),
                            _TwoCol(
                              left: AppTextFormField(
                                name: 'registeredAddress',
                                label: '注册地址',
                                hintText: '请输入注册地址',
                                initialValue:
                                    _asStr(c.initialOf('registeredAddress')),
                              ),
                              right: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    '营业执照附件',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Obx(() {
                                    final label = c.licenseLabel.value;
                                    return Text(
                                      label?.trim().isNotEmpty == true
                                          ? label!
                                          : '暂无，请点击上方营业执照识别上传',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: label == null
                                            ? _kMuted
                                            : _kTitle,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            AppTextAreaFormField(
                              name: 'businessScope',
                              label: '经营范围',
                              hintText: '请输入经营范围',
                              minHeight: 88,
                              initialValue:
                                  _asStr(c.initialOf('businessScope')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '合同与结算',
                        headerTrailing: const Text(
                          '合作模式、结算方式、账期与返点',
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            _ThreeCol(
                              left: AppSelectFormField<String>(
                                name: 'cooperationMode',
                                label: '合作模式',
                                required: true,
                                hintText: '请选择',
                                options: SupplierEditController
                                    .cooperationModeOptions,
                                initialValue:
                                    _asStr(c.initialOf('cooperationMode')),
                                validator: AppValidators.required(
                                  message: '请选择合作模式',
                                ),
                              ),
                              mid: AppSelectFormField<String>(
                                name: 'settlementMethod',
                                label: '结算方式',
                                required: true,
                                hintText: '请选择',
                                options: SupplierEditController
                                    .settlementMethodOptions,
                                initialValue:
                                    _asStr(c.initialOf('settlementMethod')),
                                validator: AppValidators.required(
                                  message: '请选择结算方式',
                                ),
                              ),
                              right: AppNumberInputFormField(
                                name: 'paymentTermDays',
                                label: '账期(天)',
                                min: 0,
                                max: 3650,
                                initialValue:
                                    _asInt(c.initialOf('paymentTermDays')) ??
                                        0,
                              ),
                            ),
                            _ThreeCol(
                              left: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    '合同模板',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Obx(() {
                                    final count = c.contractPaths.length;
                                    return Row(
                                      children: [
                                        AppButton.primary(
                                          onPressed: count >= 5
                                              ? null
                                              : () => c.pickContract(context),
                                          leading: const Icon(
                                            Icons.upload_outlined,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          child: const Text('上传合同模板'),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$count/5, 支持图片/pdf/doc/docx',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _kMuted,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  Obx(() {
                                    final labels = c.contractLabels.toList();
                                    if (labels.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        children: [
                                          for (var i = 0;
                                              i < labels.length;
                                              i++)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      labels[i],
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: _kTitle,
                                                      ),
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                  AppButton.text(
                                                    onPressed: () =>
                                                        c.removeContractAt(i),
                                                    child: const Text('删除'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              mid: AppTextAreaFormField(
                                name: 'paymentCondition',
                                label: '付款条件',
                                hintText: '付款节点、比例等情况说明',
                                minHeight: 72,
                                initialValue:
                                    _asStr(c.initialOf('paymentCondition')),
                              ),
                              right: AppTextAreaFormField(
                                name: 'rebatePolicy',
                                label: '返点政策',
                                hintText:
                                    '适用于媒介采购等类型，记录返点比例、结算周期、兑现方式',
                                minHeight: 72,
                                initialValue:
                                    _asStr(c.initialOf('rebatePolicy')),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '能力与品类',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            AppMultiSelectFormField<String>(
                              name: 'serviceArea',
                              label: '服务区域',
                              options: serviceOpts,
                              initialValue:
                                  _asStrList(c.initialOf('serviceArea')),
                            ),
                            _ThreeCol(
                              left: AppNumberInputFormField(
                                name: 'teamSize',
                                label: '团队规模',
                                min: 0,
                                max: 999999,
                                initialValue:
                                    _asInt(c.initialOf('teamSize')) ?? 0,
                              ),
                              mid: AppSelectFormField<String>(
                                name: 'invoiceType',
                                label: '开票类型',
                                hintText: '请选择',
                                clearable: true,
                                options:
                                    SupplierEditController.invoiceTypeOptions,
                                initialValue:
                                    _asStr(c.initialOf('invoiceType')),
                              ),
                              right: AppSelectFormField<String>(
                                name: 'taxRate',
                                label: '开票税率',
                                hintText: '请选择',
                                clearable: true,
                                options:
                                    SupplierEditController.taxRateOptions,
                                initialValue: _asStr(c.initialOf('taxRate')),
                              ),
                            ),
                            AppTextAreaFormField(
                              name: 'deliveryCapacity',
                              label: '交付能力',
                              hintText: '选填',
                              minHeight: 72,
                              initialValue:
                                  _asStr(c.initialOf('deliveryCapacity')),
                            ),
                            AppTextAreaFormField(
                              name: 'coreAdvantage',
                              label: '核心优势',
                              hintText: '选填',
                              minHeight: 72,
                              initialValue:
                                  _asStr(c.initialOf('coreAdvantage')),
                            ),
                            AppTextAreaFormField(
                              name: 'remark',
                              label: '备注',
                              hintText: '选填',
                              minHeight: 72,
                              initialValue: _asStr(c.initialOf('remark')),
                            ),
                            const Text(
                              '供应品类明细',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kTitle,
                              ),
                            ),
                            Obx(() {
                              final list = c.categories.toList();
                              if (list.isEmpty) {
                                return const Text(
                                  '随上方供应商类型自动增减',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _kMuted,
                                  ),
                                );
                              }
                              return Column(
                                spacing: 8,
                                children: [
                                  for (final item in list)
                                    _CategoryDraftCard(item: item),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '银税信息',
                        headerTrailing: const Text(
                          '银行账户与开票信息，均可创建多条并一键复制',
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 16,
                          children: [
                            _SubSectionHeader(
                              title: '银行账户信息',
                              hint: '可创建多个开户行与开票汇总信息',
                              onAdd: c.addBank,
                            ),
                            Obx(() {
                              final list = c.banks.toList();
                              if (list.isEmpty) {
                                return const _SubEmptyHint(
                                  '暂无银行账户，可点击添加',
                                );
                              }
                              return Column(
                                spacing: 8,
                                children: [
                                  for (final item in list)
                                    _BankDraftCard(item: item),
                                ],
                              );
                            }),
                            _SubSectionHeader(
                              title: '开票信息',
                              hint: '发票类型与税率，可创建多条并一键复制',
                              onAdd: c.addInvoice,
                            ),
                            Obx(() {
                              final list = c.invoices.toList();
                              if (list.isEmpty) {
                                return const _SubEmptyHint('暂无开票信息');
                              }
                              return Column(
                                spacing: 8,
                                children: [
                                  for (final item in list)
                                    _InvoiceDraftCard(item: item),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '联系人信息',
                        headerTrailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '供应商侧对接人，可创建多个',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            ),
                            const SizedBox(width: 8),
                            AppButton.link(
                              onPressed: c.addContact,
                              child: const Text(
                                '+ 添加',
                                style: TextStyle(color: _kPrimary),
                              ),
                            ),
                          ],
                        ),
                        child: Obx(() {
                          final list = c.contacts.toList();
                          if (list.isEmpty) {
                            return const _SubEmptyHint('暂无联系人');
                          }
                          return Column(
                            spacing: 8,
                            children: [
                              for (final item in list)
                                _ContactDraftCard(item: item),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '我方对接人员',
                        headerTrailing: AppButton.link(
                          onPressed: () async {
                            final selected =
                                await showSelectSalesPersonDialog(
                              context,
                              alreadySelectedUserIds: c.staffs
                                  .map((e) => e.userId)
                                  .whereType<int>()
                                  .toSet(),
                            );
                            if (selected != null && selected.isNotEmpty) {
                              c.addStaffFromEmployees(selected);
                            }
                          },
                          child: const Text(
                            '+ 添加',
                            style: TextStyle(color: _kPrimary),
                          ),
                        ),
                        child: Obx(() {
                          final list = c.staffs.toList();
                          if (list.isEmpty) {
                            return const _SubEmptyHint('暂无我方对接人');
                          }
                          return Column(
                            spacing: 8,
                            children: [
                              for (final item in list)
                                _StaffDraftCard(item: item),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                );
              }),
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
                      '请确认必填项完整后再保存',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ),
                  AppButton.outline(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('取消'),
                  ),
                  if (!c.isEdit) ...[
                    const SizedBox(width: 8),
                    AppButton.outline(
                      onPressed: () => _onSave(context, continueAdd: true),
                      child: const Text('保存并继续新增'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  AppButton.primary(
                    onPressed: () => _onSave(context, continueAdd: false),
                    child: const Text('保存'),
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

// ── 布局小部件 ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.headerTrailing,
  });

  final String title;
  final Widget child;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      borderRadius: BorderRadius.circular(10),
      borderColor: _kBorder,
      fillColor: Colors.white,
      filled: true,
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
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SubEmptyHint extends StatelessWidget {
  const _SubEmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppEmpty(
      padding: const EdgeInsets.symmetric(vertical: 16),
      icon: const Icon(AppLucideIcons.inbox, size: 28),
      title: Text(
        text,
        style: const TextStyle(fontSize: 13, color: _kMuted),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [left, right],
          );
        }
        final w = (constraints.maxWidth - 12) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: w, child: left),
            const SizedBox(width: 12),
            SizedBox(width: w, child: right),
          ],
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [left, mid, right],
          );
        }
        final w = (constraints.maxWidth - 24) / 3;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: w, child: left),
            const SizedBox(width: 12),
            SizedBox(width: w, child: mid),
            const SizedBox(width: 12),
            SizedBox(width: w, child: right),
          ],
        );
      },
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  const _SubSectionHeader({
    required this.title,
    required this.hint,
    required this.onAdd,
  });

  final String title;
  final String hint;
  final VoidCallback onAdd;

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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: _kMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppButton.link(
          onPressed: onAdd,
          child: const Text(
            '+ 添加',
            style: TextStyle(color: _kPrimary),
          ),
        ),
      ],
    );
  }
}

class _DraftShell extends StatelessWidget {
  const _DraftShell({
    super.key,
    required this.child,
    required this.onRemove,
    this.onDuplicate,
    this.showDuplicate = true,
  });

  final Widget child;
  final VoidCallback? onDuplicate;
  final VoidCallback onRemove;
  final bool showDuplicate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              if (showDuplicate && onDuplicate != null)
                IconButton(
                  tooltip: '复制',
                  onPressed: onDuplicate,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_outlined, size: 16, color: _kPrimary),
                ),
              IconButton(
                tooltip: '删除',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 16, color: _kDanger),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.required = false,
    this.hintText,
    this.errorText,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? hintText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final err = errorText?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (required)
              const Text('*', style: TextStyle(color: _kDanger, fontSize: 12)),
            if (required) const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: _kLabel)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: (err != null && err.isNotEmpty) ? _kDanger : _kBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: (err != null && err.isNotEmpty) ? _kDanger : _kPrimary,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
        if (err != null && err.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(err, style: const TextStyle(fontSize: 12, color: _kDanger)),
        ],
      ],
    );
  }
}

class _CategoryDraftCard extends StatelessWidget {
  const _CategoryDraftCard({required this.item});

  final CategoryDraft item;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('cat_${item.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        color: const Color(0xFFF7F8FA),
      ),
      child: _ThreeCol(
        left: TextFormField(
          initialValue: item.supplyCategory,
          decoration: const InputDecoration(
            labelText: '品类',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => item.supplyCategory = v,
        ),
        mid: TextFormField(
          initialValue: item.itemType,
          decoration: const InputDecoration(
            labelText: '类型',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => item.itemType = v,
        ),
        right: TextFormField(
          initialValue: item.itemDesc,
          decoration: const InputDecoration(
            labelText: '描述',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => item.itemDesc = v,
        ),
      ),
    );
  }
}

class _BankDraftCard extends StatelessWidget {
  const _BankDraftCard({required this.item});

  final BankDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierEditController>();
    return _DraftShell(
      key: ValueKey('bank_${item.id}'),
      onDuplicate: () => c.duplicateBank(item),
      onRemove: () => c.removeBank(item.id),
      child: Obx(() {
        final showErr = c.showChildErrors.value;
        return _TwoCol(
          left: CnapsBankPicker(
            required: true,
            value: item.bankName.trim().isEmpty ? null : item.bankName,
            errorText:
                showErr && item.bankName.trim().isEmpty ? '请选择开户行' : null,
            onChanged: (v) {
              item.bankName = v?.trim() ?? '';
              c.banks.refresh();
            },
          ),
          right: _LabeledTextField(
            label: '银行账号',
            required: true,
            initialValue: item.bankAccount,
            errorText: showErr && item.bankAccount.trim().isEmpty
                ? '请填写银行账号'
                : null,
            onChanged: (v) {
              item.bankAccount = v;
              if (showErr) c.banks.refresh();
            },
          ),
        );
      }),
    );
  }
}

class _InvoiceDraftCard extends StatelessWidget {
  const _InvoiceDraftCard({required this.item});

  final InvoiceDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierEditController>();
    return _DraftShell(
      key: ValueKey('inv_${item.id}'),
      onDuplicate: () => c.duplicateInvoice(item),
      onRemove: () => c.removeInvoice(item.id),
      child: Obx(() {
        final showErr = c.showChildErrors.value;
        return Column(
          spacing: 10,
          children: [
            _ThreeCol(
              left: _LabeledTextField(
                label: '名称',
                required: true,
                hintText: '发票抬头名称',
                initialValue: item.invoiceName,
                errorText: showErr && item.invoiceName.trim().isEmpty
                    ? '请填写名称'
                    : null,
                onChanged: (v) {
                  item.invoiceName = v;
                  if (showErr) c.invoices.refresh();
                },
              ),
              mid: _LabeledTextField(
                label: '税号',
                required: true,
                initialValue: item.taxNo,
                errorText:
                    showErr && item.taxNo.trim().isEmpty ? '请填写税号' : null,
                onChanged: (v) {
                  item.taxNo = v;
                  if (showErr) c.invoices.refresh();
                },
              ),
              right: _LabeledTextField(
                label: '注册地址',
                initialValue: item.registerAddress,
                onChanged: (v) => item.registerAddress = v,
              ),
            ),
            _ThreeCol(
              left: _LabeledTextField(
                label: '注册电话',
                initialValue: item.registerPhone,
                onChanged: (v) => item.registerPhone = v,
              ),
              mid: CnapsBankPicker(
                required: true,
                value: item.bankName.trim().isEmpty ? null : item.bankName,
                errorText:
                    showErr && item.bankName.trim().isEmpty ? '请选择开户行' : null,
                onChanged: (v) {
                  item.bankName = v?.trim() ?? '';
                  c.invoices.refresh();
                },
              ),
              right: _LabeledTextField(
                label: '开户银行账号',
                required: true,
                initialValue: item.bankAccount,
                errorText: showErr && item.bankAccount.trim().isEmpty
                    ? '请填写开户银行账号'
                    : null,
                onChanged: (v) {
                  item.bankAccount = v;
                  if (showErr) c.invoices.refresh();
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ContactDraftCard extends StatefulWidget {
  const _ContactDraftCard({required this.item});

  final ContactDraft item;

  @override
  State<_ContactDraftCard> createState() => _ContactDraftCardState();
}

class _ContactDraftCardState extends State<_ContactDraftCard> {
  late final TextEditingController _nameEnCtrl;
  final _nameEnFocus = FocusNode();

  ContactDraft get item => widget.item;

  @override
  void initState() {
    super.initState();
    _nameEnCtrl = TextEditingController(text: item.nameEn);
    _nameEnFocus.addListener(_onNameEnFocus);
  }

  @override
  void dispose() {
    _nameEnFocus.removeListener(_onNameEnFocus);
    _nameEnFocus.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  void _onNameEnFocus() {
    if (!_nameEnFocus.hasFocus) return;
    if (_nameEnCtrl.text.trim().isNotEmpty) return;
    final zh = item.name.trim();
    if (zh.isEmpty) return;
    final en = _chineseToEnglishName(zh);
    if (en.isEmpty) return;
    _nameEnCtrl.text = en;
    item.nameEn = en;
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

  String get _ageYearHint {
    final n = int.tryParse((item.ageGroup ?? '').trim());
    if (n == null || n <= 0 || n > 120) return '即?年前后';
    final year = DateTime.now().year - n;
    return '即$year年前后';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierEditController>();
    return _DraftShell(
      key: ValueKey('contact_${item.id}'),
      showDuplicate: false,
      onDuplicate: null,
      onRemove: () => c.removeContact(item.id),
      child: Obx(() {
        final showErr = c.showChildErrors.value;
        return Column(
        spacing: 10,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 900;
              final name = _LabeledTextField(
                label: '姓名',
                required: true,
                initialValue: item.name,
                errorText:
                    showErr && item.name.trim().isEmpty ? '请填写姓名' : null,
                onChanged: (v) {
                  item.name = v;
                  if (showErr) c.contacts.refresh();
                },
              );
              final nameEn = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(fontSize: 12, color: _kLabel),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameEnCtrl,
                    focusNode: _nameEnFocus,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '填写姓名后自动生成拼音',
                      hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                    ),
                    onChanged: (v) => item.nameEn = v,
                  ),
                ],
              );
              final gender = AppSelectFormField<String>(
                label: '性别',
                hintText: '请选择',
                clearable: true,
                options: SupplierEditController.genderOptions,
                initialValue: item.gender,
                onChanged: (v) => item.gender = v,
              );
              final age = _AgeApproxField(
                initialAge: item.ageGroup,
                yearHint: _ageYearHint,
                onChanged: (v) {
                  item.ageGroup = v;
                  setState(() {});
                },
              );
              if (narrow) {
                return Column(
                  spacing: 10,
                  children: [name, nameEn, gender, age],
                );
              }
              final w = (constraints.maxWidth - 36) / 4;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: w, child: name),
                  const SizedBox(width: 12),
                  SizedBox(width: w, child: nameEn),
                  const SizedBox(width: 12),
                  SizedBox(width: w, child: gender),
                  const SizedBox(width: 12),
                  SizedBox(width: w, child: age),
                ],
              );
            },
          ),
          _TwoCol(
            left: _LabeledTextField(
              label: '部门/职位',
              initialValue: item.deptPost,
              onChanged: (v) => item.deptPost = v,
            ),
            right: _LabeledTextField(
              label: '职能描述',
              initialValue: item.dutyDesc,
              onChanged: (v) => item.dutyDesc = v,
            ),
          ),
          _TwoCol(
            left: _LabeledTextField(
              label: '手机号',
              required: true,
              hintText: '11位手机号',
              initialValue: item.mobile,
              errorText:
                  showErr && item.mobile.trim().isEmpty ? '请填写手机号' : null,
              onChanged: (v) {
                item.mobile = v;
                if (showErr) c.contacts.refresh();
              },
            ),
            right: _LabeledTextField(
              label: '邮箱',
              required: true,
              hintText: 'name@example.com',
              initialValue: item.email,
              errorText:
                  showErr && item.email.trim().isEmpty ? '请填写邮箱' : null,
              onChanged: (v) {
                item.email = v;
                if (showErr) c.contacts.refresh();
              },
            ),
          ),
        ],
      );
      }),
    );
  }
}

class _AgeApproxField extends StatelessWidget {
  const _AgeApproxField({
    required this.initialAge,
    required this.yearHint,
    required this.onChanged,
  });

  final String? initialAge;
  final String yearHint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('年龄段', style: TextStyle(fontSize: 12, color: _kLabel)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('约', style: TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(width: 6),
            SizedBox(
              width: 64,
              child: TextFormField(
                initialValue: initialAge ?? '',
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 6),
            Text('岁，$yearHint', style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ),
      ],
    );
  }
}

class _StaffDraftCard extends StatelessWidget {
  const _StaffDraftCard({required this.item});

  final StaffDraft item;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierEditController>();
    return Container(
      key: ValueKey('staff_${item.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        color: const Color(0xFFF7F8FA),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.trim().isEmpty ? '-' : item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.deptPost.trim().isEmpty ? '—' : item.deptPost,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          AppButton.text(
            onPressed: () => c.removeStaff(item.id),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
