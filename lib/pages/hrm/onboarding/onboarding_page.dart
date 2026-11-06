import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import '../employee_archive/employee_archive_controller.dart';
import 'dialogs/onboarding_person_dialog.dart';
import '../../location_breadcrumb.dart';
import 'onboarding_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFFF4D4F);
const _kGreen = Color(0xFF52C41A);
const _kOrange = Color(0xFFFA8C16);

/// HRM · 入职管理。
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<OnboardingController>(OnboardingController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OnboardingController>();
    return ColoredBox(
      color: _kPageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LocationBreadcrumb(segments: ['HRM', '入职管理']),
            Obx(() {
              final s = c.stats.value;
              return Row(
                children: [
                  _StatCard(
                    label: '全部待入职',
                    value: '${s.totalCount}',
                    color: _kPrimary,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: '今日待入职',
                    value: '${s.todayCount}',
                    color: _kGreen,
                    icon: Icons.event_available_outlined,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: '本月待入职',
                    value: '${s.monthCount}',
                    color: _kOrange,
                    icon: Icons.calendar_month_outlined,
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Obx(() {
                            final current = c.tab.value;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F3F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TabChip(
                                      label: '待入职',
                                      selected: current == OnboardingTab.pending,
                                      onTap: () => c.switchTab(OnboardingTab.pending),
                                    ),
                                    _TabChip(
                                      label: '已取消入职',
                                      selected: current == OnboardingTab.cancelled,
                                      onTap: () => c.switchTab(OnboardingTab.cancelled),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 280,
                            height: 34,
                            child: TextField(
                              controller: c.keywordCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: '通过姓名、工作邮箱、手机号码搜索...',
                                hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search, size: 18, color: _kMuted),
                                  onPressed: c.search,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                              ),
                              onSubmitted: (_) => c.search(),
                            ),
                          ),
                          const Spacer(),
                          AppButton.primary(
                            onPressed: () => showAddPendingDialog(context),
                            leading: const Icon(Icons.add, size: 16, color: Colors.white),
                            child: const Text('添加待入职人员'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (c.loading.value && c.rows.isEmpty) {
                          return const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                          );
                        }
                        final err = c.errorMessage.value;
                        if (err != null && c.rows.isEmpty) {
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
                        final pending = c.tab.value == OnboardingTab.pending;
                        final rows = c.rows.toList();
                        c.levels.length;
                        c.seqs.length;
                        c.dicts.length;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return AppDataGrid<HrmEmployeeProfile>.local(
                              height: constraints.maxHeight > 0
                                  ? constraints.maxHeight
                                  : 420,
                              rows: rows,
                              rowKey: (row) => row.id ?? '${row.userId ?? ''}',
                              sortable: true,
                              showInternalDividers: true,
                              headerBackgroundColor: const Color(0xFFFAFAFA),
                              textStyle: const TextStyle(fontSize: 12),
                              cellTextStyle: const TextStyle(fontSize: 12),
                              empty: const Center(
                                child: Text('暂无人员', style: TextStyle(color: _kMuted)),
                              ),
                              columns: [
                                AppDataGridColumn(
                                  id: 'name',
                                  title: '姓名',
                                  width: 150,
                                  minWidth: 120,
                                  value: (row) => row.name ?? '',
                                  cellBuilder: (context, row, _) => _NameCell(name: row.name),
                                ),
                                AppDataGridColumn(
                                  id: 'mobile',
                                  title: '手机号码',
                                  width: 160,
                                  minWidth: 140,
                                  value: (row) => OnboardingController.phoneText(row.mobile),
                                ),
                                AppDataGridColumn(
                                  id: 'hireDate',
                                  title: '预计入职日期',
                                  width: 130,
                                  minWidth: 120,
                                  value: (row) => OnboardingController.dateText(row.hireDate),
                                ),
                                AppDataGridColumn(
                                  id: 'type',
                                  title: '人员类型',
                                  width: 100,
                                  minWidth: 88,
                                  value: (row) => c.dictText(
                                    row.empType,
                                    current: OnboardingController.typeLabel(row.empType),
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'dept',
                                  title: '部门',
                                  width: 120,
                                  minWidth: 88,
                                  value: (row) => EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.deptName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'post',
                                  title: '职务',
                                  width: 120,
                                  minWidth: 88,
                                  value: (row) => EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.postName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'level',
                                  title: '职级',
                                  width: 100,
                                  minWidth: 72,
                                  value: (row) => EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.postSeqLeveName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'seq',
                                  title: '序列',
                                  width: 100,
                                  minWidth: 72,
                                  value: (row) => c.seqLabel(row),
                                ),
                                AppDataGridColumn(
                                  id: 'actions',
                                  title: '操作',
                                  width: pending ? 228 : 140,
                                  minWidth: 120,
                                  sortable: false,
                                  resizable: false,
                                  pin: AppDataGridColumnPin.end,
                                  value: (_) => '',
                                  cellBuilder: (context, row, _) {
                                    final status = row.empStatus?.trim();
                                    final cancelled = status == 'CANCEL_ACTIVE' ||
                                        ((status == null || status.isEmpty) &&
                                            !pending);
                                    return cancelled
                                        ? _RestoreAction(row: row)
                                        : _PendingActions(row: row);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ),
                    const Divider(height: 1, color: _kBorder),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: _Pager(),
                    ),
                  ],
                ),
              ),
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
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
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
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _kTitle : _kMuted,
          ),
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final text = name?.trim() ?? '';
    final letter = text.isEmpty ? '?' : text.characters.last;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _kPrimary,
            shape: BoxShape.circle,
          ),
          child: Text(
            letter,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? '-' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _kTitle),
          ),
        ),
      ],
    );
  }
}

class _PendingActions extends StatelessWidget {
  const _PendingActions({required this.row});

  final HrmEmployeeProfile row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppInkWell(
          onPressed: () => showEditPendingDialog(context, row),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('编辑', style: TextStyle(fontSize: 13, color: _kPrimary)),
          ),
        ),
        AppInkWell(
          onPressed: () => showConfirmHireDialog(context, row),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('确认入职', style: TextStyle(fontSize: 13, color: _kPrimary)),
          ),
        ),
        AppInkWell(
          onPressed: () async {
            final c = context.lx.find<OnboardingController>();
            try {
              await c.revokeHire(row);
              if (!context.mounted) return;
              AppToast.show(context: context, title: '已取消入职');
            } catch (e) {
              if (!context.mounted) return;
              AppToast.show(context: context, title: e.toString());
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('取消入职', style: TextStyle(fontSize: 13, color: _kDanger)),
          ),
        ),
      ],
    );
  }
}

