import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:yidivination/bokong/entity/lcd/ad_file_list_entity.dart';
import 'package:yidivination/bokong/theme/theme.dart';
import 'package:yidivination/bokong/utils/widget_size.dart';
import 'package:yidivination/bokong/widget/change_office_icon_dialog.dart';
import 'package:yidivination/bokong/widget/change_sidebar_icon_dialog.dart';
import 'package:yidivination/bokong/widget/message.dart';
import 'package:yidivination/bokong/widget/office_card_icon.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

/// 客户订单侧栏：98 / 86 / 其他尺寸卡片图标。
const _kOrderSizeFileIconAsset = 'assets/images/order_size_file_icon.svg';

/// 客户订单侧栏：播放量卡片图标。
const _kOrderPlayCameraIconAsset = 'assets/images/order_play_camera_icon.svg';

/// 客户订单侧栏：订单总量卡片图标。
const _kOrderTotalDeviceIconAsset = 'assets/images/order_total_device_icon.svg';

/// 设备管理 / 客户订单共用的「文件信息」侧边栏（file_list + 添加标签）。
enum AdFileInfoSidebarKind {
  /// 物业 type=1
  property,

  /// 客户 type=2
  customer,
}

class AdFileInfoSidebar extends StatelessWidget {
  const AdFileInfoSidebar({
    required this.file,
    required this.loading,
    required this.title,
    required this.total,
    required this.size98,
    required this.size86,
    required this.online,
    required this.offline,
    required this.abnormal,
    required this.onAddTag,
    this.onDeleteTag,
    this.kind = AdFileInfoSidebarKind.property,
    this.iconUpdateType,
    this.iconUpdateId,
    this.avatarIcon,
    this.address,
    this.onIconUpdated,
    this.onTitleUpdated,
    this.width = 344,
    this.showCard = true,
    super.key,
  });

  final AdFileListEntity? file;
  final bool loading;
  final String title;
  final int total;
  final int size98;
  final int size86;
  final int online;
  final int offline;
  final int abnormal;
  final Future<bool> Function(String tag) onAddTag;

  /// 删除标签（悬停角标）。
  final Future<bool> Function(String tag)? onDeleteTag;
  final AdFileInfoSidebarKind kind;

  /// ShowDoc 1514：1 客户 / 2 写字楼。
  final int? iconUpdateType;
  final int? iconUpdateId;
  final String? avatarIcon;

  /// 物业概览卡地址行（如「济南市-历下区-xx路」）。
  final String? address;
  final ValueChanged<String>? onIconUpdated;

  /// 楼栋弹窗改名后回调（先于 [onIconUpdated]）。
  final ValueChanged<String>? onTitleUpdated;
  final double width;

  /// 嵌在页面已有卡片内时去掉外壳，避免叠卡。
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final isCustomer = kind == AdFileInfoSidebarKind.customer;
    final tags = parseAdFileListTags(
      isCustomer ? (file?.add_tag ?? file?.tags) : file?.tags,
    );
    final distribution = file?.order_distribution;

