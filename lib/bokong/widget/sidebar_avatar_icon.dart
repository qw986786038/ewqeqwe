import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yidivination/bokong/pages/lcd/customer/lcd_customer_utils.dart';
import 'package:yidivination/bokong/theme/theme.dart';

/// `update_icon` 的 type：1 客户 / 2 写字楼 / 3 设备 / 4 主订单。
abstract final class SidebarAvatarIconType {
  static const customer = 1;
  static const office = 2;
  static const device = 3;
  static const order = 4;
}

/// 模版库项：`name` 入库；[asset] 为本地 SVG。
class SidebarAvatarTemplate {
  const SidebarAvatarTemplate({
    required this.name,
    required this.asset,
    required this.type,
  });

  final String name;
  final String asset;
  final int type;
}

const _kCustomerDir = 'assets/images/sidebar_icons/customer';
const _kOfficeDir = 'assets/images/sidebar_icons/office';
const _kDeviceDir = 'assets/images/sidebar_icons/device';

/// 已废弃：旧的分类模版，仅用于渲染已保存的旧 `avatar_icon`，不再出现在选择列表。
const kSidebarAvatarTemplates = <SidebarAvatarTemplate>[
  // 客户
  SidebarAvatarTemplate(
    name: 'user_business',
    asset: '$_kCustomerDir/user_business.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_checked',
    asset: '$_kCustomerDir/user_checked.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_clear',
    asset: '$_kCustomerDir/user_clear.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_list',
    asset: '$_kCustomerDir/user_list.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_marked',
    asset: '$_kCustomerDir/user_marked.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_search',
    asset: '$_kCustomerDir/user_search.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_setting',
    asset: '$_kCustomerDir/user_setting.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_transmit',
    asset: '$_kCustomerDir/user_transmit.svg',
    type: SidebarAvatarIconType.customer,
  ),
  SidebarAvatarTemplate(
    name: 'user_visible',
    asset: '$_kCustomerDir/user_visible.svg',
    type: SidebarAvatarIconType.customer,
  ),
  // 写字楼 / 楼栋
  SidebarAvatarTemplate(
    name: 'folder',
    asset: '$_kOfficeDir/folder.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_add',
    asset: '$_kOfficeDir/folder_add.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_details',
    asset: '$_kOfficeDir/folder_details.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_solid',
    asset: '$_kOfficeDir/folder_solid.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_minus',
    asset: '$_kOfficeDir/folder_minus.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_move',
    asset: '$_kOfficeDir/folder_move.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_open',
    asset: '$_kOfficeDir/folder_open.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_open_alt',
    asset: '$_kOfficeDir/folder_open_alt.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_shared',
    asset: '$_kOfficeDir/folder_shared.svg',
    type: SidebarAvatarIconType.office,
  ),
  SidebarAvatarTemplate(
    name: 'folder_zip',
    asset: '$_kOfficeDir/folder_zip.svg',
    type: SidebarAvatarIconType.office,
  ),
  // 设备
  SidebarAvatarTemplate(
    name: 'airplay_wave',
    asset: '$_kDeviceDir/airplay_wave.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'desktop',
    asset: '$_kDeviceDir/desktop.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'device',
    asset: '$_kDeviceDir/device.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'hotspot_wave',
    asset: '$_kDeviceDir/hotspot_wave.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'laptop',
    asset: '$_kDeviceDir/laptop.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'mobile',
    asset: '$_kDeviceDir/mobile.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'mobile_vibrate',
    asset: '$_kDeviceDir/mobile_vibrate.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'phone_locked',
    asset: '$_kDeviceDir/phone_locked.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'remote_wave',
    asset: '$_kDeviceDir/remote_wave.svg',
    type: SidebarAvatarIconType.device,
  ),
  SidebarAvatarTemplate(
    name: 'tv',
    asset: '$_kDeviceDir/tv.svg',
    type: SidebarAvatarIconType.device,
  ),
];

const _kCommonDir = 'assets/images/sidebar_icons/common';

/// 通用默认图标（25 个），各处「更换图标」统一使用。
final kSidebarAvatarCommonTemplates = <SidebarAvatarTemplate>[
  for (var i = 1; i <= 25; i++)
    SidebarAvatarTemplate(
      name: 'icon_${i.toString().padLeft(2, '0')}',
      asset: '$_kCommonDir/icon_${i.toString().padLeft(2, '0')}.svg',
      type: 0,
    ),
];

/// 各处统一返回 [kSidebarAvatarCommonTemplates]；[type] 仅为兼容旧调用。
List<SidebarAvatarTemplate> sidebarAvatarTemplatesForType(int type) =>
    kSidebarAvatarCommonTemplates;

/// 先查通用图标，再查已废弃的 [kSidebarAvatarTemplates]（兼容已保存的旧数据）。
SidebarAvatarTemplate? sidebarAvatarTemplateByName(String? name) {
  final key = name?.trim();
  if (key == null || key.isEmpty) return null;
  for (final t in [...kSidebarAvatarCommonTemplates, ...kSidebarAvatarTemplates]) {
    if (t.name == key) return t;
  }
  return null;
}