class _RestoreAction extends StatelessWidget {
  const _RestoreAction({required this.row});

  final HrmEmployeeProfile row;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: () async {
        final c = context.lx.find<OnboardingController>();
        try {
          await c.restoreHire(row);
          if (!context.mounted) return;
          AppToast.show(context: context, title: '已恢复为待入职');
        } catch (e) {
          if (!context.mounted) return;
          AppToast.show(context: context, title: e.toString());
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text('恢复为待入职', style: TextStyle(fontSize: 13, color: _kPrimary)),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OnboardingController>();
    return Obx(() {
      final page = c.pageNum.value;
      final pages = c.totalPages;
      final size = c.pageSize.value;
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('共 ${c.total.value} 条', style: const TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(width: 10),
            PopupMenuButton<int>(
              initialValue: size,
              tooltip: '每页条数',
              onSelected: c.changePageSize,
              itemBuilder: (context) => [
                for (final v in const [10, 20, 50])
                  PopupMenuItem(value: v, height: 36, child: Text('$v条/页')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kBorder),
                ),
                child: Text('$size条/页', style: const TextStyle(fontSize: 12, color: _kTitle)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: page > 1 ? () => c.goPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left, size: 18),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$page',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: page < pages ? () => c.goPage(page + 1) : null,
              icon: const Icon(Icons.chevron_right, size: 18),
            ),
          ],
        ),
      );
    });
  }
}