    Future<void> changeIcon() async {
      final type = iconUpdateType;
      final id = iconUpdateId;
      if (type == null || id == null) {
        showWarn('请先选择客户或写字楼');
        return;
      }
      final result = type == SidebarAvatarIconType.office
          ? await showChangeOfficeIconDialog(
              context,
              officeId: id,
              title: title,
              currentAvatarIcon: avatarIcon ?? file?.avatar_icon,
              deviceCount: total,
            )
          : await showChangeSidebarIconDialog(
              context,
              iconType: type,
              updateId: id,
              currentAvatarIcon: avatarIcon ?? file?.avatar_icon,
            );
      if (result == null) return;
      if (result.title != null) onTitleUpdated?.call(result.title!);
      onIconUpdated?.call(result.avatarIcon);
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (showCard)
          Row(
            spacing: 8,
            children: [
              const AppText.h3('文件信息', style: TextStyle(fontSize: 16)),
              AppButton.link(
                size: AppButtonSize.small,
                onPressed: changeIcon,
                child: const Text('更改'),
              ),
            ],
          ),
        if (loading && file == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: AppCircularProgressIndicator(),
            ),
          ).expanded()
        else
          Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCustomer)
                _SidebarCustomerSummaryCard(
                  title: title,
                  avatarIcon: avatarIcon ?? file?.avatar_icon,
                  totalOrders: file?.device_basic_data?.total_orders ?? 0,
                  playOrders: file?.device_basic_data?.play_orders ?? 0,
                  endOrders: file?.device_basic_data?.end_orders ?? 0,
                  onChangeIcon: showCard ? null : changeIcon,
                )
              else
                _SidebarPropertySummaryCard(
                  title: title,
                  avatarIcon: avatarIcon ?? file?.avatar_icon,
                  address: address,
                  total: total,
                  online: online,
                  offline: offline,
                  abnormal: abnormal,
                  onChangeIcon: showCard ? null : changeIcon,
                ),
                if (isCustomer) ...[
                  _SidebarRankingTop3Card(
                    title: '客户订单排名TOP3',
                    nameHeader: '客户名称',
                    valueHeader: '订单数',
                    rows: [
                      for (final row
                          in file?.customer_order_ranking_top3 ?? const [])
                        (
                          rank: row.rank ?? 0,
                          name: row.customer_name?.trim().isNotEmpty == true
                              ? row.customer_name!.trim()
                              : '-',
                          value: '${row.order_count ?? 0}',
                        ),
                    ],
                  ),
                  _SidebarRankingTop3Card(
                    title: '行业排名TOP3',
                    nameHeader: '行业名称',
                    valueHeader: '订单数',
                    gradientColors: const [
                      Color(0x4D6023FB), // 6023FB @ 30%
                      Color(0xFFFFFFFF),
                      Color(0xFFFFFFFF),
                    ],
                    rows: [
                      for (final row in file?.industry_ranking_top3 ?? const [])
                        (
                          rank: row.rank ?? 0,
                          name: row.industry_name?.trim().isNotEmpty == true
                              ? row.industry_name!.trim()
                              : '-',
                          value: '${row.order_count ?? 0}',
                        ),
                    ],
                  ),
                ],
                // 设备管理 · 上刊率排名暂时隐藏
                // ] else
                //   _SidebarRankingTop3Card(
                //     title: '上刊率排名TOP3',
                //     nameHeader: '媒体位置',
                //     valueHeader: '百分率',
                //     rows: [
                //       for (final row in file?.advertising_rate_top3 ?? const [])
                //         (
                //           rank: row.rank ?? 0,
                //           name: row.media_location?.trim().isNotEmpty == true
                //               ? row.media_location!.trim()
                //               : '-',
                //           value: row.rate?.trim().isNotEmpty == true
                //               ? row.rate!.trim()
                //               : '-',
                //         ),
                //     ],
                //   ),
                SidebarFileTagsCard(
                  tags: tags,
                  onAddTag: onAddTag,
                  onDeleteTag: onDeleteTag,
                ),
                // 设备管理 · 设备占比暂时隐藏，恢复时去掉 if (isCustomer)
                if (isCustomer)
                _SidebarDeviceShareCard(
                  title: isCustomer ? '订单分布' : '设备占比',
                  defaultCenterLabel: isCustomer ? '订单总量' : '设备总量',
                  softIcon: true,
                  chart: isCustomer ? distribution?.chart : file?.chart,
                  cards: isCustomer
                      ? (distribution?.cards ?? const [])
                      : (file?.cards ?? const []),
                ),
              ],
            ).scroll().expanded(),
      ],
    );

    if (!showCard) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: body,
      ).width(width);
    }
    return AppCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: body,
    ).width(width);
  }
}

class _SidebarPropertySummaryCard extends StatelessWidget {
  const _SidebarPropertySummaryCard({
    required this.title,
    this.avatarIcon,
    this.address,
    required this.total,
    required this.online,
    required this.offline,
    required this.abnormal,
    this.onChangeIcon,
  });

