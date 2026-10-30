import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/sidebar_avatar_icon.dart';

/// 楼栋图标固定配色：图标块 / 浅色底 / 数量标签。
const kOfficeIconPalette = <({Color tile, Color back, Color badge})>[
  (tile: Color(0xFF6EE7B7), back: Color(0xFFD1FAE5), badge: Color(0xFF09843B)),
  (tile: Color(0xFF67E8F9), back: Color(0xFFCFFAFE), badge: Color(0xFF0891B2)),
  (tile: Color(0xFF7DD3FC), back: Color(0xFFE0F2FE), badge: Color(0xFF0284C7)),
  (tile: Color(0xFFBEF264), back: Color(0xFFECFCCB), badge: Color(0xFF78BC0D)),
  (tile: Color(0xFFFDA4AF), back: Color(0xFFFFE4E6), badge: Color(0xFFE11D48)),
  (tile: Color(0xFFFDBA74), back: Color(0xFFFFEDD5), badge: Color(0xFFF97316)),
  (tile: Color(0xFFFCD34D), back: Color(0xFFFEF3C7), badge: Color(0xFFF59E0B)),
  (tile: Color(0xFFE2E8F0), back: Color(0xFFF1F5F9), badge: Color(0xFF6D7E93)),
];

/// 楼栋未设置图标时的默认模版。
const kOfficeDefaultTemplate = 'icon_23';

/// 按图标块颜色取最接近的一组固定配色。
({Color tile, Color back, Color badge}) officeIconColors(Color? tile) {
  if (tile == null) return kOfficeIconPalette[2];
  double dist(Color a) =>
      (a.r - tile.r) * (a.r - tile.r) + (a.g - tile.g) * (a.g - tile.g) + (a.b - tile.b) * (a.b - tile.b);
  return kOfficeIconPalette.reduce((a, b) => dist(a.tile) <= dist(b.tile) ? a : b);
}

/// 未设置（或无法解析）图标时替换为默认模版 [kOfficeDefaultTemplate] + 蓝色图标块。
String? withDefaultAvatar(String? avatarIcon) {
  if (SidebarAvatarIconValue.tryParse(avatarIcon) != null) return avatarIcon;
  return SidebarAvatarIconValue.template(
    name: kOfficeDefaultTemplate,
    color: const Color(0xFF1F2937),
    bg: kOfficeIconPalette[2].tile,
  ).encode();
}

/// 侧栏深色标题卡的强调色（标题、「更改」文字）：有底色块取 `bg`，否则取图标色；无模版 / 文字图标时为默认蓝。
Color sidebarHeaderAccent(String? avatarIcon, {required bool templateBackground}) {
  final parsed = SidebarAvatarIconValue.tryParse(avatarIcon);
  final isGlyph = parsed != null && !parsed.isNetwork;
  final color = !isGlyph ? null : (templateBackground ? parsed.bg : parsed.color);
  return color ?? kOfficeIconPalette[2].tile;
}

/// 楼栋卡片图标：40 图标顶部对齐、52 浅色底底部对齐、14 高数量标签底部居中，整体 52×58。
///
/// 浅色底与标签色按 `avatar_icon` 的 `bg` 取 [kOfficeIconPalette]；未设置图标时为蓝色组 + [kOfficeDefaultTemplate]。
///
/// ```dart
/// OfficeCardIcon(avatarIcon: office.avatar_icon, count: office.deviceCount ?? 0)
/// ```
class OfficeCardIcon extends StatelessWidget {
  const OfficeCardIcon({
    this.avatarIcon,
    this.count = 0,
    this.fallbackAsset = 'assets/images/folder_icon.png',
    super.key,
  }) : swatch = null;

  /// 仅色块、无图标（模版色板用）。
  const OfficeCardIcon.swatch(Color this.swatch, {this.count = 0, super.key})
    : avatarIcon = null,
      fallbackAsset = '';

  final String? avatarIcon;
  final Color? swatch;
  final int count;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final parsed = SidebarAvatarIconValue.tryParse(avatarIcon);
    final palette = officeIconColors(swatch ?? parsed?.bg);
    final plainTile = swatch != null || parsed == null;

    return SizedBox(
      width: 52,
      height: 58,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.back,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (plainTile)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.tile, borderRadius: BorderRadius.circular(14)),
              child: swatch == null
                  ? sidebarAvatarSvg(asset: sidebarAvatarTemplateAsset(kOfficeDefaultTemplate)!, size: 24, color: const Color(0xFF1F2937))
                  : null,
            )
          else
            SidebarAvatarIcon(
              avatarIcon: avatarIcon,
              size: 40,
              iconSize: 24,
              borderRadius: 14,
              fallbackAsset: fallbackAsset,
              useTemplateBackground: true,
            ),
          Positioned(
            bottom: 0,
            child: Container(
              height: 14,
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.badge,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10, height: 1, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
