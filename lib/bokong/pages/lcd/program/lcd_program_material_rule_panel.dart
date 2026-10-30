import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_program_material_entity.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/pages/lcd/program/lcd_program_exclusive_industry_field.dart';

/// 素材详情：排他行业 / 排他时长 / 循环间隔。
///
/// [readOnly] 为 true 时仅展示；无值显示「无」。
class LcdProgramMaterialRulePanel extends StatefulWidget {
  const LcdProgramMaterialRulePanel({
    super.key,
    required this.material,
    required this.labelWidth,
    this.onSave,
    this.showTitle = true,
    this.readOnly = false,
  }) : assert(readOnly || onSave != null);

  final LcdProgramMaterialEntity material;
  final double labelWidth;
  final Future<void> Function({
    required int materialId,
    Set<int>? industryIds,
    int? exclusiveRule,
    int? loopRule,
  })?
  onSave;
  final bool showTitle;
  final bool readOnly;

  @override
  State<LcdProgramMaterialRulePanel> createState() =>
      _LcdProgramMaterialRulePanelState();
}

class _LcdProgramMaterialRulePanelState
    extends State<LcdProgramMaterialRulePanel> {
  List<AdContentGroupEntity> _industryItems = [];

  @override
  void initState() {
    super.initState();
    unawaited(_reloadIndustryItems());
  }

  @override
  void didUpdateWidget(LcdProgramMaterialRulePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.material.id != widget.material.id) {
      unawaited(_reloadIndustryItems());
    }
  }

  Future<void> _reloadIndustryItems() async {
    final resp = await LcdApi.contentGroupList(page: 1, size: 500);
    if (!mounted) return;
    setState(() => _industryItems = resp.data ?? []);
  }

  int? get _materialId => widget.material.id;

  int get _exclusiveRule {
    final rule = widget.material.exclusive_rule?.trim();
    if (rule == null || rule.isEmpty) return 0;
    return int.tryParse(rule) ?? 0;
  }

  int get _loopRule => widget.material.loop_rule ?? 0;

  Set<int> get _industryIds => parseExclusiveIndustryIds(
    widget.material.exclusive_industry,
    _industryItems,
  );

  List<int> get _sortedIndustryIds {
    final ids = _industryIds.toList()..sort();
    return ids;
  }

  List<AppOption<int>> get _industryOptions => [
    for (final item in _industryItems)
      if (item.id != null)
        AppOption<int>(value: item.id!, label: item.category_name ?? '-'),
  ];

  Future<void> _persist({
    Set<int>? industryIds,
    int? exclusiveRule,
    int? loopRule,
  }) async {
    final id = _materialId;
    final save = widget.onSave;
    if (id == null || save == null) return;
    await save(
      materialId: id,
      industryIds: industryIds,
      exclusiveRule: exclusiveRule,
      loopRule: loopRule,
    );
  }

  String _industryLabel(Set<int> selected) {
    if (selected.isEmpty) {
      final raw = widget.material.exclusive_industry?.trim();
      if (raw == null || raw.isEmpty) return '无';
      // 行业列表尚未解析出 id 时，尽量展示原始文案（非纯数字）。
      if (int.tryParse(raw.split(RegExp(r'[,、，]')).first.trim()) == null) {
        return raw;
      }
      return '无';
    }
    final names = _industryItems
        .where((item) => selected.contains(item.id))
        .map((item) => item.category_name ?? '-')
        .join('、');
    if (names.isNotEmpty) return names;
    return '已选 ${selected.length} 项';
  }

  Widget _industryDisplayWidget(Set<int> selected) {
    final text = _industryLabel(selected);
    if (widget.readOnly) return Text(text);
    if (selected.isEmpty) {
      return AppText.muted('请选择行业（可多选）');
    }
    return Text(text);
  }

  String _secondsLabel(int value) {
    if (widget.readOnly && value <= 0) return '无';
    return '$value 秒';
  }

  Widget _secondsDisplay(int value) => Text(_secondsLabel(value));

  @override
  Widget build(BuildContext context) {
    final materialId = _materialId;
    if (materialId == null) {
      return const SizedBox.shrink();
    }

    final colors = ShadcnTheme.of(context).colorScheme;
    final selected = _industryIds;

    return AppDescriptions(
      labelWidth: widget.labelWidth,
      runSpacing: 0,
      valueHeight: AppControlMetricsScope.resolve(context).height,
      layout: AppDescriptionLayout.horizontal,
      title: widget.showTitle ? const Text('排它要求') : null,
      titleIcon: widget.showTitle
          ? AppAvatar.square(
              appearance: AppAvatarAppearance.soft,
              icon: const Icon(AppLucideIcons.listChecks),
              color: colors.primary,
              size: 24,
              borderRadius: 6,
            )
          : null,
      items: [
        AppDescriptionItem(
          label: const Text('排它行业'),
          value: widget.readOnly
              ? _industryDisplayWidget(selected)
              : AppInlineEdit<List<int>>(
                  key: ValueKey(
                    'industry-$materialId-${widget.material.exclusive_industry}-'
                    '${_industryItems.length}',
                  ),
                  value: _sortedIndustryIds,
                  displayBuilder: (_, value) =>
                      _industryDisplayWidget(value.toSet()),
                  valuesEqual: (left, right) {
                    final a = left.toSet();
                    final b = right.toSet();
                    return a.length == b.length && a.containsAll(b);
                  },
                  saveOnBlur: true,
                  onSaved: (value) => _persist(industryIds: value.toSet()),
                  editorBuilder: (context, details) => AppMultiSelect<int>(
                    options: _industryOptions,
                    value: details.value,
                    enabled: !details.saving,
                    onChanged: (value) =>
                        details.onChanged([...(value ?? const [])]..sort()),
                  ),
                ),
        ),
        AppDescriptionItem(
          label: const Text('排它时长'),
          value: widget.readOnly
              ? _secondsDisplay(_exclusiveRule)
              : AppInlineEdit.number(
                  key: ValueKey(
                    'exclusive-$materialId-${widget.material.exclusive_rule}',
                  ),
                  value: _exclusiveRule,
                  min: 0,
                  displayBuilder: (_, value) => _secondsDisplay(value),
                  onSaved: (value) => _persist(exclusiveRule: value),
                ),
        ),
        AppDescriptionItem(
          label: const Text('循环间隔'),
          value: widget.readOnly
              ? _secondsDisplay(_loopRule)
              : AppInlineEdit.number(
                  key: ValueKey(
                    'loop-$materialId-${widget.material.loop_rule}',
                  ),
                  value: _loopRule,
                  min: 1,
                  displayBuilder: (_, value) => _secondsDisplay(value),
                  onSaved: (value) => _persist(loopRule: value),
                ),
        ),
      ],
    );
  }
}
