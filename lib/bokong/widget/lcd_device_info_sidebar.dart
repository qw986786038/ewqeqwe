import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_device_entity.dart';
import 'package:yidivination/bokong/entity/lcd/lcd_terminal_play_preview_entity.dart';
import 'package:yidivination/bokong/pages/preview/preview_image_view.dart';
import 'package:yidivination/bokong/pages/preview/program_material_preview.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/ad_file_info_sidebar.dart';
import 'package:yidivination/bokong/widget/change_device_icon_dialog.dart';
import 'package:yidivination/bokong/widget/change_sidebar_icon_dialog.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/office_card_icon.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

/// 设备管理 · 设备列表右侧栏：设备播放预览 / 设备信息 / 节目单信息 / 上刊率。
class LcdDeviceInfoSidebar extends StatelessWidget {
  const LcdDeviceInfoSidebar({
    this.device,
    this.playPreview,
    this.playPreviewLoading = false,
    this.onIconUpdated,
    this.width = 344,
    super.key,
  });

  final LcdDeviceEntity? device;

  /// 正在播放内容（ShowDoc 1515）；优先于设备本地预览图。
  final LcdTerminalPlayPreviewEntity? playPreview;

  final bool playPreviewLoading;

  final ValueChanged<String>? onIconUpdated;

  final double width;

  static const _cardRadius = 24.0;
  static const _previewFallbackAsset = 'assets/images/terminal_thumb_100.png';

  @override
  Widget build(BuildContext context) {
    final info = device?.device_info;
    final title = _sidebarDeviceTitle(device, info);
    final apiPath = playPreview?.material_path?.trim();
    final useApiPreview = apiPath != null && apiPath.isNotEmpty;
    final previewPath = useApiPreview ? apiPath : _sidebarPreviewPath(device);
    final programs =
        device?.program_list ?? const <LcdDeviceProgramListItemEntity>[];
    // final rate = device?.publish_rate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DeviceInfoCard(
                title: title,
                info: info,
                avatarIcon: device?.avatar_icon,
                deviceId: device?.id,
                building: device?.building,
                mediaAddress: device?.media_address,
                onIconUpdated: (result) {
                  if (result.title != null) device?.point_name = result.title;
                  onIconUpdated?.call(result.avatarIcon);
                },
              ),
              _DevicePreviewCard(
                previewPath: previewPath,
                mediaType: playPreview?.media_type,
                previewTitle: playPreview?.program_name,
                mediaWidth: playPreview?.screen_width,
                mediaHeight: playPreview?.screen_height,
                deviceNo: device?.device_no,
                useMediaPathPreview: useApiPreview,
                loading: playPreviewLoading,
              ),
              _DeviceScheduleCard(programs: programs),
              // 上刊率暂时隐藏
              // _DeviceUpRateCard(rate: rate),
            ],
          ).scroll().expanded(),
        ],
      ),
    ).width(width);
  }
}

String _sidebarDeviceTitle(
  LcdDeviceEntity? device,
  LcdDeviceInfoSummaryEntity? info,
) {
  final fromInfo = info?.device_name?.trim();
  if (fromInfo != null && fromInfo.isNotEmpty) return fromInfo;
  final point = device?.point_name?.trim();
  if (point != null && point.isNotEmpty) return point;
  final no = device?.device_no?.trim();
  if (no != null && no.isNotEmpty) return no;
  return '-';
}

String? _sidebarPreviewPath(LcdDeviceEntity? device) {
  if (device == null) return null;
  for (final raw in device.device_play_preview ?? const <String>[]) {
    final path = raw.trim();
    if (path.isNotEmpty) return path;
  }
  final scene = device.scene_pic?.trim();
  if (scene == null || scene.isEmpty) return null;
  for (final part in scene.split(',')) {
    final path = part.trim();
    if (path.isNotEmpty) return path;
  }
  return null;
}

String _dash(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '-';
  return text;
}

String _deviceSizeLabel(String? size) {
  final text = size?.trim();
  if (text == null || text.isEmpty) return '-';
  if (text.endsWith('寸')) return text;
  return '$text寸';
}

String _durationLabel(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '-';
  return double.tryParse(text) == null ? text : '$text小时';
}

