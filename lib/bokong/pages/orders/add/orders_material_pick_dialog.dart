import 'package:extended_image/extended_image.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:yidivination/bokong/api/lcd_api.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/pages/media/add/ad_media_add_dialog.dart';
import 'package:yidivination/bokong/pages/media/ad_media_controller.dart';
import 'package:yidivination/bokong/pages/media/ad_media_utils.dart';
import 'package:yidivination/bokong/pages/media/dialogs/ad_media_delete_dialog.dart';
import 'package:yidivination/bokong/pages/media/dialogs/ad_media_rename_dialog.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/search_icon_button.dart';

/// 打开素材选择弹窗（单选，卡片网格），返回所选素材。
Future<AdMediaEntity?> showOrdersMaterialPickDialog(
  BuildContext context, {
  required int customerId,
  int? initialId,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  return showAppWindowDialog<AdMediaEntity>(
    context: context,
    barrierDismissible: false,
    resizable: true,
    initialSize: Size(960, initialHeight),
    builder: (dialogContext) => LxScope(
      bindings: (container) {
        container.put<AdMediaController>(AdMediaController.new);
      },
      child: _OrdersMaterialPickDialog(
        customerId: customerId,
        initialId: initialId,
      ),
    ),
  ).future;
}

class _OrdersMaterialPickDialog extends StatefulWidget {
  const _OrdersMaterialPickDialog({required this.customerId, this.initialId});

  final int customerId;
  final int? initialId;

  @override
  State<_OrdersMaterialPickDialog> createState() =>
      _OrdersMaterialPickDialogState();
}

class _OrdersMaterialPickDialogState extends State<_OrdersMaterialPickDialog> {
  static const double _gridGap = 16;
  static const int _maxColumns = 6;
  static const double _itemHeight = 270;
  static const double _cardBottomHeight = 64;

  static double get _thumbHeight => _itemHeight - _cardBottomHeight;

  final _kwController = TextEditingController();
  List<AdMediaEntity> _all = const [];
  var _loading = true;
  String? _error;
  int? _draft;
  var _appliedKw = '';
  var _mediaControllerReady = false;

  AdMediaController get _mediaController =>
      context.lx.find<AdMediaController>();

  @override
  void initState() {
    super.initState();
    _draft = widget.initialId;
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mediaControllerReady) return;
    _mediaControllerReady = true;
    _mediaController.customerId.value = widget.customerId;
  }

  @override
  void dispose() {
    _kwController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await LcdApi.mediaList(
        page: 1,
        size: 200,
        param: {
          'customer_id': widget.customerId,
          if (_appliedKw.isNotEmpty) 'title': _appliedKw,
        },
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all = resp.data ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _applySearch() {
    final kw = _kwController.text.trim();
    setState(() => _appliedKw = kw);
    _load();
  }

  Future<void> _addMedia() async {
    _mediaController.customerId.value = widget.customerId;
    final ok = await showAdMediaAddDialog(
      context: context,
      controller: _mediaController,
      scope: AdMediaLibraryScope.local,
    );
    if (ok && mounted) await _load();
  }

  Future<void> _afterMediaChanged() async {
    if (mounted) await _load();
  }

  void _confirm() {
    final id = _draft;
    if (id == null) {
      showWarn('请选择素材');
      return;
    }
    for (final item in _all) {
      if (item.id == id) {
        AppOverlay.close(context, item);
        return;
      }
    }
    showWarn('素材不存在或已失效');
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final items = _all;

    return AppFormDialog(
      title: const Text('素材选择'),
      constraints: const BoxConstraints(minWidth: 880, maxWidth: 960),
      content: SizedBox(
        width: 920,
        height: maxHeight.clamp(420, 640),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final ratio = _mediaController.thumbRatio.value;
              final uploading = _mediaController.uploading.value;
              return Row(
                spacing: 8,
                children: [
                  AppTabs(
                    index: ratio.index,
                    selectedColor: Colors.white,
                    onChanged: (index) => _mediaController.thumbRatio.value =
                        AdMediaThumbRatio.values[index],
                    children: const [
                      AppTabItem(child: Text('1:1')),
                      AppTabItem(child: Text('4:3')),
                      AppTabItem(child: Text('16:9')),
                    ],
                  ),
                  AppTextFormField(
                    width: 280,
                    hintText: '搜索素材',
                    controller: _kwController,
                    onSubmitted: (_) => _applySearch(),
                    trailing: SearchIconButton(onPressed: _applySearch),
                  ),
                  const Spacer(),
                  AppButton.primary(
                    color: const Color(0xFF00A0EC),
                    onPressed: uploading ? null : _addMedia,
                    leading: Icon(
                      uploading
                          ? AppLucideIcons.loaderCircle
                          : AppLucideIcons.plus,
                      size: 16,
                    ),
                    child: const Text('新增'),
                  ),
                ],
              );
            }),
            Expanded(
              child: Obx(() {
                final ratio = _mediaController.thumbRatio.value;
                if (_loading) {
                  return const Center(child: AppCircularProgressIndicator());
                }
                if (_error != null) {
                  return Center(child: AppText.muted(_error!));
                }
                if (items.isEmpty) {
                  return const Center(child: AppEmptyState());
                }
                return FixedSizeGrid(
                  itemWidth: _thumbHeight * ratio.layoutFactor,
                  itemHeight: _itemHeight,
                  spacing: _gridGap,
                  maxColumns: _maxColumns,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = item.id != null && item.id == _draft;
                    return SizedBox.expand(
                      child: _PickMediaCard(
                        item: item,
                        selected: selected,
                        onSelect: () => setState(() => _draft = item.id),
                        onDelete: () async {
                          await showAdMediaDeleteDialog(
                            context,
                            controller: _mediaController,
                            item: item,
                          );
                          await _afterMediaChanged();
                        },
                        onRename: () async {
                          await showAdMediaRenameDialog(
                            context,
                            controller: _mediaController,
                            item: item,
                          );
                          await _afterMediaChanged();
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.outline(
          onPressed: () => AppOverlay.close(context),
          child: const Text('取消'),
        ),
        AppButton.primary(onPressed: _confirm, child: const Text('确定')),
      ],
    );
  }
}

class _PickMediaCard extends StatelessWidget {
  static const Color metaColor = Color(0xFF6B7280);

  const _PickMediaCard({
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
  });

  final AdMediaEntity item;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final resolution = adMediaResolution(item);
    final resolutionLabel = resolution == '-' ? null : resolution;
    final format = item.file_format?.trim().isNotEmpty == true
        ? item.file_format!.trim().toUpperCase()
        : null;
    final duration = item.media_type == 2
        ? adMediaDurationClock(item.duration)
        : '';
    final size = adMediaFileSizeLabel(item.file_size);
    final isWeb = adMediaIsWebType(item.media_type);
    final showPlay = adMediaShowPlayOverlay(item.media_type);

    return GestureDetector(
      onTap: onSelect,
      onDoubleTap: () =>
          showAdMediaPreviewDialog(context: context, media: item),
      child: AppCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadow: false,
        borderWidth: 1,
        borderColor: selected ? const Color(0xFF22C55E) : colors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                _PickThumb(
                  path: resolveAdMediaGridThumbPath(item),
                  isWeb: isWeb,
                ),
                if (selected)
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: MediaThumbCornerStatusBadge(
                      label: '已选中',
                      color: Color(0xFF22C55E),
                    ),
                  ),
                if (resolutionLabel != null || format != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      spacing: 6,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (resolutionLabel != null)
                          MediaThumbOverlayTextBadge(label: resolutionLabel),
                        if (format != null)
                          MediaThumbOverlayTextBadge(label: format),
                      ],
                    ),
                  ),
                if (showPlay) const Center(child: MediaThumbPlayOverlay()),
                if (duration.isNotEmpty)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: MediaThumbOverlayTextBadge(label: duration),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: MediaThumbDeleteButton(onPressed: onDelete),
                ),
              ],
            ).expanded(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                spacing: 6,
                children: [
                  Row(
                    children: [
                      AppText.label(
                        item.title ?? item.media_no ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).expanded(),
                      MediaEditIcon(onPressed: onRename, color: metaColor),
                    ],
                  ),
                  Row(
                    children: [
                      AppText.caption(
                        item.create_time ?? '-',
                        style: const TextStyle(color: metaColor),
                      ).expanded(),
                      if (size.isNotEmpty)
                        AppText.caption(
                          size,
                          style: const TextStyle(color: metaColor),
                        ),
                    ],
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

class _PickThumb extends StatelessWidget {
  const _PickThumb({required this.path, this.isWeb = false});

  final String? path;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xFF94A3B8);
    if (path == null || path!.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFE8EEF3),
        child: Center(
          child: Icon(
            isWeb ? AppLucideIcons.globe : AppLucideIcons.image,
            size: 34,
            color: hintColor,
          ),
        ),
      );
    }

    return ExtendedImage.network(
      path!,
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        if (state.extendedImageLoadState == LoadState.loading) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: AppCircularProgressIndicator(),
            ),
          );
        }
        if (state.extendedImageLoadState == LoadState.failed) {
          return const ColoredBox(
            color: Color(0xFFE8EEF3),
            child: Center(
              child: Icon(AppLucideIcons.imageOff, size: 34, color: hintColor),
            ),
          );
        }
        return null;
      },
    );
  }
}
