import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import '../employee_archive/employee_archive_controller.dart';
import 'dialogs/regularize_dialog.dart';
import '../../location_breadcrumb.dart';
import 'regularization_controller.dart';

const _kGreen = Color(0xFF22C55E);
const _kPageBg = Color(0xFFF0F2F5);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kDanger = Color(0xFFFF4D4F);
const _kOrange = Color(0xFFFA8C16);

/// HRM · 转正管理。
class RegularizationPage extends StatelessWidget {
  const RegularizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<RegularizationController>(RegularizationController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<RegularizationController>();
    return ColoredBox(
      color: _kPageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LocationBreadcrumb(segments: ['HRM', '转正管理']),
            Obx(() {
              final s = c.stats.value;
              return Row(
                children: [
                  _StatCard(
                    label: '全部待转正',
                    value: '${s.totalCount}',
                    color: _kGreen,
                    bordered: true,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: '超期未转正',
                    value: '${s.overdueCount}',
                    color: _kDanger,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: '本月待转正',
                    value: '${s.monthCount}',
                    color: _kOrange,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: '下月待转正',
                    value: '${s.nextMonthCount}',
                    color: _kTitle,
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
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
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
                        final rows = c.rows.toList();
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
                                child: Text('暂无待转正人员', style: TextStyle(color: _kMuted)),
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
                                  value: (row) => RegularizationController.phoneText(row.mobile),
                                ),
                                AppDataGridColumn(
                                  id: 'hireDate',
                                  title: '入职日期',
                                  width: 120,
                                  minWidth: 110,
                                  value: (row) => RegularizationController.dateText(row.hireDate),
                                ),
                                AppDataGridColumn(
                                  id: 'regularizationDate',
                                  title: '转正日期',
                                  width: 120,
                                  minWidth: 110,
                                  value: (row) => RegularizationController.dateText(
                                    row.regularizationDate,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'type',
                                  title: '人员类型',
                                  width: 100,
                                  minWidth: 88,
                                  value: (row) => RegularizationController.typeLabel(row.empType),
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
                                  id: 'status',
                                  title: '状态',
                                  width: 96,
                                  minWidth: 88,
                                  value: (_) => '待转正',
                                  cellBuilder: (context, row, _) => const _StatusTag(),
                                ),
                                AppDataGridColumn(
                                  id: 'actions',
                                  title: '操作',
                                  width: 100,
                                  minWidth: 88,
                                  sortable: false,
                                  resizable: false,
                                  pin: AppDataGridColumnPin.end,
                                  value: (_) => '',
                                  cellBuilder: (context, row, _) => AppInkWell(
                                    onPressed: () => showRegularizeDialog(context, row),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Text(
                                        '确认转正',
                                        style: TextStyle(fontSize: 13, color: _kGreen),
                                      ),
                                    ),
                                  ),
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
    this.bordered = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bordered ? _kGreen : _kBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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

class _StatusTag extends StatelessWidget {
  const _StatusTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFFD591)),
      ),
      child: const Text(
        '待转正',
        style: TextStyle(fontSize: 12, color: _kOrange),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<RegularizationController>();
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
                color: _kGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$page', style: const TextStyle(fontSize: 12, color: Colors.white)),
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
