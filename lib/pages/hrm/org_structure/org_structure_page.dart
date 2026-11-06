import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../location_breadcrumb.dart';
import 'dialogs/dept_form_dialog.dart';
import 'org_structure_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);
const _kDanger = Color(0xFFFF4D4F);
const _kWarnBg = Color(0xFFFFF7E6);
const _kWarnFg = Color(0xFFD46B08);
const _kPurple = Color(0xFF722ED1);
const _kSideW = 280.0;

/// HRM · 部门（组织架构图谱：部门树 + 组织图）。
class OrgStructurePage extends StatelessWidget {
  const OrgStructurePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<OrgStructureController>(OrgStructureController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    return ColoredBox(
      color: _kPageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: LocationBreadcrumb(segments: ['HRM', '部门']),
          ),
          Expanded(
            child: Obx(() {
        if (c.loading.value && c.roots.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final err = c.errorMessage.value;
        if (err != null && c.roots.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err, style: const TextStyle(color: _kDanger)),
                const SizedBox(height: 12),
                AppButton.outline(
                  onPressed: c.refreshAll,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: _kSideW, child: _DeptTreePanel()),
                  VerticalDivider(width: 1, color: _kBorder),
                  Expanded(child: _ChartPanel()),
                ],
              ),
            ),
          ],
        );
      }),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    return ColoredBox(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '组织架构图谱',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTitle,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '按行政汇报关系树形展示直接上下级与部门职务配置，支持搜索定位与汇报链高亮。',
                    style: TextStyle(fontSize: 12, color: _kMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final active = c.hasDeptFilter;
              final n = c.filterDeptIds.length;
              return Builder(
                builder: (anchorCtx) => _HeaderOutlineButton(
                  onPressed: () {
                    // Overlay 不在页面 LxScope 内，需 putInstance 注入。
                    final ctrl =
                        anchorCtx.lx.find<OrgStructureController>();
                    AppPopover.show<void>(
                      context: anchorCtx,
                      alignment: Alignment.topRight,
                      anchorAlignment: Alignment.bottomRight,
                      offset: const Offset(0, 6),
                      builder: (_) => LxScope(
                        bindings: (container) {
                          container.putInstance<OrgStructureController>(
                            ctrl,
                            owned: false,
                          );
                        },
                        child: const _DeptFilterPopover(),
                      ),
                    );
                  },
                  leading: Icon(
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: active ? _kPurple : _kLabel,
                  ),
                  trailing: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: active ? _kPurple : _kMuted,
                  ),
                  active: active,
                  child: Text(
                    active ? '部门筛选 ($n)' : '部门筛选',
                    style: TextStyle(
                      fontSize: 13,
                      color: active ? _kPurple : _kLabel,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _HeaderOutlineButton(
              onPressed: () {
                c.expandAllDepts();
                c.setZoom(1);
                AppToast.show(
                  context: context,
                  title: '已展开全部组织点并重置缩放',
                );
              },
              leading: const Icon(
                Icons.open_in_full,
                size: 15,
                color: _kLabel,
              ),
              child: const Text(
                '展开全部',
                style: TextStyle(fontSize: 13, color: _kLabel),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final busy = c.exporting.value;
              return _HeaderFilledButton(
                onPressed: busy ? null : () => _exportChartPng(context, c),
                leading: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.download_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                child: Text(
                  busy ? '导出中…' : '导出架构图',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

Future<void> _exportChartPng(
  BuildContext context,
  OrgStructureController c,
) async {
  if (c.exporting.value) return;
  c.exporting.value = true;
  try {
    final bytes = await c.captureChartPng();
    if (!context.mounted) return;
    final stamp = DateTime.now();
    final name =
        '组织架构图_${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}.png';
    final savedUri = await FilePicker.saveFile(
      dialogTitle: '导出架构图',
      fileName: name,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['png'],
      windowsOptions: const WindowsOptions(lockParentWindow: true),
    );
    if (!context.mounted) return;
    if (savedUri == null) return;
    AppToast.show(context: context, title: '组织架构图已导出为 PNG');
  } catch (e) {
    if (!context.mounted) return;
    AppToast.show(context: context, title: e.toString());
  } finally {
    c.exporting.value = false;
  }
}

class _HeaderOutlineButton extends StatelessWidget {
  const _HeaderOutlineButton({
    required this.onPressed,
    required this.child,
    this.leading,
    this.trailing,
    this.active = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? _kPurple : _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            child,
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderFilledButton extends StatelessWidget {
  const _HeaderFilledButton({
    required this.onPressed,
    required this.child,
    this.leading,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.7 : 1,
      child: AppInkWell(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 部门筛选弹层：树形多选 + 人数。
class _DeptFilterPopover extends StatelessWidget {
  const _DeptFilterPopover();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '按部门筛选（可多选）',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kTitle,
                      ),
                    ),
                  ),
                  AppInkWell(
                    onPressed: c.clearDeptFilter,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        '全部部门',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: Obx(() {
                c.filterDeptIds.length;
                c.roots.length;
                final entries = _filterEntries(c);
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '暂无部门',
                        style: TextStyle(fontSize: 13, color: _kMuted),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    final checked = c.filterDeptIds.contains(e.id);
                    return AppInkWell(
                      onPressed: () => c.toggleFilterDept(e.id),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 8.0 + e.depth * 18,
                          right: 8,
                          top: 7,
                          bottom: 7,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: checked,
                                onChanged: (_) => c.toggleFilterDept(e.id),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                side: const BorderSide(color: _kBorder),
                                activeColor: _kPurple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: e.depth == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _kTitle,
                                ),
                              ),
                            ),
                            Text(
                              '${e.onDuty} 人',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹层树：公司根有子级时从子级起列（与截图一致）；否则列全部根。
  List<({String id, String name, int onDuty, int depth})> _filterEntries(
    OrgStructureController c,
  ) {
    final out = <({String id, String name, int onDuty, int depth})>[];
    void walk(OrgDeptNode n, int depth) {
      final id = n.id;
      if (id == null || id.isEmpty) return;
      final name = n.dept.deptName?.trim().isNotEmpty == true
          ? n.dept.deptName!.trim()
          : '未命名部门';
      out.add((id: id, name: name, onDuty: n.subtreeOnDuty, depth: depth));
      for (final child in n.children) {
        walk(child, depth + 1);
      }
    }

    if (c.roots.length == 1 && c.roots.first.children.isNotEmpty) {
      for (final child in c.roots.first.children) {
        walk(child, 0);
      }
    } else {
      for (final root in c.roots) {
        walk(root, 0);
      }
    }
    return out;
  }
}

// ── 左侧部门树 ───────────────────────────────────────────────────────────────

class _DeptTreePanel extends StatelessWidget {
  const _DeptTreePanel();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Obx(() {
              return Row(
                children: [
                  const Text(
                    '部门树',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${c.orgCount} 个组织 · ${c.companyOnDuty} 人',
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ],
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              // 订阅展开 / 选中
              c.expandedIds.length;
              c.selectedDeptId.value;
              c.roots.length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                children: [
                  for (final root in c.roots)
                    if (root.shouldShow)
                      _DeptTreeItem(node: root, depth: 0),
                ],
              );
            }),
          ),
          const Divider(height: 1, color: _kBorder),
          const _CompanyConfigCard(),
        ],
      ),
    );
  }
}

class _DeptTreeItem extends StatelessWidget {
  const _DeptTreeItem({required this.node, required this.depth});

  final OrgDeptNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    if (!node.shouldShow) return const SizedBox.shrink();

    final id = node.id ?? '';
    final visibleKids = node.visibleChildren;
    final hasChildren = visibleKids.isNotEmpty;
    final expanded = c.expandedIds.contains(id);
    final selected = c.selectedDeptId.value == id;
    final name = node.dept.deptName?.trim().isNotEmpty == true
        ? node.dept.deptName!.trim()
        : '未命名部门';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HyperContextMenu(
          enabled: id.isNotEmpty,
          items: const [
            HyperMenuItem(id: 'add', label: '添加'),
            HyperMenuItem(id: 'edit', label: '修改'),
            HyperMenuItem(id: 'delete', label: '删除'),
          ],
          onSelected: (action) {
            switch (action) {
              case 'add':
                showDeptAddDialog(context, parent: node.dept);
              case 'edit':
                showDeptEditDialog(context, node.dept);
              case 'delete':
                confirmDeleteDept(context, node.dept);
            }
          },
          child: AppInkWell(
          onPressed: () {
            if (id.isNotEmpty) c.selectDept(id);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: EdgeInsets.only(
              left: 8.0 + depth * 14,
              right: 8,
              top: 7,
              bottom: 7,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? _kPrimary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: hasChildren
                      ? AppInkWell(
                          onPressed: () {
                            if (id.isNotEmpty) c.toggleExpand(id);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Icon(
                            expanded
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            size: 16,
                            color: _kMuted,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? _kPrimary : _kTitle,
                    ),
                  ),
                ),
                Text(
                  '${node.subtreeOnDuty}人',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? _kPrimary : _kMuted,
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        if (hasChildren && expanded)
          for (final child in visibleKids)
            _DeptTreeItem(node: child, depth: depth + 1),
      ],
    );
  }
}

class _CompanyConfigCard extends StatelessWidget {
  const _CompanyConfigCard();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    return Obx(() {
      final rate = (c.fillRate * 100).round();
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '公司整体配置',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTitle,
              ),
            ),
            const SizedBox(height: 10),
            _kv('总编制', '${c.companyHeadcount}'),
            _kv('在岗人数', '${c.companyOnDuty}'),
            _kv(
              '空缺职务',
              '${c.companyVacancy}',
              valueColor: c.companyVacancy > 0 ? _kDanger : null,
            ),
            _kv('管理 / 专业', '${c.manageCount} / ${c.professionalCount}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '编制满足率',
                  style: TextStyle(fontSize: 12, color: _kLabel),
                ),
                const Spacer(),
                Text(
                  '$rate%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: c.fillRate,
                minHeight: 6,
                backgroundColor: const Color(0xFFF2F3F5),
                color: _kPrimary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _kv(String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: _kLabel)),
          const Spacer(),
          Text(
            v,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? _kTitle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 右侧组织图 ───────────────────────────────────────────────────────────────

class _ChartPanel extends StatelessWidget {
  const _ChartPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ChartToolbar(),
        const Divider(height: 1, color: _kBorder),
        Expanded(
          child: Obx(() {
            final c = context.lx.find<OrgStructureController>();
            // 组织图根固定为公司树根，点选左侧只改蓝框链路，不换根、不挪视角。
            final reportMode =
                c.viewMode.value == OrgChartViewMode.reportChain;
            // 订阅选中链路 / 职务标签 / 汇报树等；InteractiveViewer 保持同一实例。
            c.selectionPathIds.length;
            c.reportPathIds.length;
            c.reportRoots.length;
            c.selectedPositionId.value;
            c.postTagsByDept.length;
            c.vacancyByDept.length;
            c.filterDeptIds.length;
            c.searchQuery.value;
            c.highlightReport.value;
            final vertical = c.layout.value == OrgChartLayout.vertical;

            if (reportMode) {
              if (c.reportRoots.isEmpty) {
                return Center(
                  child: Text(
                    c.chartLoading.value ? '汇报链加载中…' : '暂无汇报链数据',
                    style: const TextStyle(color: _kMuted, fontSize: 13),
                  ),
                );
              }
              return Stack(
                children: [
                  InteractiveViewer(
                    transformationController: c.transformCtrl,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(200),
                    minScale: 0.5,
                    maxScale: 1.8,
                    child: RepaintBoundary(
                      key: c.chartExportKey,
                      child: ColoredBox(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
                          child: vertical
                              ? _ReportChartVertical(
                                  roots: c.reportRoots.toList(),
                                )
                              : _ReportChartHorizontal(
                                  roots: c.reportRoots.toList(),
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (c.chartLoading.value)
                    const Positioned(
                      right: 16,
                      top: 12,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              );
            }

            final root = c.chartRoot;
            if (root == null) {
              return const Center(
                child: Text(
                  '请选择左侧部门',
                  style: TextStyle(color: _kMuted, fontSize: 13),
                ),
              );
            }
            return Stack(
              children: [
                InteractiveViewer(
                  transformationController: c.transformCtrl,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(200),
                  minScale: 0.5,
                  maxScale: 1.8,
                  child: RepaintBoundary(
                    key: c.chartExportKey,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
                        child: vertical
                            ? _OrgChartVertical(root: root)
                            : _OrgChartHorizontal(root: root),
                      ),
                    ),
                  ),
                ),
                if (c.chartLoading.value)
                  const Positioned(
                    right: 16,
                    top: 12,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _ChartToolbar extends StatelessWidget {
  const _ChartToolbar();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Obx(() {
          c.viewMode.value;
          c.layout.value;
          c.zoom.value;
          c.highlightReport.value;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Seg(
                  labels: const ['部门视图', '汇报链视图'],
                  index: c.viewMode.value == OrgChartViewMode.department
                      ? 0
                      : 1,
                  onChanged: (i) => c.setViewMode(
                    i == 0
                        ? OrgChartViewMode.department
                        : OrgChartViewMode.reportChain,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '布局方向',
                  style: TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(width: 6),
                _Seg(
                  labels: const ['纵向', '横向'],
                  index: c.layout.value == OrgChartLayout.vertical ? 0 : 1,
                  onChanged: (i) => c.setLayout(
                    i == 0
                        ? OrgChartLayout.vertical
                        : OrgChartLayout.horizontal,
                  ),
                ),
                const SizedBox(width: 12),
                AppButton.outline(
                  onPressed: c.enableHighlightReport,
                  child: const Text(
                    '高亮汇报链',
                    style: TextStyle(color: _kPrimary),
                  ),
                ),
                const SizedBox(width: 6),
                AppButton.ghost(
                  onPressed: c.clearHighlight,
                  child: const Text('清除高亮'),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: c.searchCtrl,
                    onChanged: c.setSearch,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '搜索姓名、职务',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC9CDD4),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: _kMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: _kPageBg,
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
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton.ghost(
                  onPressed: c.zoomOut,
                  child: const Icon(Icons.remove, size: 16),
                ),
                Text(
                  '${(c.zoom.value * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: _kLabel),
                ),
                AppButton.ghost(
                  onPressed: c.zoomIn,
                  child: const Icon(Icons.add, size: 16),
                ),
                AppButton.outline(
                  onPressed: c.resetView,
                  child: const Text('重置'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _kPageBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            AppInkWell(
              onPressed: () => onChanged(i),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: index == i ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: index == i
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        index == i ? FontWeight.w600 : FontWeight.w400,
                    color: index == i ? _kPrimary : _kLabel,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 纵向组织图 ───────────────────────────────────────────────────────────────

class _OrgChartVertical extends StatelessWidget {
  const _OrgChartVertical({required this.root});

  final OrgDeptNode root;

  @override
  Widget build(BuildContext context) {
    return _VNode(node: root, isChartRoot: true);
  }
}

class _VNode extends StatelessWidget {
  const _VNode({required this.node, this.isChartRoot = false});

  final OrgDeptNode node;
  final bool isChartRoot;

  @override
  Widget build(BuildContext context) {
    if (!isChartRoot && !node.shouldShow) {
      return const SizedBox.shrink();
    }
    final c = context.lx.find<OrgStructureController>();
    final children = c.chartChildrenOf(node);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DeptCard(node: node, isChartRoot: isChartRoot),
        if (children.isNotEmpty) ...[
          Container(width: 1.5, height: 18, color: _kBorder),
          if (children.length == 1)
            _VNode(node: children.first)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++)
                  _VBranch(
                    node: children[i],
                    isFirst: i == 0,
                    isLast: i == children.length - 1,
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

class _VBranch extends StatelessWidget {
  const _VBranch({
    required this.node,
    required this.isFirst,
    required this.isLast,
  });

  final OrgDeptNode node;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: double.infinity,
              child: CustomPaint(
                painter: _HConnectorPainter(isFirst: isFirst, isLast: isLast),
              ),
            ),
            Container(width: 1.5, height: 10, color: _kBorder),
            _VNode(node: node),
          ],
        ),
      ),
    );
  }
}

class _HConnectorPainter extends CustomPainter {
  _HConnectorPainter({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;
    final midX = size.width / 2;
    if (!isFirst && !isLast) {
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    } else if (isFirst && isLast) {
      // single — no horizontal
    } else if (isFirst) {
      canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
    } else if (isLast) {
      canvas.drawLine(Offset(0, midY), Offset(midX, midY), paint);
    }
    canvas.drawLine(Offset(midX, midY), Offset(midX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _HConnectorPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst || oldDelegate.isLast != isLast;
}

// ── 横向组织图 ───────────────────────────────────────────────────────────────

class _OrgChartHorizontal extends StatelessWidget {
  const _OrgChartHorizontal({required this.root});

  final OrgDeptNode root;

  @override
  Widget build(BuildContext context) {
    return _HNode(node: root, isChartRoot: true);
  }
}

class _HNode extends StatelessWidget {
  const _HNode({required this.node, this.isChartRoot = false});

  final OrgDeptNode node;
  final bool isChartRoot;

  @override
  Widget build(BuildContext context) {
    if (!isChartRoot && !node.shouldShow) {
      return const SizedBox.shrink();
    }
    final c = context.lx.find<OrgStructureController>();
    final children = c.chartChildrenOf(node);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DeptCard(node: node, isChartRoot: isChartRoot),
        if (children.isNotEmpty) ...[
          Container(width: 18, height: 1.5, color: _kBorder),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 1.5, color: _kBorder),
                    _HNode(node: children[i]),
                  ],
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ── 汇报链组织图 ─────────────────────────────────────────────────────────────

class _ReportChartVertical extends StatelessWidget {
  const _ReportChartVertical({required this.roots});

  final List<OrgPersonNode> roots;

  @override
  Widget build(BuildContext context) {
    if (roots.length == 1) {
      return _ReportVNode(node: roots.first);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < roots.length; i++) ...[
          if (i > 0) const SizedBox(width: 32),
          _ReportVNode(node: roots[i]),
        ],
      ],
    );
  }
}

class _ReportVNode extends StatelessWidget {
  const _ReportVNode({required this.node});

  final OrgPersonNode node;

  @override
  Widget build(BuildContext context) {
    final children = node.children;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PersonCard(node: node),
        if (children.isNotEmpty) ...[
          Container(width: 1.5, height: 18, color: _kBorder),
          if (children.length == 1)
            _ReportVNode(node: children.first)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++)
                  _ReportVBranch(
                    node: children[i],
                    isFirst: i == 0,
                    isLast: i == children.length - 1,
                  ),
              ],
            ),
        ],
      ],
    );
  }
}

class _ReportVBranch extends StatelessWidget {
  const _ReportVBranch({
    required this.node,
    required this.isFirst,
    required this.isLast,
  });

  final OrgPersonNode node;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: double.infinity,
              child: CustomPaint(
                painter: _HConnectorPainter(isFirst: isFirst, isLast: isLast),
              ),
            ),
            Container(width: 1.5, height: 10, color: _kBorder),
            _ReportVNode(node: node),
          ],
        ),
      ),
    );
  }
}

class _ReportChartHorizontal extends StatelessWidget {
  const _ReportChartHorizontal({required this.roots});

  final List<OrgPersonNode> roots;

  @override
  Widget build(BuildContext context) {
    if (roots.length == 1) {
      return _ReportHNode(node: roots.first);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < roots.length; i++) ...[
          if (i > 0) const SizedBox(height: 28),
          _ReportHNode(node: roots[i]),
        ],
      ],
    );
  }
}

class _ReportHNode extends StatelessWidget {
  const _ReportHNode({required this.node});

  final OrgPersonNode node;

  @override
  Widget build(BuildContext context) {
    final children = node.children;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PersonCard(node: node),
        if (children.isNotEmpty) ...[
          Container(width: 18, height: 1.5, color: _kBorder),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 1.5, color: _kBorder),
                    _ReportHNode(node: children[i]),
                  ],
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.node});

  final OrgPersonNode node;

  static const _avatarColors = [
    Color(0xFF1677FF),
    Color(0xFF722ED1),
    Color(0xFF13C2C2),
    Color(0xFFFA8C16),
    Color(0xFFEB2F96),
    Color(0xFF52C41A),
  ];

  Color get _avatarColor {
    final h = node.name.hashCode.abs();
    return _avatarColors[h % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    final searching = c.searchQuery.value.isNotEmpty;
    final inPath = c.isInReportPath(node.positionId);
    final hit = c.matchesPersonSearch(node);
    // 搜索中：命中亮起蓝框，其余变灰；无搜索时按高亮汇报链。
    final emphasized = searching
        ? hit
        : (c.highlightReport.value && inPath);
    final dimmed = searching && !hit;

    return Opacity(
      opacity: dimmed ? 0.28 : 1,
      child: AppInkWell(
        onPressed: () => c.selectPerson(node.positionId),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: emphasized ? _kPrimary : _kBorder,
              width: emphasized ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _avatarColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                node.avatarChar,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                      height: 1.25,
                    ),
                  ),
                  if (node.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      node.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kLabel,
                        height: 1.2,
                      ),
                    ),
                  ],
                  if (node.deptName.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      node.deptName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// ── 部门卡片 ─────────────────────────────────────────────────────────────────

class _DeptCard extends StatelessWidget {
  const _DeptCard({required this.node, this.isChartRoot = false});

  final OrgDeptNode node;
  final bool isChartRoot;

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OrgStructureController>();
    final name = node.dept.deptName?.trim().isNotEmpty == true
        ? node.dept.deptName!.trim()
        : '未命名部门';
    final searching = c.searchQuery.value.isNotEmpty;
    final inPath = c.isInSelectionPath(node.id);
    final hit = c.matchesSearch(node);
    final hasChildren = c.chartChildrenOf(node).isNotEmpty;
    // 截图：有子节点的中心卡展示「编制/空缺」；叶子卡展示职务编制标签。
    // 总经办图根：只展示「全员」人数。
    final showStaffing = !isChartRoot && hasChildren;
    final tags = (!isChartRoot && !hasChildren) ? c.tagsFor(node) : const <({
      String label,
      int count,
      bool vacancy,
    })>[];
    final staffing = showStaffing ? c.staffingLine(node) : (0, 0);
    final leader = isChartRoot ? null : c.leaderNameOf(node.id);
    final metaLine = isChartRoot
        ? null
        : showStaffing
            ? '${(leader != null && leader.isNotEmpty) ? '负责人 $leader · ' : ''}编制 ${staffing.$1} · 空缺 ${staffing.$2}'
            : ((leader != null && leader.isNotEmpty) ? '负责人 $leader' : null);
    // 搜索中：命中亮起蓝框，其余变灰；无搜索时按高亮路径。
    final emphasized = searching
        ? hit
        : (c.highlightReport.value && inPath);
    final dimmed = searching && !hit;

    return Opacity(
      opacity: dimmed ? 0.28 : 1,
      child: AppInkWell(
        onPressed: () {
          final id = node.id;
          if (id != null) c.selectDept(id);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 188,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: emphasized ? _kPrimary : _kBorder,
              width: emphasized ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (isChartRoot) ...[
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _kPurple,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Text(
                      '总',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    isChartRoot ? name : '$name · ${node.subtreeOnDuty}人',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            if (isChartRoot) ...[
              const SizedBox(height: 4),
              Text(
                '全员 ${c.companyOnDuty} 人',
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ] else if (metaLine != null) ...[
              const SizedBox(height: 4),
              Text(
                metaLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t.vacancy
                            ? _kWarnBg
                            : const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${t.label} ${t.count}',
                        style: TextStyle(
                          fontSize: 11,
                          color: t.vacancy ? _kWarnFg : _kLabel,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
