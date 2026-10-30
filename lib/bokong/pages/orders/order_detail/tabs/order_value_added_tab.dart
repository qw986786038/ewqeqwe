import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show CheckboxState;
import 'package:lemon_x/lemon_x.dart';

import 'package:yidivination/bokong/entity/order/order_monitor_vas_entity.dart';
import 'package:yidivination/bokong/pages/lcd_devices/device_detail/device_detail_title_icon.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/media_thumb_overlay_badge.dart';
import 'package:yidivination/bokong/widget/message.dart';

import '../dialogs/order_vas_media_dialog.dart';
import '../order_detail_controller.dart';
import '../order_detail_insets.dart';

/// 本地素材项；[url] 为已上传公网地址，[path] 为本地路径。
class _VasMediaItem {
  _VasMediaItem({
    required this.path,
    this.url,
    this.isVideo = false,
    this.duration,
  });

  final String path;
  String? url;
  final bool isVideo;
  final String? duration;

  bool get isRemote =>
      (url != null && url!.isNotEmpty) ||
      path.startsWith('http://') ||
      path.startsWith('https://');

  String get displayPath => url?.isNotEmpty == true ? url! : path;
}

/// 自定义拍摄要求条目。
class _VasCustomRequirement {
  _VasCustomRequirement({this.name = ''});

  String name;
  String content = '';
  final List<_VasMediaItem> media = <_VasMediaItem>[];
}

/// 输出视频条目。
class _VasOutputVideo {
  int editSeconds = 15;
  String remark = '';
}

/// 增值服务 Tab：拍摄 / 输出 / 传播要求。
class OrderValueAddedTab extends StatefulWidget {
  const OrderValueAddedTab({required this.controller, super.key});

  final OrderDetailController controller;

  @override
  State<OrderValueAddedTab> createState() => _OrderValueAddedTabState();
}

class _OrderValueAddedTabState extends State<OrderValueAddedTab> {
  // —— 拍摄要求 ——
  var _droneOn = false;
  var _droneShotCount = 1080;
  final _droneMedia = <_VasMediaItem>[];

  var _timelapseOn = false;
  var _timelapseMinutes = 3;
  final _timelapseMedia = <_VasMediaItem>[];

  var _customOn = false;
  final _customItems = <_VasCustomRequirement>[_VasCustomRequirement()];

  // —— 输出要求（默认开启；最少 1 条，拍摄要求合计只算 1）——
  var _videoCount = 1;
  final _outputVideos = <_VasOutputVideo>[_VasOutputVideo()];
  final _outputMedia = <_VasMediaItem>[];

  // —— 传播要求 ——
  final _spreadPlatforms = <String>{};

  int _formRevision = 0;
  Worker? _releaseWorker;

