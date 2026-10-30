import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import '../../../../models/srm_supplier.dart';
import '../../../../services/srm_supplier_api.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);
const _kDanger = Color(0xFFFF4D4F);

/// 开户行选择：顶部搜索支行 + 省/市/支行级联下钻。
/// 选中后 [onChanged] 回传支行全称（提交 `bankName`）。
class CnapsBankPicker extends StatefulWidget {
  const CnapsBankPicker({
    super.key,
    this.label = '开户行',
    this.required = false,
    this.value,
    this.hintText = '请选择开户行（省 / 市 / 支行）',
    this.enabled = true,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final bool required;
  final String? value;
  final String hintText;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?>? onChanged;

  @override
  State<CnapsBankPicker> createState() => _CnapsBankPickerState();
}

class _CnapsBankPickerState extends State<CnapsBankPicker> {
  final _api = SrmSupplierApi();
  final _layerLink = LayerLink();
  final _searchCtrl = TextEditingController();
  OverlayEntry? _entry;
  Timer? _debounce;

  var _path = <String>[];
  var _nodes = <SrmCnapsTreeNode>[];
  var _searchHits = <SrmCnapsItem>[];
  var _loading = false;
  String? _loadError;
  var _searching = false;

  bool get _open => _entry != null;
  bool get _inSearch => _searchCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _closePopup();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closePopup() {
    _entry?.remove();
    _entry = null;
    _debounce?.cancel();
  }

  Future<void> _toggle() async {
    if (!widget.enabled) return;
    if (_open) {
      setState(() => _closePopup());
      return;
    }
    _path = [];
    _searchCtrl.clear();
    _searchHits = [];
    _searching = false;
    await _loadCascade();
    if (!mounted) return;
    _showPopup();
  }

  void _showPopup() {
    _closePopup();
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 360;
    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _closePopup();
                  setState(() {});
                },
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, (box?.size.height ?? 40) + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: SizedBox(
                  width: width.clamp(280, 480),
                  child: _PopupBody(
                    searchCtrl: _searchCtrl,
                    path: _path,
                    nodes: _nodes,
                    searchHits: _searchHits,
                    loading: _loading,
                    searching: _searching,
                    loadError: _loadError,
                    inSearch: _inSearch,
                    onSearchChanged: _onSearchChanged,
                    onBack: _onBack,
                    onTapNode: _onTapNode,
                    onTapSearch: _onTapSearch,
                    onRetry: () {
                      if (_inSearch) {
                        _runSearch(_searchCtrl.text);
                      } else {
                        _loadCascade();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _rebuildPopup() {
    _entry?.markNeedsBuild();
  }

  Future<void> _loadCascade() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _rebuildPopup();
    try {
      late final List<SrmCnapsTreeNode> list;
      if (_path.isEmpty) {
        list = await _api.fetchCnapsProvinces();
      } else if (_path.length == 1) {
        list = await _api.fetchCnapsCities(_path[0]);
      } else {
        list = await _api.fetchCnapsBranches(
          provinceName: _path[0],
          cityName: _path[1],
        );
      }
      if (!mounted) return;
      _nodes = list;
      _loading = false;
      _loadError = null;
      setState(() {});
      _rebuildPopup();
    } catch (e) {
      if (!mounted) return;
      _loading = false;
      _loadError = e.toString();
      setState(() {});
      _rebuildPopup();
    }
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      _searching = false;
      _searchHits = [];
      _rebuildPopup();
      unawaited(_loadCascade());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String keyword) async {
    _searching = true;
    _loadError = null;
    _rebuildPopup();
    try {
      final hits = await _api.searchCnaps(keyword: keyword, limit: 20);
      if (!mounted) return;
      _searchHits = hits;
      _searching = false;
      _rebuildPopup();
    } catch (e) {
      if (!mounted) return;
      _searching = false;
      _loadError = e.toString();
      _rebuildPopup();
    }
  }

  Future<void> _onBack() async {
    if (_path.isEmpty) return;
    _path = _path.sublist(0, _path.length - 1);
    await _loadCascade();
  }

  Future<void> _onTapNode(SrmCnapsTreeNode node) async {
    final value = (node.value ?? node.label ?? '').trim();
    if (value.isEmpty) return;
    if (node.leaf || _path.length >= 2) {
      _select(value);
      return;
    }
    _path = [..._path, value];
    await _loadCascade();
  }

  void _onTapSearch(SrmCnapsItem item) {
    final name = (item.name ?? '').trim();
    if (name.isEmpty) return;
    _select(name);
  }

  void _select(String name) {
    _closePopup();
    widget.onChanged?.call(name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value?.trim();
    final hasValue = selected != null && selected.isNotEmpty;
    final err = widget.errorText?.trim();
    final borderColor = (err != null && err.isNotEmpty)
        ? _kDanger
        : (_open ? _kPrimary : _kBorder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.required)
              const Text('*', style: TextStyle(color: _kDanger, fontSize: 12)),
            if (widget.required) const SizedBox(width: 2),
            Text(
              widget.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4E5969)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: AppInkWell(
            onPressed: widget.enabled ? _toggle : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? selected : widget.hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasValue ? _kTitle : _kMuted,
                      ),
                    ),
                  ),
                  if (hasValue && widget.enabled)
                    AppInkWell(
                      onPressed: () {
                        widget.onChanged?.call(null);
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: _kMuted,
                      ),
                    )
                  else
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: _kMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (err != null && err.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(err, style: const TextStyle(fontSize: 12, color: _kDanger)),
        ],
      ],
    );
  }
}

class _PopupBody extends StatelessWidget {
  const _PopupBody({
    required this.searchCtrl,
    required this.path,
    required this.nodes,
    required this.searchHits,
    required this.loading,
    required this.searching,
    required this.loadError,
    required this.inSearch,
    required this.onSearchChanged,
    required this.onBack,
    required this.onTapNode,
    required this.onTapSearch,
    required this.onRetry,
  });

  final TextEditingController searchCtrl;
  final List<String> path;
  final List<SrmCnapsTreeNode> nodes;
  final List<SrmCnapsItem> searchHits;
  final bool loading;
  final bool searching;
  final String? loadError;
  final bool inSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBack;
  final ValueChanged<SrmCnapsTreeNode> onTapNode;
  final ValueChanged<SrmCnapsItem> onTapSearch;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索支行名 / 银行名 / 联行号',
                hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
                prefixIcon: const Icon(Icons.search, size: 16, color: _kMuted),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
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
            ),
          ),
          if (!inSearch && path.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AppInkWell(
                onPressed: onBack,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_left, size: 16, color: _kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          path.join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(height: 1, color: _kBorder),
          Flexible(
            child: _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (loading || searching) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loadError!,
              style: const TextStyle(fontSize: 12, color: _kDanger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AppButton.outline(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      );
    }
    if (inSearch) {
      if (searchHits.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('无匹配支行', style: TextStyle(fontSize: 12, color: _kMuted)),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        shrinkWrap: true,
        itemCount: searchHits.length,
        itemBuilder: (context, i) {
          final item = searchHits[i];
          final name = item.name ?? '-';
          final sub = [
            if ((item.bankName ?? '').trim().isNotEmpty) item.bankName!.trim(),
            if ((item.bankCode ?? '').trim().isNotEmpty) item.bankCode!.trim(),
          ].join(' · ');
          return _RowTile(
            title: name,
            subtitle: sub.isEmpty ? null : sub,
            showChevron: false,
            onTap: () => onTapSearch(item),
          );
        },
      );
    }
    if (nodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('暂无数据', style: TextStyle(fontSize: 12, color: _kMuted)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: nodes.length,
      itemBuilder: (context, i) {
        final node = nodes[i];
        final title = (node.label ?? node.value ?? '-').trim();
        final isLeaf = node.leaf || path.length >= 2;
        return _RowTile(
          title: title,
          subtitle: (node.bankCode ?? '').trim().isEmpty
              ? null
              : node.bankCode,
          showChevron: !isLeaf,
          onTap: () => onTapNode(node),
        );
      },
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.title,
    required this.showChevron,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInkWell(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: _kTitle),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 11, color: _kMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, size: 16, color: _kMuted),
          ],
        ),
      ),
    );
  }
}
