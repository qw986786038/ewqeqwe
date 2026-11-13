import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../models/oac_agency.dart';
import '../../models/oac_brand.dart';
import '../../models/oac_brand_detail.dart';
import '../../models/oac_enterprise.dart';
import '../customer_archive/detail/dialogs/entity_module_edit_dialog.dart';
import '../customer_archive/dialogs/quick_create_brand_dialog.dart';
import '../office_map_dialog.dart';
import 'brand_detail_controller.dart';
import 'dialogs/add_order_dialog.dart';
import 'dialogs/agency_overview_dialog.dart';
import 'dialogs/brand_profile_actions.dart';
import 'dialogs/order_contacts_dialog.dart';
import 'dialogs/order_sales_dialog.dart';

part 'order_detail_page.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF5F7FA);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE8E8E8);
const _kTitle = Color(0xFF262626);
const _kGold = Color(0xFFD48806);
const _kBanner = Color(0xFF0B3A6E);
const _kTrendUp = Color(0xFF52C41A);
const _kTrendDown = Color(0xFFFF4D4F);


/// 详情页「导出」：导出当前详情下的订单明细（本地 SpreadsheetML `.xls`）。
Future<void> _exportOrderDetails(
  BuildContext context,
  BrandDetailController controller, {
  List<OrderItem>? orders,
}) async {
  final list = orders ?? controller.detail.value?.orders ?? const <OrderItem>[];
  if (list.isEmpty) {
    showHyperToast(context, content: const Text('暂无订单可导出'));
    return;
  }
  final brandName = controller.detail.value?.brand?.name?.trim();
  final salesFallback = () {
    final b = controller.detail.value?.brand;
    final names = b?.ownerNameList;
    if (names != null && names.isNotEmpty) return names.first;
    return b?.ownerNames?.trim() ?? '';
  }();
  try {
    final bytes = _buildOrderDetailsSpreadsheetMl(
      sheetName: '订单明细',
      controller: controller,
      orders: list,
      salesFallback: salesFallback,
    );
    final stamp = DateTime.now();
    String pad2(int n) => n.toString().padLeft(2, '0');
    final prefix = (brandName != null && brandName.isNotEmpty)
        ? '${brandName}_订单明细'
        : '订单明细';
    final fileName =
        '${prefix}_${stamp.year}${pad2(stamp.month)}${pad2(stamp.day)}_'
        '${pad2(stamp.hour)}${pad2(stamp.minute)}.xls';
    if (!context.mounted) return;
    final saved = await FilePicker.saveFile(
      dialogTitle: '导出订单明细',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/vnd.ms-excel',
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (!context.mounted || saved == null) return;
    showHyperToast(context, content: const Text('导出成功'));
  } catch (e) {
    if (!context.mounted) return;
    showHyperToast(context, content: Text('$e'));
  }
}

String _xmlEscape(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

Uint8List _buildOrderDetailsSpreadsheetMl({
  required String sheetName,
  required BrandDetailController controller,
  required List<OrderItem> orders,
  required String salesFallback,
}) {
  const headers = <String>[
    '序号',
    '订单编号',
    '品牌简称',
    '签约主体',
    '关联关系',
    '关联4A',
    '合同类型',
    '订单金额',
    '订单时间',
    '联系人',
    '销售员',
    '备注',
  ];
  final sb = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<?mso-application progid="Excel.Sheet"?>')
    ..writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    )
    ..writeln('<Worksheet ss:Name="${_xmlEscape(sheetName)}">')
    ..writeln('<Table>');

  sb.write('<Row>');
  for (final title in headers) {
    sb.write(
      '<Cell><Data ss:Type="String">${_xmlEscape(title)}</Data></Cell>',
    );
  }
  sb.writeln('</Row>');

  final fallbackBrand = controller.detail.value?.brand?.name?.trim() ?? '';
  for (var i = 0; i < orders.length; i++) {
    final o = orders[i];
    final brand = o.brandName?.trim().isNotEmpty == true
        ? o.brandName!.trim()
        : fallbackBrand;
    final sales = o.salesPerson?.trim().isNotEmpty == true
        ? o.salesPerson!.trim()
        : salesFallback;
    final cells = <String>[
      '${i + 1}',
      o.orderNo?.trim() ?? o.name?.trim() ?? '',
      brand,
      o.enterprise?.trim() ?? '',
      controller.orderRelationDisplay(o),
      o.agencyName?.trim() ?? o.agencyId?.trim() ?? '',
      controller.contractTypeLabel(o.contractType),
      o.amount?.trim() ?? '',
      _fmtOrderTime(o.orderTime, withTime: true),
      o.contact?.trim() ?? '',
      sales,
      o.remark?.trim() ?? '',
    ];
    sb.write('<Row>');
    for (var c = 0; c < cells.length; c++) {
      final text = cells[c];
      if (c == 0 || c == 7) {
        final n = num.tryParse(text);
        if (n != null) {
          sb.write('<Cell><Data ss:Type="Number">$n</Data></Cell>');
          continue;
        }
      }
      sb.write(
        '<Cell><Data ss:Type="String">${_xmlEscape(text)}</Data></Cell>',
      );
    }
    sb.writeln('</Row>');
  }

  sb
    ..writeln('</Table>')
    ..writeln('</Worksheet>')
    ..writeln('</Workbook>');
  return Uint8List.fromList(utf8.encode(sb.toString()));
}

class BrandDetailPage extends StatelessWidget {
  const BrandDetailPage({
    super.key,
    required this.brandId,
    this.perspective = OacDetailPerspective.brand,
    this.enterpriseSeed,
    this.agencySeed,
  });

  final String brandId;
  final OacDetailPerspective perspective;
  /// 企业列表行兜底（详情缺 `relationType` / 标签 / 关联品牌时用）。
  final OacEnterprise? enterpriseSeed;
  /// 4A 列表行兜底。
  final OacAgency? agencySeed;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<BrandDetailController>(
          () => BrandDetailController(
            brandId: brandId,
            perspective: perspective,
            enterpriseSeed: enterpriseSeed,
            agencySeed: agencySeed,
          ),
        );
      },
      // Scope 须包在 _Body 外：弹窗用 State.context，否则找不到 shadcn Theme。
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  BrandDetailController get _c => context.lx.find<BrandDetailController>();

  Future<void> _onAddOrder() async {
    final ok = await showAddOrderDialog(
      context,
      initialBrandId: _c.brandId,
    );
    if (ok && mounted) await _c.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: Obx(() {
        if (c.loading.value && c.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final err = c.errorMessage.value;
        if (err != null && c.detail.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                AppButton.primary(
                  onPressed: c.load,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        final detail = c.detail.value;
        if (detail == null) {
          return const Center(child: Text('暂无数据'));
        }
        final brand = detail.brand;
        // 订阅字典 / 企业·4A 行刷新，头部标签与指标重建。
        c.dictVersion.value;
        c.enterpriseVersion.value;
        c.agencyVersion.value;
        return Column(
          children: [
            _HeaderBar(
              controller: c,
              brand: brand,
              onBack: () => Navigator.pop(context),
              onAddOrder: _onAddOrder,
              onExportOrders: () => _exportOrderDetails(context, c),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                    _MetricRows(controller: c, detail: detail),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _BrandProfileCard(
                            controller: c,
                            detail: detail,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: _RelationGraphCard(
                            controller: c,
                            graph: detail.relationGraph,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ChartCard(
                            title: c.isAgency
                                ? '4A 订单金额趋势（万元）'
                                : c.isEnterprise
                                    ? '企业订单金额趋势（万元）'
                                    : '订单金额趋势（万元）',
                            trailing: () {
                              final q4 = c.isAgency
                                  ? c.agencyQ4ExpectedYoyRate()
                                  : null;
                              if (q4 == null || q4.isEmpty) return null;
                              return Text(
                                'Q4 预期同比 ${q4.startsWith('-') ? '' : '+'}$q4%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTrendUp,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }(),
                            child: _TrendChart(items: detail.monthlyTrend),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChartCard(
                            title: '合同类型占比',
                            // 环形图例在饼图上方，固定 220 易底部溢出。
                            height: 260,
                            child: _ContractDonut(counts: c.contractTypeCounts),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ChartCard(
                            title: c.isAgency ? '合作企业分布' : '关系分布',
                            child: _RelationBars(
                              counts: c.isAgency
                                  ? {
                                      for (final name
                                          in c.relatedEnterpriseNames(detail))
                                        name: detail.orders
                                            .where(
                                              (o) =>
                                                  o.enterprise?.trim() == name,
                                            )
                                            .length
                                            .clamp(1, 999),
                                    }
                                  : c.relationLabelCounts,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _OrdersCard(controller: c),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _ContactsCard(
                            controller: c,
                            contacts: detail.contacts,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: _SalesCard(
                            controller: c,
                            people: c.salesPeople,
                            detail: detail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DynamicsCard(
                            brand: brand,
                            enterprise: c.isEnterprise
                                ? c.enterpriseSeed
                                : null,
                            agency: c.isAgency ? c.agencySeed : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MapCard(
                            hq: c.resolvedHqLocation() ?? detail.hqLocation,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NotesCard(
                            controller: c,
                            showEdit: !c.isEnterprise && !c.isAgency,
                            remark: c.isEnterprise
                                ? (c.enterpriseSeed?.remark
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? c.enterpriseSeed!.remark
                                    : brand?.remark)
                                : c.isAgency
                                    ? (c.agencySeed?.remark
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? c.agencySeed!.remark
                                        : brand?.remark)
                                    : brand?.remark,
                          ),
                        ),
                      ],
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

// ── Header ───────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.controller,
    required this.brand,
    required this.onBack,
    required this.onAddOrder,
    required this.onExportOrders,
  });

  final BrandDetailController controller;
  final OacBrand? brand;
  final VoidCallback onBack;
  final VoidCallback onAddOrder;
  final VoidCallback onExportOrders;

  Future<void> _onAddContact(BuildContext context) async {
    await showAddBrandContact(context, controller: controller);
  }

  Future<void> _onEdit(BuildContext context) async {
    final customerId = controller.editCustomerId;
    if (customerId.isEmpty) {
      showHyperToast(context, content: const Text('缺少客户档案 ID'));
      return;
    }
    // 企业视角：只改当前经营主体，不改父级品牌档案头。
    if (controller.isEnterprise) {
      final seed = controller.enterpriseSeed;
      final enterpriseKey = seed?.name?.trim().isNotEmpty == true
          ? seed!.name!.trim()
          : (seed?.id?.trim() ?? '');
      if (enterpriseKey.isEmpty) {
        showHyperToast(context, content: const Text('缺少企业名称'));
        return;
      }
      await showEnterprisePerspectiveEditDialog(
        context,
        customerId: customerId,
        enterpriseName: enterpriseKey,
        onSaved: controller.load,
      );
      return;
    }
    final title =
        controller.isAgency ? '编辑 4A 档案' : '编辑品牌档案';
    await showEditCustomerArchiveDialog(
      context,
      customerId: customerId,
      title: title,
      profileOnly: true,
      onSaved: controller.load,
    );
  }

  String _fmtDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final s = raw.trim();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    final isEnterprise = controller.isEnterprise;
    final isAgency = controller.isAgency;
    final name = isEnterprise
        ? controller.enterpriseDisplayName(brand)
        : isAgency
            ? controller.agencyDisplayName(brand)
            : brand?.name?.trim().isNotEmpty == true
                ? brand!.name!
                : '品牌详情';
    final letter = name.characters.first;
    final weight = isEnterprise
        ? controller.enterpriseWeight(brand)
        : isAgency
            ? controller.agencyWeight(brand)
            : (brand?.weight ?? 0);
    final iconUrl = isEnterprise
        ? controller.enterpriseIconUrl(brand)
        : isAgency
            ? controller.agencyIconUrl(brand)
            : brand?.iconUrl?.trim();
    final displayTags = isAgency
        ? controller.agencyTagDisplays(brand)
        : isEnterprise
            ? controller.enterpriseTagDisplays(brand)
            : controller.headerDisplayTags(brand);
    final clientTag = controller.clientTagLabel(
      brand?.clientTag,
      label: brand?.clientTagLabel,
    );
    final industryText = controller.industryDisplay(brand);
    final code = isAgency
        ? controller.agencyCode(brand)
        : brand?.brandCode?.trim();
    final health = brand?.healthLabel?.trim();
    final coverageText = controller.enterpriseCoverageText();
    final agencyRating = controller.agencyCooperationRating(brand);
    final agencyScale = controller.agencyMarketScale();
    final topRank = brand?.topRank;
    final detail = controller.detail.value;
    final brandNames = detail == null
        ? const <String>[]
        : controller.relatedBrandNames(detail);
    final enterpriseNames = detail == null
        ? const <String>[]
        : controller.relatedEnterpriseNames(detail);
    final agencyCount = isEnterprise
        ? controller.enterpriseAgencyCount(detail)
        : (brand?.agencyCount ?? detail?.agencies.length ?? 0);
    final enterpriseCount = isAgency
        ? controller.agencyEnterpriseCount(detail)
        : (brand?.enterpriseCount ??
            detail?.enterprises.length ??
            enterpriseNames.length);
    final brandCount = isEnterprise
        ? controller.enterpriseBrandCount(detail)
        : isAgency
            ? controller.agencyBrandCount(detail)
            : (brand?.brandCount ?? brandNames.length);
    final address = isAgency
        ? (controller.agencyAddress() ?? '')
        : (controller.agencySeed?.address ?? '');
    final cityText = isEnterprise
        ? controller.enterpriseCity(brand)
        : isAgency
            ? controller.agencyCity(brand)
            : brand?.city?.trim().isNotEmpty == true
                ? brand!.city!
                : '';
    final ownerNames = isEnterprise
        ? controller.enterpriseOwnerNames(brand)
        : isAgency
            ? controller.agencyOwnerNames(brand)
            : (brand?.ownerNameList ??
                (brand?.ownerNames?.trim().isNotEmpty == true
                    ? [brand!.ownerNames!.trim()]
                    : const <String>[]));
    final enterpriseId = controller.enterpriseSeed?.id?.trim() ??
        controller.enterpriseSeed?.enterpriseCode?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2F5C), _kBanner, Color(0xFF145A9E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HyperPressable(
                onTap: onBack,
                builder: (context, states, child) => child!,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      isAgency
                          ? '返回4A列表'
                          : isEnterprise
                              ? '返回企业列表'
                              : '返回列表',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '|',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                ),
              ),
              Flexible(
                child: Text(
                  isAgency
                      ? '观察视角：4A > 4A一级列表 > $name'
                      : isEnterprise
                          ? '观察视角：企业 > 企业一级列表 > $name'
                          : '观察视角：品牌 > 品牌一级列表 > $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              if (isAgency) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF69B1FF)),
                  ),
                  child: Text(
                    agencyRating == null || agencyRating.isEmpty
                        ? '合作评级 —'
                        : '合作评级 $agencyRating',
                    style: const TextStyle(
                      color: Color(0xFFD6E4FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA8C16).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFA8C16)),
                  ),
                  child: Text(
                    agencyScale?.isNotEmpty == true
                        ? agencyScale!
                        : (clientTag != '-' ? clientTag : '4A 公司'),
                    style: const TextStyle(
                      color: Color(0xFFFFD591),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else if (isEnterprise) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    coverageText ?? '覆盖评分 —',
                    style: const TextStyle(
                      color: Color(0xFFE6F4FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAAD14).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFAAD14)),
                  ),
                  child: Text(
                    controller.enterpriseTypeDisplay(brand),
                    style: const TextStyle(
                      color: Color(0xFFFFD666),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '品牌健康度 · ${health?.isNotEmpty == true ? health! : '—'}',
                    style: const TextStyle(
                      color: Color(0xFFE6F4FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (topRank != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAAD14).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFAAD14)),
                    ),
                    child: Text(
                      'TOP $topRank 客户',
                      style: const TextStyle(
                        color: Color(0xFFFFD666),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: iconUrl != null && iconUrl.isNotEmpty
                    ? Image.network(
                        iconUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _HeaderAvatar(letter: letter),
                      )
                    : _HeaderAvatar(letter: letter),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < weight
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: const Color(0xFFFAAD14),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '权重 ${weight.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Color(0xFFB8D4F0),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (var ti = 0; ti < displayTags.length; ti++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isEnterprise || (isAgency && ti > 0))
                                  ? const Color(0xFF52C41A)
                                      .withValues(alpha: 0.22)
                                  : isAgency
                                      ? _kPrimary.withValues(alpha: 0.22)
                                      : const Color(0xFF722ED1)
                                          .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (isEnterprise || (isAgency && ti > 0))
                                    ? const Color(0xFFB7EB8F)
                                    : isAgency
                                        ? const Color(0xFF69B1FF)
                                        : const Color(0xFFD3ADF7),
                              ),
                            ),
                            child: Text(
                              displayTags[ti],
                              style: TextStyle(
                                color: (isEnterprise || (isAgency && ti > 0))
                                    ? const Color(0xFFD9F7BE)
                                    : isAgency
                                        ? const Color(0xFFD6E4FF)
                                        : const Color(0xFFEFDBFF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (isEnterprise &&
                            industryText != '-' &&
                            !displayTags.contains(industryText))
                          Text(
                            industryText,
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                        if (!isEnterprise &&
                            !isAgency &&
                            code != null &&
                            code.isNotEmpty)
                          Text(
                            '品牌编号 $code',
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                        if (isAgency && code != null && code.isNotEmpty)
                          Text(
                            '4A编号 $code',
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                        if (isEnterprise &&
                            enterpriseId != null &&
                            enterpriseId.isNotEmpty)
                          Text(
                            '企业编号 $enterpriseId',
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                        if (!isEnterprise &&
                            !isAgency &&
                            clientTag != '-' &&
                            RegExp(r'[\u4e00-\u9fff]').hasMatch(clientTag))
                          Text(
                            '· $clientTag',
                            style: const TextStyle(
                              color: Color(0xFFB8D4F0),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAgency
                          ? [
                              if (cityText.isNotEmpty) cityText,
                              if (code != null && code.isNotEmpty) '4A编号 $code',
                              if (address.trim().isNotEmpty) address.trim(),
                              if (ownerNames.isNotEmpty)
                                '负责人：${ownerNames.join('、')}',
                              '服务 $brandCount 品牌',
                              '关联企业 $enterpriseCount',
                            ].join('  ·  ')
                          : isEnterprise
                              ? [
                                  if (cityText.isNotEmpty) cityText,
                                  if (ownerNames.isNotEmpty)
                                    '负责人：${ownerNames.join('、')}',
                                  '关联品牌 $brandCount',
                                  '关联 4A $agencyCount',
                                ].join('  ·  ')
                              : [
                                  if (brand?.spokesperson?.trim().isNotEmpty ==
                                      true)
                                    '最新代言人：${brand!.spokesperson}',
                                  if (brand?.ownerNames?.trim().isNotEmpty ==
                                      true)
                                    '负责人：${brand!.ownerNames}',
                                  '建档日期 ${_fmtDay(brand?.createTime)}',
                                  '最近更新 ${_fmtDay(brand?.updateTime)}',
                                ].join('  ·  '),
                      style: const TextStyle(
                        color: Color(0xFF9EB9D4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AppButton.outline(
                    onPressed: () => _onEdit(context),
                    child: const Text(
                      '编辑',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  AppButton.outline(
                    onPressed: () => _onAddContact(context),
                    child: const Text(
                      '添加联系人',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  AppButton.primary(
                    onPressed: onAddOrder,
                    leading: const Icon(Icons.add, size: 16),
                    child: const Text('添加订单'),
                  ),
                  AppButton.outline(
                    onPressed: onExportOrders,
                    child: const Text(
                      '导出',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      color: const Color(0xFF52C41A),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Metrics ──────────────────────────────────────────────────────────────────

class _MetricRows extends StatelessWidget {
  const _MetricRows({required this.controller, required this.detail});

  final BrandDetailController controller;
  final OacBrandDetail detail;

  (int media, int agency) _enterpriseSplit() {
    var media = 0;
    var agency = 0;
    for (final e in detail.enterprises) {
      final t = (e.type ?? '').toLowerCase();
      if (t.contains('代理') || t.contains('agency') || t.contains('4a')) {
        agency++;
      } else {
        media++;
      }
    }
    return (media, agency);
  }

  String _agencySubtitle() {
    final names = [
      for (final a in detail.agencies)
        if (a.name?.trim().isNotEmpty == true) a.name!.trim(),
    ];
    if (names.isEmpty) return '-';
    if (names.length == 1) return names.first;
    return '${names.first}等 ${names.length} 家';
  }

  String _latestOrderTimeText(OacBrand? b) {
    final raw = b?.latestOrderTime?.trim();
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 19 ? raw.substring(0, 19) : raw;
  }

  Future<void> _onAddSales(BuildContext context) async {
    final order = detail.orders.isNotEmpty ? detail.orders.first : OrderItem();
    final saved = await showOrderSalesDialog(
      context,
      controller: controller,
      order: order,
    );
    if (!saved || !context.mounted) return;
    await controller.load();
    if (!context.mounted) return;
    showHyperToast(context, content: const Text('销售员已更新'));
  }

  @override
  Widget build(BuildContext context) {
    final b = detail.brand;
    final isEnterprise = controller.isEnterprise;
    final isAgency = controller.isAgency;
    final latestOrder = detail.orders.isNotEmpty ? detail.orders.first : null;
    final (mediaCnt, agencyCnt) = _enterpriseSplit();
    final relatedBrands = controller.relatedBrandNames(detail);
    final relatedEnterprises = controller.relatedEnterpriseNames(detail);
    final subBrandText = detail.subBrands.isEmpty
        ? '-'
        : detail.subBrands.take(4).join('、');
    final brandSubtitle = relatedBrands.isEmpty
        ? controller.industryDisplay(b)
        : relatedBrands.take(3).join('、');
    final enterpriseSubtitle = relatedEnterprises.isEmpty
        ? '-'
        : relatedEnterprises.take(3).join('、');
    final sales = [
      for (final p in controller.salesPeople) p.name,
    ];
    if (sales.isEmpty) {
      sales.addAll(
        isEnterprise
            ? controller.enterpriseOwnerNames(b)
            : isAgency
                ? controller.agencyOwnerNames(b)
                : (b?.ownerNameList ?? _splitPeople(b?.ownerNames)),
      );
    }
    final contactCount = isEnterprise
        ? controller.enterpriseContactCount(detail)
        : isAgency
            ? controller.agencyContactCount(detail)
            : (b?.contactCount ?? detail.contacts.length);
    final mom = detail.orderAmountMomRate?.trim();
    final yoy = isEnterprise
        ? controller.enterpriseOrderAmountYoyRate()
        : isAgency
            ? controller.agencyOrderAmountYoyRate()
            : null;
    final deptShare = isEnterprise
        ? controller.enterpriseDeptPerfShareRate()
        : isAgency
            ? controller.agencyDeptPerfShareRate()
            : null;
    final orderAmount = isEnterprise
        ? controller.enterpriseOrderAmount()
        : isAgency
            ? controller.agencyOrderAmount()
            : b?.orderAmount;
    final orderCount = isEnterprise
        ? controller.enterpriseOrderCount()
        : isAgency
            ? controller.agencyOrderCount()
            : (b?.orderCount ?? detail.orders.length);
    final brandCount = isEnterprise
        ? controller.enterpriseBrandCount(detail)
        : isAgency
            ? controller.agencyBrandCount(detail)
            : (b?.brandCount ?? relatedBrands.length);
    final brandSubtitleText = isAgency
        ? controller.agencyBrandSubtitle(detail)
        : brandSubtitle;
    final agencyMetricCount = isEnterprise
        ? controller.enterpriseAgencyCount(detail)
        : (b?.agencyCount ?? detail.agencies.length);
    final agencySubtitle = isEnterprise
        ? controller.enterpriseAgencySubtitle(detail)
        : _agencySubtitle();
    final enterpriseMetricCount = isAgency
        ? controller.agencyEnterpriseCount(detail)
        : (b?.enterpriseCount ?? relatedEnterprises.length);
    final enterpriseSubtitleText = isAgency
        ? controller.agencyEnterpriseSubtitle(detail)
        : enterpriseSubtitle;
    final latestOrderTime = isEnterprise
        ? controller.enterpriseLatestOrderTime(b)
        : isAgency
            ? controller.agencyLatestOrderTime(b)
            : _latestOrderTimeText(b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '订单金额（累计）',
                value: _fmtWan(orderAmount),
                valueColor: _kGold,
                subtitleWidget: (isEnterprise || isAgency)
                    ? Wrap(
                        spacing: 10,
                        children: [
                          if (yoy != null && yoy.isNotEmpty)
                            Text(
                              '同比 ${yoy.startsWith('-') ? '' : '+'}$yoy%',
                              style: TextStyle(
                                fontSize: 12,
                                color: yoy.startsWith('-')
                                    ? _kTrendDown
                                    : _kTrendUp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            deptShare != null && deptShare.isNotEmpty
                                ? '部门业绩占比 $deptShare%'
                                : '部门业绩占比 —',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTrendUp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : null,
                subtitle: isEnterprise ||
                        isAgency ||
                        mom == null ||
                        mom.isEmpty
                    ? null
                    : '环比 $mom%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '订单数量',
                value: '$orderCount',
                subtitle: isAgency ? '查看订单列表' : '查看订单明细',
                subtitleColor: _kPrimary,
                onTap: () => openBrandOrderDetailPage(context),
              ),
            ),
            const SizedBox(width: 10),
            if (isEnterprise || isAgency)
              Expanded(
                child: _MetricCard(
                  label: '关联品牌',
                  value: '$brandCount',
                  subtitle: brandSubtitleText,
                ),
              )
            else ...[
              Expanded(
                child: _MetricCard(
                  label: '关联子品牌',
                  value: '${detail.subBrands.length}',
                  subtitle: subBrandText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: '关联企业',
                  value: '${b?.enterpriseCount ?? detail.enterprises.length}',
                  subtitle: '媒体主 $mediaCnt · 代理方 $agencyCnt',
                ),
              ),
            ],
            const SizedBox(width: 10),
            if (isAgency)
              Expanded(
                child: _MetricCard(
                  label: '关联企业',
                  value: '$enterpriseMetricCount',
                  subtitle: enterpriseSubtitleText,
                ),
              )
            else if (!isEnterprise)
              Expanded(
                child: _MetricCard(
                  label: '关联4A',
                  value: '${b?.agencyCount ?? detail.agencies.length}',
                  subtitle: _agencySubtitle(),
                ),
              )
            else
              Expanded(
                child: _MetricCard(
                  label: '关联4A',
                  value: '$agencyMetricCount',
                  subtitle: agencySubtitle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '联系人数量',
                value: '$contactCount 人',
                valueStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
                subtitle: isAgency
                    ? '关键对接人 $contactCount 人'
                    : isEnterprise
                        ? '企业联系人 $contactCount 人'
                        : '覆盖 ${detail.enterprises.length} 家企业 / ${detail.agencies.length} 家4A',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: '最新订单时间',
                value: latestOrderTime,
                valueStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                ),
                subtitle: latestOrder == null
                    ? null
                    : '${latestOrder.name ?? '-'} · ${_fmtWan(latestOrder.amount)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: (isEnterprise || isAgency) ? '资源形式分布' : '合作媒体形式',
                valueWidget: detail.mediaFormats.isEmpty
                    ? const Text(
                        '暂无媒体形式数据',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kMuted,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final m in detail.mediaFormats)
                            AppBadge.primary(
                              shape: AppBadgeShape.square,
                              child: Text(
                                '${m.name ?? '-'} ${m.percent ?? 0}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: isEnterprise ? '销售负责人' : '销售员',
                valueWidget: Row(
                  children: [
                    if (sales.isNotEmpty)
                      _Avatar(name: sales.first, size: 28)
                    else
                      const _Avatar(name: '?', size: 28),
                    const SizedBox(width: 8),
                    _orderAddChip(
                      label: '+',
                      onTap: () => _onAddSales(context),
                    ),
                  ],
                ),
                subtitle: sales.isEmpty
                    ? '暂无销售员'
                    : '主销售：${sales.first}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    this.value,
    this.valueWidget,
    this.subtitle,
    this.subtitleWidget,
    this.subtitleColor,
    this.valueColor,
    this.valueStyle,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Color? subtitleColor;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: valueWidget ??
                  Text(
                    value ?? '-',
                    style: valueStyle ??
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? _kTitle,
                          height: 1.1,
                        ),
                  ),
            ),
          ),
          if (subtitleWidget != null)
            subtitleWidget!
          else if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? _kMuted,
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return card;
    return HyperPressable(
      onTap: onTap,
      builder: (context, states, child) => child!,
      child: card,
    );
  }
}

// ── Profile / Graph ──────────────────────────────────────────────────────────

class _BrandProfileCard extends StatelessWidget {
  const _BrandProfileCard({
    required this.controller,
    required this.detail,
  });

  final BrandDetailController controller;
  final OacBrandDetail detail;

  @override
  Widget build(BuildContext context) {
    final b = detail.brand;
    final isEnterprise = controller.isEnterprise;
    final isAgency = controller.isAgency;
    final tagLabels = <String>[
      for (final t in [...?b?.tagList])
        if (controller.tagLabel(t) != '-') controller.tagLabel(t),
    ];
    final clientTag = controller.clientTagLabel(
      b?.clientTag,
      label: b?.clientTagLabel,
    );
    final relatedBrands = controller.relatedBrandNames(detail);
    final orderCount = b?.orderCount ?? detail.orders.length;

    if (isAgency) {
      final agencyTags = controller.agencyTagDisplays(b);
      final city = controller.agencyCity(b);
      final agencyOrderCount = controller.agencyOrderCount() ?? orderCount;
      final agencyOrderAmount =
          _fmtWan(controller.agencyOrderAmount() ?? b?.orderAmount);
      return _SectionCard(
        title: '4A 画像',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ProfileRow(label: '公司类型', value: '4A 广告公司'),
            _ProfileRow(
              label: '服务标签',
              valueWidget: agencyTags.isEmpty
                  ? const Text('-')
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < agencyTags.length; i++)
                          AppBadge.custom(
                            color: i == 0
                                ? _kPrimary
                                : const Color(0xFF52C41A),
                            appearance: AppBadgeStyle.soft,
                            shape: AppBadgeShape.square,
                            child: Text(
                              agencyTags[i],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
            ),
            _ProfileRow(
              label: '所在城市',
              value: city.isNotEmpty ? city : '-',
            ),
            _ProfileRow(
              label: '关联品牌',
              valueWidget: relatedBrands.isEmpty
                  ? const Text('-')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final name in relatedBrands)
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
            ),
            _ProfileRow(
              label: '订单规模',
              value: '$agencyOrderCount 笔 · $agencyOrderAmount',
            ),
          ],
        ),
      );
    }

    if (isEnterprise) {
      final typeText = controller.enterpriseTypeDisplay(b);
      final enterpriseTags = controller.enterpriseTagDisplays(b);
      final city = controller.enterpriseCity(b);
      final entOrderCount = controller.enterpriseOrderCount() ?? orderCount;
      final entOrderAmount =
          _fmtWan(controller.enterpriseOrderAmount() ?? b?.orderAmount);
      return _SectionCard(
        title: '企业画像',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileRow(label: '企业类型', value: typeText),
            _ProfileRow(
              label: '企业标签',
              valueWidget: enterpriseTags.isEmpty
                  ? const Text('-')
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in enterpriseTags)
                          AppBadge.success(
                            appearance: AppBadgeStyle.soft,
                            shape: AppBadgeShape.square,
                            child:
                                Text(t, style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
            ),
            _ProfileRow(
              label: '所在城市',
              value: city.isNotEmpty ? city : '-',
            ),
            _ProfileRow(
              label: '关联品牌',
              valueWidget: relatedBrands.isEmpty
                  ? const Text('-')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final name in relatedBrands)
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
            ),
            _ProfileRow(
              label: '订单规模',
              value: '$entOrderCount 笔 · $entOrderAmount',
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      title: '品牌画像',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow(
            label: '所属行业',
            value: controller.industryDisplay(b),
          ),
          _ProfileRow(label: '品牌归属', value: clientTag),
          _ProfileRow(
            label: '标签',
            valueWidget: tagLabels.isEmpty
                ? const Text('-')
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final t in tagLabels)
                        AppBadge.secondary(
                          appearance: AppBadgeStyle.soft,
                          shape: AppBadgeShape.square,
                          child: Text(t, style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
          ),
          _ProfileRow(
            label: '代言人',
            value: b?.spokesperson ?? '-',
            icon: Icons.person_outline,
          ),
          _ProfileRow(label: '主市场', value: b?.city ?? '-'),
          _ProfileRow(
            label: '投放偏好',
            value: detail.mediaFormats.isEmpty
                ? '-'
                : detail.mediaFormats.map((e) => e.name).join('、'),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                '子品牌',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              AppButton.ghost(
                onPressed: () =>
                    showAddSubBrandDialog(context, controller: controller),
                leading: const Icon(Icons.add, size: 14),
                child: const Text('添加'),
              ),
            ],
          ),
          if (detail.subBrands.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '暂无子品牌',
                style: TextStyle(color: _kMuted, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 8,
              children: [
                for (final s in detail.subBrands)
                  AppBadge.outline(
                    child: Text(s),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          if (icon != null) ...[
            Icon(icon, size: 14, color: _kMuted),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '-',
                  style: const TextStyle(fontSize: 13, color: _kTitle),
                ),
          ),
        ],
      ),
    );
  }
}

class _RelationGraphCard extends StatelessWidget {
  const _RelationGraphCard({
    required this.controller,
    required this.graph,
  });

  final BrandDetailController controller;
  final RelationGraph? graph;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = controller.isEnterprise;
    final isAgency = controller.isAgency;
    final title = isAgency
        ? '4A 关系网络图谱'
        : isEnterprise
            ? '企业关系网络图谱'
            : '品牌关系网络图谱';
    final centerCategory = isAgency
        ? 'agency'
        : isEnterprise
            ? 'enterprise'
            : 'brand';
    return _SectionCard(
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(
            color: isAgency
                ? const Color(0xFFFA8C16)
                : isEnterprise
                    ? const Color(0xFF13C2C2)
                    : _kPrimary,
            label: isAgency
                ? '4A'
                : isEnterprise
                    ? '企业'
                    : '品牌',
          ),
          const SizedBox(width: 10),
          _LegendDot(
            color: _kPrimary,
            label: '品牌',
          ),
          const SizedBox(width: 10),
          _LegendDot(
            color: const Color(0xFF13C2C2),
            label: '企业',
          ),
          if (!isAgency) ...[
            const SizedBox(width: 10),
            const _LegendDot(color: Color(0xFFFA8C16), label: '4A'),
          ],
          const SizedBox(width: 10),
          const _LegendDot(color: Color(0xFFEB2F96), label: '联系人'),
          const SizedBox(width: 10),
          const _LegendDot(color: Color(0xFF52C41A), label: '销售'),
        ],
      ),
      child: SizedBox(
        height: 280,
        child: graph == null || graph!.nodes.isEmpty
            ? const Center(
                child: Text('暂无关系数据', style: TextStyle(color: _kMuted)),
              )
            : CustomPaint(
                painter: _RelationGraphPainter(
                  graph!,
                  centerCategory: centerCategory,
                ),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _kMuted)),
      ],
    );
  }
}

class _RelationGraphPainter extends CustomPainter {
  _RelationGraphPainter(this.graph, {this.centerCategory = 'brand'});

  final RelationGraph graph;
  final String centerCategory;

  Color _color(String? category) {
    return switch (category) {
      'brand' => _kPrimary,
      'enterprise' => const Color(0xFF13C2C2),
      'agency' => const Color(0xFFFA8C16),
      'contact' => const Color(0xFFEB2F96),
      'salesperson' => const Color(0xFF52C41A),
      _ => _kMuted,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nodes = graph.nodes;
    RelationNode? hub;
    for (final n in nodes) {
      if (n.category == centerCategory) {
        hub = n;
        break;
      }
    }
    hub ??= nodes.isEmpty ? null : nodes.first;
    final others = nodes.where((n) => n.id != hub?.id).toList();
    final positions = <String, Offset>{};
    if (hub?.id != null) positions[hub!.id!] = center;

    final radius = math.min(size.width, size.height) * 0.34;
    for (var i = 0; i < others.length; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / math.max(others.length, 1));
      final id = others[i].id;
      if (id == null) continue;
      positions[id] = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFFD0D7DE)
      ..strokeWidth = 1;
    for (final link in graph.links) {
      final a = positions[link.source];
      final b = positions[link.target];
      if (a == null || b == null) continue;
      canvas.drawLine(a, b, linePaint);
    }

    for (final node in nodes) {
      final id = node.id;
      if (id == null) continue;
      final pos = positions[id];
      if (pos == null) continue;
      final isHub = node.category == centerCategory || node.id == hub?.id;
      final r = isHub ? 28.0 : 22.0;
      final paint = Paint()..color = _color(node.category);
      canvas.drawCircle(pos, r, paint);
      final tp = TextPainter(
        text: TextSpan(
          text: _shortName(node.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: isHub ? 12 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: r * 2 - 4);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  String _shortName(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    return n.length <= 4 ? n : n.substring(0, 4);
  }

  @override
  bool shouldRepaint(covariant _RelationGraphPainter oldDelegate) =>
      oldDelegate.graph != graph ||
      oldDelegate.centerCategory != centerCategory;
}

// ── Charts ───────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.trailing,
    this.height = 220,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      trailing: trailing,
      child: SizedBox(height: height, child: child),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.items});

  final List<MonthAmountItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无趋势数据', style: TextStyle(color: _kMuted)));
    }
    return AppLineChart(
      showLegend: false,
      height: 220,
      series: [
        AppLineSeries(
          name: '订单金额',
          points: [
            for (var i = 0; i < items.length; i++)
              AppLinePoint(
                x: i.toDouble(),
                y: num.tryParse(items[i].amount ?? '')?.toDouble() ?? 0,
                label: items[i].month ?? '$i',
              ),
          ],
        ),
      ],
      yAxis: AppChartAxis(formatter: (v) => v.toStringAsFixed(0)),
    );
  }
}

class _ContractDonut extends StatelessWidget {
  const _ContractDonut({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(child: Text('暂无合同数据', style: TextStyle(color: _kMuted)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return AppPieChart.donut(
          // 吃满卡片内高度；图例+饼图同处一列，勿再写死 220。
          height: h.isFinite && h > 0 ? h : 260,
          showValues: true,
          sections: [
            for (final e in counts.entries)
              AppPieSection(label: e.key, value: e.value.toDouble()),
          ],
        );
      },
    );
  }
}

class _RelationBars extends StatelessWidget {
  const _RelationBars({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return const Center(child: Text('暂无关系数据', style: TextStyle(color: _kMuted)));
    }
    final entries = counts.entries.toList();
    return AppBarChart.horizontal(
      height: 220,
      showLegend: false,
      showValues: true,
      groups: [
        for (final e in entries)
          AppBarGroup(
            label: e.key,
            values: [AppBarValue(value: e.value.toDouble())],
          ),
      ],
    );
  }
}

// ── Orders ───────────────────────────────────────────────────────────────────

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.controller});

  final BrandDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final orders = controller.filteredOrders;
      final total = controller.detail.value?.orders.length ?? 0;
      final brand = controller.detail.value?.brand;
      // 读字典版本，标签映射变更时刷新表格。
      controller.dictVersion.value;
      var shownAmount = 0.0;
      for (final o in orders) {
        shownAmount += num.tryParse(o.amount ?? '')?.toDouble() ?? 0;
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrdersHeader(
              controller: controller,
              shown: orders.length,
              total: total,
              amountText: _fmtWan('$shownAmount'),
              onViewAll: () => openBrandOrderDetailPage(context),
            ),
            const SizedBox(height: 12),
            _OrdersGrid(
              controller: controller,
              orders: orders,
              brand: brand,
              height: math.min(80.0 + math.max(orders.length, 1) * 56, 320),
            ),
          ],
        ),
      );
    });
  }
}

/// 标题行：左「订单明细 + 近期汇总」，右「筛选 + 全部 N 笔」。
class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.controller,
    required this.shown,
    required this.total,
    required this.amountText,
    required this.onViewAll,
  });

  final BrandDetailController controller;
  final int shown;
  final int total;
  final String amountText;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.receipt_long,
            size: 14,
            color: Color(0xFF52C41A),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '订单明细',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kTitle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '近期 $shown 笔 · 金额合计 $amountText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _kMuted),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 200,
          child: TextField(
            controller: controller.orderKeywordCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: '筛选订单号 / 标签',
              hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
              prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        HyperPressable(
          onTap: onViewAll,
          builder: (context, states, child) => child!,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '全部 $total 笔',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF52C41A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF52C41A),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersGrid extends StatelessWidget {
  const _OrdersGrid({
    required this.controller,
    required this.orders,
    required this.brand,
    required this.height,
    this.withTime = false,
    this.indexOffset = 0,
  });

  final BrandDetailController controller;
  final List<OrderItem> orders;
  final OacBrand? brand;
  final double height;
  final bool withTime;
  final int indexOffset;

  List<String> get _brandTags {
    // 仅用 tagList（如 listed_company）；不带 clientTag（international）。
    final raw = <String>[...?brand?.tagList];
    final seen = <String>{};
    final out = <String>[];
    for (final t in raw) {
      final key = t.trim();
      if (key.isEmpty) continue;
      final label = controller.tagLabel(key);
      // 与订单管理一致：不展示纯英文标签。
      if (label == '-' || !_isDisplayableTag(label) || !seen.add(label)) {
        continue;
      }
      out.add(label);
    }
    return out;
  }

  String get _salesFallback {
    final list = brand?.ownerNameList;
    if (list != null && list.isNotEmpty) return list.first;
    return brand?.ownerNames?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('暂无订单', style: TextStyle(color: _kMuted)),
        ),
      );
    }
    final brandTags = _brandTags;
    final brandName = brand?.name?.trim().isNotEmpty == true
        ? brand!.name!.trim()
        : '-';
    String rowBrandName(OrderItem row) {
      final own = row.brandName?.trim();
      if (own != null && own.isNotEmpty) return own;
      return brandName;
    }
    final weight = brand?.weight;
    final iconUrl = brand?.iconUrl?.trim();
    final letter = brandName.characters.first;

    return SizedBox(
      width: double.infinity,
      child: AppDataGrid<OrderItem>.local(
        height: height,
        rows: orders,
        rowKey: (row) => row.id ?? row.orderNo ?? row.name ?? '',
        sortable: false,
        showInternalDividers: false,
        headerBackgroundColor: const Color(0xFFFAFAFA),
        columns: [
          AppDataGridColumn(
            id: 'index',
            title: '序号',
            width: 52,
            value: (row) => '${indexOffset + orders.indexOf(row) + 1}',
          ),
          AppDataGridColumn(
            id: 'weight',
            title: '权重',
            width: 110,
            value: (row) => '${weight ?? 0}',
            cellBuilder: (context, row, _) {
              final score = (weight ?? 0).clamp(0, 5);
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < score
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: i < score
                            ? const Color(0xFFFAAD14)
                            : const Color(0xFFD9D9D9),
                      ),
                  ],
                ),
              );
            },
          ),
          AppDataGridColumn(
            id: 'icon',
            title: '图标',
            width: 56,
            value: (row) => iconUrl ?? brandName,
            cellBuilder: (context, row, _) {
              if (iconUrl != null && iconUrl.isNotEmpty) {
                return Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      iconUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _Avatar(name: brandName, size: 28),
                    ),
                  ),
                );
              }
              return Center(child: _Avatar(name: letter, size: 28));
            },
          ),
          if (controller.isAgency)
            AppDataGridColumn(
              id: 'agencyName',
              title: '4A 名称',
              width: 160,
              minWidth: 120,
              widthMode: AppDataGridColumnWidthMode.fill,
              flex: 1.3,
              alignment: Alignment.centerLeft,
              titleAlignment: Alignment.centerLeft,
              value: (_) => brandName,
              cellBuilder: (context, row, _) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  brandName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
            )
          else if (controller.isEnterprise)
            AppDataGridColumn(
              id: 'enterprise',
              title: '企业名称',
              width: 160,
              minWidth: 120,
              widthMode: AppDataGridColumnWidthMode.fill,
              flex: 1.3,
              alignment: Alignment.centerLeft,
              titleAlignment: Alignment.centerLeft,
              value: (row) => row.enterprise ?? brandName,
              cellBuilder: (context, row, _) {
                final text = row.enterprise?.trim().isNotEmpty == true
                    ? row.enterprise!.trim()
                    : brandName;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                );
              },
            )
          else
            AppDataGridColumn(
              id: 'brandName',
              title: '品牌名称',
              width: 120,
              minWidth: 88,
              widthMode: AppDataGridColumnWidthMode.fill,
              alignment: Alignment.centerLeft,
              titleAlignment: Alignment.centerLeft,
              value: rowBrandName,
              cellBuilder: (context, row, _) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  rowBrandName(row),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          AppDataGridColumn(
            id: 'tags',
            title: '标签',
            width: 168,
            minWidth: 120,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 1.2,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => brandTags.join(','),
            cellBuilder: (context, row, _) {
              if (brandTags.isEmpty) return const Text('-');
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < brandTags.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AppBadge.custom(
                          color: controller.isAgency && i == 0
                              ? _kPrimary
                              : controller.isAgency || controller.isEnterprise
                                  ? const Color(0xFF52C41A)
                                  : const Color(0xFF722ED1),
                          appearance: AppBadgeStyle.soft,
                          shape: AppBadgeShape.square,
                          child: Text(
                            brandTags[i],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (controller.isEnterprise || controller.isAgency)
            AppDataGridColumn(
              id: 'relatedBrand',
              title: '关联品牌',
              width: 120,
              minWidth: 88,
              widthMode: AppDataGridColumnWidthMode.fill,
              alignment: Alignment.centerLeft,
              titleAlignment: Alignment.centerLeft,
              value: rowBrandName,
              cellBuilder: (context, row, _) {
                final name = rowBrandName(row);
                final id = row.brandId?.trim() ?? '';
                if (name == '-' || name.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('-', style: TextStyle(fontSize: 12)),
                  );
                }
                // 详情页内点击品牌 → 弹窗（列表仍跳转品牌详情页）。
                return Align(
                  alignment: Alignment.centerLeft,
                  child: HyperPressable(
                    onTap: id.isEmpty
                        ? () => showHyperToast(
                              context,
                              content: const Text('缺少品牌 ID，无法打开概览'),
                            )
                        : () => showAgencyOverviewDialog(
                              context,
                              customerId: id,
                              enterpriseName: name,
                            ),
                    builder: (context, states, child) => child!,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (controller.isAgency || !controller.isEnterprise)
            AppDataGridColumn(
              id: 'enterprise',
              title: controller.isAgency ? '关联企业' : '关联企业',
              width: 160,
              minWidth: 120,
              widthMode: AppDataGridColumnWidthMode.fill,
              flex: 1.3,
              alignment: Alignment.centerLeft,
              titleAlignment: Alignment.centerLeft,
              value: (row) => row.enterprise ?? '-',
              cellBuilder: (context, row, _) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  row.enterprise?.trim().isNotEmpty == true
                      ? row.enterprise!.trim()
                      : '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          AppDataGridColumn(
            id: 'relation',
            title: '关联关系',
            width: 100,
            value: (row) => controller.orderRelationDisplay(row),
          ),
          if (!controller.isAgency)
            AppDataGridColumn(
              id: 'agency',
              title: '关联4A',
              width: 180,
              minWidth: 140,
              widthMode: AppDataGridColumnWidthMode.fill,
              flex: 1.4,
              alignment: Alignment.centerLeft,
              titleAlignment: Alignment.centerLeft,
              value: (row) => row.agencyName ?? row.agencyId ?? '',
              cellBuilder: (context, row, _) => _OrderAgencyLink(order: row),
            ),
          AppDataGridColumn(
            id: 'contract',
            title: '合同类型',
            width: 100,
            value: (row) => controller.contractTypeLabel(row.contractType),
            cellBuilder: (context, row, _) {
              final label = controller.contractTypeLabel(row.contractType);
              if (label == '-') return const Text('-');
              return Center(
                child: AppBadge.custom(
                  color: const Color(0xFF1677FF),
                  appearance: AppBadgeStyle.soft,
                  shape: AppBadgeShape.square,
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
          AppDataGridColumn(
            id: 'amount',
            title: '订单金额',
            width: 100,
            value: (row) => _fmtWan(row.amount),
            cellBuilder: (context, row, _) => Text(
              _fmtWan(row.amount),
              style: const TextStyle(
                color: _kGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppDataGridColumn(
            id: 'time',
            title: '订单时间',
            width: 110,
            value: (row) => _fmtOrderTime(row.orderTime, withTime: withTime),
          ),
          AppDataGridColumn(
            id: 'contact',
            title: '联系人',
            width: 180,
            minWidth: 140,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 1.4,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => row.contact ?? '-',
            cellBuilder: (context, row, _) => _OrderContactsCell(
              controller: controller,
              order: row,
            ),
          ),
          AppDataGridColumn(
            id: 'sales',
            title: '销售员',
            width: 120,
            minWidth: 96,
            widthMode: AppDataGridColumnWidthMode.fill,
            flex: 0.9,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) {
              final s = row.salesPerson?.trim();
              if (s != null && s.isNotEmpty) return s;
              final fb = _salesFallback;
              return fb.isEmpty ? '-' : fb;
            },
            cellBuilder: (context, row, _) => _OrderSalesCell(
              controller: controller,
              order: row,
              fallback: _salesFallback,
            ),
          ),
          AppDataGridColumn(
            id: 'remark',
            title: '备注',
            width: 120,
            minWidth: 96,
            widthMode: AppDataGridColumnWidthMode.fill,
            alignment: Alignment.centerLeft,
            titleAlignment: Alignment.centerLeft,
            value: (row) => row.remark?.trim().isNotEmpty == true
                ? row.remark!.trim()
                : '-',
          ),
          if (!controller.isEnterprise && !controller.isAgency)
            AppDataGridColumn(
              id: 'actions',
              title: '操作',
              width: 64,
              widthMode: AppDataGridColumnWidthMode.fixed,
              pin: AppDataGridColumnPin.end,
              value: (_) => '',
              cellBuilder: (context, row, _) => Center(
                child: HyperPressable(
                  onTap: () async {
                    final ok = await showEditOrderDialog(
                      context,
                      order: row,
                      initialBrandId: controller.brandId,
                    );
                    if (!ok || !context.mounted) return;
                    await controller.load();
                  },
                  builder: (context, states, child) => child!,
                  child: const Text(
                    '编辑',
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(
                      color: Color(0xFF52C41A),
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 蓝色「+ / +N」添加按钮（联系人、销售员共用）。
Widget _orderAddChip({required String label, required VoidCallback onTap}) {
  return HyperPressable(
    onTap: onTap,
    builder: (context, states, child) => child!,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFECF5FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF409EFF),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

List<String> _splitPeople(String? raw) => (raw ?? '')
    .split(RegExp(r'[,，;；、/|]+'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// 联系人：`[+N] 名1 · 名2 [+]`——溢出在前，末尾固定添加。
class _OrderContactsCell extends StatelessWidget {
  const _OrderContactsCell({
    required this.controller,
    required this.order,
  });

  final BrandDetailController controller;
  final OrderItem order;

  Future<void> _openAdd(BuildContext context) async {
    final saved = await showOrderContactsDialog(
      context,
      controller: controller,
      order: order,
    );
    if (!saved || !context.mounted) return;
    showHyperToast(context, content: const Text('联系人已更新'));
  }

  @override
  Widget build(BuildContext context) {
    final parts = _splitPeople(order.contact);
    final visible = parts.take(2).toList();
    final more = parts.length - visible.length;
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (more > 0) ...[
              _orderAddChip(label: '+$more', onTap: () => _openAdd(context)),
              const SizedBox(width: 6),
            ],
            if (visible.isNotEmpty) ...[
              Text(
                visible.join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF52C41A),
                ),
              ),
              const SizedBox(width: 6),
            ],
            _orderAddChip(label: '+', onTap: () => _openAdd(context)),
          ],
        ),
      ),
    );
  }
}

/// 销售员：`[+N] 名1 · 名2 [+]`——溢出在前，末尾固定添加。
class _OrderSalesCell extends StatelessWidget {
  const _OrderSalesCell({
    required this.controller,
    required this.order,
    required this.fallback,
  });

  final BrandDetailController controller;
  final OrderItem order;
  final String fallback;

  Future<void> _openAdd(BuildContext context) async {
    final saved = await showOrderSalesDialog(
      context,
      controller: controller,
      order: order,
    );
    if (!saved || !context.mounted) return;
    showHyperToast(context, content: const Text('销售员已更新'));
  }

  @override
  Widget build(BuildContext context) {
    var parts = _splitPeople(order.salesPerson);
    if (parts.isEmpty) parts = _splitPeople(fallback);
    final visible = parts.take(2).toList();
    final more = parts.length - visible.length;
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (more > 0) ...[
              _orderAddChip(label: '+$more', onTap: () => _openAdd(context)),
              const SizedBox(width: 6),
            ],
            if (visible.isNotEmpty) ...[
              Text(
                visible.join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
            ],
            _orderAddChip(label: '+', onTap: () => _openAdd(context)),
          ],
        ),
      ),
    );
  }
}

/// 订单行「关联4A」：蓝色可点，打开主体概览（`GET /desktop/oac/customer/{id}`）。
class _OrderAgencyLink extends StatelessWidget {
  const _OrderAgencyLink({required this.order});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    final id = order.agencyId?.trim() ?? '';
    final name = order.agencyName?.trim() ?? '';
    final label = name.isNotEmpty ? name : id;
    if (label.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('-', style: TextStyle(fontSize: 12)),
      );
    }
    if (id.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: HyperPressable(
        onTap: () => showAgencyOverviewDialog(
          context,
          customerId: id,
        ),
        builder: (context, states, child) => child!,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
            style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF52C41A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Contacts / Sales ─────────────────────────────────────────────────────────

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({
    required this.controller,
    required this.contacts,
  });

  final BrandDetailController controller;
  final List<ContactItem> contacts;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = controller.isEnterprise;
    final isAgency = controller.isAgency;
    final useGrid = isEnterprise || isAgency;
    final titlePrefix = isAgency
        ? '4A 联系人'
        : isEnterprise
            ? '企业联系人'
            : '联系人';
    final titleSuffix = isAgency
        ? '共 ${contacts.length} 人 · 展示关键对接人'
        : '共 ${contacts.length} 人';
    final sameCount = contacts.length > 1 ? contacts.length - 1 : 0;
    return _SectionCard(
      title: '$titlePrefix $titleSuffix',
      trailing: AppButton.ghost(
        onPressed: () =>
            showAddBrandContact(context, controller: controller),
        leading: const Icon(Icons.add, size: 14),
        child: const Text('添加联系人'),
      ),
      child: contacts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('暂无联系人', style: TextStyle(color: _kMuted)),
              ),
            )
          : useGrid
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contacts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    // 含手机/邮箱时需更高卡片，避免 Column 底部溢出。
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final c = contacts[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFBFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Avatar(name: c.name ?? '?', size: 36),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _kTitle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (c.orgName?.trim().isNotEmpty == true)
                                c.orgName!.trim(),
                              if (c.title?.trim().isNotEmpty == true)
                                c.title!.trim(),
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (c.phone?.trim().isNotEmpty == true)
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 12,
                                  color: _kMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    c.phone!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          if (c.email?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.mail_outline,
                                  size: 12,
                                  color: _kMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    c.email!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '同企业联系人 $sameCount 人',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Column(
                  children: [
                    for (final c in contacts)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFBFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(
                          children: [
                            _Avatar(name: c.name ?? '?', size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: c.name ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kTitle,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextSpan(
                                          text: [
                                            if (c.orgName?.trim().isNotEmpty ==
                                                true)
                                              ' · ${c.orgName}',
                                            if (c.title?.trim().isNotEmpty ==
                                                true)
                                              ' · ${c.title}',
                                          ].join(),
                                          style: const TextStyle(
                                            color: _kMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (c.phone?.trim().isNotEmpty ==
                                          true) ...[
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 14,
                                          color: _kMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.phone!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      if (c.email?.trim().isNotEmpty ==
                                          true) ...[
                                        const Icon(
                                          Icons.mail_outline,
                                          size: 14,
                                          color: _kMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.email!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({
    required this.controller,
    required this.people,
    required this.detail,
  });

  final BrandDetailController controller;
  final List<SalesPersonView> people;
  final OacBrandDetail detail;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = controller.isEnterprise;
    final isAgency = controller.isAgency;
    final orderCount = isEnterprise
        ? (controller.enterpriseOrderCount() ?? detail.orders.length)
        : isAgency
            ? (controller.agencyOrderCount() ?? detail.orders.length)
            : (detail.brand?.orderCount ?? detail.orders.length);
    final amountText = _fmtWan(
      isEnterprise
          ? controller.enterpriseOrderAmount()
          : isAgency
              ? controller.agencyOrderAmount()
              : detail.brand?.orderAmount,
    );
    final shareRate = isEnterprise
        ? controller.enterpriseDeptPerfShareRate()
        : isAgency
            ? controller.agencyDeptPerfShareRate()
            : null;
    return _SectionCard(
      title: '销售员',
      trailing: AppButton.ghost(
        onPressed: () =>
            showAddBrandSales(context, controller: controller),
        leading: const Icon(Icons.add, size: 14),
        child: const Text('添加'),
      ),
      child: people.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('暂无销售员', style: TextStyle(color: _kMuted)),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < people.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        _Avatar(name: people[i].name, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    people[i].name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppBadge.custom(
                                    color: i == 0 ||
                                            people[i].role.contains('负责')
                                        ? _kPrimary
                                        : const Color(0xFF52C41A),
                                    appearance: AppBadgeStyle.soft,
                                    shape: AppBadgeShape.square,
                                    child: Text(
                                      i == 0 || people[i].role.contains('负责')
                                          ? '主销售'
                                          : '协同销售',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                people[i].deptTitle?.trim().isNotEmpty == true
                                    ? '${people[i].deptTitle} · 负责订单 $orderCount 笔'
                                    : '${people[i].role} · 负责订单 $orderCount 笔',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEnterprise || isAgency)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                people.length <= 1
                                    ? amountText
                                    : _fmtWan(
                                        ((num.tryParse(
                                                      (isAgency
                                                              ? controller
                                                                  .agencyOrderAmount()
                                                              : controller
                                                                  .enterpriseOrderAmount()) ??
                                                          '0',
                                                    ) ??
                                                    0) /
                                                people.length)
                                            .toStringAsFixed(2),
                                      ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kGold,
                                ),
                              ),
                              Text(
                                isEnterprise &&
                                        people.length <= 1 &&
                                        shareRate != null &&
                                        shareRate.isNotEmpty
                                    ? '占比 $shareRate%'
                                    : people.length <= 1
                                        ? (shareRate != null &&
                                                shareRate.isNotEmpty
                                            ? '占比 $shareRate%'
                                            : '占比 100%')
                                        : '占比 ${(100 / people.length).round()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Dynamics / Map / Notes ───────────────────────────────────────────────────

class _DynamicsCard extends StatelessWidget {
  const _DynamicsCard({
    required this.brand,
    this.enterprise,
    this.agency,
  });

  final OacBrand? brand;
  final OacEnterprise? enterprise;
  final OacAgency? agency;

  @override
  Widget build(BuildContext context) {
    final text = enterprise?.latestDynamic?.trim().isNotEmpty == true
        ? enterprise!.latestDynamic!.trim()
        : agency?.latestDynamic?.trim().isNotEmpty == true
            ? agency!.latestDynamic!.trim()
            : brand?.latestDynamic?.trim();
    final time = enterprise?.updateTime ??
        enterprise?.createTime ??
        agency?.updateTime ??
        agency?.createTime ??
        brand?.updateTime ??
        brand?.createTime ??
        '';
    return _SectionCard(
      title: '最新动态 · AI 简报',
      child: text == null || text.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('暂无动态', style: TextStyle(color: _kMuted)),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$time · 来源：系统动态',
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '动态：$text',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapCard extends StatefulWidget {
  const _MapCard({required this.hq});

  final HqLocation? hq;

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  final _mapKey = GlobalKey<OfficeAmapViewState>();

  @override
  Widget build(BuildContext context) {
    final hq = widget.hq;
    final name = hq?.name?.trim().isNotEmpty == true ? hq!.name!.trim() : '总部';
    final address = (hq?.address?.trim().isNotEmpty == true &&
            hq!.address!.trim() != '-')
        ? hq.address!.trim()
        : '';
    final region = hq?.region?.trim() ?? '';
    return _SectionCard(
      title: '总部办公地图',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: OfficeAmapView(
              key: _mapKey,
              address: address,
              city: region,
              longitude: hq?.lng,
              latitude: hq?.lat,
              showZoomControl: false,
            ),
          ),
          if (address.isNotEmpty || name.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                name,
                if (address.isNotEmpty) address,
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: _kTitle),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  onPressed: address.isEmpty && hq?.lng == null
                      ? null
                      : () async {
                          final text = [
                            name,
                            if (address.isNotEmpty) address,
                            if (hq?.lng != null && hq?.lat != null)
                              '${hq!.lng},${hq.lat}',
                          ].join(' ');
                          await Clipboard.setData(ClipboardData(text: text));
                          if (!context.mounted) return;
                          showHyperToast(
                            context,
                            content: const Text('已复制地址'),
                          );
                        },
                  child: const Text('复制地址'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.outline(
                  onPressed: address.isEmpty && hq?.lng == null
                      ? null
                      : () {
                          final s = _mapKey.currentState;
                          openAmapNavigation(
                            context,
                            address: address.isNotEmpty ? address : name,
                            name: name,
                            longitude: s?.lng ?? hq?.lng,
                            latitude: s?.lat ?? hq?.lat,
                          );
                        },
                  child: const Text('导航到这'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.controller,
    required this.remark,
    this.showEdit = true,
  });

  final BrandDetailController controller;
  final String? remark;
  final bool showEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '备注与附件',
      trailing: showEdit
          ? AppButton.ghost(
              onPressed: () => showEditBrandRemarkDialog(
                context,
                controller: controller,
                initialRemark: remark,
              ),
              child: const Text('编辑'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFE58F)),
            ),
            child: Text(
              (remark == null || remark!.trim().isEmpty) ? '暂无备注' : remark!,
              style: const TextStyle(fontSize: 13, color: _kTitle),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final files = controller.attachments.toList();
            if (files.isEmpty) {
              return const Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 18,
                    color: _kMuted,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '暂无附件',
                    style: TextStyle(color: _kMuted, fontSize: 13),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: _kMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kTitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
          if (showEdit) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton.link(
                onPressed: () =>
                    uploadBrandAttachment(context, controller: controller),
                child: const Text('+ 上传附件'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
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
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first;
    final colors = [
      const Color(0xFF722ED1),
      const Color(0xFFEB2F96),
      const Color(0xFF52C41A),
      const Color(0xFF1677FF),
      const Color(0xFFFA8C16),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// 品牌标签不展示纯英文（如 international）。
bool _isDisplayableTag(String tag) {
  final t = tag.trim();
  if (t.isEmpty) return false;
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(t);
}

String _fmtWan(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final n = num.tryParse(raw.trim());
  if (n == null) return raw.startsWith('¥') ? raw : '¥$raw';
  // 接口返回已是「万」；展示固定带万。
  if (n.abs() < 0.005) return '¥0万';
  final text =
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  return '¥$text万';
}

String _fmtDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final s = raw.trim();
  return s.length >= 10 ? s.substring(0, 10) : s;
}

DateTime? _parseOrderTime(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;
  final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

String _fmtOrderTime(String? raw, {required bool withTime}) {
  final d = _parseOrderTime(raw);
  if (d == null) return _fmtDate(raw);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  if (!withTime) return '$y.$m.$day';
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}

void openBrandOrderDetailPage(BuildContext context) {
  final controller = context.lx.find<BrandDetailController>();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LxScope(
        bindings: (container) {
          container.putInstance<BrandDetailController>(
            controller,
            owned: false,
          );
        },
        child: AppShadcnScope(
          config: AppThemeConfig.standard(primary: _kPrimary),
          child: const BrandOrderDetailPage(),
        ),
      ),
    ),
  );
}