/// `98寸` → [`98`, ` 寸`]；无数字前缀时整体作为数值。
List<String> _splitValueUnit(String value) {
  final m = RegExp(r'^([\d.]+)\s*(.+)$').firstMatch(value);
  if (m == null) return [value];
  return [m.group(1)!, ' ${m.group(2)!}'];
}

String? _resolveNetworkUrl(String raw) {
  try {
    final source = PreviewImageSource.parse(raw);
    return source.url;
  } catch (_) {
    return null;
  }
}

/// 卡片外壳：白色圆角卡 + 标题。
class _SidebarSectionCard extends StatelessWidget {
  const _SidebarSectionCard({
    required this.title,
    required this.child,
    this.titleTrailing,
  });

  final String title;
  final Widget child;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          children: [
            AppText.title(title, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            if (titleTrailing != null) titleTrailing!,
          ],
        ),
        child,
      ],
    );
  }
}

/// 设备播放预览（接口数据按素材库类型分流；无接口时回退本地预览图）。
class _DevicePreviewCard extends StatelessWidget {
  const _DevicePreviewCard({
    this.previewPath,
    this.mediaType,
    this.previewTitle,
    this.mediaWidth,
    this.mediaHeight,
    this.deviceNo,
    this.useMediaPathPreview = false,
    this.loading = false,
  });

  final String? previewPath;
  final int? mediaType;
  final String? previewTitle;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? deviceNo;
  final bool useMediaPathPreview;
  final bool loading;