String? sidebarAvatarTemplateAsset(String? name) =>
    sidebarAvatarTemplateByName(name)?.asset;

Widget sidebarAvatarSvg({
  required String asset,
  required double size,
  required Color color,
}) {
  return SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

Widget sidebarAvatarText({
  required String text,
  required Color color,
  double fontSize = 22,
}) {
  return Text(
    text,
    maxLines: 1,
    style: TextStyle(fontSize: fontSize, height: 1, fontWeight: FontWeight.w600, color: color),
  );
}

/// 解析 / 编码侧边栏 `avatar_icon`：
/// - 上传图：存 http(s) 链接
/// - 模版：存 JSON `{"name","color","bg"}`
/// - 字体：存 JSON `{"text","color","bg"}`（单字）
class SidebarAvatarIconValue {
  const SidebarAvatarIconValue.url(this.url)
    : name = null,
      text = null,
      color = null,
      bg = null;

  const SidebarAvatarIconValue.template({
    required this.name,
    required this.color,
    required this.bg,
  }) : url = null,
       text = null;

  const SidebarAvatarIconValue.text({
    required this.text,
    required this.color,
    required this.bg,
  }) : url = null,
       name = null;

  final String? url;
  final String? name;
  final String? text;
  final Color? color;
  final Color? bg;

  bool get isText => text != null && text!.isNotEmpty;

  bool get isNetwork => url != null && url!.isNotEmpty;

  static bool isHttpUrl(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  static SidebarAvatarIconValue? tryParse(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    if (isHttpUrl(text)) {
      return SidebarAvatarIconValue.url(text);
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      final map = <String, dynamic>{
        for (final e in decoded.entries) '${e.key}': e.value,
      };
      final glyph = map['text']?.toString().trim();
      if (glyph != null && glyph.isNotEmpty) {
        return SidebarAvatarIconValue.text(
          text: glyph,
          color: parseHexColor(map['color']?.toString()) ?? const Color(0xFF111827),
          bg: parseHexColor(map['bg']?.toString()) ?? const Color(0xFFFFFFFF),
        );
      }
      final name = map['name']?.toString().trim();
      if (name == null || name.isEmpty) return null;
      return SidebarAvatarIconValue.template(
        name: name,
        color:
            parseHexColor(map['color']?.toString()) ?? const Color(0xFF111827),
        bg: parseHexColor(map['bg']?.toString()) ?? const Color(0xFFFFFFFF),
      );
    } catch (_) {
      return null;
    }
  }

  /// 写入接口的 `avatar_icon` 字符串。
  String encode() {
    if (isNetwork) return url!.trim();
    return jsonEncode({
      if (isText) 'text': text else 'name': name,
      'color': colorToHex(color ?? const Color(0xFF111827)),
      'bg': colorToHex(bg ?? const Color(0xFFFFFFFF)),
    });
  }
}

String colorToHex(Color color) {
  int ch(double c) => (c * 255.0).round().clamp(0, 255);
  final r = ch(color.r).toRadixString(16).padLeft(2, '0');
  final g = ch(color.g).toRadixString(16).padLeft(2, '0');
  final b = ch(color.b).toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

/// 侧边栏头像：http 走网络图，否则按模版 JSON 渲染 SVG。
///
/// 底色与订单卡片一致：灰底 [kAvatarBackground]、无描边；模版/资源图本身不变。
class SidebarAvatarIcon extends StatelessWidget {
  const SidebarAvatarIcon({
    this.avatarIcon,
    this.size = 36,
    this.iconSize,
    this.fallbackAsset = 'assets/images/analytics/device_total.png',
    this.borderRadius = 16,
    this.useTemplateBackground = false,
    super.key,
  });

  final String? avatarIcon;
  final double size;
  final double? iconSize;
  final String fallbackAsset;
  final double borderRadius;

  /// 为 true 时模版头像用保存的 `bg` 作底色，否则统一灰底。
  final bool useTemplateBackground;

  @override
  Widget build(BuildContext context) {
    final parsed = SidebarAvatarIconValue.tryParse(avatarIcon);
    final glyph = iconSize ?? (size * 0.55);
    final fg = parsed?.color ?? const Color(0xFF111827);
    final svgAsset = sidebarAvatarTemplateAsset(parsed?.name);

    Widget child;
    if (parsed?.isNetwork == true) {
      child = ExtendedImage.network(
        parsed!.url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (parsed?.isText == true) {
      child = sidebarAvatarText(text: parsed!.text!, color: fg);
    } else if (svgAsset != null) {
      child = sidebarAvatarSvg(asset: svgAsset, size: glyph, color: fg);
    } else {
      child = Image.asset(
        fallbackAsset,
        width: glyph,
        height: glyph,
        filterQuality: FilterQuality.medium,
      );
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: parsed?.isNetwork == true
            ? null
            : useTemplateBackground && (svgAsset != null || parsed?.isText == true)
            ? parsed?.bg ?? kAvatarBackground
            : kAvatarBackground,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
