import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import '../../../models/srm_purchase_order.dart';
import '../../home_controller.dart';
import '../supplier/widgets/column_header_filter.dart';
import 'dialogs/purchase_order_form_dialog.dart';
import 'dialogs/purchase_order_import_dialog.dart';
import 'purchase_order_list_controller.dart';

/// 列头筛选仅接已有 Query：brandName / contractType。
const _kFilterableColumnIds = {
  'brand',
  'contractType',
};

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);

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
  ('orderNo', '订单号'),
  ('orderName', '订单名称'),
  ('orderTag', '订单标签'),
  ('brand', '关联品牌'),
  ('supplier', '供应商全称'),
  ('contractType', '合同类型'),
  ('orderAmount', '订单金额(万元)'),
  ('orderTime', '订单时间'),
  ('settle', '结算方式'),
  ('invoice', '发票类型'),
  ('taxRate', '税率'),
  ('city', '城市'),
  ('contact', '联系人'),
  ('staff', '我方对接人'),
  ('remark', '备注'),
];

class PurchaseOrderListPage extends StatelessWidget {
  const PurchaseOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<PurchaseOrderListController>(
          PurchaseOrderListController.new,
        );
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  void _goBack(BuildContext context) {
    try {
      context.lx.find<HomeController>().sideMenu.value = 'orders';
    } catch (_) {
      AppToast.show(context: context, title: '无法返回上一页');
    }
  }

  Future<void> _export(
    BuildContext context,
    PurchaseOrderListController c,
  ) async {
    if (c.exporting.value) return;
    try {
      final file = await c.exportSelected();
      if (!context.mounted) return;
      final savedUri = await FilePicker.saveFile(
        dialogTitle: '导出采购订单',
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
    final c = context.lx.find<PurchaseOrderListController>();
    return ColoredBox(
      color: _kPageBg,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
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
                    '当前位置 / 供应商管理 / 采购订单列表',
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
                          '搜索订单号 / 名称 / 供应商',
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
                  const count = 3;
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
                          label: '订单数量',
                          value: '${k.orderCount}',
                          subtitle: '全部采购订单',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '物业租赁',
                          value: '${k.propertyLeaseCount}',
                          subtitle: '供应品类=物业租赁',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '媒介采购',
                          value: '${k.mediaPurchaseCount}',
                          subtitle: '供应品类=媒介采购',
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
                            '采购订单列表 · 共 ${c.total.value} 条',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kTitle,
                            ),
                            softWrap: false,
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
                            final ok =
                                await showPurchaseOrderCreateDialog(context);
                            if (ok && context.mounted) {
                              await c.refreshAll(clearSelected: true);
                            }
                          },
                          leading: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                          child: const Text('创建'),
                        ),
                        const SizedBox(width: 8),
                        AppButton.outline(
                          onPressed: () async {
                            final ok =
                                await showPurchaseOrderImportDialog(context);
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
                    final gridHeight =
                        (MediaQuery.sizeOf(context).height * 0.48)
                            .clamp(420.0, 620.0);
                    final allColumns = <AppDataGridColumn<SrmPurchaseOrder>>[
                      AppDataGridColumn(
                        id: 'no',
                        title: '序号',
                        width: 56,
                        value: (row) {
                          final i = list.indexOf(row);
                          final page = c.pageNum.value;
                          final size = c.pageSize.value;
                          return i < 0 ? '-' : '${(page - 1) * size + i + 1}';
                        },
                        cellBuilder: (context, row, value) =>
                            _cellText('${value ?? '-'}'),
                      ),
                      AppDataGridColumn(
                        id: 'orderNo',
                        title: '订单号',
                        width: 168,
                        value: (row) => row.orderNo ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.orderNo)),
                      ),
                      AppDataGridColumn(
                        id: 'orderName',
                        title: '订单名称',
                        width: 140,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.orderName ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          _dash(row.orderName),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'orderTag',
                        title: '订单标签',
                        width: 110,
                        value: (row) => row.orderTag ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.orderTag)),
                      ),
                      AppDataGridColumn(
                        id: 'brand',
                        title: '关联品牌',
                        width: 100,
                        value: (row) => row.brandName ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.brandName)),
                      ),
                      AppDataGridColumn(
                        id: 'supplier',
                        title: '供应商全称',
                        width: 200,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.supplierFullName ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          _dash(row.supplierFullName),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'contractType',
                        title: '合同类型',
                        width: 110,
                        value: (row) => row.contractType ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.contractType)),
                      ),
                      AppDataGridColumn(
                        id: 'orderAmount',
                        title: '订单金额(万元)',
                        width: 130,
                        type: AppDataGridColumnType.number,
                        value: (row) => row.orderAmount,
                        cellBuilder: (context, row, _) {
                          final v = row.orderAmount;
                          if (v == null) return _cellText('-');
                          return _cellText(v.toStringAsFixed(2));
                        },
                      ),
                      AppDataGridColumn(
                        id: 'orderTime',
                        title: '订单时间',
                        width: 120,
                        value: (row) => row.orderTime ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.orderTime)),
                      ),
                      AppDataGridColumn(
                        id: 'settle',
                        title: '结算方式',
                        width: 110,
                        value: (row) => row.settlementMethod ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.settlementMethod)),
                      ),
                      AppDataGridColumn(
                        id: 'invoice',
                        title: '发票类型',
                        width: 110,
                        value: (row) => row.invoiceType ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.invoiceType)),
                      ),
                      AppDataGridColumn(
                        id: 'taxRate',
                        title: '税率',
                        width: 88,
                        value: (row) => row.taxRate ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.taxRate)),
                      ),
                      AppDataGridColumn(
                        id: 'city',
                        title: '城市',
                        width: 100,
                        value: (row) => row.city ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.city)),
                      ),
                      AppDataGridColumn(
                        id: 'contact',
                        title: '联系人',
                        width: 100,
                        value: (row) => row.contactName ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.contactName)),
                      ),
                      AppDataGridColumn(
                        id: 'staff',
                        title: '我方对接人',
                        width: 120,
                        value: (row) => row.staffName ?? '-',
                        cellBuilder: (context, row, _) =>
                            _cellText(_dash(row.staffName)),
                      ),
                      AppDataGridColumn(
                        id: 'remark',
                        title: '备注',
                        width: 160,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.remark ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          _dash(row.remark),
                          alignment: Alignment.centerLeft,
                        ),
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
                            onPressed: () async {
                              final id = row.id?.trim();
                              if (id == null || id.isEmpty) {
                                AppToast.show(
                                  context: context,
                                  title: '缺少采购订单 ID',
                                );
                                return;
                              }
                              final ok =
                                  await showPurchaseOrderDetailDialog(
                                context,
                                orderId: id,
                              );
                              if (ok && context.mounted) {
                                await c.refreshAll(clearSelected: true);
                              }
                            },
                            child: const Text('查看'),
                          ),
                        ),
                      ),
                    ];
                    c.columnFilters.length;
                    final visibleColumns = [
                      for (final col in allColumns)
                        if (col.id == 'no' ||
                            col.id == 'actions' ||
                            !hidden.contains(col.id))
                          col,
                    ];
                    return _OrderGridWithColumnFilters(
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

  final PurchaseOrderListController controller;

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
                                    softWrap: false,
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
  });

  final String label;
  final String value;
  final String? subtitle;

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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kTitle,
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF4E5969)),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