  /// 内容宽高比：网页锁死 9:16；其它类型有素材尺寸则用之，否则铺满。
  double? get _contentAspect {
    final path = previewPath?.trim() ?? '';
    final type =
        mediaType ?? (path.isEmpty ? null : inferMediaTypeFromPath(path));
    if (isProgramMaterialWebPreview(type) || type == 6) {
      return 9 / 16;
    }
    final w = mediaWidth;
    final h = mediaHeight;
    if (w != null && h != null && w > 0 && h > 0) return w / h;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final path = previewPath?.trim();
    final hasPath = path != null && path.isNotEmpty;
    final networkUrl = !hasPath || useMediaPathPreview
        ? null
        : _resolveNetworkUrl(path);

    Widget previewChild;
    if (useMediaPathPreview && hasPath) {
      previewChild = buildMediaPathPreview(
        path: path,
        mediaType: mediaType,
        fitWebViewport: true,
        deviceNo: deviceNo,
      );
    } else if (networkUrl != null) {
      previewChild = ExtendedImage.network(
        networkUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.completed) {
            return null;
          }
          return Image.asset(
            LcdDeviceInfoSidebar._previewFallbackAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
          );
        },
      );
    } else {
      previewChild = Image.asset(
        LcdDeviceInfoSidebar._previewFallbackAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
      );
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(LcdDeviceInfoSidebar._cardRadius),
        child: AspectRatio(
          // 外框高度保持原先 16:9；内容自适应铺满，多余区域黑边。
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final aspect = _contentAspect;
                    if (aspect == null) {
                      return SizedBox.expand(child: previewChild);
                    }
                    var width = constraints.maxWidth;
                    var height = width / aspect;
                    if (height > constraints.maxHeight) {
                      height = constraints.maxHeight;
                      width = height * aspect;
                    }
                    return Center(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: previewChild,
                      ),
                    );
                  },
                ),
                if (loading)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AppIconButton(
                    icon: const Icon(
                      AppLucideIcons.expand,
                      size: 14,
                      color: Colors.white,
                    ),
                    tooltip: '放大预览',
                    variant: AppButtonVariant.ghost,
                    config: const AppButtonConfig(height: 24),
                    backgroundColor: const Color(0xB31F2937),
                    onPressed: !hasPath
                        ? null
                        : () {
                            if (useMediaPathPreview) {
                              showMediaPathPreviewDialog(
                                context: context,
                                path: path,
                                mediaType: mediaType,
                                title: previewTitle ?? '设备播放预览',
                                deviceNo: deviceNo,
                              );
                              return;
                            }
                            showImagePreviewDialog(
                              context: context,
                              imagePath: path,
                              title: '设备播放预览',
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

/// 设备信息：与楼栋侧栏同一套深色头 + 竖向统计。
class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({
    required this.title,
    this.info,
    this.avatarIcon,
    this.deviceId,
    this.building,
    this.mediaAddress,
    this.onIconUpdated,
  });

  final String title;
  final LcdDeviceInfoSummaryEntity? info;
  final String? avatarIcon;
  final int? deviceId;
  final String? building;
  final String? mediaAddress;
  final ValueChanged<ChangeSidebarIconResult>? onIconUpdated;

  Future<void> _changeIcon(BuildContext context) async {
    final id = deviceId;
    if (id == null) {
      showWarn('请先选择设备');
      return;
    }
    final result = await showChangeDeviceIconDialog(
      context,
      deviceId: id,
      title: title,
      currentAvatarIcon: avatarIcon,
    );
    if (result == null) return;
    if (result.title != null) info?.device_name = result.title;
    onIconUpdated?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final rows = <({String label, String value})>[
      (label: '设备尺寸', value: _deviceSizeLabel(info?.device_size)),
      (label: '在线总时长', value: _durationLabel(info?.online_duration)),
    ];
    final valueStyle = TextStyle(color: colors.foreground, fontWeight: FontWeight.bold);
    final accent = sidebarHeaderAccent(avatarIcon, templateBackground: true);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(LcdDeviceInfoSidebar._cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2129),
              borderRadius: BorderRadius.circular(
                LcdDeviceInfoSidebar._cardRadius,
              ),
            ),
            child: Row(
              spacing: 12,
              children: [
                SidebarAvatarIcon(
                  avatarIcon: withDefaultAvatar(avatarIcon),
                  size: 40,
                  iconSize: 24,
                  borderRadius: 16,
                  useTemplateBackground: true,
                ),
                AppText.body(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ).expanded(),
                AppButton.primary(
                  size: AppButtonSize.small,
                  config: const AppButtonConfig(height: 24),
                  color: const Color(0x1AFFFFFF),
                  onPressed: () => _changeIcon(context),
                  child: Text(
                    '更改',
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              spacing: 12,
              children: [
                Text(
                  _dash(building),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle.copyWith(fontSize: 20),
                ).expanded(),
                Text(
                  _dash(mediaAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          for (final row in rows) ...[
            const AppDivider.horizontal(indent: 32, endIndent: 32),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  AppText.caption(
                    row.label,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ).expanded(),
                  Text.rich(
                    TextSpan(
                      children: [
                        for (final (i, part) in _splitValueUnit(row.value).indexed)
                          TextSpan(text: part, style: TextStyle(fontSize: i == 0 ? 20 : 14)),
                      ],
                    ),
                    style: valueStyle,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 节目单信息（设计图红字「显示10条…」仅为标注，不进界面）。
class _DeviceScheduleCard extends StatefulWidget {
  const _DeviceScheduleCard({required this.programs});

  final List<LcdDeviceProgramListItemEntity> programs;

  @override
  State<_DeviceScheduleCard> createState() => _DeviceScheduleCardState();
}

class _DeviceScheduleCardState extends State<_DeviceScheduleCard> {
  static const _pageSize = 10;

  int _page = 0;

  @override
  void didUpdateWidget(covariant _DeviceScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.programs, widget.programs)) {
      final maxPage = _maxPage;
      if (_page > maxPage) _page = maxPage;
    }
  }

  int get _maxPage {
    final n = widget.programs.length;
    if (n <= 0) return 0;
    return ((n - 1) / _pageSize).floor();
  }

  List<LcdDeviceProgramListItemEntity> get _pageRows {
    final start = _page * _pageSize;
    if (start >= widget.programs.length) return const [];
    return widget.programs.skip(start).take(_pageSize).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final rows = _pageRows;
    final showPager = widget.programs.length > _pageSize;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 102,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x4D2393FB), Color(0x002393FB)],
                ),
              ),
            ),
          ),
          Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AppText.title(
                  '节目单信息（${widget.programs.length}）',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 32,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: AppText.caption(
                            '序号',
                            style: TextStyle(
                              color: colors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        AppText.caption(
                          '节目名称',
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ).expanded(),
                        SizedBox(
                          width: 64,
                          child: AppText.caption(
                            '行业类型',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.programs.isEmpty)
                    Container(
                      height: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AppText.caption(
                        '暂无节目单',
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                    )
                  else
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        height: 44,
                        alignment: Alignment.center,
                        color: i.isOdd ? const Color(0xFFF9FAFB) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: sidebarRankBadge(
                                  _page * _pageSize + i + 1,
                                ),
                              ),
                            ),
                            AppText.body(
                              _dash(rows[i].program_name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ).expanded(),
                            SizedBox(
                              width: 64,
                              child: AppText.body(
                                _dash(rows[i].industry),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
              if (showPager)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton.ghost(
                        onPressed: _page <= 0
                            ? null
                            : () => setState(() => _page -= 1),
                        child: const Text('上一页'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AppText.caption(
                          '${_page + 1}/${_maxPage + 1}',
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      ),
                      AppButton.ghost(
                        onPressed: _page >= _maxPage
                            ? null
                            : () => setState(() => _page += 1),
                        child: const Text('下一页'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 上刊率。
class _DeviceUpRateCard extends StatelessWidget {
  const _DeviceUpRateCard({this.rate});

  final LcdDevicePublishRateEntity? rate;

  static const _publishedColor = Color(0xFFF97316);
  static const _unpublishedColor = Color(0xFF6366F1);
  static const _donutBoxSize = 160.0;
  static const _donutHoleRadius = 44.0;
  static const _donutRingRadius = 30.0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadcnTheme.of(context);
    final published = rate?.published_count ?? 0;
    final unpublished = rate?.unpublished_count ?? 0;
    final total = published + unpublished;
    final hasPositive = total > 0;
    final rateText = () {
      final raw = rate?.rate?.trim();
      if (raw != null && raw.isNotEmpty) return raw;
      if (!hasPositive) return '0.00%';
      return '${(published / total * 100).toStringAsFixed(2)}%';
    }();

    return _SidebarSectionCard(
      title: '上刊率',
      child: Column(
        spacing: 16,
        children: [
          SizedBox.square(
            dimension: _donutBoxSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppPieChart.donut(
                  height: _donutBoxSize,
                  showLegend: false,
                  showValues: false,
                  interactive: false,
                  sections: [
                    if (!hasPositive)
                      const AppPieSection(
                        label: '-',
                        value: 1,
                        color: Color(0xFFE5E7EB),
                      )
                    else ...[
                      AppPieSection(
                        label: '已上刊',
                        value: published.toDouble(),
                        color: _publishedColor,
                      ),
                      AppPieSection(
                        label: '未上刊',
                        value: unpublished.toDouble(),
                        color: _unpublishedColor,
                      ),
                    ],
                  ],
                  dataBuilder: (chartData) => chartData.copyWith(
                    centerSpaceRadius: _donutHoleRadius,
                    centerSpaceColor: theme.colorScheme.background,
                    sections: [
                      for (final section in chartData.sections)
                        section.copyWith(radius: _donutRingRadius),
                    ],
                  ),
                ),
                // 覆盖默认「总计」：中心按设计展示上刊率百分比。
                IgnorePointer(
                  child: Container(
                    width: _donutHoleRadius * 2 - 4,
                    height: _donutHoleRadius * 2 - 4,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rateText,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: theme.typography.large.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '上刊率',
                          style: theme.typography.xSmall.copyWith(
                            color: theme.colorScheme.mutedForeground,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 设计图两侧引出次数；侧栏改用底部图例展示。
          Row(
            children: [
              _countLegend(
                color: _publishedColor,
                countText: '${published}次',
                label: '已上刊',
                muted: theme.colorScheme.mutedForeground,
              ).expanded(),
              _countLegend(
                color: _unpublishedColor,
                countText: '${unpublished}次',
                label: '未上刊',
                muted: theme.colorScheme.mutedForeground,
              ).expanded(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countLegend({
    required Color color,
    required String countText,
    required String label,
    required Color muted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              countText,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: muted, fontSize: 12, height: 1.3),
            ),
          ],
        ),
      ],
    );
  }
}
