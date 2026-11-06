import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_ui/lemon_ui.dart';

import '../../../../../models/srm_purchase_order.dart';
import '../../../../../services/srm_purchase_order_api.dart';

const _kPrimary = Color(0xFF1677FF);
const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kHeaderBg = Color(0xFFFAFAFA);
const _kBarrier = Color(0x99000000);
const _kSelectedBg = Color(0xFFE8F3FF);

/// 打开「选择采购订单」弹窗（多选未绑定订单）；确定后返回选中订单 id 列表。
Future<List<int>?> showSelectPurchaseOrderDialog(
  BuildContext context, {
  int? excludeSupplierId,
}) {
  return showHyperDialog<List<int>>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
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
          child: _SelectPurchaseOrderDialog(
            excludeSupplierId: excludeSupplierId,
            onClose: () => Navigator.of(dialogContext).pop(),
            onConfirm: (ids) => Navigator.of(dialogContext).pop(ids),
          ),
        ),
      );
    },
  );
}

class _SelectPurchaseOrderDialog extends StatefulWidget {
  const _SelectPurchaseOrderDialog({
    required this.onClose,
    required this.onConfirm,
    this.excludeSupplierId,
  });

  final int? excludeSupplierId;
  final VoidCallback onClose;
  final ValueChanged<List<int>> onConfirm;

  @override
  State<_SelectPurchaseOrderDialog> createState() =>
      _SelectPurchaseOrderDialogState();
}

class _SelectPurchaseOrderDialogState
    extends State<_SelectPurchaseOrderDialog> {
  final _api = SrmPurchaseOrderApi();
  final _keywordCtrl = TextEditingController();
  final _selected = <String>{};

  var _loading = true;
  String? _error;
  List<SrmPurchaseOrder> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.fetchList(
        SrmPurchaseOrderQuery(
          keyword: _keywordCtrl.text.trim().isEmpty
              ? null
              : _keywordCtrl.text.trim(),
          unboundOnly: true,
          excludeSupplierId: widget.excludeSupplierId,
          pageNum: 1,
          pageSize: 200,
        ),
      );
      if (!mounted) return;
      setState(() {
        _rows = page.rows;
        _loading = false;
        _selected.removeWhere((id) => !_rows.any((e) => e.id == id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _toggle(String? id, bool checked) {
    final sid = id?.trim();
    if (sid == null || sid.isEmpty) return;
    setState(() {
      if (checked) {
        _selected.add(sid);
      } else {
        _selected.remove(sid);
      }
    });
  }

  void _toggleAll(bool checked) {
    setState(() {
      if (!checked) {
        _selected.clear();
        return;
      }
      _selected
        ..clear()
        ..addAll({
          for (final e in _rows)
            if ((e.id ?? '').trim().isNotEmpty) e.id!.trim(),
        });
    });
  }

  void _confirm() {
    final ids = <int>[
      for (final id in _selected)
        if (int.tryParse(id) != null) int.parse(id),
    ];
    if (ids.isEmpty) return;
    widget.onConfirm(ids);
  }

  String _dash(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? '-' : t;
  }

  String _amount(SrmPurchaseOrder row) {
    final v = row.orderAmount;
    if (v == null) return '-';
    return v.toStringAsFixed(2);
  }

  String _orderTitle(SrmPurchaseOrder row) {
    final name = row.orderName?.trim();
    final no = row.orderNo?.trim();
    if (name != null && name.isNotEmpty && no != null && no.isNotEmpty) {
      return '$name / $no';
    }
    return name ?? no ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    final allIds = [
      for (final e in _rows)
        if ((e.id ?? '').trim().isNotEmpty) e.id!.trim(),
    ];
    final allChecked =
        allIds.isNotEmpty && allIds.every(_selected.contains);
    final someChecked = allIds.any(_selected.contains);
    final headerState = allChecked
        ? CheckboxState.checked
        : someChecked
            ? CheckboxState.indeterminate
            : CheckboxState.unchecked;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 720,
            maxWidth: 880,
            minHeight: 460,
            maxHeight: 620,
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
                        '选择采购订单',
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keywordCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '搜索订单名称 / 订单号 / 品牌',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: _kMuted,
                            ),
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
                          onSubmitted: (_) => _load(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      HyperButton.filled(
                        onPressed: _loading ? null : _load,
                        label: const Text('查询'),
                      ),
                    ],
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Color(0xFFCF1322),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    HyperButton.outlined(
                                      onPressed: _load,
                                      label: const Text('重试'),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: 36,
                                    color: _kHeaderBg,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: AppInkWell(
                                            onPressed: () =>
                                                _toggleAll(!allChecked),
                                            child: Center(
                                              child: AppCheckboxIndicator(
                                                state: headerState,
                                                onChanged: (state) =>
                                                    _toggleAll(
                                                  state ==
                                                      CheckboxState.checked,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 3,
                                          child: Text(
                                            '订单名称 / 订单号',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            '订单标签',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            '关联品牌',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            '合同类型',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            '订单金额(万元)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _kTitle,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            '订单时间',
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
                                    child: _rows.isEmpty
                                        ? const Center(
                                            child: Text(
                                              '暂无未关联的采购订单',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _kMuted,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: _rows.length,
                                            itemBuilder: (context, index) {
                                              final row = _rows[index];
                                              final id = row.id?.trim() ?? '';
                                              final checked =
                                                  id.isNotEmpty &&
                                                      _selected.contains(id);
                                              return _OrderRow(
                                                checked: checked,
                                                title: _orderTitle(row),
                                                tag: _dash(row.orderTag),
                                                brand: _dash(row.brandName),
                                                contract:
                                                    _dash(row.contractType),
                                                amount: _amount(row),
                                                time: _dash(row.orderTime),
                                                onTap: id.isEmpty
                                                    ? null
                                                    : () =>
                                                        _toggle(id, !checked),
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
                  child: Row(
                    children: [
                      Text(
                        '已选 ${_selected.length} 条',
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                      const Spacer(),
                      HyperButton.outlined(
                        onPressed: widget.onClose,
                        label: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      HyperButton.filled(
                        onPressed: _selected.isEmpty ? null : _confirm,
                        label: const Text('确定'),
                      ),
                    ],
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

class _OrderRow extends StatefulWidget {
  const _OrderRow({
    required this.checked,
    required this.title,
    required this.tag,
    required this.brand,
    required this.contract,
    required this.amount,
    required this.time,
    this.onTap,
  });

  final bool checked;
  final String title;
  final String tag;
  final String brand;
  final String contract;
  final String amount;
  final String time;
  final VoidCallback? onTap;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AppInkWell(
        onPressed: widget.onTap,
        child: Container(
          height: 40,
          color: widget.checked
              ? _kSelectedBg
              : _hovered
                  ? const Color(0xFFF5F7FA)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Center(
                  child: AppCheckboxIndicator(
                    state: widget.checked
                        ? CheckboxState.checked
                        : CheckboxState.unchecked,
                    onChanged: widget.onTap == null
                        ? null
                        : (_) => widget.onTap!(),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.contract,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kTitle),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
