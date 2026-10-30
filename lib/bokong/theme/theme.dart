import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';
import 'package:lemon_shadcn/shadcn.dart' show ComponentTheme, TabsTheme;

/// 品牌主色（实色 token，用于 ring / 选中态等）。
const Color kBrandPrimary = Color(0xFF00A0E9);

/// 列表卡头像底色（灰底 + 主色字）。
const Color kAvatarBackground = Color(0xFFEBEEF5);

/// 素材库 / 设备管理 / 客户订单等顶栏搜索框背景。
const Color kSearchFieldBackground = Color(0xFFF2F3F5);

/// 全局默认文字色（colorScheme.foreground / cardForeground / popoverForeground）。
const Color kTextPrimary = Color(0xFF1D2129);

/// 图标按钮默认前景色（outline / ghost / text）；未选中 Tab 的 muted 文案同色。
const Color kIconButtonForeground = Color(0xFF4E5969);

/// Scaffold 全局底色。
const Color kContentBackground = Color(0xFFEFF0F2);

/// 弹窗（AppFormDialog / AppAlertDialog）默认背景；对应 colorScheme.popover。
const Color kDialogBackground = Color(0xFFF8FAFC);

/// 表格表头背景色。
const Color kTableHeaderBackground = Color(0xFFE5E6EB);

/// 表格斑马纹行背景色。
const Color kTableStripeBackground = Color(0xFFF7F8FA);

/// 卡片选中态浅底。
const Color kCardSelectedBackground = Color(0xFFF7F8FA);

/// 文件夹 / 设备等卡片「选中」右上角勾选角标色。
const Color kSelectedCornerBadgeColor = Color(0xFF38BEF0);

/// 按钮 / 表单 / 分段 Tab 统一圆角（逻辑像素）。
///
/// 上游 `radiusMd = theme.radius × 12`，故 [kControlRadius] 对应
/// `AppThemeConfig.standard(radius: kControlRadius / 12)`。
const double kControlRadius = 8;

/// 文件夹页签渐变（选中：#00A0E9 → #38BEF0，深色约占左侧 1/4，之后缓慢过渡）。
const LinearGradient kFolderTabGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF00A0E9), Color(0xFF38BEF0)],
  stops: [0.25, 0.75],
);

/// 文件夹页签渐变（未选中：#777D80 → #9EA4A7，深色约占左侧 1/4，之后缓慢过渡）。
const LinearGradient kFolderTabIdleGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF777D80), Color(0xFF9EA4A7)],
  stops: [0.25, 0.75],
);

/// 表格表头文字样式（Medium，与状态徽章文字同字重）。
const TextStyle kTableHeaderTextStyle = TextStyle(
  color: Color(0xFF4E5969),
  fontWeight: FontWeight.w500,
);

/// 全局中文 UI 字体（`pubspec` `SourceHanSansSC`：Regular 400 / Medium 500 / Bold 700）。
const String kFontSourceHanSans = 'SourceHanSansSC';

final _sourceHanTypography = () {
  final source = AppTypography.system();
  TextStyle pf(TextStyle style) => style.copyWith(
    fontFamily: kFontSourceHanSans,
    fontFamilyFallback: const [
      'PingFang SC',
      'Microsoft YaHei UI',
      'Microsoft YaHei',
      'sans-serif',
    ],
  );
  return source.copyWith(
    sans: () => pf(source.sans),
    xSmall: () => pf(source.xSmall),
    small: () => pf(source.small),
    base: () => pf(source.base),
    large: () => pf(source.large),
    xLarge: () => pf(source.xLarge),
    x2Large: () => pf(source.x2Large),
    x3Large: () => pf(source.x3Large),
    x4Large: () => pf(source.x4Large),
    x5Large: () => pf(source.x5Large),
    x6Large: () => pf(source.x6Large),
    x7Large: () => pf(source.x7Large),
    x8Large: () => pf(source.x8Large),
    x9Large: () => pf(source.x9Large),
    thin: () => pf(source.thin),
    extraLight: () => pf(source.extraLight),
    light: () => pf(source.light),
    normal: () => pf(source.normal),
    medium: () => pf(source.medium),
    semiBold: () => pf(source.semiBold),
    bold: () => pf(source.bold),
    extraBold: () => pf(source.extraBold),
    black: () => pf(source.black),
    italic: () => pf(source.italic),
    h1: () => pf(source.h1),
    h2: () => pf(source.h2),
    h3: () => pf(source.h3),
    h4: () => pf(source.h4),
    p: () => pf(source.p),
    blockQuote: () => pf(source.blockQuote),
    lead: () => pf(source.lead),
    textLarge: () => pf(source.textLarge),
    textSmall: () => pf(source.textSmall),
    textMuted: () => pf(source.textMuted),
  );
}();

/// 产品主题配置。
abstract final class AppThemes {
  static final AppThemeConfig _standard = AppThemeConfig.standard(
    primary: kBrandPrimary,
    radius: kControlRadius / 12,
    controls: const AppControlMetrics(
      height: 36,
      buttonHeight: 35,
      buttonContentGap: 4,
    ),
    dialogRadius: 24,
  );

  static final config = _standard.copyWith(
    // 未选中 Tab 走 muted() → mutedForeground；保留子节点显式色（订单状态 Tab）。
    // 勿用 AppTabsTheme.unselectedForegroundColor：会 ColorFiltered 整页强染，盖掉子色。
    lightTheme: _standard.lightTheme.copyWith(
      typography: () => _sourceHanTypography,
      colorScheme: () => _standard.lightTheme.colorScheme.copyWith(
        foreground: () => kTextPrimary,
        cardForeground: () => kTextPrimary,
        popoverForeground: () => kTextPrimary,
        mutedForeground: () => kIconButtonForeground,
        popover: () => kDialogBackground,
      ),
    ),
    darkTheme: _standard.darkTheme.copyWith(
      typography: () => _sourceHanTypography,
      colorScheme: () => _standard.darkTheme.colorScheme.copyWith(
        mutedForeground: () => kIconButtonForeground,
      ),
    ),
    componentThemeWrapper: (child) => ComponentTheme<AppIconButtonTheme>(
      data: const AppIconButtonTheme(color: kIconButtonForeground),
      child: ComponentTheme<AppTabsTheme>(
        // 与 controls.height=36 对齐：外框 inset≈4 + tab 竖向 6×2 + 内容≈16。
        data: const AppTabsTheme(
          tabPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        // AppTabs 外框默认 radiusLg（=16）；改为与按钮/表单一致的 kControlRadius。
        child: ComponentTheme<TabsTheme>(
          data: TabsTheme(
            borderRadius: BorderRadius.circular(kControlRadius),
          ),
          child: ComponentTheme<AppDescriptionsTheme>(
            data: const AppDescriptionsTheme(
              labelStyle: TextStyle(color: Color(0xFF86909C)),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: kFontSourceHanSans,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBrandPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: kContentBackground,
  );
}
