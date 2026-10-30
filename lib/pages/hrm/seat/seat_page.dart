import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../../models/hrm_position.dart';
import 'add/seat_form_dialog.dart';
import 'seat_controller.dart';

const _kPrimary = Color(0xFF1677FF);
const _kPageBg = Color(0xFFF0F2F5);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kLabel = Color(0xFF4E5969);

/// HRM · 席位。
class SeatPage extends StatelessWidget {
  const SeatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LxScope(
      bindings: (container) {
        container.put<SeatController>(SeatController.new);
      },
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = context.lx.find<SeatController>();
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
                final metaVer = c.metaVersion.value;
                final deptId = c.filterDeptId.value;
                final postId = c.filterPostId.value;
                final type = c.filterType.value;
                return Wrap(
                  key: ValueKey('seat-filters-$metaVer'),
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FilterSelect<String>(
                      label: '所属部门',
                      width: 200,
                      hint: '请选择部门',
                      value: deptId,
                      items: [
                        for (final d in c.depts)
                          if (d.deptId != null &&
                              d.deptId!.trim().isNotEmpty &&
                              d.deptName?.trim().isNotEmpty == true)
                            (d.deptId!.trim(), d.deptName!.trim()),
                      ],
                      onChanged: (v) => c.filterDeptId.value = v,
                    ),
                    _FilterSelect<String>(
                      label: '所属岗位',
                      width: 180,
                      hint: '请选择岗位',
                      value: postId,
                      items: [
                        for (final p in c.posts)
                          if (p.id != null &&
                              p.id!.trim().isNotEmpty &&
                              p.name?.trim().isNotEmpty == true)
                            (p.id!.trim(), p.name!.trim()),
                      ],
                      onChanged: (v) => c.filterPostId.value = v,
                    ),
                    _FilterSelect<String>(
                      label: '编制类型',
                      width: 160,
                      hint: '请选择编制类型',
                      value: type,
                      items: [
                        for (final t in SeatController.typeOptions) t,
                      ],
                      onChanged: (v) => c.filterType.value = v,
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
                            onPressed: () => showSeatAddDialog(context),
                            leading: const Icon(Icons.add, size: 16),
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
                            return AppDataGrid<HrmPosition>.local(
                              height: h > 0 ? h : 420,
                              rows: rows,
                              rowKey: (row) => row.id ?? '',
                              sortable: true,
                              showInternalDividers: true,
                              headerBackgroundColor: const Color(0xFFFAFAFA),
                              textStyle: const TextStyle(fontSize: 12),
                              cellTextStyle: const TextStyle(fontSize: 12),
                              empty: const Center(
                                child: Text(
                                  '暂无席位',
                                  style: TextStyle(color: _kMuted),
                                ),
                              ),
                              columns: [
                                AppDataGridColumn(
                                  id: 'dept',
                                  title: '所属部门',
                                  width: 140,
                                  value: (row) => c.deptDisplay(row),
                                ),
                                AppDataGridColumn(
                                  id: 'post',
                                  title: '所属岗位',
                                  width: 120,
                                  value: (row) => c.postDisplay(row),
                                ),
                                AppDataGridColumn(
                                  id: 'type',
                                  title: '编制类型',
                                  width: 100,
                                  value: (row) =>
                                      SeatController.typeLabel(row.type),
                                ),
                                AppDataGridColumn(
                                  id: 'report',
                                  title: '行政汇报席位',
                                  width: 240,
                                  value: (row) {
                                    final s = c.positionRefDisplay(
                                      row.reportPositionId,
                                    );
                                    return s.isEmpty ? '-' : s;
                                  },
                                ),
                                AppDataGridColumn(
                                  id: 'dotted',
                                  title: '虚线汇报席位',
                                  width: 240,
                                  value: (row) {
                                    final s = c.positionRefDisplay(
                                      row.dottedPositionId,
                                    );
                                    return s.isEmpty ? '-' : s;
                                  },
                                ),
                                AppDataGridColumn(
                                  id: 'actions',
                                  title: '操作',
                                  width: 88,
                                  sortable: false,
                                  resizable: false,
                                  pin: AppDataGridColumnPin.end,
                                  value: (_) => '',
                                  cellBuilder: (context, row, _) => Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppInkWell(
                                          onPressed: () =>
                                              showSeatEditDialog(context, row),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: _kPrimary,
                                            ),
                                          ),
                                        ),
                                        AppInkWell(
                                          onPressed: () =>
                                              _confirmDelete(context, row),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: _kPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
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

Future<void> _confirmDelete(BuildContext context, HrmPosition seat) async {
  final id = seat.id?.trim();
  if (id == null || id.isEmpty) {
    AppToast.show(context: context, title: '席位 id 无效');
    return;
  }
  final c = context.lx.find<SeatController>();
  final label =
      '${c.deptDisplay(seat)} / ${c.postDisplay(seat)} / ${SeatController.typeLabel(seat.type)}';
  final hostContext = context;
  final ok = await AppDialog.show<bool>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      title: const Text('确认删除'),
      content: Text('确定删除席位「$label」吗？'),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(dialogContext, false),
          child: const Text('取消'),
        ),
        AppButton.destructive(
          onPressed: () => AppOverlay.close(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  ).future;
  if (ok != true) return;
  try {
    await c.deleteSeat(id);
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: '删除席位成功');
    }
  } catch (e) {
    if (hostContext.mounted) {
      AppToast.show(context: hostContext, title: e.toString());
    }
  }
}

List<int> _pageWindow(int current, int total) {
  if (total <= 0) return const [1];
  final end = (current + 2).clamp(1, total);
  final start = (end - 4).clamp(1, total);
  return [for (var i = start; i <= end; i++) i];
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
