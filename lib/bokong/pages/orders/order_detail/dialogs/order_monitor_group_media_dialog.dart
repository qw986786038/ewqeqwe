import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/entity/order/ad_media_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_feedback_entity.dart';
import 'package:yidivination/bokong/entity/order/order_monitor_group_media_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_scene_pic_utils.dart';
import 'package:yidivination/bokong/pages/media/preview/ad_media_preview.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../order_detail_controller.dart';

/// 打开监测拍摄分组媒体弹窗。
void showOrderMonitorGroupMediaDialog(
  BuildContext context, {
  required OrderDetailController controller,
  required int groupId,
  bool autoUpload = false,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1080, initialHeight),
    builder: (dialogContext) => OrderMonitorGroupMediaDialog(
      controller: controller,
      groupId: groupId,
      autoUpload: autoUpload,
    ),
  );
}

/// 监测拍摄分组媒体弹窗：缩略图网格 + 上传 + 删除。
class OrderMonitorGroupMediaDialog extends StatefulWidget {
  const OrderMonitorGroupMediaDialog({
    required this.controller,
    required this.groupId,
    this.autoUpload = false,
    super.key,
  });

  final OrderDetailController controller;
  final int groupId;
  final bool autoUpload;

  @override
  State<OrderMonitorGroupMediaDialog> createState() =>
      _OrderMonitorGroupMediaDialogState();
}

