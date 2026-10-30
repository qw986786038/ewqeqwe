import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/entity/order/order_entity.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/order_release_material_card.dart';

import '../order_detail_controller.dart';
import 'order_release_edit_dialog.dart';

/// 打开订单广告物料「查看全部」弹窗。
void showOrderMaterialsDialog(
  BuildContext context, {
  required OrderDetailController controller,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(1080, initialHeight),
    builder: (dialogContext) => OrderMaterialsDialog(controller: controller),
  );
}

/// 订单广告物料弹窗：比例 Tab + 网格卡片（对齐素材库样式）。
class OrderMaterialsDialog extends StatefulWidget {
  const OrderMaterialsDialog({required this.controller, super.key});

  final OrderDetailController controller;

  @override
  State<OrderMaterialsDialog> createState() => _OrderMaterialsDialogState();
}

class _OrderMaterialsDialogState extends State<OrderMaterialsDialog> {
  static const double _gridGap = 16;
  static const int _maxColumns = 5;
  static const double _itemHeight = 270;
  static const double _cardBottomHeight = OrderReleaseMaterialCard.bottomHeight;
  static const Color _addTagColor = Color(0xFF15803D);
  static const _tagPalette = [
    Color(0xFFF97316),
    Color(0xFF22C55E),
    Color(0xFF38BDF8),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFFEAB308),
    Color(0xFF14B8A6),
  ];
  static const _tagSize = AppBadgeSize(
    fontSize: 12,
    height: 20,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    iconSize: 12,
    contentGap: 4,
  );

  static double get _thumbHeight => _itemHeight - _cardBottomHeight;

  var _thumbRatio = AdMediaThumbRatio.r4x3;

  OrderDetailController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.refreshOrderDetail();
    });
  }

  Future<void> _showAddTagDialog() async {
    await showOrderMaterialAddTagDialog(context, onSubmit: _c.addOrderTag);
  }

  Future<void> _confirmDeleteRelease(OrderItemEntity item) async {
    final title = orderReleaseMaterialTitle(item);
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '删除发布单',
      message: '确定要删除「$title」吗？此操作不可撤销。',
    );
    if (!confirmed || !mounted) return;
    await _c.deleteRelease(item);
  }

  /// 浅底 + 同色描边，与侧边栏标签一致。
  Widget _orderTagChip({required String label, required Color color}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.14),
          const Color(0xFFFFFFFF),
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: _tagSize.padding,
        child: SizedBox(
          height: _tagSize.height,
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _tagSize.fontSize,
                color: color,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final industryLabel = _c.displayIndustryLabel;
    final industryTag = industryLabel == '-' ? null : industryLabel;

    return AppFormDialog(
      title: Obx(() {
        final tags = _c.orderTags.toList();
        return Row(
          spacing: 8,
          children: [
            const Text('广告物料'),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < tags.length; i++)
                    _orderTagChip(
                      label: tags[i],
                      color: _tagPalette[i % _tagPalette.length],
                    ),
                  AppButton.ghost(
                    size: AppButtonSize.small,
                    leading: const Icon(
                      AppLucideIcons.tags,
                      size: 14,
                      color: _addTagColor,
                    ),
                    onPressed: _showAddTagDialog,
                    child: const Text(
                      '添加标签',
                      style: TextStyle(color: _addTagColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      constraints: const BoxConstraints(maxWidth: 1080),
      content: SizedBox(
        width: 1040,
        height: maxHeight.clamp(420, 640),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppTabs(
                  index: _thumbRatio.index,
                  selectedColor: Colors.white,
                  onChanged: (index) => setState(
                    () => _thumbRatio = AdMediaThumbRatio.values[index],
                  ),
                  children: const [
                    AppTabItem(child: Text('1:1')),
                    AppTabItem(child: Text('4:3')),
                    AppTabItem(child: Text('16:9')),
                  ],
                ),
              ],
            ),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final selectedKey = _c.selectedReleaseKey.value;
                  final materials = _c.releaseItems;
                  if (materials.isEmpty) {
                    return const Center(child: AppEmptyState());
                  }
                  return FixedSizeGrid(
                    itemWidth: _thumbHeight * _thumbRatio.layoutFactor,
                    itemHeight: _itemHeight,
                    spacing: _gridGap,
                    maxColumns: _maxColumns,
                    itemCount: materials.length,
                    itemBuilder: (context, index) {
                      final item = materials[index];
                      return SizedBox.expand(
                        child: OrderReleaseMaterialCard(
                          item: item,
                          fillCell: true,
                          industryLabel: industryTag,
                          selected: _c.releaseRowKey(item) == selectedKey,
                          onTap: () => _c.selectRelease(item),
                          onDoubleTap: () => showAdMediaPreviewDialog(
                            context: context,
                            media: orderReleaseToAdMedia(item),
                          ),
                          onEdit: () => showOrderReleaseEditDialog(
                            context,
                            controller: _c,
                            item: item,
                          ),
                          onDelete: () => _confirmDeleteRelease(item),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(context),
          child: const Text('取消'),
        ),
        AppButton.primary(
          onPressed: () => AppOverlay.close(context),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 广告物料添加标签输入弹窗。
Future<bool> showOrderMaterialAddTagDialog(
  BuildContext context, {
  required Future<bool> Function(String tag) onSubmit,
}) {
  return showAppWindowDialog<bool>(
    context: context,
    builder: (dialogContext) => _OrderMaterialAddTagDialog(
      onSubmit: (tag) async {
        final ok = await onSubmit(tag);
        if (ok && dialogContext.mounted) {
          AppOverlay.close(dialogContext, true);
        }
        return ok;
      },
      onCancel: () => AppOverlay.close(dialogContext, false),
    ),
  ).future.then((value) => value == true);
}

class _OrderMaterialAddTagDialog extends StatefulWidget {
  const _OrderMaterialAddTagDialog({
    required this.onSubmit,
    required this.onCancel,
  });

  final Future<bool> Function(String tag) onSubmit;
  final VoidCallback onCancel;

  @override
  State<_OrderMaterialAddTagDialog> createState() =>
      _OrderMaterialAddTagDialogState();
}

class _OrderMaterialAddTagDialogState
    extends State<_OrderMaterialAddTagDialog> {
  final _form = AppFormController();
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _form.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await _form.submit((values) async {
      final tag =
          (values['tag'] as String?)?.trim() ?? _tagController.text.trim();
      if (tag.isEmpty) {
        showWarn('请输入标签');
        return;
      }
      await widget.onSubmit(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppForm(
      controller: _form,
      child: AppFormDialog(
        title: const Text('添加标签'),
        constraints: const BoxConstraints(maxWidth: 420),
        content: AppCard(
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: AppFieldScope.horizontal(
            labelWidth: 56,
            child: AppTextFormField(
              name: 'tag',
              label: '标签',
              hintText: '输入标签',
              required: true,
              controller: _tagController,
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        actions: [
          AppButton.outline(
            onPressed: widget.onCancel,
            child: const Text('取消'),
          ),
          AppButton.primary(
            color: const Color(0xFF00A0EC),
            onPressed: _submit,
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
