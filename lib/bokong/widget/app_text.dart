import 'package:flutter/material.dart';

/// 文案规格：小字 / 正文 / 标题 / 大标题 / 列表标题 / 列表次级标题。
enum AppTextVariant {
  /// 小字，默认 12。
  small,

  /// 14 号通用正文。
  body,

  /// 标题，默认 16、加粗。
  title,

  /// 大标题，默认 18、加粗。
  largeTitle,

  /// 列表主标题，对齐 [ListTileThemeData.titleTextStyle]。
  listTitle,

  /// 列表次级标题，对齐 [ListTileThemeData.subtitleTextStyle]。
  listSubtitle,
}

/// 应用通用文案；字号 / 字重 / 颜色均有默认值，也可按需覆盖。
///
/// ```dart
/// AppText.body('正文')
/// AppText.title('区块标题')
/// AppText.largeTitle('页面大标题')
/// AppText.body('强调', color: Colors.red, fontWeight: FontWeight.w600)
/// ```
class AppText extends StatelessWidget {
  const AppText.small(
    this.data, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : variant = AppTextVariant.small;

  /// 14 号通用字体。
  const AppText.body(
    this.data, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : variant = AppTextVariant.body;

  /// 16 号标题，默认加粗；默认单行省略。
  const AppText.title(
    this.data, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.softWrap,
  }) : variant = AppTextVariant.title;

  /// 18 号大标题，默认加粗；默认单行省略。
  const AppText.largeTitle(
    this.data, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.softWrap,
  }) : variant = AppTextVariant.largeTitle;

  const AppText.listTitle(
    this.data, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : variant = AppTextVariant.listTitle;

  const AppText.listSubtitle(
    this.data, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  }) : variant = AppTextVariant.listSubtitle;

  final String data;
  final AppTextVariant variant;

  /// 覆盖默认颜色；为 null 时用规格默认色。
  final Color? color;

  /// 覆盖默认字重；为 null 时用规格默认字重。
  final FontWeight? fontWeight;

  /// 覆盖默认字号；为 null 时用规格默认字号。
  final double? fontSize;

  final double? height;

  /// 最大行数；[AppText.title] / [AppText.largeTitle] 默认 1，其余默认不限制。
  final int? maxLines;

  /// 溢出策略；[AppText.title] / [AppText.largeTitle] 默认 [TextOverflow.ellipsis]。
  final TextOverflow? overflow;

  final TextAlign? textAlign;
  final bool? softWrap;

  static const Color colorPrimary = Colors.black;
  static const Color colorSecondary = Color(0xFF525252);
  static const Color colorMuted = Color(0xFF6E8299);

  /// 规格默认字号。
  static double defaultFontSize(AppTextVariant variant) => switch (variant) {
    AppTextVariant.small => 12,
    AppTextVariant.body => 14,
    AppTextVariant.title => 16,
    AppTextVariant.largeTitle => 18,
    AppTextVariant.listTitle => 16,
    AppTextVariant.listSubtitle => 14,
  };

  /// 规格默认字重。
  static FontWeight defaultFontWeight(AppTextVariant variant) =>
      switch (variant) {
        AppTextVariant.small => FontWeight.normal,
        AppTextVariant.body => FontWeight.normal,
        AppTextVariant.title => FontWeight.bold,
        AppTextVariant.largeTitle => FontWeight.bold,
        AppTextVariant.listTitle => FontWeight.bold,
        AppTextVariant.listSubtitle => FontWeight.normal,
      };

  /// 规格默认颜色。
  static Color defaultColor(AppTextVariant variant) => switch (variant) {
    AppTextVariant.small => colorMuted,
    AppTextVariant.body => colorPrimary,
    AppTextVariant.title => colorPrimary,
    AppTextVariant.largeTitle => colorPrimary,
    AppTextVariant.listTitle => colorPrimary,
    AppTextVariant.listSubtitle => colorSecondary,
  };

  /// 解析规格基础样式：显式带上主题 fontFamily，避免 Syncfusion 等覆盖 DefaultTextStyle 后丢字体。
  static TextStyle baseStyle(BuildContext context, AppTextVariant variant) {
    final ThemeData theme = Theme.of(context);
    final ListTileThemeData listTile = theme.listTileTheme;
    final TextStyle? themed = switch (variant) {
      AppTextVariant.small => theme.textTheme.bodySmall,
      AppTextVariant.body => theme.textTheme.bodyMedium,
      AppTextVariant.title => theme.textTheme.titleMedium,
      AppTextVariant.largeTitle => theme.textTheme.titleLarge,
      AppTextVariant.listTitle =>
        listTile.titleTextStyle ?? theme.textTheme.titleMedium,
      AppTextVariant.listSubtitle =>
        listTile.subtitleTextStyle ?? theme.textTheme.bodyMedium,
    };
    final String? fontFamily =
        themed?.fontFamily ??
        theme.textTheme.bodyMedium?.fontFamily ??
        'SourceHanSansSC';
    // title / largeTitle 固定加粗，避免被 Material textTheme 的 Regular 覆盖。
    final FontWeight weight = switch (variant) {
      AppTextVariant.title ||
      AppTextVariant.largeTitle => defaultFontWeight(variant),
      _ => themed?.fontWeight ?? defaultFontWeight(variant),
    };
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback:
          themed?.fontFamilyFallback ??
          theme.textTheme.bodyMedium?.fontFamilyFallback,
      fontSize: themed?.fontSize ?? defaultFontSize(variant),
      fontWeight: weight,
      color: themed?.color ?? defaultColor(variant),
      height: themed?.height,
      letterSpacing: themed?.letterSpacing,
    );
  }

  /// 基础样式 + 可选覆盖。
  static TextStyle styleOf(
    BuildContext context,
    AppTextVariant variant, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
  }) {
    return baseStyle(context, variant).copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      textAlign: textAlign,
      softWrap: softWrap,
      style: styleOf(
        context,
        variant,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
        height: height,
      ),
    );
  }
}
