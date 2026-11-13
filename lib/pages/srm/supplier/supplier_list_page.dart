import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import '../../../models/srm_supplier.dart';
import '../../home_controller.dart';
import 'detail/supplier_detail_page.dart';
import 'dialogs/supplier_import_dialog.dart';
import 'edit/supplier_edit_page.dart';
import 'supplier_list_controller.dart';
import 'widgets/column_header_filter.dart';

const _kFilterableColumnIds = {
  'supplierType',
  'category',
  'nature',
  'teamSize',
  'coop',
  'settle',
  'city',
};

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kGold = Color(0xFFFAAD14);
const _kPurple = Color(0xFF722ED1);

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

const _kToggleableColumns = <(String id, String title)>[
  ('code', '编号'),
  ('weight', '权重星级'),
  ('icon', '图标'),
  ('shortName', '供应商简称'),
  ('fullName', '主体全称'),
  ('supplierType', '供应商类型'),
  ('category', '供应品类'),
  ('nature', '企业性质'),
  ('teamSize', '团队规模'),
  ('coop', '合作模式'),
  ('settle', '结算方式'),
  ('city', '所在城市'),
  ('address', '详细地址'),
  ('contact', '联系人'),
  ('staff', '我方对接人'),
  ('createTime', '创建时间'),
  ('dynamic', '最新动态(AI)'),
];

