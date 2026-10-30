import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);

/// 列头多选筛选（勾选列表 + 筛选 / 重置）。
/// 待上游：建议 [AppDataGridColumn] 支持 `titleBuilder` 后收回叠层方案。
class ColumnHeaderFilter extends StatefulWidget {
  const ColumnHeaderFilter({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onApply,
    this.width,
    this.alignment = Alignment.center,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;
  final double? width;
  final Alignment alignment;

  @override
  State<ColumnHeaderFilter> createState() => _ColumnHeaderFilterState();
}

class _ColumnHeaderFilterState extends State<ColumnHeaderFilter> {
  var _open = false;

  Future<void> _openFilter() async {
    setState(() => _open = true);
    final draft = Set<String>.from(widget.selected);
    await AppPopover.show<void>(
      context: context,
      alignment: Alignment.topLeft,
      anchorAlignment: Alignment.bottomLeft,
      offset: const Offset(0, 4),
      builder: (ctx) {
        return _FilterPanel(
          options: widget.options,
          initial: draft,
          onApply: (next) {
            widget.onApply(next);
            AppOverlay.close(ctx);
          },
          onReset: () {
            widget.onApply({});
            AppOverlay.close(ctx);
          },
        );
      },
    ).future;
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.selected.isNotEmpty;
    return SizedBox(
      width: widget.width,
      child: AppInkWell(
        onPressed: _openFilter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: widget.alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? _kPrimary : _kTitle,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 18,
                  color: active || _open ? _kPrimary : _kMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.options,
    required this.initial,
    required this.onApply,
    required this.onReset,
  });

  final List<String> options;
  final Set<String> initial;
  final ValueChanged<Set<String>> onApply;
  final VoidCallback onReset;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final Set<String> _draft = Set<String>.from(widget.initial);

  @override
  Widget build(BuildContext context) {
    final hasDraft = _draft.isNotEmpty;
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: widget.options.length,
                itemBuilder: (context, i) {
                  final opt = widget.options[i];
                  final checked = _draft.contains(opt);
                  return AppInkWell(
                    onPressed: () {
                      setState(() {
                        if (checked) {
                          _draft.remove(opt);
                        } else {
                          _draft.add(opt);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: checked,
                              tristate: false,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(color: _kBorder),
                              activeColor: _kPrimary,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _draft.add(opt);
                                  } else {
                                    _draft.remove(opt);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kTitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  AppButton.link(
                    onPressed: hasDraft
                        ? () => widget.onApply(Set<String>.from(_draft))
                        : null,
                    child: Text(
                      '筛选',
                      style: TextStyle(
                        color: hasDraft ? _kPrimary : _kMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton.link(
                    onPressed: widget.onReset,
                    child: const Text(
                      '重置',
                      style: TextStyle(color: _kMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 普通列头（无筛选）。
class ColumnHeaderLabel extends StatelessWidget {
  const ColumnHeaderLabel({
    super.key,
    required this.title,
    this.width,
    this.alignment = Alignment.center,
  });

  final String title;
  final double? width;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: alignment,
          child: Text(
            title,
            softWrap: false,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
        ),
      ),
    );
  }
}
