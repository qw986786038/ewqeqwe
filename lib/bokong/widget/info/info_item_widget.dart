import 'package:flutter/material.dart';
import 'package:yidivination/bokong/utils/ext.dart';

class InfoItemTextWidget extends StatelessWidget {
  const InfoItemTextWidget({
    super.key,
    required this.title,
    required this.info,
    this.twoLine = false,
  });

  final String title;
  final String? info;
  final bool twoLine;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final TextStyle infoStyle =
        theme.listTileTheme.titleTextStyle?.copyWith(fontSize: 14) ??
        const TextStyle(fontSize: 14);
    final double twoLineHeight =
        (infoStyle.fontSize ?? 14) * (infoStyle.height ?? 1.0) * 2.5;
    final Widget infoText = Text(
      info ?? "-",
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: infoStyle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.listTileTheme.subtitleTextStyle?.copyWith(fontSize: 12),
        ),
        if (twoLine)
          SizedBox(
            height: twoLineHeight,
            child: Align(alignment: Alignment.topLeft, child: infoText),
          )
        else
          infoText,
      ],
    );
  }
}

/// 标题与内容同一行水平排列；内容过长自动换行。
class InfoItemInlineWidget extends StatelessWidget {
  const InfoItemInlineWidget({
    super.key,
    required this.title,
    required this.info,
    this.titleWidth = 80,
    this.onTap,
  });

  final String title;
  final String? info;
  final double titleWidth;
  final VoidCallback? onTap;

  static TextStyle? titleStyle(ThemeData theme) =>
      theme.listTileTheme.subtitleTextStyle?.copyWith(fontSize: 12);

  static TextStyle? infoStyle(ThemeData theme) =>
      theme.listTileTheme.titleTextStyle?.copyWith(fontSize: 14);

  static Widget titleLabel({
    required String title,
    required double titleWidth,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: titleWidth,
      child: Text(title, style: titleStyle(theme)),
    );
  }

  Widget _infoContent(ThemeData theme) {
    final TextStyle? style = onTap != null
        ? infoStyle(theme)?.copyWith(color: Colors.blue)
        : infoStyle(theme);
    final Widget text = Text(info ?? '-', softWrap: true, style: style);
    if (onTap == null) return text;
    return GestureDetector(onTap: onTap, child: text);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleLabel(title: title, titleWidth: titleWidth, theme: theme),
        Expanded(child: _infoContent(theme)),
      ],
    );
  }
}

class InfoItemTextWidget2 extends StatelessWidget {
  const InfoItemTextWidget2({
    super.key,
    required this.title,
    required this.department,
    required this.name,
    required this.phone,
    this.action,
    this.onAction,
    this.titleWidth = 80,
  });

  final String title;
  final String? department;
  final String? name;
  final String? phone;
  final String? action;
  final VoidCallback? onAction;
  final double titleWidth;

  Widget _valueText(ThemeData theme, String? value) {
    return Flexible(
      child: Text(
        value ?? '-',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.listTileTheme.titleTextStyle?.copyWith(fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoItemInlineWidget.titleLabel(
          title: title,
          titleWidth: titleWidth,
          theme: theme,
        ),
        Expanded(
          child: Row(
            children: [
              _valueText(theme, department),
              const SizedBox(width: 8),
              _valueText(theme, name),
              const SizedBox(width: 8),
              _valueText(theme, phone),
              if (action != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