  final String title;
  final String? avatarIcon;
  final String? address;
  final int total;
  final int online;
  final int offline;
  final int abnormal;
  final VoidCallback? onChangeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: colors.mutedForeground,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    const valueStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    final addressText = address?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarSummaryHeader(
            title: title,
            avatarIcon: avatarIcon,
            onChangeIcon: onChangeIcon,
            useTemplateBackground: true,
            iconSize: 24,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (addressText.isNotEmpty) ...[
                  Text(addressText, style: labelStyle),
                  const AppDivider.horizontal(height: 40),
                ],
                Row(
                  children: [
                    Text('设备总量', style: labelStyle).expanded(),
                    Text('$total', style: valueStyle),
                  ],
                ),
                const AppDivider.horizontal(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('在线', style: labelStyle),
                        Text('$online', style: valueStyle),
                      ],
                    ),
                    Row(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('离线', style: labelStyle),
                        Text('$offline', style: valueStyle),
                      ],
                    ),
                    Row(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('异常', style: labelStyle),
                        Text('$abnormal', style: valueStyle),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 客户侧栏顶部：订单数量 + 执行中 / 已完播。
class _SidebarCustomerSummaryCard extends StatelessWidget {
  const _SidebarCustomerSummaryCard({
    required this.title,
    this.avatarIcon,
    required this.totalOrders,
    required this.playOrders,
    required this.endOrders,
    this.onChangeIcon,
  });

  final String title;
  final String? avatarIcon;
  final int totalOrders;
  final int playOrders;
  final int endOrders;
  final VoidCallback? onChangeIcon;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (label: '订单数量', value: '$totalOrders'),
      (label: '执行中', value: '$playOrders'),
      (label: '已完播', value: '$endOrders'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarSummaryHeader(
            title: title,
            avatarIcon: avatarIcon,
            onChangeIcon: onChangeIcon,
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const AppDivider.horizontal(indent: 32, endIndent: 32),
            _SidebarStatRow(
              label: rows[i].label,
              value: rows[i].value,
              filled: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarSummaryHeader extends StatelessWidget {
  const _SidebarSummaryHeader({
    required this.title,
    this.avatarIcon,
    this.onChangeIcon,
    this.useTemplateBackground = false,
    this.iconSize = 16,
  });

  final String title;
  final String? avatarIcon;
  final VoidCallback? onChangeIcon;
  final bool useTemplateBackground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final effectiveAvatar = useTemplateBackground ? withDefaultAvatar(avatarIcon) : avatarIcon;
    final accent = sidebarHeaderAccent(effectiveAvatar, templateBackground: useTemplateBackground);
    return Container(
      height: 80,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2129),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        spacing: 12,
        children: [
          // 与楼栋列表 item 同一套图标（灰底 / 资源）；圆角保持组件默认。
          SidebarAvatarIcon(
            avatarIcon: effectiveAvatar,
            size: 40,
            iconSize: iconSize,
            fallbackAsset: 'assets/images/folder_icon.png',
            useTemplateBackground: useTemplateBackground,
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
          if (onChangeIcon != null)
            AppButton.primary(
              size: AppButtonSize.small,
              config: const AppButtonConfig(height: 24),
              color: const Color(0x1AFFFFFF),
              onPressed: onChangeIcon,
              child: Text(
                '更改',
                style: TextStyle(color: accent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

/// 左标签右数值的通栏统计格（客户「订单数量」）。
class _SidebarStatRow extends StatelessWidget {
  const _SidebarStatRow({
    required this.label,
    required this.value,
    this.filled = true,
  });

  final String label;
  final String value;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    return Container(
      height: filled ? 56 : 48,
      padding: EdgeInsets.symmetric(horizontal: filled ? 30 : 32),
      decoration: filled
          ? BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: Row(
        children: [
          AppText.caption(
            label,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: filled ? 12 : 14,
              fontWeight: filled ? null : FontWeight.bold,
            ),
          ).expanded(),
          AppText.title(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: filled ? 16 : 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// 排名 TOP3（物业上刊率 / 客户订单 / 行业等）。
class _SidebarRankingTop3Card extends StatelessWidget {
  const _SidebarRankingTop3Card({
    required this.title,
    required this.nameHeader,
    required this.valueHeader,
    required this.rows,
    this.gradientColors,
    this.gradientStops,
  });

  final String title;
  final String nameHeader;
  final String valueHeader;
  final List<({int rank, String name, String value})> rows;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  /// 固定展示 3 行；不足用 `-` 占位。
  List<({int rank, String name, String value})> get _displayRows {
    final list = <({int rank, String name, String value})>[
      for (final row in rows.take(3)) row,
    ];
    while (list.length < 3) {
      list.add((rank: list.length + 1, name: '-', value: '-'));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final gradient =
        gradientColors ??
        [
          kBrandPrimary.withValues(alpha: 0.3),
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
        ];
    final stops = gradientStops ?? const [0.0, 0.5, 1.0];
    final displayRows = _displayRows;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
          stops: stops,
        ),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.title(title, style: const TextStyle(fontSize: 14)),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: AppText.caption(
                    '序号',
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                ),
                AppText.caption(
                  nameHeader,
                  style: TextStyle(color: colors.mutedForeground),
                ).expanded(),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppText.caption(
                      valueHeader,
                      style: TextStyle(color: colors.mutedForeground),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final row in displayRows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: sidebarRankBadge(row.rank),
                    ),
                  ),
                  AppText.body(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).expanded(),
                  SizedBox(
                    width: 56,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppText.body(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 与数据分析页 `_rankBadge` 同款（待上游 `AppRankBadge`）。
Widget sidebarRankBadge(int rank) {
  final (Color background, Color foreground) = switch (rank) {
    1 => (const Color(0xFFF5C518), const Color(0xFFFFFFFF)),
    2 => (const Color(0xFFB8C4D4), const Color(0xFF334155)),
    3 => (const Color(0xFFE8B48A), const Color(0xFF5C3D2E)),
    _ => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
  };

  return Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
      boxShadow: rank <= 3
          ? [
              BoxShadow(
                color: background.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    ),
    child: Text(
      '$rank',
      style: TextStyle(
        color: foreground,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    ),
  );
}

/// 标签区：已选标签 + 输入添加；删除角标悬停显示。
///
/// 设备 / 客户 / 订单侧栏共用。
class SidebarFileTagsCard extends StatefulWidget {
  const SidebarFileTagsCard({
    required this.tags,
    required this.onAddTag,
    this.onDeleteTag,
    super.key,
  });

  final List<AdFileListTagEntity> tags;
  final Future<bool> Function(String tag) onAddTag;
  final Future<bool> Function(String tag)? onDeleteTag;

  @override
  State<SidebarFileTagsCard> createState() => _SidebarFileTagsCardState();
}

class _SidebarFileTagsCardState extends State<SidebarFileTagsCard> {
  static const _tagPalette = [
    Color(0xFFF97316), // 橙
    Color(0xFF22C55E), // 绿
    Color(0xFF38BDF8), // 天蓝
    Color(0xFFEC4899), // 粉
    Color(0xFF8B5CF6), // 紫
    Color(0xFFEF4444), // 红
    Color(0xFFEAB308), // 黄
    Color(0xFF14B8A6), // 青
  ];

  /// 总高 24 = 内容 20 + 上下 padding 2。
  static const _tagSize = AppBadgeSize(
    fontSize: 12,
    height: 20,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    iconSize: 12,
    contentGap: 4,
  );

  final _tagController = TextEditingController();
  var _pickerVisible = false;
  var _saving = false;
  var _deleting = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submit(String tag) async {
    if (_saving) return;
    final text = tag.trim();
    if (text.isEmpty) return;
    // 先结束 IME 组词并失焦，再进入 saving；勿在组词中把输入框
    // enabled 关掉，否则 FormField 已 dispose 仍会收到 controller 通知。
    FocusManager.instance.primaryFocus?.unfocus();
    _tagController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _saving = true);
    try {
      final ok = await widget.onAddTag(text);
      if (!mounted) return;
      if (ok) _tagController.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String tag) async {
    if (_deleting) return;
    final onDelete = widget.onDeleteTag;
    if (onDelete == null) return;
    setState(() => _deleting = true);
    try {
      await onDelete(tag);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Color _tagColorAt(int index) => _tagPalette[index % _tagPalette.length];

  String _tagLabel(AdFileListTagEntity tag) {
    final label = tag.label?.trim();
    if (label != null && label.isNotEmpty) return label;
    final name = tag.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.tags;

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppText.title(
                '添加标签',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              AppButton.ghost(
                size: AppButtonSize.small,
                leading: const Icon(
                  AppLucideIcons.tag,
                  size: 14,
                  color: Color(0xFF15803D),
                ),
                onPressed: () =>
                    setState(() => _pickerVisible = !_pickerVisible),
                child: const Text(
                  '添加标签',
                  style: TextStyle(color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < tags.length; i++)
                  _SidebarHoverDeleteTag(
                    color: _tagColorAt(i),
                    label: _tagLabel(tags[i]),
                    size: _tagSize,
                    enabled: !_deleting,
                    onDelete: () => _delete(_tagLabel(tags[i])),
                  ),
              ],
            ),
          if (_pickerVisible)
            Row(
              spacing: 8,
              children: [
                AppTextFormField(
                  hintText: '输入标签',
                  controller: _tagController,
                  onSubmitted: _saving ? null : _submit,
                ).expanded(),
                // 勿同时传 loading: 与返回 Future 的 onPressed：
                // 上游在 loading != null 时不会清 _running，按钮会永久不可点。
                AppButton.primary(
                  color: const Color(0xFF00A0EC),
                  onPressed: _saving
                      ? null
                      : () => _submit(_tagController.text),
                  child: const Text('添加'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 标签悬停显示右上角删除角标。
class _SidebarHoverDeleteTag extends StatefulWidget {
  const _SidebarHoverDeleteTag({
    required this.color,
    required this.label,
    required this.size,
    required this.onDelete,
    this.enabled = true,
  });

  final Color color;
  final String label;
  final AppBadgeSize size;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  State<_SidebarHoverDeleteTag> createState() => _SidebarHoverDeleteTagState();
}

class _SidebarHoverDeleteTagState extends State<_SidebarHoverDeleteTag> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AppCornerBadge(
        position: AppCornerBadgePosition.topRight,
        ignorePointer: false,
        badge: _hovered
            ? AppInkWell(
                onPressed: widget.enabled ? widget.onDelete : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.destructive,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppLucideIcons.x,
                    size: 9,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              )
            : const SizedBox.shrink(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              widget.color.withValues(alpha: 0.14),
              const Color(0xFFFFFFFF),
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: widget.color),
          ),
          child: Padding(
            padding: widget.size.padding,
            child: SizedBox(
              height: widget.size.height,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.size.fontSize,
                    color: widget.color,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 设备占比 / 订单分布（环图 + 卡片）。
class _SidebarDeviceShareCard extends StatelessWidget {
  const _SidebarDeviceShareCard({
    required this.title,
    required this.defaultCenterLabel,
    required this.chart,
    required this.cards,
    this.softIcon = false,
  });

  final String title;
  final String defaultCenterLabel;
  final AdFileListChartEntity? chart;
  final List<AdFileListCardEntity> cards;

  /// 浅底彩色图标（与订单分布一致）。
  final bool softIcon;

  static const _accentRed = Color(0xFFEF4444);
  static const _accentGreen = Color(0xFF22C55E);

  static Color _segmentColor(int? id) => switch (id) {
    1 => const Color(0xFFF97316),
    2 => const Color(0xFF8B5CF6),
    3 => const Color(0xFF06B6D4),
    _ => const Color(0xFF64748B),
  };

  static Color _cardColor(AdFileListCardEntity card) {
    final title = card.title ?? '';
    if (title.contains('播放')) return const Color(0xFF22C55E);
    if (title.contains('总量')) return kBrandPrimary;
    return _segmentColor(card.id);
  }

  static IconData _cardIcon(AdFileListCardEntity card) {
    final title = card.title ?? '';
    if (title.contains('播放')) return AppLucideIcons.play;
    if (title.contains('总量')) return AppLucideIcons.folder;
    return AppLucideIcons.monitor;
  }

  /// 98 / 86 / 其他尺寸订单卡片用文件 SVG。
  static bool _isSizeOrderCard(AdFileListCardEntity card) {
    final title = card.title ?? '';
    return title.contains('寸');
  }

  static Widget _cardIconWidget(
    AdFileListCardEntity card, {
    required bool softIcon,
  }) {
    final fg = softIcon ? _cardColor(card) : const Color(0xFFFFFFFF);
    final title = card.title ?? '';
    if (title.contains('播放')) {
      return SvgPicture.asset(
        _kOrderPlayCameraIconAsset,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      );
    }
    if (title.contains('总量')) {
      return SvgPicture.asset(
        _kOrderTotalDeviceIconAsset,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      );
    }
    if (_isSizeOrderCard(card)) {
      return SvgPicture.asset(
        _kOrderSizeFileIconAsset,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      );
    }
    return Icon(_cardIcon(card), size: 14, color: fg);
  }

  static String _formatCount(int value) {
    final text = '$value';
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buf.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  static String _extraAccent(AdFileListCardExtraEntity? extra) {
    if (extra == null) return '';
    final direction = extra.direction?.trim().toLowerCase();
    if (direction == 'up' || direction == 'down') {
      final display = extra.display?.trim();
      // display 若已含箭头则直接用，避免再拼成 ↓↓ / ↑↑
      if (display != null && display.isNotEmpty) {
        if (display.startsWith('↑') || display.startsWith('↓')) {
          return display;
        }
        final arrow = direction == 'down' ? '↓' : '↑';
        return '$arrow $display';
      }
      final arrow = direction == 'down' ? '↓' : '↑';
      return '$arrow ${extra.value ?? ''}';
    }
    final value = extra.value;
    if (value == null) return '';
    return '$value';
  }

  static Color _extraAccentColor(AdFileListCardExtraEntity? extra) {
    final direction = extra?.direction?.trim().toLowerCase();
    return switch (direction) {
      'down' => _accentGreen,
      'up' => _accentRed,
      _ => _accentRed,
    };
  }

  static String? _extraAccentOrNull(AdFileListCardExtraEntity? extra) {
    final accent = _extraAccent(extra);
    return accent.isEmpty ? null : accent;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final centerValue = chart?.center?.value ?? chart?.total ?? 0;
    final centerLabel = chart?.center?.label?.trim().isNotEmpty == true
        ? chart!.center!.label!.trim()
        : defaultCenterLabel;
    final segments = [
      for (final s in chart?.segments ?? const <AdFileListChartSegmentEntity>[])
        ((s.percentage ?? 0) / 100.0, _segmentColor(s.id)),
    ];

    final cardRows = <List<AdFileListCardEntity>>[];
    for (var i = 0; i < cards.length; i += 2) {
      cardRows.add(
        cards.sublist(i, i + 2 > cards.length ? cards.length : i + 2),
      );
    }

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.title(title),
        Center(
          child: SizedBox.square(
            dimension: 160,
            child: CustomPaint(
              painter: _SidebarDonutPainter(
                segments: segments,
                trackColor: colors.muted,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText.title(
                    _formatCount(centerValue),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  AppText.caption(
                    centerLabel,
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final row in cardRows)
          Row(
            spacing: 8,
            children: [
              for (final card in row)
                _SidebarShareMiniCard(
                  icon: _cardIconWidget(card, softIcon: softIcon),
                  iconColor: _cardColor(card),
                  softIcon: softIcon,
                  title: card.title?.trim().isNotEmpty == true
                      ? card.title!.trim()
                      : '-',
                  value: card.formatted_value?.trim().isNotEmpty == true
                      ? card.formatted_value!.trim()
                      : '${card.value ?? 0}',
                  caption: card.extra?.label?.trim().isNotEmpty == true
                      ? card.extra!.label!.trim()
                      : '',
                  captionAccent: _extraAccentOrNull(card.extra),
                  captionAccentColor: card.extra?.direction != null
                      ? _extraAccentColor(card.extra)
                      : _cardColor(card),
                ).expanded(),
              if (row.length == 1) const Spacer(),
            ],
          ),
      ],
    );
  }
}

class _SidebarShareMiniCard extends StatelessWidget {
  const _SidebarShareMiniCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.caption,
    this.captionAccent,
    this.captionAccentColor,
    this.softIcon = false,
  });

  final Widget icon;
  final Color iconColor;
  final String title;
  final String value;
  final String caption;
  final String? captionAccent;
  final Color? captionAccentColor;
  final bool softIcon;

  @override
  Widget build(BuildContext context) {
    final colors = ShadcnTheme.of(context).colorScheme;
    final muted = colors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar.square(
            size: 28,
            borderRadius: 6,
            color: softIcon ? iconColor.withValues(alpha: 0.12) : iconColor,
            icon: icon,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              AppText.caption(
                title,
                style: TextStyle(color: muted, fontSize: 12),
              ),
              AppText.body(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text.rich(
                TextSpan(
                  style: TextStyle(color: muted, fontSize: 12),
                  children: [
                    TextSpan(text: caption),
                    if (captionAccent != null && captionAccent!.isNotEmpty)
                      TextSpan(
                        text: ' $captionAccent',
                        style: TextStyle(
                          color: captionAccentColor ?? muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ).expanded(),
        ],
      ),
    );
  }
}

class _SidebarDonutPainter extends CustomPainter {
  _SidebarDonutPainter({required this.segments, required this.trackColor});

  final List<(double ratio, Color color)> segments;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final stroke = radius * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    const tau = 3.141592653589793 * 2;
    final bg = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, tau, false, bg);

    var start = -3.141592653589793 / 2;
    for (final (ratio, color) in segments) {
      final sweep = ratio.clamp(0.0, 1.0) * tau;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SidebarDonutPainter oldDelegate) {
    if (oldDelegate.trackColor != trackColor) return true;
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i] != segments[i]) return true;
    }
    return false;
  }
}