  OrderDetailController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _releaseWorker = ever(_c.selectedReleaseKey, (_) {
      unawaited(_reload());
    });
    unawaited(_reload());
  }

  @override
  void dispose() {
    _releaseWorker?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await _c.loadMonitorVas();
    if (!mounted) return;
    _applyVas(_c.monitorVas.value);
  }

  void _applyVas(OrderMonitorVasEntity? vas) {
    setState(() {
      if (vas == null || vas.exists != true) {
        _resetVasForm();
        return;
      }

      final shooting = vas.shooting;
      _droneOn = shooting?.drone_enabled == 1;
      _droneShotCount = shooting?.drone_lens_count ?? 1080;
      _droneMedia
        ..clear()
        ..addAll(_mediaFromApi(shooting?.drone_media));

      _timelapseOn = shooting?.timelapse_enabled == 1;
      _timelapseMinutes = shooting?.timelapse_minutes ?? 3;
      _timelapseMedia
        ..clear()
        ..addAll(_mediaFromApi(shooting?.timelapse_media));

      final custom = vas.custom;
      _customOn = custom?.enabled == 1;
      final customItems = [...?custom?.items]
        ..sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
      _customItems
        ..clear()
        ..addAll([
          for (final item in customItems)
            _VasCustomRequirement(name: item.req_name?.trim() ?? '')
              ..content = item.req_content?.trim() ?? ''
              ..media.addAll(_mediaFromApi(item.media)),
        ]);
      if (_customItems.isEmpty) {
        _customItems.add(_VasCustomRequirement());
      }

      final output = vas.output;
      final outputItems = [...?output?.items]
        ..sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
      _outputVideos
        ..clear()
        ..addAll([
          for (final item in outputItems)
            _VasOutputVideo()
              ..editSeconds = item.edit_seconds ?? 15
              ..remark = item.remark ?? '',
        ]);
      _outputMedia
        ..clear()
        ..addAll(_mediaFromApi(output?.media));
      _videoCount = output?.count ?? _outputVideos.length;
      _syncOutputFromShooting();

      final publish = vas.publish;
      _spreadPlatforms
        ..clear()
        ..addAll([
          if (publish?.wechat_mp == 1) 'wechat_oa',
          if (publish?.wechat_channels == 1) 'wechat_channels',
          if (publish?.wechat_moments == 1) 'wechat_moments',
          if (publish?.toutiao == 1) 'toutiao',
          if (publish?.douyin == 1) 'douyin',
          if (publish?.website == 1) 'website',
          if (publish?.weibo == 1) 'weibo',
        ]);

      _formRevision++;
    });
  }

  void _resetVasForm() {
    _droneOn = false;
    _droneShotCount = 1080;
    _droneMedia.clear();
    _timelapseOn = false;
    _timelapseMinutes = 3;
    _timelapseMedia.clear();
    _customOn = false;
    _customItems
      ..clear()
      ..add(_VasCustomRequirement());
    _videoCount = 1;
    _outputVideos
      ..clear()
      ..add(_VasOutputVideo());
    _outputMedia.clear();
    _spreadPlatforms.clear();
    _formRevision++;
  }

  List<_VasMediaItem> _mediaFromApi(List<OrderMonitorVasMediaEntity>? list) {
    if (list == null || list.isEmpty) return const [];
    final sorted = [...list]
      ..sort((a, b) => (a.sort ?? 0).compareTo(b.sort ?? 0));
    return [
      for (final m in sorted)
        if ((m.url ?? '').trim().isNotEmpty)
          _VasMediaItem(
            path: m.url!.trim(),
            url: m.url!.trim(),
            isVideo: _isVideoMedia(m),
            duration: _formatDurationSec(m.duration_sec),
          ),
    ];
  }

  bool _isVideoMedia(OrderMonitorVasMediaEntity m) {
    final type = (m.file_type ?? '').toLowerCase();
    if (type.contains('video')) return true;
    if (type.contains('image')) return false;
    final url = (m.url ?? '').toLowerCase();
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        url.endsWith('.webm');
  }

  String? _formatDurationSec(int? sec) {
    if (sec == null || sec < 0) return null;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 输出视频最少条数（拍摄要求合计只算 1，下限恒为 1）。
  static const int _outputVideoMinCount = 1;

  Future<void> _pickMedia(List<_VasMediaItem> target) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'gif',
        'webp',
        'mp4',
        'mov',
        'avi',
      ],
    );
    if (!mounted || files.isEmpty) return;
    setState(() {
      for (final file in files) {
        final path = file.path?.trim();
        if (path == null || path.isEmpty) continue;
        final lower = path.toLowerCase();
        final isVideo =
            lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi');
        target.add(
          _VasMediaItem(
            path: path,
            isVideo: isVideo,
            duration: isVideo ? '00:30' : null,
          ),
        );
      }
    });
  }

  void _viewMedia(List<_VasMediaItem> media) {
    if (media.isEmpty) {
      showWarn('暂无素材');
      return;
    }
    showOrderVasMediaDialog(
      context,
      items: [
        for (final item in media)
          OrderVasMediaViewItem(
            displayPath: item.displayPath,
            isVideo: item.isVideo,
            duration: item.duration,
          ),
      ],
    );
  }

  void _syncOutputVideoCount(int count) {
    final next = count < _outputVideoMinCount ? _outputVideoMinCount : count;
    _videoCount = next;
    while (_outputVideos.length < next) {
      _outputVideos.add(_VasOutputVideo());
    }
    while (_outputVideos.length > next) {
      _outputVideos.removeLast();
    }
  }

  /// 拍摄要求变更后，保证输出条数不少于下限（最少 1 条）。
  void _syncOutputFromShooting() {
    _syncOutputVideoCount(_videoCount);
  }

  /// [AppNumberInput] 可能在 build 期回调 onChanged；避开同步 setState。
  void _setNumber(
    int Function() read,
    void Function(int value) write,
    int next,
  ) {
    if (read() == next) return;
    void apply() {
      if (!mounted || read() == next) return;
      setState(() => write(next));
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      apply();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    }
  }

  void _toggleSpread(String key, bool on) {
    setState(() {
      if (on) {
        _spreadPlatforms.add(key);
      } else {
        _spreadPlatforms.remove(key);
      }
    });
  }

  Future<void> _removeMedia(
    List<_VasMediaItem> list,
    _VasMediaItem item,
  ) async {
    setState(() => list.remove(item));
    await _save();
  }

  Future<void> _save() async {
    if (_c.vasSaving.value) return;
    final detailId = _c.selectedRelease?.id;
    if (detailId == null) {
      showWarn('请先选择发布单');
      return;
    }

    _c.vasSaving.value = true;
    try {
      final droneMedia = await _resolveMedia(_droneMedia);
      final timelapseMedia = await _resolveMedia(_timelapseMedia);
      final outputMedia = await _resolveMedia(_outputMedia);
      final customItems = <OrderMonitorVasCustomItemEntity>[];
      if (_customOn) {
        for (final item in _customItems) {
          customItems.add(
            OrderMonitorVasCustomItemEntity()
              ..req_name = item.name.trim()
              ..req_content = item.content.trim()
              ..media = await _resolveMedia(item.media),
          );
        }
      }

      final param = OrderMonitorVasSaveEntity()
        ..order_detail_id = detailId
        ..shooting = (OrderMonitorVasShootingEntity()
          ..drone_enabled = _droneOn ? 1 : 0
          ..drone_lens_count = _droneOn ? _droneShotCount : null
          ..drone_media = _droneOn ? droneMedia : const []
          ..timelapse_enabled = _timelapseOn ? 1 : 0
          ..timelapse_minutes = _timelapseOn ? _timelapseMinutes : null
          ..timelapse_media = _timelapseOn ? timelapseMedia : const [])
        ..custom = (OrderMonitorVasCustomEntity()
          ..enabled = _customOn ? 1 : 0
          ..items = _customOn ? customItems : const [])
        ..output = (OrderMonitorVasOutputEntity()
          ..enabled = 1
          ..count = _videoCount
          ..items = [
            for (final item in _outputVideos)
              OrderMonitorVasOutputItemEntity()
                ..edit_seconds = item.editSeconds
                ..remark = item.remark,
          ]
          ..media = outputMedia)
        ..publish = (OrderMonitorVasPublishEntity()
          ..wechat_mp = _spreadOn('wechat_oa')
          ..wechat_channels = _spreadOn('wechat_channels')
          ..wechat_moments = _spreadOn('wechat_moments')
          ..toutiao = _spreadOn('toutiao')
          ..douyin = _spreadOn('douyin')
          ..website = _spreadOn('website')
          ..weibo = _spreadOn('weibo'));

      await _c.saveMonitorVas(param);
      if (!mounted) return;
      _applyVas(_c.monitorVas.value);
    } catch (e) {
      if (mounted) showError('$e');
    } finally {
      _c.vasSaving.value = false;
    }
  }

  int _spreadOn(String key) => _spreadPlatforms.contains(key) ? 1 : 0;

  Future<List<OrderMonitorVasMediaEntity>> _resolveMedia(
    List<_VasMediaItem> items,
  ) async {
    final result = <OrderMonitorVasMediaEntity>[];
    for (final item in items) {
      var url = item.url?.trim();
      if (url == null || url.isEmpty) {
        if (item.path.startsWith('http://') ||
            item.path.startsWith('https://')) {
          url = item.path;
        } else {
          url = await _c.uploadVasMedia(item.path);
          item.url = url;
        }
      }
      result.add(
        OrderMonitorVasMediaEntity()
          ..url = url
          ..duration_sec = _durationSec(item.duration),
      );
    }
    return result;
  }

  int? _durationSec(String? duration) {
    if (duration == null || duration.isEmpty) return null;
    final parts = duration.split(':');
    if (parts.length != 2) return int.tryParse(duration);
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null || seconds == null) return null;
    return minutes * 60 + seconds;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return Column(
      spacing: 20,
      children: [
        Row(
          children: [
            _ValueAddedOrdersBar(controller: _c),
            const Spacer(),
            Obx(
              () => AppButton.primary(
                color: const Color(0xFF00A0EC),
                loading: _c.vasSaving.value,
                loadingLabel: '保存中…',
                // 外部已传 loading 时勿让 onPressed 返回 Future，否则 _running 不清理。
                onPressed: _c.vasSaving.value
                    ? null
                    : () {
                        unawaited(_save());
                      },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
        Obx(() {
          if (_c.vasLoading.value) {
            return const Center(
              child: AppCircularProgressIndicator(),
            ).expanded();
          }
          return Column(
            key: ValueKey('vas-form-$_formRevision'),
            spacing: 20,
            children: [
              // 拍摄要求
              AppCard(
                borderRadius: BorderRadius.circular(24),
                borderWidth: 0,
                child: AppDescriptions.custom(
                  title: const Text('拍摄要求'),
                  titleIcon: deviceDetailTitleIcon(
                    context,
                    AppLucideIcons.camera,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      // 无人机 / 延时：各一张高 130、#F7F8FA 卡片，间距 8，内容垂直居中
                      Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            constraints: const BoxConstraints(minHeight: 130),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppCheckbox(
                                  state: _droneOn
                                      ? CheckboxState.checked
                                      : CheckboxState.unchecked,
                                  trailing: const Text('无人机航拍'),
                                  onChanged: (state) => setState(() {
                                    _droneOn = state == CheckboxState.checked;
                                    _syncOutputFromShooting();
                                  }),
                                ),
                                AppText.body(
                                  '镜头数量',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                AppNumberInput(
                                  value: _droneShotCount,
                                  min: 1,
                                  max: 9999,
                                  width: 120,
                                  onChanged: (v) => _setNumber(
                                    () => _droneShotCount,
                                    (n) => _droneShotCount = n,
                                    v,
                                  ),
                                ),
                                _VasMediaRow(
                                  label: '原始照片/视频素材',
                                  media: _droneMedia,
                                  placeholderAsset:
                                      'assets/images/vas/media_placeholder_drone.png',
                                  placeholderSize: const Size(72, 72),
                                  onUpload: () => _pickMedia(_droneMedia),
                                  onView: () => _viewMedia(_droneMedia),
                                  onDeleteItem: (item) =>
                                      _removeMedia(_droneMedia, item),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minHeight: 130),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppCheckbox(
                                  state: _timelapseOn
                                      ? CheckboxState.checked
                                      : CheckboxState.unchecked,
                                  trailing: const Text('延时拍摄'),
                                  onChanged: (state) => setState(() {
                                    _timelapseOn =
                                        state == CheckboxState.checked;
                                    _syncOutputFromShooting();
                                  }),
                                ),
                                AppText.body(
                                  '时长要求',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                AppNumberInput(
                                  value: _timelapseMinutes,
                                  min: 1,
                                  max: 120,
                                  width: 100,
                                  onChanged: (v) => _setNumber(
                                    () => _timelapseMinutes,
                                    (n) => _timelapseMinutes = n,
                                    v,
                                  ),
                                ),
                                AppText.caption(
                                  '分钟',
                                  style: TextStyle(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                _VasMediaRow(
                                  media: _timelapseMedia,
                                  placeholderAsset:
                                      'assets/images/vas/media_placeholder_timelapse.png',
                                  placeholderSize: const Size(165, 72),
                                  onUpload: () => _pickMedia(_timelapseMedia),
                                  onView: () => _viewMedia(_timelapseMedia),
                                  onDeleteItem: (item) =>
                                      _removeMedia(_timelapseMedia, item),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // 自定义要求：左边距 16，与无人机 / 延时勾选左对齐
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                AppCheckbox(
                                  state: _customOn
                                      ? CheckboxState.checked
                                      : CheckboxState.unchecked,
                                  trailing: const Text('自定义要求'),
                                  onChanged: (state) => setState(() {
                                    _customOn = state == CheckboxState.checked;
                                    _syncOutputFromShooting();
                                  }),
                                ),
                                const Spacer(),
                                AppButton.outline(
                                  size: AppButtonSize.small,
                                  config: const AppButtonConfig(height: 28),
                                  leading: const Icon(
                                    AppLucideIcons.plus,
                                    size: 14,
                                  ),
                                  onPressed: () => setState(() {
                                    _customItems.add(_VasCustomRequirement());
                                    _syncOutputFromShooting();
                                  }),
                                  child: const Text('添加要求'),
                                ),
                              ],
                            ),
                          ),
                          for (var i = 0; i < _customItems.length; i++)
                            _VasCustomRequirementCard(
                              index: i,
                              item: _customItems[i],
                              onChanged: () => setState(() {}),
                              onUpload: () => _pickMedia(_customItems[i].media),
                              onView: () => _viewMedia(_customItems[i].media),
                              onDeleteMedia: (item) =>
                                  _removeMedia(_customItems[i].media, item),
                              onDelete: _customItems.length <= 1
                                  ? null
                                  : () => setState(() {
                                      _customItems.removeAt(i);
                                      _syncOutputFromShooting();
                                    }),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 输出要求
              AppCard(
                borderRadius: BorderRadius.circular(24),
                borderWidth: 0,
                child: AppDescriptions.custom(
                  title: const Text('输出要求'),
                  titleIcon: deviceDetailTitleIcon(
                    context,
                    AppLucideIcons.fileText,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          const AppText.body('视频'),
                          AppText.body(
                            '数量(多条)',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                          AppNumberInput(
                            value: _videoCount,
                            min: _outputVideoMinCount,
                            max: 20,
                            width: 100,
                            onChanged: (v) => _setNumber(
                              () => _videoCount,
                              _syncOutputVideoCount,
                              v,
                            ),
                          ),
                          AppText.caption(
                            '条',
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        ],
                      ),
                      for (var i = 0; i < _outputVideos.length; i++)
                        Container(
                          height: 88,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            spacing: 12,
                            children: [
                              SizedBox(
                                width: 56,
                                child: AppText.body('视频${i + 1}'),
                              ),
                              AppText.body(
                                '剪辑时长',
                                style: TextStyle(color: colors.mutedForeground),
                              ),
                              AppNumberInput(
                                value: _outputVideos[i].editSeconds,
                                min: 1,
                                max: 3600,
                                width: 100,
                                onChanged: (v) => _setNumber(
                                  () => _outputVideos[i].editSeconds,
                                  (n) => _outputVideos[i].editSeconds = n,
                                  v,
                                ),
                              ),
                              AppText.caption(
                                '秒',
                                style: TextStyle(color: colors.mutedForeground),
                              ),
                              AppText.body(
                                '备注说明',
                                style: TextStyle(color: colors.mutedForeground),
                              ),
                              AppTextFormField(
                                hintText: '请输入内容',
                                initialValue: _outputVideos[i].remark,
                                onChanged: (v) => _outputVideos[i].remark = v,
                              ).expanded(),
                              if (_outputVideos.length > _outputVideoMinCount)
                                AppIconButton(
                                  icon: Icon(
                                    AppLucideIcons.minus,
                                    size: 14,
                                    color: colors.destructive,
                                  ),
                                  tooltip: '删除',
                                  size: AppButtonSize.small,
                                  variant: AppButtonVariant.outline,
                                  onPressed: () => setState(() {
                                    _outputVideos.removeAt(i);
                                    _syncOutputVideoCount(_outputVideos.length);
                                  }),
                                ),
                            ],
                          ),
                        ),
                      _VasMediaRow(
                        label: '输出成品视频',
                        media: _outputMedia,
                        placeholderAsset:
                            'assets/images/vas/media_placeholder_output.png',
                        placeholderSize: const Size(112, 72),
                        onUpload: () => _pickMedia(_outputMedia),
                        onView: () => _viewMedia(_outputMedia),
                        onDeleteItem: (item) =>
                            _removeMedia(_outputMedia, item),
                      ),
                    ],
                  ),
                ),
              ),

              // 传播要求
              AppCard(
                borderRadius: BorderRadius.circular(24),
                borderWidth: 0,
                child: AppDescriptions.custom(
                  title: const Text('传播要求'),
                  titleIcon: deviceDetailTitleIcon(
                    context,
                    AppLucideIcons.share2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      _VasPlatformGroup(
                        title: '微信平台',
                        iconAsset: 'assets/images/vas/platform_wechat.png',
                        children: [
                          AppCheckbox(
                            state: _spreadPlatforms.contains('wechat_oa')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('公众号/订阅号'),
                            onChanged: (s) => _toggleSpread(
                              'wechat_oa',
                              s == CheckboxState.checked,
                            ),
                          ),
                          AppCheckbox(
                            state: _spreadPlatforms.contains('wechat_channels')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('视频号'),
                            onChanged: (s) => _toggleSpread(
                              'wechat_channels',
                              s == CheckboxState.checked,
                            ),
                          ),
                          AppCheckbox(
                            state: _spreadPlatforms.contains('wechat_moments')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('朋友圈'),
                            onChanged: (s) => _toggleSpread(
                              'wechat_moments',
                              s == CheckboxState.checked,
                            ),
                          ),
                        ],
                      ),
                      _VasPlatformGroup(
                        title: '字节平台',
                        iconAsset: 'assets/images/vas/platform_bytedance.png',
                        children: [
                          AppCheckbox(
                            state: _spreadPlatforms.contains('toutiao')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('头条'),
                            onChanged: (s) => _toggleSpread(
                              'toutiao',
                              s == CheckboxState.checked,
                            ),
                          ),
                          AppCheckbox(
                            state: _spreadPlatforms.contains('douyin')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('抖音'),
                            onChanged: (s) => _toggleSpread(
                              'douyin',
                              s == CheckboxState.checked,
                            ),
                          ),
                        ],
                      ),
                      _VasPlatformGroup(
                        title: '其他平台',
                        iconAsset: 'assets/images/vas/platform_other.png',
                        children: [
                          AppCheckbox(
                            state: _spreadPlatforms.contains('website')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('网站'),
                            onChanged: (s) => _toggleSpread(
                              'website',
                              s == CheckboxState.checked,
                            ),
                          ),
                          AppCheckbox(
                            state: _spreadPlatforms.contains('weibo')
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            trailing: const Text('微博'),
                            onChanged: (s) => _toggleSpread(
                              'weibo',
                              s == CheckboxState.checked,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).scroll(padding: kOrderDetailPagePadding).expanded();
        }),
      ],
    );
  }
}

/// 订单子 Tab：与监测反馈一致，联动 [OrderDetailController.selectedRelease]。
class _ValueAddedOrdersBar extends StatelessWidget {
  const _ValueAddedOrdersBar({required this.controller});

  final OrderDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.releaseRevision.value;
      final materials = controller.releaseItems;
      if (materials.isEmpty) return const SizedBox.shrink();

      final selectedKey = controller.selectedReleaseKey.value;
      var selectedIndex = 0;
      for (var i = 0; i < materials.length; i++) {
        if (controller.releaseRowKey(materials[i]) == selectedKey) {
          selectedIndex = i;
          break;
        }
      }

      return Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: AppTabs(
            index: selectedIndex,
            onChanged: (index) {
              if (index < 0 || index >= materials.length) return;
              controller.selectRelease(materials[index]);
            },
            selectedColor: const Color(0xFFFFFFFF),
            children: [
              for (var i = 0; i < materials.length; i++)
                AppTabItem(child: Text('订单${i + 1}')),
            ],
          ),
        ),
      );
    });
  }
}

/// 素材缩略图 + 上传 / 查看（横向一行，可嵌进条件 Wrap）。
class _VasMediaRow extends StatelessWidget {
  const _VasMediaRow({
    required this.media,
    required this.onUpload,
    required this.onView,
    this.onDeleteItem,
    this.label,
    this.placeholderAsset,
    this.placeholderSize = const Size(72, 72),
  });

  final String? label;
  final List<_VasMediaItem> media;
  final VoidCallback onUpload;
  final VoidCallback onView;
  final ValueChanged<_VasMediaItem>? onDeleteItem;

  /// 无素材时展示的占位图（无人机 / 延时 / 输出成品各一张）。
  final String? placeholderAsset;
  final Size placeholderSize;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null)
          AppText.body(label!, style: TextStyle(color: colors.mutedForeground)),
        if (media.isEmpty && placeholderAsset != null)
          Image.asset(
            placeholderAsset!,
            width: placeholderSize.width,
            height: placeholderSize.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        else
          for (final item in media)
            _VasMediaThumb(
              item: item,
              onDelete: onDeleteItem == null ? null : () => onDeleteItem!(item),
            ),
        AppButton.outline(
          size: AppButtonSize.small,
          config: const AppButtonConfig(height: 28),
          leading: const Icon(AppLucideIcons.upload, size: 14),
          onPressed: onUpload,
          child: const Text('上传素材'),
        ),
        AppButton.outline(
          size: AppButtonSize.small,
          config: const AppButtonConfig(height: 28),
          leading: const Icon(AppLucideIcons.cloud, size: 14),
          onPressed: onView,
          child: const Text('查看素材'),
        ),
      ],
    );
  }
}

class _VasMediaThumb extends StatelessWidget {
  const _VasMediaThumb({required this.item, this.onDelete});

  final _VasMediaItem item;
  final VoidCallback? onDelete;

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final remote = item.isRemote ? item.displayPath : null;
    final file = remote == null ? File(item.path) : null;
    final exists = file?.existsSync() == true;

    final thumb = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!item.isVideo && remote != null)
            ExtendedImage.network(
              remote,
              fit: BoxFit.cover,
              loadStateChanged: (state) {
                if (state.extendedImageLoadState == LoadState.completed) {
                  return null;
                }
                return Icon(
                  AppLucideIcons.image,
                  size: 20,
                  color: colors.mutedForeground,
                );
              },
            )
          else if (exists && !item.isVideo)
            ExtendedImage(
              image: FileImage(file!),
              fit: BoxFit.cover,
              loadStateChanged: (state) {
                if (state.extendedImageLoadState == LoadState.completed) {
                  return null;
                }
                return Icon(
                  AppLucideIcons.image,
                  size: 20,
                  color: colors.mutedForeground,
                );
              },
            )
          else
            ColoredBox(
              color: const Color(0xFFE2E8F0),
              child: Icon(
                item.isVideo ? AppLucideIcons.play : AppLucideIcons.image,
                size: 22,
                color: colors.mutedForeground,
              ),
            ),
          if (item.isVideo) const Center(child: MediaThumbPlayOverlay()),
          if (item.duration != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.duration!,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onDelete == null) return thumb;

    return AppCornerBadge(
      position: AppCornerBadgePosition.topRight,
      ignorePointer: false,
      badge: MediaThumbRemoveBadge(tooltip: '删除', onPressed: onDelete),
      child: thumb,
    );
  }
}

/// 自定义要求卡片：横向一行（名称 / 内容 / 素材 / 删除）。
class _VasCustomRequirementCard extends StatelessWidget {
  const _VasCustomRequirementCard({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onUpload,
    required this.onView,
    this.onDeleteMedia,
    this.onDelete,
  });

  final int index;
  final _VasCustomRequirement item;
  final VoidCallback onChanged;
  final VoidCallback onUpload;
  final VoidCallback onView;
  final ValueChanged<_VasMediaItem>? onDeleteMedia;
  final VoidCallback? onDelete;

  static String zhIndex(int n) {
    const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    if (n >= 1 && n <= 10) return digits[n];
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppBadge.custom(
            color: colors.primary,
            appearance: AppBadgeStyle.soft,
            shape: AppBadgeShape.square,
            size: AppBadgeSize.large.copyWith(height: 16),
            child: Text('要求${zhIndex(index + 1)}'),
          ),
          AppText.body('要求名称', style: TextStyle(color: colors.mutedForeground)),
          SizedBox(
            width: 160,
            child: AppTextFormField(
              hintText: '请输入内容',
              initialValue: item.name,
              onChanged: (v) {
                item.name = v;
                onChanged();
              },
            ),
          ),
          AppText.body('要求内容', style: TextStyle(color: colors.mutedForeground)),
          SizedBox(
            width: 280,
            child: AppTextFormField(
              hintText: '请输入内容',
              initialValue: item.content,
              onChanged: (v) {
                item.content = v;
                onChanged();
              },
            ),
          ),
          _VasMediaRow(
            media: item.media,
            placeholderAsset: 'assets/images/vas/media_placeholder_drone.png',
            placeholderSize: const Size(72, 72),
            onUpload: onUpload,
            onView: onView,
            onDeleteItem: onDeleteMedia,
          ),
          if (onDelete != null)
            AppIconButton(
              icon: Icon(
                AppLucideIcons.minus,
                size: 14,
                color: colors.destructive,
              ),
              tooltip: '删除',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outline,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// 传播平台分组行。
class _VasPlatformGroup extends StatelessWidget {
  const _VasPlatformGroup({
    required this.title,
    required this.iconAsset,
    required this.children,
  });

  final String title;
  final String iconAsset;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 16,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            iconAsset,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 72, child: AppText.body(title)),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ).expanded(),
      ],
    );
  }
}
