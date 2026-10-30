import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/entity/order/ad_content_group_entity.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';

/// 排他行业多选（横向标签 + 点击弹窗勾选）。
class LcdProgramExclusiveIndustryField extends FormField<Set<int>> {
  LcdProgramExclusiveIndustryField({
    super.key,
    required List<AdContentGroupEntity> items,
    required Future<void> Function() reload,
    Set<int>? initialValue,
    this.labelText = '排他行业',
    this.labelWidth = 88,
    ValueChanged<Set<int>>? onChanged,
    FormFieldSetter<Set<int>>? onSaved,
    FormFieldValidator<Set<int>>? validator,
  }) : super(
         initialValue: initialValue ?? {},
         onSaved: onSaved,
         validator: validator,
         builder: (FormFieldState<Set<int>> field) {
           final Set<int> selected = field.value ?? {};
           final String displayText = selected.isEmpty
               ? '请选择行业（可多选）'
               : () {
                   final String names = items
                       .where((e) => selected.contains(e.id))
                       .map((e) => e.category_name ?? '-')
                       .join('、');
                   if (names.isNotEmpty) return names;
                   return '已选 ${selected.length} 项';
                 }();

           return AppField(
             label: labelText,
             labelWidth: labelWidth,
             layout: AppFieldLayout.horizontal,
             errorText: field.errorText,
             child: Row(
               spacing: 12,
               children: [
                 AppButton.primary(
                   onPressed: () async {
                     final BuildContext hostContext = field.context;
                     await reload();
                     if (!hostContext.mounted) return;
                     final Set<int>? next = await showExclusiveIndustryPicker(
                       context: hostContext,
                       items: items,
                       selected: selected,
                     );
                     if (next == null) return;
                     field.didChange(next);
                     onChanged?.call(next);
                   },
                   child: const Text('选择行业'),
                 ),
                 Expanded(
                   child: AppText(
                     displayText,
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
               ],
             ),
           );
         },
       );

  final String labelText;
  final double labelWidth;
}

Future<Set<int>?> showExclusiveIndustryPicker({
  required BuildContext context,
  required List<AdContentGroupEntity> items,
  required Set<int> selected,
}) async {
  final List<AppOption<int>> options = items
      .where((e) => e.id != null)
      .map((e) => AppOption<int>(value: e.id!, label: e.category_name ?? '-'))
      .toList();
  List<int> draft = selected
      .where((id) => options.any((o) => o.value == id))
      .toList();

  final bool? confirmed = await showAppWindowDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AppFormDialog(
            title: const Text('选择排他行业'),
            constraints: const BoxConstraints(minWidth: 420, maxWidth: 480),
            content: AppCard(
              borderWidth: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: options.isEmpty
                    ? const Center(child: AppEmptyState())
                    : AppCheckboxGroup<int>(
                        options: options,
                        value: draft,
                        valueDirection: Axis.vertical,
                        onChanged: (value) =>
                            setDialogState(() => draft = value),
                      ).scroll(),
              ),
            ),
            actions: [
              AppButton.outline(
                onPressed: () => AppOverlay.close<bool>(dialogContext, false),
                child: const Text('取消'),
              ),
              AppButton.primary(
                onPressed: () => AppOverlay.close<bool>(dialogContext, true),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  ).future;

  if (confirmed != true) return null;
  return draft.toSet();
}

Set<int> parseExclusiveIndustryIds(
  String? raw,
  List<AdContentGroupEntity> items,
) {
  if (raw == null || raw.trim().isEmpty) return {};
  final Iterable<String> parts = raw
      .split(RegExp(r'[,、，]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty);
  final Set<int> ids = <int>{};
  for (final String part in parts) {
    final int? asId = int.tryParse(part);
    if (asId != null) {
      ids.add(asId);
      continue;
    }
    for (final AdContentGroupEntity item in items) {
      if (item.category_name == part && item.id != null) {
        ids.add(item.id!);
      }
    }
  }
  return ids;
}
