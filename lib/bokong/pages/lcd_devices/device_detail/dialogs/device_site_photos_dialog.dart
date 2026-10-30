import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:path/path.dart' as p;
import 'package:yidivination/bokong/api/common_api.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_scene_pic_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/lcd_device_scene_pic_utils.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/app_dialog_close_button.dart';
import 'package:yidivination/bokong/widget/app_delete_confirm_dialog.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';
import 'package:yidivination/bokong/widget/fixed_size_grid.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../device_detail_controller.dart';

/// 打开设备现场照片弹窗。
void showDeviceSitePhotosDialog(
  BuildContext context, {
  required LcdDeviceDetailController controller,
}) {
  final screen = MediaQuery.sizeOf(context);
  final initialHeight = (screen.height * 0.72).clamp(420.0, 720.0);
  showAppWindowDialog<void>(
    context: context,
    resizable: true,
    initialSize: Size(1080, initialHeight),
    builder: (dialogContext) => DeviceSitePhotosDialog(controller: controller),
  );
}

/// 现场照片弹窗：缩略图网格 + 新增 + 删除 + 下载。
class DeviceSitePhotosDialog extends StatefulWidget {
  const DeviceSitePhotosDialog({required this.controller, super.key});

  final LcdDeviceDetailController controller;

  @override
  State<DeviceSitePhotosDialog> createState() => _DeviceSitePhotosDialogState();
}

class _DeviceSitePhotosDialogState extends State<DeviceSitePhotosDialog> {
  static const double _gridGap = 16;
  static const int _maxColumns = 5;
  static const double _itemHeight = 270;
  static const double _cardBottomHeight = 64;
  static double get _thumbHeight => _itemHeight - _cardBottomHeight;

  var _adding = false;

  LcdDeviceDetailController get controller => widget.controller;

  Future<void> _addPhoto() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await controller.pickAndAddScenePic();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _confirmDeleteScenePic(LcdDeviceScenePicEntity photo) async {
    final path = photo.path?.trim();
    if (path == null || path.isEmpty) return;
    final name = photo.name?.trim();
    final label = name != null && name.isNotEmpty ? name : '现场照片';
    final confirmed = await showAppDeleteConfirmDialog(
      context,
      title: '删除照片',
      message: '确定要删除「$label」吗？此操作不可撤销。',
    );
    if (!confirmed || !mounted) return;
    await controller.deleteScenePic(path);
  }

  Future<void> _downloadPhoto(LcdDeviceScenePicEntity photo) async {
    final url = photo.url?.trim();
    final downloadUrl = (url != null && url.isNotEmpty)
        ? url
        : resolveLcdDeviceScenePicPreviewPath(photo);
    if (downloadUrl == null ||
        downloadUrl.isEmpty ||
        !downloadUrl.startsWith('http')) {
      showWarn('暂无下载地址');
      return;
    }
    try {
      final raw = await CommonApi.getRemoteBytes(downloadUrl);
      if (raw.isEmpty) {
        showWarn('文件为空');
        return;
      }
      final savedUri = await FilePicker.saveFile(
        dialogTitle: '保存文件',
        fileName: _downloadFileName(photo, downloadUrl),
        bytes: raw,
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );
      if (savedUri == null) return;
      showComplete('已保存');
    } catch (e) {
      showError('$e');
    }
  }

  String _downloadFileName(LcdDeviceScenePicEntity photo, String url) {
    final name = photo.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    final fromUrl = Uri.tryParse(url)?.pathSegments.lastOrNull?.trim() ?? '';
    if (fromUrl.isNotEmpty) return fromUrl;
    final fromPath = photo.path?.trim();
    if (fromPath != null && fromPath.isNotEmpty) return p.basename(fromPath);
    return isLcdDeviceScenePicVideo(photo) ? '现场视频' : '现场照片';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AppFormDialog(
      title: const Text('现场照片'),
      constraints: const BoxConstraints(maxWidth: 1080),
      trailing: AppButton.primary(
        color: const Color(0xFF00A0EC),
        leading: const Icon(AppLucideIcons.plus, size: 16),
        loading: _adding,
        // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
        onPressed: _adding
            ? null
            : () {
                unawaited(_addPhoto());
              },
        child: Text(_adding ? '上传中...' : '新增'),
      ),
      content: SizedBox(
        width: 1040,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Obx(() {
                  final photos = controller.scenePics;
                  if (photos.isEmpty) {
                    return const Center(child: AppEmptyState());
                  }
                  return FixedSizeGrid(
                    itemWidth: _thumbHeight,
                    itemHeight: _itemHeight,
                    spacing: _gridGap,
                    maxColumns: _maxColumns,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return SizedBox.expand(
                        child: AppCard(
                          borderWidth: 0,
                          padding: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppInkWell(
                                onDoubleTap: () => showLcdDeviceScenePicPreview(
                                  context: context,
                                  item: photo,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _PhotoPreview(photo: photo),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: MediaThumbDeleteButton(
                                          onPressed: _adding
                                              ? null
                                              : () => _confirmDeleteScenePic(
                                                  photo,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).expanded(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  10,
                                  10,
                                  12,
                                ),
                                child: Row(
                                  spacing: 8,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      spacing: 4,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText.label(
                                          photo.name ?? '现场照片',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        AppText.caption(
                                          photo.path ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ).expanded(),
                                    AppInkWell(
                                      onPressed: _adding
                                          ? null
                                          : () {
                                              unawaited(_downloadPhoto(photo));
                                            },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          AppLucideIcons.download,
                                          size: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final LcdDeviceScenePicEntity photo;

  @override
  Widget build(BuildContext context) {
    final isVideo = isLcdDeviceScenePicVideo(photo);
    final url = photo.url?.trim();
    final canPreview = resolveLcdDeviceScenePicPreviewPath(photo) != null;

    Widget preview;
    if (url != null && url.isNotEmpty) {
      preview = DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      );
    } else {
      preview = ColoredBox(
        color: const Color(0xFF64748B),
        child: Icon(
          isVideo ? AppLucideIcons.video : AppLucideIcons.image,
          size: 36,
          color: const Color(0x66FFFFFF),
        ).center(),
      );
    }

    if (isVideo && canPreview) {
      return Stack(
        fit: StackFit.expand,
        children: [
          preview,
          const Center(child: MediaThumbPlayOverlay()),
        ],
      );
    }

    return preview;
  }
}