class SupplierListPage extends StatelessWidget {
  const SupplierListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<SupplierListController>(SupplierListController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _pageScroll = ScrollController();

  @override
  void dispose() {
    _pageScroll.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    try {
      context.lx.find<HomeController>().sideMenu.value = 'orders';
    } catch (_) {
      AppToast.show(context: context, title: '无法返回上一页');
    }
  }

  Future<void> _export(BuildContext context, SupplierListController c) async {
    if (c.exporting.value) return;
    try {
      final file = await c.exportSelected();
      if (!context.mounted) return;
      final savedUri = await FilePicker.saveFile(
        dialogTitle: '导出供应商',
        fileName: file.fileName,
        bytes: file.bytes,
        mimeType: 'application/vnd.ms-excel',
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );
      if (!context.mounted) return;
      if (savedUri == null) return;
      AppToast.show(context: context, title: '导出成功');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context: context, title: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SupplierListController>();
    return ColoredBox(
      color: _kPageBg,
      child: Scrollbar(
        controller: _pageScroll,
        thumbVisibility: true,
        child: ListView(
          controller: _pageScroll,
          primary: false,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ── 顶栏：后退/前进 · 当前位置 · 搜索 ─────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  _NavIconBtn(
                    icon: Icons.chevron_left,
                    tooltip: '向后',
                    onPressed: () => _goBack(context),
                  ),
                  const SizedBox(width: 2),
                  _NavIconBtn(
                    icon: Icons.chevron_right,
                    tooltip: '向前',
                    onPressed: () {
                      AppToast.show(context: context, title: '已是最新位置');
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '当前位置 / 供应商管理 / 供应商列表',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4E5969)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: c.topSearchCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: _searchDecoration(
                          '搜索名称 / 代码 / 法人 / 地址',
                        ),
                        onSubmitted: (_) => c.search(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final k = c.kpi.value;
              return LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  const count = 4;
                  const minCard = 148.0;
                  final totalGap = gap * (count - 1);
                  final cardW = constraints.maxWidth.isFinite
                      ? ((constraints.maxWidth - totalGap) / count)
                          .clamp(minCard, double.infinity)
                      : minCard;
                  final rowW = cardW * count + totalGap;
                  final row = Row(
                    children: [
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '供应商数量',
                          value: '${k.total}',
                          subtitle: '全部档案',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '物业租赁',
                          value: '${k.propertyLeaseCount}',
                          subtitle: '按供应商类型统计',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '媒介采购',
                          value: '${k.mediaPurchaseCount}',
                          subtitle: '按供应商类型统计',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '黑名单',
                          value: '${k.blacklistCount}',
                          subtitle: '需关注',
                          valueColor: k.blacklistCount > 0
                              ? const Color(0xFFFF4D4F)
                              : null,
                        ),
                      ),
                    ],
                  );
                  if (rowW <= constraints.maxWidth) return row;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: rowW, child: row),
                  );
                },
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final expanded = c.filterExpanded.value;
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: _kCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        _FilterField(
                          width: 200,
                          label: '名称',
                          child: TextField(
                            controller: c.keywordCtrl,
                            decoration: _inputDecoration(
                              '名称 / 代码 / 法人 / 地址 / 联系人',
                            ),
                            onSubmitted: (_) => c.search(),
                          ),
                        ),
                        _FilterField(
                          width: 148,
                          label: '供应商类型',
                          child: _FilterSelect(
                            value: c.supplierType.value,
                            options:
                                SupplierListController.supplierTypeOptions,
                            onChanged: (v) => c.supplierType.value = v,
                          ),
                        ),
                        _FilterField(
                          width: 160,
                          label: '地址',
                          child: TextField(
                            controller: c.addressCtrl,
                            decoration: _inputDecoration('经营 / 注册 / 地区'),
                            onSubmitted: (_) => c.search(),
                          ),
                        ),
                        _FilterField(
                          width: 140,
                          label: '联系人',
                          child: TextField(
                            controller: c.contactCtrl,
                            decoration: _inputDecoration('姓名 / 手机号'),
                            onSubmitted: (_) => c.search(),
                          ),
                        ),
                        _FilterField(
                          width: 140,
                          label: '销售人员',
                          child: TextField(
                            controller: c.staffCtrl,
                            decoration: _inputDecoration('对接人姓名'),
                            onSubmitted: (_) => c.search(),
                          ),
                        ),
                      ],
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          _FilterField(
                            width: 200,
                            label: '团队规模',
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: c.teamSizeMinCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters:  [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _inputDecoration('最小'),
                                    onSubmitted: (_) => c.search(),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '-',
                                    style: TextStyle(color: _kMuted),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: c.teamSizeMaxCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters:  [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _inputDecoration('最大'),
                                    onSubmitted: (_) => c.search(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _FilterField(
                            width: 148,
                            label: '合作模式',
                            child: _FilterSelect(
                              value: c.cooperationMode.value,
                              options: SupplierListController
                                  .cooperationModeOptions,
                              onChanged: (v) => c.cooperationMode.value = v,
                            ),
                          ),
                          _FilterField(
                            width: 148,
                            label: '结算方式',
                            child: _FilterSelect(
                              value: c.settlementMethod.value,
                              options: SupplierListController
                                  .settlementMethodOptions,
                              labelBuilder: _settleFilterLabel,
                              selectedOptions: _settleSelectedOption(
                                c.settlementMethod.value,
                              ),
                              onChanged: c.setSettlementFromTop,
                            ),
                          ),
                          _FilterField(
                            width: 140,
                            label: '合作状态',
                            child: _FilterSelect(
                              value: c.status.value,
                              options: SupplierListController.statusOptions,
                              onChanged: (v) => c.status.value = v,
                            ),
                          ),
                          _FilterField(
                            width: 120,
                            label: '黑名单',
                            child: _FilterSelect(
                              value: c.blacklistStatus.value,
                              options: SupplierListController.blacklistOptions,
                              onChanged: (v) => c.blacklistStatus.value = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        AppButton.primary(
                          onPressed: c.search,
                          leading: const Icon(Icons.search, size: 16),
                          child: const Text('查询'),
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          onPressed: c.resetFilters,
                          leading: const Icon(Icons.refresh, size: 16),
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                    Center(
                      child: AppInkWell(
                        onPressed: c.toggleFilterExpanded,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 22,
                            color: _kMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: _kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: Text(
                            '供应商列表 · 共 ${c.total.value} 条',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kTitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Builder(
                          builder: (anchorCtx) => AppButton.outline(
                            onPressed: () {
                              AppPopover.show<void>(
                                context: anchorCtx,
                                alignment: Alignment.topRight,
                                anchorAlignment: Alignment.bottomRight,
                                builder: (_) =>
                                    _ColumnSettingsPopover(controller: c),
                              );
                            },
                            leading: const Icon(
                              Icons.view_column_outlined,
                              size: 16,
                            ),
                            child: const Text('列设置'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton.primary(
                          onPressed: () async {
                            final ok = await showSupplierEditDialog(context);
                            if (ok && context.mounted) {
                              await c.refreshAll(clearSelected: true);
                            }
                          },
                          leading: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                          child: const Text('新建供应商'),
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          onPressed: () async {
                            final ok = await showSupplierImportDialog(context);
                            if (ok && context.mounted) {
                              await c.refreshAll(clearSelected: true);
                            }
                          },
                          leading: const Icon(Icons.upload_outlined, size: 16),
                          child: const Text('导入'),
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          onPressed: () => _export(context, c),
                          leading:
                              const Icon(Icons.download_outlined, size: 16),
                          child: const Text('导出'),
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          onPressed: c.loading.value
                              ? null
                              : () => c.refreshAll(clearSelected: true),
                          leading: c.loading.value
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync, size: 16),
                          child: const Text('刷新'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final hidden = c.hiddenColumnIds.toSet();
                    final list = c.rows.toList();
                    final err = c.errorMessage.value;
                    if (c.loading.value && list.isEmpty) {
                      return const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (err != null && list.isEmpty) {
                      return SizedBox(
                        height: 240,
                        child: Center(
                          child: Text(
                            err,
                            style: const TextStyle(color: Color(0xFFFF4D4F)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final page = c.pageNum.value;
                    final size = c.pageSize.value;
                    final gridHeight =
                        (MediaQuery.sizeOf(context).height * 0.48)
                            .clamp(420.0, 620.0);
                    final allColumns = <AppDataGridColumn<SrmSupplier>>[
                      AppDataGridColumn(
                        id: 'no',
                        title: '序号',
                        width: 56,
                        value: (row) {
                          final i = list.indexOf(row);
                          return (page - 1) * size + i + 1;
                        },
                        type: AppDataGridColumnType.number,
                        cellBuilder: (context, row, value) =>
                            _cellText('${value ?? ''}'),
                      ),
                      AppDataGridColumn(
                        id: 'code',
                        title: '编号',
                        width: 140,
                        value: (row) => row.supplierCode ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.supplierCode)),
                      ),
                      AppDataGridColumn(
                        id: 'weight',
                        title: '权重星级',
                        width: 110,
                        value: (row) => row.weight ?? 0,
                        cellBuilder: (context, row, _) =>
                            Center(child: _Stars(weight: row.weight ?? 0)),
                      ),
                      AppDataGridColumn(
                        id: 'icon',
                        title: '图标',
                        width: 56,
                        value: (row) => row.shortName ?? '',
                        cellBuilder: (context, row, _) {
                          final name = row.shortName?.trim() ?? '';
                          if (name.isEmpty) return const SizedBox.shrink();
                          final logo = row.logoFile?.trim() ?? '';
                          if (logo.isNotEmpty) {
                            return Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  logo,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _letterIcon(name),
                                ),
                              ),
                            );
                          }
                          return Center(child: _letterIcon(name));
                        },
                      ),
                      AppDataGridColumn(
                        id: 'shortName',
                        title: '供应商简称',
                        width: 160,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.shortName ?? '-',
                        cellBuilder: (context, row, _) {
                          final name = row.shortName?.trim() ?? '';
                          if (name.isEmpty) {
                            return _cellText(
                              '-',
                              alignment: Alignment.centerLeft,
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: AppInkWell(
                              onPressed: () {
                                final id = row.id?.trim();
                                if (id == null || id.isEmpty) {
                                  AppToast.show(
                                    context: context,
                                    title: '缺少供应商 ID',
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        SupplierDetailPage(supplierId: id),
                                  ),
                                );
                              },
                              child: Text(
                                name,
                                softWrap: false,
                                style: const TextStyle(
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'fullName',
                        title: '主体全称',
                        width: 200,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.fullName ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          _dash(row.fullName),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'supplierType',
                        title: '供应商类型',
                        width: 130,
                        value: (row) => row.supplierType ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.supplierType)),
                      ),
                      AppDataGridColumn(
                        id: 'category',
                        title: '供应品类',
                        width: 130,
                        value: (row) => row.supplyCategoryText ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.supplyCategoryText)),
                      ),
                      AppDataGridColumn(
                        id: 'nature',
                        title: '企业性质',
                        width: 110,
                        value: (row) => row.enterpriseNature ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.enterpriseNature)),
                      ),
                      AppDataGridColumn(
                        id: 'teamSize',
                        title: '团队规模',
                        width: 110,
                        value: (row) => row.teamSize,
                        type: AppDataGridColumnType.number,
                        cellBuilder: (context, row, value) =>
                            _cellText(value == null ? '-' : '$value'),
                      ),
                      AppDataGridColumn(
                        id: 'coop',
                        title: '合作模式',
                        width: 120,
                        value: (row) => row.cooperationMode ?? '-',
                        cellBuilder: (context, row, _) {
                          final text = row.cooperationMode?.trim() ?? '';
                          if (text.isEmpty) return _cellText('-');
                          return Center(
                            child: AppBadge.custom(
                              color: _kPurple,
                              appearance: AppBadgeStyle.soft,
                              shape: AppBadgeShape.square,
                              child: Text(
                                text,
                                softWrap: false,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'settle',
                        title: '结算方式',
                        width: 120,
                        value: (row) => row.settlementMethod ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.settlementMethod)),
                      ),
                      AppDataGridColumn(
                        id: 'city',
                        title: '所在城市',
                        width: 120,
                        value: (row) {
                          final city = row.city?.trim() ?? '';
                          if (city.isNotEmpty) return city;
                          return row.regionName ?? '-';
                        },
                        cellBuilder: (context, row, _) {
                          final city = row.city?.trim() ?? '';
                          final region = row.regionName?.trim() ?? '';
                          return _cellText(
                            city.isNotEmpty
                                ? city
                                : (region.isNotEmpty ? region : '-'),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'address',
                        title: '详细地址',
                        width: 200,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.businessAddress ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          _dash(row.businessAddress),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'contact',
                        title: '联系人',
                        width: 100,
                        value: (row) => row.contactInfoText ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.contactInfoText)),
                      ),
                      AppDataGridColumn(
                        id: 'staff',
                        title: '我方对接人',
                        width: 120,
                        value: (row) => row.staffInfoText ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.staffInfoText)),
                      ),
                      AppDataGridColumn(
                        id: 'createTime',
                        title: '创建时间',
                        width: 168,
                        value: (row) => row.createTime ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.createTime)),
                      ),
                      AppDataGridColumn(
                        id: 'dynamic',
                        title: '最新动态(AI)',
                        width: 150,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.latestDynamic ?? '-',
                        cellBuilder: (context, row, _) {
                          final text = row.latestDynamic?.trim() ?? '';
                          if (text.isEmpty) {
                            return _cellText(
                              '-',
                              alignment: Alignment.centerLeft,
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: HyperTooltip(
                              appearance: HyperTooltipAppearance.dark,
                              placement: HyperOverlayPlacement.topStart,
                              waitDuration: const Duration(milliseconds: 200),
                              message: text,
                              style:   HyperCardStyle(
                                constraints: BoxConstraints(maxWidth: 360),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kPrimary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: _kPrimary,
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
                        pin: AppDataGridColumnPin.end,
                        value: (_) => '',
                        cellBuilder: (context, row, _) => Center(
                          child: AppButton.primary(
                            size: AppButtonSize.xSmall,
                            onPressed: () {
                              final id = row.id?.trim();
                              if (id == null || id.isEmpty) {
                                AppToast.show(
                                  context: context,
                                  title: '缺少供应商 ID',
                                );
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      SupplierDetailPage(supplierId: id),
                                ),
                              );
                            },
                            child: const Text('查看'),
                          ),
                        ),
                      ),
                    ];
                    // 触达列头筛选 Rx，保证勾选后表头高亮刷新。
                    c.columnFilters.length;
                    final visibleColumns = [
                      for (final col in allColumns)
                        if (col.id == 'no' ||
                            col.id == 'actions' ||
                            !hidden.contains(col.id))
                          col,
                    ];
                    return _SupplierGridWithColumnFilters(
                      controller: c,
                      height: gridHeight,
                      rows: list,
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
                                child: AppInkWell(
                                  onPressed: () => c.goPage(p),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: p == page
                                          ? _kPrimary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            p == page ? _kPrimary : _kBorder,
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
                              style: TextStyle(fontSize: 12, color: _kMuted),
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
                              style: TextStyle(fontSize: 12, color: _kMuted),
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
        ),
      ),
    );
  }
}

class _ColumnSettingsPopover extends StatelessWidget {
  const _ColumnSettingsPopover({required this.controller});

  final SupplierListController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 260,
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
            Obx(() {
              final hidden = controller.hiddenColumnIds.toSet();
              final ids = [for (final (id, _) in _kToggleableColumns) id];
              final hiddenCount =
                  ids.where((id) => hidden.contains(id)).length;
              final allState = hiddenCount == 0
                  ? CheckboxState.checked
                  : hiddenCount == ids.length
                      ? CheckboxState.unchecked
                      : CheckboxState.indeterminate;
              void toggleAll(bool visible) =>
                  controller.setAllColumnsVisible(ids, visible);
              return AppInkWell(
                onPressed: () => toggleAll(allState != CheckboxState.checked),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      AppCheckboxIndicator(
                        state: allState,
                        tristate: true,
                        onChanged: (state) =>
                            toggleAll(state == CheckboxState.checked),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '全选',
                          style: TextStyle(fontSize: 13, color: _kTitle),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 16, color: _kBorder),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: Obx(() {
                final hidden = controller.hiddenColumnIds.toSet();
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (id, title) in _kToggleableColumns)
                        AppInkWell(
                          onPressed: () => controller.setColumnVisible(
                            id,
                            hidden.contains(id),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                AppCheckboxIndicator(
                                  state: hidden.contains(id)
                                      ? CheckboxState.unchecked
                                      : CheckboxState.checked,
                                  onChanged: (state) =>
                                      controller.setColumnVisible(
                                    id,
                                    state == CheckboxState.checked,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            softWrap: false,
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            softWrap: false,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _kTitle,
              height: 1.1,
            ),
          ),
          if (sub != null && sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sub,
              softWrap: false,
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
          ],
        ],
      ),
    );
  }
}

final _customSettleDay = RegExp(r'^(\d+)天$');

bool _isPresetSettle(String text) {
  return SupplierListController.settlementMethodOptions
      .any((item) => item.$1 == text);
}

String _settleFilterLabel(String raw) {
  final text = raw.trim();
  if (_customSettleDay.hasMatch(text) && !_isPresetSettle(text)) {
    return text.substring(0, text.length - 1);
  }
  return text;
}

List<HyperSelectOption<String>> _settleSelectedOption(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return const [];
  if (_isPresetSettle(text)) return const [];
  return [HyperSelectOption(value: text, label: _settleFilterLabel(text))];
}

/// 筛选区下拉：lemon_ui `HyperSelect`，白底圆角。
class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelBuilder,
    this.selectedOptions = const [],
  });

  final String? value;
  final List<(String? value, String label)> options;
  final ValueChanged<String?> onChanged;
  final String Function(String value)? labelBuilder;
  final List<HyperSelectOption<String>> selectedOptions;

  static const _arrow = Color(0xFF86909C);
  static const _placeholder = Color(0xFFC9CDD4);

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.trim().isEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return HyperSelect<String>(
          value: empty ? null : value,
          placeholder: '全部',
          allowDeselect: true,
          labelBuilder: labelBuilder,
          selectedOptions: selectedOptions,
          size: HyperButtonSizeVariant.small,
          options: [
            for (final option in options)
              if (option.$1 != null)
                HyperSelectOption(value: option.$1!, label: option.$2),
          ],
          onChanged: onChanged,
          menuStyle: const HyperMenuStyle(
            surfaceRadius: 10,
            itemRadius: 8,
            itemHeight: 34,
          ),
          style: HyperSelectStyle(
            width: width,
            arrowSize: 16,
            arrowSpacing: 4,
            arrowColor: _arrow,
            foregroundColor: empty ? _placeholder : _kTitle,
            buttonStyle: HyperButtonStyle(
              width: width,
              height: 34,
              background: HyperFill.color(Colors.white),
              boxBorder: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(8),
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
      },
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.weight});

  final int weight;

  @override
  Widget build(BuildContext context) {
    final n = weight.clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            Icons.star,
            size: 14,
            color: i < n ? _kGold : const Color(0xFFD9D9D9),
          ),
      ],
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

class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({
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
      child: Material(
        color: const Color(0xFFF7F8FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _kBorder),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 18, color: const Color(0xFF4E5969)),
          ),
        ),
      ),
    );
  }
}

class _PageSizeMenu extends StatelessWidget {
  const _PageSizeMenu({required this.size, required this.onChanged});

  final int size;
  final ValueChanged<int> onChanged;

  static const _options = [10, 20, 50];

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4E5969);
    return HyperSelect<int>(
      value: size,
      size: HyperButtonSizeVariant.small,
      labelBuilder: (v) => '$v条/页',
      options: [
        for (final v in _options)
          HyperSelectOption(value: v, label: '$v条/页'),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      menuStyle: const HyperMenuStyle(
        width: 120,
        surfaceRadius: 10,
        itemRadius: 8,
        itemHeight: 32,
      ),
      style: HyperSelectStyle(
        width: 108,
        arrowSize: 16,
        arrowSpacing: 2,
        arrowColor: color,
        foregroundColor: color,
        buttonStyle: HyperButtonStyle(
          width: 108,
          height: 32,
          background: HyperFill.color(Colors.white),
          boxBorder: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
          textStyle: const TextStyle(fontSize: 12, color: color),
          boxShadow: const [],
          hoveredBoxShadow: const [],
          pressedBoxShadow: const [],
          focusedBoxShadow: const [],
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
    return AppInkWell(
      onPressed: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(4),
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
      width: 48,
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

Widget _letterIcon(String name) {
  final letter = String.fromCharCodes(name.runes.take(1));
  return Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF4E5969),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      letter,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

Widget _cellText(
  String text, {
  TextStyle? style,
  Alignment alignment = Alignment.center,
}) {
  return Align(
    alignment: alignment,
    child: Text(
      text,
      softWrap: false,
      style: style ?? const TextStyle(fontSize: 12, color: _kTitle),
    ),
  );
}

String _dash(String? s) {
  final t = s?.trim() ?? '';
  return t.isEmpty ? '-' : t;
}

InputDecoration _searchDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
    prefixIcon: const Icon(Icons.search, size: 18, color: _kMuted),
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    contentPadding: const EdgeInsets.symmetric(vertical: 0),
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

InputDecoration _inputDecoration(String hint) {
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

List<int> _pageWindow(int current, int total) {
  if (total <= 0) return const [1];
  final end = (current + 2).clamp(1, total);
  final start = (end - 4).clamp(1, total);
  return [for (var i = start; i <= end; i++) i];
}

/// 在 AppDataGrid 表头上叠一层可点筛选（上游暂无 titleBuilder，待回收）。
class _SupplierGridWithColumnFilters extends StatefulWidget {
  const _SupplierGridWithColumnFilters({
    required this.controller,
    required this.height,
    required this.rows,
    required this.columns,
  });

  final SupplierListController controller;
  final double height;
  final List<SrmSupplier> rows;
  final List<AppDataGridColumn<SrmSupplier>> columns;

  @override
  State<_SupplierGridWithColumnFilters> createState() =>
      _SupplierGridWithColumnFiltersState();
}

class _SupplierGridWithColumnFiltersState
    extends State<_SupplierGridWithColumnFilters> {
  static const _kSelectionColW = 40.0;
  static const _kHeaderH = 40.0;

  double _hScroll = 0;

  List<String> _optionsFor(String id) => widget.controller.columnOptionsOf(id);

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cols = widget.columns;
    final bodyW = cols.fold<double>(0, (sum, col) => sum + col.width);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.horizontal) {
                final next = n.metrics.pixels;
                if ((next - _hScroll).abs() > 0.5) {
                  setState(() => _hScroll = next);
                }
              }
              return false;
            },
            child: AppDataGrid<SrmSupplier>.local(
              key: ValueKey(
                'supplier-grid-${cols.map((e) => e.id).join(',')}-'
                '${c.pageNum.value}-${c.pageSize.value}',
              ),
              height: widget.height,
              rows: widget.rows,
              rowKey: (row) => row.id ?? row.supplierCode ?? '',
              sortable: false,
              selectionMode: AppDataGridSelectionMode.multiple,
              onSelectionChanged: c.setSelectedRows,
              showInternalDividers: true,
              headerBackgroundColor: const Color(0xFFFAFAFA),
              headerForegroundColor: Colors.transparent,
              headerTextStyle: const TextStyle(
                color: Colors.transparent,
                fontSize: 1,
              ),
              textStyle: const TextStyle(fontSize: 12),
              cellTextStyle: const TextStyle(fontSize: 12),
              empty: const Center(
                child: Text(
                  '暂无供应商',
                  style: TextStyle(color: _kMuted),
                ),
              ),
              columns: [
                for (final col in cols)
                  AppDataGridColumn<SrmSupplier>(
                    id: col.id,
                    title: col.title,
                    value: col.value,
                    type: col.type,
                    cellBuilder: col.cellBuilder,
                    width: col.width,
                    minWidth: col.minWidth,
                    widthMode: col.widthMode,
                    flex: col.flex,
                    pin: col.pin,
                    sortable: false,
                    filterable: false,
                    resizable: col.resizable,
                    reorderable: false,
                    editable: col.editable,
                    hidden: col.hidden,
                    alignment: col.alignment,
                    titleAlignment: col.titleAlignment,
                  ),
              ],
            ),
          ),
          // 左侧留出勾选列，避免挡住表头「全选」。
          Positioned(
            top: 0,
            left: _kSelectionColW,
            right: 0,
            height: _kHeaderH,
            child: Material(
              color: const Color(0xFFFAFAFA),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: bodyW,
                  maxWidth: bodyW,
                  child: Transform.translate(
                    offset: Offset(-_hScroll, 0),
                    child: SizedBox(
                      width: bodyW,
                      height: _kHeaderH,
                      child: Row(
                        children: [
                          for (final col in cols)
                            if (_kFilterableColumnIds.contains(col.id))
                              Obx(() {
                                final selected = c.columnFilterOf(col.id);
                                return ColumnHeaderFilter(
                                  title: col.title,
                                  width: col.width,
                                  options: _optionsFor(col.id),
                                  selected: selected,
                                  customDayInput: col.id == 'settle',
                                  alignment:
                                      col.titleAlignment ?? col.alignment,
                                  onApply: (next) =>
                                      c.applyColumnFilter(col.id, next),
                                );
                              })
                            else
                              ColumnHeaderLabel(
                                title: col.title,
                                width: col.width,
                                alignment:
                                    col.titleAlignment ?? col.alignment,
                              ),
                        ],
                      ),
                    ),
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
