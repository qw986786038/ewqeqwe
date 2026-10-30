import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import '../../models/customer_archive.dart';
import '../../services/customer_api.dart';
import '../home_controller.dart';
import 'customer_archive_controller.dart';
import 'detail/customer_brand_detail_page.dart';
import 'detail/customer_contact_detail_page.dart';
import 'detail/customer_entity_detail_page.dart';
import 'dialogs/quick_create_brand_dialog.dart';

/// 列设置可开关的列（序号 / 操作固定显示）。
const _kToggleableColumns = <(String id, String title)>[
  ('type', '客户类型'),
  ('market', '市场层级'),
  ('icon', '图标'),
  ('brand', '品牌简称'),
  ('industry', '所属行业'),
  ('entityCount', '关联主体数量'),
  ('entityName', '关联主体全称'),
  ('relation', '关联关系'),
  ('nature', '主体性质'),
  ('city', '所在城市'),
  ('address', '详细地址'),
  ('contact', '联系人'),
  ('createTime', '创建时间'),
  ('dynamic', '最新动态(AI)'),
  ('owner', '负责人'),
  ('assignTime', '分配时间'),
  ('assignDays', '分配天数'),
  ('status', '状态'),
  ('remark', '备注'),
  ('log', '日志'),
];

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kOrange = Color(0xFFFA8C16);

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

