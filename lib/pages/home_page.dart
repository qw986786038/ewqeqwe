import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../bokong/http/bokong_auto_auth.dart';
import '../bokong/main.dart';
import '../models/oac_agency.dart';
import '../models/oac_brand.dart';
import '../models/oac_enterprise.dart';
import '../models/oac_person.dart';
import '../services/auth_session.dart';
import 'brand_detail/brand_detail_page.dart';
import 'brand_detail/dialogs/add_order_dialog.dart';
import 'customer_archive/customer_archive_page.dart';
import 'home_controller.dart';
import 'location_breadcrumb.dart';
import 'hrm/directory/enterprise_directory_page.dart';
import 'hrm/hrm_placeholder_page.dart';
import 'hrm/org_structure/org_structure_page.dart';
import 'hrm/post_manage/post_manage_page.dart';
import 'hrm/employee_archive/employee_archive_page.dart';
import 'hrm/offboarding/offboarding_page.dart';
import 'hrm/onboarding/onboarding_page.dart';
import 'hrm/regularization/regularization_page.dart';
import 'hrm/seat/seat_page.dart';
import 'hrm/post_seq/post_seq_page.dart';
import 'hrm/workplace/workplace_page.dart';
import 'login_page.dart';
import 'srm/purchase_order/purchase_order_list_page.dart';
import 'srm/srm_placeholder_page.dart';
import 'srm/supplier/supplier_list_page.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kTrendUp = Color(0xFF52C41A);
const _kTrendDown = Color(0xFFFF4D4F);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
/// 订单金额展示色（金橙，对齐企业视角稿）。
const _kAmount = Color(0xFFE6A23C);
const _kSideBg = Color(0xFFFFFFFF);
const _kSideWidth = 200.0;