List<int> _pageWindow(int current, int total) {
  if (total <= 0) return const [1];
  final end = (current + 2).clamp(1, total);
  final start = (end - 4).clamp(1, total);
  return [for (var i = start; i <= end; i++) i];
}

/// 在 AppDataGrid 表头上叠一层可点筛选（上游暂无 titleBuilder，待回收）。
class _OrderGridWithColumnFilters extends StatefulWidget {
  const _OrderGridWithColumnFilters({
    required this.controller,
    required this.height,
    required this.rows,
    required this.columns,
  });

  final PurchaseOrderListController controller;
  final double height;
  final List<SrmPurchaseOrder> rows;
  final List<AppDataGridColumn<SrmPurchaseOrder>> columns;

  @override
  State<_OrderGridWithColumnFilters> createState() =>
      _OrderGridWithColumnFiltersState();
}

class _OrderGridWithColumnFiltersState
    extends State<_OrderGridWithColumnFilters> {
  static const _kSelectionColW = 40.0;
  static const _kHeaderH = 40.0;

  double _hScroll = 0;

  List<String> _optionsFor(String id) {
    return switch (id) {
      'brand' => PurchaseOrderListController.columnBrandOptions,
      'contractType' => PurchaseOrderListController.columnContractTypeOptions,
      _ => const <String>[],
    };
  }

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
            child: AppDataGrid<SrmPurchaseOrder>.local(
              key: ValueKey(
                'po-grid-${cols.map((e) => e.id).join(',')}-'
                '${c.pageNum.value}-${c.pageSize.value}',
              ),
              height: widget.height,
              rows: widget.rows,
              rowKey: (row) => row.id ?? row.orderNo ?? '',
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
                  '暂无采购订单',
                  style: TextStyle(color: _kMuted),
                ),
              ),
              columns: [
                for (final col in cols)
                  AppDataGridColumn<SrmPurchaseOrder>(
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