class _OrderMonitorGroupMediaDialogState
    extends State<OrderMonitorGroupMediaDialog> {
  OrderMonitorGroupMediaEntity? _data;
  var _loading = true;
  var _uploading = false;
  var _deleting = false;
  int? _selectedId;

  OrderDetailController get _c => widget.controller;

  OrderMonitorPeriodGroupEntity? get _group => _data?.group;

  List<OrderMonitorGroupMediaItemEntity> get _items => _data?.items ?? const [];

  int get _maxUploadCount => _group?.max_upload_count ?? 10;

  bool get _atUploadLimit => _items.length >= _maxUploadCount;

  bool get _canUpload => !_uploading && !_deleting && !_atUploadLimit;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    await _reload();
    if (!mounted) return;
    if (!widget.autoUpload) return;
    if (_canUpload) {
      await _uploadPhoto();
    } else if (_atUploadLimit) {
      showWarn('已达上传上限（$_maxUploadCount 张）');
    }
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final data = await _c.loadMonitorGroupMedia(widget.groupId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        final ids = _items.map((e) => e.id).whereType<int>().toSet();
        if (_selectedId != null && !ids.contains(_selectedId)) {
          _selectedId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showError('$e');
    }
  }

  String _dialogTitle() {
    final group = _group;
    if (group == null) return '拍摄照片';
    final name = group.group_name?.trim();
    final time = group.time_label?.trim();
    if (name != null &&
        name.isNotEmpty &&
        time != null &&
        time.isNotEmpty &&
        time != '无要求') {
      return '$name-$time';
    }
    if (name != null && name.isNotEmpty) return name;
    final col = group.col_index;
    if (col != null) return '拍摄$col';
    return '拍摄照片';
  }

  Future<void> _uploadPhoto() async {
    if (_uploading || _deleting) return;
    if (_atUploadLimit) {
      showWarn('已达上传上限（$_maxUploadCount 张）');
      return;
    }

    final localPath = await pickLcdDeviceScenePicFilePath();
    if (localPath == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await _c.uploadMonitorGroupMedia(widget.groupId, localPath);
      if (!mounted) return;
      showComplete('上传成功');
      await _reload();
      if (!mounted) return;
      if (_atUploadLimit) {
        showWarn('已达上传上限（$_maxUploadCount 张）');
      }
    } on StateError catch (e) {
      if (e.message != 'cancelled' && mounted) showError('$e');
    } catch (e) {
      if (mounted) showError('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(OrderMonitorGroupMediaItemEntity item) async {
    final id = item.id;
    if (id == null || _deleting) return;

    await showAppWindowDialog<void>(
      context: context,
      builder: (dialogContext) => AppDeleteConfirmAlertDialog(
        title: const Text('删除照片'),
        content: Text('确定删除「${item.file_name ?? '该文件'}」吗？此操作不可撤销。'),
        actions: [
          AppButton.outline(
            onPressed: () => AppOverlay.close<void>(dialogContext),
            child: const Text('取消'),
          ),
          AppButton.destructive(
            onPressed: () async {
              AppOverlay.close<void>(dialogContext);
              setState(() => _deleting = true);
              try {
                await _c.deleteMonitorGroupMedia(mediaId: id);
                if (!mounted) return;
                await _reload();
              } catch (e) {
                if (mounted) showError('$e');
              } finally {
                if (mounted) setState(() => _deleting = false);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    ).future;
  }

  void _previewItem(OrderMonitorGroupMediaItemEntity item) {
    final url = item.file_url?.trim();
    if (url == null || url.isEmpty) return;
    showAdMediaPreviewDialog(
      context: context,
      media: AdMediaEntity()
        ..title = item.file_name
        ..file_path = url
        ..media_type = item.file_type == 'video' ? 2 : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    final group = _group;

    return AppFormDialog(
      title: Text(_dialogTitle()),
      constraints: const BoxConstraints(maxWidth: 1080),
      trailing: AppButton.primary(
        color: const Color(0xFF00A0EC),
        loading: _uploading,
        // 勿直接传 async：AppButton 在外部已传 loading 时不会清掉内部 _running，
        // 会导致上传后按钮永久不可点，关掉弹窗再开才恢复。
        // 满额时仍可点，由 _uploadPhoto 弹出上限提示。
        onPressed: (_uploading || _deleting)
            ? null
            : () {
                unawaited(_uploadPhoto());
              },
        child: Text(_uploading ? '上传中...' : '上传照片'),
      ),
      content: SizedBox(
        width: 1040,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _loading
              ? const Center(child: AppCircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: AppEmptyState())
              : FixedSizeGrid(
                  itemWidth: _MonitorMediaLayout.itemWidth,
                  itemHeight: _MonitorMediaLayout.itemHeight,
                  spacing: 16,
                  maxColumns: 5,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final selected = item.id == _selectedId;
                    return _MonitorMediaCard(
                      item: item,
                      group: group,
                      selected: selected,
                      onTap: () {
                        setState(() => _selectedId = item.id);
                      },
                      onDoubleTap: () => _previewItem(item),
                      onDelete: _deleting || _uploading
                          ? null
                          : () => _confirmDelete(item),
                    );
                  },
                ),
        ),
      ),
      actions: const [],
    );
  }
}

/// 监测拍摄媒体卡片：216×316，缩略图 1:1（216×216）。
abstract final class _MonitorMediaLayout {
  static const itemWidth = 216.0;
  static const itemHeight = 316.0;
}

class _MonitorMediaCard extends StatelessWidget {
  const _MonitorMediaCard({
    required this.item,
    required this.group,
    required this.selected,
    this.onTap,
    this.onDoubleTap,
    this.onDelete,
  });

  static const metaColor = Color(0xFF6B7280);

  final OrderMonitorGroupMediaItemEntity item;
  final OrderMonitorPeriodGroupEntity? group;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final isVideo = item.file_type == 'video';
    final badges = _groupBadges(group, colors.primary);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AppCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadow: false,
        borderWidth: 1,
        borderColor: selected ? colors.primary : colors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                Stack(
                  fit: StackFit.expand,
                  children: [
                    _MonitorMediaThumb(item: item, isVideo: isVideo),
                    if (isVideo) const Center(child: MediaThumbPlayOverlay()),
                  ],
                ),
                if (onDelete != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: MediaThumbDeleteButton(onPressed: onDelete),
                    ),
                  ),
              ],
            ).expanded(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText.label(
                    item.file_name ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppText.caption(
                    item.create_time ?? '-',
                    style: const TextStyle(color: metaColor),
                  ),
                  if (badges.isNotEmpty)
                    Wrap(spacing: 6, runSpacing: 4, children: badges),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _groupBadges(
    OrderMonitorPeriodGroupEntity? group,
    Color primaryColor,
  ) {
    if (group == null) return const [];
    final badges = <Widget>[];
    final watermark = group.watermark_label?.trim();
    if (watermark != null && watermark.isNotEmpty && watermark != '无要求') {
      badges.add(
        AppBadge.custom(
          color: primaryColor,
          appearance: AppBadgeStyle.soft,
          shape: AppBadgeShape.square,
          size: AppBadgeSize.small,
          child: Text(watermark),
        ),
      );
    }
    final distance = group.distance_label?.trim();
    if (distance != null && distance.isNotEmpty && distance != '无要求') {
      badges.add(
        AppBadge.warning(
          appearance: AppBadgeStyle.soft,
          shape: AppBadgeShape.square,
          size: AppBadgeSize.small,
          child: Text(distance),
        ),
      );
    }
    return badges;
  }
}

class _MonitorMediaThumb extends StatelessWidget {
  const _MonitorMediaThumb({required this.item, required this.isVideo});

  final OrderMonitorGroupMediaItemEntity item;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xFF94A3B8);
    final url = item.file_url?.trim();
    if (url == null || url.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFE8EEF3),
        child: Center(
          child: Icon(
            isVideo ? AppLucideIcons.circlePlay : AppLucideIcons.image,
            size: 34,
            color: hintColor,
          ),
        ),
      );
    }

    return ExtendedImage.network(
      url,
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
          return ColoredBox(
            color: const Color(0xFFE8EEF3),
            child: Center(
              child: Icon(
                isVideo ? AppLucideIcons.circlePlay : AppLucideIcons.imageOff,
                size: 34,
                color: hintColor,
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}
