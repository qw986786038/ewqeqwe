import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import 'detail/employee_detail_page.dart';
import 'dialogs/employee_leave_dialog.dart';
import 'dialogs/employee_transfer_dialog.dart';
import 'edit/employee_edit_controller.dart';
import 'edit/employee_edit_page.dart';
import '../../location_breadcrumb.dart';
import 'employee_archive_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);
const _kTitle = Color(0xFF1D2129);
const _kCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(8)),
  border: Border.fromBorderSide(BorderSide(color: _kBorder)),
);

/// HRM · 花名册。
class EmployeeArchivePage extends StatelessWidget {
  const EmployeeArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<EmployeeArchiveController>(
          EmployeeArchiveController.new,
        );
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<EmployeeArchiveController>();
    return Obx(() {
      if (c.showEdit.value) {
        final editEmployeeId = c.editingEmployeeId.value;
        final editUserId = c.editingUserId.value;
        return LxScope(
          bindings: (container) {
            container.put<EmployeeEditController>(
              () => EmployeeEditController(
                employeeId: editEmployeeId,
                userId: editUserId,
              ),
            );
          },
          child: EmployeeEditPage(
            onBack: () async {
              c.closeEdit();
              await c.refreshAll();
            },
          ),
        );
      }
      final detailId = c.viewingEmployeeId.value;
      if (c.showDetail.value && detailId != null) {
        return EmployeeDetailPage(
          employeeId: detailId,
          onBack: c.closeDetail,
        );
      }
      return _ListView(controller: c);
    });
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.controller});

  final EmployeeArchiveController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ColoredBox(
      color: _kPageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LocationBreadcrumb(segments: ['HRM', '花名册']),
            Obx(() {
              final s = c.stats.value;
              final total = s.totalCount;
              final activePct = total <= 0
                  ? '0%'
                  : '${(s.activeCount * 1000 / total).round() / 10}%';
              final hireDiff = s.monthHireCount - s.lastMonthHireCount;
              final hireDiffText = hireDiff == 0
                  ? '较上月持平'
                  : (hireDiff > 0 ? '较上月 +$hireDiff' : '较上月 $hireDiff');
              final nearest = s.nearestPendingHireDate?.trim();
              final pendingSub = (nearest == null || nearest.isEmpty)
                  ? '暂无预计入职'
                  : '最近入职 ${EmployeeArchiveController.dateText(nearest)}';
              final expireDays = s.contractExpiringDays <= 0
                  ? 90
                  : s.contractExpiringDays;
              final leaveParts = <String>[
                '主动离职 ${s.monthLeaveVoluntaryCount}',
                '合同终止 ${s.monthLeaveInvoluntaryCount}',
                if (s.monthLeaveOtherCount > 0)
                  '其他 ${s.monthLeaveOtherCount}',
              ];
              const gap = 12.0;
              const green = Color(0xFF52C41A);
              const orange = Color(0xFFFA8C16);
              const purple = Color(0xFF722ED1);
              const red = Color(0xFFFF4D4F);
              const iconMuted = Color(0xFFC9CDD4);
              final cards = <Widget>[
                _StatCard(
                  label: '总人数',
                  value: '${s.totalCount}',
                  subtitle: '含外包与实习人员',
                  icon: Icons.groups_outlined,
                  iconColor: iconMuted,
                ),
                _StatCard(
                  label: '在职',
                  value: '${s.activeCount}',
                  subtitle: '占 $activePct',
                  icon: Icons.badge_outlined,
                  valueColor: green,
                  iconColor: green,
                ),
                _StatCard(
                  label: '试用',
                  value: '${s.probationCount}',
                  subtitle: '待转正',
                  icon: Icons.hourglass_empty_outlined,
                  valueColor: orange,
                  iconColor: orange,
                ),
                _StatCard(
                  label: '待入职',
                  value: '${s.pendingActiveCount}',
                  subtitle: pendingSub,
                  icon: Icons.event_available_outlined,
                  valueColor: purple,
                  iconColor: purple,
                ),
                _StatCard(
                  label: '离职',
                  value: '${s.leaveCount}',
                  subtitle: '默认不进入通讯录',
                  icon: Icons.person_off_outlined,
                  iconColor: iconMuted,
                ),
                _StatCard(
                  label: '本月入职',
                  value: '${s.monthHireCount}',
                  subtitle: hireDiffText,
                  icon: Icons.trending_up,
                  valueColor: green,
                  iconColor: green,
                  subtitleColor: hireDiff > 0 ? green : null,
                ),
                _StatCard(
                  label: '本月离职',
                  value: '${s.monthLeaveCount}',
                  subtitle: leaveParts.join(' · '),
                  icon: Icons.trending_down,
                  valueColor: red,
                  iconColor: red,
                ),
                _StatCard(
                  label: '合同即将到期',
                  value: '${s.contractExpiringCount}',
                  subtitle: '$expireDays 天内到期，建议尽快续签',
                  icon: Icons.description_outlined,
                  valueColor: orange,
                  iconColor: orange,
                  borderColor: s.contractExpiringCount > 0
                      ? const Color(0xFFFFD591)
                      : null,
                ),
              ];
              return Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                  const SizedBox(height: gap),
                  Row(
                    children: [
                      for (var i = 4; i < 8; i++) ...[
                        if (i > 4) const SizedBox(width: gap),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: _kCardDecoration,
              child: Obx(() {
                final status = c.filterEmpStatus.value;
                final type = c.filterEmpType.value;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FilterText(
                      label: '关键词',
                      width: 220,
                      controller: c.keywordCtrl,
                      hint: '姓名/手机/邮箱/工号',
                      onSubmitted: (_) => c.search(),
                    ),
                    _FilterSelect<String>(
                      label: '员工状态',
                      width: 160,
                      hint: '请选择员工状态',
                      value: status,
                      items: [
                        for (final o in EmployeeArchiveController.statusOptions)
                          o,
                      ],
                      onChanged: (v) => c.filterEmpStatus.value = v,
                    ),
                    _FilterSelect<String>(
                      label: '员工类型',
                      width: 160,
                      hint: '请选择员工类型',
                      value: type,
                      items: [
                        for (final o in EmployeeArchiveController.typeOptions)
                          o,
                      ],
                      onChanged: (v) => c.filterEmpType.value = v,
                    ),
                    AppButton.primary(
                      onPressed: c.search,
                      leading: const Icon(Icons.search, size: 16),
                      child: const Text('搜索'),
                    ),
                    AppButton.outline(
                      onPressed: c.resetSearch,
                      child: const Text('重置'),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: _kCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Row(
                        children: [
                          const Spacer(),
                          Obx(() {
                            final loading = c.loading.value;
                            return AppInkWell(
                              onPressed: loading ? null : c.refreshAll,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: loading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        size: 18,
                                        color: _kMuted,
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _kBorder),
                    Expanded(
                      child: Obx(() {
                        final rows = c.rows.toList();
                        final loading = c.loading.value;
                        final err = c.errorMessage.value;
                        if (loading && rows.isEmpty) {
                          return const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          );
                        }
                        if (err != null && rows.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  err,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppButton.outline(
                                  onPressed: c.refreshAll,
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final h = constraints.maxHeight;
                            return AppDataGrid<HrmEmployeeProfile>.local(
                              height: h > 0 ? h : 420,
                              rows: rows,
                              rowKey: (row) =>
                                  row.id ?? '${row.userId ?? row.no ?? ''}',
                              sortable: true,
                              showInternalDividers: true,
                              headerBackgroundColor: const Color(0xFFFAFAFA),
                              textStyle: const TextStyle(fontSize: 12),
                              cellTextStyle: const TextStyle(fontSize: 12),
                              empty: const Center(
                                child: Text(
                                  '暂无员工',
                                  style: TextStyle(color: _kMuted),
                                ),
                              ),
                              columns: [
                                AppDataGridColumn(
                                  id: 'name',
                                  title: '姓名',
                                  width: 96,
                                  minWidth: 96,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.name,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'dept',
                                  title: '部门',
                                  width: 140,
                                  minWidth: 96,
                                  value: (row) =>
                                      EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.deptName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'post',
                                  title: '职务',
                                  width: 120,
                                  minWidth: 96,
                                  value: (row) =>
                                      EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.postName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'level',
                                  title: '职级',
                                  width: 96,
                                  minWidth: 96,
                                  value: (row) =>
                                      EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.postSeqLeveName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'report',
                                  title: '汇报对象',
                                  width: 140,
                                  minWidth: 120,
                                  value: (row) =>
                                      EmployeeArchiveController.titleField(
                                    row,
                                    (t) => t.reportEmployeeName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'status',
                                  title: '状态',
                                  width: 96,
                                  minWidth: 96,
                                  sortable: false,
                                  value: (row) =>
                                      EmployeeArchiveController.statusLabel(
                                    row.empStatus,
                                  ),
                                  cellBuilder: (context, row, _) => Center(
                                    child: _StatusBadge(
                                      status: row.empStatus,
                                    ),
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'type',
                                  title: '员工类型',
                                  width: 120,
                                  minWidth: 120,
                                  value: (row) =>
                                      EmployeeArchiveController.typeLabel(
                                    row.empType,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'hireDate',
                                  title: '入职日期',
                                  width: 120,
                                  minWidth: 120,
                                  value: (row) =>
                                      EmployeeArchiveController.dateText(
                                    row.hireDate,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'tenure',
                                  title: '司龄',
                                  width: 88,
                                  minWidth: 88,
                                  value: (row) =>
                                      EmployeeArchiveController.tenureText(
                                    row.hireDate,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'mobile',
                                  title: '手机',
                                  width: 140,
                                  minWidth: 96,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.mobile,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'email',
                                  title: '邮箱',
                                  width: 220,
                                  minWidth: 96,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.corpEmail,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'contractExpire',
                                  title: '合同到期日期',
                                  width: 148,
                                  minWidth: 148,
                                  value: (row) =>
                                      EmployeeArchiveController
                                          .contractExpireText(row),
                                ),
                                AppDataGridColumn(
                                  id: 'actions',
                                  title: '操作',
                                  width: 280,
                                  minWidth: 96,
                                  sortable: false,
                                  resizable: false,
                                  pin: AppDataGridColumnPin.end,
                                  value: (_) => '',
                                  cellBuilder: (context, row, _) =>
                                      _ActionLinks(
                                    row: row,
                                    archiveController: c,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }),
                    ),
                    const Divider(height: 1, color: _kBorder),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Obx(() {
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
    required this.subtitle,
    required this.icon,
    this.valueColor,
    this.iconColor,
    this.subtitleColor,
    this.borderColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? valueColor;
  final Color? iconColor;
  final Color? subtitleColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: borderColor ?? _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ),
              Icon(icon, size: 16, color: iconColor ?? const Color(0xFFC9CDD4)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            softWrap: false,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _kTitle,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: subtitleColor ?? _kMuted),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final key = status?.trim().toUpperCase() ?? '';
    final label = EmployeeArchiveController.statusLabel(status);
    switch (key) {
      case 'ACTIVE':
        return AppBadge.success(
          appearance: AppBadgeStyle.soft,
          shape: AppBadgeShape.square,
          child: Text(label),
        );
      case 'PENDING_ACTIVE':
      case 'PENDING':
        return AppBadge.primary(
          shape: AppBadgeShape.square,
          child: Text(label),
        );
      case 'PENDING_LEAVE':
      case 'PROBATION':
        return AppBadge.warning(
          appearance: AppBadgeStyle.soft,
          shape: AppBadgeShape.square,
          child: Text(label),
        );
      case 'LEAVE':
      case 'LEFT':
      case 'CANCEL_ACTIVE':
        return AppBadge.secondary(
          appearance: AppBadgeStyle.soft,
          shape: AppBadgeShape.square,
          child: Text(label),
        );
      default:
        return Text(label, style: const TextStyle(fontSize: 12));
    }
  }
}

class _ActionLinks extends StatelessWidget {
  const _ActionLinks({
    required this.row,
    required this.archiveController,
  });

  final HrmEmployeeProfile row;
  final EmployeeArchiveController archiveController;

  void _openDetail(BuildContext context) {
    final employeeId = row.id?.trim() ?? '';
    if (employeeId.isEmpty) {
      AppToast.show(context: context, title: '缺少员工 ID');
      return;
    }
    archiveController.openDetail(employeeId);
  }

  void _openEdit(BuildContext context) {
    final employeeId = row.id?.trim() ?? '';
    if (employeeId.isEmpty) {
      AppToast.show(context: context, title: '缺少员工 ID');
      return;
    }
    archiveController.openEdit(employeeId: employeeId, userId: row.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _link('编辑', () => _openEdit(context)),
            _link('档案', () => _openDetail(context)),
            _link('发起调动', () => showEmployeeTransferDialog(context, row)),
            _link('办理离职', () => showEmployeeLeaveDialog(context, row)),
          ],
        ),
      ),
    );
  }

  Widget _link(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppInkWell(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kPrimary),
          ),
        ),
      ),
    );
  }
}

List<int> _pageWindow(int current, int total) {
  if (total <= 0) return const [1];
  final end = (current + 2).clamp(1, total);
  final start = (end - 4).clamp(1, total);
  return [for (var i = start; i <= end; i++) i];
}

class _FilterText extends StatelessWidget {
  const _FilterText({
    required this.label,
    required this.width,
    required this.controller,
    required this.hint,
    this.onSubmitted,
  });

  final String label;
  final double width;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _kLabel)),
        const SizedBox(width: 10),
        SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC9CDD4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
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
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterSelect<T> extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.width,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final double width;
  final String hint;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    String? selectedLabel;
    for (final item in items) {
      if (item.$1 == value) {
        selectedLabel = item.$2;
        break;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _kLabel)),
        const SizedBox(width: 10),
        SizedBox(
          width: width,
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: _kBorder),
            ),
            child: PopupMenuButton<T?>(
              tooltip: label,
              padding: EdgeInsets.zero,
              onSelected: onChanged,
              itemBuilder: (context) => [
                PopupMenuItem<T?>(
                  value: null,
                  height: 36,
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC9CDD4),
                    ),
                  ),
                ),
                for (final item in items)
                  PopupMenuItem<T?>(
                    value: item.$1,
                    height: 36,
                    child: Text(
                      item.$2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel ?? hint,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedLabel == null
                              ? const Color(0xFFC9CDD4)
                              : const Color(0xFF1D2129),
                        ),
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
          ),
        ),
      ],
    );
  }
}

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
