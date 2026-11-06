import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import '../employee_archive/detail/employee_detail_page.dart';
import 'dialogs/leave_confirm_dialog.dart';
import '../../location_breadcrumb.dart';
import 'offboarding_controller.dart';

bool _isLeftEmployee(HrmEmployeeProfile row, {required bool leftTab}) {
  final status = row.empStatus?.trim().toUpperCase() ?? '';
  if (status == 'LEAVE' || status == 'LEFT') return true;
  if (status == 'PENDING_LEAVE') return false;
  return leftTab;
}

const _kGreen = Color(0xFF22C55E);
const _kPageBg = Color(0xFFF0F2F5);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);

/// HRM · 离职管理。
class OffboardingPage extends StatelessWidget {
  const OffboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<OffboardingController>(OffboardingController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OffboardingController>();
    return Obx(() {
      final viewingId = c.viewingEmployeeId.value;
      if (viewingId != null && viewingId.isNotEmpty) {
        return EmployeeDetailPage(
          employeeId: viewingId,
          onBack: () {
            c.closeDetail();
            c.refreshAll();
          },
        );
      }
      return ColoredBox(
        color: _kPageBg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LocationBreadcrumb(segments: ['HRM', '离职管理']),
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
                                  label: '待离职',
                                  selected: current == OffboardingTab.pending,
                                  onTap: () => c.switchTab(OffboardingTab.pending),
                                ),
                                _TabChip(
                                  label: '已离职',
                                  selected: current == OffboardingTab.left,
                                  onTap: () => c.switchTab(OffboardingTab.left),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      SizedBox(
                        width: 320,
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
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final rows = c.rows.toList();
                    final pending = c.tab.value == OffboardingTab.pending;
                    final error = c.errorMessage.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null && error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              error,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFFF4D4F)),
                            ),
                          ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final leftTab = !pending;
                              return AppDataGrid<HrmEmployeeProfile>.local(
                                key: ValueKey(
                                  'offboarding-${leftTab ? 'left' : 'pending'}',
                                ),
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
                                    cellBuilder: (context, row, _) =>
                                        _NameCell(name: row.name),
                                  ),
                                  AppDataGridColumn(
                                    id: 'mobile',
                                    title: '手机号码',
                                    width: 160,
                                    minWidth: 140,
                                    value: (row) =>
                                        OffboardingController.phoneText(row.mobile),
                                  ),
                                  AppDataGridColumn(
                                    id: 'hireDate',
                                    title: '入职日期',
                                    width: 120,
                                    minWidth: 100,
                                    value: (row) =>
                                        OffboardingController.dateText(row.hireDate),
                                  ),
                                  AppDataGridColumn(
                                    id: 'leaveDate',
                                    title: '离职日期',
                                    width: 120,
                                    minWidth: 100,
                                    value: (row) =>
                                        OffboardingController.dateText(row.leaveDate),
                                  ),
                                  AppDataGridColumn(
                                    id: 'leaveType',
                                    title: '离职类型',
                                    width: 100,
                                    minWidth: 88,
                                    value: (row) => OffboardingController.leaveTypeLabel(
                                      row.leaveType,
                                    ),
                                  ),
                                  AppDataGridColumn(
                                    id: 'type',
                                    title: '人员类型',
                                    width: 100,
                                    minWidth: 88,
                                    value: (row) =>
                                        OffboardingController.typeLabel(row.empType),
                                  ),
                                  AppDataGridColumn(
                                    id: 'dept',
                                    title: '部门',
                                    width: 140,
                                    minWidth: 100,
                                    value: (row) => OffboardingController.deptLabel(row),
                                  ),
                                  AppDataGridColumn(
                                    id: 'actions',
                                    title: '操作',
                                    width: pending ? 140 : 88,
                                    minWidth: 80,
                                    sortable: false,
                                    resizable: false,
                                    pin: AppDataGridColumnPin.end,
                                    value: (_) => '',
                                    cellBuilder: (context, row, _) =>
                                        _isLeftEmployee(row, leftTab: leftTab)
                                            ? _ArchiveAction(row: row)
                                            : _PendingActions(row: row),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
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
    });
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
          decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
          child: Text(letter, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? '—' : text,
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
          onPressed: () async {
            final ok = await showLeaveConfirmDialog(context, row);
            if (!ok || !context.mounted) return;
            await context.lx.find<OffboardingController>().refreshAll();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('确认离职', style: TextStyle(fontSize: 13, color: _kGreen)),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: '更多',
          onSelected: (value) => _onMenu(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'revoke', height: 36, child: Text('撤销离职')),
            PopupMenuItem(value: 'detail', height: 36, child: Text('查看档案')),
            PopupMenuItem(value: 'delete', height: 36, child: Text('删除')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Icon(Icons.more_horiz, size: 18, color: _kGreen),
          ),
        ),
      ],
    );
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    final c = context.lx.find<OffboardingController>();
    if (value == 'detail') {
      final id = row.id?.trim() ?? '';
      if (id.isEmpty) {
        AppToast.show(context: context, title: '缺少员工 ID');
        return;
      }
      c.openDetail(id);
      return;
    }
    if (value == 'delete') {
      AppToast.show(context: context, title: '删除接口尚未提供');
      return;
    }
    try {
      await c.revokeLeave(row);
      if (!context.mounted) return;
      AppToast.show(context: context, title: '已撤销离职申请');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context: context, title: e.toString());
    }
  }
}

class _ArchiveAction extends StatelessWidget {
  const _ArchiveAction({required this.row});

  final HrmEmployeeProfile row;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: () {
        final id = row.id?.trim() ?? '';
        if (id.isEmpty) {
          AppToast.show(context: context, title: '缺少员工 ID');
          return;
        }
        context.lx.find<OffboardingController>().openDetail(id);
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text('档案', style: TextStyle(fontSize: 13, color: _kGreen)),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<OffboardingController>();
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
            const SizedBox(width: 4),
            IconButton(
              onPressed: page > 1 ? () => c.goPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left, size: 18),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kGreen,
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
            const SizedBox(width: 8),
            const Text('前往', style: TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(width: 6),
            _JumpField(page: page, pages: pages),
            const SizedBox(width: 6),
            const Text('页', style: TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ),
      );
    });
  }
}

class _JumpField extends StatefulWidget {
  const _JumpField({required this.page, required this.pages});

  final int page;
  final int pages;

  @override
  State<_JumpField> createState() => _JumpFieldState();
}

class _JumpFieldState extends State<_JumpField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.page}');
  }

  @override
  void didUpdateWidget(covariant _JumpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page && _ctrl.text != '${widget.page}') {
      _ctrl.text = '${widget.page}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null) return;
    context.lx.find<OffboardingController>().goPage(n.clamp(1, widget.pages));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 28,
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _kBorder),
          ),
        ),
        onSubmitted: (_) => _go(),
      ),
    );
  }
}
