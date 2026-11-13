import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' as shad;
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:pinyin/pinyin.dart';

import '../../purchase_order/dialogs/select_counterpart_dialog.dart';
import '../../../../utils/china_regions.dart';
import 'cnaps_bank_picker.dart';
import 'supplier_edit_controller.dart';

const _kPrimary = Color(0xFF1677FF);
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

/// 打开「新建 / 编辑供应商」弹窗（与主体概览同款 HyperDialog）。
/// 返回 `true` 表示保存成功并关闭。
Future<bool> showSupplierEditDialog(
  BuildContext context, {
  String? supplierId,
  SupplierEditSection? section,
}) async {
  // 等触发按钮的 pointer/mouse 事件结束后再打开，避免 MouseTracker 重入。
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return false;
  final result = await showHyperDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final mq = MediaQuery.of(dialogContext);
      return LxScope(
        bindings: (container) {
          container.put<SupplierEditController>(
            () => SupplierEditController(
              supplierId: supplierId,
              section: section,
            ),
          );
        },
        child: AppShadcnScope(
          config: AppThemeConfig.standard(primary: _kPrimary),
          child: MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.noScaling),
            child: _Body(
              onClose: (ok) => Navigator.of(dialogContext).pop(ok),
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

/// 兼容旧全页入口；请优先使用 [showSupplierEditDialog]。
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
        child: _Body(
          onClose: (ok) => Navigator.of(context).pop(ok),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.onClose});

  final void Function(bool ok) onClose;

  SupplierEditController _c(BuildContext context) =>
      context.lx.find<SupplierEditController>();

  Future<void> _onSave(
    BuildContext context, {
    required bool continueAdd,
  }) async {
    final c = _c(context);
    final ok = await c.save(context: context, continueAdd: continueAdd);
    if (ok && !continueAdd && context.mounted) {
      onClose(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final dialogH =
        (MediaQuery.sizeOf(context).height * 0.78).clamp(420.0, 720.0);
    return Obx(() {
      final title = c.dialogTitle;
      if (c.bootLoading.value) {
        return HyperDialog(
          title: Text(title),
          scrollable: false,
          style: const HyperDialogStyle(maxWidth: 960),
          onClose: () => onClose(false),
          content: const SizedBox(
            height: 180,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ),
          actions: [
            HyperButton.outlined(
              onPressed: () => onClose(false),
              label: const Text('取消'),
            ),
          ],
        );
      }
      final err = c.errorMessage.value;
      if (err != null && c.isEdit) {
        return HyperDialog(
          title: Text(title),
          scrollable: false,
          style: const HyperDialogStyle(maxWidth: 960),
          onClose: () => onClose(false),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              err,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          actions: [
            HyperButton.outlined(
              onPressed: () => onClose(false),
              label: const Text('关闭'),
            ),
          ],
        );
      }
      return Obx(() {
        final epoch = c.formEpoch.value;
        final regions = c.regionOptions.toList();
        final serviceTree = ChinaRegions.toProvinceCity(regions);
        return AppForm(
          key: ValueKey('supplier_edit_form_$epoch'),
          controller: c.form,
          child: HyperDialog(
            title: Text(title),
            scrollable: false,
            style: const HyperDialogStyle(maxWidth: 960),
            onClose: () => onClose(false),
            content: SizedBox(
              height: dialogH,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  if (c.shows(SupplierEditSection.overview)) ...[
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
                                    '公司logo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Obx(() {
                                    final has = c.hasLogo;
                                    final label = c.logoLabel.value?.trim();
                                    final bytes = c.logoBytes.value;
                                    final url = c.logoPreviewUrl.value?.trim();
                                    if (!has) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: AppButton.primary(
                                          onPressed: () => c.pickLogo(context),
                                          leading: const Icon(
                                            Icons.upload_outlined,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          child: const Text('上传 Logo'),
                                        ),
                                      );
                                    }
                                    return Container(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        6,
                                        8,
                                        6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _kBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: bytes != null &&
                                                      bytes.isNotEmpty
                                                  ? Image.memory(
                                                      bytes,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                    )
                                                  : (url != null &&
                                                          url.isNotEmpty)
                                                      ? Image.network(
                                                          url,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (
                                                            _,
                                                            _,
                                                            _,
                                                          ) =>
                                                              const ColoredBox(
                                                            color: Color(
                                                              0xFFF2F3F5,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .image_outlined,
                                                              size: 18,
                                                              color: _kMuted,
                                                            ),
                                                          ),
                                                        )
                                                      : const ColoredBox(
                                                          color: Color(
                                                            0xFFF2F3F5,
                                                          ),
                                                          child: Icon(
                                                            Icons.image_outlined,
                                                            size: 18,
                                                            color: _kMuted,
                                                          ),
                                                        ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              (label != null &&
                                                      label.isNotEmpty)
                                                  ? label
                                                  : '已上传',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: _kTitle,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          AppButton.link(
                                            onPressed: () =>
                                                c.pickLogo(context),
                                            child: const Text(
                                              '重新上传',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _kPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          AppButton.link(
                                            onPressed: c.clearLogo,
                                            child: const Text(
                                              '删除',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _kDanger,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              right: AppTextFormField(
                                name: 'website',
                                label: '官网',
                                hintText: 'https://',
                                initialValue: _asStr(c.initialOf('website')),
                              ),
                            ),
                            if (c.section == null) ...[
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                  ],
                  if (c.shows(SupplierEditSection.basic)) ...[
                      _SectionCard(
                        title: '营业执照信息',
                        headerTrailing: c.section == SupplierEditSection.basic
                            ? Obx(() {
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
                              })
                            : null,
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
                                // 营业执照识别后强制换新字段，避免数字框停在初始 0。
                                key: ValueKey(
                                  'registeredCapital_$epoch'
                                  '_${c.initialOf('registeredCapital')}',
                                ),
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
                                key: ValueKey(
                                  'establishDate_$epoch'
                                  '_${c.initialOf('establishDate')}',
                                ),
                                name: 'establishDate',
                                label: '成立日期',
                                hintText: '请选择日期',
                                // popover 在 HyperDialog 内无法点「确定」，改 dialog
                                mode: shad.PromptMode.dialog,
                                initialValue:
                                    _asDate(c.initialOf('establishDate')),
                              ),
                              mid: AppDateRangePickerFormField(
                                name: 'licenseValid',
                                label: '执照有效期',
                                hintText: '开始日期 - 结束日期',
                                mode: shad.PromptMode.dialog,
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
                            if (c.section == SupplierEditSection.basic) ...[
                              AppTextAreaFormField(
                                name: 'remark',
                                label: '备注',
                                hintText: '选填',
                                minHeight: 72,
                                initialValue: _asStr(c.initialOf('remark')),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                  ],
                  if (c.shows(SupplierEditSection.contract)) ...[
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
                              mid: _SettlementMethodField(
                                initialValue: _asStr(
                                  c.initialOf('settlementMethod'),
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
                                    final labels = c.contractLabels.toList();
                                    final bytesList =
                                        c.contractPreviewBytes.toList();
                                    final urls =
                                        c.contractPreviewUrls.toList();
                                    final count = c.contractPaths.length;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (var i = 0;
                                            i < labels.length;
                                            i++) ...[
                                          Container(
                                            padding:
                                                const EdgeInsets.fromLTRB(
                                              8,
                                              6,
                                              8,
                                              6,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _kBorder,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    4,
                                                  ),
                                                  child: SizedBox(
                                                    width: 36,
                                                    height: 36,
                                                    child: _contractThumb(
                                                      bytes: i <
                                                              bytesList.length
                                                          ? bytesList[i]
                                                          : null,
                                                      url: i < urls.length
                                                          ? urls[i]
                                                          : null,
                                                      fileName: labels[i],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    labels[i],
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: _kTitle,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                AppButton.link(
                                                  onPressed: () =>
                                                      c.removeContractAt(i),
                                                  child: const Text(
                                                    '删除',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: _kDanger,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        CustomPaint(
                                          foregroundPainter:
                                              _DashedRRectPainter(
                                            color: const Color(0xFF91CAFF),
                                            radius: 6,
                                          ),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.fromLTRB(
                                              10,
                                              10,
                                              10,
                                              10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F7FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                AppButton.primary(
                                                  onPressed: count >= 5
                                                      ? null
                                                      : () => c.pickContract(
                                                            context,
                                                          ),
                                                  leading: const Icon(
                                                    Icons.upload_outlined,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                  child: const Text(
                                                    '上传合同模板',
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    '$count/5，支持图片 / pdf / doc / docx',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: _kMuted,
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
                  ],
                  if (c.shows(SupplierEditSection.capability)) ...[
                      _SectionCard(
                        title: '能力与品类',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            // 待上游：AppCascadeMultiSelectFormField（省市多选级联）
                            _ServiceAreaCascadeMultiFormField(
                              name: 'serviceArea',
                              label: '服务区域',
                              options: serviceTree,
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
                              mid: AppMultiSelectFormField<String>(
                                name: 'invoiceType',
                                label: '开票类型',
                                options:
                                    SupplierEditController.invoiceTypeOptions,
                                initialValue:
                                    _asStrList(c.initialOf('invoiceType')),
                              ),
                              right: _TaxRateFields(
                                initialRate: _asStr(c.initialOf('taxRate')),
                                initialCustom:
                                    _asStr(c.initialOf('taxRateCustom')),
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
                            if (c.section == null)
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
                  ],
                  if (c.shows(SupplierEditSection.bank) ||
                      c.shows(SupplierEditSection.invoice)) ...[
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
                            if (c.shows(SupplierEditSection.bank)) ...[
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
                            ],
                            if (c.shows(SupplierEditSection.invoice)) ...[
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                  ],
                  if (c.shows(SupplierEditSection.overview)) ...[
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
                        headerTrailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '从组织架构选择，可创建多个',
                              style: TextStyle(fontSize: 12, color: _kMuted),
                            ),
                            const SizedBox(width: 8),
                            AppButton.link(
                              onPressed: c.addStaff,
                              child: const Text(
                                '+ 添加',
                                style: TextStyle(color: _kPrimary),
                              ),
                            ),
                          ],
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
                                _StaffDraftCard(
                                  key: ValueKey(item.id),
                                  item: item,
                                ),
                            ],
                          );
                        }),
                      ),
                  ],
                    ],
                  ),
                ),
              ),
            actions: [
              HyperButton.outlined(
                onPressed: () => onClose(false),
                label: const Text('取消'),
              ),
              if (!c.isEdit)
                HyperButton.outlined(
                  onPressed: () => _onSave(context, continueAdd: true),
                  label: const Text('保存并继续新增'),
                ),
              HyperButton.filled(
                onPressed: () => _onSave(context, continueAdd: false),
                label: const Text('保存'),
              ),
            ],
          ),
        );
      });
    });
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

const _settlementPresets = {'30天', '60天', '90天', '按次结算', 'X天'};

/// 结算方式：选「X天」时在下方手填天数（0–3650）。
/// 天数框保持展开，下拉值始终停在「X天」，避免收成选项外的「N天」后无法再改。
class _SettlementMethodField extends StatefulWidget {
  const _SettlementMethodField({this.initialValue});

  final String? initialValue;

  @override
  State<_SettlementMethodField> createState() => _SettlementMethodFieldState();
}

class _SettlementMethodFieldState extends State<_SettlementMethodField> {
  late String? _selected;
  String? _custom;
  var _showInput = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.initialValue?.trim();
    if (raw == null || raw.isEmpty) {
      _selected = null;
    } else if (raw == 'X天') {
      _selected = raw;
      _showInput = true;
    } else if (_settlementPresets.contains(raw)) {
      _selected = raw;
    } else if (raw.endsWith('天')) {
      final days = raw.substring(0, raw.length - 1);
      final n = int.tryParse(days);
      if (n != null && n >= 0 && n <= 3650) {
        _selected = 'X天';
        _custom = '$n';
        _showInput = true;
      } else {
        _selected = raw;
      }
    } else {
      _selected = raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        AppSelectFormField<String>(
          name: 'settlementMethod',
          label: '结算方式',
          required: true,
          hintText: '请选择',
          options: SupplierEditController.settlementMethodOptions,
          initialValue: _selected,
          onChanged: (v) {
            setState(() {
              _selected = v;
              _showInput = v == 'X天';
              if (v != 'X天') _custom = null;
            });
          },
          validator: AppValidators.required(message: '请选择结算方式'),
        ),
        if (_showInput)
          AppTextFormField(
            name: 'settlementCustomDays',
            hintText: '请输入 0-3650',
            initialValue: _custom,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            trailing: const Text(
              '天',
              style: TextStyle(fontSize: 13, color: _kMuted),
            ),
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty) return '请输入结算天数';
              final n = int.tryParse(text);
              if (n == null || n < 0 || n > 3650) return '请输入 0-3650';
              return null;
            },
          ),
      ],
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

/// 开票税率：选「其他」时下方出现手填税率（带 %）。
class _TaxRateFields extends StatefulWidget {
  const _TaxRateFields({this.initialRate, this.initialCustom});

  final String? initialRate;
  final String? initialCustom;

  @override
  State<_TaxRateFields> createState() => _TaxRateFieldsState();
}

class _TaxRateFieldsState extends State<_TaxRateFields> {
  late String? _selected = widget.initialRate;

  bool get _isOther => _selected == '其他';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        AppSelectFormField<String>(
          name: 'taxRate',
          label: '开票税率',
          hintText: '请选择',
          clearable: true,
          options: SupplierEditController.taxRateOptions,
          initialValue: widget.initialRate,
          onChanged: (v) => setState(() => _selected = v),
        ),
        if (_isOther)
          AppTextFormField(
            name: 'taxRateCustom',
            hintText: '请输入税率',
            initialValue: widget.initialCustom,
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
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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

  List<String> _splitTypes(String raw) => [
        for (final e in raw.split(RegExp(r'[,，、]')))
          if (e.trim().isNotEmpty) e.trim(),
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierEditController>();
    final cat = item.supplyCategory.trim();
    final subLabel = switch (cat) {
      '媒介采购' => '媒体类型',
      '物业租赁' => '物业类型',
      '设备采购' => '设备类型',
      _ => null,
    };
    final subOptions = switch (cat) {
      '媒介采购' => SupplierEditController.mediaTypeOptions,
      '物业租赁' => SupplierEditController.propertyTypeOptions,
      '设备采购' => SupplierEditController.equipmentTypeOptions,
      _ => const <AppOption<String>>[],
    };
    final multi = cat == '媒介采购';
    return _DraftShell(
      key: ValueKey('cat_${item.id}'),
      showDuplicate: false,
      onRemove: () => c.removeCategory(item.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '供应商品类',
                style: TextStyle(fontSize: 12, color: _kLabel),
              ),
              const SizedBox(height: 6),
              AppSelect<String>(
                options: SupplierEditController.supplierTypeOptions,
                value: cat.isEmpty ? null : cat,
                hintText: '随上方供应商类型',
                enabled: false,
              ),
            ],
          ),
          if (subLabel != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  subLabel,
                  style: const TextStyle(fontSize: 12, color: _kLabel),
                ),
                const SizedBox(height: 6),
                if (multi)
                  AppMultiSelect<String>(
                    options: subOptions,
                    value: _splitTypes(item.itemType),
                    onChanged: (v) {
                      item.itemType = (v ?? const []).join(',');
                      c.categories.refresh();
                    },
                  )
                else
                  AppSelect<String>(
                    options: subOptions,
                    value: item.itemType.trim().isEmpty
                        ? null
                        : item.itemType.trim(),
                    hintText: '请选择',
                    clearable: true,
                    onChanged: (v) {
                      item.itemType = v?.trim() ?? '';
                      c.categories.refresh();
                    },
                  ),
              ],
            ),
          _LabeledTextField(
            label: '描述',
            hintText: '填写描述',
            initialValue: item.itemDesc,
            onChanged: (v) => item.itemDesc = v,
          ),
          _LabeledTextField(
            label: '备注',
            hintText: '填写备注',
            initialValue: item.remark,
            onChanged: (v) => item.remark = v,
          ),
        ],
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
                hintText: '最多11位数字',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                initialValue: item.registerPhone,
                errorText: SupplierEditController.contactMobileError(
                  item.registerPhone,
                  required: false,
                  label: '注册电话',
                ),
                onChanged: (v) {
                  item.registerPhone = v;
                  c.invoices.refresh();
                },
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

/// 格式不对立刻提示；空的必填项等到保存再提示。
String? _contactFieldError({
  required String raw,
  required bool showRequired,
  required String? error,
}) {
  if (error == null) return null;
  if (raw.trim().isEmpty) return showRequired ? error : null;
  return error;
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
                  final en = _chineseToEnglishName(v);
                  _nameEnCtrl.value = TextEditingValue(
                    text: en,
                    selection: TextSelection.collapsed(offset: en.length),
                  );
                  item.nameEn = en;
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
              hintText: '最多11位数字',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              initialValue: item.mobile,
              errorText: _contactFieldError(
                raw: item.mobile,
                showRequired: showErr,
                error: SupplierEditController.contactMobileError(item.mobile),
              ),
              onChanged: (v) {
                item.mobile = v;
                c.contacts.refresh();
              },
            ),
            right: _LabeledTextField(
              label: '邮箱',
              required: true,
              hintText: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              initialValue: item.email,
              errorText: _contactFieldError(
                raw: item.email,
                showRequired: showErr,
                error: SupplierEditController.contactEmailError(item.email),
              ),
              onChanged: (v) {
                item.email = v;
                c.contacts.refresh();
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

Widget _contractThumb({
  required Uint8List? bytes,
  required String? url,
  required String fileName,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }
  final remote = url?.trim() ?? '';
  if (remote.isNotEmpty) {
    return Image.network(
      remote,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _contractFileIcon(fileName),
    );
  }
  return _contractFileIcon(fileName);
}

Widget _contractFileIcon(String fileName) {
  final lower = fileName.toLowerCase();
  final IconData icon;
  if (lower.endsWith('.pdf')) {
    icon = Icons.picture_as_pdf_outlined;
  } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
    icon = Icons.description_outlined;
  } else {
    icon = Icons.insert_drive_file_outlined;
  }
  return ColoredBox(
    color: const Color(0xFFF2F3F5),
    child: Icon(icon, size: 18, color: _kMuted),
  );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

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
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _StaffDraftCard extends StatefulWidget {
  const _StaffDraftCard({super.key, required this.item});

  final StaffDraft item;

  @override
  State<_StaffDraftCard> createState() => _StaffDraftCardState();
}

class _StaffDraftCardState extends State<_StaffDraftCard> {
  StaffDraft get item => widget.item;
  var _picking = false;

  Future<void> _pickEmployee() async {
    if (_picking) return;
    _picking = true;
    final draftId = item.id;
    try {
      // 等当前 pointer/mouse 事件结束，避免嵌套弹窗与 MouseTracker 重入。
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      final c = context.lx.find<SupplierEditController>();
      final picked = await showSelectCounterpartDialog(context);
      if (picked == null) return;

      // 数据写在 Controller 上：弹窗关闭后即便本 State 短暂 unmounted 也要回填。
      StaffDraft? target;
      for (final s in c.staffs) {
        if (s.id == draftId) {
          target = s;
          break;
        }
      }
      if (target == null) return;

      final ok = c.applyEmployeeToStaff(target, picked);
      // 等选人弹窗路由卸干净再刷 UI，减少落点二次打开。
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      if (!ok) {
        showHyperToast(
          context,
          content: const Text('该人员已添加为我方对接人'),
        );
        return;
      }
      setState(() {});
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _picking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierEditController>();
    final nameText = item.name.trim();
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: const Color(0xFFC9CDD4),
        radius: 8,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '删除',
                onPressed: () => c.removeStaff(item.id),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: _kDanger,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final nameField = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '姓名',
                      style: TextStyle(fontSize: 12, color: _kLabel),
                    ),
                    const SizedBox(height: 6),
                    AppInkWell(
                      onPressed: _pickEmployee,
                      borderRadius: BorderRadius.circular(6),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          isDense: true,
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
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: _kMuted,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        child: Text(
                          nameText.isEmpty ? '请选择' : nameText,
                          style: TextStyle(
                            fontSize: 12,
                            color: nameText.isEmpty ? _kMuted : _kTitle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
                final nameEn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Name (EN)',
                      style: TextStyle(fontSize: 12, color: _kLabel),
                    ),
                    const SizedBox(height: 6),
                    _StaffReadonlyBox(text: item.nameEn),
                  ],
                );
                final gender = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '性别',
                      style: TextStyle(fontSize: 12, color: _kLabel),
                    ),
                    const SizedBox(height: 6),
                    _StaffReadonlyBox(text: _staffGenderText(item.gender)),
                  ],
                );
                if (constraints.maxWidth < 900) {
                  return Column(
                    spacing: 10,
                    children: [nameField, nameEn, gender],
                  );
                }
                final w = (constraints.maxWidth - 24) / 3;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: w, child: nameField),
                    const SizedBox(width: 12),
                    SizedBox(width: w, child: nameEn),
                    const SizedBox(width: 12),
                    SizedBox(width: w, child: gender),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '部门/职位',
                  style: TextStyle(fontSize: 12, color: _kLabel),
                ),
                const SizedBox(height: 6),
                _StaffReadonlyBox(text: item.deptPost),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _staffGenderText(String? gender) {
  return switch (gender?.trim()) {
    '1' || '男' => '男',
    '2' || '女' => '女',
    '0' || '未知' => '未知',
    final s when s != null && s.isNotEmpty => s,
    _ => '',
  };
}

class _StaffReadonlyBox extends StatelessWidget {
  const _StaffReadonlyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _kMuted),
      ),
    );
  }
}

/// 服务区域：省 → 市多选级联（临时；待上游 AppCascadeMultiSelectFormField）。
/// 勾选后用 [ValueNotifier] 即时刷新框内标签；表单写回放到 microtask，避免 MouseTracker 重入。
class _ServiceAreaCascadeMultiFormField extends FormField<List<String>> {
  _ServiceAreaCascadeMultiFormField({
    required List<AppCascadeOption<String>> options,
    this.name,
    this.label,
    super.initialValue,
  }) : super(
         builder: (state) {
           final field = state.widget as _ServiceAreaCascadeMultiFormField;
           return AppFormFieldBinding<List<String>>(
             name: field.name,
             value: state.value,
             builder: (context, asyncError) => AppField(
               label: field.label,
               errorText: state.errorText ?? asyncError,
               child: _ServiceAreaCascadeMulti(
                 options: options,
                 value: state.value ?? const [],
                 onChanged: state.didChange,
               ),
             ),
           );
         },
       );

  final String? name;
  final String? label;
}

class _ServiceAreaCascadeMulti extends StatefulWidget {
  const _ServiceAreaCascadeMulti({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<AppCascadeOption<String>> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_ServiceAreaCascadeMulti> createState() =>
      _ServiceAreaCascadeMultiState();
}

class _ServiceAreaCascadeMultiState extends State<_ServiceAreaCascadeMulti> {
  late final ValueNotifier<List<String>> _live;
  bool _opening = false;

  Map<String, String> get _labels {
    final map = <String, String>{};
    for (final p in widget.options) {
      map[p.value] = p.label;
      for (final c in p.children) {
        map[c.value] = c.label;
      }
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _live = ValueNotifier(List<String>.of(widget.value));
  }

  @override
  void didUpdateWidget(covariant _ServiceAreaCascadeMulti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_opening && oldWidget.value != widget.value) {
      _live.value = List<String>.of(widget.value);
    }
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  void _emit(List<String> next) {
    _live.value = List<String>.of(next);
    // 延后写表单，避免与浮层 pointer/mouse 更新重入。
    scheduleMicrotask(() {
      if (mounted) widget.onChanged(List<String>.of(_live.value));
    });
  }

  void _remove(String v) {
    _emit([for (final e in _live.value) if (e != v) e]);
  }

  void _clear() => _emit(const []);

  Future<void> _open(BuildContext context) async {
    if (_opening) return;
    _opening = true;
    final draft = List<String>.of(_live.value);
    var active = widget.options
        .where(
          (p) =>
              draft.contains(p.value) ||
              p.children.any((c) => draft.contains(c.value)),
        )
        .map((p) => p.value)
        .firstOrNull;
    active ??= widget.options.firstOrNull?.value;

    final overlay = shad.showDropdown<void>(
      context: context,
      anchorAlignment: Alignment.bottomLeft,
      alignment: Alignment.topLeft,
      widthConstraint: shad.PopoverConstraint.flexible,
      builder: (context) {
        final theme = shad.Theme.of(context);
        return StatefulBuilder(
          builder: (context, setLocal) {
            final province =
                widget.options.where((e) => e.value == active).firstOrNull;
            final cities = province?.children ?? const [];
            final showCities = province != null && cities.isNotEmpty;
            final rows = widget.options.length > cities.length
                ? widget.options.length
                : (showCities ? cities.length : widget.options.length);
            final height = (rows * 32.0 + 8.0).clamp(160.0, 320.0);

            void toggle(String v) {
              if (draft.contains(v)) {
                draft.remove(v);
              } else {
                draft.add(v);
              }
              setLocal(() {});
              _emit(draft);
            }

            return shad.ModalContainer(
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 168,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemExtent: 32,
                        itemCount: widget.options.length,
                        itemBuilder: (_, i) {
                          final node = widget.options[i];
                          return _ServiceAreaRow(
                            label: node.label,
                            checked: draft.contains(node.value),
                            active: active == node.value,
                            hasChildren: node.children.isNotEmpty,
                            onCheck: () => toggle(node.value),
                            onExpand: () =>
                                setLocal(() => active = node.value),
                          );
                        },
                      ),
                    ),
                    if (showCities) ...[
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: theme.colorScheme.border,
                      ),
                      SizedBox(
                        width: 168,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(4),
                          itemExtent: 32,
                          itemCount: cities.length,
                          itemBuilder: (_, i) {
                            final node = cities[i];
                            return _ServiceAreaRow(
                              label: node.label,
                              checked: draft.contains(node.value),
                              active: false,
                              hasChildren: false,
                              onCheck: () => toggle(node.value),
                              onExpand: () => toggle(node.value),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    await overlay.future;
    _opening = false;
    if (mounted) widget.onChanged(List<String>.of(_live.value));
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder),
        ),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: _live,
          builder: (context, selected, _) {
            final chips = [for (final v in selected) labels[v] ?? v];
            return Row(
              children: [
                Expanded(
                  child: chips.isEmpty
                      ? const Text(
                          '请选择',
                          style: TextStyle(fontSize: 13, color: _kMuted),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var i = 0; i < chips.length && i < 2; i++)
                              _ServiceAreaChip(
                                label: chips[i],
                                onRemove: () => _remove(selected[i]),
                              ),
                            if (chips.length > 2)
                              Text(
                                '+${chips.length - 2}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                ),
                              ),
                          ],
                        ),
                ),
                if (selected.isNotEmpty)
                  GestureDetector(
                    onTap: _clear,
                    child: const Icon(Icons.cancel, size: 16, color: _kMuted),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: _kMuted,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceAreaChip extends StatelessWidget {
  const _ServiceAreaChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kTitle),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _ServiceAreaRow extends StatelessWidget {
  const _ServiceAreaRow({
    required this.label,
    required this.checked,
    required this.active,
    required this.hasChildren,
    required this.onCheck,
    required this.onExpand,
  });

  final String label;
  final bool checked;
  final bool active;
  final bool hasChildren;
  final VoidCallback onCheck;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFE8F3FF) : Colors.transparent;
    final fg = active || checked ? _kPrimary : _kTitle;
    return ColoredBox(
      color: bg,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCheck,
            child: SizedBox(
              width: 28,
              height: 32,
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: checked ? _kPrimary : _kBorder,
                      width: 1.5,
                    ),
                    color: checked ? _kPrimary : Colors.transparent,
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExpand,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: fg,
                  fontWeight:
                      active || checked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          if (hasChildren)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExpand,
              child: SizedBox(
                width: 24,
                height: 32,
                child: Icon(Icons.chevron_right, size: 16, color: fg),
              ),
            ),
        ],
      ),
    );
  }
}
