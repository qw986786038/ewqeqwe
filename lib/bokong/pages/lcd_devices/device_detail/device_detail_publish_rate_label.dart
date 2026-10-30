import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'device_detail_insets.dart';

/// 详情顶栏「上刊率」：灰色标签 + 绿色数值（对照设计图，非 Badge）。
///
/// 用 [Row] 垂直居中，避免 [Text.rich] 混排 14/20 号时按基线对齐显得下沉。
Widget deviceDetailPublishRateLabel(BuildContext context, String value) {
  final labelStyle = kDeviceDetailHeaderTextStyle.merge(
    TextStyle(
      fontSize: 14,
      color: ShadcnTheme.of(context).colorScheme.mutedForeground,
    ),
  );
  final valueStyle = kDeviceDetailHeaderTextStyle.merge(
    const TextStyle(
      color: Color(0xFF22C55E),
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  );
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text('上刊率:', style: labelStyle),
      Text(value, style: valueStyle),
    ],
  );
}