class CustomerArchivePage extends StatelessWidget {
  const CustomerArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<CustomerArchiveController>(
          CustomerArchiveController.new,
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
    CustomerArchiveController c,
  ) async {
    if (c.exporting.value) return;
    try {
      final file = await c.exportExcel();
      if (!context.mounted) return;
      final savedUri = await FilePicker.saveFile(
        dialogTitle: '导出客户档案',
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
    final c = context.lx.find<CustomerArchiveController>();
    return ColoredBox(
      color: _kPageBg,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── 顶栏：后退/前进 · 当前位置 · 搜索 · 新建档案 ─────────────
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
                  '当前位置 / 户外传媒CRM / 客户档案管理',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4E5969)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: TextField(
                      controller: c.topSearchCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '搜索栏：品牌简称 / 档案编码 / 代言人',
                        hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: _kMuted,
                        ),
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
                      ),
                      onSubmitted: (_) {
                        c.keywordCtrl.text = c.topSearchCtrl.text;
                        c.search();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  onPressed: () => showCreateCustomerArchiveDialog(
                    context,
                    onCreated: c.refreshAll,
                  ),
                  leading: const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                  child: const Text('新建档案'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── KPI 统计卡 ─────────────────────────────────────────────
          Obx(() {
            final dictVer = c.dictVersion.value;
            final s = c.stats.value;
            return KeyedSubtree(
              key: ValueKey('kpi-$dictVer'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  const minCard = 148.0;
                  const count = 5;
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
                          label: '品牌数量',
                          value: '${s.brandEnterprise}',
                          valueColor: _kOrange,
                          subtitle: '品牌企业',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '关联主体',
                          value: '${s.relatedEntityCount}',
                          subtitle: '经营主体总数',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '公海',
                          value: '${s.publicSea}',
                          subtitle: '规划中',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '私海',
                          value: '${s.privateSea}',
                          valueColor: _kPrimary,
                          subtitle: '规划中',
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: cardW,
                        child: _StatCard(
                          label: '待分配',
                          value: '${s.pendingAssign}',
                          subtitle: '规划中',
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
              ),
            );
          }),
          const SizedBox(height: 12),

          // ── 表格 ───────────────────────────────────────────────────
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
                          '客户档案列表 · 共 ${c.total.value} 条',
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
                              builder: (_) => _ColumnSettingsPopover(
                                controller: c,
                              ),
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
                      AppButton.outline(
                        onPressed: () {
                          AppToast.show(context: context, title: '导入待接入');
                        },
                        leading: const Icon(Icons.upload_outlined, size: 16),
                        child: const Text('导入'),
                      ),
                      const SizedBox(width: 8),
                      Obx(
                        () => AppButton.outline(
                          onPressed: c.exporting.value
                              ? null
                              : () => _export(context, c),
                          leading: c.exporting.value
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined, size: 16),
                          child: Text(c.exporting.value ? '导出中...' : '导出'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final dictVer = c.dictVersion.value;
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
                  // 桌面放大后表格略增高，减少底部空白感。
                  final gridHeight =
                      (MediaQuery.sizeOf(context).height * 0.52)
                          .clamp(520.0, 680.0);
                  final allColumns = <AppDataGridColumn<CustomerArchive>>[
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
                        id: 'type',
                        title: '客户类型',
                        width: 120,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => c.customerTypeLabel(row.customerType),
                        cellBuilder: (context, row, _) {
                          final raw = row.customerType ?? '';
                          final label = c.customerTypeLabel(raw);
                          return AppBadge.custom(
                            color: _typeColor(raw, label),
                            appearance: AppBadgeStyle.soft,
                            shape: AppBadgeShape.square,
                            child: Text(
                              label,
                              softWrap: false,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'market',
                        title: '市场层级',
                        width: 140,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => c.marketLabel(row.marketLevel),
                        cellBuilder: (context, row, _) =>
                            _cellText(c.marketLabel(row.marketLevel)),
                      ),
                      AppDataGridColumn(
                        id: 'icon',
                        title: '图标',
                        width: 56,
                        value: (row) => row.iconLetter ?? '',
                        cellBuilder: (context, row, _) {
                          final main = row.brandName?.trim() ?? '';
                          final sub = row.brandSub?.trim() ?? '';
                          // 无品牌简称时不显示图标占位。
                          if (main.isEmpty && sub.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final letter = row.iconLetter?.trim().isNotEmpty == true
                              ? row.iconLetter!.trim()
                              : (main.isNotEmpty
                                  ? String.fromCharCodes(main.runes.take(1))
                                  : String.fromCharCodes(sub.runes.take(1)));
                          final color = _logoColor(main.isNotEmpty ? main : sub);
                          return Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                letter,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'brand',
                        title: '品牌简称',
                        width: 200,
                        widthMode: AppDataGridColumnWidthMode.content,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) {
                          final main = row.brandName?.trim() ?? '';
                          final sub = _subBrandsExcludingMain(
                            row.brandSub,
                            main,
                          );
                          if (main.isEmpty && sub.isEmpty) return '';
                          if (sub.isEmpty) return main;
                          if (main.isEmpty) return sub;
                          return '$main $sub';
                        },
                        cellBuilder: (context, row, _) {
                          final main = row.brandName?.trim() ?? '';
                          final sub = _subBrandsExcludingMain(
                            row.brandSub,
                            main,
                          );
                          if (main.isEmpty && sub.isEmpty) {
                            return _cellText(
                              '-',
                              alignment: Alignment.centerLeft,
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (main.isNotEmpty)
                                    AppInkWell(
                                      onPressed: () {
                                        final id = row.id?.trim();
                                        if (id == null || id.isEmpty) {
                                          AppToast.show(
                                            context: context,
                                            title: '缺少档案 ID，无法打开详情',
                                          );
                                          return;
                                        }
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                CustomerBrandDetailPage(
                                              customerId: id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        main,
                                        softWrap: false,
                                        style: const TextStyle(
                                          color: _kPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (main.isNotEmpty && sub.isNotEmpty)
                                    const Text(' '),
                                  if (sub.isNotEmpty)
                                    Text(
                                      sub,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: _kTitle,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                      ),
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
                        width: 120,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => c.industryLabel(row.industry),
                        cellBuilder: (context, row, _) =>
                            _cellText(c.industryLabel(row.industry)),
                      ),
                      AppDataGridColumn(
                        id: 'entityCount',
                        title: '关联主体数量',
                        width: 108,
                        value: (row) => row.entityCount ?? 0,
                        type: AppDataGridColumnType.number,
                        cellBuilder: (context, row, value) =>
                            _cellText('${value ?? 0}'),
                      ),
                      AppDataGridColumn(
                        id: 'entityName',
                        title: '关联主体全称',
                        width: 220,
                        widthMode: AppDataGridColumnWidthMode.content,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.entityName ?? '-',
                        cellBuilder: (context, row, _) => _multiLineCell(
                          _splitMulti(row.entityName),
                          alignment: Alignment.centerLeft,
                          linkStyle: true,
                          onLinePressed: (line) {
                            if (line == '-') return;
                            final id = row.id?.trim();
                            if (id == null || id.isEmpty) {
                              AppToast.show(
                                context: context,
                                title: '缺少档案 ID，无法打开详情',
                              );
                              return;
                            }
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CustomerEntityDetailPage(
                                  customerId: id,
                                  enterpriseName: line,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'relation',
                        title: '关联关系',
                        width: 120,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => c.relationLabel(row.relation),
                        cellBuilder: (context, row, _) => _multiLineCell([
                          for (final p in _splitMulti(row.relation))
                            c.relationLabel(p),
                        ]),
                      ),
                      AppDataGridColumn(
                        id: 'nature',
                        title: '主体性质',
                        width: 96,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => c.entityNatureLabel(row.entityNature),
                        cellBuilder: (context, row, _) => _multiLineCell([
                          for (final p in _splitMulti(row.entityNature))
                            c.entityNatureLabel(p),
                        ]),
                      ),
                      AppDataGridColumn(
                        id: 'city',
                        title: '所在城市',
                        width: 100,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) =>  row.city ?? '-',
                        cellBuilder: (context, row, _) =>
                            _multiLineCell(_splitMulti(row.city)),
                      ),
                      AppDataGridColumn(
                        id: 'address',
                        title: '详细地址',
                        width: 220,
                        widthMode: AppDataGridColumnWidthMode.content,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.address ?? '-',
                        cellBuilder: (context, row, _) => _multiLineCell(
                          _splitMulti(row.address),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'contact',
                        title: '联系人',
                        width: 140,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => row.contact ?? '-',
                        cellBuilder: (context, row, _) {
                          final entities = _splitMulti(row.entityName);
                          final lines = _contactLinesForEntities(
                            row.entityName,
                            row.contact,
                          );
                          return _contactLinkCell(
                            lines,
                            onNamePressed: (lineIndex, name) {
                              final ent =
                                  lineIndex < entities.length &&
                                          entities[lineIndex] != '-'
                                      ? entities[lineIndex]
                                      : null;
                              _openListContact(
                                context,
                                row: row,
                                contactName: name,
                                enterpriseName: ent,
                              );
                            },
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'createTime',
                        title: '创建时间',
                        width: 168,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => row.createTime ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          row.createTime?.trim().isNotEmpty == true
                              ? row.createTime!.trim()
                              : '-',
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'dynamic',
                        title: '最新动态(AI)',
                        width: 160,
                        widthMode: AppDataGridColumnWidthMode.content,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.latestDynamic ?? '-',
                        cellBuilder: (context, row, _) {
                          final text = row.latestDynamic?.trim();
                          if (text == null || text.isEmpty) {
                            return _cellText(
                              '-',
                              alignment: Alignment.centerLeft,
                            );
                          }
                          return _cellText(
                            text,
                            alignment: Alignment.centerLeft,
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'owner',
                        title: '负责人',
                        width: 120,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) =>
                            row.owner?.trim().isNotEmpty == true
                                ? row.owner!.trim()
                                : (row.salesperson ?? '-'),
                        cellBuilder: (context, row, _) {
                          final text =
                              row.owner?.trim().isNotEmpty == true
                                  ? row.owner!.trim()
                                  : (row.salesperson?.trim().isNotEmpty == true
                                      ? row.salesperson!.trim()
                                      : '-');
                          return Tooltip(
                            message: text == '-' ? '' : text,
                            child: _cellText(text),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'assignTime',
                        title: '分配时间',
                        width: 168,
                        widthMode: AppDataGridColumnWidthMode.content,
                        value: (row) => row.assignTime ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          row.assignTime?.trim().isNotEmpty == true
                              ? row.assignTime!.trim()
                              : '-',
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'assignDays',
                        title: '分配天数',
                        width: 88,
                        value: (row) => row.assignDays,
                        type: AppDataGridColumnType.number,
                        cellBuilder: (context, row, value) =>
                            _cellText(value == null ? '-' : '$value'),
                      ),
                      AppDataGridColumn(
                        id: 'status',
                        title: '状态',
                        width: 88,
                        value: (row) => row.status ?? '-',
                        cellBuilder: (context, row, _) {
                          final raw = row.status?.trim() ?? '';
                          if (raw.isEmpty) return _cellText('-');
                          final label = raw == '0'
                              ? '跟进中'
                              : (raw == '1' ? '停用' : raw);
                          final isFollow = label == '跟进中' || label == '正常';
                          return Center(
                            child: AppBadge.custom(
                              color: isFollow
                                  ? const Color(0xFF52C41A)
                                  : const Color(0xFF8C8C8C),
                              appearance: AppBadgeStyle.soft,
                              shape: AppBadgeShape.square,
                              child: Text(
                                label,
                                softWrap: false,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
                      AppDataGridColumn(
                        id: 'remark',
                        title: '备注',
                        width: 120,
                        widthMode: AppDataGridColumnWidthMode.content,
                        alignment: Alignment.centerLeft,
                        titleAlignment: Alignment.centerLeft,
                        value: (row) => row.remark ?? '-',
                        cellBuilder: (context, row, _) => _cellText(
                          row.remark?.trim().isNotEmpty == true
                              ? row.remark!.trim()
                              : '-',
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'log',
                        title: '日志',
                        width: 64,
                        value: (_) => '查看',
                        cellBuilder: (context, row, _) => Center(
                          child: AppInkWell(
                            onPressed: () {
                              AppToast.show(
                                context: context,
                                title: '日志待接入',
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: const Text(
                              '查看',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppDataGridColumn(
                        id: 'actions',
                        title: '操作',
                        width: 148,
                        pin: AppDataGridColumnPin.end,
                        value: (_) => '',
                        cellBuilder: (context, row, _) => Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppInkWell(
                                onPressed: () {
                                  AppToast.show(
                                    context: context,
                                    title: '回收待接入',
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '回收',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              AppInkWell(
                                onPressed: () {
                                  AppToast.show(
                                    context: context,
                                    title: '分配待接入',
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '分配',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              AppInkWell(
                                onPressed: () {
                                  final id = row.id?.trim();
                                  if (id == null || id.isEmpty) return;
                                  showEditCustomerArchiveDialog(
                                    context,
                                    customerId: id,
                                    onSaved: c.refreshAll,
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '编辑',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                  return AppDataGrid<CustomerArchive>.local(
                    key: ValueKey(
                      'archive-grid-$dictVer-${hidden.join(',')}',
                    ),
                    height: gridHeight,
                    rows: list,
                    rowKey: (row) => row.id ?? row.archiveCode ?? '',
                    sortable: false,
                    selectionMode: AppDataGridSelectionMode.multiple,
                    showInternalDividers: true,
                    headerBackgroundColor: const Color(0xFFFAFAFA),
                    textStyle: const TextStyle(fontSize: 12),
                    cellTextStyle: const TextStyle(fontSize: 12),
                    empty: const Center(
                      child: Text(
                        '暂无客户档案',
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
                                      color: p == page ? _kPrimary : _kBorder,
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

  final CustomerArchiveController controller;

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

/// 子品牌文案去掉与主品牌同名的项，避免「品牌简称」主品牌显示两次。
String _subBrandsExcludingMain(String? rawSub, String main) {
  final text = rawSub?.trim() ?? '';
  if (text.isEmpty) return '';
  final mainName = main.trim();
  final parts = text
      .split(RegExp(r'[,，;；、|/]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .where((e) => mainName.isEmpty || e != mainName)
      .toList();
  return parts.join('；');
}

/// 表格单元格：单行完整展示，不裁切为「…」（列宽不足时靠表格横向滚动）。
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

/// 将接口多主体字段拆成多行（`,` / `；` / `|` 等分隔）。
List<String> _splitMulti(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return const ['-'];
  final parts = text
      .split(RegExp(r'[,，|/\n；;、]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.isEmpty ? const ['-'] : parts;
}

/// `contactNames`：不同关联主体用 `;` 隔开。
List<String> _splitContactByEntity(String? contacts) {
  final text = contacts?.trim() ?? '';
  if (text.isEmpty) return const ['-'];
  final parts = text
      .split(RegExp(r'[;；]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.isEmpty ? const ['-'] : parts;
}

/// 联系人按关联主体分行：行数与主体一致。
List<String> _contactLinesForEntities(String? entityNames, String? contacts) {
  final entities = _splitMulti(entityNames);
  final contactGroups = _splitContactByEntity(contacts);
  // 无主体时仍展示联系人分组。
  if (entities.length == 1 && entities.first == '-') {
    return contactGroups;
  }
  return [
    for (var i = 0; i < entities.length; i++)
      i < contactGroups.length && contactGroups[i] != '-'
          ? contactGroups[i]
          : '-',
  ];
}

/// 同主体内：主联系人与上下级用顿号 `、` 分隔。
List<String> _contactNamesInLine(String line) {
  final text = line.trim();
  if (text.isEmpty || text == '-') return const [];
  return text
      .split(RegExp(r'[、]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// 列表联系人：`主体A主联系人、上级、下级;主体B…`——
/// 仅每组第一人蓝色可点，其后上下级普通色仅展示。
Widget _contactLinkCell(
  List<String> lines, {
  required void Function(int lineIndex, String name) onNamePressed,
}) {
  const linkStyle = TextStyle(
    fontSize: 12,
    color: _kPrimary,
    fontWeight: FontWeight.w600,
  );
  const plainStyle = TextStyle(
    fontSize: 12,
    color: _kTitle,
    fontWeight: FontWeight.w400,
  );

  Widget lineChild(int lineIndex, String line) {
    final names = _contactNamesInLine(line);
    if (names.isEmpty) {
      return const Text('-', softWrap: false, style: TextStyle(fontSize: 12));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < names.length; i++) ...[
          if (i > 0)
            const Text('、', softWrap: false, style: plainStyle),
          if (i == 0)
            AppInkWell(
              onPressed: () => onNamePressed(lineIndex, names[i]),
              child: Text(names[i], softWrap: false, style: linkStyle),
            )
          else
            Text(names[i], softWrap: false, style: plainStyle),
        ],
      ],
    );
  }

  if (lines.length <= 1) {
    return Align(
      alignment: Alignment.center,
      child: lineChild(0, lines.isEmpty ? '-' : lines.first),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final maxH = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : 40.0;
      final maxW = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : double.infinity;
      return SizedBox(
        width: maxW,
        height: maxH,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0)
                    const ColoredBox(
                      color: _kBorder,
                      child: SizedBox(height: 1, width: double.infinity),
                    ),
                  Align(
                    alignment: Alignment.center,
                    child: lineChild(i, lines[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _openListContact(
  BuildContext context, {
  required CustomerArchive row,
  required String contactName,
  String? enterpriseName,
}) async {
  final name = contactName.trim();
  if (name.isEmpty || name == '-') return;
  final archiveId = row.id?.trim();
  if (archiveId == null || archiveId.isEmpty) {
    AppToast.show(context: context, title: '缺少档案 ID，无法打开联系人详情');
    return;
  }
  try {
    final detail = await CustomerApi().fetchCustomerDetail(archiveId);
    if (!context.mounted) return;
    final contactId = _findContactIdInDetail(
      detail,
      name,
      enterpriseName: enterpriseName,
    );
    if (contactId == null || contactId.isEmpty) {
      AppToast.show(context: context, title: '未找到联系人「$name」');
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerContactDetailPage(contactId: contactId),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    AppToast.show(context: context, title: e.toString());
  }
}

/// 从档案详情 `contacts` 中解析联系人 id；优先同主体。
String? _findContactIdInDetail(
  Map<String, dynamic> detail,
  String name, {
  String? enterpriseName,
}) {
  final list = detail['contacts'];
  if (list is! List) return null;
  final contacts = <Map<String, dynamic>>[
    for (final e in list)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
  final ent = enterpriseName?.trim() ?? '';

  String? idOf(Map<String, dynamic> c) {
    final id = c['id']?.toString().trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  Map<String, dynamic>? byName(Iterable<Map<String, dynamic>> src) {
    for (final c in src) {
      if ((c['name']?.toString().trim() ?? '') == name) return c;
    }
    return null;
  }

  if (ent.isNotEmpty) {
    final sameEnt = [
      for (final c in contacts)
        if ((c['relatedEnterprise']?.toString().trim() ?? '') == ent) c,
    ];
    final hit = byName(sameEnt);
    if (hit != null) return idOf(hit);
  }
  final top = byName(contacts);
  return top == null ? null : idOf(top);
}

/// 关联主体等多值单元格：每个主体单独一行，多行之间加分割线。
/// 行高与整表一致；内容超出时缩放装入，避免 RenderFlex overflow。
Widget _multiLineCell(
  List<String> lines, {
  Alignment alignment = Alignment.center,
  bool linkStyle = false,
  void Function(String line)? onLinePressed,
}) {
  final style = TextStyle(
    fontSize: 12,
    color: linkStyle ? _kPrimary : _kTitle,
    fontWeight: linkStyle ? FontWeight.w600 : FontWeight.w400,
  );
  Widget lineChild(String line) {
    if (onLinePressed != null && line != '-') {
      return GestureDetector(
        onTap: () => onLinePressed(line),
        behavior: HitTestBehavior.opaque,
        child: Text(line, softWrap: false, style: style),
      );
    }
    return Text(line, softWrap: false, style: style);
  }

  if (lines.length <= 1) {
    return Align(alignment: alignment, child: lineChild(lines.first));
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final maxH = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : 40.0;
      final maxW = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : double.infinity;
      return SizedBox(
        width: maxW,
        height: maxH,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0)
                    const ColoredBox(
                      color: _kBorder,
                      child: SizedBox(height: 1, width: double.infinity),
                    ),
                  Align(
                    alignment: alignment,
                    child: lineChild(lines[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
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

Color _typeColor(String raw, String label) {
  final key = raw.trim();
  final text = label.trim();
  return switch (key) {
    'brand' => const Color(0xFF1677FF),
    'agency' => const Color(0xFFFA8C16),
    'channel' => const Color(0xFF52C41A),
    'gov' => const Color(0xFF13C2C2),
    'dsp' => const Color(0xFF722ED1),
    _ => switch (text) {
      '品牌企业' => const Color(0xFF1677FF),
      '4A公司' => const Color(0xFFFA8C16),
      '渠道广告公司' => const Color(0xFF52C41A),
      '政务单位' => const Color(0xFF13C2C2),
      'DSP/API' => const Color(0xFF722ED1),
      _ => const Color(0xFF8C8C8C),
    },
  };
}

Color _logoColor(String name) {
  const colors = [
    Color(0xFF1677FF),
    Color(0xFF13C2C2),
    Color(0xFF722ED1),
    Color(0xFFFAAD14),
    Color(0xFFEB2F96),
    Color(0xFF52C41A),
    Color(0xFFFA541C),
  ];
  if (name.isEmpty) return colors.first;
  return colors[name.hashCode.abs() % colors.length];
}

List<int> _pageWindow(int current, int total) {
  if (total <= 0) return const [1];
  final end = (current + 2).clamp(1, total);
  final start = (end - 4).clamp(1, total);
  return [for (var i = start; i <= end; i++) i];
}
