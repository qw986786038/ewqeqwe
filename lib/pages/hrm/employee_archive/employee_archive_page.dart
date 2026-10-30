import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_employee_profile.dart';
import 'detail/employee_detail_page.dart';
import 'dialogs/employee_appoint_dialog.dart';
import 'dialogs/employee_level_dialog.dart';
import 'dialogs/employee_relieve_dialog.dart';
import 'edit/employee_edit_controller.dart';
import 'edit/employee_edit_page.dart';
import 'employee_archive_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);

/// HRM · 人事档案。
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
        final editId = c.editingUserId.value;
        return LxScope(
          bindings: (container) {
            container.put<EmployeeEditController>(
              () => EmployeeEditController(userId: editId),
            );
          },
          child: EmployeeEditPage(
            onBack: () async {
              c.closeEdit();
              await c.loadPage();
            },
          ),
        );
      }
      final detailId = c.viewingUserId.value;
      if (c.showDetail.value && detailId != null) {
        return EmployeeDetailPage(
          userId: detailId,
          onBack: c.closeDetail,
        );
      }
      return _listView(context, c);
    });
  }

  Widget _listView(BuildContext context, EmployeeArchiveController c) {
    return ColoredBox(
      color: _kPageBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Obx(() {
                final status = c.filterEmpStatus.value;
                final type = c.filterEmpType.value;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FilterText(
                      label: '姓名',
                      width: 160,
                      controller: c.nameCtrl,
                      hint: '请输入姓名',
                      onSubmitted: (_) => c.search(),
                    ),
                    _FilterText(
                      label: '工号',
                      width: 140,
                      controller: c.noCtrl,
                      hint: '请输入工号',
                      onSubmitted: (_) => c.search(),
                    ),
                    _FilterText(
                      label: '手机号',
                      width: 160,
                      controller: c.mobileCtrl,
                      hint: '请输入手机号',
                      onSubmitted: (_) => c.search(),
                    ),
                    _FilterSelect<String>(
                      label: '员工状态',
                      width: 150,
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
                      width: 150,
                      hint: '请选择员工类型',
                      value: type,
                      items: [
                        for (final o in EmployeeArchiveController.typeOptions) o,
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
                      leading: const Icon(Icons.refresh, size: 16),
                      child: const Text('重置'),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Row(
                        children: [
                          AppButton.primary(
                            onPressed: c.openCreate,
                            leading: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            child: const Text('新增'),
                          ),
                          const Spacer(),
                          AppInkWell(
                            onPressed: c.search,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.search,
                                size: 18,
                                color: _kMuted,
                              ),
                            ),
                          ),
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
                                  id: 'no',
                                  title: '工号',
                                  width: 88,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.no,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'name',
                                  title: '姓名',
                                  width: 88,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.name,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'pinYin',
                                  title: '拼音',
                                  width: 100,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.pinYin,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'alias',
                                  title: '花名',
                                  width: 88,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.aliasName,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'mobile',
                                  title: '手机号',
                                  width: 120,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.mobile,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'status',
                                  title: '员工状态',
                                  width: 88,
                                  value: (row) =>
                                      EmployeeArchiveController.statusLabel(
                                    row.empStatus,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'type',
                                  title: '员工类型',
                                  width: 100,
                                  value: (row) =>
                                      EmployeeArchiveController.typeLabel(
                                    row.empType,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'timeType',
                                  title: '工时',
                                  width: 72,
                                  value: (row) {
                                    final s =
                                        EmployeeArchiveController.timeTypeLabel(
                                      row.timeType,
                                    );
                                    return s.isEmpty ? '-' : s;
                                  },
                                ),
                                AppDataGridColumn(
                                  id: 'email',
                                  title: '企业邮箱',
                                  width: 180,
                                  value: (row) =>
                                      EmployeeArchiveController.displayOrDash(
                                    row.corpEmail,
                                  ),
                                ),
                                AppDataGridColumn(
                                  id: 'actions',
                                  title: '操作',
                                  width: 220,
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

class _ActionLinks extends StatelessWidget {
  const _ActionLinks({
    required this.row,
    required this.archiveController,
  });

  final HrmEmployeeProfile row;
  final EmployeeArchiveController archiveController;

  void _todo(BuildContext context, String action) {
    final name = row.name?.trim().isNotEmpty == true
        ? row.name!.trim()
        : (row.no?.trim() ?? '');
    AppToast.show(
      context: context,
      title: name.isEmpty ? '$action待接入' : '$action「$name」待接入',
    );
  }

  void _openDetail(BuildContext context) {
    final userId = row.userId;
    if (userId == null) {
      AppToast.show(context: context, title: '缺少用户 ID');
      return;
    }
    archiveController.openDetail(userId);
  }

  void _openEdit(BuildContext context) {
    final userId = row.userId;
    if (userId == null) {
      AppToast.show(context: context, title: '缺少用户 ID');
      return;
    }
    archiveController.openEdit(userId);
  }

  Future<void> _openAppoint(BuildContext context) async {
    final ok = await showEmployeeAppointDialog(context, employee: row);
    if (ok && context.mounted) {
      await archiveController.loadPage();
    }
  }

  Future<void> _openRelieve(BuildContext context) async {
    final ok = await showEmployeeRelieveDialog(context, employee: row);
    if (ok && context.mounted) {
      await archiveController.loadPage();
    }
  }

  Future<void> _openLevel(BuildContext context) async {
    final ok = await showEmployeeLevelDialog(context, employee: row);
    if (ok && context.mounted) {
      await archiveController.loadPage();
    }
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
            AppInkWell(
              onPressed: () => _openEdit(context),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(Icons.edit_outlined, size: 16, color: _kPrimary),
              ),
            ),
            for (final label in const ['档案', '任职', '卸任', '职级'])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: AppInkWell(
                  onPressed: () {
                    if (label == '档案') {
                      _openDetail(context);
                    } else if (label == '任职') {
                      _openAppoint(context);
                    } else if (label == '卸任') {
                      _openRelieve(context);
                    } else if (label == '职级') {
                      _openLevel(context);
                    } else {
                      _todo(context, label);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: _kPrimary),
                    ),
                  ),
                ),
              ),
          ],
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