/// AppInkWell → HyperPressable（本页迁移薄封装）。
Widget _hInk({VoidCallback? onPressed, required Widget child}) {
  return HyperPressable(
    enabled: onPressed != null,
    onTap: onPressed,
    builder: (context, states, child) => child!,
    child: child,
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.loginData});

  final Map<String, dynamic>? loginData;

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<HomeController>(
          () => HomeController(loginData: loginData),
        );
      },
      // AppDataGrid 仍依赖 shadcn Scope；Hyper* 用根级 HyperTheme（见 main.dart）。
      child: AppShadcnScope(
        config: AppThemeConfig.standard(primary: _kPrimary),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _openBokong(BuildContext context) async {
    await ensureBokongInitialized();
    // 进入播控前无感登录，拿到 token 后直接进壳层。
    await BokongAutoAuth.loginSilently();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BokongApp()),
    );
  }

  void _logout(BuildContext context) {
    AuthSession.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openBrandDetail(BuildContext context, OacBrand row) {
    final id = row.id?.trim();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrandDetailPage(brandId: id),
      ),
    );
  }

  Future<void> _openAddOrder(BuildContext context) async {
    final ok = await showAddOrderDialog(context);
    if (ok && context.mounted) {
      context.lx.find<HomeController>().refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<HomeController>();

    return Scaffold(
      backgroundColor: _kPageBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => _SideNav(
              selectedId: c.sideMenu.value,
              onSelect: (id) {
                if (id == 'bokong') {
                  _openBokong(context);
                  return;
                }
                c.openSideMenu(id);
              },
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  if (c.sideMenu.value != 'orders') {
                    return const SizedBox.shrink();
                  }
                  return _TopBar(
                    searchController: c.topSearchCtrl,
                    displayName: c.displayName,
                    syncing: c.overviewLoading.value || c.listLoading.value,
                    onAddOrder: () => _openAddOrder(context),
                    onSync: c.refreshAll,
                    onLogout: () => _logout(context),
                  );
                }),
                Expanded(
                  child: Obx(() {
                    final menu = c.sideMenu.value;
                    if (menu == 'customers') {
                      return const CustomerArchivePage();
                    }
                    if (menu == 'hrm_org') {
                      return const OrgStructurePage();
                    }
                    if (menu == 'hrm_post') {
                      return const PostManagePage();
                    }
                    if (menu == 'hrm_post_seq') {
                      return const PostSeqPage();
                    }
                    if (menu == 'hrm_seat') {
                      return const SeatPage();
                    }
                    if (menu == 'hrm_archive') {
                      return const EmployeeArchivePage();
                    }
                    if (menu == 'hrm_onboarding') {
                      return const OnboardingPage();
                    }
                    if (menu == 'hrm_regularization') {
                      return const RegularizationPage();
                    }
                    if (menu == 'hrm_offboarding') {
                      return const OffboardingPage();
                    }
                    if (menu == 'hrm_directory') {
                      return const EnterpriseDirectoryPage();
                    }
                    if (menu == 'hrm_workplace') {
                      return const WorkplacePage();
                    }
                    if (menu.startsWith('hrm_')) {
                      return HrmPlaceholderPage(menuId: menu);
                    }
                    if (menu == 'srm_supplier') {
                      return const SupplierListPage();
                    }
                    if (menu == 'srm_purchase_order') {
                      return const PurchaseOrderListPage();
                    }
                    if (menu.startsWith('srm_')) {
                      return SrmPlaceholderPage(menuId: menu);
                    }
                    return _OrderBrandPage(
                      onOpenBrandDetail: (row) =>
                          _openBrandDetail(context, row),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _exportBrands(BuildContext context, HomeController c) async {
  if (c.exporting.value) return;
  try {
    final hidden = c.hiddenColumnIds.toSet();
    final source = c.isPersonTab
        ? _kPersonToggleableColumns
        : c.isAgencyTab
            ? _kAgencyToggleableColumns
            : c.isEnterpriseTab
                ? _kEnterpriseToggleableColumns
                : _kToggleableColumns;
    final columns = [
      for (final col in source)
        if (!hidden.contains(col.$1)) col,
    ];
    final file = await c.exportExcel(columns: columns);
    if (!context.mounted) return;
    final dialogTitle = c.isPersonTab
        ? '导出联系人汇总'
        : c.isAgencyTab
            ? '导出4A公司主体汇总'
            : c.isEnterpriseTab
                ? '导出企业主体汇总'
                : '导出品牌主体汇总';
    final savedUri = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: file.fileName,
      bytes: file.bytes,
      mimeType: 'application/vnd.ms-excel',
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (!context.mounted) return;
    if (savedUri == null) return;
    showHyperToast(context, content: const Text('导出成功'));
  } catch (e) {
    if (!context.mounted) return;
    showHyperToast(context, content: Text('$e'));
  }
}

/// 订单管理 · 品牌列表（原首页主体）
class _OrderBrandPage extends StatelessWidget {
  const _OrderBrandPage({required this.onOpenBrandDetail});

  final void Function(OacBrand row) onOpenBrandDetail;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<HomeController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
                  const LocationBreadcrumb(
                    segments: ['户外传媒CRM', '订单管理'],
                  ),
                  // ── Tabs + 状态行 ──────────────────────────────────────
                  Row(
                    children: [
                      Obx(() {
                        final tab = c.entityTab.value;
                        return _EntityTabBar(
                          selected: tab,
                          onSelect: c.selectEntityTab,
                        );
                      }),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() {
                          final tab = c.entityTab.value;
                          final asOf = switch (tab) {
                            1 => c.enterpriseOverview.value?.dataAsOf,
                            2 => c.agencyOverview.value?.dataAsOf,
                            3 => c.personOverview.value?.dataAsOf,
                            _ => c.overview.value?.dataAsOf,
                          };
                          final asOfText =
                              asOf == null || asOf.isEmpty ? '—' : asOf;
                          final dim = switch (tab) {
                            1 => '企业维度汇总',
                            2 => '4A 公司维度汇总',
                            3 => '人员维度汇总',
                            _ => '品牌维度汇总',
                          };
                          return Text(
                            '订单管理 > 当前视图：$dim，数据截至 $asOfText，自动同步中',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4E5969),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── KPI 六卡 ───────────────────────────────────────────
                  Obx(() {
                    final tab = c.entityTab.value;
                    final brandO = c.overview.value;
                    final entO = c.enterpriseOverview.value;
                    final agencyO = c.agencyOverview.value;
                    final personO = c.personOverview.value;
                    final loading = c.overviewLoading.value &&
                        (tab == 3
                            ? personO == null
                            : tab == 2
                                ? agencyO == null
                                : tab == 1
                                    ? entO == null
                                    : brandO == null);
                    if (loading) {
                      return const SizedBox(
                        height: 96,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (tab == 3) {
                      final latestRaw = personO?.latestOrderTime?.trim();
                      final latestDate = _fmtDate(latestRaw);
                      final latestTime = _fmtTimeOnly(latestRaw);
                      final latestName =
                          personO?.latestOrderContactName?.trim();
                      final latestSub = [
                        ?latestTime,
                        if (latestName != null && latestName.isNotEmpty)
                          latestName,
                      ].join(' · ');
                      final avg = personO?.avgBrandPerContact?.trim();
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: '联系人总数',
                              value: _fmtInt(personO?.contactCount),
                              subtitle:
                                  '本周新增 ${personO?.contactNewThisWeek ?? 0} 人',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '总订单数',
                              value: _fmtInt(personO?.totalOrderCount),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '总订单金额',
                              value: _fmtMoney(personO?.totalOrderAmount),
                              valueStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _kAmount,
                                height: 1.1,
                              ),
                              subtitle: '金额单位：万元',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '关联品牌数',
                              value: _fmtInt(personO?.relatedBrandCount),
                              subtitle: avg == null || avg.isEmpty
                                  ? '人均关联品牌'
                                  : '人均 $avg 个品牌',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '关联企业数',
                              value: _fmtInt(personO?.relatedEnterpriseCount),
                              subtitle:
                                  '关联4A ${personO?.relatedAgencyCount ?? 0} 家',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '最新订单时间',
                              value: latestDate,
                              valueStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                                height: 1.1,
                              ),
                              subtitle: latestSub.isEmpty ? null : latestSub,
                            ),
                          ),
                        ],
                      );
                    }
                    if (tab == 2) {
                      final latestRaw = agencyO?.latestOrderTime?.trim();
                      final latestDate = _fmtDate(latestRaw);
                      final latestTime = _fmtTimeOnly(latestRaw);
                      final latestName =
                          agencyO?.latestOrderAgencyName?.trim();
                      final latestSub = [
                        ?latestTime,
                        if (latestName != null && latestName.isNotEmpty)
                          latestName,
                      ].join(' · ');
                      final avg = agencyO?.avgBrandPerAgency?.trim();
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: '总订单数',
                              value: _fmtInt(agencyO?.totalOrderCount),
                              trend: _fmtMomRate(agencyO?.orderCountMomRate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '总订单金额',
                              value: _fmtMoney(agencyO?.totalOrderAmount),
                              valueStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _kAmount,
                                height: 1.1,
                              ),
                              trend: _fmtMomRate(agencyO?.orderAmountMomRate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '关联品牌数',
                              value: _fmtInt(agencyO?.relatedBrandCount),
                              subtitle: avg == null || avg.isEmpty
                                  ? '平均关联品牌'
                                  : '平均 $avg 个品牌/家4A',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '关联企业数',
                              value: _fmtInt(agencyO?.relatedEnterpriseCount),
                              subtitle: '覆盖合作企业',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '联系人数量',
                              value: _fmtInt(agencyO?.contactCount),
                              subtitle:
                                  '本周新增 ${agencyO?.contactNewThisWeek ?? 0} 人',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '最新订单时间',
                              value: latestDate,
                              valueStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                                height: 1.1,
                              ),
                              subtitle: latestSub.isEmpty ? null : latestSub,
                            ),
                          ),
                        ],
                      );
                    }
                    if (tab == 1) {
                      final latestRaw = entO?.latestOrderTime?.trim();
                      final latestDate = _fmtDate(latestRaw);
                      final latestTime = _fmtTimeOnly(latestRaw);
                      final latestName =
                          entO?.latestOrderEnterpriseName?.trim() ??
                              entO?.latestOrderBrandName?.trim();
                      final latestSub = [
                        ?latestTime,
                        if (latestName != null && latestName.isNotEmpty)
                          latestName,
                      ].join(' · ');
                      final entTotal = c.total.value;
                      final brandCnt = entO?.relatedBrandCount ?? 0;
                      final avgBrand = entTotal > 0
                          ? (brandCnt / entTotal)
                              .toStringAsFixed(1)
                              .replaceFirst(RegExp(r'\.0$'), '')
                          : '0';
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: '总订单数',
                              value: _fmtInt(entO?.totalOrderCount),
                              subtitle: '当前筛选范围合计',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '总订单金额',
                              value: _fmtMoney(entO?.totalOrderAmount),
                              valueStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _kAmount,
                                height: 1.1,
                              ),
                              subtitle: '金额单位：万元',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '关联品牌数',
                              value: _fmtInt(entO?.relatedBrandCount),
                              subtitle: '媒体主平均 $avgBrand 家',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '关联4A数',
                              value: _fmtInt(entO?.relatedAgencyCount),
                              subtitle:
                                  '国际4A占 ${entO?.internationalAgencyCount ?? 0} 家',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '联系人总数量',
                              value: _fmtInt(entO?.contactCount),
                              subtitle:
                                  '本周新增 ${entO?.contactNewThisWeek ?? 0} 人',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: '最新订单时间',
                              value: latestDate,
                              valueStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                                height: 1.1,
                              ),
                              subtitle: latestSub.isEmpty ? null : latestSub,
                            ),
                          ),
                        ],
                      );
                    }
                    final latestRaw = brandO?.latestOrderTime?.trim();
                    final latestDate = _fmtDate(latestRaw);
                    final latestTime = _fmtTimeOnly(latestRaw);
                    final latestName = brandO?.latestOrderBrandName?.trim();
                    final latestSub = [
                      ?latestTime,
                      if (latestName != null && latestName.isNotEmpty)
                        latestName,
                    ].join(' · ');
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: '总订单数',
                            value: _fmtInt(brandO?.totalOrderCount),
                            trend: _fmtMomRate(brandO?.orderCountMomRate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '总订单金额',
                            value: _fmtMoney(brandO?.totalOrderAmount),
                            valueStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _kAmount,
                              height: 1.1,
                            ),
                            trend: _fmtMomRate(brandO?.orderAmountMomRate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '关联企业数',
                            value: _fmtInt(brandO?.relatedEnterpriseCount),
                            subtitle:
                                '覆盖 ${brandO?.industryCount ?? 0} 个行业',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '关联 4A 数',
                            value: _fmtInt(brandO?.relatedAgencyCount),
                            subtitle:
                                '国际 4A 占 ${brandO?.internationalAgencyCount ?? 0} 家',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '联系人数量',
                            value: _fmtInt(brandO?.contactCount),
                            subtitle:
                                '本周新增 ${brandO?.contactNewThisWeek ?? 0} 人',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '最新订单时间',
                            value: latestDate,
                            valueStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                              height: 1.1,
                            ),
                            subtitle: latestSub.isEmpty ? null : latestSub,
                          ),
                        ),
                      ],
                    );
                  }),
                  Obx(() {
                    final err = c.errorMessage.value;
                    if (err == null || err.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        err,
                        style: const TextStyle(
                          color: _kTrendDown,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // ── 筛选区 ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _kCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  Obx(() {
                                    final hint = switch (c.entityTab.value) {
                                      1 => '企业名称 / 标签',
                                      2 => '4A名称 / 服务标签',
                                      3 => '姓名 / 职位 / 企业',
                                      _ => '品牌名 / 标签 / 代言人',
                                    };
                                    return _FilterField(
                                      width: 180,
                                      label: '关键词',
                                      child: TextField(
                                        controller: c.keywordCtrl,
                                        decoration: _filterDecoration(hint),
                                        onSubmitted: (_) => c.search(),
                                      ),
                                    );
                                  }),
                                  // 人：关键词 → 企业类型 → 城市 → 就职企业 → 时间
                                  Obx(() {
                                    if (!c.isPersonTab) {
                                      return const SizedBox.shrink();
                                    }
                                    return _FilterField(
                                      width: 140,
                                      label: '企业类型',
                                      child: Obx(() {
                                        final opts =
                                            c.enterpriseTypeOptions.toList();
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.enterpriseType.value,
                                          searchable: true,
                                          placeholder: '全部类型',
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) =>
                                              c.enterpriseType.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  // 企业：关键词 → 企业标签 → 城市 → 媒体类型 → …
                                  Obx(() {
                                    if (!c.isEnterpriseTab) {
                                      return const SizedBox.shrink();
                                    }
                                    return _FilterField(
                                      width: 140,
                                      label: '企业标签',
                                      child: Obx(() {
                                        final opts = c.tagOptions.toList();
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.tags.value,
                                          searchable: true,
                                          placeholder: '全部标签',
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) => c.tags.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    if (c.isEnterpriseTab || c.isPersonTab) {
                                      return const SizedBox.shrink();
                                    }
                                    if (c.isAgencyTab) {
                                      return _FilterField(
                                        width: 140,
                                        label: '服务标签',
                                        child: Obx(() {
                                          final opts = c.tagOptions.toList();
                                          return _FilterSelect<String>(
                                            width: 140,
                                            value: c.tags.value,
                                            searchable: true,
                                            options: [
                                              for (final o in opts)
                                                HyperSelectOption(
                                                  value: o,
                                                  label: o,
                                                ),
                                            ],
                                            onChanged: (v) => c.tags.value = v,
                                          );
                                        }),
                                      );
                                    }
                                    return _FilterField(
                                      width: 140,
                                      label: '所属行业',
                                      child: Obx(() {
                                        final opts = c.industryOptions;
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.industry.value,
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o.value,
                                                label: o.label,
                                              ),
                                          ],
                                          onChanged: (v) =>
                                              c.industry.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    final allCity = c.isEnterpriseTab ||
                                        c.isPersonTab;
                                    return _FilterField(
                                      width: 140,
                                      label: '所在城市',
                                      child: Obx(() {
                                        final opts = c.cityOptions.toList();
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.city.value,
                                          searchable: true,
                                          placeholder:
                                              allCity ? '全部城市' : '全部',
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) => c.city.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    if (!c.isPersonTab) {
                                      return const SizedBox.shrink();
                                    }
                                    return _FilterField(
                                      width: 160,
                                      label: '就职企业',
                                      child: Obx(() {
                                        final opts =
                                            c.employerOptions.toList();
                                        return _FilterSelect<String>(
                                          width: 160,
                                          value: c.latestEmployer.value,
                                          searchable: true,
                                          placeholder: '全部企业',
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) =>
                                              c.latestEmployer.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    if (!c.isEnterpriseTab) {
                                      return const SizedBox.shrink();
                                    }
                                    return _FilterField(
                                      width: 140,
                                      label: '媒体类型',
                                      child: Obx(() {
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.mediaType.value,
                                          placeholder: '全部媒体类型',
                                          options: [
                                            for (final o
                                                in HomeController
                                                    .mediaTypeOptions)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) =>
                                              c.mediaType.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    if (c.isEnterpriseTab || c.isPersonTab) {
                                      return const SizedBox.shrink();
                                    }
                                    if (c.isAgencyTab) {
                                      return _FilterField(
                                        width: 140,
                                        label: '关联关系',
                                        child: Obx(() {
                                          final opts = c.relationTypeOptions;
                                          return _FilterSelect<String>(
                                            width: 140,
                                            value: c.relationType.value,
                                            options: [
                                              for (final o in opts)
                                                HyperSelectOption(
                                                  value: o.value,
                                                  label: o.label,
                                                ),
                                            ],
                                            onChanged: (v) =>
                                                c.relationType.value = v,
                                          );
                                        }),
                                      );
                                    }
                                    return _FilterField(
                                      width: 140,
                                      label: '品牌标签',
                                      child: Obx(() {
                                        final opts = c.tagOptions.toList();
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.tags.value,
                                          searchable: true,
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) => c.tags.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    if (c.isPersonTab) {
                                      return const SizedBox.shrink();
                                    }
                                    final ent = c.isEnterpriseTab;
                                    return _FilterField(
                                      width: 140,
                                      label: '销售员',
                                      child: Obx(() {
                                        final opts = c.ownerOptions.toList();
                                        return _FilterSelect<String>(
                                          width: 140,
                                          value: c.ownerNames.value,
                                          searchable: true,
                                          placeholder:
                                              ent ? '全部销售员' : '全部',
                                          options: [
                                            for (final o in opts)
                                              HyperSelectOption(
                                                value: o,
                                                label: o,
                                              ),
                                          ],
                                          onChanged: (v) =>
                                              c.ownerNames.value = v,
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    final person = c.isPersonTab;
                                    return _FilterField(
                                      width: 280,
                                      label: person
                                          ? '最新订单时间范围'
                                          : '订单时间范围',
                                      child: Obx(() {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: HyperDateTimePicker(
                                                mode: HyperDateTimePickerMode
                                                    .date,
                                                placeholder: '开始日期',
                                                value: c.orderTimeBegin.value,
                                                onChanged: (v) => c
                                                    .orderTimeBegin.value = v,
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                              ),
                                              child: Text(
                                                '—',
                                                style:
                                                    TextStyle(color: _kMuted),
                                              ),
                                            ),
                                            Expanded(
                                              child: HyperDateTimePicker(
                                                mode: HyperDateTimePickerMode
                                                    .date,
                                                placeholder: '结束日期',
                                                value: c.orderTimeEnd.value,
                                                onChanged: (v) =>
                                                    c.orderTimeEnd.value = v,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    );
                                  }),
                                  Obx(() {
                                    if (c.isAgencyTab ||
                                        c.isEnterpriseTab ||
                                        c.isPersonTab) {
                                      return const SizedBox.shrink();
                                    }
                                    return _FilterField(
                                      width: 180,
                                      label: '订单金额区间(万)',
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: c.amountMinCtrl,
                                              decoration:
                                                  _filterDecoration('最低'),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              '—',
                                              style: TextStyle(color: _kMuted),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: c.amountMaxCtrl,
                                              decoration:
                                                  _filterDecoration('最高'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            HyperButton.filled(
                              onPressed: c.search,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('查询'),
                            ),
                            const SizedBox(width: 8),
                            HyperButton.outlined(
                              onPressed: c.resetFilters,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('重置'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 表格区 ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: _kCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(
                          () {
                            final tab = c.entityTab.value;
                            final title = switch (tab) {
                              1 => '企业主体汇总',
                              2 => '4A 公司主体汇总',
                              3 => '联系人汇总',
                              _ => '品牌主体汇总',
                            };
                            return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$title · 共 ${c.total.value} 条',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kTitle,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              HyperAnchoredOverlay.builder(
                                placement: HyperOverlayPlacement.bottomEnd,
                                anchorBuilder: (context, toggle, isOpen) =>
                                    _TableTool(
                                  icon: Icons.view_column_outlined,
                                  label: '列设置',
                                  onPressed: toggle,
                                ),
                                overlayBuilder: (context, close) =>
                                    _ColumnSettingsPopover(controller: c),
                              ),
                              HyperAnchoredOverlay.builder(
                                placement: HyperOverlayPlacement.bottomEnd,
                                anchorBuilder: (context, toggle, isOpen) =>
                                    _TableTool(
                                  icon: Icons.sort,
                                  label: '排序',
                                  onPressed: toggle,
                                ),
                                overlayBuilder: (context, close) =>
                                    _SortPopover(
                                  controller: c,
                                  onClose: close,
                                ),
                              ),
                              _TableTool(
                                icon: Icons.download_outlined,
                                label: '导出',
                                onPressed: c.exporting.value
                                    ? null
                                    : () => _exportBrands(context, c),
                              ),
                              Obx(() {
                                final show = c.tableSearchVisible.value;
                                return _TableIconButton(
                                  tooltip: show ? '隐藏搜索' : '显示搜索',
                                  icon: show
                                      ? Icons.search_off_outlined
                                      : Icons.search,
                                  onPressed: () => c.tableSearchVisible.value =
                                      !c.tableSearchVisible.value,
                                );
                              }),
                              _TableIconButton(
                                tooltip: '刷新',
                                icon: Icons.refresh,
                                onPressed: c.listLoading.value ||
                                        c.entityTab.value > 3
                                    ? null
                                    : () => c.loadList(resetPage: false),
                              ),
                            ],
                          );
                          },
                        ),
                        Obx(() {
                          if (!c.tableSearchVisible.value) {
                            return const SizedBox(height: 8);
                          }
                          final hint = switch (c.entityTab.value) {
                            1 => '搜索企业名 / 标签 / 城市',
                            2 => '搜索4A名称 / 服务标签 / 城市',
                            3 => '搜索姓名 / 职位 / 就职企业',
                            _ => '搜索品牌名 / 标签 / 代言人',
                          };
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: TextField(
                              controller: c.keywordCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: _filterDecoration(
                                hint,
                              ).copyWith(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 18,
                                  color: _kMuted,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: '查询',
                                  onPressed: c.search,
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => c.search(),
                            ),
                          );
                        }),
                        Obx(() {
                          final tab = c.entityTab.value;
                          if (tab == 3) {
                            return _PersonDataGrid(controller: c);
                          }
                          if (tab == 2) {
                            return _AgencyDataGrid(controller: c);
                          }
                          if (tab == 1) {
                            return _EnterpriseDataGrid(controller: c);
                          }
                          final rows = c.brands.toList();
                          final loading = c.listLoading.value;
                          final hidden = c.hiddenColumnIds.toSet();
                          final _ = c.sortKey.value;
                          // 订阅行业 / 标签字典，加载完成后刷新列中文。
                          final industryDictReady =
                              c.industryOptions.isNotEmpty;
                          final tagDictReady = c.tagOptions.isNotEmpty;
                          if (loading && rows.isEmpty) {
                            return const SizedBox(
                              height: 280,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final page = c.pageNum.value;
                          final size = c.pageSize.value;
                          final allColumns = <AppDataGridColumn<OacBrand>>[
                              AppDataGridColumn(
                                id: 'no',
                                title: '序号',
                                width: 52,
                                sortable: false,
                                value: (row) {
                                  final i = rows.indexOf(row);
                                  return (page - 1) * size + i + 1;
                                },
                                type: AppDataGridColumnType.number,
                              ),
                              AppDataGridColumn(
                                id: 'weight',
                                title: '权重',
                                width: 96,
                                sortable: false,
                                value: (row) => row.weight ?? 0,
                                cellBuilder: (context, row, _) {
                                  final score =
                                      (row.weight ?? 0).clamp(0, 5);
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          i < score
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 14,
                                          color: i < score
                                              ? const Color(0xFFFAAD14)
                                              : const Color(0xFFD9D9D9),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                              AppDataGridColumn(
                                id: 'icon',
                                title: '图标',
                                width: 52,
                                sortable: false,
                                value: (row) => row.iconUrl ?? '',
                                cellBuilder: (context, row, _) {
                                  final name = row.name?.trim() ?? '';
                                  final icon = row.iconUrl?.trim();
                                  final letter = name.isNotEmpty
                                      ? name.characters.first
                                      : '?';
                                  final color = _logoColor(name);
                                  if (icon != null && icon.isNotEmpty) {
                                    return Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          icon,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              _LetterAvatar(
                                            letter: letter,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: _LetterAvatar(
                                      letter: letter,
                                      color: color,
                                    ),
                                  );
                                },
                              ),
                              AppDataGridColumn(
                                id: 'name',
                                title: '品牌名称',
                                width: 168,
                                sortable: false,
                                alignment: Alignment.centerLeft,
                                titleAlignment: Alignment.centerLeft,
                                value: (row) => row.name ?? '',
                                cellBuilder: (context, row, _) {
                                  final name = row.name?.trim();
                                  final code = row.brandCode?.trim();
                                  final client = row.clientTag?.trim();
                                  final sub = [
                                    if (code != null && code.isNotEmpty) code,
                                    if (client != null && client.isNotEmpty)
                                      client,
                                  ].join(' · ');
                                  return _hInk(
                                    onPressed: () => onOpenBrandDetail(row),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name?.isNotEmpty == true
                                                ? name!
                                                : '-',
                                            style: const TextStyle(
                                              color: _kPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            softWrap: false,
                                          ),
                                          if (sub.isNotEmpty)
                                            Text(
                                              sub,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: _kMuted,
                                              ),
                                              softWrap: false,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              AppDataGridColumn(
                                id: 'industry',
                                title: '所属行业',
                                width: 108,
                                sortable: false,
                                alignment: Alignment.centerLeft,
                                titleAlignment: Alignment.centerLeft,
                                value: (row) => industryDictReady
                                    ? c.industryLabel(row.industry)
                                    : (row.industry?.trim().isNotEmpty == true
                                        ? row.industry!.trim()
                                        : '-'),
                              ),
                              AppDataGridColumn(
                                id: 'tags',
                                title: '标签',
                                width: 168,
                                sortable: false,
                                alignment: Alignment.centerLeft,
                                titleAlignment: Alignment.centerLeft,
                                value: (row) => _brandTagLabels(row)
                                    .map(c.tagLabel)
                                    .where(_isDisplayableTag)
                                    .join(','),
                                cellBuilder: (context, row, _) {
                                  final tags = [
                                    for (final raw in _brandTagLabels(row))
                                      if (_isDisplayableTag(
                                        tagDictReady
                                            ? c.tagLabel(raw)
                                            : raw,
                                      ))
                                        tagDictReady
                                            ? c.tagLabel(raw)
                                            : raw,
                                  ];
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (var i = 0;
                                            i < tags.length;
                                            i++) ...[
                                          if (i > 0) const SizedBox(width: 4),
                                          HyperTag(
                                            label: tags[i],
                                            style: const HyperTagStyle(
                                              colorVariant:
                                                  HyperTagColorVariant.soft,
                                              baseColor: Color(0xFF722ED1),
                                              radius: 3,
                                              height: 20,
                                              horizontalPadding: 6,
                                              textStyle: TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (tags.isNotEmpty)
                                          const SizedBox(width: 4),
                                        _hInk(
                                          onPressed: () =>
                                              _openAddBrandTags(
                                            context,
                                            c,
                                            row,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Color(0xFF69B1FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              AppDataGridColumn(
                                id: 'spokesperson',
                                title: '最新代言人',
                                width: 96,
                                sortable: false,
                                value: (row) => row.spokesperson ?? '-',
                              ),
                              AppDataGridColumn(
                                id: 'agency',
                                title: '关联 4A',
                                width: 80,
                                sortable: false,
                                value: (row) => row.agencyCount ?? 0,
                                type: AppDataGridColumnType.number,
                                cellBuilder: (context, row, _) {
                                  final n = row.agencyCount ?? 0;
                                  return Text(
                                    '$n',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: n > 0 ? _kPrimary : _kTitle,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    softWrap: false,
                                  );
                                },
                              ),
                              AppDataGridColumn(
                                id: 'enterprise',
                                title: '关联企业',
                                width: 80,
                                sortable: false,
                                value: (row) => row.enterpriseCount ?? 0,
                                type: AppDataGridColumnType.number,
                              ),
                              AppDataGridColumn(
                                id: 'orders',
                                title: '订单数量',
                                width: 96,
                                value: (row) => row.orderCount ?? 0,
                                type: AppDataGridColumnType.number,
                              ),
                              AppDataGridColumn(
                                id: 'amount',
                                title: '订单金额',
                                width: 112,
                                value: (row) =>
                                    num.tryParse(
                                      row.orderAmount?.trim() ?? '',
                                    ) ??
                                    0,
                                type: AppDataGridColumnType.number,
                                alignment: Alignment.centerRight,
                                titleAlignment: Alignment.centerRight,
                                cellBuilder: (context, row, _) => Text(
                                  _fmtMoney(row.orderAmount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kAmount,
                                  ),
                                  softWrap: false,
                                ),
                              ),
                              AppDataGridColumn(
                                id: 'latestOrder',
                                title: '最新订单时间',
                                width: 160,
                                value: (row) =>
                                    row.latestOrderTime?.trim() ?? '',
                                cellBuilder: (context, row, _) => Text(
                                  _fmtDateTime(row.latestOrderTime),
                                  style: const TextStyle(fontSize: 12),
                                  softWrap: false,
                                ),
                              ),
                              AppDataGridColumn(
                                id: 'contact',
                                title: '联系人',
                                width: 64,
                                sortable: false,
                                value: (row) => row.contactCount == null
                                    ? '-'
                                    : '${row.contactCount}人',
                              ),
                              AppDataGridColumn(
                                id: 'sales',
                                title: '销售员',
                                width: 120,
                                minWidth: 100,
                                widthMode: AppDataGridColumnWidthMode.fill,
                                sortable: false,
                                alignment: Alignment.centerLeft,
                                titleAlignment: Alignment.centerLeft,
                                value: (row) =>
                                    row.ownerNames?.trim().isNotEmpty == true
                                        ? row.ownerNames!
                                        : '-',
                              ),
                              AppDataGridColumn(
                                id: 'dynamic',
                                title: '最新动态',
                                width: 180,
                                sortable: false,
                                alignment: Alignment.centerLeft,
                                titleAlignment: Alignment.centerLeft,
                                value: (row) => row.latestDynamic ?? '',
                                cellBuilder: (context, row, _) {
                                  final text = row.latestDynamic?.trim();
                                  if (text == null || text.isEmpty) {
                                    return const Text('-');
                                  }
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _kPrimary.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _kPrimary.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          text,
                                          softWrap: false,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _kPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              AppDataGridColumn(
                                id: 'actions',
                                title: '操作',
                                width: 80,
                                sortable: false,
                                resizable: false,
                                pin: AppDataGridColumnPin.end,
                                value: (_) => '',
                                cellBuilder: (context, row, _) => Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GridActionIcon(
                                          tooltip: '编辑',
                                          icon: Icons.edit_outlined,
                                          onPressed: () async {
                                            final id = row.id?.trim();
                                            if (id == null || id.isEmpty) {
                                              showHyperToast(
                                                context,
                                                content: const Text(
                                                  '缺少品牌 ID，无法编辑',
                                                ),
                                              );
                                              return;
                                            }
                                            final ok =
                                                await showAddOrderDialog(
                                              context,
                                              initialBrandId: id,
                                            );
                                            if (ok && context.mounted) {
                                              context.lx
                                                  .find<HomeController>()
                                                  .refreshAll();
                                            }
                                          },
                                        ),
                                        _GridActionIcon(
                                          tooltip: '删除',
                                          icon: Icons.delete_outline,
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ];
                          final visibleColumns = [
                            for (final col in allColumns)
                              if (col.id == 'no' ||
                                  col.id == 'actions' ||
                                  !hidden.contains(col.id))
                                col,
                          ];
                          return AppDataGrid<OacBrand>.local(
                            key: ValueKey(
                              'brand-grid-${hidden.join(',')}-${c.sortKey.value}',
                            ),
                            height: 440,
                            rows: rows,
                            rowKey: (row) =>
                                row.id ?? row.brandCode ?? row.name ?? '',
                            sortable: true,
                            selectionMode: AppDataGridSelectionMode.multiple,
                            showInternalDividers: true,
                            headerBackgroundColor: const Color(0xFFFAFAFA),
                            textStyle: const TextStyle(fontSize: 12),
                            cellTextStyle: const TextStyle(fontSize: 12),
                            empty: const Center(
                              child: Text(
                                '暂无品牌数据',
                                style: TextStyle(color: _kMuted),
                              ),
                            ),
                            columns: visibleColumns,
                          );
                        }),
                        const SizedBox(height: 12),
                        Obx(() {
                          final page = c.pageNum.value;
                          final pages = c.totalPages;
                          final size = c.pageSize.value;
                          return Align(
                            alignment: Alignment.centerRight,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '共 ${c.total.value} 条',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _kMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _PageSizeMenu(
                                    size: size,
                                    onChanged: c.changePageSize,
                                  ),
                                  const SizedBox(width: 8),
                                  _PagerIcon(
                                    icon: Icons.chevron_left,
                                    enabled: page > 1,
                                    onPressed: () => c.goPage(page - 1),
                                  ),
                                  for (final p in _pageWindow(page, pages))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: _hInk(
                                        onPressed: () => c.goPage(p),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: p == page
                                                ? _kPrimary
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: p == page
                                                  ? _kPrimary
                                                  : _kBorder,
                                            ),
                                          ),
                                          child: Text(
                                            '$p',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: p == page
                                                  ? Colors.white
                                                  : const Color(0xFF595959),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  _PagerIcon(
                                    icon: Icons.chevron_right,
                                    enabled: page < pages,
                                    onPressed: () => c.goPage(page + 1),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '前往',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _PageJumpField(
                                    page: page,
                                    totalPages: pages,
                                    onJump: c.goPage,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '页',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ],
    );
  }
}

/// 企业视角表格（同页私有；与品牌表格列差异：名称 / 城市 / 关联品牌）。
class _EnterpriseDataGrid extends StatelessWidget {
  const _EnterpriseDataGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
    final c = controller;
    final rows = c.enterprises.toList();
    final loading = c.listLoading.value;
    final hidden = c.hiddenColumnIds.toSet();
    final _ = c.sortKey.value;
    final tagDictReady = c.tagOptions.isNotEmpty;
    if (loading && rows.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final page = c.pageNum.value;
    final size = c.pageSize.value;
    final allColumns = <AppDataGridColumn<OacEnterprise>>[
      AppDataGridColumn(
        id: 'no',
        title: '序号',
        width: 52,
        sortable: false,
        value: (row) {
          final i = rows.indexOf(row);
          return (page - 1) * size + i + 1;
        },
        type: AppDataGridColumnType.number,
      ),
      AppDataGridColumn(
        id: 'weight',
        title: '权重',
        width: 96,
        sortable: false,
        value: (row) => row.weight ?? 0,
        cellBuilder: (context, row, _) {
          final score = (row.weight ?? 0).clamp(0, 5);
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Icon(
                  i < score
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 14,
                  color: i < score
                      ? const Color(0xFFFAAD14)
                      : const Color(0xFFD9D9D9),
                );
              }),
            ),
          );
        },
      ),
      AppDataGridColumn(
        id: 'icon',
        title: '图标',
        width: 52,
        sortable: false,
        value: (row) => row.iconUrl ?? '',
        cellBuilder: (context, row, _) {
          final name = row.name?.trim() ?? '';
          final icon = row.iconUrl?.trim();
          final letter = name.isNotEmpty ? name.characters.first : '?';
          final color = _logoColor(name);
          if (icon != null && icon.isNotEmpty) {
            return Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  icon,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _LetterAvatar(
                    letter: letter,
                    color: color,
                  ),
                ),
              ),
            );
          }
          return Center(
            child: _LetterAvatar(letter: letter, color: color),
          );
        },
      ),
      AppDataGridColumn(
        id: 'name',
        title: '企业名称',
        width: 200,
        sortable: false,
        alignment: Alignment.centerLeft,
        titleAlignment: Alignment.centerLeft,
        value: (row) => row.name ?? '',
        cellBuilder: (context, row, _) {
          final name = row.name?.trim();
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              name?.isNotEmpty == true ? name! : '-',
              style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              softWrap: false,
            ),
          );
        },
      ),
      AppDataGridColumn(
        id: 'tags',
        title: '标签',
        width: 120,
        sortable: false,
        alignment: Alignment.centerLeft,
        titleAlignment: Alignment.centerLeft,
        value: (row) => _enterpriseTagLabels(row)
            .map(c.tagLabel)
            .where(_isDisplayableTag)
            .join(','),
        cellBuilder: (context, row, _) {
          final tags = [
            for (final raw in _enterpriseTagLabels(row))
              if (_isDisplayableTag(
                tagDictReady ? c.tagLabel(raw) : raw,
              ))
                tagDictReady ? c.tagLabel(raw) : raw,
          ];
          if (tags.isEmpty) {
            return const Text('-', style: TextStyle(fontSize: 12));
          }
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < tags.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  HyperTag(
                    label: tags[i],
                    style: const HyperTagStyle(
                      colorVariant: HyperTagColorVariant.soft,
                      baseColor: Color(0xFF722ED1),
                      radius: 3,
                      height: 20,
                      horizontalPadding: 6,
                      textStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      AppDataGridColumn(
        id: 'city',
        title: '所在城市',
        width: 100,
        sortable: false,
        value: (row) => row.city?.trim().isNotEmpty == true
            ? row.city!.trim()
            : '-',
      ),
      AppDataGridColumn(
        id: 'brandCount',
        title: '关联品牌数量',
        width: 108,
        sortable: false,
        value: (row) => row.brandCount ?? 0,
        type: AppDataGridColumnType.number,
        cellBuilder: (context, row, _) {
          final n = row.brandCount ?? 0;
          return Text(
            '$n',
            style: TextStyle(
              fontSize: 12,
              color: n > 0 ? _kPrimary : _kTitle,
              fontWeight: FontWeight.w500,
            ),
            softWrap: false,
          );
        },
      ),
      AppDataGridColumn(
        id: 'brandNames',
        title: '关联品牌',
        width: 100,
        sortable: false,
        alignment: Alignment.centerLeft,
        titleAlignment: Alignment.centerLeft,
        value: (row) => _enterpriseBrandNames(row),
      ),
      AppDataGridColumn(
        id: 'agency',
        title: '关联4A数量',
        width: 100,
        sortable: false,
        value: (row) => row.agencyCount ?? 0,
        type: AppDataGridColumnType.number,
        cellBuilder: (context, row, _) {
          final n = row.agencyCount ?? 0;
          return Text(
            '$n',
            style: TextStyle(
              fontSize: 12,
              color: n > 0 ? _kPrimary : _kTitle,
              fontWeight: FontWeight.w500,
            ),
            softWrap: false,
          );
        },
      ),
      AppDataGridColumn(
        id: 'orders',
        title: '订单数量',
        width: 96,
        value: (row) => row.orderCount ?? 0,
        type: AppDataGridColumnType.number,
        cellBuilder: (context, row, _) {
          final n = row.orderCount ?? 0;
          return Text(
            '$n',
            style: TextStyle(
              fontSize: 12,
              color: n > 0 ? _kPrimary : _kTitle,
              fontWeight: FontWeight.w500,
            ),
            softWrap: false,
          );
        },
      ),
      AppDataGridColumn(
        id: 'amount',
        title: '订单金额',
        width: 112,
        value: (row) =>
            num.tryParse(row.orderAmount?.trim() ?? '') ?? 0,
        type: AppDataGridColumnType.number,
        alignment: Alignment.centerRight,
        titleAlignment: Alignment.centerRight,
        cellBuilder: (context, row, _) => Text(
          _fmtMoney(row.orderAmount),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kAmount,
          ),
          softWrap: false,
        ),
      ),
      AppDataGridColumn(
        id: 'latestOrder',
        title: '最新订单时间',
        width: 160,
        value: (row) => row.latestOrderTime?.trim() ?? '',
        cellBuilder: (context, row, _) => Text(
          _fmtDateTime(row.latestOrderTime),
          style: const TextStyle(fontSize: 12),
          softWrap: false,
        ),
      ),
      AppDataGridColumn(
        id: 'contact',
        title: '联系人数量',
        width: 96,
        sortable: false,
        value: (row) =>
            row.contactCount == null ? '-' : '${row.contactCount}人',
      ),
      AppDataGridColumn(
        id: 'sales',
        title: '销售员',
        width: 100,
        minWidth: 88,
        widthMode: AppDataGridColumnWidthMode.fill,
        sortable: false,
        alignment: Alignment.centerLeft,
        titleAlignment: Alignment.centerLeft,
        value: (row) => row.ownerNames?.trim().isNotEmpty == true
            ? row.ownerNames!
            : '-',
      ),
      AppDataGridColumn(
        id: 'dynamic',
        title: '最新动态',
        width: 140,
        sortable: false,
        alignment: Alignment.centerLeft,
        titleAlignment: Alignment.centerLeft,
        value: (row) => row.latestDynamic ?? '',
        cellBuilder: (context, row, _) {
          final text = row.latestDynamic?.trim();
          if (text == null || text.isEmpty) {
            return const Text('-');
          }
          return Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  text,
                  softWrap: false,
                  style: const TextStyle(fontSize: 11, color: _kPrimary),
                ),
              ),
            ),
          );
        },
      ),
    ];
    final visibleColumns = [
      for (final col in allColumns)
        if (col.id == 'no' || !hidden.contains(col.id)) col,
    ];
    return AppDataGrid<OacEnterprise>.local(
      key: ValueKey(
        'enterprise-grid-${hidden.join(',')}-${c.sortKey.value}',
      ),
      height: 440,
      rows: rows,
      rowKey: (row) => row.id ?? row.name ?? '',
      sortable: true,
      selectionMode: AppDataGridSelectionMode.multiple,
      showInternalDividers: true,
      headerBackgroundColor: const Color(0xFFFAFAFA),
      textStyle: const TextStyle(fontSize: 12),
      cellTextStyle: const TextStyle(fontSize: 12),
      empty: const Center(
        child: Text(
          '暂无企业数据',
          style: TextStyle(color: _kMuted),
        ),
      ),
      columns: visibleColumns,
    );
    });
  }
}

/// 4A 公司视角表格。
class _AgencyDataGrid extends StatelessWidget {
  const _AgencyDataGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final rows = c.agencies.toList();
      final loading = c.listLoading.value;
      final hidden = c.hiddenColumnIds.toSet();
      final _ = c.sortKey.value;
      final tagDictReady = c.tagOptions.isNotEmpty;
      if (loading && rows.isEmpty) {
        return const SizedBox(
          height: 280,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final page = c.pageNum.value;
      final size = c.pageSize.value;
      final allColumns = <AppDataGridColumn<OacAgency>>[
        AppDataGridColumn(
          id: 'no',
          title: '序号',
          width: 52,
          sortable: false,
          value: (row) {
            final i = rows.indexOf(row);
            return (page - 1) * size + i + 1;
          },
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'weight',
          title: '权重',
          width: 96,
          sortable: false,
          value: (row) => row.weight ?? 0,
          cellBuilder: (context, row, _) {
            final score = (row.weight ?? 0).clamp(0, 5);
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return Icon(
                    i < score
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: i < score
                        ? const Color(0xFFFAAD14)
                        : const Color(0xFFD9D9D9),
                  );
                }),
              ),
            );
          },
        ),
        AppDataGridColumn(
          id: 'icon',
          title: '图标',
          width: 52,
          sortable: false,
          value: (row) => row.iconUrl ?? '',
          cellBuilder: (context, row, _) {
            final name = row.name?.trim() ?? '';
            final icon = row.iconUrl?.trim();
            final letter = name.isNotEmpty ? name.characters.first : '?';
            final color = _logoColor(name);
            if (icon != null && icon.isNotEmpty) {
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    icon,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _LetterAvatar(
                      letter: letter,
                      color: color,
                    ),
                  ),
                ),
              );
            }
            return Center(
              child: _LetterAvatar(letter: letter, color: color),
            );
          },
        ),
        AppDataGridColumn(
          id: 'name',
          title: '4A名称',
          width: 200,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => row.name ?? '',
          cellBuilder: (context, row, _) {
            final name = row.name?.trim();
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                name?.isNotEmpty == true ? name! : '-',
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                softWrap: false,
              ),
            );
          },
        ),
        AppDataGridColumn(
          id: 'tags',
          title: '标签',
          width: 120,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => _agencyTagLabels(row)
              .map(c.tagLabel)
              .where(_isDisplayableTag)
              .join(','),
          cellBuilder: (context, row, _) {
            final tags = [
              for (final raw in _agencyTagLabels(row))
                if (_isDisplayableTag(
                  tagDictReady ? c.tagLabel(raw) : raw,
                ))
                  tagDictReady ? c.tagLabel(raw) : raw,
            ];
            if (tags.isEmpty) {
              return const Text('-', style: TextStyle(fontSize: 12));
            }
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < tags.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    HyperTag(
                      label: tags[i],
                      style: const HyperTagStyle(
                        colorVariant: HyperTagColorVariant.soft,
                        baseColor: Color(0xFF722ED1),
                        radius: 3,
                        height: 20,
                        horizontalPadding: 6,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        AppDataGridColumn(
          id: 'city',
          title: '所在城市',
          width: 100,
          sortable: false,
          value: (row) => row.city?.trim().isNotEmpty == true
              ? row.city!.trim()
              : '-',
        ),
        AppDataGridColumn(
          id: 'brandCount',
          title: '关联品牌数量',
          width: 108,
          sortable: false,
          value: (row) => row.brandCount ?? 0,
          type: AppDataGridColumnType.number,
          cellBuilder: (context, row, _) {
            final n = row.brandCount ?? 0;
            return Text(
              '$n',
              style: TextStyle(
                fontSize: 12,
                color: n > 0 ? _kPrimary : _kTitle,
                fontWeight: FontWeight.w500,
              ),
              softWrap: false,
            );
          },
        ),
        AppDataGridColumn(
          id: 'brandNames',
          title: '关联品牌',
          width: 100,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => _agencyBrandNames(row),
          cellBuilder: (context, row, _) {
            final text = _agencyBrandNames(row);
            if (text == '-') {
              return const Text('-', style: TextStyle(fontSize: 12));
            }
            return Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: _kPrimary,
                fontWeight: FontWeight.w500,
              ),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        AppDataGridColumn(
          id: 'enterpriseCount',
          title: '关联企业数量',
          width: 108,
          sortable: false,
          value: (row) => row.enterpriseCount ?? 0,
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'orders',
          title: '订单数量',
          width: 96,
          value: (row) => row.orderCount ?? 0,
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'amount',
          title: '订单金额',
          width: 112,
          value: (row) =>
              num.tryParse(row.orderAmount?.trim() ?? '') ?? 0,
          type: AppDataGridColumnType.number,
          alignment: Alignment.centerRight,
          titleAlignment: Alignment.centerRight,
          cellBuilder: (context, row, _) => Text(
            _fmtMoney(row.orderAmount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kAmount,
            ),
            softWrap: false,
          ),
        ),
        AppDataGridColumn(
          id: 'latestOrder',
          title: '最新订单时间',
          width: 160,
          value: (row) => row.latestOrderTime?.trim() ?? '',
          cellBuilder: (context, row, _) => Text(
            _fmtDateTime(row.latestOrderTime),
            style: const TextStyle(fontSize: 12),
            softWrap: false,
          ),
        ),
        AppDataGridColumn(
          id: 'contact',
          title: '联系人数量',
          width: 96,
          sortable: false,
          value: (row) =>
              row.contactCount == null ? '-' : '${row.contactCount}人',
        ),
        AppDataGridColumn(
          id: 'sales',
          title: '销售员',
          width: 100,
          minWidth: 88,
          widthMode: AppDataGridColumnWidthMode.fill,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => row.ownerNames?.trim().isNotEmpty == true
              ? row.ownerNames!
              : '-',
        ),
        AppDataGridColumn(
          id: 'dynamic',
          title: '最新动态',
          width: 140,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => row.latestDynamic ?? '',
          cellBuilder: (context, row, _) {
            final text = row.latestDynamic?.trim();
            if (text == null || text.isEmpty) {
              return const Text('-');
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _kPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    text,
                    softWrap: false,
                    style: const TextStyle(fontSize: 11, color: _kPrimary),
                  ),
                ),
              ),
            );
          },
        ),
      ];
      final visibleColumns = [
        for (final col in allColumns)
          if (col.id == 'no' || !hidden.contains(col.id)) col,
      ];
      return AppDataGrid<OacAgency>.local(
        key: ValueKey(
          'agency-grid-${hidden.join(',')}-${c.sortKey.value}',
        ),
        height: 440,
        rows: rows,
        rowKey: (row) => row.id ?? row.name ?? '',
        sortable: true,
        selectionMode: AppDataGridSelectionMode.multiple,
        showInternalDividers: true,
        headerBackgroundColor: const Color(0xFFFAFAFA),
        textStyle: const TextStyle(fontSize: 12),
        cellTextStyle: const TextStyle(fontSize: 12),
        empty: const Center(
          child: Text(
            '暂无4A公司数据',
            style: TextStyle(color: _kMuted),
          ),
        ),
        columns: visibleColumns,
      );
    });
  }
}

/// 人视角表格（同页私有）。
class _PersonDataGrid extends StatelessWidget {
  const _PersonDataGrid({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final rows = c.persons.toList();
      final loading = c.listLoading.value;
      final hidden = c.hiddenColumnIds.toSet();
      final _ = c.sortKey.value;
      if (loading && rows.isEmpty) {
        return const SizedBox(
          height: 280,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final page = c.pageNum.value;
      final size = c.pageSize.value;
      final allColumns = <AppDataGridColumn<OacPerson>>[
        AppDataGridColumn(
          id: 'no',
          title: '序号',
          width: 52,
          sortable: false,
          value: (row) {
            final i = rows.indexOf(row);
            return (page - 1) * size + i + 1;
          },
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'icon',
          title: '图标',
          width: 52,
          sortable: false,
          value: (row) => row.avatarUrl ?? '',
          cellBuilder: (context, row, _) {
            final name = row.name?.trim() ?? '';
            final icon = row.avatarUrl?.trim();
            final letter = name.isNotEmpty ? name.characters.first : '?';
            final color = _logoColor(name);
            if (icon != null && icon.isNotEmpty) {
              return Center(
                child: ClipOval(
                  child: Image.network(
                    icon,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _CircleLetterAvatar(
                      letter: letter,
                      color: color,
                    ),
                  ),
                ),
              );
            }
            return Center(
              child: _CircleLetterAvatar(letter: letter, color: color),
            );
          },
        ),
        AppDataGridColumn(
          id: 'name',
          title: '联系人',
          width: 140,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => row.name ?? '',
          cellBuilder: (context, row, _) {
            final name = row.name?.trim();
            final title = row.title?.trim();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : '-',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                if (title != null && title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 11,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );
          },
        ),
        AppDataGridColumn(
          id: 'employer',
          title: '就职企业(最新)',
          width: 160,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => row.latestEmployer?.trim().isNotEmpty == true
              ? row.latestEmployer!.trim()
              : '-',
        ),
        AppDataGridColumn(
          id: 'enterpriseType',
          title: '企业类型',
          width: 100,
          sortable: false,
          value: (row) => row.enterpriseType ?? '',
          cellBuilder: (context, row, _) {
            final text = row.enterpriseType?.trim();
            if (text == null || text.isEmpty) {
              return const Text('-', style: TextStyle(fontSize: 12));
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: HyperTag(
                label: text,
                style: const HyperTagStyle(
                  colorVariant: HyperTagColorVariant.soft,
                  baseColor: Color(0xFF1677FF),
                  radius: 3,
                  height: 20,
                  horizontalPadding: 6,
                  textStyle: TextStyle(fontSize: 10),
                ),
              ),
            );
          },
        ),
        AppDataGridColumn(
          id: 'city',
          title: '所在城市',
          width: 140,
          sortable: false,
          value: (row) => row.city?.trim().isNotEmpty == true
              ? row.city!.trim()
              : '-',
        ),
        AppDataGridColumn(
          id: 'address',
          title: '办公地址',
          width: 140,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => row.address?.trim().isNotEmpty == true
              ? row.address!.trim()
              : '-',
        ),
        AppDataGridColumn(
          id: 'sameContact',
          title: '同企业联系人',
          width: 108,
          sortable: false,
          value: (row) => row.sameEnterpriseContactCount == null
              ? '-'
              : '${row.sameEnterpriseContactCount}人',
        ),
        AppDataGridColumn(
          id: 'brandCount',
          title: '关联品牌数量',
          width: 108,
          value: (row) => row.brandCount ?? 0,
          type: AppDataGridColumnType.number,
          cellBuilder: (context, row, _) {
            final n = row.brandCount ?? 0;
            return Text(
              '$n',
              style: TextStyle(
                fontSize: 12,
                color: n > 0 ? _kPrimary : _kTitle,
                fontWeight: FontWeight.w500,
              ),
              softWrap: false,
            );
          },
        ),
        AppDataGridColumn(
          id: 'brandNames',
          title: '关联品牌',
          width: 100,
          sortable: false,
          alignment: Alignment.centerLeft,
          titleAlignment: Alignment.centerLeft,
          value: (row) => _personBrandNames(row),
          cellBuilder: (context, row, _) {
            final text = _personBrandNames(row);
            if (text == '-') {
              return const Text('-', style: TextStyle(fontSize: 12));
            }
            return Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: _kPrimary,
                fontWeight: FontWeight.w500,
              ),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        AppDataGridColumn(
          id: 'enterpriseCount',
          title: '关联企业数量',
          width: 108,
          sortable: false,
          value: (row) => row.enterpriseCount ?? 0,
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'agencyCount',
          title: '关联4A数量',
          width: 100,
          sortable: false,
          value: (row) => row.agencyCount ?? 0,
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'orders',
          title: '订单数量',
          width: 96,
          value: (row) => row.orderCount ?? 0,
          type: AppDataGridColumnType.number,
        ),
        AppDataGridColumn(
          id: 'amount',
          title: '订单金额',
          width: 112,
          value: (row) =>
              num.tryParse(row.orderAmount?.trim() ?? '') ?? 0,
          type: AppDataGridColumnType.number,
          alignment: Alignment.centerRight,
          titleAlignment: Alignment.centerRight,
          cellBuilder: (context, row, _) => Text(
            _fmtMoney(row.orderAmount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kAmount,
            ),
            softWrap: false,
          ),
        ),
        AppDataGridColumn(
          id: 'latestOrder',
          title: '最新订单时间',
          width: 160,
          value: (row) => row.latestOrderTime?.trim() ?? '',
          cellBuilder: (context, row, _) => Text(
            _fmtDateTime(row.latestOrderTime),
            style: const TextStyle(fontSize: 12),
            softWrap: false,
          ),
        ),
      ];
      final visibleColumns = [
        for (final col in allColumns)
          if (col.id == 'no' || !hidden.contains(col.id)) col,
      ];
      return AppDataGrid<OacPerson>.local(
        key: ValueKey(
          'person-grid-${hidden.join(',')}-${c.sortKey.value}',
        ),
        height: 440,
        rows: rows,
        rowKey: (row) => row.id ?? row.name ?? '',
        sortable: true,
        selectionMode: AppDataGridSelectionMode.multiple,
        showInternalDividers: true,
        headerBackgroundColor: const Color(0xFFFAFAFA),
        textStyle: const TextStyle(fontSize: 12),
        cellTextStyle: const TextStyle(fontSize: 12),
        empty: const Center(
          child: Text(
            '暂无联系人数据',
            style: TextStyle(color: _kMuted),
          ),
        ),
        columns: visibleColumns,
      );
    });
  }
}

String _personBrandNames(OacPerson row) {
  final list = row.brandNameList;
  if (list != null && list.isNotEmpty) {
    final names = [
      for (final e in list)
        if (e.trim().isNotEmpty) e.trim(),
    ];
    if (names.isNotEmpty) return names.join('、');
  }
  final raw = row.brandNames?.trim();
  return (raw == null || raw.isEmpty) ? '-' : raw;
}

class _CircleLetterAvatar extends StatelessWidget {
  const _CircleLetterAvatar({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Constants / helpers ──────────────────────────────────────────────────────

/// 列设置可开关的列（序号 / 操作固定显示）。
const _kToggleableColumns = <(String id, String title)>[
  ('weight', '权重'),
  ('icon', '图标'),
  ('name', '品牌名称'),
  ('industry', '所属行业'),
  ('tags', '标签'),
  ('spokesperson', '最新代言人'),
  ('agency', '关联 4A'),
  ('enterprise', '关联企业'),
  ('orders', '订单数量'),
  ('amount', '订单金额'),
  ('latestOrder', '最新订单时间'),
  ('contact', '联系人'),
  ('sales', '销售员'),
  ('dynamic', '最新动态'),
];

const _kEnterpriseToggleableColumns = <(String id, String title)>[
  ('weight', '权重'),
  ('icon', '图标'),
  ('name', '企业名称'),
  ('tags', '标签'),
  ('city', '所在城市'),
  ('brandCount', '关联品牌数量'),
  ('brandNames', '关联品牌'),
  ('agency', '关联4A数量'),
  ('orders', '订单数量'),
  ('amount', '订单金额'),
  ('latestOrder', '最新订单时间'),
  ('contact', '联系人数量'),
  ('sales', '销售员'),
  ('dynamic', '最新动态'),
];

const _kAgencyToggleableColumns = <(String id, String title)>[
  ('weight', '权重'),
  ('icon', '图标'),
  ('name', '4A名称'),
  ('tags', '标签'),
  ('city', '所在城市'),
  ('brandCount', '关联品牌数量'),
  ('brandNames', '关联品牌'),
  ('enterpriseCount', '关联企业数量'),
  ('orders', '订单数量'),
  ('amount', '订单金额'),
  ('latestOrder', '最新订单时间'),
  ('contact', '联系人数量'),
  ('sales', '销售员'),
  ('dynamic', '最新动态'),
];

const _kPersonToggleableColumns = <(String id, String title)>[
  ('icon', '图标'),
  ('name', '联系人'),
  ('employer', '就职企业(最新)'),
  ('enterpriseType', '企业类型'),
  ('city', '所在城市'),
  ('address', '办公地址'),
  ('sameContact', '同企业联系人'),
  ('brandCount', '关联品牌数量'),
  ('brandNames', '关联品牌'),
  ('enterpriseCount', '关联企业数量'),
  ('agencyCount', '关联4A数量'),
  ('orders', '订单数量'),
  ('amount', '订单金额'),
  ('latestOrder', '最新订单时间'),
];

const _kEntityTabs = ['品牌', '企业', '4A公司', '人'];

final _kCardDecoration = BoxDecoration(
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
);

String _fmtInt(int? v) {
  if (v == null) return '-';
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtMoney(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final n = num.tryParse(raw.trim());
  if (n == null) return raw.startsWith('¥') ? raw : '¥$raw';
  // 接口返回已是「万」；展示固定带万。新建订单录入仍用「元」。
  if (n.abs() < 0.005) return '¥0万';
  final text =
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  return '¥$text万';
}

String? _fmtMomRate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final n = num.tryParse(raw.trim());
  if (n == null) {
    final text = raw.contains('%') ? raw : '$raw%';
    return '↗ 环比 $text';
  }
  final sign = n > 0 ? '+' : '';
  final arrow = n < 0 ? '↘' : '↗';
  return '$arrow 环比 $sign${n.toString()}%';
}

String _fmtDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final s = raw.trim();
  return s.length >= 10 ? s.substring(0, 10) : s;
}

String? _fmtTimeOnly(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  if (s.length >= 16) return s.substring(11, 16);
  if (s.length >= 19) return s.substring(11, 16);
  return null;
}

String _fmtDateTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  return raw.trim();
}

List<String> _brandTagLabels(OacBrand row) {
  final out = <String>[];
  final list = row.tagList;
  if (list != null && list.isNotEmpty) {
    for (final t in list) {
      final v = t.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
  } else {
    final tags = row.tags?.trim();
    if (tags != null && tags.isNotEmpty) {
      for (final part in tags.split(RegExp(r'[,，;；\s]+'))) {
        final v = part.trim();
        if (v.isNotEmpty && !out.contains(v)) out.add(v);
      }
    }
  }
  return out;
}

List<String> _enterpriseTagLabels(OacEnterprise row) {
  final out = <String>[];
  final list = row.tagList;
  if (list != null && list.isNotEmpty) {
    for (final t in list) {
      final v = t.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
  } else {
    final tags = row.tags?.trim();
    if (tags != null && tags.isNotEmpty) {
      for (final part in tags.split(RegExp(r'[,，;；\s]+'))) {
        final v = part.trim();
        if (v.isNotEmpty && !out.contains(v)) out.add(v);
      }
    }
  }
  return out;
}

String _enterpriseBrandNames(OacEnterprise row) {
  final list = row.brandNameList;
  if (list != null && list.isNotEmpty) {
    final names = [
      for (final e in list)
        if (e.trim().isNotEmpty) e.trim(),
    ];
    if (names.isNotEmpty) return names.join('、');
  }
  final raw = row.brandNames?.trim();
  if (raw != null && raw.isNotEmpty) return raw;
  return '-';
}

List<String> _agencyTagLabels(OacAgency row) {
  final out = <String>[];
  final list = row.tagList;
  if (list != null && list.isNotEmpty) {
    for (final t in list) {
      final v = t.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
  } else {
    final tags = row.tags?.trim();
    if (tags != null && tags.isNotEmpty) {
      for (final part in tags.split(RegExp(r'[,，;；\s]+'))) {
        final v = part.trim();
        if (v.isNotEmpty && !out.contains(v)) out.add(v);
      }
    }
  }
  return out;
}

String _agencyBrandNames(OacAgency row) {
  final list = row.brandNameList;
  if (list != null && list.isNotEmpty) {
    final names = [
      for (final e in list)
        if (e.trim().isNotEmpty) e.trim(),
    ];
    if (names.isNotEmpty) return names.join('、');
  }
  final raw = row.brandNames?.trim();
  if (raw != null && raw.isNotEmpty) return raw;
  return '-';
}

Future<void> _openAddBrandTags(
  BuildContext context,
  HomeController c,
  OacBrand row,
) async {
  // 选项与回填均用字典 dictLabel，保证与筛选下拉一致。
  final initial = <String>[
    for (final raw in _brandTagLabels(row))
      if (c.tagLabel(raw).isNotEmpty &&
          _isDisplayableTag(c.tagLabel(raw)))
        c.tagLabel(raw),
  ];
  final options = [
    for (final o in c.tagOptions)
      if (_isDisplayableTag(o)) o,
  ];
  final selected = await showHyperDialog<List<String>>(
    context: context,
    builder: (dialogContext) => _AddBrandTagsDialog(
      initialTags: initial,
      options: options,
    ),
  );
  if (selected == null || !context.mounted) return;
  c.applyBrandTags(row, selected);
  showHyperToast(context, content: const Text('标签已更新'));
}

/// 品牌标签不展示纯英文（如 international）。
bool _isDisplayableTag(String tag) {
  final t = tag.trim();
  if (t.isEmpty) return false;
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(t);
}


Color _logoColor(String name) {
  if (name.isEmpty) return _kPrimary;
  const colors = [
    Color(0xFF1677FF),
    Color(0xFF13C2C2),
    Color(0xFF722ED1),
    Color(0xFFFAAD14),
    Color(0xFFEB2F96),
    Color(0xFF52C41A),
    Color(0xFFFA541C),
    Color(0xFF2F54EB),
  ];
  return colors[name.hashCode.abs() % colors.length];
}

List<int> _pageWindow(int current, int total) {
  if (total <= 0) return const [1];
  final end = (current + 2).clamp(1, total);
  final start = (end - 4).clamp(1, total);
  return [for (var i = start; i <= end; i++) i];
}

InputDecoration _filterDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    hintText: hint.isEmpty ? null : hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFC9CDD4)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _kPrimary),
    ),
  );
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SideNav extends StatefulWidget {
  const _SideNav({
    required this.selectedId,
    required this.onSelect,
  });

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  State<_SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<_SideNav> {
  /// [children] 非空时为二级分组（如 HRM·组织），叶子项 [children] 为 null。
  static const _groups = <({
    String id,
    String label,
    List<
        ({
          String id,
          String label,
          IconData icon,
          List<({String id, String label, IconData icon})>? children,
        })> children,
  })>[
    (
      id: 'crm',
      label: '户外传媒CRM',
      children: [
        (
          id: 'orders',
          label: '订单管理',
          icon: Icons.receipt_long_outlined,
          children: null,
        ),
        (
          id: 'customers',
          label: '客户档案管理',
          icon: Icons.folder_shared_outlined,
          children: null,
        ),
      ],
    ),
    (
      id: 'hrm',
      label: 'HRM',
      children: [
        (
          id: 'hrm_org_group',
          label: '组织',
          icon: Icons.apartment_outlined,
          children: [
            (id: 'hrm_org', label: '部门', icon: Icons.account_tree_outlined),
            (id: 'hrm_post', label: '职务', icon: Icons.badge_outlined),
            (
              id: 'hrm_post_seq',
              label: '序列',
              icon: Icons.linear_scale_outlined,
            ),
            (id: 'hrm_seat', label: '编制', icon: Icons.event_seat_outlined),
            (id: 'hrm_workplace', label: '工作地点', icon: Icons.place_outlined),
          ],
        ),
        (
          id: 'hrm_people_group',
          label: '人员',
          icon: Icons.groups_outlined,
          children: [
            (
              id: 'hrm_archive',
              label: '花名册',
              icon: Icons.contact_page_outlined,
            ),
            (
              id: 'hrm_onboarding',
              label: '入职管理',
              icon: Icons.person_add_alt_1_outlined,
            ),
            (
              id: 'hrm_regularization',
              label: '转正管理',
              icon: Icons.verified_outlined,
            ),
            (
              id: 'hrm_offboarding',
              label: '离职管理',
              icon: Icons.person_remove_outlined,
            ),
            (
              id: 'hrm_directory',
              label: '企业通讯录',
              icon: Icons.contacts_outlined,
            ),
          ],
        ),
      ],
    ),
    (
      id: 'srm',
      label: 'SRM供应商',
      children: [
        (
          id: 'srm_supplier',
          label: '供应商列表',
          icon: Icons.storefront_outlined,
          children: null,
        ),
        (
          id: 'srm_purchase_order',
          label: '采购订单列表',
          icon: Icons.shopping_cart_outlined,
          children: null,
        ),
      ],
    ),
  ];

  late final Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = {
      for (final g in _groups) g.id,
      for (final g in _groups)
        for (final item in g.children)
          if (item.children != null) item.id,
    };
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Widget _leafTile({
    required String id,
    required String label,
    required IconData icon,
    double indent = 0,
  }) {
    final selected = widget.selectedId == id;
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 2),
      child: _hInk(
        onPressed: () => widget.onSelect(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? _kPrimary : _kMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? _kPrimary : _kMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSideWidth,
      decoration: const BoxDecoration(
        color: _kSideBg,
        border: Border(right: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: const Text(
              '媒花易数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTitle,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
              children: [
                for (final group in _groups) ...[
                  _hInk(
                    onPressed: () => _toggleGroup(group.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kTitle,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Icon(
                            _expanded.contains(group.id)
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            size: 16,
                            color: _kMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_expanded.contains(group.id))
                    for (final item in group.children) ...[
                      if (item.children == null)
                        _leafTile(
                          id: item.id,
                          label: item.label,
                          icon: item.icon,
                        )
                      else ...[
                        _hInk(
                          onPressed: () => _toggleGroup(item.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(item.icon, size: 16, color: _kTitle),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kTitle,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _expanded.contains(item.id)
                                      ? Icons.expand_more
                                      : Icons.chevron_right,
                                  size: 16,
                                  color: _kMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_expanded.contains(item.id))
                          for (final leaf in item.children!)
                            _leafTile(
                              id: leaf.id,
                              label: leaf.label,
                              icon: leaf.icon,
                              indent: 12,
                            ),
                      ],
                    ],
                  const SizedBox(height: 8),
                ],
                // 与「户外传媒CRM / HRM」平级：播控（进入独立播控壳）
                _hInk(
                  onPressed: () => widget.onSelect('bokong'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tv_outlined,
                          size: 16,
                          color: _kTitle,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '播控',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kTitle,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: _kMuted,
                        ),
                      ],
                    ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.searchController,
    required this.displayName,
    required this.syncing,
    required this.onAddOrder,
    required this.onSync,
    required this.onLogout,
  });

  final TextEditingController searchController;
  final String displayName;
  final bool syncing;
  final VoidCallback onAddOrder;
  final VoidCallback onSync;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: '全局搜索：品牌/企业/4A/联系人/订单号',
                hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: _kMuted),
                filled: true,
                fillColor: _kPageBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kPrimary, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          HyperButton.filled(
            onPressed: onAddOrder,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加订单'),
          ),
          const SizedBox(width: 8),
          HyperButton.outlined(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('导出'),
          ),
          const SizedBox(width: 8),
          HyperButton.outlined(
            onPressed: syncing ? null : onSync,
            loading: syncing,
            icon: const Icon(Icons.sync, size: 16),
            label: const Text('同步'),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') onLogout();
            },
            offset: const Offset(0, 40),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('退出登录')),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _kPrimary.withValues(alpha: 0.12),
              child: Text(
                displayName.characters.first,
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 订单管理工具栏按钮（lemon_ui HyperButton）。
class _TableTool extends StatelessWidget {
  const _TableTool({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: HyperButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        size: HyperButtonSizeVariant.small,
      ),
    );
  }
}

class _ColumnSettingsPopover extends StatelessWidget {
  const _ColumnSettingsPopover({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '显示 / 隐藏列',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5969),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Obx(() {
                final hidden = controller.hiddenColumnIds.toSet();
                final cols = controller.isPersonTab
                    ? _kPersonToggleableColumns
                    : controller.isAgencyTab
                        ? _kAgencyToggleableColumns
                        : controller.isEnterpriseTab
                            ? _kEnterpriseToggleableColumns
                            : _kToggleableColumns;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (id, title) in cols)
                        _hInk(
                          onPressed: () => controller.setColumnVisible(
                            id,
                            hidden.contains(id),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                HyperCheckbox.rounded(
                                  value: !hidden.contains(id),
                                  onChanged: (v) =>
                                      controller.setColumnVisible(
                                    id,
                                    v ?? false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kTitle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortPopover extends StatelessWidget {
  const _SortPopover({
    required this.controller,
    required this.onClose,
  });

  final HomeController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 168,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Obx(() {
          final current = controller.sortKey.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in kBrandListSortOptions)
                _hInk(
                  onPressed: () {
                    onClose();
                    controller.applySort(option);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: option.key == current
                            ? const Color(0xFFC9CDD4)
                            : _kTitle,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TableIconButton extends StatelessWidget {
  const _TableIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: _kBorder),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(icon, size: 16, color: const Color(0xFF4E5969)),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridActionIcon extends StatelessWidget {
  const _GridActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _hInk(
        onPressed: onPressed,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: _kPrimary),
        ),
      ),
    );
  }
}

/// 每页条数：用 PopupMenu + 自适应宽度，避免 DropdownButtonFormField 在文字缩放下右侧溢出。
class _PageSizeMenu extends StatelessWidget {
  const _PageSizeMenu({
    required this.size,
    required this.onChanged,
  });

  final int size;
  final ValueChanged<int> onChanged;

  static const _options = [10, 20, 50];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: _kBorder),
      ),
      child: PopupMenuButton<int>(
        initialValue: size,
        tooltip: '每页条数',
        padding: EdgeInsets.zero,
        onSelected: onChanged,
        itemBuilder: (context) => [
          for (final v in _options)
            PopupMenuItem<int>(
              value: v,
              height: 36,
              child: Text('$v条/页'),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$size条/页',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4E5969),
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Color(0xFF4E5969),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagerIcon extends StatelessWidget {
  const _PagerIcon({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _hInk(
      onPressed: enabled ? onPressed : null,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF4E5969) : const Color(0xFFC9CDD4),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.trend,
    this.subtitle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String? trend;
  final String? subtitle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final trendDown =
        trend != null && (trend!.startsWith('↘') || trend!.contains('环比 -'));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kTitle,
                  height: 1.1,
                ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Text(
              trend!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: trendDown ? _kTrendDown : _kTrendUp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
          ] else
            const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.width,
    required this.label,
    required this.child,
  });

  final double width;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// 品牌 / 企业等视角分段切换（胶囊分段，避免散落独立描边按钮）。
class _EntityTabBar extends StatelessWidget {
  const _EntityTabBar({
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _kEntityTabs.length; i++)
            _hInk(
              onPressed: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected == i ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selected == i
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _kEntityTabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected == i ? FontWeight.w600 : FontWeight.w400,
                    color: selected == i
                        ? _kPrimary
                        : const Color(0xFF4E5969),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 筛选区下拉：与关键词输入框对齐的描边输入风（白底、6 圆角、固定宽高）。
class _FilterSelect<T> extends StatelessWidget {
  const _FilterSelect({
    required this.width,
    required this.value,
    required this.options,
    required this.onChanged,
    this.searchable = false,
    this.placeholder = '全部',
  });

  final double width;
  final T? value;
  final List<HyperSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool searchable;
  final String placeholder;

  static const _arrow = Color(0xFF86909C);
  static const _placeholder = Color(0xFFC9CDD4);

  @override
  Widget build(BuildContext context) {
    final empty = value == null;
    return HyperSelect<T>(
      value: value,
      placeholder: placeholder,
      allowDeselect: true,
      searchable: searchable,
      size: HyperButtonSizeVariant.small,
      options: options,
      onChanged: onChanged,
      style: HyperSelectStyle(
        width: width,
        arrowSize: 14,
        arrowSpacing: 6,
        arrowColor: _arrow,
        foregroundColor: empty ? _placeholder : _kTitle,
        buttonStyle: HyperButtonStyle(
          width: width,
          height: 36,
          background: HyperFill.color(Colors.white),
          boxBorder: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(6),
          padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
          textStyle: TextStyle(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w400,
            color: empty ? _placeholder : _kTitle,
          ),
          boxShadow: const [],
          hoveredBoxShadow: const [],
          pressedBoxShadow: const [],
          focusedBoxShadow: const [],
        ),
      ),
    );
  }
}

class _PageJumpField extends StatefulWidget {
  const _PageJumpField({
    required this.page,
    required this.totalPages,
    required this.onJump,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onJump;

  @override
  State<_PageJumpField> createState() => _PageJumpFieldState();
}

class _PageJumpFieldState extends State<_PageJumpField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.page}');
  }

  @override
  void didUpdateWidget(covariant _PageJumpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page &&
        _ctrl.text.trim() != '${widget.page}') {
      _ctrl.text = '${widget.page}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null) {
      _ctrl.text = '${widget.page}';
      return;
    }
    final target = n.clamp(1, widget.totalPages);
    _ctrl.text = '$target';
    if (target != widget.page) widget.onJump(target);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kPrimary),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// 订单管理 · 品牌行「添加标签」多选弹窗。
class _AddBrandTagsDialog extends StatefulWidget {
  const _AddBrandTagsDialog({
    required this.initialTags,
    required this.options,
  });

  final List<String> initialTags;
  final List<String> options;

  @override
  State<_AddBrandTagsDialog> createState() => _AddBrandTagsDialogState();
}

class _AddBrandTagsDialogState extends State<_AddBrandTagsDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialTags};
  }

  void _toggle(String tag, bool? checked) {
    setState(() {
      if (checked == true) {
        _selected.add(tag);
      } else {
        _selected.remove(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 不用 HyperSelect 单行折叠（+N）；已选用 Wrap 展全，下方勾选列表。
    return HyperDialog(
      title: const Text('添加标签'),
      scrollable: false,
      style: const HyperDialogStyle(maxWidth: 560),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: _selected.isEmpty
                ? const Text(
                    '请选择标签',
                    style: TextStyle(fontSize: 13, color: _kMuted),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in _selected)
                        HyperChip.input(
                          label: tag,
                          onDeleted: () => _toggle(tag, false),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: widget.options.isEmpty
                ? const Center(
                    child: Text(
                      '暂无标签选项',
                      style: TextStyle(fontSize: 13, color: _kMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: widget.options.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: _kBorder,
                    ),
                    itemBuilder: (context, index) {
                      final tag = widget.options[index];
                      final checked = _selected.contains(tag);
                      return HyperPressable(
                        onTap: () => _toggle(tag, !checked),
                        builder: (context, states, child) => child!,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              HyperCheckbox(
                                value: checked,
                                onChanged: (v) => _toggle(tag, v),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kTitle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      actions: [
        HyperButton.filled(
          onPressed: () =>
              Navigator.of(context).pop<List<String>>(_selected.toList()),
          label: const Text('确定'),
        ),
        HyperButton.outlined(
          onPressed: () => Navigator.of(context).pop(),
          label: const Text('取消'),
        ),
      ],
    );
  }
}
