import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../../customer_archive/dialogs/select_sales_person_dialog.dart'
    show hrmEmployeeDeptPost, hrmEmployeeStatusLabel;
import '../../../../models/hrm_employee.dart';
import '../../../../services/hrm_api.dart';

const _kPrimary = Color(0xFF1677FF);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kHeaderBg = Color(0xFFFAFAFA);
const _kHoverBg = Color(0xFFF5F7FA);
const _kBarrier = Color(0x99000000);

/// 打开「选择对接人员」弹窗（单选）；点行即选中返回，取消返回 `null`。
Future<HrmEmployee?> showSelectCounterpartDialog(BuildContext context) async {
  // 与供应商编辑弹窗一致：等 pointer 结束再推路由，避免 MouseTracker 重入。
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return null;
  return showHyperDialog<HrmEmployee>(
    context: context,
    barrierDismissible: false,
    style: const HyperDialogStyle(barrierColor: _kBarrier),
    builder: (dialogContext) {
      final mq = MediaQuery.of(dialogContext);
      return AppShadcnScope(
        config: AppThemeConfig.standard(
          primary: _kPrimary,
          themeMode: AppThemeMode.light,
          controls: const AppControlMetrics(
            height: 34,
            buttonHeight: 32,
            horizontalPadding: 10,
            fontSize: 12,
            iconSize: 14,
            contentGap: 6,
          ),
        ),
        child: MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.noScaling),
          child: _SelectCounterpartDialog(
            onClose: () => Navigator.of(dialogContext).pop(),
            onPick: (e) => Navigator.of(dialogContext).pop(e),
          ),
        ),
      );
    },
  );
}

class _SelectCounterpartDialog extends StatefulWidget {
  const _SelectCounterpartDialog({
    required this.onClose,
    required this.onPick,
  });

  final VoidCallback onClose;
  final ValueChanged<HrmEmployee> onPick;

  @override
  State<_SelectCounterpartDialog> createState() =>
      _SelectCounterpartDialogState();
}

class _SelectCounterpartDialogState extends State<_SelectCounterpartDialog> {
  final _api = HrmApi();
  final _nameFilterCtrl = TextEditingController();

  var _loading = true;
  String? _error;
  List<HrmEmployee> _employees = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchEmployees();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<HrmEmployee> get _visible {
    final q = _nameFilterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _employees;
    return [
      for (final e in _employees)
        if ((e.name?.toLowerCase().contains(q) ?? false) ||
            (e.englishName?.toLowerCase().contains(q) ?? false))
          e,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 520,
            maxWidth: 640,
            minHeight: 420,
            maxHeight: 560,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Text(
                        '选择对接人员',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTitle,
                        ),
                      ),
                      const Spacer(),
                      AppInkWell(
                        onPressed: widget.onClose,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close, size: 18, color: _kMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _nameFilterCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '输入姓名搜索',
                      hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFCF1322),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: 36,
                                    color: _kHeaderBg,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '姓名',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            '部门/职位',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 64,
                                          child: Text(
                                            '状态',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: _kBorder),
                                  Expanded(
                                    child: rows.isEmpty
                                        ? const Center(
                                            child: Text(
                                              '暂无人员',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _kMuted,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: rows.length,
                                            itemBuilder: (context, index) {
                                              final e = rows[index];
                                              return _EmpRow(
                                                employee: e,
                                                onTap: () => widget.onPick(e),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: HyperButton.outlined(
                      onPressed: widget.onClose,
                      label: const Text('取消'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmpRow extends StatefulWidget {
  const _EmpRow({required this.employee, required this.onTap});

  final HrmEmployee employee;
  final VoidCallback onTap;

  @override
  State<_EmpRow> createState() => _EmpRowState();
}

class _EmpRowState extends State<_EmpRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;
    final deptPost = hrmEmployeeDeptPost(e);
    final status = hrmEmployeeStatusLabel(e.empStatus);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AppInkWell(
        onPressed: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _hovered ? _kHoverBg : null,
            border: const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  e.name ?? '-',
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  deptPost == '-' ? '' : deptPost,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  status == '-' ? '' : status,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
