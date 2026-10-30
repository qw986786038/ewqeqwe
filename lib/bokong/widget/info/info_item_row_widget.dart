import 'package:flutter/material.dart';
import 'package:yidivination/bokong/utils/ext.dart';

/// 横向信息项：左侧标题，右侧内容（与 [InfoItemWidget] 纵向版对应）。
class InfoItemRowWidget extends StatelessWidget {
  const InfoItemRowWidget({
    super.key,
    required this.title,
    required this.info,
    this.twoLine = false,
    this.gap = 8,
  });

  final String title;
  final String? info;
  final bool twoLine;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = context.theme;
    final TextStyle titleStyle =
        theme.listTileTheme.subtitleTextStyle?.copyWith(fontSize: 12) ??
        const TextStyle(fontSize: 12);
    final TextStyle infoStyle =
        theme.listTileTheme.titleTextStyle?.copyWith(fontSize: 14) ??
        const TextStyle(fontSize: 14);
    final double twoLineHeight =
        (infoStyle.fontSize ?? 14) * (infoStyle.height ?? 1.0) * 2.5;
    final Widget infoText = Text(
      info ?? '-',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: infoStyle,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: titleStyle),
        SizedBox(width: gap),
        Flexible(
          child: twoLine
              ? SizedBox(
                  height: twoLineHeight,
                  child: Align(alignment: Alignment.topLeft, child: infoText),
                )
              : infoText,
        ),
      ],
    );
  }
}
